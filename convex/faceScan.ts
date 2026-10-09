import { ConvexError, v } from "convex/values";
import { action } from "./_generated/server";
import { reserveAiCall } from "./aiAccess";

/**
 * Weekly face check: describes visible signs of tiredness on a selfie (puffiness, dark
 * circles, jaw tension, dull skin). Wellness only: no cortisol, no diagnosis.
 * The photo is forwarded to OpenAI for this single request and never stored by CortiFree.
 * Needs the Convex secret OPENAI_API_KEY (optional OPENAI_FACE_MODEL, default gpt-5-mini).
 * Gated by the server-verified subscription and a daily quota (aiAccess.ts).
 */
const maxImageLength = 900_000; // base64 JPEG, ~650 KB

const prompt = (language: string) => `You are Milo, the calm companion of the CortiFree wellbeing app. The user takes a selfie once a week to follow visible signs of tiredness and tension over their 28-day plan.
Describe ONLY what is visible on the face, kindly and neutrally. Never comment on attractiveness, weight, age, gender, ethnicity or skin colour. Never mention cortisol, hormones, illness or any diagnosis, and never claim to measure stress.
Reply ONLY with a JSON object:
{"face": true, "rested_score": 0-100, "puffiness": "low|medium|high", "dark_circles": "low|medium|high", "jaw_tension": "low|medium|high", "skin_dullness": "low|medium|high", "summary": "...", "tip": "..."}
- rested_score: 100 = looks very rested, 0 = looks very tired.
- summary: two short, warm sentences in ${language} about what you notice (for example "Your eyes look a bit puffy this morning and your jaw seems tight.").
- tip: one concrete, gentle thing to do today in ${language} (breathing, water before coffee, an early night, unclenching the jaw…).
If there is no clearly visible face, or several faces, or the photo is too dark or blurry, reply {"face": false}.`;

export const analyze = action({
  args: { image: v.string(), language: v.string() },
  handler: async (ctx, { image, language }) => {
    if (!image || image.length > maxImageLength || !/^[A-Za-z0-9+/=]+$/.test(image)) {
      throw new ConvexError("Invalid image");
    }
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) throw new Error("Face check is not configured");
    const model = process.env.OPENAI_FACE_MODEL || "gpt-5-mini";

    const reservation = await reserveAiCall(ctx, "faceScan");
    try {
      return { ...(await requestAnalysis(apiKey, model, image, language)), remaining: reservation.remaining };
    } catch (error) {
      await reservation.refund();
      throw error;
    }
  },
});

async function requestAnalysis(apiKey: string, model: string, image: string, language: string) {
  const upstream = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      response_format: { type: "json_object" },
      max_completion_tokens: 600,
      messages: [
        { role: "system", content: prompt(language.replace(/[^\p{L}\p{M} ()-]/gu, "").trim().slice(0, 40) || "English") },
        {
          role: "user",
          content: [
            { type: "text", text: "Here is my weekly selfie." },
            { type: "image_url", image_url: { url: `data:image/jpeg;base64,${image}`, detail: "low" } },
          ],
        },
      ],
    }),
  });

  if (!upstream.ok) throw new Error("Face check unavailable");
  const result: unknown = await upstream.json();
  if (
    typeof result !== "object" ||
    result === null ||
    !("choices" in result) ||
    !Array.isArray(result.choices)
  ) {
    throw new Error("Invalid face check response");
  }
  const content = result.choices[0]?.message?.content;
  if (typeof content !== "string" || !content.trim()) {
    throw new Error("Invalid face check response");
  }
  return { content: content.trim() };
}
