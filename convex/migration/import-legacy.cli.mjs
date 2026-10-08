#!/usr/bin/env node
// Imports the Firestore exporter output (functions/scripts/export-firestore-for-convex.js)
// into the PRIVATE Convex staging tables (legacyUsers / legacyRecords) in batches,
// through internal mutations called with an admin/deploy key.
//
// This file has two dots in its name, so Convex does not bundle it as a function.
//
// Usage:
//   CONVEX_URL=https://<deployment>.convex.cloud CONVEX_DEPLOY_KEY=<key> \
//     node convex/migration/import-legacy.cli.mjs --dir migration/private/firestore-<ts> --run-id <id> [--batch 100]
//
// The deploy key comes from the Convex dashboard (Settings → Deploy keys) of the
// target deployment (dev first, then prod). Never commit it.

import fs from "node:fs";
import path from "node:path";
import readline from "node:readline";
import crypto from "node:crypto";
import { ConvexHttpClient } from "convex/browser";
import { makeFunctionReference } from "convex/server";

function parseArgs(argv) {
  const options = { batch: 100 };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--dir") options.dir = argv[++i];
    else if (arg === "--run-id") options.runId = argv[++i];
    else if (arg === "--batch") options.batch = Number(argv[++i]);
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!options.dir || !options.runId) throw new Error("Pass --dir <export dir> and --run-id <id>.");
  if (!Number.isInteger(options.batch) || options.batch < 1 || options.batch > 500) {
    throw new Error("--batch must be between 1 and 500");
  }
  return options;
}

async function* readJsonl(file) {
  if (!fs.existsSync(file)) return;
  const rl = readline.createInterface({ input: fs.createReadStream(file), crlfDelay: Infinity });
  for await (const line of rl) {
    if (line.trim()) yield JSON.parse(line);
  }
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const url = process.env.CONVEX_URL;
  const key = process.env.CONVEX_DEPLOY_KEY;
  if (!url || !key) throw new Error("Set CONVEX_URL and CONVEX_DEPLOY_KEY.");

  const client = new ConvexHttpClient(url);
  client.setAdminAuth(key);
  const fn = (name) => makeFunctionReference(`migration/importer:${name}`);

  const dir = path.resolve(options.dir);
  const manifest = JSON.parse(fs.readFileSync(path.join(dir, "manifest.json"), "utf8"));
  const sourceCount = (manifest.legacyUsers?.count ?? 0) + (manifest.legacyRecords?.count ?? 0);
  await client.mutation(fn("startRun"), {
    runId: options.runId,
    sourceDocumentCount: sourceCount,
    sourceDigest: `${manifest.legacyUsers?.sha256 ?? ""}:${manifest.legacyRecords?.sha256 ?? ""}`,
  });

  // 1) Firebase Auth accounts → identity keys (email, Apple sub, Google sub).
  const identities = new Map();
  for await (const account of readJsonl(path.join(dir, "legacyAuthUsers.jsonl"))) {
    const apple = account.providerData?.find((p) => p.providerId === "apple.com");
    const google = account.providerData?.find((p) => p.providerId === "google.com");
    identities.set(account.uid, {
      email: account.email?.trim().toLowerCase(),
      appleSub: apple?.uid,
      googleSub: google?.uid,
      providers: (account.providerData ?? []).map((p) => p.providerId),
    });
  }

  // 2) users/{uid} profiles (+ identity keys).
  const digest = crypto.createHash("sha256");
  let imported = 0;
  let batch = [];
  const seenUids = new Set();
  const flushUsers = async () => {
    if (batch.length === 0) return;
    const result = await client.mutation(fn("importLegacyUsers"), { runId: options.runId, rows: batch });
    imported += result.written;
    batch = [];
  };
  for await (const row of readJsonl(path.join(dir, "legacyUsers.jsonl"))) {
    seenUids.add(row.firebaseUid);
    const identity = identities.get(row.firebaseUid) ?? {};
    const out = {
      firebaseUid: row.firebaseUid,
      emailCanonical: identity.email ?? row.emailCanonical,
      appleSub: identity.appleSub,
      googleSub: identity.googleSub,
      authProviders: identity.providers ?? [],
      profile: row.profile ?? {},
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
    digest.update(JSON.stringify(out));
    batch.push(JSON.parse(JSON.stringify(out)));
    if (batch.length >= options.batch) await flushUsers();
  }
  // Auth accounts without a Firestore profile still need identity keys so their
  // subcollections can be claimed.
  for (const [firebaseUid, identity] of identities) {
    if (seenUids.has(firebaseUid)) continue;
    const out = JSON.parse(
      JSON.stringify({
        firebaseUid,
        emailCanonical: identity.email,
        appleSub: identity.appleSub,
        googleSub: identity.googleSub,
        authProviders: identity.providers ?? [],
        profile: {},
        createdAt: manifest.exportedAt,
        updatedAt: manifest.exportedAt,
      })
    );
    batch.push(out);
    if (batch.length >= options.batch) await flushUsers();
  }
  await flushUsers();
  process.stdout.write(`legacyUsers: ${imported}\n`);

  // 3) Every other Firestore document → legacyRecords (path preserved).
  let records = 0;
  let recordBatch = [];
  const flushRecords = async () => {
    if (recordBatch.length === 0) return;
    const result = await client.mutation(fn("importLegacyRecords"), {
      runId: options.runId,
      rows: recordBatch,
    });
    records += result.written;
    recordBatch = [];
  };
  for await (const row of readJsonl(path.join(dir, "legacyRecords.jsonl"))) {
    digest.update(JSON.stringify(row));
    recordBatch.push(row);
    if (recordBatch.length >= options.batch) await flushRecords();
  }
  await flushRecords();
  process.stdout.write(`legacyRecords: ${records}\n`);

  await client.mutation(fn("finishRun"), {
    runId: options.runId,
    importedDocumentCount: imported + records,
    importedDigest: digest.digest("hex"),
  });
  process.stdout.write("Import finished. Users claim their data with account:claimLegacyData.\n");
}

main().catch((error) => {
  process.stderr.write(`${error.message ?? error}\n`);
  process.exitCode = 1;
});
