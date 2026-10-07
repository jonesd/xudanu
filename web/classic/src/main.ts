import { ClassicClient, type TrailEntry } from "./client";

const app = document.getElementById("app")!;
let client: ClassicClient | null = null;

type View =
  | { kind: "empty" }
  | { kind: "work"; workId: number; title: string; text: string }
  | { kind: "trail"; trail: TrailEntry };

let view: View = { kind: "empty" };

function esc(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function render(): void {
  if (!client) {
    app.innerHTML = `<div class="gate">
      <h1>Xudanu <span>classic</span></h1>
      <p class="quiet">A reading posture for the docuverse.<br>Read-only; speaks the wire contract, api_version 1.</p>
      <button id="connect">connect</button>
      <p id="gate-status" class="quiet"></p>
    </div>`;
    document.getElementById("connect")!.onclick = async () => {
      const status = document.getElementById("gate-status")!;
      status.textContent = "connecting…";
      try {
        client = new ClassicClient();
        await client.connect();
        render();
      } catch (e) {
        status.textContent = String(e instanceof Error ? e.message : e);
      }
    };
    return;
  }

  const sideTrails = trailHtml();
  const main = mainHtml();
  app.innerHTML = `
    <header>
      <span class="mark">Xudanu <span>classic</span></span>
      <span class="quiet">${esc(client.serverName)} · v${esc(client.serverVersion || "?")} · api ${client.apiVersion}</span>
    </header>
    <div class="frame">
      <nav>
        <form id="search"><input id="q" placeholder="search the docuverse" autocomplete="off"></form>
        <div id="results"></div>
        ${sideTrails}
      </nav>
      <main>${main}</main>
    </div>`;

  document.getElementById("search")!.onsubmit = async (ev) => {
    ev.preventDefault();
    const q = (document.getElementById("q") as HTMLInputElement).value.trim();
    if (!q || !client) return;
    try {
      const entries = await client.search(q);
      document.getElementById("results")!.innerHTML =
        entries.length === 0
          ? `<p class="quiet small">nothing found</p>`
          : entries
              .map(
                (e) =>
                  `<a href="#" data-work="${e.work_id}">${esc(e.title || `work ${e.work_id}`)}</a>`,
              )
              .join("");
      wireLinks();
    } catch (e) {
      document.getElementById("results")!.innerHTML =
        `<p class="quiet small">${esc(String(e instanceof Error ? e.message : e))}</p>`;
    }
  };
  wireLinks();
  wireTrailLinks();
}

async function openWork(workId: number): Promise<void> {
  if (!client) return;
  const text = await client.readWork(workId);
  view = { kind: "work", workId, title: `work ${workId}`, text };
  const titled = text.split("\n")[0].slice(0, 72);
  view.title = titled || `work ${workId}`;
  render();
}

function trailHtml(): string {
  if (!client) return "";
  client
    .trails()
    .then((ts) => {
      const el = document.getElementById("trails");
      if (el) {
        el.innerHTML =
          `<h3>trails</h3>` +
          ts.map((t) => `<a href="#" class="trail" data-trail="${t.trail_id}">${esc(t.name)}</a>`).join("");
        wireTrailLinks();
      }
    })
    .catch(() => {});
  return `<div id="trails"></div>`;
}

function mainHtml(): string {
  if (view.kind === "work") {
    return `<article><h2>${esc(view.title)}</h2><pre class="prose">${esc(view.text)}</pre></article>`;
  }
  if (view.kind === "trail") {
    return `<article><h2>${esc(view.trail.name)}</h2>
      ${view.trail.introduction ? `<p class="quiet">${esc(view.trail.introduction)}</p>` : ""}
      <ol class="stops">${view.trail.stops
        .map(
          (s) =>
            `<li><a href="#" data-work="${s.work_id}">${esc(s.title || `work ${s.work_id}`)}</a>` +
            `${s.note ? `<span class="quiet"> — ${esc(s.note)}</span>` : ""}</li>`,
        )
        .join("")}</ol></article>`;
  }
  return `<article><p class="quiet">Search, or follow a trail. Everything here is read-only —
    the writing posture lives in the reference UI; this is the reading one.</p></article>`;
}

function wireLinks(): void {
  document.querySelectorAll<HTMLAnchorElement>("a[data-work]").forEach((a) => {
    a.onclick = (ev) => {
      ev.preventDefault();
      void openWork(Number(a.dataset.work));
    };
  });
}

let trailCache: TrailEntry[] = [];

function wireTrailLinks(): void {
  document.querySelectorAll<HTMLAnchorElement>("a[data-trail]").forEach((a) => {
    a.onclick = (ev) => {
      ev.preventDefault();
      const t = trailCache.find((x) => x.trail_id === Number(a.dataset.trail));
      if (t) {
        view = { kind: "trail", trail: t };
        render();
      }
    };
  });
}

const origTrails = ClassicClient.prototype.trails;
ClassicClient.prototype.trails = async function (): Promise<TrailEntry[]> {
  const ts = await origTrails.call(this);
  trailCache = ts;
  return ts;
};

render();
