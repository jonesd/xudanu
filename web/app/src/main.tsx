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

createRoot(document.getElementById("root")!).render(
  <App />,
);

// PWA: register the service worker (app-shell offline; document content
// is mirrored in IndexedDB by offline-cache.ts). Debug builds too — the
// SW is small and correctness matters everywhere.
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/sw.js").catch(() => {
      /* offline shell is best-effort */
    });
  });
}
