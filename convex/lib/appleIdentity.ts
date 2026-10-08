import { createRemoteJWKSet, jwtVerify } from "jose";

const APPLE_ISSUER = "https://appleid.apple.com";
const appleJwks = createRemoteJWKSet(new URL("https://appleid.apple.com/auth/keys"));

export type AppleIdentity = {
  sub: string;
  email?: string;
  emailVerified: boolean;
  isPrivateEmail: boolean;
};

function allowedAudiences(): string[] {
  const raw = process.env.APPLE_BUNDLE_ID ?? "com.solstys.cortifree";
  return raw
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
}

async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function truthy(value: unknown): boolean {
  return value === true || value === "true";
}

/**
 * Verifies a native Sign in with Apple identity token (JWT from
 * ASAuthorizationAppleIDCredential.identityToken): RS256 signature against
 * Apple's JWKS, issuer, audience (= iOS bundle id), expiry, and the nonce.
 *
 * The client must generate a random raw nonce, set
 * `request.nonce = sha256(rawNonce)` (hex), and send the raw nonce here.
 */
export async function verifyAppleIdentityToken(
  identityToken: string,
  rawNonce: string
): Promise<AppleIdentity> {
  const { payload } = await jwtVerify(identityToken, appleJwks, {
    issuer: APPLE_ISSUER,
    audience: allowedAudiences(),
    algorithms: ["RS256"],
    clockTolerance: 60,
  });
  if (typeof payload.sub !== "string" || payload.sub.length === 0) {
    throw new Error("Invalid Apple identity token");
  }
  const expectedNonce = await sha256Hex(rawNonce);
  if (typeof payload.nonce !== "string" || payload.nonce !== expectedNonce) {
    throw new Error("Invalid Apple identity token nonce");
  }
  const email =
    typeof payload.email === "string" ? payload.email.trim().toLowerCase() : undefined;
  return {
    sub: payload.sub,
    email,
    emailVerified: truthy(payload.email_verified),
    isPrivateEmail: truthy(payload.is_private_email),
  };
}
