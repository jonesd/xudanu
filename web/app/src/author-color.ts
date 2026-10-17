import { storageGet, storageSet } from "./safe-storage";

const HUE_PALETTE_SIZE = 360;

export interface ColorPair {
  primary: string;
  secondary: string;
}

function hslToHex(h: number, s: number, l: number): string {
  const a = s * Math.min(l, 1 - l);
  const f = (n: number) => {
    const k = (n + h / 30) % 12;
    const c = l - a * Math.max(-1, Math.min(k - 3, Math.min(9 - k, 1)));
    return Math.round(255 * c)
      .toString(16)
      .padStart(2, "0");
  };
  return `#${f(0)}${f(8)}${f(4)}`;
}

const PALETTE: ColorPair[] = (() => {
  const pairs: ColorPair[] = [];
  const baseHues = [
    210, 30, 340, 150, 270, 60, 180, 0, 120, 300,
    240, 15, 195, 45, 165, 330, 75, 225, 105, 285,
    20, 200, 50, 140, 315,
  ];
  for (const hue of baseHues) {
    const complementary = (hue + 180) % HUE_PALETTE_SIZE;
    pairs.push({
      primary: hslToHex(hue, 0.5, 0.68),
      secondary: hslToHex(complementary, 0.55, 0.45),
    });
  }
  return pairs;
})();

function fnv1aHash(str: string): number {
  let hash = 2166136261;
  for (let i = 0; i < str.length; i++) {
    hash ^= str.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

export function authorColorPair(name: string): ColorPair {
  const hash = fnv1aHash(name);
  const mixed = (hash ^ (hash >>> 16)) >>> 0;
  return PALETTE[mixed % PALETTE.length];
}

export function authorColor(name: string): string {
  return authorColorPair(name).primary;
}

export function authorColorSecondary(name: string): string {
  return authorColorPair(name).secondary;
}

/**
 * Ordered two-hue identity code: [hueA, hueB], always distinct, both
 * stable per identity. Rendered together (angled split or stripe) the
 * palette of 25 hues distinguishes 25×24 = 600 authors — the paired
 * colour scheme. Derived from independent hash bits so the pair is
 * not merely a rotation of one hue.
 */
export function authorOrderedPair(name: string): [string, string] {
  const hash = fnv1aHash(name);
  const mixed = (hash ^ (hash >>> 16)) >>> 0;
  const a = mixed % PALETTE.length;
  const b = (a + 1 + ((mixed >>> 8) % (PALETTE.length - 1))) % PALETTE.length;
  return [PALETTE[a].primary, PALETTE[b].primary];
}

const PAIRED_MODE_KEY = "xudanu_paired_author_colors";

export function pairedAuthorColors(): boolean {
  return storageGet(PAIRED_MODE_KEY) === "1";
}

export function setPairedAuthorColors(on: boolean): void {
  try {
    if (on) storageSet(PAIRED_MODE_KEY, "1");
    else storageSet(PAIRED_MODE_KEY, "");
  } catch {
    /* storage unavailable — session-only fallback */
  }
}

export function gradientCss(pair: ColorPair, angle: number = 180): string {
  return `linear-gradient(${angle}deg, ${pair.primary} 40%, ${pair.secondary} 60%)`;
}

export function pillStyle(pair: ColorPair): React.CSSProperties {
  return {
    background: gradientCss(pair),
    borderRadius: "12px",
  };
}
