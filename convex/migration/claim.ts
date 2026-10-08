import { v } from "convex/values";
import { internal } from "../_generated/api";
import { Doc, Id } from "../_generated/dataModel";
import { internalMutation, MutationCtx } from "../_generated/server";
import { transformProfile, transformRecord, TransformResult } from "./transform";

const BATCH = 100;

type RowResult = Extract<TransformResult, { kind: "row" }>;

/** Existing row with the same natural key (Convex data written after sign-in wins). */
async function findExisting(ctx: MutationCtx, userId: Id<"users">, item: RowResult) {
  switch (item.table) {
    case "userSettings":
    case "personalPlans":
    case "baselines":
    case "userStats":
      return await ctx.db
        .query(item.table)
        .withIndex("by_user", (q) => q.eq("userId", userId))
        .first();
    case "habitTracking":
      return await ctx.db
        .query("habitTracking")
        .withIndex("by_user_habit", (q) => q.eq("userId", userId).eq("habitId", item.row.habitId))
        .first();
    case "habitCompletions":
      return await ctx.db
        .query("habitCompletions")
        .withIndex("by_user_habit_date", (q) =>
          q.eq("userId", userId).eq("habitId", item.row.habitId).eq("date", item.row.date)
        )
        .first();
    case "taskStatuses":
      return await ctx.db
        .query("taskStatuses")
        .withIndex("by_user_day", (q) => q.eq("userId", userId).eq("programDay", item.row.programDay))
        .first();
    case "dailyCheckins":
    case "dailyMoods":
      return await ctx.db
        .query(item.table)
        .withIndex("by_user_date", (q) => q.eq("userId", userId).eq("date", item.row.date))
        .first();
    case "achievements":
      return await ctx.db
        .query("achievements")
        .withIndex("by_user_achievement", (q) =>
          q.eq("userId", userId).eq("achievementId", item.row.achievementId)
        )
        .first();
    case "habitBadges":
      return await ctx.db
        .query("habitBadges")
        .withIndex("by_user_habit_level", (q) =>
          q.eq("userId", userId).eq("habitId", item.row.habitId).eq("level", item.row.level)
        )
        .first();
    case "completedTasks":
    case "exerciseSessions":
    case "journalEntries":
    case "userTasks":
    case "dailyTodos":
      return await ctx.db
        .query(item.table)
        .withIndex("by_user_legacyPath", (q) =>
          q.eq("userId", userId).eq("legacyPath", item.row.legacyPath)
        )
        .first();
    case "bugReports":
      return null;
  }
}

/** Inserts one transformed row unless a newer Convex row exists. Returns true if written. */
export async function applyRow(ctx: MutationCtx, userId: Id<"users">, item: RowResult) {
  const existing = await findExisting(ctx, userId, item);
  if (existing) {
    if (item.table === "taskStatuses") {
      // Merge keys the Convex row does not have yet.
      const current = existing as Doc<"taskStatuses">;
      const known = new Set(current.statuses.map((s) => s.key));
      const added = item.row.statuses.filter((s) => !known.has(s.key));
      if (added.length > 0) {
        await ctx.db.patch(current._id, { statuses: [...current.statuses, ...added] });
      }
    }
    return false;
  }
  // The union is narrowed per table above; the cast only bridges TS's
  // inability to correlate `table` and `row` in a generic insert.
  await ctx.db.insert(item.table, { ...item.row, userId } as never);
  return true;
}

/** Applies the legacy root profile (users/{uid}) – only fills empty fields. */
export async function applyLegacyProfile(
  ctx: MutationCtx,
  user: Doc<"users">,
  legacy: Doc<"legacyUsers">
) {
  const patch = transformProfile(legacy.profile);
  const toApply: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(patch)) {
    if (value === undefined) continue;
    if (key === "onboardingCompleted") {
      if (value === true && user.onboardingCompleted !== true) toApply[key] = true;
      continue;
    }
    if (key === "createdAt") {
      // Keep the original account creation date (program start fallback).
      if (typeof value === "number" && (user.createdAt === undefined || value < user.createdAt)) {
        toApply[key] = value;
      }
      continue;
    }
    if ((user as Record<string, unknown>)[key] === undefined) toApply[key] = value;
  }
  if (Object.keys(toApply).length > 0) await ctx.db.patch(user._id, toApply as Partial<Doc<"users">>);
  // Keep the raw profile for reference (owned, deleted with the account).
  await ctx.db.insert("archivedRecords", {
    userId: user._id,
    collection: "users",
    firestorePath: `users/${legacy.firebaseUid}`,
    data: legacy.profile ?? {},
    importedAt: legacy.importedAt,
  });
}

/**
 * Moves the next batch of legacyRecords of `firebaseUid` into the app tables,
 * deletes them from staging, and reschedules itself until done.
 */
export const claimBatch = internalMutation({
  args: { userId: v.id("users"), firebaseUid: v.string() },
  handler: async (ctx, { userId, firebaseUid }) => {
    const user = await ctx.db.get(userId);
    if (!user || user.legacyFirebaseUid !== firebaseUid) return; // account deleted / relinked
    const records = await ctx.db
      .query("legacyRecords")
      .withIndex("by_firebaseUid", (q) => q.eq("firebaseUid", firebaseUid))
      .take(BATCH);

    let needsMedia = false;
    for (const record of records) {
      const result = transformRecord(record);
      if (result.kind === "row") {
        await applyRow(ctx, userId, result);
        if (
          ("legacyPhotoBase64" in result.row && result.row.legacyPhotoBase64) ||
          ("legacyScreenshotBase64" in result.row && result.row.legacyScreenshotBase64)
        ) {
          needsMedia = true;
        }
      } else if (result.kind === "archive") {
        await ctx.db.insert("archivedRecords", {
          userId,
          collection: record.collection,
          firestorePath: record.firestorePath,
          data: record.data,
          importedAt: record.importedAt,
        });
      }
      // "skip": not user data (should not happen for a firebaseUid-scoped record)
      await ctx.db.delete(record._id);
    }

    if (needsMedia) {
      await ctx.scheduler.runAfter(0, internal.migration.media.convertLegacyImages, { userId });
    }
    if (records.length === BATCH) {
      await ctx.scheduler.runAfter(0, internal.migration.claim.claimBatch, { userId, firebaseUid });
    } else {
      await ctx.db.patch(userId, { legacyClaimState: "done", legacyClaimedAt: Date.now() });
      if (user.legacyAvatarBase64) {
        await ctx.scheduler.runAfter(0, internal.migration.media.convertLegacyImages, { userId });
      }
    }
  },
});
