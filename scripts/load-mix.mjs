// Mixed-load capacity probe for a Xudanu server.
//
// Spawns concurrent READER and WRITER sessions over the same wire
// ops the browser uses, ramps through stages, and reports latency
// percentiles + error rates per op class. Writes touch ONLY
// QA-LOAD-* works (archived at the end unless --keep).
//
// Usage:
//   node scripts/load-mix.mjs [--host 127.0.0.1:8080] [--readers 25] [--writers 5]
//        [--duration 20] [--stage readers,writers ...] [--keep]
// Defaults ramp: 5/1, 10/2, 25/5, 50/10 — each stage --duration secs.
//
// Reading the results: capacity ≈ the last stage where p95 read
// latency stays under your SLO (default guidance 250ms) with <1%
// errors. Client CPU is the usual ceiling on a single machine —
// if Node saturates before the server degrades, distribute readers
// across machines or lower per-reader rate.

import WebSocket from "ws";

const args = process.argv.slice(2);
const flag = (name, dflt) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : dflt;
};
const HOST = flag("host", "127.0.0.1:8080");
const DURATION = Number(flag("duration", 20));
const KEEP = args.includes("--keep");
const stageArg = args.indexOf("--stage");
const STAGES = stageArg >= 0
  ? args[stageArg + 1].split(";").map((s) => s.split(",").map(Number))
  : [[5, 1], [10, 2], [25, 5], [50, 10]];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pct = (arr, p) => {
  if (!arr.length) return NaN;
  const s = [...arr].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.floor((p / 100) * s.length))];
};

let reqSeq = 0;
class Session {
  constructor(label) {
    this.label = label;
    this.lat = { connect: [], read: [], write: [] };
    this.errs = 0;
    this.counts = { read: 0, write: 0 };
    this.stopped = false;
  }
  async connect() {
    const t0 = Date.now();
    const tok = await fetch(`http://${HOST}/csrf-token`).then((r) => r.json()).then((d) => d.csrf_token);
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(`ws://${HOST}/xudanu?format=json&login=public&csrf_token=${tok}`, {
        headers: { Origin: `http://${HOST}` },
      });
      this.ws.on("open", async () => {
        await this.call("session_connect", {}).catch(() => {});
        this.lat.connect.push(Date.now() - t0);
        resolve(this);
      });
      this.ws.on("error", (e) => { this.errs++; reject(e); });
    });
  }
  call(op, payload) {
    return new Promise((resolve, reject) => {
      const id = ++reqSeq + 1000;
      const on = (data) => {
        try {
          const m = JSON.parse(data.toString());
          if (m.id === id || m.type === "error") {
            this.ws.off("message", on);
            m.type === "error" ? reject(new Error(m.message || "error")) : resolve(m.value?.value ?? m.value);
          }
        } catch {}
      };
      this.ws.on("message", on);
      this.ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload }));
      setTimeout(() => { this.ws.off("message", on); reject(new Error("timeout")); }, 10000);
    });
  }
  timed(kind, op, payload) {
    const t0 = Date.now();
    return this.call(op, payload).then((v) => {
      this.lat[kind].push(Date.now() - t0);
      this.counts[kind]++;
      return v;
    }, (e) => { this.errs++; throw e; });
  }
  close() {
    this.stopped = true;
    try { this.ws.close(); } catch {}
  }
}

async function runStage(readers, writers, duration) {
  const target = await new Session("setup").connect();
  const stamp = Date.now().toString(36);
  const readTargets = [];
  for (let i = 0; i < Math.min(readers, 8); i++) {
    const wid = await target.timed("write", "work_create", { edition: { text: `QA-LOAD doc ${i} ${stamp}\n${"lorem ipsum dolor sit amet ".repeat(40)}` } });
    await target.call("work_set_title", { work_id: wid, title: `QA-LOAD-r-${i}-${stamp}` });
    readTargets.push(wid);
  }
  const writerWorks = [];
  for (let i = 0; i < writers; i++) {
    const wid = await target.timed("write", "work_create", { edition: { text: `QA-LOAD writer ${i}\n` } });
    await target.call("work_set_title", { work_id: wid, title: `QA-LOAD-w-${i}-${stamp}` });
    writerWorks.push({ wid, n: 0 });
  }

  const sessions = [];
  const jobs = [];
  for (let i = 0; i < readers; i++) {
    const s = new Session(`r${i}`);
    sessions.push(s);
    jobs.push(s.connect().then(async () => {
      let k = 0;
      while (!s.stopped) {
        const wid = readTargets[k++ % readTargets.length];
        await s.timed("read", "work_get_edition", { work_id: wid }).catch(() => {});
        await sleep(250 + Math.random() * 750);
      }
    }));
  }
  for (let i = 0; i < writers; i++) {
    const s = new Session(`w${i}`);
    sessions.push(s);
    const job = writerWorks[i];
    jobs.push(s.connect().then(async () => {
      while (!s.stopped) {
        job.n++;
        await s.timed("write", "work_set_text", { work_id: job.wid, text: `QA-LOAD writer ${i} rev ${job.n}\n${"edit line ".repeat(job.n % 50)}` }).catch(() => {});
        await sleep(1000 + Math.random() * 2000);
      }
    }));
  }

  await sleep(duration * 1000);
  const healthStart = Date.now();
  const health = await fetch(`http://${HOST}/health`).then((r) => r.json()).catch(() => ({}));
  const healthMs = Date.now() - healthStart;
  sessions.forEach((s) => s.close());
  await Promise.allSettled(jobs);

  const all = { read: [], write: [], connect: [] };
  let errs = 0;
  for (const s of sessions) {
    all.read.push(...s.lat.read);
    all.write.push(...s.lat.write);
    all.connect.push(...s.lat.connect);
    errs += s.errs;
  }
  const totalOps = all.read.length + all.write.length;
  const line = (name, arr) =>
    arr.length
      ? `${name}: n=${arr.length} p50=${pct(arr, 50)}ms p95=${pct(arr, 95)}ms p99=${pct(arr, 99)}ms max=${Math.max(...arr)}ms`
      : `${name}: (none)`;
  console.log(`\n─ stage ${readers}R/${writers}W · ${duration}s ─`);
  console.log(`  ${line("connect", all.connect)}`);
  console.log(`  ${line("read   ", all.read)}`);
  console.log(`  ${line("write  ", all.write)}`);
  console.log(`  ops=${totalOps} (${(totalOps / duration).toFixed(1)}/s) errors=${errs} /health=${healthMs}ms works=${health.works ?? "?"}`);
  const readP95 = pct(all.read, 50 + 45);
  const verdict = Number.isNaN(readP95) ? "no reads" : readP95 < 250 && errs <= totalOps * 0.01 ? "PASS (p95<250ms, <1% err)" : `DEGRADE (p95=${readP95}ms, errs=${errs})`;
  console.log(`  verdict: ${verdict}`);

  if (!KEEP) {
    for (const wid of [...readTargets, ...writerWorks.map((w) => w.wid)]) {
      await target.call("work_archive", { work_id: wid }).catch(() => {});
    }
  }
  target.close();
}

console.log(`xudanu load-mix → http://${HOST} · stages: ${STAGES.map((s) => s.join("R/") + "W").join(" → ")}`);
for (const [r, w] of STAGES) {
  await runStage(r, w, DURATION);
}
console.log("\ndone. Capacity = last PASS stage under your SLO.");
process.exit(0);
