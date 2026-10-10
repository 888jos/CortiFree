import { v } from "convex/values";
import { internal } from "./_generated/api";
import { Doc } from "./_generated/dataModel";
import { internalAction, internalQuery, mutation } from "./_generated/server";
import { definedOnly, requireUser } from "./lib/session";

/**
 * Trial recovery: the app reports where the user stopped before starting the free trial,
 * and each change is mirrored to OneSignal, whose email journeys use these tags
 * (segment "CortiFree Email Recovery Eligible": tag email_recovery_eligible = "true").
 * Spec: docs/app-notes/TRIAL_RECOVERY_NOTIFICATIONS_PLAN.md
 *
 * Env: ONESIGNAL_REST_API_KEY (required to sync), ONESIGNAL_APP_ID (defaults to the CortiFree app).
 */

const DEFAULT_ONESIGNAL_APP_ID = "cdae2b5e-2f96-4e5a-a9c3-5108d95e762a";
const ONESIGNAL_API = "https://api.onesignal.com";

/** Steps from `authentication` on: the user has a plan. */
const PLAN_READY_STEPS = new Set([
  "authentication", "loading", "notificationPermissions", "planReady", "planDay", "planWeeks",
  "commitmentPledge", "complete",
  // Steps of older app builds (8-habits screens)
  "eightHabitsIntro", "weekProgress", "eightHabits", "habitsProgress",
]);

/** Copy used by the email templates ("struggling with {{main_symptom}}", "want to {{selected_goal}}"). */
const GOAL_COPY: Record<string, { symptom: string; goal: string }> = {
  sleep: { symptom: "poor sleep", goal: "sleep better" },
  stress: { symptom: "stress and anxiety", goal: "feel calmer" },
  energy: { symptom: "constant fatigue", goal: "get your energy back" },
  focus: { symptom: "trouble focusing", goal: "think more clearly" },
  emotional: { symptom: "emotional overload", goal: "feel lighter" },
};

/** OnboardingV2FlowView / RecoveryScheduler: progress before the trial (merged). */
export const sync = mutation({
  args: {
    step: v.optional(v.string()),
    paywallSeenAt: v.optional(v.number()),
    goal: v.optional(v.string()),
    offersOptIn: v.optional(v.boolean()),
    holdout: v.optional(v.boolean()),
    timezone: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const user = await requireUser(ctx);
    const current = user.recovery;
    const now = Date.now();
    const next = {
      ...(current ?? {}),
      ...definedOnly(args),
      // The first paywall view is the anchor of the sequences: never moved.
      paywallSeenAt: current?.paywallSeenAt ?? args.paywallSeenAt,
      stepAt: args.step !== undefined && args.step !== current?.step ? now : current?.stepAt,
      updatedAt: now,
    };
    await ctx.db.patch(user._id, { recovery: definedOnly(next) as NonNullable<Doc<"users">["recovery"]> });
    await ctx.scheduler.runAfter(0, internal.recovery.pushToOneSignal, { userId: user._id });
  },
});

export const userForOneSignal = internalQuery({
  args: { userId: v.id("users") },
  handler: async (ctx, { userId }) => ctx.db.get(userId),
});

/** Tags read by the OneSignal segment and email templates. */
export function oneSignalTags(user: Doc<"users">): Record<string, string> {
  const recovery = user.recovery;
  const copy = GOAL_COPY[recovery?.goal ?? ""] ?? GOAL_COPY.stress;
  const isPaid = user.subscription?.isPaid === true;
  const sawPaywall = recovery?.paywallSeenAt !== undefined;
  const eligible =
    !!user.email &&
    recovery?.offersOptIn === true &&
    recovery?.holdout !== true &&
    !isPaid &&
    // onboardingCompleted is only set after a purchase: lapsed users get the winback flow instead.
    user.onboardingCompleted !== true;
  const segment = sawPaywall ? "B" : PLAN_READY_STEPS.has(recovery?.step ?? "") ? "A2" : "A1";
  return {
    email_recovery_eligible: String(eligible),
    recovery_segment: segment,
    onboarding_step: recovery?.step ?? "",
    paywall_seen: String(sawPaywall),
    paywall_seen_at: sawPaywall ? String(Math.floor(recovery!.paywallSeenAt! / 1000)) : "",
    is_subscribed: String(isPaid),
    selected_goal: copy.goal,
    main_symptom: copy.symptom,
    goal: recovery?.goal ?? "",
    first_name: user.firstName ?? "",
  };
}

function oneSignalConfig() {
  const apiKey = process.env.ONESIGNAL_REST_API_KEY;
  if (!apiKey) return null;
  return { apiKey, appId: process.env.ONESIGNAL_APP_ID ?? DEFAULT_ONESIGNAL_APP_ID };
}

/** Creates or updates the OneSignal user (external_id = Convex user id). */
export const pushToOneSignal = internalAction({
  args: { userId: v.id("users") },
  handler: async (ctx, { userId }) => {
    const config = oneSignalConfig();
    if (!config) {
      console.warn("ONESIGNAL_REST_API_KEY missing: recovery sync skipped");
      return;
    }
    const user = await ctx.runQuery(internal.recovery.userForOneSignal, { userId });
    if (!user) return;

    const tags = oneSignalTags(user);
    const properties = definedOnly({
      tags,
      language: user.language?.slice(0, 2),
      timezone_id: user.recovery?.timezone,
    });
    const headers = { Authorization: `Key ${config.apiKey}`, "Content-Type": "application/json" };
    const base = `${ONESIGNAL_API}/apps/${config.appId}/users`;
    const externalId = encodeURIComponent(userId);
    // Email subscription only with consent to offers (GDPR / guideline 4.5.4).
    const consented = user.recovery?.offersOptIn === true && !!user.email;

    const created = await fetch(base, {
      method: "POST",
      headers,
      body: JSON.stringify({
        identity: { external_id: userId },
        properties,
        subscriptions: consented ? [{ type: "Email", token: user.email, enabled: true }] : [],
      }),
    });
    // An existing user gets the email subscription added but keeps its old tags: update them.
    if (!created.ok || created.status !== 201) {
      const updated = await fetch(`${base}/by/external_id/${externalId}`, {
        method: "PATCH",
        headers,
        body: JSON.stringify({ properties }),
      });
      if (!updated.ok) {
        console.error("OneSignal update failed", updated.status, await updated.text());
        return;
      }
    }
  },
});

/** Account deletion: removes the OneSignal user and its email subscription. */
export const removeFromOneSignal = internalAction({
  args: { userId: v.string() },
  handler: async (_ctx, { userId }) => {
    const config = oneSignalConfig();
    if (!config) return;
    const response = await fetch(
      `${ONESIGNAL_API}/apps/${config.appId}/users/by/external_id/${encodeURIComponent(userId)}`,
      { method: "DELETE", headers: { Authorization: `Key ${config.apiKey}` } }
    );
    if (!response.ok && response.status !== 404) {
      console.error("OneSignal delete failed", response.status, await response.text());
    }
  },
});
