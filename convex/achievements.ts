import { v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { badgeLevel } from "./schema";
import { requireUser } from "./lib/session";

/** users/{uid}/achievements – progress rows (templates live in the app). */
export const list = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    return await ctx.db
      .query("achievements")
      .withIndex("by_user_achievement", (q) => q.eq("userId", user._id))
      .take(100);
  },
});

/**
 * AchievementService.checkAchievements – batch upsert (merge). An already
 * unlocked achievement keeps its original unlockedAt.
 */
export const upsertMany = mutation({
  args: {
    items: v.array(
      v.object({
        achievementId: v.string(),
        progress: v.number(),
        unlockedAt: v.optional(v.number()),
      })
    ),
  },
  handler: async (ctx, { items }) => {
    const user = await requireUser(ctx);
    const now = Date.now();
    for (const item of items.slice(0, 100)) {
      const existing = await ctx.db
        .query("achievements")
        .withIndex("by_user_achievement", (q) =>
          q.eq("userId", user._id).eq("achievementId", item.achievementId)
        )
        .unique();
      if (existing) {
        await ctx.db.patch(existing._id, {
          progress: item.progress,
          unlockedAt: existing.unlockedAt ?? item.unlockedAt,
          updatedAt: now,
        });
      } else {
        await ctx.db.insert("achievements", { userId: user._id, ...item, updatedAt: now });
      }
    }
  },
});

/** users/{uid}/habit_badges – all badges. */
export const listBadges = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    return await ctx.db
      .query("habitBadges")
      .withIndex("by_user_habit_level", (q) => q.eq("userId", user._id))
      .take(64);
  },
});

/**
 * HabitBadgeService.initializeAllBadges / checkHabitBadges – upsert badges
 * keyed by (habitId, level). unlockedAt is never cleared once set.
 */
export const upsertBadges = mutation({
  args: {
    badges: v.array(
      v.object({
        habitId: v.string(),
        level: badgeLevel,
        requirement: v.number(),
        progress: v.number(),
        unlockedAt: v.optional(v.number()),
      })
    ),
  },
  handler: async (ctx, { badges }) => {
    const user = await requireUser(ctx);
    const now = Date.now();
    for (const badge of badges.slice(0, 64)) {
      const existing = await ctx.db
        .query("habitBadges")
        .withIndex("by_user_habit_level", (q) =>
          q.eq("userId", user._id).eq("habitId", badge.habitId).eq("level", badge.level)
        )
        .unique();
      if (existing) {
        await ctx.db.patch(existing._id, {
          requirement: badge.requirement,
          progress: badge.progress,
          unlockedAt: existing.unlockedAt ?? badge.unlockedAt,
          updatedAt: now,
        });
      } else {
        await ctx.db.insert("habitBadges", { userId: user._id, ...badge, updatedAt: now });
      }
    }
  },
});
