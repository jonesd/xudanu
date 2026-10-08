import { defineConfig } from "vite";

// Phase A dev shape: proxy to a local xudanu-server (default :8080),
// same pattern as web/app — the server sees same-origin traffic.
export default defineConfig({
  base: "./",
  server: {
    port: 5174,
    proxy: {
      "/xudanu": { target: "ws://127.0.0.1:8080", ws: true },
      "/.well-known": "http://127.0.0.1:8080",
      "/health": "http://127.0.0.1:8080",
    },
  },
});
