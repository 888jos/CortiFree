#!/usr/bin/env node

// One-time, read-only Firestore export to Convex JSONL staging tables.
// Requires Firebase Admin ADC/service-account access and an explicit cost ack.

const crypto = require("node:crypto");
const path = require("node:path");
const fs = require("node:fs/promises");
const { applicationDefault, initializeApp } = require("firebase-admin/app");
const { FieldPath, getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

const COLLECTION_GROUPS = [
  "achievements",
  "ai_insights",
  "analytics_events",
  "baseline",
  "bug_reports",
  "completed_tasks",
  "custom_tasks",
  "daily_checkins",
  "daily_completion",
  "daily_moods",
  "daily_progress",
  "dailyPrograms",
  "days",
  "exercises",
  "exercises_done",
  "feedback",
  "habit_badges",
  "habit_goals",
  "habit_tracking",
  "journalEntries",
  "onboarding_responses",
  "personalized_plan",
  "routine_progress",
  "routines",
  "settings",
  "stats",
  "task_statuses",
  "tasks",
  "users",
  "weeklyTargets",
];

function parseArgs(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--confirm-read-cost") options.confirmReadCost = true;
    else if (argument === "--writes-paused") options.writesPaused = true;
    else if (argument === "--include-password-hashes") options.includePasswordHashes = true;
    else if (argument === "--project") options.projectId = argv[++index];
    else if (argument === "--out") options.outputPath = argv[++index];
    else throw new Error(`Unknown argument: ${argument}`);
  }
  if (!options.confirmReadCost) {
    throw new Error("Refusing to read production data without --confirm-read-cost.");
  }
  if (!options.writesPaused) {
    throw new Error("Pause app/server writes first, then pass --writes-paused for a consistent export.");
  }
  if (!options.projectId) throw new Error("Pass --project <firebase-project-id>.");
  return options;
}

function toPlainValue(value) {
  if (value === null || typeof value === "string" || typeof value === "boolean") return value;
  if (typeof value === "number") {
    if (!Number.isFinite(value)) return { __firebaseType: "number", value: String(value) };
    return value;
  }
  if (typeof value === "bigint") return { __firebaseType: "integer", value: value.toString() };
  if (Buffer.isBuffer(value) || value instanceof Uint8Array) {
    return { __firebaseType: "bytes", base64: Buffer.from(value).toString("base64") };
  }
  if (Array.isArray(value)) return value.map(toPlainValue);
  if (value instanceof Date) {
    return { __firebaseType: "timestamp", milliseconds: value.getTime() };
  }
  if (value && typeof value.toMillis === "function" && typeof value.toDate === "function") {
    return { __firebaseType: "timestamp", milliseconds: value.toMillis() };
  }
  if (value && typeof value.path === "string" && value.firestore) {
    return { __firebaseType: "documentReference", path: value.path };
  }
  if (value && typeof value.latitude === "number" && typeof value.longitude === "number") {
    return {
      __firebaseType: "geopoint",
      latitude: value.latitude,
      longitude: value.longitude,
    };
  }
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([key, entry]) => [key, toPlainValue(entry)]));
  }
  return null;
}

