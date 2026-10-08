import { v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { settingsFields } from "./schema";
import { definedOnly, requireUser } from "./lib/session";

/** users/{uid}/settings/preferences (null if never saved). */
export const get = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    return await ctx.db
      .query("userSettings")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .unique();
  },
});

/**
 * Merge-upsert (setData(merge: true)). Only provided top-level fields change;
 * nested objects (notifications / experience / privacy) are replaced whole.
 * Pass `null` for morning/eveningReminderTime to clear them.
 */
export const save = mutation({
  args: v.object(settingsFields),
  handler: async (ctx, args) => {
    const user = await requireUser(ctx);
    const existing = await ctx.db
      .query("userSettings")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .unique();
    const patch = { ...definedOnly(args), updatedAt: Date.now() };
    if (existing) {
      await ctx.db.patch(existing._id, patch);
      return existing._id;
    }
    return await ctx.db.insert("userSettings", { userId: user._id, ...patch });
  },
});
