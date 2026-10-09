import { v } from "convex/values";
import { internal } from "./_generated/api";
import { Doc, Id } from "./_generated/dataModel";
import { ActionCtx, httpAction, internalMutation, MutationCtx } from "./_generated/server";

/**
 * Server-side source of truth for the "pro" entitlement, which gates the paid AI
 * features (assistant.ts, faceScan.ts). Written by the RevenueCat webhook
 * (POST /revenuecat/webhook) and, when the webhook has not arrived yet (purchase a
 * few seconds ago, subscribers from before the webhook existed), by a throttled
 * lookup in the RevenueCat REST API. The client-reported `users.subscription`
 * mirror is never used here.
 *
 * Env: REVENUECAT_WEBHOOK_AUTH (required, exact Authorization header value set in
 * the RevenueCat dashboard), REVENUECAT_SECRET_API_KEY (optional, enables the REST
 * fallback), REVENUECAT_ENTITLEMENT_ID (optional, default "pro").
 */

const restCheckInterval = 60_000;

function entitlementId(): string {
  return process.env.REVENUECAT_ENTITLEMENT_ID || "pro";
}

export function hasActiveEntitlement(user: Doc<"users">, now: number): boolean {
  const entitlement = user.entitlement;
  if (!entitlement) return false;
  return entitlement.expiresAt === null || entitlement.expiresAt > now;
}

/** Constant-time comparison so the secret cannot be guessed byte by byte. */
function safeEqual(a: string, b: string): boolean {
  const left = new TextEncoder().encode(a);
  const right = new TextEncoder().encode(b);
  let diff = left.length ^ right.length;
  for (let i = 0; i < Math.max(left.length, right.length); i++) {
    diff |= (left[i] ?? 0) ^ (right[i] ?? 0);
  }
  return diff === 0;
}

const stringOrNull = v.optional(v.union(v.string(), v.null()));
const numberOrNull = v.optional(v.union(v.number(), v.null()));

/** The subset of the RevenueCat webhook `event` object this backend reads. */
const revenueCatEvent = v.object({
  id: v.optional(v.string()),
  type: v.string(),
  app_user_id: stringOrNull,
  original_app_user_id: stringOrNull,
  aliases: v.optional(v.union(v.array(v.string()), v.null())),
  transferred_from: v.optional(v.union(v.array(v.string()), v.null())),
  transferred_to: v.optional(v.union(v.array(v.string()), v.null())),
  entitlement_ids: v.optional(v.union(v.array(v.string()), v.null())),
  expiration_at_ms: numberOrNull,
  event_timestamp_ms: numberOrNull,
  product_id: stringOrNull,
  store: stringOrNull,
  environment: stringOrNull,
});

async function findUser(ctx: MutationCtx, ids: Array<string | null | undefined>) {
  for (const raw of ids) {
    if (!raw) continue;
    const id = ctx.db.normalizeId("users", raw);
    const user = id ? await ctx.db.get(id) : null;
    if (user) return user;
  }
  return null;
}

/** Ignores events older than the one already applied (RevenueCat may retry out of order). */
async function writeEntitlement(
  ctx: MutationCtx,
  user: Doc<"users">,
  entitlement: NonNullable<Doc<"users">["entitlement"]>
) {
  if (user.entitlement && user.entitlement.eventAt > entitlement.eventAt) return false;
  await ctx.db.patch(user._id, { entitlement });
  return true;
}

export const applyRevenueCatEvent = internalMutation({
  args: { event: revenueCatEvent },
  handler: async (ctx, { event }) => {
    const now = Date.now();
    const eventAt = event.event_timestamp_ms ?? now;

    if (event.type === "TRANSFER") {
      // The purchases moved to another app user: revoke the old owner, let the new
      // one be confirmed by its next REST lookup (the event carries no expiry).
      for (const raw of event.transferred_from ?? []) {
        const user = await findUser(ctx, [raw]);
        if (user) {
          await writeEntitlement(ctx, user, { expiresAt: eventAt, source: "webhook", eventAt, updatedAt: now });
        }
      }
      for (const raw of event.transferred_to ?? []) {
        const user = await findUser(ctx, [raw]);
        if (user) await ctx.db.patch(user._id, { entitlementCheckedAt: undefined });
      }
      return { applied: true };
    }

    const ids = event.entitlement_ids;
    if (Array.isArray(ids) && !ids.includes(entitlementId())) return { applied: false, reason: "other_entitlement" };
    // TEST, SUBSCRIBER_ALIAS… carry no entitlement change.
    if (!("expiration_at_ms" in event) || event.type === "TEST") return { applied: false, reason: "ignored_type" };

    const user = await findUser(ctx, [event.app_user_id, event.original_app_user_id, ...(event.aliases ?? [])]);
    if (!user) return { applied: false, reason: "unknown_user" };

    let expiresAt = event.expiration_at_ms ?? null;
    if (event.type === "EXPIRATION") {
      // After a product change, the old product expires while the new one keeps access.
      const current = user.entitlement;
      if (current?.productId && event.product_id && current.productId !== event.product_id && hasActiveEntitlement(user, now)) {
        return { applied: false, reason: "other_product" };
      }
      expiresAt = Math.min(expiresAt ?? eventAt, eventAt);
    }
    const applied = await writeEntitlement(ctx, user, {
      expiresAt,
      ...(event.product_id ? { productId: event.product_id } : {}),
      ...(event.store ? { store: event.store } : {}),
      ...(event.environment ? { environment: event.environment } : {}),
      source: "webhook",
      eventAt,
      updatedAt: now,
    });
    return { applied };
  },
});

