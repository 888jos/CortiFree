/**
 * Pure transforms: exported Firestore document (legacyRecords row) → Convex row.
 *
 * Input values come from functions/scripts/export-firestore-for-convex.js:
 * timestamps are `{ __firebaseType: "timestamp", milliseconds }`, everything
 * else is plain JSON. Each transform is defensive: anything that does not fit
 * the typed table goes to `archive` instead of failing the whole claim.
 *
 * Path → table mapping (see README for the full table):
 *   users/{uid}                                   → users (profile patch, see transformProfile)
 *   users/{uid}/settings/preferences              → userSettings
 *   users/{uid}/habit_tracking/{habitId}          → habitTracking
 *   users/{uid}/habit_tracking/{h}/daily_completion/{date} → habitCompletions
 *   users/{uid}/task_statuses/day_{N}             → taskStatuses
 *   users/{uid}/completed_tasks/{id}              → completedTasks
 *   users/{uid}/exercises_done/{id}               → exerciseSessions
 *   users/{uid}/daily_checkins/{date}             → dailyCheckins
 *   users/{uid}/daily_moods/{date}                → dailyMoods
 *   users/{uid}/journalEntries/{id}               → journalEntries
 *   users/{uid}/achievements/{id}                 → achievements
 *   users/{uid}/habit_badges/{habit}_{level}      → habitBadges
 *   users/{uid}/personalized_plan/current         → personalPlans
 *   users/{uid}/baseline/initial                  → baselines
 *   users/{uid}/stats/main                        → userStats
 *   users/{uid}/tasks/{id}                        → userTasks
 *   dailyTodos/{id}                               → dailyTodos
 *   bug_reports/{id}                              → bugReports
 *   anything else owned by the user               → archivedRecords
 */
import { Doc, TableNames } from "../_generated/dataModel";

type Row<T extends TableNames> = Omit<Doc<T>, "_id" | "_creationTime" | "userId">;

export type AppTable =
  | "userSettings"
  | "habitTracking"
  | "habitCompletions"
  | "taskStatuses"
  | "completedTasks"
  | "exerciseSessions"
  | "dailyCheckins"
  | "dailyMoods"
  | "journalEntries"
  | "achievements"
  | "habitBadges"
  | "personalPlans"
  | "baselines"
  | "userStats"
  | "userTasks"
  | "dailyTodos"
  | "bugReports";

export type TransformResult =
  | { [T in AppTable]: { kind: "row"; table: T; row: Row<T> } }[AppTable]
  | { kind: "archive"; reason: string }
  | { kind: "skip"; reason: string };

export type LegacyRecord = {
  firestorePath: string;
  collection: string;
  data: unknown;
  sourceUpdatedAt?: number;
  importedAt: number;
};

// ---------------------------------------------------------------------------
// Value helpers
// ---------------------------------------------------------------------------

type Obj = Record<string, unknown>;

const isObj = (value: unknown): value is Obj =>
  typeof value === "object" && value !== null && !Array.isArray(value);

export function ts(value: unknown): number | undefined {
  if (isObj(value) && value.__firebaseType === "timestamp" && typeof value.milliseconds === "number") {
    return value.milliseconds;
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    // Firestore Date fields are Timestamps; plain numbers are rare. Treat
    // values < 1e11 as seconds.
    return value < 1e11 ? Math.round(value * 1000) : value;
  }
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return undefined;
}

const str = (value: unknown): string | undefined =>
  typeof value === "string" ? value : undefined;
const num = (value: unknown): number | undefined =>
  typeof value === "number" && Number.isFinite(value) ? value : undefined;
const bool = (value: unknown): boolean | undefined =>
  typeof value === "boolean" ? value : undefined;
const strArr = (value: unknown): string[] | undefined =>
  Array.isArray(value) ? value.filter((v): v is string => typeof v === "string") : undefined;
const numArr = (value: unknown): number[] | undefined =>
  Array.isArray(value) ? value.filter((v): v is number => typeof v === "number") : undefined;

function compact<T extends Obj>(value: T): T {
  const out: Obj = {};
  for (const [key, entry] of Object.entries(value)) if (entry !== undefined) out[key] = entry;
  return out as T;
}

const DAY_KEY = /^\d{4}-\d{2}-\d{2}$/;
const dayKeyToUtc = (key: string) => {
  const [y, m, d] = key.split("-").map(Number);
  return Date.UTC(y, m - 1, d);
};
const utcDayKey = (ms: number) => new Date(ms).toISOString().slice(0, 10);

