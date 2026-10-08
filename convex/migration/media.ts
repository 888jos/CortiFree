import { v } from "convex/values";
import { internal } from "../_generated/api";
import { Id } from "../_generated/dataModel";
import { internalAction, internalMutation, internalQuery } from "../_generated/server";

/**
 * Converts the base64 images that Firestore stored inline (profilePhotoBase64,
 * journal photoURL, bug report screenshotBase64) into Convex file storage.
 * Runs in small batches and reschedules itself.
 */

const BATCH = 10;

type Pending =
  | { kind: "avatar"; id: Id<"users">; base64: string }
  | { kind: "journal"; id: Id<"journalEntries">; base64: string }
  | { kind: "bugReport"; id: Id<"bugReports">; base64: string };

export const pendingImages = internalQuery({
  args: { userId: v.id("users") },
  handler: async (ctx, { userId }): Promise<Pending[]> => {
    const pending: Pending[] = [];
    const user = await ctx.db.get(userId);
    if (!user) return [];
    if (user.legacyAvatarBase64) pending.push({ kind: "avatar", id: userId, base64: user.legacyAvatarBase64 });
    for await (const entry of ctx.db
      .query("journalEntries")
      .withIndex("by_user_createdAt", (q) => q.eq("userId", userId))) {
      if (pending.length >= BATCH) break;
      if (entry.legacyPhotoBase64) pending.push({ kind: "journal", id: entry._id, base64: entry.legacyPhotoBase64 });
    }
    for await (const report of ctx.db
      .query("bugReports")
      .withIndex("by_user", (q) => q.eq("userId", userId))) {
      if (pending.length >= BATCH) break;
      if (report.legacyScreenshotBase64) {
        pending.push({ kind: "bugReport", id: report._id, base64: report.legacyScreenshotBase64 });
      }
    }
    return pending.slice(0, BATCH);
  },
});

export const attachImage = internalMutation({
  args: {
    kind: v.union(v.literal("avatar"), v.literal("journal"), v.literal("bugReport")),
    id: v.string(),
    storageId: v.optional(v.id("_storage")),
  },
  handler: async (ctx, { kind, id, storageId }) => {
    if (kind === "avatar") {
      const userId = ctx.db.normalizeId("users", id);
      const user = userId ? await ctx.db.get(userId) : null;
      if (!user) {
        if (storageId) await ctx.storage.delete(storageId);
        return;
      }
      if (user.avatarStorageId && storageId) {
        await ctx.storage.delete(storageId); // user already set a new avatar
        await ctx.db.patch(user._id, { legacyAvatarBase64: undefined });
        return;
      }
      await ctx.db.patch(user._id, { avatarStorageId: storageId, legacyAvatarBase64: undefined });
    } else if (kind === "journal") {
      const entryId = ctx.db.normalizeId("journalEntries", id);
      const entry = entryId ? await ctx.db.get(entryId) : null;
      if (!entry) {
        if (storageId) await ctx.storage.delete(storageId);
        return;
      }
      await ctx.db.patch(entry._id, { photoStorageId: storageId, legacyPhotoBase64: undefined });
    } else {
      const reportId = ctx.db.normalizeId("bugReports", id);
      const report = reportId ? await ctx.db.get(reportId) : null;
      if (!report) {
        if (storageId) await ctx.storage.delete(storageId);
        return;
      }
      await ctx.db.patch(report._id, {
        screenshotStorageId: storageId,
        legacyScreenshotBase64: undefined,
      });
    }
  },
});

function decodeBase64(input: string): Uint8Array<ArrayBuffer> | null {
  try {
    const clean = input.replace(/^data:[^;]+;base64,/, "").replace(/\s/g, "");
    const binary = atob(clean);
    const bytes = new Uint8Array(new ArrayBuffer(binary.length));
    for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
    return bytes;
  } catch {
    return null;
  }
}

export const convertLegacyImages = internalAction({
  args: { userId: v.id("users") },
  handler: async (ctx, { userId }) => {
    const pending = await ctx.runQuery(internal.migration.media.pendingImages, { userId });
    for (const item of pending) {
      const bytes = decodeBase64(item.base64);
      // Undecodable payloads are dropped (storageId undefined clears the base64).
      const storageId = bytes
        ? await ctx.storage.store(new Blob([bytes], { type: "image/jpeg" }))
        : undefined;
      await ctx.runMutation(internal.migration.media.attachImage, {
        kind: item.kind,
        id: item.id,
        storageId,
      });
    }
    if (pending.length === BATCH) {
      await ctx.scheduler.runAfter(0, internal.migration.media.convertLegacyImages, { userId });
    }
  },
});
