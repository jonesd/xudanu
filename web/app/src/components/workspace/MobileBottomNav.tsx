import type React from "react";
import type { WorkspaceNavTab } from "./WorkspaceTopBar";

interface MobileBottomNavProps {
  activeNav: WorkspaceNavTab;
  onNavChange: (tab: WorkspaceNavTab) => void;
  /** Called by the Panels button: opens the bottom sheet (right panel
   * content is the richest — connections/attribution/history). */
  onOpenPanels: () => void;
  panelsOpen: boolean;
}

/**
 * Phone-only bottom navigation (phase 2 mobile shell): thumb-reachable
 * primary destinations. Rendered by WorkspaceShell under `isPhone`;
 * hidden by CSS at >=768px where the top-bar nav remains the interface.
 * The desktop nav and this bar share the same WorkspaceNavTab state.
 */
export function MobileBottomNav({ activeNav, onNavChange, onOpenPanels, panelsOpen }: MobileBottomNavProps) {
  const items: Array<{ id: WorkspaceNavTab | "panels"; label: string; icon: React.ReactNode }> = [
    {
      id: "explore",
      label: "Explore",
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
          <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
        </svg>
      ),
    },
    {
      id: "library",
      label: "Library",
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <rect x="3" y="3" width="7" height="7" rx="1" />
          <rect x="14" y="3" width="7" height="7" rx="1" />
          <rect x="3" y="14" width="7" height="7" rx="1" />
          <rect x="14" y="14" width="7" height="7" rx="1" />
        </svg>
      ),
    },
    {
      id: "compose",
      label: "Compose",
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M12 20h9" />
          <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z" />
        </svg>
      ),
    },
    {
      id: "panels",
      label: panelsOpen ? "Close" : "Panels",
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <rect x="3" y="3" width="18" height="18" rx="2" />
          <path d="M3 9h18" />
          <path d="M9 21V9" />
        </svg>
      ),
    },
  ];

  return (
    <nav className="ws-bottom-nav" role="tablist">
      {items.map((item) => {
        const active = item.id === "panels" ? panelsOpen : activeNav === item.id;
        return (
          <button
            key={item.id}
            role="tab"
            aria-selected={active}
            className={`ws-bottom-nav-item ${active ? "active" : ""}`}
            onClick={() => {
              if (item.id === "panels") {
                onOpenPanels();
              } else {
                onNavChange(item.id as WorkspaceNavTab);
              }
            }}
          >
            {item.icon}
            <span className="ws-bottom-nav-label">{item.label}</span>
          </button>
        );
      })}
    </nav>
  );
}