/** POST /revenuecat/webhook */
export const revenueCatWebhook = httpAction(async (ctx, request) => {
  const secret = process.env.REVENUECAT_WEBHOOK_AUTH;
  if (!secret) return new Response("Webhook not configured", { status: 503 });
  const header = request.headers.get("Authorization") ?? "";
  if (!safeEqual(header, secret) && !safeEqual(header, `Bearer ${secret}`)) {
    return new Response("Unauthorized", { status: 401 });
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }
  const raw = typeof body === "object" && body !== null && "event" in body ? body.event : null;
  if (typeof raw !== "object" || raw === null || typeof (raw as { type?: unknown }).type !== "string") {
    return new Response("Invalid event", { status: 400 });
  }
  const event = pickEvent(raw as Record<string, unknown>);
  const result = await ctx.runMutation(internal.subscriptions.applyRevenueCatEvent, { event });
  return Response.json(result);
});

/** Keeps only the validated fields (the webhook payload has many more). */
function pickEvent(raw: Record<string, unknown>) {
  const str = (key: string) => (typeof raw[key] === "string" ? (raw[key] as string) : null);
  const num = (key: string) => (typeof raw[key] === "number" ? (raw[key] as number) : null);
  const list = (key: string) =>
    Array.isArray(raw[key]) ? (raw[key] as unknown[]).filter((x): x is string => typeof x === "string") : null;
  const event: Record<string, unknown> = {
    type: raw.type as string,
    app_user_id: str("app_user_id"),
    original_app_user_id: str("original_app_user_id"),
    aliases: list("aliases"),
    transferred_from: list("transferred_from"),
    transferred_to: list("transferred_to"),
    entitlement_ids: list("entitlement_ids"),
    event_timestamp_ms: num("event_timestamp_ms"),
    product_id: str("product_id"),
    store: str("store"),
    environment: str("environment"),
  };
  if (str("id")) event.id = str("id");
  // Absent vs null matters: null means "never expires" (lifetime purchase).
  if ("expiration_at_ms" in raw) event.expiration_at_ms = num("expiration_at_ms");
  return event as typeof revenueCatEvent.type;
}

// ---------------------------------------------------------------------------
// REST fallback
// ---------------------------------------------------------------------------

export const startRestCheck = internalMutation({
  args: { userId: v.id("users") },
  handler: async (ctx, { userId }) => {
    const user = await ctx.db.get(userId);
    const now = Date.now();
    if (!user || (user.entitlementCheckedAt && now - user.entitlementCheckedAt < restCheckInterval)) return false;
    await ctx.db.patch(userId, { entitlementCheckedAt: now });
    return true;
  },
});

export const saveRestEntitlement = internalMutation({
  args: {
    userId: v.id("users"),
    expiresAt: v.union(v.number(), v.null()),
    productId: v.optional(v.string()),
  },
  handler: async (ctx, { userId, expiresAt, productId }) => {
    const user = await ctx.db.get(userId);
    if (!user) return;
    const now = Date.now();
    await ctx.db.patch(userId, {
      entitlement: { expiresAt, ...(productId ? { productId } : {}), source: "api", eventAt: now, updatedAt: now },
    });
  },
});

/**
 * Asks RevenueCat directly (GET /v1/subscribers/{id}) when the webhook has not
 * granted access. At most once per minute per user. Returns true if the user now
 * holds an active entitlement.
 */
export async function refreshEntitlementFromRevenueCat(ctx: ActionCtx, userId: Id<"users">): Promise<boolean> {
  const apiKey = process.env.REVENUECAT_SECRET_API_KEY;
  if (!apiKey) return false;
  if (!(await ctx.runMutation(internal.subscriptions.startRestCheck, { userId }))) return false;

  const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`, {
    headers: { Authorization: `Bearer ${apiKey}`, Accept: "application/json" },
  }).catch(() => null);
  if (!response?.ok) return false;
  const body: unknown = await response.json().catch(() => null);
  const entitlement = (body as { subscriber?: { entitlements?: Record<string, unknown> } } | null)?.subscriber
    ?.entitlements?.[entitlementId()] as
    | { expires_date?: string | null; grace_period_expires_date?: string | null; product_identifier?: string }
    | undefined;
  if (!entitlement) return false;

  const dates = [entitlement.expires_date, entitlement.grace_period_expires_date];
  const expiresAt =
    entitlement.expires_date === null || entitlement.expires_date === undefined
      ? null
      : Math.max(...dates.filter((d): d is string => typeof d === "string").map((d) => Date.parse(d) || 0));
  await ctx.runMutation(internal.subscriptions.saveRestEntitlement, {
    userId,
    expiresAt,
    productId: entitlement.product_identifier,
  });
  return expiresAt === null || expiresAt > Date.now();
}
