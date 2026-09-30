// Xudanu Overlay — MV3 service worker.
//
// Minimal by design (FR-79 Stage 2): no content_scripts in the
// manifest; the user opts in per server on the options page, which
// grants optional host permissions and dynamically registers the
// content script. This worker relays marks queries (the content
// script never fetches on its own) and manages that registration.

const CONTENT_SCRIPT_ID = "xudanu-overlay";

async function getConfig() {
  const { serverUrl, enabled } = await chrome.storage.local.get({
    serverUrl: "",
    enabled: false,
  });
  return { serverUrl: serverUrl.replace(/\/+$/, ""), enabled };
}

async function registerOverlay() {
  // Register for all granted hosts. The permission grant itself is
  // the user's scoping decision (options page requests it once).
  await chrome.scripting.registerContentScripts([
    {
      id: CONTENT_SCRIPT_ID,
      matches: ["http://*/*", "https://*/*"],
      js: ["content.js"],
      runAt: "document_idle",
      persistAcrossSessions: true,
    },
  ]);
}

async function unregisterOverlay() {
  const existing = await chrome.scripting.getRegisteredContentScripts();
  if (existing.some((s) => s.id === CONTENT_SCRIPT_ID)) {
    await chrome.scripting.unregisterContentScripts({
      ids: [CONTENT_SCRIPT_ID],
    });
  }
}

chrome.runtime.onInstalled.addListener(async () => {
  const { serverUrl } = await getConfig();
  if (!serverUrl) {
    chrome.runtime.openOptionsPage();
  }
});

chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  (async () => {
    try {
      switch (msg?.type) {
        case "marks": {
          const { serverUrl } = await getConfig();
          if (!serverUrl) return sendResponse({ ok: false, error: "no server configured" });
          const res = await fetch(serverUrl + "/api/overlay/marks", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ url: msg.url, page_text: msg.text }),
          });
          if (res.status === 429) {
            return sendResponse({ ok: false, error: "rate limited", retryAfterMs: 60000 });
          }
          if (!res.ok) {
            return sendResponse({ ok: false, error: "server " + res.status });
          }
          const etag = res.headers.get("etag") || "";
          const body = await res.json();
          return sendResponse({ ok: true, body, etag });
        }
        case "ping": {
          const base = String(msg.serverUrl || "").replace(/\/+$/, "");
          if (!/^https?:\/\//.test(base)) {
            return sendResponse({ ok: false, error: "url must start with http(s)://" });
          }
          try {
            const res = await fetch(base + "/health");
            const j = await res.json().catch(() => null);
            return sendResponse({ ok: res.ok && !!j, body: j });
          } catch (e) {
            return sendResponse({ ok: false, error: String(e) });
          }
        }
        case "enable": {
          const granted = await chrome.permissions.request({
            origins: ["http://*/*", "https://*/*"],
          });
          if (!granted) return sendResponse({ ok: false, error: "host permission denied" });
          await unregisterOverlay();
          await registerOverlay();
          await chrome.storage.local.set({ enabled: true });
          return sendResponse({ ok: true });
        }
        case "disable": {
          await unregisterOverlay();
          await chrome.storage.local.set({ enabled: false });
          return sendResponse({ ok: true });
        }
        default:
          return sendResponse({ ok: false, error: "unknown message" });
      }
    } catch (e) {
      return sendResponse({ ok: false, error: String(e) });
    }
  })();
  return true; // async sendResponse
});