const MOODS = new Set(["awful", "angry", "low", "okay", "good", "amazing"]);
type Mood = "awful" | "angry" | "low" | "okay" | "good" | "amazing";
const mood = (value: unknown): Mood | undefined =>
  typeof value === "string" && MOODS.has(value) ? (value as Mood) : undefined;

const PLAN_GOALS = new Set(["stress", "sleep", "energy", "focus", "emotional"]);
type PlanGoal = "stress" | "sleep" | "energy" | "focus" | "emotional";
const planGoal = (value: unknown): PlanGoal | undefined =>
  typeof value === "string" && PLAN_GOALS.has(value) ? (value as PlanGoal) : undefined;

const BADGE_LEVELS = new Set(["bronze", "silver", "gold", "diamond"]);
type BadgeLevel = "bronze" | "silver" | "gold" | "diamond";

const clamp15 = (value: unknown) => Math.min(5, Math.max(1, Math.round(num(value) ?? 3)));
const words = (text: string) => text.split(/\s+/).filter(Boolean).length;

/** base64 image payloads larger than this stay out of the row (Convex 1 MiB doc limit). */
const MAX_INLINE_BASE64 = 900_000;
function base64Image(value: unknown): string | undefined {
  const s = str(value);
  if (!s || s.startsWith("http") || s.length > MAX_INLINE_BASE64) return undefined;
  return s;
}

function reminder(value: unknown) {
  if (!isObj(value)) return undefined;
  const enabled = bool(value.enabled);
  const time = str(value.time);
  return enabled !== undefined && time !== undefined ? { enabled, time } : undefined;
}

// ---------------------------------------------------------------------------
// Root profile (legacyUsers.profile → users patch)
// ---------------------------------------------------------------------------

/** Fields to set on the Convex user, only where the Convex user has no value yet. */
export function transformProfile(profile: unknown): Partial<Doc<"users">> {
  if (!isObj(profile)) return {};
  const onboarding = compact({
    age: str(profile.age),
    gender: str(profile.gender),
    genderCode: str(profile.genderCode),
    stressReasons: strArr(profile.stressReasons),
    stressDuration: str(profile.stressDuration),
    acquisitionChannel: str(profile.acquisitionChannel),
  });
  const isPaid = bool(profile.isPaid);
  const photoURL = str(profile.photoURL);
  return compact({
    firstName: str(profile.firstName) ?? str(profile.name),
    displayName: str(profile.displayName) ?? str(profile.username),
    photoURL: photoURL && photoURL.startsWith("https://") ? photoURL : undefined,
    legacyAvatarBase64: base64Image(profile.profilePhotoBase64),
    createdAt: ts(profile.createdAt),
    lastLoginAt: ts(profile.lastLoginAt) ?? ts(profile.lastLogin),
    onboardingCompleted: bool(profile.onboardingCompleted),
    onboardingCompletedAt: ts(profile.onboardingCompletedAt),
    onboarding: Object.keys(onboarding).length > 0 ? onboarding : undefined,
    hasBaseline: bool(profile.hasBaseline),
    subscription: isPaid !== undefined ? { isPaid, updatedAt: Date.now() } : undefined,
    lastSituation: str(profile.lastSituation),
    lastSituationAt: ts(profile.lastSituationTimestamp),
    lastExerciseType: str(profile.lastExerciseType),
    lastExerciseAt: ts(profile.lastExerciseDate),
    totalExercisesCompleted: num(profile.totalExercisesCompleted),
  });
}

// ---------------------------------------------------------------------------
// Sub-collections
// ---------------------------------------------------------------------------

