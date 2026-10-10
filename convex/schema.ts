import { authTables } from "@convex-dev/auth/server";
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

/**
 * CortiFree data model (replaces Firebase Auth + Firestore).
 *
 * - Auth tables come from Convex Auth (`authTables`); `users` is extended with
 *   the old `users/{uid}` profile fields and identity link keys.
 * - Every user-owned table carries `userId: v.id("users")` and an index whose
 *   first field is `userId` (used for scoping and account deletion).
 * - Day keys are "yyyy-MM-dd" strings computed on the device (local calendar),
 *   exactly like the old Firestore document ids. Timestamps are epoch ms.
 * - `legacyUsers` / `legacyRecords` / `migrationRuns` are private staging
 *   tables for the Firestore import; no public function reads them.
 */

export const mood = v.union(
  v.literal("awful"),
  v.literal("angry"),
  v.literal("low"),
  v.literal("okay"),
  v.literal("good"),
  v.literal("amazing")
);

export const taskStatus = v.union(v.literal("done"), v.literal("todo"), v.literal("skipped"));

export const badgeLevel = v.union(
  v.literal("bronze"),
  v.literal("silver"),
  v.literal("gold"),
  v.literal("diamond")
);

export const planGoal = v.union(
  v.literal("stress"),
  v.literal("sleep"),
  v.literal("energy"),
  v.literal("focus"),
  v.literal("emotional")
);

const reminderSlot = v.object({ enabled: v.boolean(), time: v.string() });

export const settingsFields = {
  // UserSettings (Models/UserSettings.swift)
  programStartDate: v.optional(v.number()),
  wakeUpTime: v.optional(v.string()),
  bedTime: v.optional(v.string()),
  preferredSportActivities: v.optional(v.array(v.string())),
  preferredNatureActivities: v.optional(v.array(v.string())),
  preferredSocialActivities: v.optional(v.array(v.string())),
  notificationsEnabled: v.optional(v.boolean()),
  morningReminderTime: v.optional(v.union(v.string(), v.null())),
  eveningReminderTime: v.optional(v.union(v.string(), v.null())),
  // SettingsViewModel
  notifications: v.optional(
    v.object({
      enabled: v.boolean(),
      morning: v.optional(reminderSlot),
      afternoon: v.optional(reminderSlot),
      evening: v.optional(reminderSlot),
    })
  ),
  experience: v.optional(
    v.object({
      defaultSound: v.optional(v.string()),
      voiceGuidance: v.optional(v.boolean()),
      ambientVolume: v.optional(v.number()),
    })
  ),
  privacy: v.optional(v.object({ syncEnabled: v.optional(v.boolean()) })),
};

export const onboardingProfile = v.object({
  age: v.optional(v.string()),
  gender: v.optional(v.string()),
  genderCode: v.optional(v.string()),
  stressReasons: v.optional(v.array(v.string())),
  stressDuration: v.optional(v.string()),
  acquisitionChannel: v.optional(v.string()),
});

export const baselineFields = {
  collectedAt: v.number(),
  method: v.string(),
  currentHabits: v.optional(
    v.object({
      wakeTime: v.optional(v.string()),
      sleepDuration: v.optional(v.number()),
      waterIntake: v.optional(v.number()),
      exerciseFrequency: v.optional(v.number()),
      exerciseDuration: v.optional(v.number()),
      meditationFrequency: v.optional(v.number()),
      meditationDuration: v.optional(v.number()),
      breathingFrequency: v.optional(v.number()),
    })
  ),
  preferences: v.optional(
    v.object({
      availableTime: v.optional(v.number()),
      preferredIntensity: v.optional(v.string()),
      hasPhysicalLimitations: v.optional(v.boolean()),
      preferredTimeOfDay: v.optional(v.string()),
      primaryGoal: v.optional(v.string()),
    })
  ),
  quizAnswers: v.optional(v.array(v.number())),
  isValidated: v.optional(v.boolean()),
};

