// Xudanu Overlay options page.

const $ = (id) => document.getElementById(id);

async function refreshStatus() {
  const { enabled } = await chrome.storage.local.get({ enabled: false });
  $("enable").disabled = enabled;
  $("disable").disabled = !enabled;
}

function status(text, ok) {
  const el = $("status");
  el.textContent = text;
  el.className = ok ? "ok" : "err";
}

function send(msg) {
  return new Promise((resolve) => chrome.runtime.sendMessage(msg, resolve));
}

$("save").addEventListener("click", async () => {
  const url = $("server").value.trim().replace(/\/+$/, "");
  if (!/^https?:\/\//.test(url)) {
    status("Server URL must start with http:// or https://", false);
    return;
  }
  await chrome.storage.local.set({ serverUrl: url });
  status("Saved. Test the connection, then enable the overlay.", true);
});

$("test").addEventListener("click", async () => {
  const url = $("server").value.trim().replace(/\/+$/, "");
  const res = await send({ type: "ping", serverUrl: url });
  if (res?.ok) {
    status("Connected — server is alive.", true);
  } else {
    status("Could not reach server: " + (res?.error || "unknown"), false);
  }
});

$("enable").addEventListener("click", async () => {
  const url = $("server").value.trim().replace(/\/+$/, "");
  if (!/^https?:\/\//.test(url)) {
    status("Set the server URL first.", false);
    return;
  }
  await chrome.storage.local.set({ serverUrl: url });
  // permissions.request MUST run here, inside the click's user-gesture
  // context: a gesture does not survive the sendMessage hop to the
  // service worker, and the SW-side call fails with "This function
  // must be called during a user gesture" (the bug that blocked the
  // production-manifest flow — see MANUAL-TEST.md).
  const granted = await chrome.permissions.request({
    origins: ["http://*/*", "https://*/*"],
  });
  if (!granted) {
    status("Overlay needs host permission to run — Enable was cancelled.", false);
    refreshStatus();
    return;
  }
  const res = await send({ type: "enable" });
  if (res?.ok) {
    status("Overlay enabled. Reload any open tabs, then visit a page your shadows point at.", true);
  } else {
    status("Enable failed: " + (res?.error || "unknown"), false);
  }
  refreshStatus();
});

$("disable").addEventListener("click", async () => {
  await send({ type: "disable" });
  status("Overlay disabled.", true);
  refreshStatus();
});

(async () => {
  const { serverUrl } = await chrome.storage.local.get({ serverUrl: "" });
  $("server").value = serverUrl;
  refreshStatus();
})();
