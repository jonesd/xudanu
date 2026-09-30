/**
 * UI-wide font size preference (FR-84 follow-on): one base size the
 * user controls; chrome surfaces consume it via the --ws-font CSS
 * variable so the whole system scales from one knob.
 *
 * New components should use `var(--ws-font, 14px)` (and calc()
 * variants) instead of hardcoded px. Legacy absolute sizes migrate
 * opportunistically; no big-bang rewrite.
 */
import { storageGet, storageSet } from "./safe-storage";

const KEY = "xudanu-ui-font-size";

export const DEFAULT_UI_FONT_SIZE = 14;
export const UI_FONT_MIN = 12;
export const UI_FONT_MAX = 20;
export const UI_FONT_STEPS = [12, 13, 14, 15, 16, 18, 20];

export function clampUiFontSize(n: number): number {
  if (!Number.isFinite(n)) return DEFAULT_UI_FONT_SIZE;
  return Math.min(UI_FONT_MAX, Math.max(UI_FONT_MIN, Math.round(n)));
}

export function readUiFontSize(): number {
  const raw = storageGet(KEY);
  const n = typeof raw === "string" ? Number(raw) : Number(raw);
  return clampUiFontSize(Number.isFinite(n) && n !== 0 ? n : DEFAULT_UI_FONT_SIZE);
}

export function writeUiFontSize(n: number): number {
  const v = clampUiFontSize(n);
  storageSet(KEY, String(v));
  return v;
}

/** Next step in the cycle (for a one-button control). */
export function nextUiFontSize(current: number): number {
  const idx = UI_FONT_STEPS.indexOf(clampUiFontSize(current));
  const next = UI_FONT_STEPS[(idx + 1) % UI_FONT_STEPS.length];
  return clampUiFontSize(next);
}
