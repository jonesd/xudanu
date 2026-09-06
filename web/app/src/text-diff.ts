export type DiffOpKind = "equal" | "delete" | "insert";

export interface DiffOp {
  kind: DiffOpKind;
  text: string;
}

export interface DiffResult {
  ops: DiffOp[];
  /** 0..1 — matched words over the longer text's word count. */
  matchRatio: number;
}

/** Tokens are words with their trailing whitespace; joining tokens
 * reproduces the original text. */
export function tokenizeWords(text: string): string[] {
  const raw = text.match(/\s+|\S+/g) ?? [];
  const tokens: string[] = [];
  for (const r of raw) {
    if (/^\s+$/.test(r) && tokens.length > 0 && /\S/.test(tokens[tokens.length - 1])) {
      tokens[tokens.length - 1] += r;
    } else {
      tokens.push(r);
    }
  }
  return tokens;
}

const wordCount = (tokens: string[]) => tokens.reduce((n, t) => (/\S/.test(t) ? n + 1 : n), 0);

/** Myers O(ND) diff over tokens. Returns null when the edit distance
 * exceeds the cap (pathologically different or huge texts) — callers
 * fall back to a non-aligned presentation. */
function myers(a: string[], b: string[], dCap: number): Array<{ kind: DiffOpKind; count: number }> | null {
  const n = a.length;
  const m = b.length;
  const max = n + m;
  const offset = max;
  const v = new Int32Array(2 * max + 1);
  const trace: Int32Array[] = [];
  for (let d = 0; d <= Math.min(max, dCap); d++) {
    const snapshot = v.slice();
    trace.push(snapshot);
    for (let k = -d; k <= d; k += 2) {
      let x: number;
      if (k === -d || (k !== d && v[offset + k - 1] < v[offset + k + 1])) {
        x = v[offset + k + 1];
      } else {
        x = v[offset + k - 1] + 1;
      }
      let y = x - k;
      while (x < n && y < m && a[x] === b[y]) {
        x++;
        y++;
      }
      v[offset + k] = x;
      if (x >= n && y >= m) {
        // backtrack
        const ops: Array<{ kind: DiffOpKind; count: number }> = [];
        let px = n;
        let py = m;
        for (let dd = d; dd > 0; dd--) {
          const vv = trace[dd];
          const kk = px - py;
          let prevK: number;
          if (kk === -dd || (kk !== dd && vv[offset + kk - 1] < vv[offset + kk + 1])) {
            prevK = kk + 1;
          } else {
            prevK = kk - 1;
          }
          const prevX = vv[offset + prevK];
          const prevY = prevX - prevK;
          while (px > prevX && py > prevY) {
            ops.push({ kind: "equal", count: 1 });
            px--;
            py--;
          }
          if (px === prevX) {
            ops.push({ kind: "insert", count: py - prevY });
            py = prevY;
          } else {
            ops.push({ kind: "delete", count: px - prevX });
            px = prevX;
          }
        }
        while (px > 0 && py > 0) {
          ops.push({ kind: "equal", count: 1 });
          px--;
          py--;
        }
        ops.reverse();
        return ops;
      }
    }
  }
  return null;
}

export function diffTexts(textA: string, textB: string): DiffResult | null {
  const a = tokenizeWords(textA);
  const b = tokenizeWords(textB);
  if (a.length === 0 && b.length === 0) {
    return { ops: [{ kind: "equal", text: "" }], matchRatio: 1 };
  }
  const raw = myers(a, b, 3000);
  if (!raw) return null;
  const ops: DiffOp[] = [];
  let ai = 0;
  let bi = 0;
  for (const step of raw) {
    if (step.count === 0) continue;
    let text = "";
    if (step.kind === "equal") text = a.slice(ai, ai + step.count).join("");
    else if (step.kind === "delete") text = a.slice(ai, ai + step.count).join("");
    else text = b.slice(bi, bi + step.count).join("");
    const last = ops[ops.length - 1];
    if (last && last.kind === step.kind) last.text += text;
    else ops.push({ kind: step.kind, text });
    if (step.kind === "equal") {
      ai += step.count;
      bi += step.count;
    } else if (step.kind === "delete") {
      ai += step.count;
    } else {
      bi += step.count;
    }
  }
  const matched = ops.filter((o) => o.kind === "equal").reduce((n, o) => n + wordCount(tokenizeWords(o.text)), 0);
  const ratio = Math.max(wordCount(a), wordCount(b));
  return { ops, matchRatio: ratio === 0 ? 0 : matched / ratio };
}

export interface DiffRenderOptions {
  /** Collapse matched runs longer than this many words. */
  collapseOver?: number;
}

/** HTML for one side of the aligned diff ("a" shows deletions,
 * "b" shows insertions; both collapse long equal runs). */
export function renderDiffSideHtml(
  result: DiffResult,
  side: "a" | "b",
  opts: DiffRenderOptions = {},
): string {
  const collapseOver = opts.collapseOver ?? 16;
  const esc = (t: string) =>
    t.replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c] ?? c));
  const words = (t: string) => wordCount(tokenizeWords(t));
  let html = "";
  for (const op of result.ops) {
    if (op.kind === "equal") {
      const n = words(op.text);
      if (n > collapseOver) {
        const first = op.text.slice(0, Math.min(op.text.length, 40));
        const last = op.text.slice(-40);
        html += `<span class="cmp-ctx">${esc(first.trimEnd())} ⋯ ${n} matched words ⋯ ${esc(last.trimStart())}</span>`;
      } else {
        html += `<span class="cmp-eq">${esc(op.text)}</span>`;
      }
    } else if ((side === "a" && op.kind === "delete") || (side === "b" && op.kind === "insert")) {
      html += `<span class="${side === "a" ? "cmp-del" : "cmp-ins"}">${esc(op.text)}</span>`;
    } else {
      // The other side's hunk: a thin placeholder keeps the columns
      // tracking each other (side a gaps where b inserted, etc).
      html += `<span class="cmp-gap" title="${words(op.text)} words on the other side"></span>`;
    }
  }
  return html;
}
