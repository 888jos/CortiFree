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
  providers: [
    Password<DataModel>({
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
    }),
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
