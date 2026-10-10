import { ConvexError, v } from "convex/values";
import { action } from "./_generated/server";
import { reserveAiCall } from "./aiAccess";

/**
 * Milo voice dictation: the app records the message (m4a, ≤ 1 min) and sends it here;
 * OpenAI turns it into text. The key stays on the server, the audio is not stored.
 * Same gate as Milo (signed in, subscription, daily quota under "transcribe").
 */

/** ~1 min of 32 kbit/s AAC is ~240 KB: 1.5 MB leaves room without allowing long uploads. */
const maxAudioBytes = 1_500_000;

/** Names the transcriber should spell as the app does. */
const vocabulary =
  "Milo, CortiFree, cortisol, cohérence cardiaque, respiration 4-7-8, méditation, anxiété, sommeil, body scan";

function decodeBase64(data: string): Uint8Array<ArrayBuffer> {
  const binary = atob(data);
  const bytes = new Uint8Array(new ArrayBuffer(binary.length));
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/** The OpenAI call alone (also used by devTools.testTranscribe). */
export async function transcribeWithOpenAI(
  apiKey: string,
  bytes: Uint8Array<ArrayBuffer>,
  mimeType: string,
  language?: string
): Promise<string> {
  const form = new FormData();
  form.append("file", new Blob([bytes], { type: mimeType }), mimeType === "audio/wav" ? "dictation.wav" : "dictation.m4a");
  form.append("model", process.env.OPENAI_TRANSCRIBE_MODEL || "gpt-4o-mini-transcribe");
  form.append("response_format", "json");
  form.append("prompt", `Vocabulary that may appear: ${vocabulary}.`);
  if (language) form.append("language", language);

  const upstream = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}` },
    body: form,
  });
  if (!upstream.ok) throw new Error(`Transcription unavailable (${upstream.status})`);
  const result = (await upstream.json()) as { text?: unknown };
  return typeof result.text === "string" ? result.text.trim() : "";
}

export function decodeAudio(data: string): Uint8Array<ArrayBuffer> {
  return decodeBase64(data);
}

export const audio = action({
  args: {
    /** Base64 of the recording. */
    audio: v.string(),
    mimeType: v.optional(v.string()),
    /** ISO-639-1 code when the user forced a dictation language; otherwise auto-detected. */
    language: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    if (args.audio.length === 0 || args.audio.length > Math.ceil((maxAudioBytes * 4) / 3)) {
      throw new ConvexError("Invalid audio");
    }
    const language = args.language && /^[a-z]{2}$/.test(args.language) ? args.language : undefined;
    const mimeType = args.mimeType === "audio/wav" ? "audio/wav" : "audio/mp4";

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) throw new Error("Transcription is not configured");

    let bytes: Uint8Array<ArrayBuffer>;
    try {
      bytes = decodeBase64(args.audio);
    } catch {
      throw new ConvexError("Invalid audio");
    }

    const reservation = await reserveAiCall(ctx, "transcribe");
    try {
      const text = await transcribeWithOpenAI(apiKey, bytes, mimeType, language);
      return { text, remaining: reservation.remaining };
    } catch (error) {
      await reservation.refund();
      throw error;
    }
  },
});
