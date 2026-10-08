import { getAuthUserId } from "@convex-dev/auth/server";
import { ConvexError, v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { onboardingProfile } from "./schema";
import { definedOnly, requireUser } from "./lib/session";

/** Current user's profile (users/{uid}). Returns null when signed out. */
export const me = query({
  args: {},
  handler: async (ctx) => {
    const userId = await getAuthUserId(ctx);
    if (userId === null) return null;
    const user = await ctx.db.get(userId);
    if (user === null) return null;
    const avatarUrl = user.avatarStorageId ? await ctx.storage.getUrl(user.avatarStorageId) : null;
    return {
      _id: user._id,
      _creationTime: user._creationTime,
      email: user.email ?? null,
      firstName: user.firstName ?? null,
      displayName: user.displayName ?? user.name ?? null,
      avatarUrl: avatarUrl ?? user.photoURL ?? null,
      hasLegacyAvatarPending: user.legacyAvatarBase64 !== undefined,
      language: user.language ?? null,
      createdAt: user.createdAt ?? user._creationTime,
      lastLoginAt: user.lastLoginAt ?? null,
      onboardingCompleted: user.onboardingCompleted ?? false,
      onboardingCompletedAt: user.onboardingCompletedAt ?? null,
      onboarding: user.onboarding ?? null,
      hasBaseline: user.hasBaseline ?? false,
      subscription: user.subscription ?? null,
      lastSituation: user.lastSituation ?? null,
      lastExerciseType: user.lastExerciseType ?? null,
      totalExercisesCompleted: user.totalExercisesCompleted ?? 0,
      emailVerified: user.emailVerificationTime !== undefined,
      authProviders: {
        apple: user.appleSub !== undefined,
        google: user.googleSub !== undefined,
      },
      legacy: {
        linked: user.legacyFirebaseUid !== undefined,
        claimState: user.legacyClaimState ?? null,
      },
    };
  },
});

/** Call after each successful sign-in (replaces `lastLoginAt` updateData). */
export const recordLogin = mutation({
  args: { language: v.optional(v.string()) },
  handler: async (ctx, { language }) => {
    const user = await requireUser(ctx);
    const now = Date.now();
    await ctx.db.patch(user._id, definedOnly({ lastLoginAt: now, language, updatedAt: now }));
  },
});

/** EditProfileView: firstName / displayName / language (merge). */
export const updateProfile = mutation({
  args: {
    firstName: v.optional(v.string()),
    displayName: v.optional(v.string()),
    language: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const user = await requireUser(ctx);
    for (const value of [args.firstName, args.displayName]) {
      if (value !== undefined && value.length > 120) throw new ConvexError("Name too long");
    }
    await ctx.db.patch(
      user._id,
      definedOnly({
        firstName: args.firstName?.trim(),
        displayName: args.displayName?.trim(),
        name: args.displayName?.trim() ?? args.firstName?.trim(),
        language: args.language,
        updatedAt: Date.now(),
      })
    );
  },
});

/** Step 1 of avatar upload: POST the JPEG to the returned URL, get {storageId}. */
export const generateAvatarUploadUrl = mutation({
  args: {},
  handler: async (ctx) => {
    await requireUser(ctx);
    return await ctx.storage.generateUploadUrl();
  },
});

/** Step 2 of avatar upload (replaces profilePhotoBase64). Deletes the previous file. */
export const setAvatar = mutation({
  args: { storageId: v.id("_storage") },
  handler: async (ctx, { storageId }) => {
    const user = await requireUser(ctx);
    const meta = await ctx.db.system.get(storageId);
    if (meta === null) throw new ConvexError("Unknown file");
    if (meta.size > 2 * 1024 * 1024) throw new ConvexError("Avatar too large (max 2 MB)");
    if (user.avatarStorageId && user.avatarStorageId !== storageId) {
      await ctx.storage.delete(user.avatarStorageId);
    }
    await ctx.db.patch(user._id, {
      avatarStorageId: storageId,
      legacyAvatarBase64: undefined,
      updatedAt: Date.now(),
    });
  },
});

export const removeAvatar = mutation({
  args: {},
  handler: async (ctx) => {
    const user = await requireUser(ctx);
    if (user.avatarStorageId) await ctx.storage.delete(user.avatarStorageId);
    await ctx.db.patch(user._id, {
      avatarStorageId: undefined,
      legacyAvatarBase64: undefined,
      updatedAt: Date.now(),
    });
  },
});

/**
 * Onboarding answers (OptimizedFirebaseService / OnboardingV2FlowView
 * saveOverallDataToFirebase). Merges fields; `completed: true` also sets
 * onboardingCompleted + onboardingCompletedAt.
 */
export const saveOnboarding = mutation({
  args: {
    answers: v.optional(onboardingProfile),
    completed: v.optional(v.boolean()),
    hasBaseline: v.optional(v.boolean()),
  },
  handler: async (ctx, { answers, completed, hasBaseline }) => {
    const user = await requireUser(ctx);
    const now = Date.now();
    await ctx.db.patch(
      user._id,
      definedOnly({
        onboarding: answers ? { ...(user.onboarding ?? {}), ...definedOnly(answers) } : undefined,
        hasBaseline,
        onboardingCompleted: completed === true ? true : undefined,
        onboardingCompletedAt:
          completed === true ? (user.onboardingCompletedAt ?? now) : undefined,
        updatedAt: now,
      })
    );
  },
});

/**
 * Mirror of the RevenueCat entitlement (RevenueCatManager: `isPaid`).
 * Client-reported: informative only, never use it to gate server features.
 */
export const setSubscriptionStatus = mutation({
  args: { isPaid: v.boolean(), entitlementId: v.optional(v.string()) },
  handler: async (ctx, { isPaid, entitlementId }) => {
    const user = await requireUser(ctx);
    const current = user.subscription;
    if (current && current.isPaid === isPaid && current.entitlementId === entitlementId) return;
    await ctx.db.patch(user._id, {
      subscription: definedOnly({ isPaid, entitlementId, updatedAt: Date.now() }) as {
        isPaid: boolean;
        entitlementId?: string;
        updatedAt: number;
      },
    });
  },
});

/** AntiStressViewModel: situation picked. */
export const recordSituation = mutation({
  args: { situation: v.string() },
  handler: async (ctx, { situation }) => {
    const user = await requireUser(ctx);
    await ctx.db.patch(user._id, { lastSituation: situation, lastSituationAt: Date.now() });
  },
});
