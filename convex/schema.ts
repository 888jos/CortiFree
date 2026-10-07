import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

/**
 * Migration staging schema. Legacy rows are deliberately separate from live
 * application rows so importing production data cannot expose it to clients.
 */
export default defineSchema({
  users: defineTable({
    authSubject: v.optional(v.string()),
    emailCanonical: v.optional(v.string()),
    legacyFirebaseUid: v.optional(v.string()),
    profile: v.optional(v.any()),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_authSubject", ["authSubject"])
    .index("by_emailCanonical", ["emailCanonical"])
    .index("by_legacyFirebaseUid", ["legacyFirebaseUid"]),

  /** Imported Firestore documents; kept private until identity linking passes. */
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

  /** Normalized, authenticated application records after each cutover step. */
  userRecords: defineTable({
    ownerId: v.id("users"),
    recordKey: v.string(),
    kind: v.string(),
    data: v.any(),
    revision: v.number(),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_owner_recordKey", ["ownerId", "recordKey"])
    .index("by_owner_kind", ["ownerId", "kind"]),

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
