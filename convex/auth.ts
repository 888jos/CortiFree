import { convexAuth, createAccount } from "@convex-dev/auth/server";
import { ConvexCredentials } from "@convex-dev/auth/providers/ConvexCredentials";
import { Password } from "@convex-dev/auth/providers/Password";
import { ConvexError } from "convex/values";
import { internal } from "./_generated/api";
import { DataModel } from "./_generated/dataModel";
import { verifyAppleIdentityToken } from "./lib/appleIdentity";
import { verifyGoogleIdToken } from "./lib/googleIdentity";
import { PasswordResetEmail } from "./lib/passwordResetEmail";

function normalizeEmail(value: unknown): string {
  if (typeof value !== "string") throw new ConvexError("Missing email");
  const email = value.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254) {
    throw new ConvexError("Invalid email");
  }
  return email;
}

function optionalName(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed ? trimmed.slice(0, 80) : undefined;
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0 || value.length > 8192) {
    throw new ConvexError(`Missing ${field}`);
  }
  return value;
}

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Convex redacts plain `Error` messages in production, so Convex Auth's password
 * failures (wrong password, existing account, bad reset code…) would all reach the
 * app as "Server Error". Re-throw them as ConvexError codes the app maps to messages
 * (AuthFailure in ConvexBackend.swift).
 */
function withReadableErrors<P extends object>(provider: P): P {
  // ConvexCredentials keeps the real `authorize` in its internal `options`.
  const options = (provider as unknown as {
    options: { authorize: (params: Record<string, unknown>, ctx: unknown) => Promise<unknown> };
  }).options;
  const authorize = options.authorize;
  options.authorize = async (params, ctx) => {
    try {
      return await authorize(params, ctx);
    } catch (error) {
      if (error instanceof ConvexError) throw error;
      const message = error instanceof Error ? error.message : String(error);
      // An unknown address answers like a sent reset email: no account enumeration.
      if (params.flow === "reset" && message.includes("InvalidAccountId")) return null;
      if (message.includes("already exists")) throw new ConvexError("Account already exists");
      const code = ["InvalidAccountId", "InvalidSecret", "TooManyFailedAttempts", "Invalid credentials", "Invalid code"]
        .find((known) => message.includes(known));
      throw code ? new ConvexError(code) : error;
    }
  };
  return provider;
}

/**
 * Native-app friendly Convex Auth.
 *
 * Providers (all called through the public action `auth:signIn`):
 *  - "password"      email + password; flows signUp / signIn / reset / reset-verification
 *  - "apple-native"  native Sign in with Apple identity token (+ raw nonce)
 *  - "google-native" native Google Sign-In ID token (needs GOOGLE_CLIENT_IDS)
 *
 * See convex/README.md for the exact payloads used by the Swift client.
 */
export const { auth, signIn, signOut, store, isAuthenticated } = convexAuth({
  // Sessions used to end after 30 days even for daily users (the default total duration).
  // Now they last as long as the app keeps refreshing them at least every 90 days.
  session: {
    totalDurationMs: 10 * 365 * DAY_MS,
    inactiveDurationMs: 90 * DAY_MS,
  },
  providers: [
    withReadableErrors(Password<DataModel>({
      profile(params) {
        const email = normalizeEmail(params.email);
        const firstName = optionalName(params.firstName);
        return {
          email,
          emailCanonical: email,
          ...(firstName ? { firstName, name: firstName } : {}),
        };
      },
      validatePasswordRequirements(password) {
        if (typeof password !== "string" || password.length < 8 || password.length > 256) {
          throw new ConvexError("Password must contain at least 8 characters");
        }
      },
      reset: PasswordResetEmail,
    })),
    ConvexCredentials<DataModel>({
      id: "apple-native",
      authorize: async (params, ctx) => {
        const identityToken = requireString(params.identityToken, "identityToken");
        const nonce = requireString(params.nonce, "nonce");
        const apple = await verifyAppleIdentityToken(identityToken, nonce);
        const firstName = optionalName(params.firstName);
        const { user } = await createAccount<DataModel>(ctx, {
          provider: "apple-native",
          account: { id: apple.sub },
          profile: {
            appleSub: apple.sub,
            ...(apple.email ? { email: apple.email, emailCanonical: apple.email } : {}),
            ...(firstName ? { firstName, name: firstName } : {}),
          },
          // Never auto-link to another user by email: an attacker-controlled
          // password account must not capture an Apple identity.
          shouldLinkViaEmail: false,
          shouldLinkViaPhone: false,
        });
        await ctx.runMutation(internal.account.syncIdentityFields, {
          userId: user._id,
          appleSub: apple.sub,
          email: apple.email,
          emailVerified: apple.emailVerified,
          firstName,
        });
        return { userId: user._id };
      },
    }),
    ConvexCredentials<DataModel>({
      id: "google-native",
      authorize: async (params, ctx) => {
        const idToken = requireString(params.idToken, "idToken");
        const nonce = typeof params.nonce === "string" ? params.nonce : undefined;
        const google = await verifyGoogleIdToken(idToken, nonce);
        const firstName = optionalName(params.firstName) ?? optionalName(google.givenName);
        const { user } = await createAccount<DataModel>(ctx, {
          provider: "google-native",
          account: { id: google.sub },
          profile: {
            googleSub: google.sub,
            ...(google.email ? { email: google.email, emailCanonical: google.email } : {}),
            ...(firstName ? { firstName, name: firstName } : {}),
          },
          shouldLinkViaEmail: false,
          shouldLinkViaPhone: false,
        });
        await ctx.runMutation(internal.account.syncIdentityFields, {
          userId: user._id,
          googleSub: google.sub,
          email: google.email,
          emailVerified: google.emailVerified,
          firstName,
        });
        return { userId: user._id };
      },
    }),
  ],
  callbacks: {
    async afterUserCreatedOrUpdated(ctx, { userId, existingUserId }) {
      if (existingUserId === null) {
        const now = Date.now();
        await ctx.db.patch(userId, { createdAt: now, updatedAt: now });
      }
    },
  },
});
