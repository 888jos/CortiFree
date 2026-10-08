import { ConvexError, v } from "convex/values";
import { importPKCS8, SignJWT } from "jose";
import { internal } from "./_generated/api";
import { Doc, Id, TableNames } from "./_generated/dataModel";
import {
  action,
  internalMutation,
  mutation,
  MutationCtx,
  query,
} from "./_generated/server";
import { applyLegacyProfile } from "./migration/claim";
import { requireUser, requireUserId } from "./lib/session";

// ===========================================================================
// Identity sync (called by the auth providers in convex/auth.ts)
// ===========================================================================

export const syncIdentityFields = internalMutation({
  args: {
    userId: v.id("users"),
    appleSub: v.optional(v.string()),
    googleSub: v.optional(v.string()),
    email: v.optional(v.string()),
    emailVerified: v.optional(v.boolean()),
    firstName: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const user = await ctx.db.get(args.userId);
    if (!user) return;
    const now = Date.now();
    const patch: Partial<Doc<"users">> = { lastLoginAt: now, updatedAt: now };
    if (args.appleSub && !user.appleSub) patch.appleSub = args.appleSub;
    if (args.googleSub && !user.googleSub) patch.googleSub = args.googleSub;
    if (args.email && !user.email) {
      patch.email = args.email;
      patch.emailCanonical = args.email;
    }
    const email = patch.email ?? user.email;
    if (args.emailVerified && args.email && email === args.email && !user.emailVerificationTime) {
      // Apple / Google verified this address: allows claiming legacy data by email.
      patch.emailVerificationTime = now;
    }
    if (args.firstName && !user.firstName) {
      patch.firstName = args.firstName;
      patch.name = user.name ?? args.firstName;
    }
    await ctx.db.patch(user._id, patch);
  },
});

// ===========================================================================
// Email ownership verification (password accounts → legacy claim by email)
// ===========================================================================

async function sha256Hex(input: string) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export const storeEmailCode = internalMutation({
  args: { userId: v.id("users"), codeHash: v.string() },
  handler: async (ctx, { userId, codeHash }) => {
    const user = await ctx.db.get(userId);
    if (!user?.email) throw new ConvexError("No email on this account");
    if (user.emailVerificationTime) throw new ConvexError("Email already verified");
    const previous = await ctx.db
      .query("emailVerificationCodes")
      .withIndex("by_user", (q) => q.eq("userId", userId))
      .take(10);
    const latest = previous.reduce((max, row) => Math.max(max, row._creationTime), 0);
    if (Date.now() - latest < 60_000) throw new ConvexError("Please wait before requesting a new code");
    for (const row of previous) await ctx.db.delete(row._id);
    await ctx.db.insert("emailVerificationCodes", {
      userId,
      email: user.email,
      codeHash,
      expiresAt: Date.now() + 15 * 60_000,
      attemptsLeft: 5,
    });
    return { email: user.email };
  },
});

/** Sends a 6-digit code to the account email (Resend; needs RESEND_API_KEY). */
export const sendEmailVerificationCode = action({
  args: {},
  handler: async (ctx) => {
    const userId = await requireUserId(ctx);
    const apiKey = process.env.RESEND_API_KEY;
    if (!apiKey) throw new ConvexError("Email sending is not configured");
    const bytes = new Uint32Array(1);
    crypto.getRandomValues(bytes);
    const code = String(bytes[0] % 1_000_000).padStart(6, "0");
    const { email } = await ctx.runMutation(internal.account.storeEmailCode, {
      userId,
      codeHash: await sha256Hex(code),
    });
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        from: process.env.AUTH_EMAIL_FROM ?? "CortiFree <onboarding@resend.dev>",
        to: [email],
        subject: "CortiFree – vérification de votre email / verify your email",
        text: `Code CortiFree : ${code}\nCortiFree code: ${code}\n\n15 min.`,
      }),
    });
    if (!response.ok) throw new ConvexError("Could not send the verification email");
    return { sent: true };
  },
});

export const verifyEmail = mutation({
  args: { code: v.string() },
  handler: async (ctx, { code }) => {
    const user = await requireUser(ctx);
    const row = await ctx.db
      .query("emailVerificationCodes")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .first();
    if (!row || row.expiresAt < Date.now() || row.attemptsLeft <= 0 || row.email !== user.email) {
      throw new ConvexError("Invalid or expired code");
    }
    if ((await sha256Hex(code.trim())) !== row.codeHash) {
      await ctx.db.patch(row._id, { attemptsLeft: row.attemptsLeft - 1 });
      // Returned (not thrown) so the attempt decrement is committed.
      return { verified: false };
    }
    await ctx.db.delete(row._id);
    await ctx.db.patch(user._id, { emailVerificationTime: Date.now() });
    return { verified: true };
  },
});

// ===========================================================================
// Legacy (Firestore) data claim
// ===========================================================================

