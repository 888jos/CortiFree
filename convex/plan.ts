import { ConvexError, v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { planFields } from "./schema";
import { requireUser } from "./lib/session";

/** personalized_plan/current (fetchRemotePlan). */
export const getCurrent = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    return await ctx.db
      .query("personalPlans")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .unique();
  },
});

/** PersonalPlanStore.pushRemote – full overwrite of the current plan. */
export const saveCurrent = mutation({
  args: v.object(planFields),
  handler: async (ctx, args) => {
    const user = await requireUser(ctx);
    if (args.planJSON.length > 900_000) throw new ConvexError("Plan too large");
    const existing = await ctx.db
      .query("personalPlans")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .unique();
    const doc = { userId: user._id, ...args, updatedAt: Date.now() };
    if (existing) {
      await ctx.db.replace(existing._id, doc);
      return existing._id;
    }
    return await ctx.db.insert("personalPlans", doc);
  },
});

/**
 * Inputs PersonalPlanStore reads to build a plan: onboarding answers on the
 * profile + baseline preferences (replaces two Firestore reads).
 */
export const planInputs = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    const baseline = await ctx.db
      .query("baselines")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .unique();
    return {
      onboarding: user.onboarding ?? null,
      quizAnswers: baseline?.quizAnswers ?? null,
      primaryGoal: baseline?.preferences?.primaryGoal ?? null,
      availableTime: baseline?.preferences?.availableTime ?? null,
    };
  },
});
