import { ConvexError, v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { taskStatus, userTaskFields } from "./schema";
import { boundedLimit, requireUser } from "./lib/session";

function assertProgramDay(day: number) {
  if (!Number.isInteger(day) || day < 1 || day > 10000) throw new ConvexError("Invalid programDay");
}

// ---------------------------------------------------------------------------
// task_statuses/day_{N}
// ---------------------------------------------------------------------------

/** loadAllTaskStatuses – every program day, as {programDay, statuses{key: status}}. */
export const listStatuses = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    const rows = await ctx.db
      .query("taskStatuses")
      .withIndex("by_user_day", (q) => q.eq("userId", user._id))
      .take(400);
    return rows.map((row) => ({
      programDay: row.programDay,
      statuses: Object.fromEntries(row.statuses.map((s) => [s.key, s.status])) as Record<
        string,
        "done" | "todo" | "skipped"
      >,
      updatedAt: row.updatedAt,
    }));
  },
});

/** saveTaskStatus – set one key ("plan_<itemId>") for a program day (merge). */
export const setStatus = mutation({
  args: { programDay: v.number(), key: v.string(), status: taskStatus },
  handler: async (ctx, { programDay, key, status }) => {
    assertProgramDay(programDay);
    if (!key || key.length > 200) throw new ConvexError("Invalid status key");
    const user = await requireUser(ctx);
    const existing = await ctx.db
      .query("taskStatuses")
      .withIndex("by_user_day", (q) => q.eq("userId", user._id).eq("programDay", programDay))
      .unique();
    if (!existing) {
      await ctx.db.insert("taskStatuses", {
        userId: user._id,
        programDay,
        statuses: [{ key, status }],
        updatedAt: Date.now(),
      });
      return;
    }
    const statuses = existing.statuses.filter((s) => s.key !== key);
    statuses.push({ key, status });
    await ctx.db.patch(existing._id, { statuses, updatedAt: Date.now() });
  },
});

/** deleteTaskStatus – remove one key. */
export const clearStatus = mutation({
  args: { programDay: v.number(), key: v.string() },
  handler: async (ctx, { programDay, key }) => {
    const user = await requireUser(ctx);
    const existing = await ctx.db
      .query("taskStatuses")
      .withIndex("by_user_day", (q) => q.eq("userId", user._id).eq("programDay", programDay))
      .unique();
    if (!existing) return;
    await ctx.db.patch(existing._id, {
      statuses: existing.statuses.filter((s) => s.key !== key),
      updatedAt: Date.now(),
    });
  },
});

// ---------------------------------------------------------------------------
// completed_tasks
// ---------------------------------------------------------------------------

/**
 * ProgressAnalyticsService.recordTaskCompletion – idempotent per
 * (programDay, taskId), like the deterministic Firestore doc id.
 */
export const recordCompletion = mutation({
  args: {
    taskId: v.string(),
    habitId: v.optional(v.string()),
    exerciseId: v.optional(v.string()),
    programDay: v.number(),
    durationActualSeconds: v.optional(v.number()),
    completedAt: v.optional(v.number()),
    source: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    assertProgramDay(args.programDay);
    const user = await requireUser(ctx);
    const row = {
      taskId: args.taskId,
      habitId: args.habitId,
      exerciseId: args.exerciseId,
      programDay: args.programDay,
      durationActualSeconds: args.durationActualSeconds,
      completedAt: args.completedAt ?? Date.now(),
      source: args.source ?? "tasks_v2",
    };
    const existing = await ctx.db
      .query("completedTasks")
      .withIndex("by_user_day_task", (q) =>
        q.eq("userId", user._id).eq("programDay", args.programDay).eq("taskId", args.taskId)
      )
      .first();
    if (existing) {
      await ctx.db.patch(existing._id, row);
      return existing._id;
    }
    return await ctx.db.insert("completedTasks", { userId: user._id, ...row });
  },
});

/** Undo a completion (when a task goes back to "todo"). */
export const removeCompletion = mutation({
  args: { programDay: v.number(), taskId: v.string() },
  handler: async (ctx, { programDay, taskId }) => {
    const user = await requireUser(ctx);
    const rows = await ctx.db
      .query("completedTasks")
      .withIndex("by_user_day_task", (q) =>
        q.eq("userId", user._id).eq("programDay", programDay).eq("taskId", taskId)
      )
      .take(20);
    for (const row of rows) await ctx.db.delete(row._id);
  },
});

/** completed_tasks with completedAt >= since (newest first, optional limit). */
export const listCompletions = query({
  args: { since: v.optional(v.number()), until: v.optional(v.number()), limit: v.optional(v.number()) },
  handler: async (ctx, { since, until, limit }) => {
    const user = await requireUser(ctx);
    const q = ctx.db
      .query("completedTasks")
      .withIndex("by_user_completedAt", (q) => {
        const base = q.eq("userId", user._id).gte("completedAt", since ?? 0);
        return until !== undefined ? base.lt("completedAt", until) : base;
      })
      .order("desc");
    return await q.take(boundedLimit(limit, 250, 1000));
  },
});

// ---------------------------------------------------------------------------
// users/{uid}/tasks (legacy TaskItem list, HomeViewModel)
// ---------------------------------------------------------------------------

export const listUserTasks = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    return await ctx.db
      .query("userTasks")
      .withIndex("by_user_createdAt", (q) => q.eq("userId", user._id))
      .take(250);
  },
});

export const upsertUserTask = mutation({
  args: { id: v.optional(v.id("userTasks")), ...userTaskFields },
  handler: async (ctx, { id, ...fields }) => {
    const user = await requireUser(ctx);
    if (id) {
      const existing = await ctx.db.get(id);
      if (!existing || existing.userId !== user._id) throw new ConvexError("Task not found");
      await ctx.db.patch(id, fields);
      return id;
    }
    return await ctx.db.insert("userTasks", { userId: user._id, ...fields, createdAt: Date.now() });
  },
});

export const removeUserTask = mutation({
  args: { id: v.id("userTasks") },
  handler: async (ctx, { id }) => {
    const user = await requireUser(ctx);
    const existing = await ctx.db.get(id);
    if (!existing || existing.userId !== user._id) throw new ConvexError("Task not found");
    await ctx.db.delete(id);
  },
});

/** Starts a new program while preserving lifetime completion totals and history. */
export const resetProgramData = mutation({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    const [statuses, tracking] = await Promise.all([
      ctx.db
        .query("taskStatuses")
        .withIndex("by_user_day", (q) => q.eq("userId", user._id))
        .take(400),
      ctx.db
        .query("habitTracking")
        .withIndex("by_user_habit", (q) => q.eq("userId", user._id))
        .take(16),
    ]);
    for (const status of statuses) await ctx.db.delete(status._id);
    for (const habit of tracking) {
      await ctx.db.patch(habit._id, {
        completedDays: [],
        currentStreak: 0,
        last7Days: [false, false, false, false, false, false, false],
        lastCompletedAt: undefined,
        lastCompletedDate: undefined,
        updatedAt: Date.now(),
      });
    }
  },
});
