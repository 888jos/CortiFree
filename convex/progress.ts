import { ConvexError, v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { boundedLimit, requireUser } from "./lib/session";

const ANALYTICS_LIMITS = {
  taskStatuses: 400,
  completedTasks: 2000,
  habitTracking: 16,
  exerciseSessions: 2000,
  dailyRows: 1000,
} as const;

/**
 * ExerciseSessionRecorder / AntiStressViewModel (exercises_done).
 * Idempotent on `localSessionId` when provided. When `situation` is set
 * (anti-stress flow) it also updates lastExerciseType / totalExercisesCompleted
 * on the profile, in the same transaction.
 */
export const recordExerciseSession = mutation({
  args: {
    exerciseId: v.optional(v.string()),
    exerciseType: v.string(),
    durationSeconds: v.number(),
    completedAt: v.optional(v.number()),
    source: v.optional(v.string()),
    localSessionId: v.optional(v.string()),
    situation: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const user = await requireUser(ctx);
    if (args.durationSeconds < 0 || args.durationSeconds > 24 * 3600) {
      throw new ConvexError("Invalid duration");
    }
    if (args.localSessionId) {
      const dup = await ctx.db
        .query("exerciseSessions")
        .withIndex("by_user_localSessionId", (q) =>
          q.eq("userId", user._id).eq("localSessionId", args.localSessionId)
        )
        .first();
      if (dup) return dup._id;
    }
    const completedAt = args.completedAt ?? Date.now();
    const id = await ctx.db.insert("exerciseSessions", { userId: user._id, ...args, completedAt });
    if (args.situation !== undefined) {
      await ctx.db.patch(user._id, {
        lastExerciseType: args.exerciseType,
        lastExerciseAt: completedAt,
        totalExercisesCompleted: (user.totalExercisesCompleted ?? 0) + 1,
      });
    }
    return id;
  },
});

export const listExerciseSessions = query({
  args: { since: v.optional(v.number()), limit: v.optional(v.number()) },
  handler: async (ctx, { since, limit }) => {
    const user = await requireUser(ctx);
    const q = ctx.db
      .query("exerciseSessions")
      .withIndex("by_user_completedAt", (q) => q.eq("userId", user._id).gte("completedAt", since ?? 0))
      .order("desc");
    return await q.take(boundedLimit(limit, 100, 1000));
  },
});

/** stats/main – returns defaults when missing (the client no longer creates it). */
export const getStats = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    const stats = await ctx.db
      .query("userStats")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .unique();
    return (
      stats ?? { streak: 0, totalTasksCompleted: 0, history: {} as Record<string, number>, updatedAt: null }
    );
  },
});

/** FirebaseService.updateDailyProgress – merge stats/main. */
export const updateStats = mutation({
  args: {
    streak: v.optional(v.number()),
    totalTasksCompleted: v.optional(v.number()),
    historyEntry: v.optional(v.object({ date: v.string(), value: v.number() })),
  },
  handler: async (ctx, { streak, totalTasksCompleted, historyEntry }) => {
    const user = await requireUser(ctx);
    const existing = await ctx.db
      .query("userStats")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .unique();
    const history = { ...(existing?.history ?? {}) };
    if (historyEntry) {
      if (!/^\d{4}-\d{2}-\d{2}$/.test(historyEntry.date)) throw new ConvexError("Invalid date");
      history[historyEntry.date] = historyEntry.value;
    }
    const next = {
      streak: streak ?? existing?.streak ?? 0,
      totalTasksCompleted: totalTasksCompleted ?? existing?.totalTasksCompleted ?? 0,
      history,
      updatedAt: Date.now(),
    };
    if (existing) await ctx.db.patch(existing._id, next);
    else await ctx.db.insert("userStats", { userId: user._id, ...next });
  },
});

/**
 * Everything ProgressAnalyticsService reads, in one round trip:
 * profile dates, settings.programStartDate, task statuses, completed tasks,
 * habit tracking, exercise sessions, moods and check-ins since `since`
 * (default: programStartDate, else account creation).
 */
export const analyticsSnapshot = query({
  args: { since: v.optional(v.number()), sinceDate: v.optional(v.string()) },
  handler: async (ctx, args) => {
    const user = await requireUser(ctx);
    const settings = await ctx.db
      .query("userSettings")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .unique();
    const since =
      args.since ?? settings?.programStartDate ?? user.onboardingCompletedAt ?? user.createdAt ?? 0;
    const sinceDate = args.sinceDate ?? new Date(since).toISOString().slice(0, 10);

    const [taskStatuses, completedTasks, habitTracking, exerciseSessions, moods, checkins] =
      await Promise.all([
        ctx.db
          .query("taskStatuses")
          .withIndex("by_user_day", (q) => q.eq("userId", user._id))
          .take(ANALYTICS_LIMITS.taskStatuses),
        ctx.db
          .query("completedTasks")
          .withIndex("by_user_completedAt", (q) => q.eq("userId", user._id).gte("completedAt", since))
          .take(ANALYTICS_LIMITS.completedTasks),
        ctx.db
          .query("habitTracking")
          .withIndex("by_user_habit", (q) => q.eq("userId", user._id))
          .take(ANALYTICS_LIMITS.habitTracking),
        ctx.db
          .query("exerciseSessions")
          .withIndex("by_user_completedAt", (q) => q.eq("userId", user._id).gte("completedAt", since))
          .take(ANALYTICS_LIMITS.exerciseSessions),
        ctx.db
          .query("dailyMoods")
          .withIndex("by_user_date", (q) => q.eq("userId", user._id).gte("date", sinceDate))
          .take(ANALYTICS_LIMITS.dailyRows),
        ctx.db
          .query("dailyCheckins")
          .withIndex("by_user_date", (q) => q.eq("userId", user._id).gte("date", sinceDate))
          .take(ANALYTICS_LIMITS.dailyRows),
      ]);

    return {
      since,
      programStartDate: settings?.programStartDate ?? null,
      createdAt: user.createdAt ?? user._creationTime,
      onboardingCompletedAt: user.onboardingCompletedAt ?? null,
      taskStatuses: taskStatuses.map((row) => ({
        programDay: row.programDay,
        statuses: Object.fromEntries(row.statuses.map((s) => [s.key, s.status])),
      })),
      completedTasks,
      habitTracking,
      exerciseSessions,
      moods,
      checkins,
    };
  },
});
