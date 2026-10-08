import { getAuthUserId } from "@convex-dev/auth/server";
import { action } from "./_generated/server";
import { v } from "convex/values";

const allowedRoles = new Set(["system", "user", "assistant"]);
const maxMessages = 24;
const maxMessageLength = 6000;

/** Server-side DeepSeek proxy. The API key is a Convex secret, never a client value. */
export const chat = action({
  args: {
    messages: v.array(
      v.object({
        role: v.string(),
        content: v.string(),
      })
    ),
  },
  handler: async (ctx, { messages }) => {
    if ((await getAuthUserId(ctx)) === null) {
      throw new Error("Authentication required");
    }
    if (messages.length === 0 || messages.length > maxMessages) {
      throw new Error("Invalid messages");
    }

    const safeMessages = messages.map(({ role, content }) => ({
      role,
      content: content.trim(),
    }));
    if (
      safeMessages.some(
        ({ role, content }) =>
          !allowedRoles.has(role) || !content || content.length > maxMessageLength
      )
    ) {
      throw new Error("Invalid messages");
    }

    const apiKey = process.env.DEEPSEEK_API_KEY;
    if (!apiKey) throw new Error("Assistant is not configured");

    const upstream = await fetch("https://api.deepseek.com/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "deepseek-chat",
        messages: safeMessages,
        temperature: 0.6,
        stream: false,
      }),
    });

    if (!upstream.ok) throw new Error("Assistant unavailable");
    const result: unknown = await upstream.json();
    if (
      typeof result !== "object" ||
      result === null ||
      !("choices" in result) ||
      !Array.isArray(result.choices)
    ) {
      throw new Error("Invalid assistant response");
    }

    const content = result.choices[0]?.message?.content;
    if (typeof content !== "string" || !content.trim()) {
      throw new Error("Invalid assistant response");
    }
    return { content: content.trim() };
  },
});
