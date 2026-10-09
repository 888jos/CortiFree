import { defineConfig } from "vitest/config";

// Run with: npm run test:convex  (file has two dots → not bundled by Convex)
export default defineConfig({
  test: {
    root: import.meta.dirname,
    environment: "edge-runtime",
    testTimeout: 60000,
    server: { deps: { inline: ["convex-test"] } },
  },
});