function epochFrom(value, fallback) {
  if (value && typeof value.milliseconds === "number") return value.milliseconds;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return fallback;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  initializeApp({
    credential: applicationDefault(),
    projectId: options.projectId,
  });
  const db = getFirestore();
  const exportedAt = Date.now();
  const outputDirectory = path.resolve(
    options.outputPath ?? path.join(__dirname, "../../migration/private", `firestore-${exportedAt}`)
  );
  await fs.mkdir(path.dirname(outputDirectory), { recursive: true, mode: 0o700 });
  await fs.mkdir(outputDirectory, { mode: 0o700 });

  const usersFile = await fs.open(path.join(outputDirectory, "legacyUsers.jsonl"), "w", 0o600);
  const recordsFile = await fs.open(path.join(outputDirectory, "legacyRecords.jsonl"), "w", 0o600);
  const authFile = await fs.open(path.join(outputDirectory, "legacyAuthUsers.jsonl"), "w", 0o600);
  const usersHash = crypto.createHash("sha256");
  const recordsHash = crypto.createHash("sha256");
  const authHash = crypto.createHash("sha256");
  const counts = {};
  let userCount = 0;
  let recordCount = 0;
  let authCount = 0;

  try {
    for (const collectionName of COLLECTION_GROUPS) {
      let cursor;
      let collectionCount = 0;
      while (true) {
        let query = db
          .collectionGroup(collectionName)
          .orderBy(FieldPath.documentId())
          .limit(250);
        if (cursor) query = query.startAfter(cursor);
        const snapshot = await query.get();
        for (const document of snapshot.docs) {
          const firestorePath = document.ref.path;
          const segments = firestorePath.split("/");
          const raw = toPlainValue(document.data());
          const sourceCreatedAt = raw?.createdAt;
          const sourceUpdatedAt = raw?.updatedAt ?? raw?.modifiedAt;

          if (firestorePath.startsWith("users/") && segments.length === 2) {
            const firebaseUid = segments[1];
            const email = typeof raw?.email === "string" ? raw.email.trim().toLowerCase() : undefined;
            const row = {
              firebaseUid,
              ...(email ? { emailCanonical: email } : {}),
              profile: raw,
              createdAt: epochFrom(sourceCreatedAt, exportedAt),
              updatedAt: epochFrom(sourceUpdatedAt, exportedAt),
            };
            const line = `${JSON.stringify(row)}\n`;
            await usersFile.write(line);
            usersHash.update(line);
            userCount += 1;
          } else {
            const firebaseUid = firestorePath.startsWith("users/") ? segments[1] : undefined;
            const row = {
              ...(firebaseUid ? { firebaseUid } : {}),
              firestorePath,
              collection: segments[segments.length - 2],
              data: raw,
              ...(typeof sourceUpdatedAt?.milliseconds === "number"
                ? { sourceUpdatedAt: sourceUpdatedAt.milliseconds }
                : {}),
              importedAt: exportedAt,
            };
            const line = `${JSON.stringify(row)}\n`;
            await recordsFile.write(line);
            recordsHash.update(line);
            recordCount += 1;
          }
        }
        collectionCount += snapshot.size;
        if (snapshot.size < 250) break;
        cursor = snapshot.docs[snapshot.docs.length - 1];
      }
      counts[collectionName] = collectionCount;
      process.stdout.write(`${collectionName}: ${collectionCount} documents\n`);
    }

    let pageToken;
    do {
      const page = await getAuth().listUsers(1000, pageToken);
      for (const user of page.users) {
        const account = {
          uid: user.uid,
          ...(user.email ? { email: user.email } : {}),
          emailVerified: user.emailVerified,
          disabled: user.disabled,
          ...(user.displayName ? { displayName: user.displayName } : {}),
          ...(user.photoURL ? { photoURL: user.photoURL } : {}),
          ...(user.phoneNumber ? { phoneNumber: user.phoneNumber } : {}),
          ...(user.tenantId ? { tenantId: user.tenantId } : {}),
          providerData: user.providerData.map((provider) => ({
            providerId: provider.providerId,
            uid: provider.uid,
            ...(provider.email ? { email: provider.email } : {}),
            ...(provider.displayName ? { displayName: provider.displayName } : {}),
            ...(provider.photoURL ? { photoURL: provider.photoURL } : {}),
          })),
          metadata: {
            creationTime: user.metadata.creationTime,
            lastSignInTime: user.metadata.lastSignInTime,
            lastRefreshTime: user.metadata.lastRefreshTime,
          },
          ...(user.customClaims ? { customClaims: user.customClaims } : {}),
          ...(options.includePasswordHashes && user.passwordHash
            ? { passwordHash: user.passwordHash }
            : {}),
          ...(options.includePasswordHashes && user.passwordSalt
            ? { passwordSalt: user.passwordSalt }
            : {}),
        };
        const line = `${JSON.stringify(account)}\n`;
        await authFile.write(line);
        authHash.update(line);
        authCount += 1;
      }
      pageToken = page.pageToken;
    } while (pageToken);
  } finally {
    await Promise.all([usersFile.close(), recordsFile.close(), authFile.close()]);
  }

  const manifest = {
    projectId: options.projectId,
    exportedAt,
    collectionGroupCounts: counts,
    legacyUsers: { count: userCount, sha256: usersHash.digest("hex") },
    legacyRecords: { count: recordCount, sha256: recordsHash.digest("hex") },
    legacyAuthUsers: { count: authCount, sha256: authHash.digest("hex") },
    passwordHashesIncluded: options.includePasswordHashes === true,
  };
  await fs.writeFile(
    path.join(outputDirectory, "manifest.json"),
    `${JSON.stringify(manifest, null, 2)}\n`,
    { mode: 0o600 }
  );
  process.stdout.write(
    `Export complete. ${userCount} profiles, ${recordCount} Firestore records, ${authCount} Auth accounts.\n`
  );
  process.stdout.write(`Private export directory: ${outputDirectory}\n`);
}

main().catch((error) => {
  process.stderr.write(`${error.message ?? "Firestore export failed."}\n`);
  process.exitCode = 1;
});
