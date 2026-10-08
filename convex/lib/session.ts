import { getAuthUserId } from "@convex-dev/auth/server";
import { ConvexError } from "convex/values";
import { Id } from "../_generated/dataModel";
import { ActionCtx, MutationCtx, QueryCtx } from "../_generated/server";

/** Returns the authenticated Convex user id or throws. */
export async function requireUserId(
  ctx: QueryCtx | MutationCtx | ActionCtx
): Promise<Id<"users">> {
  const userId = await getAuthUserId(ctx);
  if (userId === null) throw new ConvexError("Authentication required");
  return userId;
}

/**
 * For queries/mutations: also checks the user row still exists (a JWT stays
 * valid up to 1h after account deletion; this prevents orphan writes).
 */
export async function requireUser(ctx: QueryCtx | MutationCtx) {
  const userId = await requireUserId(ctx);
  const user = await ctx.db.get(userId);
  if (user === null) throw new ConvexError("Authentication required");
  return user;
}

/** Removes keys whose value is `undefined` (Convex patch() would unset them). */
export function definedOnly<T extends Record<string, unknown>>(value: T): Partial<T> {
  const result: Record<string, unknown> = {};
  for (const [key, entry] of Object.entries(value)) {
    if (entry !== undefined) result[key] = entry;
  }
  return result as Partial<T>;
}

export const DATE_KEY = /^\d{4}-\d{2}-\d{2}$/;

/** Validates a "yyyy-MM-dd" day key (the Firestore document id scheme). */
export function assertDateKey(date: string): void {
  if (!DATE_KEY.test(date)) throw new ConvexError(`Invalid date key: ${date}`);
}

/** Keeps list queries predictable even when older clients omit a limit. */
export function boundedLimit(limit: number | undefined, fallback: number, maximum: number): number {
  if (limit === undefined) return fallback;
  if (!Number.isFinite(limit)) throw new ConvexError("Invalid limit");
  return Math.min(Math.max(1, Math.floor(limit)), maximum);
}
