/// <reference types="vite/client" />
import { convexTest } from "convex-test";
import { describe, expect, test } from "vitest";
import { api, internal } from "./_generated/api";
import schema from "./schema";

const modules = import.meta.glob([
  "./**/*.ts",
  "./**/*.js",
  "!./**/*.test.ts",
  "!./**/*.d.ts",
  "!./**/*.config.ts",
]);

async function setupUser(t: ReturnType<typeof convexTest>, extra: Record<string, unknown> = {}) {
  const userId = await t.run(async (ctx) =>
    ctx.db.insert("users", { email: "a@example.test", emailCanonical: "a@example.test", ...extra })
  );
  const sessionId = await t.run(async (ctx) =>
    ctx.db.insert("authSessions", { userId, expirationTime: Date.now() + 3_600_000 })
  );
  return { userId, as: t.withIdentity({ subject: `${userId}|${sessionId}` }) };
}

describe("app functions", () => {
  test("rejects unauthenticated calls", async () => {
    const t = convexTest(schema, modules);
    await expect(t.query(api.journal.list, {})).rejects.toThrow(/Authentication required/);
  });

  test("habit streaks, statuses, check-in + journal", async () => {
    const t = convexTest(schema, modules);
    const { as } = await setupUser(t);
    expect((await as.mutation(api.habits.initializeTracking, {})).created).toBe(8);
    expect((await as.mutation(api.habits.initializeTracking, {})).created).toBe(0);
    await as.mutation(api.habits.markCompleted, { habitId: "water", programDay: 1, date: "2026-10-07" });
    const second = await as.mutation(api.habits.markCompleted, {
      habitId: "water",
      programDay: 2,
      date: "2026-10-08",
    });
    expect(second.currentStreak).toBe(2);
    expect(second.completedDays).toEqual([1, 2]);
    const removed = await as.mutation(api.habits.removeCompletion, {
      habitId: "water",
      programDay: 2,
      date: "2026-10-08",
    });
    expect(removed?.currentStreak).toBe(1);

    await as.mutation(api.tasks.setStatus, { programDay: 1, key: "plan_breathing", status: "done" });
    await as.mutation(api.tasks.setStatus, { programDay: 1, key: "plan_breathing", status: "skipped" });
    const statuses = await as.query(api.tasks.listStatuses, {});
    expect(statuses[0].statuses).toEqual({ plan_breathing: "skipped" });

    await as.mutation(api.checkins.submit, {
      date: "2026-10-07",
      dayStartAt: Date.UTC(2026, 9, 7),
      mood: "good",
      stress: 9,
      sleep: 3,
      energy: 0,
      note: "hello world",
    });
    const checkins = await as.query(api.checkins.listCheckins, { fromDate: "2026-10-01" });
    expect(checkins[0].stress).toBe(5);
    expect(checkins[0].energy).toBe(1);
    const journal = await as.query(api.journal.list, {});
    expect(journal).toHaveLength(1);
    expect(journal[0].wordCount).toBe(2);

    const snapshot = await as.query(api.progress.analyticsSnapshot, { since: 0, sinceDate: "2026-01-01" });
    expect(snapshot.moods).toHaveLength(1);
    expect(snapshot.habitTracking).toHaveLength(8);
  });

  test("legacy claim by Apple sub, then account deletion wipes everything", async () => {
    const t = convexTest(schema, modules);
    const { userId, as } = await setupUser(t, { appleSub: "apple-123" });

    await t.mutation(internal.migration.importer.startRun, {
      runId: "r1",
      sourceDocumentCount: 4,
      sourceDigest: "d",
    });
    await t.mutation(internal.migration.importer.importLegacyUsers, {
      runId: "r1",
      rows: [
        {
          firebaseUid: "fb1",
          emailCanonical: "old@example.test",
          appleSub: "apple-123",
          authProviders: ["apple.com"],
          profile: {
            firstName: "Léa",
            onboardingCompleted: true,
            createdAt: { __firebaseType: "timestamp", milliseconds: 1_700_000_000_000 },
            stressReasons: ["work"],
          },
        },
      ],
    });
    const ts = (ms: number) => ({ __firebaseType: "timestamp", milliseconds: ms });
    await t.mutation(internal.migration.importer.importLegacyRecords, {
      runId: "r1",
      rows: [
        {
          firebaseUid: "fb1",
          firestorePath: "users/fb1/daily_checkins/2025-11-09",
          collection: "daily_checkins",
          data: { mood: "low", stress: 4, sleep: 2, energy: 3, note: "", date: ts(1_762_646_400_000) },
          importedAt: 1,
        },
        {
          firebaseUid: "fb1",
          firestorePath: "users/fb1/task_statuses/day_3",
          collection: "task_statuses",
          data: { plan_breathing: "done", lastUpdated: ts(1_762_646_400_000) },
          importedAt: 1,
        },
        {
          firebaseUid: "fb1",
          firestorePath: "users/fb1/routine_progress/r1",
          collection: "routine_progress",
          data: { routineId: "r1" },
          importedAt: 1,
        },
        {
          firestorePath: "dailyTodos/abc",
          collection: "dailyTodos",
          data: { userId: "fb1", title: "Boire de l'eau", isActive: true, isCompleted: false },
          importedAt: 1,
        },
      ],
    });

    expect((await as.mutation(api.account.claimLegacyData, {})).status).toBe("started");
    await t.finishAllScheduledFunctions(() => {});
    const me = await as.query(api.profile.me, {});
    expect(me?.firstName).toBe("Léa");
    expect(me?.onboardingCompleted).toBe(true);
    expect(me?.legacy.claimState).toBe("done");
    expect(await as.query(api.checkins.listCheckins, { fromDate: "2025-01-01" })).toHaveLength(1);
    expect(await as.query(api.todos.listActive, {})).toHaveLength(1);
    expect((await as.query(api.tasks.listStatuses, {}))[0].programDay).toBe(3);
    const staging = await t.run((ctx) => ctx.db.query("legacyRecords").collect());
    expect(staging).toHaveLength(0);
    expect((await as.mutation(api.account.claimLegacyData, {})).status).toBe("already_claimed");

    await as.action(api.account.deleteMyAccount, {});
    const leftovers = await t.run(async (ctx) => ({
      user: await ctx.db.get(userId),
      checkins: (await ctx.db.query("dailyCheckins").collect()).length,
      archived: (await ctx.db.query("archivedRecords").collect()).length,
      legacyUsers: (await ctx.db.query("legacyUsers").collect()).length,
      sessions: (await ctx.db.query("authSessions").collect()).length,
    }));
    expect(leftovers).toEqual({ user: null, checkins: 0, archived: 0, legacyUsers: 0, sessions: 0 });
    await expect(as.query(api.journal.list, {})).rejects.toThrow(/Authentication required/);
  });

  test("password users cannot claim by email before verifying it", async () => {
    const t = convexTest(schema, modules);
    const { as } = await setupUser(t);
    await t.mutation(internal.migration.importer.importLegacyUsers, {
      runId: "r1",
      rows: [{ firebaseUid: "fb2", emailCanonical: "a@example.test", authProviders: ["password"], profile: {} }],
    });
    const result = await as.mutation(api.account.claimLegacyData, {});
    expect(result).toEqual({ status: "nothing_to_claim", needsEmailVerification: true });
  });
});
