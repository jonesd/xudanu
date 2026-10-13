import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import pkg from "./package.json" with { type: "json" };

const backend = `http://127.0.0.1:${process.env.BACKEND_PORT || "8080"}`;

export default defineConfig({
  plugins: [react()],
  define: {
    __APP_VERSION__: JSON.stringify(pkg.version),
  },
  optimizeDeps: {
    include: ["@uiw/react-md-editor"],
  },
  server: {
    proxy: {
      "/api": {
        target: backend,
        changeOrigin: true,
      },
      "/xudanu": {
        target: backend,
        ws: true,
        changeOrigin: true,
        timeout: 0,
        configure: (proxy) => {
          proxy.on("error", (err: Error) => {
            console.log("[ws proxy] error:", err.message);
          });
        },
      },
      "/csrf-token": {
        target: backend,
        changeOrigin: true,
      },
      "/health": {
        target: backend,
        changeOrigin: true,
      },
      "/.well-known": {
        target: backend,
        changeOrigin: true,
      },
      "/auth": {
        target: backend,
        changeOrigin: true,
      },
    },
  },
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: "./src/setupTests.ts",
    exclude: ["**/e2e/**", "**/node_modules/**", "**/dist/**"],
    coverage: {
      provider: "v8",
      // Honest measurement: every source file counts, loaded or not.
      include: ["src/**/*.{ts,tsx}"],
      exclude: [
        "src/__tests__/**",
        "src/setupTests.ts",
        "src/main.tsx",
        "src/globals.d.ts",
        // Type-only modules: no runtime code to cover.
        "src/types/**",
      ],
      reporter: ["text", "json-summary", "json", "html"],
      // Coverage-plan-web.md ratchet: raises per phase, 80% at the end.
      // Never let it drift below the shipped phase floor.
      thresholds: {
        lines: 45,
        functions: 38,
        branches: 37,
      },
    },
  },
});
