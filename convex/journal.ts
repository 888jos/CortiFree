import { paginationOptsValidator } from "convex/server";
import { ConvexError, v } from "convex/values";
import { Doc, Id } from "./_generated/dataModel";
import { mutation, MutationCtx, query, QueryCtx } from "./_generated/server";
import { mood } from "./schema";
import { boundedLimit, requireUser } from "./lib/session";

const MAX_CONTENT = 50000;
const MAX_PHOTO_BYTES = 5 * 1024 * 1024;

async function present(ctx: QueryCtx, entry: Doc<"journalEntries">) {
  const { legacyPhotoBase64, ...rest } = entry;
  return {
    ...rest,
    photoUrl: entry.photoStorageId ? await ctx.storage.getUrl(entry.photoStorageId) : null,
    hasLegacyPhotoPending: legacyPhotoBase64 !== undefined,
  };
}

async function ownedEntry(ctx: MutationCtx | QueryCtx, userId: Id<"users">, id: Id<"journalEntries">) {
  const entry = await ctx.db.get(id);
  if (!entry || entry.userId !== userId) throw new ConvexError("Journal entry not found");
  return entry;
}

async function assertPhoto(ctx: MutationCtx, storageId: Id<"_storage">) {
  const meta = await ctx.db.system.get(storageId);
  if (!meta) throw new ConvexError("Unknown file");
  if (meta.size > MAX_PHOTO_BYTES) throw new ConvexError("Photo too large");
}

function wordCount(text: string) {
  return text.split(/\s+/).filter(Boolean).length;
}

/** loadAllEntries – newest first (optional limit). */
export const list = query({
  args: { limit: v.optional(v.number()) },
  handler: async (ctx, { limit }) => {
    const user = await requireUser(ctx);
    const q = ctx.db
      .query("journalEntries")
      .withIndex("by_user_createdAt", (q) => q.eq("userId", user._id))
      .order("desc");
    const rows = await q.take(boundedLimit(limit, 100, 500));
    return await Promise.all(rows.map((row) => present(ctx, row)));
  },
});

/** Paginated variant for long histories. */
export const listPage = query({
  args: { paginationOpts: paginationOptsValidator },
  handler: async (ctx, { paginationOpts }) => {
    const user = await requireUser(ctx);
    const result = await ctx.db
      .query("journalEntries")
      .withIndex("by_user_createdAt", (q) => q.eq("userId", user._id))
      .order("desc")
      .paginate(paginationOpts);
    return { ...result, page: await Promise.all(result.page.map((row) => present(ctx, row))) };
  },
});

/** Legacy filters (meditationType / meditationId), newest first. */
export const listByMeditation = query({
  args: {
    meditationType: v.optional(v.string()),
    meditationId: v.optional(v.string()),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, { meditationType, meditationId, limit }) => {
    const user = await requireUser(ctx);
    const rowLimit = boundedLimit(limit, 100, 500);
    const rows =
      meditationId !== undefined
        ? await ctx.db
            .query("journalEntries")
            .withIndex("by_user_meditationId", (q) =>
              q.eq("userId", user._id).eq("meditationId", meditationId)
            )
            .order("desc")
            .take(rowLimit)
        : await ctx.db
            .query("journalEntries")
            .withIndex("by_user_meditationType", (q) =>
              q.eq("userId", user._id).eq("meditationType", meditationType)
            )
            .order("desc")
            .take(rowLimit);
    return await Promise.all(rows.map((row) => present(ctx, row)));
  },
});

export const get = query({
  args: { id: v.id("journalEntries") },
  handler: async (ctx, { id }) => {
    const user = await requireUser(ctx);
    return await present(ctx, await ownedEntry(ctx, user._id, id));
  },
});

/** Upload URL for a journal photo (JPEG); then pass the storageId to create/update. */
export const generatePhotoUploadUrl = mutation({
  args: {},
  handler: async (ctx) => {
    await requireUser(ctx);
    return await ctx.storage.generateUploadUrl();
  },
});

const entryFields = {
  content: v.string(),
  mood: v.optional(mood),
  photoStorageId: v.optional(v.id("_storage")),
  meditationId: v.optional(v.string()),
  meditationType: v.optional(v.string()),
  prompt: v.optional(v.string()),
  tags: v.optional(v.array(v.string())),
  isFavorite: v.optional(v.boolean()),
};

export const create = mutation({
  args: { ...entryFields, createdAt: v.optional(v.number()) },
  handler: async (ctx, args) => {
    const user = await requireUser(ctx);
    if (args.content.length > MAX_CONTENT) throw new ConvexError("Entry too long");
    if (args.photoStorageId) await assertPhoto(ctx, args.photoStorageId);
    const now = Date.now();
    return await ctx.db.insert("journalEntries", {
      userId: user._id,
      ...args,
      wordCount: wordCount(args.content),
      createdAt: args.createdAt ?? now,
      updatedAt: now,
    });
  },
});

/**
 * Edit an entry. Unlike the Firestore overwrite, `createdAt` is preserved.
 * `removePhoto: true` deletes the stored photo.
 */
export const update = mutation({
  args: {
    id: v.id("journalEntries"),
    content: v.optional(v.string()),
    mood: v.optional(mood),
    photoStorageId: v.optional(v.id("_storage")),
    removePhoto: v.optional(v.boolean()),
    isFavorite: v.optional(v.boolean()),
    tags: v.optional(v.array(v.string())),
  },
  handler: async (ctx, { id, removePhoto, ...fields }) => {
    const user = await requireUser(ctx);
    const entry = await ownedEntry(ctx, user._id, id);
    if (fields.content !== undefined && fields.content.length > MAX_CONTENT) {
      throw new ConvexError("Entry too long");
    }
    const patch: Partial<Doc<"journalEntries">> = { updatedAt: Date.now() };
    if (fields.content !== undefined) {
      patch.content = fields.content;
      patch.wordCount = wordCount(fields.content);
    }
    if (fields.mood !== undefined) patch.mood = fields.mood;
    if (fields.isFavorite !== undefined) patch.isFavorite = fields.isFavorite;
    if (fields.tags !== undefined) patch.tags = fields.tags;
    if (fields.photoStorageId !== undefined || removePhoto) {
      if (fields.photoStorageId) await assertPhoto(ctx, fields.photoStorageId);
      if (entry.photoStorageId && entry.photoStorageId !== fields.photoStorageId) {
        await ctx.storage.delete(entry.photoStorageId);
      }
      patch.photoStorageId = removePhoto ? undefined : fields.photoStorageId;
      patch.legacyPhotoBase64 = undefined;
    }
    await ctx.db.patch(id, patch);
  },
});

export const remove = mutation({
  args: { id: v.id("journalEntries") },
  handler: async (ctx, { id }) => {
    const user = await requireUser(ctx);
    const entry = await ownedEntry(ctx, user._id, id);
    if (entry.photoStorageId) await ctx.storage.delete(entry.photoStorageId);
    await ctx.db.delete(id);
  },
});