async function findClaimableLegacyUser(ctx: MutationCtx, user: Doc<"users">) {
  const candidates: (Doc<"legacyUsers"> | null)[] = [];
  if (user.appleSub) {
    candidates.push(
      await ctx.db
        .query("legacyUsers")
        .withIndex("by_appleSub", (q) => q.eq("appleSub", user.appleSub))
        .first()
    );
  }
  if (user.googleSub) {
    candidates.push(
      await ctx.db
        .query("legacyUsers")
        .withIndex("by_googleSub", (q) => q.eq("googleSub", user.googleSub))
        .first()
    );
  }
  // Email match only when this account proved it owns the address.
  if (user.emailCanonical && user.emailVerificationTime) {
    candidates.push(
      await ctx.db
        .query("legacyUsers")
        .withIndex("by_emailCanonical", (q) => q.eq("emailCanonical", user.emailCanonical))
        .first()
    );
  }
  return candidates.find((c) => c !== null && c.claimedByUserId === undefined) ?? null;
}

/**
 * Call once after sign-in (and again after verifyEmail for password users).
 * Links the imported Firebase account (matched by Apple sub, Google sub, or a
 * verified email) and moves its data into the app tables in the background.
 */
export const claimLegacyData = mutation({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    if (user.legacyFirebaseUid) {
      return { status: user.legacyClaimState === "running" ? "running" : "already_claimed" } as const;
    }
    const legacy = await findClaimableLegacyUser(ctx, user);
    if (!legacy) {
      return {
        status: "nothing_to_claim",
        needsEmailVerification: !!user.email && !user.emailVerificationTime,
      } as const;
    }
    const now = Date.now();
    await ctx.db.patch(legacy._id, { claimedByUserId: user._id, claimedAt: now });
    await ctx.db.patch(user._id, {
      legacyFirebaseUid: legacy.firebaseUid,
      legacyClaimState: "running",
    });
    const fresh = (await ctx.db.get(user._id))!;
    await applyLegacyProfile(ctx, fresh, legacy);
    await ctx.scheduler.runAfter(0, internal.migration.claim.claimBatch, {
      userId: user._id,
      firebaseUid: legacy.firebaseUid,
    });
    return { status: "started" } as const;
  },
});

/** Poll after claimLegacyData returned "started" (status "done" when finished). */
export const legacyClaimStatus = query({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    return {
      linked: user.legacyFirebaseUid !== undefined,
      state: user.legacyClaimState ?? null,
      claimedAt: user.legacyClaimedAt ?? null,
    };
  },
});

// ===========================================================================
// Account deletion (App Store guideline 5.1.1(v))
// ===========================================================================

/** Every user-owned table and an index whose first field is `userId`. */
const USER_TABLES: ReadonlyArray<[TableNames, string]> = [
  ["userSettings", "by_user"],
  ["habitTracking", "by_user_habit"],
  ["habitCompletions", "by_user_habit_date"],
  ["taskStatuses", "by_user_day"],
  ["completedTasks", "by_user_completedAt"],
  ["exerciseSessions", "by_user_completedAt"],
  ["dailyCheckins", "by_user_date"],
  ["dailyMoods", "by_user_date"],
  ["journalEntries", "by_user_createdAt"],
  ["achievements", "by_user_achievement"],
  ["habitBadges", "by_user_habit_level"],
  ["personalPlans", "by_user"],
  ["baselines", "by_user"],
  ["userStats", "by_user"],
  ["userTasks", "by_user_createdAt"],
  ["dailyTodos", "by_user_active"],
  ["bugReports", "by_user"],
  ["archivedRecords", "by_user"],
  ["emailVerificationCodes", "by_user"],
];

const DELETE_BATCH = 200;

