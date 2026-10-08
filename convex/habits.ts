import { ConvexError, v } from "convex/values";
import { Doc } from "./_generated/dataModel";
import { mutation, MutationCtx, query } from "./_generated/server";
import { assertDateKey, boundedLimit, requireUser } from "./lib/session";

export const DEFAULT_HABITS: ReadonlyArray<[string, string]> = [
  ["breathing", "Respirer en conscience"],
  ["meditation", "Méditer en pleine conscience"],
  ["journal", "Tenir un journal"],
  ["water", "S'hydrater régulièrement"],
  ["sport", "Faire du sport"],
  ["nature", "Sortir dans la nature"],
  ["social", "Moments sociaux"],
  ["sleep", "Routine de sommeil"],
];

function emptyTracking(habitId: string, habitTitle: string) {
  return {
    habitId,
    habitTitle,
    currentStreak: 0,
    longestStreak: 0,
    totalCompletions: 0,
    last7Days: [false, false, false, false, false, false, false],
    completedDays: [] as number[],
    updatedAt: Date.now(),
  };
}

function dayDiff(fromKey: string, toKey: string): number {
  const toUtc = (key: string) => {
    const [y, m, d] = key.split("-").map(Number);
    return Date.UTC(y, m - 1, d);
  };
  return Math.round((toUtc(toKey) - toUtc(fromKey)) / 86_400_000);
}

/** Port of FirebaseManager.calculateStreakFromCompletedDays. */
function streakFromDays(days: number[]): number {
  if (days.length === 0) return 0;
  const sorted = [...days].sort((a, b) => b - a);
  let streak = 1;
  for (let i = 0; i < sorted.length - 1; i += 1) {
    if (sorted[i] - sorted[i + 1] === 1) streak += 1;
    else break;
  }
  return streak;
}

async function getTracking(ctx: MutationCtx, userId: Doc<"users">["_id"], habitId: string) {
  return await ctx.db
    .query("habitTracking")
    .withIndex("by_user_habit", (q) => q.eq("userId", userId).eq("habitId", habitId))
    .unique();
}

/** fetchAllHabitTracking – all habit_tracking docs. */
export const listTracking = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    return await ctx.db
      .query("habitTracking")
      .withIndex("by_user_habit", (q) => q.eq("userId", user._id))
      .take(DEFAULT_HABITS.length);
  },
});

/** fetchHabitTracking – single habit. */
export const getTrackingByHabit = query({
  args: { habitId: v.string() },
  handler: async (ctx, { habitId }) => {
    const user = await requireUser(ctx);
    return await ctx.db
      .query("habitTracking")
      .withIndex("by_user_habit", (q) => q.eq("userId", user._id).eq("habitId", habitId))
      .unique();
  },
});

/** initializeHabitTracking – creates the 8 default habits if missing (idempotent). */
export const initializeTracking = mutation({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    let created = 0;
    for (const [habitId, title] of DEFAULT_HABITS) {
      if (!(await getTracking(ctx, user._id, habitId))) {
        await ctx.db.insert("habitTracking", { userId: user._id, ...emptyTracking(habitId, title) });
        created += 1;
      }
    }
    return { created };
  },
});

/**
 * markHabitCompleted – writes the daily completion and updates streak stats
 * atomically (server-side port of HabitTracking.markCompleted).
 * `date` = local day key "yyyy-MM-dd" computed on device.
 */
