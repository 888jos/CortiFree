import { ConvexError, v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { mood } from "./schema";
import { assertDateKey, boundedLimit, requireUser } from "./lib/session";

/** Ratings are 0-5 (0 = not rated / none). */
function clampRating(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.min(5, Math.max(0, Math.round(value)));
}

function wordCount(text: string): number {
  return text.split(/\s+/).filter(Boolean).length;
}

/**
 * DailyCheckInService.save: upserts daily_checkins/{date} and daily_moods/{date}
 * in one transaction; if `note` is not empty and `journalPrompt` is given, also
 * writes the "daily_checkin" journal entry (the client must NOT create it). A
 * resubmission the same day updates that entry instead of adding another one.
 */
export const submit = mutation({
  args: {
    date: v.string(),
    dayStartAt: v.number(),
    mood,
    stress: v.number(),
    sleep: v.number(),
    energy: v.number(),
    note: v.optional(v.string()),
    journalPrompt: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    assertDateKey(args.date);
    const user = await requireUser(ctx);
    const note = (args.note ?? "").trim();
    if (note.length > 20000) throw new ConvexError("Note too long");
    const now = Date.now();

    const checkin = {
      dayStartAt: args.dayStartAt,
      mood: args.mood,
      stress: clampRating(args.stress),
      sleep: clampRating(args.sleep),
      energy: clampRating(args.energy),
      note,
      updatedAt: now,
    };
    const existing = await ctx.db
      .query("dailyCheckins")
      .withIndex("by_user_date", (q) => q.eq("userId", user._id).eq("date", args.date))
      .unique();
    if (existing) await ctx.db.patch(existing._id, checkin);
    else
      await ctx.db.insert("dailyCheckins", {
        userId: user._id,
        date: args.date,
        createdAt: now,
        ...checkin,
      });

    const moodRow = await ctx.db
      .query("dailyMoods")
      .withIndex("by_user_date", (q) => q.eq("userId", user._id).eq("date", args.date))
      .unique();
    if (moodRow) await ctx.db.patch(moodRow._id, { mood: args.mood, recordedAt: now });
    else
      await ctx.db.insert("dailyMoods", {
        userId: user._id,
        date: args.date,
        dayStartAt: args.dayStartAt,
        mood: args.mood,
        recordedAt: now,
      });

    let journalEntryId = null;
    if (note) {
      const entry = {
        content: note,
        wordCount: wordCount(note),
        mood: args.mood,
        ...(args.journalPrompt !== undefined ? { prompt: args.journalPrompt } : {}),
        updatedAt: now,
      };
      // The entry of this day is keyed by its createdAt (the day start).
      const sameDay = await ctx.db
        .query("journalEntries")
        .withIndex("by_user_meditationType", (q) =>
          q.eq("userId", user._id).eq("meditationType", "daily_checkin").eq("createdAt", args.dayStartAt)
        )
        .first();
      if (sameDay) {
        await ctx.db.patch(sameDay._id, entry);
        journalEntryId = sameDay._id;
      } else {
        journalEntryId = await ctx.db.insert("journalEntries", {
          userId: user._id,
          ...entry,
          meditationType: "daily_checkin",
          tags: ["daily_checkin"],
          isFavorite: false,
          createdAt: args.dayStartAt,
        });
      }
    }
    return { journalEntryId };
  },
});

/** Check-ins in [fromDate, toDate] (inclusive day keys), oldest first. */
export const listCheckins = query({
  args: {
    fromDate: v.string(),
    toDate: v.optional(v.string()),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, { fromDate, toDate, limit }) => {
    assertDateKey(fromDate);
    if (toDate) assertDateKey(toDate);
    const user = await requireUser(ctx);
    return await ctx.db
      .query("dailyCheckins")
      .withIndex("by_user_date", (q) => {
        const lower = q.eq("userId", user._id).gte("date", fromDate);
        return toDate ? lower.lte("date", toDate) : lower;
      })
      .take(boundedLimit(limit, 400, 1000));
  },
});

export const getCheckin = query({
  args: { date: v.string() },
  handler: async (ctx, { date }) => {
    assertDateKey(date);
    const user = await requireUser(ctx);
    return await ctx.db
      .query("dailyCheckins")
      .withIndex("by_user_date", (q) => q.eq("userId", user._id).eq("date", date))
      .unique();
  },
});

/** daily_moods since a day key (ProgressAnalyticsService / fetchRecentMoods). */
export const listMoods = query({
  args: {
    fromDate: v.string(),
    toDate: v.optional(v.string()),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, { fromDate, toDate, limit }) => {
    assertDateKey(fromDate);
    if (toDate) assertDateKey(toDate);
    const user = await requireUser(ctx);
    return await ctx.db
      .query("dailyMoods")
      .withIndex("by_user_date", (q) => {
        const lower = q.eq("userId", user._id).gte("date", fromDate);
        return toDate ? lower.lte("date", toDate) : lower;
      })
      .take(boundedLimit(limit, 400, 1000));
  },
});

/** Standalone mood (FirebaseManager.saveDailyMood). */
export const setMood = mutation({
  args: { date: v.string(), dayStartAt: v.number(), mood },
  handler: async (ctx, args) => {
    assertDateKey(args.date);
    const user = await requireUser(ctx);
    const existing = await ctx.db
      .query("dailyMoods")
      .withIndex("by_user_date", (q) => q.eq("userId", user._id).eq("date", args.date))
      .unique();
    if (existing) await ctx.db.patch(existing._id, { mood: args.mood, recordedAt: Date.now() });
    else await ctx.db.insert("dailyMoods", { userId: user._id, ...args, recordedAt: Date.now() });
  },
});
