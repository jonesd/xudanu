import { storageGet, storageSet } from "./safe-storage";

export type ThemeMode = "light" | "dark";

export interface ThemePalette {
  id: string;
  name: string;
  mode: ThemeMode;
  cssClass: string;
  swatch: {
    bg: string;
    surface: string;
    border: string;
    text: string;
    accent: string;
  };
  description: string;
}

export const PALETTES: ThemePalette[] = [
  {
    id: "midnight",
    name: "Midnight",
    mode: "dark",
    cssClass: "theme-dark-midnight",
    description: "Deep indigo with warm amber accents",
    swatch: { bg: "#1a1a24", surface: "#22222e", border: "#3a3a48", text: "#e8e6e0", accent: "#d97706" },
  },
  {
    id: "oled",
    name: "OLED Black",
    mode: "dark",
    cssClass: "theme-dark-oled",
    description: "True black for OLED displays",
    swatch: { bg: "#000000", surface: "#0a0a0a", border: "#2a2a2a", text: "#e6e6e6", accent: "#60a5fa" },
  },
  {
    id: "slate",
    name: "Slate",
    mode: "dark",
    cssClass: "theme-dark-slate",
    description: "Cool blue-gray, easy on the eyes",
    swatch: { bg: "#0f172a", surface: "#1e293b", border: "#334155", text: "#e2e8f0", accent: "#60a5fa" },
  },
  {
    id: "github",
    name: "GitHub",
    mode: "light",
    cssClass: "theme-light-github",
    description: "Primer light, clean and neutral",
    swatch: { bg: "#ffffff", surface: "#f6f8fa", border: "#d0d7de", text: "#1f2328", accent: "#0969da" },
  },
  {
    id: "solarized",
    name: "Solarized",
    mode: "light",
    cssClass: "theme-light-solarized",
    description: "Warm cream with muted tones",
    swatch: { bg: "#fdf6e3", surface: "#eee8d5", border: "#d6cdb0", text: "#586e75", accent: "#268bd2" },
  },
  {
    id: "paper",
    name: "Paper",
    mode: "light",
    cssClass: "theme-light-paper",
    description: "Sepia-tinted, like aged paper",
    swatch: { bg: "#f4f1ea", surface: "#ebe7dc", border: "#c9c2ad", text: "#3a342a", accent: "#1d4ed8" },
  },
];

export const DEFAULT_LIGHT_PALETTE = "github";
export const DEFAULT_DARK_PALETTE = "midnight";

export function getPalette(id: string): ThemePalette | undefined {
  return PALETTES.find((p) => p.id === id);
}

export function palettesForMode(mode: ThemeMode): ThemePalette[] {
  return PALETTES.filter((p) => p.mode === mode);
}

export interface ThemeState {
  mode: ThemeMode;
  lightPaletteId: string;
  darkPaletteId: string;
}

export function activePalette(state: ThemeState): ThemePalette {
  const id = state.mode === "light" ? state.lightPaletteId : state.darkPaletteId;
  return getPalette(id) ?? (state.mode === "light" ? getPalette(DEFAULT_LIGHT_PALETTE)! : getPalette(DEFAULT_DARK_PALETTE)!);
}

const MODE_KEY = "xudanu_theme";
const LIGHT_KEY = "xudanu_theme_light";
const DARK_KEY = "xudanu_theme_dark";

function safeGet(key: string): string | null {
  try { return storageGet(key); } catch { return null; }
}

function safeSet(key: string, value: string): void {
  try { storageSet(key, value); } catch { /* no-op */ }
}

export function loadThemeState(): ThemeState {
  const storedMode = safeGet(MODE_KEY);
  const storedLight = safeGet(LIGHT_KEY);
  const storedDark = safeGet(DARK_KEY);

  // Backward compat: the old key stored "light" or "dark" (or was absent = dark).
  const mode: ThemeMode = storedMode === "light" ? "light" : "dark";

  const lightPaletteId =
    storedLight && getPalette(storedLight) && getPalette(storedLight)!.mode === "light"
      ? storedLight
      : DEFAULT_LIGHT_PALETTE;

  const darkPaletteId =
    storedDark && getPalette(storedDark) && getPalette(storedDark)!.mode === "dark"
      ? storedDark
      : DEFAULT_DARK_PALETTE;

  return { mode, lightPaletteId, darkPaletteId };
}

export function saveThemeState(state: ThemeState): void {
  safeSet(MODE_KEY, state.mode);
  safeSet(LIGHT_KEY, state.lightPaletteId);
  safeSet(DARK_KEY, state.darkPaletteId);
}
