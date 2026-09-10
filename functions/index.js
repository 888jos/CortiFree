const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const deepSeekApiKey = defineSecret("DEEPSEEK_API_KEY");

const allowedRoles = new Set(["system", "user", "assistant"]);
const maxMessages = 24;
const maxMessageLength = 6000;

exports.deepSeekChat = onRequest(
  {
    region: "us-central1",
    cors: false,
    secrets: [deepSeekApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({ error: "Method not allowed" });
      return;
    }

    const messages = request.body?.messages;
    if (!Array.isArray(messages) || messages.length === 0 || messages.length > maxMessages) {
      response.status(400).json({ error: "Invalid messages" });
      return;
    }

    const sanitizedMessages = messages.map((message) => ({
      role: message?.role,
      content: typeof message?.content === "string" ? message.content.trim() : "",
    }));

    const invalidMessage = sanitizedMessages.some(
      (message) =>
        !allowedRoles.has(message.role) ||
        !message.content ||
        message.content.length > maxMessageLength
    );

    if (invalidMessage) {
      response.status(400).json({ error: "Invalid message content" });
      return;
    }

    try {
      const upstream = await fetch("https://api.deepseek.com/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${deepSeekApiKey.value()}`,
        },
        body: JSON.stringify({
          model: "deepseek-chat",
          messages: sanitizedMessages,
          temperature: 0.6,
          stream: false,
        }),
      });

      const data = await upstream.json();
      if (!upstream.ok) {
        logger.error("DeepSeek request failed", { status: upstream.status });
        response.status(502).json({ error: "Assistant unavailable" });
        return;
      }

      const content = data?.choices?.[0]?.message?.content;
      if (typeof content !== "string" || !content.trim()) {
        response.status(502).json({ error: "Invalid assistant response" });
        return;
      }

      response.status(200).json({ content: content.trim() });
    } catch (error) {
      logger.error("DeepSeek proxy error", error);
      response.status(502).json({ error: "Assistant unavailable" });
    }
  }
);
