/* Xudanu service worker — offline app shell (PWA).
   Strategy:
   - Precache: the built index.html + hashed assets (the list arrives
     via the registration message from the app, which knows its build).
   - Runtime: cache-first for same-origin static assets; network-only
     for /api, /xudanu (WS), /csrf-token, /auth — live data must never
     be stale-served. Document content offline is handled by the
     IndexedDB mirror in offline-cache.ts, NOT by this SW. */

const SHELL_CACHE = "xudanu-shell-v2";
const RUNTIME_CACHE = "xudanu-runtime-v2";

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(SHELL_CACHE).then((c) => c.addAll(["/"])).then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter((k) => k !== SHELL_CACHE && k !== RUNTIME_CACHE)
            .map((k) => caches.delete(k)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

const NEVER_CACHE = ["/api/", "/xudanu", "/csrf-token", "/auth", "/health"];

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;
  if (event.request.method !== "GET") return;
  if (NEVER_CACHE.some((p) => url.pathname.startsWith(p))) return;

  // Navigations: network-first (fresh app), shell fallback offline.
  if (event.request.mode === "navigate") {
    event.respondWith(
      fetch(event.request)
        .then((resp) => {
          const copy = resp.clone();
          caches.open(SHELL_CACHE).then((c) => c.put("/", copy)).catch(() => {});
          return resp;
        })
        .catch(() => caches.match("/").then((m) => m || caches.match(event.request))),
    );
    return;
  }

  // Static assets: cache-first (immutable hashed filenames).
  event.respondWith(
    caches.match(event.request).then(
      (hit) =>
        hit ||
        fetch(event.request).then((resp) => {
          if (resp.ok) {
            const copy = resp.clone();
            caches.open(RUNTIME_CACHE).then((c) => c.put(event.request, copy)).catch(() => {});
          }
          return resp;
        }),
    ),
  );
});

