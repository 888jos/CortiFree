import { ConvexError, v } from "convex/values";
import { Id } from "./_generated/dataModel";
import { mutation, MutationCtx, query } from "./_generated/server";
import { requireUser } from "./lib/session";

async function ownedTodo(ctx: MutationCtx, userId: Id<"users">, id: Id<"dailyTodos">) {
  const todo = await ctx.db.get(id);
  if (!todo || todo.userId !== userId) throw new ConvexError("Todo not found");
  return todo;
}

function cleanTitle(title: string) {
  const trimmed = title.trim();
  if (!trimmed || trimmed.length > 500) throw new ConvexError("Invalid title");
  return trimmed;
}

/** DailyTodoService.fetchTodos – active todos, oldest first. */
export const listActive = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    return await ctx.db
      .query("dailyTodos")
      .withIndex("by_user_active", (q) => q.eq("userId", user._id).eq("isActive", true))
      .take(100);
  },
});

export const create = mutation({
  args: { title: v.string() },
  handler: async (ctx, { title }) => {
    const user = await requireUser(ctx);
    return await ctx.db.insert("dailyTodos", {
      userId: user._id,
      title: cleanTitle(title),
      isCompleted: false,
      isActive: true,
      createdAt: Date.now(),
    });
  },
});

export const setCompleted = mutation({
  args: { id: v.id("dailyTodos"), isCompleted: v.boolean() },
  handler: async (ctx, { id, isCompleted }) => {
    const user = await requireUser(ctx);
    await ownedTodo(ctx, user._id, id);
    await ctx.db.patch(id, { isCompleted });
  },
});

export const rename = mutation({
  args: { id: v.id("dailyTodos"), title: v.string() },
  handler: async (ctx, { id, title }) => {
    const user = await requireUser(ctx);
    await ownedTodo(ctx, user._id, id);
    await ctx.db.patch(id, { title: cleanTitle(title) });
  },
});

/** Soft delete (isActive = false), like the Firestore version. */
export const archive = mutation({
  args: { id: v.id("dailyTodos") },
  handler: async (ctx, { id }) => {
    const user = await requireUser(ctx);
    await ownedTodo(ctx, user._id, id);
    await ctx.db.patch(id, { isActive: false });
  },
});
