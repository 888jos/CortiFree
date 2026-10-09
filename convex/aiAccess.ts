import { ConvexError, v } from "convex/values";
import { internal } from "./_generated/api";
import { Id } from "./_generated/dataModel";
import { ActionCtx, internalMutation } from "./_generated/server";
import { requireUserId } from "./lib/session";
import { hasActiveEntitlement, refreshEntitlementFromRevenueCat } from "./subscriptions";

/**
 * Daily quotas for the paid AI calls (each one costs an upstream request). Counted
 * per UTC day, shared by every client of the account. `assistant` covers Milo chat,
 * « decode this message » and document import (the app shows one counter of 12).
 */
export const AI_DAILY_LIMITS = { assistant: 12, faceScan: 3 } as const;
export type AiFeature = keyof typeof AI_DAILY_LIMITS;
const aiFeature = v.union(v.literal("assistant"), v.literal("faceScan"));

/** Errors the app matches on (ConvexError data). */
export const QUOTA_EXCEEDED = "quota_exceeded";
export const SUBSCRIPTION_REQUIRED = "subscription_required";

export function utcDayKey(now: number): string {
  return new Date(now).toISOString().slice(0, 10);
}

export const consume = internalMutation({
  args: { userId: v.id("users"), feature: aiFeature },
  handler: async (ctx, { userId, feature }) => {
    const user = await ctx.db.get(userId);
    if (user === null) throw new ConvexError("Authentication required");
    const now = Date.now();
    if (!hasActiveEntitlement(user, now)) return { ok: false as const, reason: SUBSCRIPTION_REQUIRED };

    const limit = AI_DAILY_LIMITS[feature];
    const day = utcDayKey(now);
    const row = await ctx.db
      .query("aiUsage")
      .withIndex("by_user_feature_day", (q) => q.eq("userId", userId).eq("feature", feature).eq("day", day))
      .unique();
    const used = row?.count ?? 0;
    if (used >= limit) return { ok: false as const, reason: QUOTA_EXCEEDED };
    if (row) await ctx.db.patch(row._id, { count: used + 1, updatedAt: now });
    else await ctx.db.insert("aiUsage", { userId, feature, day, count: 1, updatedAt: now });
    return { ok: true as const, remaining: limit - used - 1, day };
  },
});

/** Gives the call back when the provider failed (only answered calls count). */
export const refund = internalMutation({
  args: { userId: v.id("users"), feature: aiFeature, day: v.string() },
  handler: async (ctx, { userId, feature, day }) => {
    const row = await ctx.db
      .query("aiUsage")
      .withIndex("by_user_feature_day", (q) => q.eq("userId", userId).eq("feature", feature).eq("day", day))
      .unique();
    if (row && row.count > 0) await ctx.db.patch(row._id, { count: row.count - 1, updatedAt: Date.now() });
  },
});

export type AiReservation = {
  userId: Id<"users">;
  remaining: number;
  /** Call when the upstream request failed, so the attempt does not count. */
  refund: () => Promise<void>;
};

/**
 * For actions: checks sign-in, the server-verified subscription and the daily
 * quota, and reserves one call. Throws ConvexError("subscription_required" |
 * "quota_exceeded").
 */
export async function reserveAiCall(ctx: ActionCtx, feature: AiFeature): Promise<AiReservation> {
  const userId = await requireUserId(ctx);
  let result = await ctx.runMutation(internal.aiAccess.consume, { userId, feature });
  if (!result.ok && result.reason === SUBSCRIPTION_REQUIRED && (await refreshEntitlementFromRevenueCat(ctx, userId))) {
    result = await ctx.runMutation(internal.aiAccess.consume, { userId, feature });
  }
  if (!result.ok) throw new ConvexError(result.reason);
  const { day } = result;
  return {
    userId,
    remaining: result.remaining,
    refund: async () => {
      await ctx.runMutation(internal.aiAccess.refund, { userId, feature, day });
    },
  };
}
