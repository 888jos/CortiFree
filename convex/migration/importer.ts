import { ConvexError, v } from "convex/values";
import { internalMutation, internalQuery } from "../_generated/server";

/**
 * Internal-only staging import (called by convex/migration/import-legacy.cli.mjs
 * with an admin/deploy key). Nothing here is reachable by app clients.
 * Every write is idempotent (keyed by firebaseUid / firestorePath), so a batch
 * can be retried safely.
 */

const legacyUserRow = v.object({
  firebaseUid: v.string(),
  emailCanonical: v.optional(v.string()),
  appleSub: v.optional(v.string()),
  googleSub: v.optional(v.string()),
  authProviders: v.optional(v.array(v.string())),
  profile: v.any(),
  createdAt: v.optional(v.number()),
  updatedAt: v.optional(v.number()),
});

const legacyRecordRow = v.object({
  firebaseUid: v.optional(v.string()),
  firestorePath: v.string(),
  collection: v.string(),
  data: v.any(),
  sourceUpdatedAt: v.optional(v.number()),
  importedAt: v.number(),
});

export const startRun = internalMutation({
  args: { runId: v.string(), sourceDocumentCount: v.number(), sourceDigest: v.string() },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("migrationRuns")
      .withIndex("by_runId", (q) => q.eq("runId", args.runId))
      .unique();
    if (existing) {
      if (existing.sourceDigest !== args.sourceDigest) {
        throw new ConvexError("runId already used with a different export");
      }
      return existing._id;
    }
    return await ctx.db.insert("migrationRuns", {
      runId: args.runId,
      state: "prepared",
      sourceDocumentCount: args.sourceDocumentCount,
      importedDocumentCount: 0,
      sourceDigest: args.sourceDigest,
      startedAt: Date.now(),
    });
  },
});

export const finishRun = internalMutation({
  args: { runId: v.string(), importedDocumentCount: v.number(), importedDigest: v.string() },
  handler: async (ctx, args) => {
    const run = await ctx.db
      .query("migrationRuns")
      .withIndex("by_runId", (q) => q.eq("runId", args.runId))
      .unique();
    if (!run) throw new ConvexError("Unknown runId");
    await ctx.db.patch(run._id, {
      state: args.importedDocumentCount === run.sourceDocumentCount ? "imported" : "failed",
      importedDocumentCount: args.importedDocumentCount,
      importedDigest: args.importedDigest,
      completedAt: Date.now(),
      notes:
        args.importedDocumentCount === run.sourceDocumentCount
          ? undefined
          : `Count mismatch (auth-only accounts add legacyUsers rows): source=${run.sourceDocumentCount} imported=${args.importedDocumentCount}`,
    });
  },
});

export const importLegacyUsers = internalMutation({
  args: { runId: v.string(), rows: v.array(legacyUserRow) },
  handler: async (ctx, { runId, rows }) => {
    let written = 0;
    const now = Date.now();
    for (const row of rows) {
      const existing = await ctx.db
        .query("legacyUsers")
        .withIndex("by_firebaseUid", (q) => q.eq("firebaseUid", row.firebaseUid))
        .unique();
      const doc = {
        firebaseUid: row.firebaseUid,
        emailCanonical: row.emailCanonical?.trim().toLowerCase(),
        appleSub: row.appleSub,
        googleSub: row.googleSub,
        authProviders: row.authProviders ?? [],
        profile: row.profile ?? {},
        sourceCreatedAt: row.createdAt,
        sourceUpdatedAt: row.updatedAt,
        importedAt: now,
        runId,
      };
      if (existing) {
        if (existing.claimedByUserId) continue; // never overwrite claimed data
        await ctx.db.replace(existing._id, { ...doc });
      } else {
        await ctx.db.insert("legacyUsers", doc);
      }
      written += 1;
    }
    return { written };
  },
});

export const importLegacyRecords = internalMutation({
  args: { runId: v.string(), rows: v.array(legacyRecordRow) },
  handler: async (ctx, { rows }) => {
    let written = 0;
    for (const row of rows) {
      // Top-level collections keyed by a userId field (dailyTodos, bug_reports…)
      const firebaseUid =
        row.firebaseUid ??
        (typeof row.data?.userId === "string" ? (row.data.userId as string) : undefined);
      const existing = await ctx.db
        .query("legacyRecords")
        .withIndex("by_firestorePath", (q) => q.eq("firestorePath", row.firestorePath))
        .unique();
      const doc = { ...row, ...(firebaseUid ? { firebaseUid } : {}) };
      if (existing) await ctx.db.replace(existing._id, doc);
      else await ctx.db.insert("legacyRecords", doc);
      written += 1;
    }
    return { written };
  },
});

/** Per-collection counts for verification (dashboard / `npx convex run`). */
export const stagingCounts = internalQuery({
  args: { collection: v.string() },
  handler: async (ctx, { collection }) => {
    const rows = await ctx.db
      .query("legacyRecords")
      .withIndex("by_collection", (q) => q.eq("collection", collection))
      .collect();
    return { collection, count: rows.length };
  },
});
