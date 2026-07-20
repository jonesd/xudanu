import { useEffect, useRef } from "react";
import { Logo } from "../../logo";
import { PALETTES } from "../../theme";
import type { ThemeMode, ThemePalette } from "../../theme";

type WorkspaceNavTab = "explore" | "library" | "compose";

interface WorkspaceTopBarProps {
  connected: boolean;
  identityName: string | null;
  identityColor: string;
  activeNav: WorkspaceNavTab;
  onNavChange: (tab: WorkspaceNavTab) => void;
  onOpenSearch: () => void;
  onOpenIdentity: () => void;
  onOpenAdmin: () => void;
  isAdmin: boolean;
  onCreateWork: () => void;
  themeMode: ThemeMode;
  themePickerOpen: boolean;
  onToggleThemePicker: () => void;
  onSelectPalette: (paletteId: string, mode: ThemeMode) => void;
  onQuickToggleMode: () => void;
  activeLightPaletteId: string;
  activeDarkPaletteId: string;
}

function PaletteSwatch({ palette }: { palette: ThemePalette }) {
  return (
    <span
      aria-hidden="true"
      style={{
        display: "inline-flex",
        width: 36,
        height: 20,
        borderRadius: 3,
        overflow: "hidden",
        border: "1px solid var(--border)",
        flexShrink: 0,
      }}
    >
      <span style={{ flex: 2, background: palette.swatch.bg }} />
      <span style={{ flex: 2, background: palette.swatch.surface }} />
      <span style={{ flex: 1, background: palette.swatch.accent }} />
    </span>
  );
}

export function WorkspaceTopBar({
  connected,
  identityName,
  identityColor,
  activeNav,
  onNavChange,
  onOpenSearch,
  onOpenIdentity,
  onOpenAdmin,
  isAdmin,
  onCreateWork,
  themeMode,
  themePickerOpen,
  onToggleThemePicker,
  onSelectPalette,
  onQuickToggleMode,
  activeLightPaletteId,
  activeDarkPaletteId,
}: WorkspaceTopBarProps) {
  const pickerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!themePickerOpen) return;
    function onDocClick(e: MouseEvent) {
      if (pickerRef.current && !pickerRef.current.contains(e.target as Node)) {
        onToggleThemePicker();
      }
    }
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") onToggleThemePicker();
    }
    document.addEventListener("mousedown", onDocClick);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDocClick);
      document.removeEventListener("keydown", onKey);
    };
  }, [themePickerOpen, onToggleThemePicker]);

  const darkPalettes = PALETTES.filter((p) => p.mode === "dark");
  const lightPalettes = PALETTES.filter((p) => p.mode === "light");

  return (
    <div className="ws-top-bar">
      <div
        className="ws-brand"
        onClick={() => {
          window.history.pushState({}, "", "/");
          window.dispatchEvent(new PopStateEvent("popstate"));
        }}
      >
        <Logo size={18} />
        <span>xudanu</span>
      </div>

      <div className="ws-search-trigger" onClick={onOpenSearch}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="11" cy="11" r="8" />
          <path d="m21 21-4.3-4.3" />
        </svg>
        Search content, authors, topics…
        <kbd>⌘K</kbd>
      </div>

      <nav className="ws-nav">
        <button className="ws-nav-create" onClick={onCreateWork} title="Create a new work">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <path d="M12 5v14M5 12h14" />
          </svg>
          Create
        </button>
        <button
          className={`ws-nav-tab ${activeNav === "explore" ? "active" : ""}`}
          onClick={() => onNavChange("explore")}
        >
          Explore
        </button>
        <button
          className={`ws-nav-tab ${activeNav === "library" ? "active" : ""}`}
          onClick={() => onNavChange("library")}
        >
          Library
        </button>
        <button
          className={`ws-nav-tab ${activeNav === "compose" ? "active" : ""}`}
          onClick={() => onNavChange("compose")}
        >
          Compose
        </button>
      </nav>

      <div className="ws-top-bar-actions">
        <div
          className="ws-connection-dot"
          title={connected ? "Connected" : "Offline"}
          style={connected ? {} : { background: "var(--red)" }}
        />

        <div className="theme-picker-wrap" ref={pickerRef}>
          <button
            onClick={themePickerOpen ? onToggleThemePicker : onQuickToggleMode}
            title={themeMode === "light" ? "Light theme — click to switch to dark, right-click for palettes" : "Dark theme — click to switch to light, right-click for palettes"}
            className="theme-icon-btn"
            aria-expanded={themePickerOpen}
            aria-haspopup="menu"
          >
            {themeMode === "light" ? (
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="5" /><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" /></svg>
            ) : (
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" /></svg>
            )}
          </button>
          <button
            onClick={onToggleThemePicker}
            title="Choose palette"
            className="theme-chevron-btn"
            aria-expanded={themePickerOpen}
            aria-haspopup="menu"
          >
            <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><path d="M6 9l6 6 6-6" /></svg>
          </button>
          {themePickerOpen && (
            <div className="theme-picker-menu" role="menu">
              <div className="theme-picker-section">
                <div className="theme-picker-section-title">
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" /></svg>
                  Dark palettes
                </div>
                {darkPalettes.map((p) => (
                  <button
                    key={p.id}
                    className={`theme-picker-item ${themeMode === "dark" && activeDarkPaletteId === p.id ? "active" : ""}`}
                    onClick={() => onSelectPalette(p.id, "dark")}
                    title={p.description}
                  >
                    <PaletteSwatch palette={p} />
                    <span className="theme-picker-item-name">{p.name}</span>
                    {themeMode === "dark" && activeDarkPaletteId === p.id && (
                      <svg className="theme-picker-check" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><path d="M20 6L9 17l-5-5" /></svg>
                    )}
                  </button>
                ))}
              </div>
              <div className="theme-picker-divider" />
              <div className="theme-picker-section">
                <div className="theme-picker-section-title">
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="5" /><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" /></svg>
                  Light palettes
                </div>
                {lightPalettes.map((p) => (
                  <button
                    key={p.id}
                    className={`theme-picker-item ${themeMode === "light" && activeLightPaletteId === p.id ? "active" : ""}`}
                    onClick={() => onSelectPalette(p.id, "light")}
                    title={p.description}
                  >
                    <PaletteSwatch palette={p} />
                    <span className="theme-picker-item-name">{p.name}</span>
                    {themeMode === "light" && activeLightPaletteId === p.id && (
                      <svg className="theme-picker-check" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><path d="M20 6L9 17l-5-5" /></svg>
                    )}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {isAdmin && (
          <button onClick={onOpenAdmin} title="Admin Dashboard" className="ws-admin-btn">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20z" />
              <path d="M12 16v-4M12 8h.01" />
            </svg>
            Admin
          </button>
        )}

        <div className="identity-badge" onClick={onOpenIdentity}>
          <div className="identity-avatar" style={{ background: identityColor }}>
            {identityName ? identityName[0].toUpperCase() : "?"}
          </div>
          <span className="identity-name">{identityName || "Anonymous"}</span>
        </div>
      </div>
    </div>
  );
}

export type { WorkspaceNavTab };
