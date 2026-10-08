import { Email } from "@convex-dev/auth/providers/Email";

/**
 * One-time code sent by email for the Password provider's `reset` flow.
 *
 * Sending goes through the Resend HTTP API (no SDK needed). Configure:
 *   RESEND_API_KEY   – Resend API key (secret)
 *   AUTH_EMAIL_FROM  – verified sender, e.g. "CortiFree <no-reply@cortifree.app>"
 * Without RESEND_API_KEY the reset flow fails with a clear error; sign-up and
 * sign-in keep working.
 */
export const PasswordResetEmail = Email({
  id: "password-reset",
  maxAge: 60 * 15, // 15 minutes
  async generateVerificationToken() {
    const bytes = new Uint32Array(1);
    crypto.getRandomValues(bytes);
    return String(bytes[0] % 100000000).padStart(8, "0");
  },
  async sendVerificationRequest({ identifier: email, token }) {
    const apiKey = process.env.RESEND_API_KEY;
    if (!apiKey) {
      throw new Error("Password reset email is not configured (RESEND_API_KEY)");
    }
    const from = process.env.AUTH_EMAIL_FROM ?? "CortiFree <onboarding@resend.dev>";
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from,
        to: [email],
        subject: "CortiFree – code de réinitialisation / reset code",
        text:
          `Votre code de réinitialisation CortiFree : ${token}\n` +
          `Your CortiFree reset code: ${token}\n\n` +
          "Ce code expire dans 15 minutes. / This code expires in 15 minutes.",
      }),
    });
    if (!response.ok) {
      throw new Error(`Could not send reset email (${response.status})`);
    }
  },
});