export const planFields = {
  version: v.number(),
  goal: planGoal,
  secondaryGoal: v.optional(planGoal),
  gentle: v.boolean(),
  compact: v.boolean(),
  cycle: v.number(),
  lengthDays: v.number(),
  startDate: v.number(),
  goalChosenByUser: v.boolean(),
  profileSource: v.string(),
  /** Full PersonalPlan JSON (JSONEncoder defaults) – opaque to the server. */
  planJSON: v.string(),
};

export const userTaskFields = {
  title: v.string(),
  category: v.string(),
  completed: v.boolean(),
  frequency: v.optional(v.number()),
  goalType: v.optional(v.string()),
  completedAt: v.optional(v.number()),
  taskFrequency: v.optional(v.string()),
  customCategory: v.optional(v.string()),
  durationInMinutes: v.optional(v.number()),
  isCustomTask: v.optional(v.boolean()),
  icon: v.optional(v.string()),
  sfSymbol: v.optional(v.string()),
  recommendedTime: v.optional(v.string()),
  taskDescription: v.optional(v.string()),
  habitId: v.optional(v.string()),
};

export default defineSchema({
  ...authTables,

  /** users/{uid} → Convex Auth user + profile. */
  users: defineTable({
    // Convex Auth fields
    name: v.optional(v.string()),
    image: v.optional(v.string()),
    email: v.optional(v.string()),
    emailVerificationTime: v.optional(v.number()),
    phone: v.optional(v.string()),
    phoneVerificationTime: v.optional(v.number()),
    isAnonymous: v.optional(v.boolean()),
    // Identity link keys
    emailCanonical: v.optional(v.string()),
    appleSub: v.optional(v.string()),
    googleSub: v.optional(v.string()),
    legacyFirebaseUid: v.optional(v.string()),
    legacyClaimState: v.optional(v.union(v.literal("running"), v.literal("done"))),
    legacyClaimedAt: v.optional(v.number()),
    // Profile
    firstName: v.optional(v.string()),
    displayName: v.optional(v.string()),
    avatarStorageId: v.optional(v.id("_storage")),
    legacyAvatarBase64: v.optional(v.string()),
    photoURL: v.optional(v.string()),
    language: v.optional(v.string()),
    createdAt: v.optional(v.number()),
    updatedAt: v.optional(v.number()),
    lastLoginAt: v.optional(v.number()),
    // Onboarding
    onboardingCompleted: v.optional(v.boolean()),
    onboardingCompletedAt: v.optional(v.number()),
    onboarding: v.optional(onboardingProfile),
    hasBaseline: v.optional(v.boolean()),
    // Subscription mirror reported by the app: informative only, never trusted.
    subscription: v.optional(
      v.object({
        isPaid: v.boolean(),
        entitlementId: v.optional(v.string()),
        updatedAt: v.number(),
      })
    ),
    // Server-verified RevenueCat entitlement (webhook or REST API, see subscriptions.ts).
    // Active while expiresAt is null (lifetime) or in the future. Gates the AI features.
    entitlement: v.optional(
      v.object({
        expiresAt: v.union(v.number(), v.null()),
        productId: v.optional(v.string()),
        store: v.optional(v.string()),
        environment: v.optional(v.string()),
        source: v.union(v.literal("webhook"), v.literal("api")),
        eventAt: v.number(),
        updatedAt: v.number(),
      })
    ),
    // Last RevenueCat REST lookup (throttles the fallback in subscriptions.ts).
    entitlementCheckedAt: v.optional(v.number()),
    // Trial recovery (recovery.ts): where the user stopped before starting the trial
    recovery: v.optional(
      v.object({
        step: v.optional(v.string()),
        stepAt: v.optional(v.number()),
        paywallSeenAt: v.optional(v.number()),
        goal: v.optional(v.string()),
        offersOptIn: v.optional(v.boolean()),
        holdout: v.optional(v.boolean()),
        timezone: v.optional(v.string()),
        updatedAt: v.number(),
      })
    ),
    // Anti-stress quick access
    lastSituation: v.optional(v.string()),
    lastSituationAt: v.optional(v.number()),
    lastExerciseType: v.optional(v.string()),
    lastExerciseAt: v.optional(v.number()),
    totalExercisesCompleted: v.optional(v.number()),
  })
    .index("email", ["email"])
    .index("phone", ["phone"])
    .index("by_emailCanonical", ["emailCanonical"])
    .index("by_appleSub", ["appleSub"])
    .index("by_googleSub", ["googleSub"])
    .index("by_legacyFirebaseUid", ["legacyFirebaseUid"]),

  /** Per-user daily counters of paid AI calls (aiAccess.ts). `day` is the UTC day key. */
  aiUsage: defineTable({
    userId: v.id("users"),
    feature: v.union(v.literal("assistant"), v.literal("faceScan"), v.literal("transcribe")),
    day: v.string(),
    count: v.number(),
    updatedAt: v.number(),
  }).index("by_user_feature_day", ["userId", "feature", "day"]),

  /** Email ownership proof for password accounts (needed to claim legacy data by email). */
  emailVerificationCodes: defineTable({
    userId: v.id("users"),
    email: v.string(),
    codeHash: v.string(),
    expiresAt: v.number(),
    attemptsLeft: v.number(),
  }).index("by_user", ["userId"]),

  /** users/{uid}/settings/preferences */
  userSettings: defineTable({
    userId: v.id("users"),
    ...settingsFields,
    updatedAt: v.number(),
  }).index("by_user", ["userId"]),

  /** users/{uid}/habit_tracking/{habitId} */
  habitTracking: defineTable({
    userId: v.id("users"),
    habitId: v.string(),
    habitTitle: v.string(),
    currentStreak: v.number(),
    longestStreak: v.number(),
    totalCompletions: v.number(),
    last7Days: v.array(v.boolean()),
    completedDays: v.array(v.number()),
    firstCompletedAt: v.optional(v.number()),
    lastCompletedAt: v.optional(v.number()),
    lastCompletedDate: v.optional(v.string()),
    updatedAt: v.number(),
  }).index("by_user_habit", ["userId", "habitId"]),

  /** users/{uid}/habit_tracking/{habitId}/daily_completion/{yyyy-MM-dd} */
  habitCompletions: defineTable({
    userId: v.id("users"),
    habitId: v.string(),
    date: v.string(),
    completed: v.boolean(),
    completedAt: v.number(),
  })
    .index("by_user_habit_date", ["userId", "habitId", "date"])
    .index("by_user_date", ["userId", "date"]),

  /** users/{uid}/task_statuses/day_{N} */
  taskStatuses: defineTable({
    userId: v.id("users"),
    programDay: v.number(),
    statuses: v.array(v.object({ key: v.string(), status: taskStatus })),
    updatedAt: v.number(),
  }).index("by_user_day", ["userId", "programDay"]),

  /** users/{uid}/completed_tasks/{id} */
  completedTasks: defineTable({
    userId: v.id("users"),
    taskId: v.string(),
    habitId: v.optional(v.string()),
    exerciseId: v.optional(v.string()),
    programDay: v.optional(v.number()),
    completedAt: v.number(),
    durationActualSeconds: v.optional(v.number()),
    source: v.optional(v.string()),
    legacy: v.optional(
      v.object({
        routineId: v.optional(v.string()),
        weekNumber: v.optional(v.number()),
        dayNumber: v.optional(v.number()),
        moment: v.optional(v.string()),
        feedbackMood: v.optional(v.string()),
        feedbackNote: v.optional(v.string()),
        wasManual: v.optional(v.boolean()),
      })
    ),
    legacyPath: v.optional(v.string()),
  })
    .index("by_user_completedAt", ["userId", "completedAt"])
    .index("by_user_day_task", ["userId", "programDay", "taskId"])
    .index("by_user_legacyPath", ["userId", "legacyPath"]),

  /** users/{uid}/exercises_done/{autoId} */
  exerciseSessions: defineTable({
    userId: v.id("users"),
    exerciseId: v.optional(v.string()),
    exerciseType: v.string(),
    situation: v.optional(v.string()),
    completedAt: v.number(),
    durationSeconds: v.number(),
    source: v.optional(v.string()),
    localSessionId: v.optional(v.string()),
    legacyPath: v.optional(v.string()),
  })
    .index("by_user_completedAt", ["userId", "completedAt"])
    .index("by_user_localSessionId", ["userId", "localSessionId"])
    .index("by_user_legacyPath", ["userId", "legacyPath"]),

  /** users/{uid}/daily_checkins/{yyyy-MM-dd} */
  dailyCheckins: defineTable({
    userId: v.id("users"),
    date: v.string(),
    dayStartAt: v.number(),
    mood,
    stress: v.number(),
    sleep: v.number(),
    energy: v.number(),
    note: v.string(),
    createdAt: v.number(),
    updatedAt: v.number(),
  }).index("by_user_date", ["userId", "date"]),

  /** users/{uid}/daily_moods/{yyyy-MM-dd} */
  dailyMoods: defineTable({
    userId: v.id("users"),
    date: v.string(),
    dayStartAt: v.number(),
    mood,
    recordedAt: v.number(),
  }).index("by_user_date", ["userId", "date"]),

  /** users/{uid}/journalEntries/{autoId} (base64 photos → file storage) */
  journalEntries: defineTable({
    userId: v.id("users"),
    content: v.string(),
    wordCount: v.number(),
    mood: v.optional(mood),
    photoStorageId: v.optional(v.id("_storage")),
    legacyPhotoBase64: v.optional(v.string()),
    meditationId: v.optional(v.string()),
    meditationType: v.optional(v.string()),
    prompt: v.optional(v.string()),
    tags: v.optional(v.array(v.string())),
    isFavorite: v.optional(v.boolean()),
    createdAt: v.number(),
    updatedAt: v.number(),
    legacyPath: v.optional(v.string()),
  })
    .index("by_user_createdAt", ["userId", "createdAt"])
    .index("by_user_meditationType", ["userId", "meditationType", "createdAt"])
    .index("by_user_meditationId", ["userId", "meditationId", "createdAt"])
    .index("by_user_legacyPath", ["userId", "legacyPath"]),

  /** users/{uid}/achievements/{achievementId} */
  achievements: defineTable({
    userId: v.id("users"),
    achievementId: v.string(),
    progress: v.number(),
    unlockedAt: v.optional(v.number()),
    updatedAt: v.number(),
  }).index("by_user_achievement", ["userId", "achievementId"]),

  /** users/{uid}/habit_badges/{habitId}_{level} */
  habitBadges: defineTable({
    userId: v.id("users"),
    habitId: v.string(),
    level: badgeLevel,
    requirement: v.number(),
    progress: v.number(),
    unlockedAt: v.optional(v.number()),
    updatedAt: v.number(),
  }).index("by_user_habit_level", ["userId", "habitId", "level"]),

  /** users/{uid}/personalized_plan/current */
  personalPlans: defineTable({
    userId: v.id("users"),
    ...planFields,
    updatedAt: v.number(),
  }).index("by_user", ["userId"]),

  /** users/{uid}/baseline/initial */
  baselines: defineTable({
    userId: v.id("users"),
    ...baselineFields,
    updatedAt: v.number(),
  }).index("by_user", ["userId"]),

  /** users/{uid}/stats/main */
  userStats: defineTable({
    userId: v.id("users"),
    streak: v.number(),
    totalTasksCompleted: v.number(),
    /** yyyy-MM-dd → daily completion ratio */
    history: v.record(v.string(), v.number()),
    updatedAt: v.number(),
  }).index("by_user", ["userId"]),

  /** users/{uid}/tasks/{id} (legacy TaskItem list read by HomeViewModel) */
  userTasks: defineTable({
    userId: v.id("users"),
    ...userTaskFields,
    createdAt: v.number(),
    legacyPath: v.optional(v.string()),
  })
    .index("by_user_createdAt", ["userId", "createdAt"])
    .index("by_user_legacyPath", ["userId", "legacyPath"]),

  /** dailyTodos/{autoId} (top-level, userId field) */
  dailyTodos: defineTable({
    userId: v.id("users"),
    title: v.string(),
    isCompleted: v.boolean(),
    isActive: v.boolean(),
    createdAt: v.number(),
    legacyPath: v.optional(v.string()),
  })
    .index("by_user_active", ["userId", "isActive", "createdAt"])
    .index("by_user_legacyPath", ["userId", "legacyPath"]),

  /** bug_reports/{autoId} – write-only for clients. */
  bugReports: defineTable({
    userId: v.id("users"),
    userEmail: v.optional(v.string()),
    description: v.string(),
    appVersion: v.optional(v.string()),
    iosVersion: v.optional(v.string()),
    deviceModel: v.optional(v.string()),
    language: v.optional(v.string()),
    status: v.string(),
    screenshotStorageId: v.optional(v.id("_storage")),
    legacyScreenshotBase64: v.optional(v.string()),
    createdAt: v.number(),
    legacyPath: v.optional(v.string()),
  })
    .index("by_user", ["userId"])
    .index("by_status", ["status", "createdAt"]),

  /**
   * Claimed Firestore documents of collections the app no longer uses
   * (routine_progress, feedback, custom_tasks, ai_insights, habit_goals,
   * dailyPrograms, onboarding_responses, baseline/collection…). Kept for
   * reference, owned by the user, deleted with the account, never exposed.
   */
  archivedRecords: defineTable({
    userId: v.id("users"),
    collection: v.string(),
    firestorePath: v.string(),
    data: v.any(),
    importedAt: v.number(),
  })
    .index("by_user", ["userId", "collection"])
    .index("by_user_path", ["userId", "firestorePath"]),

  // ---------------------------------------------------------------------------
  // Private migration staging (never read by public functions)
  // ---------------------------------------------------------------------------

  /** users/{uid} profile + Firebase Auth identity keys, before claiming. */
  legacyUsers: defineTable({
    firebaseUid: v.string(),
    emailCanonical: v.optional(v.string()),
    appleSub: v.optional(v.string()),
    googleSub: v.optional(v.string()),
    authProviders: v.array(v.string()),
    profile: v.any(),
    sourceCreatedAt: v.optional(v.number()),
    sourceUpdatedAt: v.optional(v.number()),
    importedAt: v.number(),
    runId: v.string(),
    claimedByUserId: v.optional(v.id("users")),
    claimedAt: v.optional(v.number()),
  })
    .index("by_firebaseUid", ["firebaseUid"])
    .index("by_emailCanonical", ["emailCanonical"])
    .index("by_appleSub", ["appleSub"])
    .index("by_googleSub", ["googleSub"])
    .index("by_claimedByUserId", ["claimedByUserId"]),

  /** Imported Firestore documents; private until the owner claims them. */
  legacyRecords: defineTable({
    firebaseUid: v.optional(v.string()),
    firestorePath: v.string(),
    collection: v.string(),
    data: v.any(),
    sourceUpdatedAt: v.optional(v.number()),
    importedAt: v.number(),
  })
    .index("by_firebaseUid", ["firebaseUid"])
    .index("by_firestorePath", ["firestorePath"])
    .index("by_collection", ["collection"]),

  migrationRuns: defineTable({
    runId: v.string(),
    state: v.union(
      v.literal("prepared"),
      v.literal("imported"),
      v.literal("verified"),
      v.literal("failed")
    ),
    sourceDocumentCount: v.number(),
    importedDocumentCount: v.number(),
    sourceDigest: v.string(),
    importedDigest: v.optional(v.string()),
    startedAt: v.number(),
    completedAt: v.optional(v.number()),
    notes: v.optional(v.string()),
  }).index("by_runId", ["runId"]),
});
