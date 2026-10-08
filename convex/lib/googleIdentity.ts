import { createRemoteJWKSet, jwtVerify } from "jose";

const googleJwks = createRemoteJWKSet(new URL("https://www.googleapis.com/oauth2/v3/certs"));

export type GoogleIdentity = {
  sub: string;
  email?: string;
  emailVerified: boolean;
  name?: string;
  givenName?: string;
};

/**
 * Verifies a native Google Sign-In ID token (GIDGoogleUser.idToken.tokenString).
 * Audience = the iOS OAuth client id(s) in GOOGLE_CLIENT_IDS (comma separated).
 * If the client passes a raw nonce, it must equal the token's `nonce` claim.
 */
export async function verifyGoogleIdToken(
  idToken: string,
  nonce?: string
): Promise<GoogleIdentity> {
  const audiences = (process.env.GOOGLE_CLIENT_IDS ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  if (audiences.length === 0) {
    throw new Error("Google sign-in is not configured (GOOGLE_CLIENT_IDS)");
  }
  const { payload } = await jwtVerify(idToken, googleJwks, {
    issuer: ["https://accounts.google.com", "accounts.google.com"],
    audience: audiences,
    algorithms: ["RS256"],
    clockTolerance: 60,
  });
  if (typeof payload.sub !== "string" || payload.sub.length === 0) {
    throw new Error("Invalid Google ID token");
  }
  if (nonce !== undefined && payload.nonce !== nonce) {
    throw new Error("Invalid Google ID token nonce");
  }
  return {
    sub: payload.sub,
    email: typeof payload.email === "string" ? payload.email.trim().toLowerCase() : undefined,
    emailVerified: payload.email_verified === true || payload.email_verified === "true",
    name: typeof payload.name === "string" ? payload.name : undefined,
    givenName: typeof payload.given_name === "string" ? payload.given_name : undefined,
  };
}
