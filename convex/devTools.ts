import { v } from "convex/values";
import { internal } from "./_generated/api";
import { internalAction, internalQuery } from "./_generated/server";
import { refreshEntitlementFromRevenueCat } from "./subscriptions";
import { decodeAudio, transcribeWithOpenAI } from "./transcribe";

/**
 * Operator tools, run from the CLI only (internal functions are never reachable from
 * the app):
 *   npx convex run devTools:recentUsers
 *   npx convex run devTools:grantPremium '{"userId": "<id>", "days": 30}'
 *   npx convex run devTools:testTranscribe '{"audio": "<base64 m4a>"}'
 */

/** The last accounts that signed in, to find a tester's user id. */
export const recentUsers = internalQuery({
  args: { limit: v.optional(v.number()) },
  handler: async (ctx, { limit }) => {
    const users = await ctx.db.query("users").order("desc").take(200);
    return users
      .sort((a, b) => (b.lastLoginAt ?? b._creationTime) - (a.lastLoginAt ?? a._creationTime))
      .slice(0, limit ?? 8)
      .map((u) => ({
        id: u._id,
        email: u.email ?? null,
        name: u.firstName ?? u.displayName ?? u.name ?? null,
        lastLoginAt: u.lastLoginAt ? new Date(u.lastLoginAt).toISOString() : null,
        premium: !!u.entitlement && (u.entitlement.expiresAt === null || u.entitlement.expiresAt > Date.now()),
      }));
  },
});

/**
 * Grants the "pro" entitlement to a customer in RevenueCat (promotional access, seen by
 * both the app and this server), then refreshes the server copy. Needs a v2 secret key
 * with write access to customers (REVENUECAT_SECRET_API_KEY + REVENUECAT_PROJECT_ID).
 */
export const grantPremium = internalAction({
  args: { userId: v.id("users"), days: v.optional(v.number()) },
  handler: async (ctx, { userId, days }) => {
    const apiKey = process.env.REVENUECAT_SECRET_API_KEY;
    const projectId = process.env.REVENUECAT_PROJECT_ID;
    if (!apiKey || !projectId) throw new Error("REVENUECAT_SECRET_API_KEY and REVENUECAT_PROJECT_ID are required");
    const lookupKey = process.env.REVENUECAT_ENTITLEMENT_ID || "pro";
    const base = `https://api.revenuecat.com/v2/projects/${encodeURIComponent(projectId)}`;
    const headers = { Authorization: `Bearer ${apiKey}`, Accept: "application/json", "Content-Type": "application/json" };

    const list = await fetch(`${base}/entitlements?limit=100`, { headers });
    if (!list.ok) throw new Error(`RevenueCat entitlements: HTTP ${list.status}`);
    const body = (await list.json()) as { items?: { id?: string; lookup_key?: string }[] };
    const entitlementId = body.items?.find((e) => e.lookup_key === lookupKey)?.id;
    if (!entitlementId) throw new Error(`Entitlement "${lookupKey}" not found`);

    const expiresAt = Date.now() + (days ?? 30) * 24 * 3600 * 1000;
    const grant = await fetch(`${base}/customers/${encodeURIComponent(userId)}/actions/grant_entitlement`, {
      method: "POST",
      headers,
      body: JSON.stringify({ entitlement_id: entitlementId, expires_at: expiresAt }),
    });
    if (!grant.ok) {
      throw new Error(`RevenueCat grant: HTTP ${grant.status} ${(await grant.text()).slice(0, 300)}`);
    }
    // The REST check is throttled to once a minute: clear the throttle first.
    await ctx.runMutation(internal.subscriptions.clearRestCheck, { userId });
    const active = await refreshEntitlementFromRevenueCat(ctx, userId);
    return { granted: true, expiresAt: new Date(expiresAt).toISOString(), serverSeesPremium: active };
  },
});

/** Checks the OpenAI transcription setup with a sample recording (no user, no quota). */
export const testTranscribe = internalAction({
  args: { audio: v.string(), language: v.optional(v.string()) },
  handler: async (_ctx, { audio, language }) => {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) throw new Error("OPENAI_API_KEY is not set");
    return { text: await transcribeWithOpenAI(apiKey, decodeAudio(audio), "audio/mp4", language) };
  },
});
