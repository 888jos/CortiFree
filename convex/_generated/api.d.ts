/* eslint-disable */
/**
 * Generated `api` utility.
 *
 * THIS CODE IS AUTOMATICALLY GENERATED.
 *
 * To regenerate, run `npx convex dev`.
 * @module
 */

import type * as account from "../account.js";
import type * as achievements from "../achievements.js";
import type * as assistant from "../assistant.js";
import type * as auth from "../auth.js";
import type * as baseline from "../baseline.js";
import type * as checkins from "../checkins.js";
import type * as faceScan from "../faceScan.js";
import type * as feedback from "../feedback.js";
import type * as habits from "../habits.js";
import type * as http from "../http.js";
import type * as journal from "../journal.js";
import type * as lib_appleIdentity from "../lib/appleIdentity.js";
import type * as lib_googleIdentity from "../lib/googleIdentity.js";
import type * as lib_passwordResetEmail from "../lib/passwordResetEmail.js";
import type * as lib_session from "../lib/session.js";
import type * as migration_claim from "../migration/claim.js";
import type * as migration_importer from "../migration/importer.js";
import type * as migration_media from "../migration/media.js";
import type * as migration_transform from "../migration/transform.js";
import type * as plan from "../plan.js";
import type * as profile from "../profile.js";
import type * as progress from "../progress.js";
import type * as recovery from "../recovery.js";
import type * as settings from "../settings.js";
import type * as tasks from "../tasks.js";
import type * as todos from "../todos.js";

import type {
  ApiFromModules,
  FilterApi,
  FunctionReference,
} from "convex/server";

declare const fullApi: ApiFromModules<{
  account: typeof account;
  achievements: typeof achievements;
  assistant: typeof assistant;
  auth: typeof auth;
  baseline: typeof baseline;
  checkins: typeof checkins;
  faceScan: typeof faceScan;
  feedback: typeof feedback;
  habits: typeof habits;
  http: typeof http;
  journal: typeof journal;
  "lib/appleIdentity": typeof lib_appleIdentity;
  "lib/googleIdentity": typeof lib_googleIdentity;
  "lib/passwordResetEmail": typeof lib_passwordResetEmail;
  "lib/session": typeof lib_session;
  "migration/claim": typeof migration_claim;
  "migration/importer": typeof migration_importer;
  "migration/media": typeof migration_media;
  "migration/transform": typeof migration_transform;
  plan: typeof plan;
  profile: typeof profile;
  progress: typeof progress;
  recovery: typeof recovery;
  settings: typeof settings;
  tasks: typeof tasks;
  todos: typeof todos;
}>;

/**
 * A utility for referencing Convex functions in your app's public API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = api.myModule.myFunction;
 * ```
 */
export declare const api: FilterApi<
  typeof fullApi,
  FunctionReference<any, "public">
>;

/**
 * A utility for referencing Convex functions in your app's internal API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = internal.myModule.myFunction;
 * ```
 */
export declare const internal: FilterApi<
  typeof fullApi,
  FunctionReference<any, "internal">
>;

export declare const components: {};
