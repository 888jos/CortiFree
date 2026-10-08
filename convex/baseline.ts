import { v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { baselineFields, onboardingProfile } from "./schema";
import { definedOnly, requireUser } from "./lib/session";

/** baseline/initial */
export const getInitial = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    return await ctx.db
      .query("baselines")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .unique();
  },
});

/**
 * OptimizedFirebaseService.saveOnboardingData – writes baseline/initial
 * (overwrite) and merges the onboarding answers into the profile atomically
 * (replaces the Firestore batch).
 */
export const saveInitial = mutation({
  args: {
    baseline: v.object({ ...baselineFields, collectedAt: v.optional(v.number()) }),
    profile: v.optional(onboardingProfile),
    onboardingCompleted: v.optional(v.boolean()),
  },
  handler: async (ctx, { baseline, profile, onboardingCompleted }) => {
    const user = await requireUser(ctx);
    const now = Date.now();
    const existing = await ctx.db
      .query("baselines")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .unique();
    const doc = {
      userId: user._id,
      ...baseline,
      collectedAt: baseline.collectedAt ?? now,
      updatedAt: now,
    };
    if (existing) await ctx.db.replace(existing._id, doc);
    else await ctx.db.insert("baselines", doc);

    await ctx.db.patch(
      user._id,
      definedOnly({
        hasBaseline: true,
        onboarding: profile ? { ...(user.onboarding ?? {}), ...definedOnly(profile) } : undefined,
        onboardingCompleted: onboardingCompleted === true ? true : undefined,
        onboardingCompletedAt:
          onboardingCompleted === true ? (user.onboardingCompletedAt ?? now) : undefined,
        updatedAt: now,
      })
    );
  },
});