export function transformRecord(record: LegacyRecord): TransformResult {
  const segments = record.firestorePath.split("/");
  const data = isObj(record.data) ? record.data : {};
  const fallbackTime = record.sourceUpdatedAt ?? record.importedAt;
  const path = record.firestorePath;

  // Top-level collections
  if (segments.length === 2) {
    if (segments[0] === "dailyTodos") {
      const title = str(data.title);
      if (!title) return { kind: "archive", reason: "todo without title" };
      return {
        kind: "row",
        table: "dailyTodos",
        row: {
          title,
          isCompleted: bool(data.isCompleted) ?? false,
          isActive: bool(data.isActive) ?? true,
          createdAt: ts(data.createdAt) ?? fallbackTime,
          legacyPath: path,
        },
      };
    }
    if (segments[0] === "bug_reports") {
      return {
        kind: "row",
        table: "bugReports",
        row: compact({
          userEmail: str(data.userEmail),
          description: str(data.description) ?? "",
          appVersion: str(data.appVersion),
          iosVersion: str(data.iosVersion),
          deviceModel: str(data.deviceModel),
          language: str(data.language),
          status: str(data.status) ?? "new",
          legacyScreenshotBase64: base64Image(data.screenshotBase64),
          createdAt: ts(data.createdAt) ?? fallbackTime,
          legacyPath: path,
        }),
      };
    }
    return { kind: "skip", reason: `top-level ${segments[0]} is not user data` };
  }

  if (segments[0] !== "users" || segments.length < 4) {
    return { kind: "archive", reason: "unexpected path" };
  }
  const collection = segments[2];
  const docId = segments[3];

  // users/{uid}/habit_tracking/{habitId}/daily_completion/{date}
  if (segments.length === 6) {
    if (collection === "habit_tracking" && segments[4] === "daily_completion") {
      const date = str(data.date) ?? segments[5];
      if (!DAY_KEY.test(date)) return { kind: "archive", reason: "bad completion date" };
      return {
        kind: "row",
        table: "habitCompletions",
        row: {
          habitId: docId,
          date,
          completed: bool(data.completed) ?? true,
          completedAt: ts(data.completedAt) ?? dayKeyToUtc(date),
        },
      };
    }
    return { kind: "archive", reason: `nested ${collection}/${segments[4]}` };
  }
  if (segments.length !== 4) return { kind: "archive", reason: "deep path" };

  switch (collection) {
    case "settings": {
      if (docId !== "preferences") return { kind: "archive", reason: "settings doc" };
      const notifications = isObj(data.notifications) ? data.notifications : undefined;
      const experience = isObj(data.experience) ? data.experience : undefined;
      const privacy = isObj(data.privacy) ? data.privacy : undefined;
      return {
        kind: "row",
        table: "userSettings",
        row: compact({
          programStartDate: ts(data.programStartDate),
          wakeUpTime: str(data.wakeUpTime),
          bedTime: str(data.bedTime),
          preferredSportActivities: strArr(data.preferredSportActivities),
          preferredNatureActivities: strArr(data.preferredNatureActivities),
          preferredSocialActivities: strArr(data.preferredSocialActivities),
          notificationsEnabled: bool(data.notificationsEnabled),
          morningReminderTime: str(data.morningReminderTime),
          eveningReminderTime: str(data.eveningReminderTime),
          notifications:
            notifications && bool(notifications.enabled) !== undefined
              ? compact({
                  enabled: bool(notifications.enabled)!,
                  morning: reminder(notifications.morning),
                  afternoon: reminder(notifications.afternoon),
                  evening: reminder(notifications.evening),
                })
              : undefined,
          experience: experience
            ? compact({
                defaultSound: str(experience.defaultSound),
                voiceGuidance: bool(experience.voiceGuidance),
                ambientVolume: num(experience.ambientVolume),
              })
            : undefined,
          privacy: privacy ? compact({ syncEnabled: bool(privacy.syncEnabled) }) : undefined,
          updatedAt: ts(data.lastUpdated) ?? fallbackTime,
        }),
      };
    }

    case "habit_tracking": {
      const last7 = Array.isArray(data.last7Days)
        ? data.last7Days.map((v) => v === true).slice(-7)
        : [];
      while (last7.length < 7) last7.unshift(false);
      const lastCompletedAt = ts(data.lastCompletedDate);
      return {
        kind: "row",
        table: "habitTracking",
        row: compact({
          habitId: str(data.habitId) ?? docId,
          habitTitle: str(data.habitTitle) ?? docId,
          currentStreak: num(data.currentStreak) ?? 0,
          longestStreak: num(data.longestStreak) ?? 0,
          totalCompletions: num(data.totalCompletions) ?? 0,
          last7Days: last7,
          completedDays: (numArr(data.completedDays) ?? []).sort((a, b) => a - b),
          firstCompletedAt: ts(data.firstCompletedDate),
          lastCompletedAt,
          // Firestore stored no local day key; UTC approximation.
          lastCompletedDate: lastCompletedAt !== undefined ? utcDayKey(lastCompletedAt) : undefined,
          updatedAt: fallbackTime,
        }),
      };
    }

    case "task_statuses": {
      const match = /^day_(\d+)$/.exec(docId);
      if (!match) return { kind: "archive", reason: "task status doc id" };
      const statuses = Object.entries(data)
        .filter(([key, value]) => key !== "lastUpdated" && (value === "done" || value === "todo" || value === "skipped"))
        .map(([key, value]) => ({ key, status: value as "done" | "todo" | "skipped" }));
      return {
        kind: "row",
        table: "taskStatuses",
        row: {
          programDay: Number(match[1]),
          statuses,
          updatedAt: ts(data.lastUpdated) ?? fallbackTime,
        },
      };
    }

    case "completed_tasks": {
      const legacy = compact({
        routineId: str(data.routineId),
        weekNumber: num(data.weekNumber),
        dayNumber: num(data.dayNumber),
        moment: str(data.moment),
        feedbackMood: str(data.feedbackMood),
        feedbackNote: str(data.feedbackNote),
        wasManual: bool(data.wasManual),
      });
      return {
        kind: "row",
        table: "completedTasks",
        row: compact({
          taskId: str(data.taskId) ?? docId,
          habitId: str(data.habitId),
          exerciseId: str(data.exerciseId),
          programDay: num(data.programDay),
          completedAt: ts(data.completedAt) ?? fallbackTime,
          durationActualSeconds: num(data.durationActualSeconds) ?? num(data.duration),
          source: str(data.source),
          legacy: Object.keys(legacy).length > 0 ? legacy : undefined,
          legacyPath: path,
        }),
      };
    }

    case "exercises_done":
      return {
        kind: "row",
        table: "exerciseSessions",
        row: compact({
          exerciseId: str(data.exerciseId),
          exerciseType: str(data.exerciseType) ?? "other",
          situation: str(data.situation),
          completedAt: ts(data.completedAt) ?? fallbackTime,
          durationSeconds: num(data.duration) ?? num(data.durationActualSeconds) ?? 0,
          source: str(data.source),
          localSessionId: str(data.localSessionId),
          legacyPath: path,
        }),
      };

    case "daily_checkins": {
      const m = mood(data.mood);
      if (!DAY_KEY.test(docId) || !m) return { kind: "archive", reason: "check-in shape" };
      return {
        kind: "row",
        table: "dailyCheckins",
        row: {
          date: docId,
          dayStartAt: ts(data.date) ?? dayKeyToUtc(docId),
          mood: m,
          stress: clamp15(data.stress),
          sleep: clamp15(data.sleep),
          energy: clamp15(data.energy),
          note: str(data.note) ?? "",
          createdAt: ts(data.createdAt) ?? fallbackTime,
          updatedAt: ts(data.createdAt) ?? fallbackTime,
        },
      };
    }

    case "daily_moods": {
      const m = mood(data.mood);
      if (!DAY_KEY.test(docId) || !m) return { kind: "archive", reason: "mood shape" };
      return {
        kind: "row",
        table: "dailyMoods",
        row: {
          date: docId,
          dayStartAt: ts(data.date) ?? dayKeyToUtc(docId),
          mood: m,
          recordedAt: ts(data.timestamp) ?? fallbackTime,
        },
      };
    }

    case "journalEntries": {
      const content = str(data.content) ?? "";
      const createdAt = ts(data.createdAt) ?? fallbackTime;
      return {
        kind: "row",
        table: "journalEntries",
        row: compact({
          content,
          wordCount: num(data.wordCount) ?? words(content),
          mood: mood(data.mood),
          legacyPhotoBase64: base64Image(data.photoURL),
          meditationId: str(data.meditationId),
          meditationType: str(data.meditationType),
          prompt: str(data.prompt),
          tags: strArr(data.tags),
          isFavorite: bool(data.isFavorite),
          createdAt,
          updatedAt: createdAt,
          legacyPath: path,
        }),
      };
    }

    case "achievements":
      return {
        kind: "row",
        table: "achievements",
        row: compact({
          achievementId: str(data.id) ?? docId,
          progress: num(data.progress) ?? 0,
          unlockedAt: ts(data.unlockedAt),
          updatedAt: fallbackTime,
        }),
      };

    case "habit_badges": {
      const level = str(data.level);
      const habitId = str(data.habitId) ?? docId.split("_")[0];
      if (!level || !BADGE_LEVELS.has(level)) return { kind: "archive", reason: "badge level" };
      return {
        kind: "row",
        table: "habitBadges",
        row: compact({
          habitId,
          level: level as BadgeLevel,
          requirement: num(data.requirement) ?? 0,
          progress: num(data.progress) ?? 0,
          unlockedAt: ts(data.unlockedAt),
          updatedAt: fallbackTime,
        }),
      };
    }

    case "personalized_plan": {
      const goal = planGoal(data.goal);
      const planJSON = str(data.planJSON);
      if (docId !== "current" || !goal || !planJSON) return { kind: "archive", reason: "plan shape" };
      return {
        kind: "row",
        table: "personalPlans",
        row: compact({
          version: num(data.version) ?? 1,
          goal,
          secondaryGoal: planGoal(data.secondaryGoal),
          gentle: bool(data.gentle) ?? false,
          compact: bool(data.compact) ?? false,
          cycle: num(data.cycle) ?? 1,
          lengthDays: num(data.lengthDays) ?? 28,
          startDate: ts(data.startDate) ?? fallbackTime,
          goalChosenByUser: bool(data.goalChosenByUser) ?? false,
          profileSource: str(data.profileSource) ?? "migrated",
          planJSON,
          updatedAt: ts(data.updatedAt) ?? fallbackTime,
        }),
      };
    }

    case "baseline": {
      if (docId !== "initial") return { kind: "archive", reason: `baseline/${docId}` };
      const habits = isObj(data.currentHabits) ? data.currentHabits : undefined;
      const prefs = isObj(data.preferences) ? data.preferences : undefined;
      return {
        kind: "row",
        table: "baselines",
        row: compact({
          collectedAt: ts(data.collectedAt) ?? fallbackTime,
          method: str(data.method) ?? "quiz",
          currentHabits: habits
            ? compact({
                wakeTime: str(habits.wakeTime),
                sleepDuration: num(habits.sleepDuration),
                waterIntake: num(habits.waterIntake),
                exerciseFrequency: num(habits.exerciseFrequency),
                exerciseDuration: num(habits.exerciseDuration),
                meditationFrequency: num(habits.meditationFrequency),
                meditationDuration: num(habits.meditationDuration),
                breathingFrequency: num(habits.breathingFrequency),
              })
            : undefined,
          preferences: prefs
            ? compact({
                availableTime: num(prefs.availableTime),
                preferredIntensity: str(prefs.preferredIntensity),
                hasPhysicalLimitations: bool(prefs.hasPhysicalLimitations),
                preferredTimeOfDay: str(prefs.preferredTimeOfDay),
                primaryGoal: str(prefs.primaryGoal),
              })
            : undefined,
          quizAnswers: numArr(data.quizAnswers),
          isValidated: bool(data.isValidated),
          updatedAt: fallbackTime,
        }),
      };
    }

    case "stats": {
      if (docId !== "main") return { kind: "archive", reason: `stats/${docId}` };
      const history: Record<string, number> = {};
      if (isObj(data.history)) {
        for (const [key, value] of Object.entries(data.history)) {
          if (DAY_KEY.test(key) && typeof value === "number") history[key] = value;
        }
      }
      return {
        kind: "row",
        table: "userStats",
        row: {
          streak: num(data.streak) ?? 0,
          totalTasksCompleted: num(data.totalTasksCompleted) ?? 0,
          history,
          updatedAt: ts(data.lastUpdated) ?? fallbackTime,
        },
      };
    }

    case "tasks": {
      const title = str(data.title);
      if (!title) return { kind: "archive", reason: "task without title" };
      return {
        kind: "row",
        table: "userTasks",
        row: compact({
          title,
          category: str(data.category) ?? "day",
          completed: bool(data.completed) ?? false,
          frequency: num(data.frequency),
          goalType: str(data.goalType),
          completedAt: ts(data.completedAt),
          taskFrequency: str(data.taskFrequency),
          customCategory: str(data.customCategory),
          durationInMinutes: num(data.durationInMinutes),
          isCustomTask: bool(data.isCustomTask),
          icon: str(data.icon),
          sfSymbol: str(data.sfSymbol),
          recommendedTime: str(data.recommendedTime),
          taskDescription: str(data.taskDescription),
          habitId: str(data.habitId),
          createdAt: ts(data.createdAt) ?? fallbackTime,
          legacyPath: path,
        }),
      };
    }

    default:
      // routine_progress, feedback, custom_tasks, ai_insights, habit_goals,
      // dailyPrograms, onboarding_responses, analytics_events, weeklyTargets…
      return { kind: "archive", reason: `unused collection ${collection}` };
  }
}