export const markCompleted = mutation({
  args: {
    habitId: v.string(),
    programDay: v.number(),
    date: v.string(),
    completedAt: v.optional(v.number()),
  },
  handler: async (ctx, { habitId, programDay, date, completedAt }) => {
    assertDateKey(date);
    if (!Number.isInteger(programDay) || programDay < 1) throw new ConvexError("Invalid programDay");
    const user = await requireUser(ctx);
    const at = completedAt ?? Date.now();

    const completion = await ctx.db
      .query("habitCompletions")
      .withIndex("by_user_habit_date", (q) =>
        q.eq("userId", user._id).eq("habitId", habitId).eq("date", date)
      )
      .unique();
    if (completion) await ctx.db.patch(completion._id, { completed: true, completedAt: at });
    else
      await ctx.db.insert("habitCompletions", {
        userId: user._id,
        habitId,
        date,
        completed: true,
        completedAt: at,
      });

    const existing = await getTracking(ctx, user._id, habitId);
    const tracking: Omit<Doc<"habitTracking">, "_id" | "_creationTime"> = existing ?? {
      userId: user._id,
      ...emptyTracking(habitId, habitId.charAt(0).toUpperCase() + habitId.slice(1)),
    };
    if (tracking.completedDays.includes(programDay)) return tracking;

    let currentStreak = tracking.currentStreak;
    if (tracking.lastCompletedDate) {
      const diff = dayDiff(tracking.lastCompletedDate, date);
      if (diff === 1) currentStreak += 1;
      else if (diff > 1) currentStreak = 1;
    } else {
      currentStreak = 1;
    }
    const next = {
      currentStreak,
      longestStreak: Math.max(tracking.longestStreak, currentStreak),
      lastCompletedAt: at,
      lastCompletedDate: date,
      firstCompletedAt: tracking.firstCompletedAt ?? at,
      totalCompletions: tracking.totalCompletions + 1,
      last7Days: [...tracking.last7Days.slice(1), true],
      completedDays: [...tracking.completedDays, programDay].sort((a, b) => a - b),
      updatedAt: Date.now(),
    };
    if (existing) await ctx.db.patch(existing._id, next);
    else await ctx.db.insert("habitTracking", { ...tracking, ...next, userId: user._id });
    return { ...tracking, ...next };
  },
});

/** removeHabitCompletion – mirror of the Swift logic. */
export const removeCompletion = mutation({
  args: { habitId: v.string(), programDay: v.number(), date: v.string() },
  handler: async (ctx, { habitId, programDay, date }) => {
    assertDateKey(date);
    const user = await requireUser(ctx);
    const completion = await ctx.db
      .query("habitCompletions")
      .withIndex("by_user_habit_date", (q) =>
        q.eq("userId", user._id).eq("habitId", habitId).eq("date", date)
      )
      .unique();
    if (completion) await ctx.db.delete(completion._id);

    const tracking = await getTracking(ctx, user._id, habitId);
    if (!tracking) return null;
    const completedDays = tracking.completedDays.filter((day) => day !== programDay);
    const next = {
      completedDays,
      totalCompletions: Math.max(0, tracking.totalCompletions - 1),
      lastCompletedAt: undefined,
      lastCompletedDate: undefined,
      currentStreak: streakFromDays(completedDays),
      updatedAt: Date.now(),
    };
    await ctx.db.patch(tracking._id, next);
    return { ...tracking, ...next };
  },
});

/** fetchHabitCompletionHistory – completions in [fromDate, toDate] (day keys). */
export const listCompletions = query({
  args: {
    habitId: v.optional(v.string()),
    fromDate: v.string(),
    toDate: v.string(),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, { habitId, fromDate, toDate, limit }) => {
    assertDateKey(fromDate);
    assertDateKey(toDate);
    const user = await requireUser(ctx);
    const rowLimit = boundedLimit(limit, 500, 2000);
    if (habitId !== undefined) {
      return await ctx.db
        .query("habitCompletions")
        .withIndex("by_user_habit_date", (q) =>
          q.eq("userId", user._id).eq("habitId", habitId).gte("date", fromDate).lte("date", toDate)
        )
        .take(rowLimit);
    }
    return await ctx.db
      .query("habitCompletions")
      .withIndex("by_user_date", (q) =>
        q.eq("userId", user._id).gte("date", fromDate).lte("date", toDate)
      )
      .take(rowLimit);
  },
});
