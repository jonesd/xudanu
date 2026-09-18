import { createRoot } from "react-dom/client";
import App from "./App";

// Fonts bundled locally (replaces runtime Google Fonts imports)
import "@fontsource/inter/300.css";
import "@fontsource/inter/400.css";
import "@fontsource/inter/500.css";
import "@fontsource/inter/600.css";
import "@fontsource/inter/700.css";
import "@fontsource/inter/800.css";
import "@fontsource/orbitron/500.css";
import "@fontsource/orbitron/700.css";
import "@fontsource/orbitron/900.css";
import "@fontsource/jetbrains-mono/400.css";
import "@fontsource/jetbrains-mono/500.css";
import "@fontsource/jetbrains-mono/600.css";
import "@fontsource/source-serif-4/300.css";
import "@fontsource/source-serif-4/400.css";
import "@fontsource/source-serif-4/500.css";
import "@fontsource/source-serif-4/600.css";
import "@fontsource/source-serif-4/700.css";

import "./app.css";

// Build marker — one glance at the console answers "is this tab
// running current code?" (the SW-shadowing saga made this necessary).
console.info("[xudanu-ui] build 2026-09-18c");

createRoot(document.getElementById("root")!).render(
  <App />,
);

// PWA: register the service worker (app-shell offline; document content
// is mirrored in IndexedDB by offline-cache.ts). PRODUCTION ONLY — in
// dev the SW's cached shell shadows Vite: new tabs get stale modules
// with a dead HMR token, which surfaces as duplicate-React crashes
// ("Invalid hook call") and edits that never arrive (found the hard
// way, Sept 2026). Dev correctness comes from Vite, not the SW.
if (import.meta.env.PROD && "serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/sw.js").catch(() => {
      /* offline shell is best-effort */
    });
  });
}
