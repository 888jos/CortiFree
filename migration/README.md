# Firebase → Convex migration staging

This directory is reserved for private, temporary migration artifacts and is
ignored by Git. The exporter sets restrictive local file permissions, but does
not encrypt files itself: use an encrypted disk/volume and securely erase the
export after the rollback window. Never put service-account keys, user exports,
journal text, or photo data in tracked files.

The Convex schema currently keeps imported documents in `legacyRecords`; these
rows must remain inaccessible to client queries until each Firebase identity is
linked to a verified Convex identity. `migrationRuns` is the audit ledger for
counts and digests. Do not use `--replace-all` against production.

Before any export/import:

1. Record Firestore/Auth counts and storage usage, then take a recoverable source
   backup. Estimate the one-time read and storage cost first. The provided
   exporter refuses to run unless both `--confirm-read-cost` and
   `--writes-paused` are explicitly passed.
2. Export to an encrypted local directory, transform Firestore values (including
   timestamps, references and bytes), and preserve each complete document path.
3. Import to a Convex development deployment and compare per-collection counts,
   per-user counts and deterministic digests. Resolve every mismatch before
   proceeding.
4. Keep Firebase as the source of truth during a dual-write/shadow-read period.
   All writes must have stable idempotency keys and a retry queue.
5. Cut over behind feature flags. Keep Firebase read-only and retain the export
   until the rollback window and old-app support window have both ended.

The exporter queries the collection groups currently found in the app and also
exports Firebase Auth metadata. Password hashes are excluded unless explicitly
requested with `--include-password-hashes`; Firebase may require a special IAM
permission to return them. The script is an initial controlled snapshot, not a
live replication mechanism. Any writes after it starts must be frozen or
captured and replayed before the cutover.

Authentication, the analytics dashboard, and the DeepSeek proxy are separate
cutover tracks. No Firebase resource should be removed as part of data import.

## Current staged state

- The analytics dashboard now reads onboarding event analytics from Amplitude
  through its local server proxy and makes no Firestore requests. It deliberately
  shows account, revenue, subscription, habit, and retention figures as
  unavailable where those values are not present in the Amplitude event stream.
- The iOS app now talks only to Convex (Debug → dev `reliable-oyster-468`,
  Release → prod `compassionate-jackal-621`); the Firebase SDK is no longer linked.
  Existing users' Firestore data is not imported yet, so Firebase Auth/Firestore
  must stay enabled (read-only source) until the export/import below is done.
- No production Firestore/Auth export or import has been run. The local Firebase
  CLI/ADC authorization and a cost estimate are still prerequisites.
- The exporter reads every matching document once (plus Auth account listing),
  so the explicit flags are an acknowledgement, not a guarantee of zero cost.
  The Firestore console is on the Spark plan; do not enable billing just to run
  a managed export without the owner's explicit cost decision.

The previous dashboard HTML contained a RevenueCat secret in browser code. That
direct request has been removed; rotate that credential in RevenueCat because
client-side credentials should be treated as exposed. Do not put its replacement
in this repository or in browser JavaScript; add a server-side proxy only after
the credential is supplied through a private environment variable.
