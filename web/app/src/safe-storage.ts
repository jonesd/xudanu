// Safari throws SecurityError on any localStorage access when storage
// is blocked (Block All Cookies / strict ITP / locked private mode).
// A raw access inside a useState initializer crashes React's first
// render and leaves #root empty — a blank page. All storage access
// goes through these wrappers so a blocked browser degrades to
// session-only state instead of failing to boot.

export function storageGet(key: string): string | null {
  try {
    return window.localStorage.getItem(key);
  } catch {
    return null;
  }
}

export function storageSet(key: string, value: string): void {
  try {
    window.localStorage.setItem(key, value);
  } catch {
    /* storage unavailable */
  }
}

export function storageRemove(key: string): void {
  try {
    window.localStorage.removeItem(key);
  } catch {
    /* storage unavailable */
  }
}

export function storageClear(): void {
  try {
    window.localStorage.clear();
  } catch {
    /* storage unavailable */
  }
}
