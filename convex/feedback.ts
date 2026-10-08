import { ConvexError, v } from "convex/values";
import { mutation } from "./_generated/server";
import { requireUser } from "./lib/session";

/** Upload URL for an optional bug-report screenshot (JPEG). */
export const generateScreenshotUploadUrl = mutation({
  args: {},
  handler: async (ctx) => {
    await requireUser(ctx);
    return await ctx.storage.generateUploadUrl();
  },
});

/**
 * SettingsView bug report (bug_reports). Write-only: there is intentionally
 * no public query; reports are read from the Convex dashboard.
 */
export const submitBugReport = mutation({
  args: {
    description: v.string(),
    appVersion: v.optional(v.string()),
    iosVersion: v.optional(v.string()),
    deviceModel: v.optional(v.string()),
    language: v.optional(v.string()),
    screenshotStorageId: v.optional(v.id("_storage")),
  },
  handler: async (ctx, args) => {
    const user = await requireUser(ctx);
    const description = args.description.trim();
    if (!description || description.length > 10000) throw new ConvexError("Invalid description");
    if (args.screenshotStorageId) {
      const meta = await ctx.db.system.get(args.screenshotStorageId);
      if (!meta || meta.size > 5 * 1024 * 1024) throw new ConvexError("Invalid screenshot");
    }
    await ctx.db.insert("bugReports", {
      userId: user._id,
      userEmail: user.email,
      ...args,
      description,
      status: "new",
      createdAt: Date.now(),
    });
  },
});
