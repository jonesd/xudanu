import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

const backend = `http://localhost:${process.env.BACKEND_PORT || "8080"}`;

export default defineConfig({
  plugins: [react()],
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
  },
});
