import { useState, useEffect } from "react";

/**
 * Reactive CSS media-query hook — the single source of truth for
 * breakpoint-dependent BEHAVIOR (drawer state, layout mode) alongside
 * the media queries in CSS that handle breakpoint-dependent STYLING.
 *
 * Mirrors the CSS breakpoints in workspace.css:
 *   isPhone  <=> max-width: 767px
 *   isTablet <=> max-width: 1023px
 */
export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(() =>
    typeof window !== "undefined" && typeof window.matchMedia === "function"
      ? window.matchMedia(query).matches
      : false,
  );

  useEffect(() => {
    if (typeof window === "undefined" || typeof window.matchMedia !== "function") {
      return;
    }
    const mql = window.matchMedia(query);
    const onChange = (e: MediaQueryListEvent) => setMatches(e.matches);
    setMatches(mql.matches);
    mql.addEventListener("change", onChange);
    return () => mql.removeEventListener("change", onChange);
  }, [query]);

  return matches;
}

export const PHONE_QUERY = "(max-width: 767px)";
export const TABLET_QUERY = "(max-width: 1023px)";

export function useIsPhone(): boolean {
  return useMediaQuery(PHONE_QUERY);
}

export function useIsTablet(): boolean {
  return useMediaQuery(TABLET_QUERY);
}