/** Deletes one batch; returns done=true once the user row itself is gone. */
export const deleteUserDataBatch = internalMutation({
  args: { userId: v.id("users") },
  handler: async (ctx, { userId }) => {
    let budget = DELETE_BATCH;
    for (const [table, index] of USER_TABLES) {
      // Generic loop over heterogeneous tables: index names are checked by the
      // list above, so we step outside the typed query builder here.
      const rows = (await ctx.db
        .query(table)
        .withIndex(index as never, (q: any) => q.eq("userId", userId))
        .take(budget)) as Array<Doc<TableNames> & Record<string, unknown>>;
      for (const row of rows) {
        for (const field of ["photoStorageId", "screenshotStorageId"]) {
          const storageId = row[field] as Id<"_storage"> | undefined;
          if (storageId) await ctx.storage.delete(storageId).catch(() => undefined);
        }
        await ctx.db.delete(row._id);
      }
      budget -= rows.length;
      if (budget <= 0) return { done: false };
    }

    const user = await ctx.db.get(userId);
    if (user?.legacyFirebaseUid) {
      // Unclaimed leftovers of the linked Firebase account.
      const leftovers = await ctx.db
        .query("legacyRecords")
        .withIndex("by_firebaseUid", (q) => q.eq("firebaseUid", user.legacyFirebaseUid))
        .take(budget);
      for (const row of leftovers) await ctx.db.delete(row._id);
      if (leftovers.length === budget) return { done: false };
    }
    const linkedLegacyUsers = await ctx.db
      .query("legacyUsers")
      .withIndex("by_claimedByUserId", (q) => q.eq("claimedByUserId", userId))
      .take(10);
    for (const legacy of linkedLegacyUsers) {
      await ctx.db.delete(legacy._id);
    }
    if (linkedLegacyUsers.length === 10) return { done: false };

    // Convex Auth rows
    const accounts = await ctx.db
      .query("authAccounts")
      .withIndex("userIdAndProvider", (q) => q.eq("userId", userId))
      .take(20);
    for (const account of accounts) {
      for (const code of await ctx.db
        .query("authVerificationCodes")
        .withIndex("accountId", (q) => q.eq("accountId", account._id))
        .take(20)) {
        await ctx.db.delete(code._id);
      }
      const codesRemain = await ctx.db
        .query("authVerificationCodes")
        .withIndex("accountId", (q) => q.eq("accountId", account._id))
        .first();
      if (codesRemain) return { done: false };
      await ctx.db.delete(account._id);
    }
    if (accounts.length === 20) return { done: false };
    const sessions = await ctx.db
      .query("authSessions")
      .withIndex("userId", (q) => q.eq("userId", userId))
      .take(100);
    for (const session of sessions) {
      for (const token of await ctx.db
        .query("authRefreshTokens")
        .withIndex("sessionId", (q) => q.eq("sessionId", session._id))
        .take(20)) {
        await ctx.db.delete(token._id);
      }
      const tokensRemain = await ctx.db
        .query("authRefreshTokens")
        .withIndex("sessionId", (q) => q.eq("sessionId", session._id))
        .first();
      if (tokensRemain) return { done: false };
      await ctx.db.delete(session._id);
    }
    if (sessions.length === 100) return { done: false };

    if (user) {
      if (user.avatarStorageId) await ctx.storage.delete(user.avatarStorageId).catch(() => undefined);
      await ctx.db.delete(user._id);
    }
    return { done: true };
  },
});

async function revokeAppleToken(authorizationCode: string): Promise<boolean> {
  const teamId = process.env.APPLE_TEAM_ID;
  const keyId = process.env.APPLE_KEY_ID;
  const privateKey = process.env.APPLE_PRIVATE_KEY;
  const clientId = (process.env.APPLE_BUNDLE_ID ?? "com.solstys.cortifree").split(",")[0].trim();
  if (!teamId || !keyId || !privateKey) return false;

  const key = await importPKCS8(privateKey.replace(/\\n/g, "\n"), "ES256");
  const clientSecret = await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt()
    .setExpirationTime("5m")
    .setAudience("https://appleid.apple.com")
    .setSubject(clientId)
    .sign(key);

  const tokenResponse = await fetch("https://appleid.apple.com/auth/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      code: authorizationCode,
      grant_type: "authorization_code",
    }),
  });
  if (!tokenResponse.ok) return false;
  const tokens = (await tokenResponse.json()) as { refresh_token?: string; access_token?: string };
  const token = tokens.refresh_token ?? tokens.access_token;
  if (!token) return false;
  const revokeResponse = await fetch("https://appleid.apple.com/auth/revoke", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      token,
      token_type_hint: tokens.refresh_token ? "refresh_token" : "access_token",
    }),
  });
  return revokeResponse.ok;
}

/**
 * Permanently deletes the signed-in account: every app row, stored files,
 * imported legacy data, and Convex Auth accounts/sessions. For Apple users,
 * pass a fresh `authorizationCode` from a new ASAuthorization request so the
 * Sign in with Apple token is revoked (needs APPLE_TEAM_ID / APPLE_KEY_ID /
 * APPLE_PRIVATE_KEY). Afterwards the client must drop its stored tokens.
 */
export const deleteMyAccount = action({
  args: { appleAuthorizationCode: v.optional(v.string()) },
  handler: async (ctx, { appleAuthorizationCode }) => {
    const userId = await requireUserId(ctx);
    let appleTokenRevoked = false;
    if (appleAuthorizationCode) {
      try {
        appleTokenRevoked = await revokeAppleToken(appleAuthorizationCode);
      } catch (error) {
        console.error("Apple token revocation failed", error);
      }
    }
    for (let i = 0; i < 1000; i += 1) {
      const { done } = await ctx.runMutation(internal.account.deleteUserDataBatch, { userId });
      if (done) {
        await ctx.scheduler.runAfter(0, internal.recovery.removeFromOneSignal, { userId });
        return { deleted: true, appleTokenRevoked };
      }
    }
    throw new ConvexError("Account deletion did not finish, please retry");
  },
});
