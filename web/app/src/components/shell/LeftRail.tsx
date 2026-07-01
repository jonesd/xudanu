import { useCallback } from "react";

interface LeftRailProps {
  activeItem: string;
  onNavigate: (item: string) => void;
  onOpenLibrary: () => void;
  onOpenSearch: () => void;
}

function RailButton({
  icon,
  label,
  active,
  onClick,
}: {
  icon: React.ReactNode;
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button className={`rail-btn ${active ? "active" : ""}`} onClick={onClick}>
      {icon}
      <span className="rail-tooltip">{label}</span>
    </button>
  );
}

const ICONS = {
  document: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
    </svg>
  ),
  library: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M3 3h18v18H3zM3 9h18M9 21V9" />
    </svg>
  ),
  search: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <circle cx="11" cy="11" r="8" />
      <path d="m21 21-4.3-4.3" />
    </svg>
  ),
  trails: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M12 2L2 7l10 5 10-5-10-5z" />
      <path d="M2 17l10 5 10-5" />
      <path d="M2 12l10 5 10-5" />
    </svg>
  ),
  compound: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 14c0-1 1-2 2-2h14c1 0 2 1 2 2v1a5 5 0 0 1-5 5H8a5 5 0 0 1-5-5v-1z" />
      <path d="M8 12c-1-3 0-6 2-8" />
      <path d="M11 4l5-2-2 5-3-3z" />
      <path d="M9.5 10.5L14 6" />
    </svg>
  ),
  annotate: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M12 20h9" />
      <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z" />
    </svg>
  ),
  provenance: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71" />
      <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71" />
    </svg>
  ),
  identity: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <circle cx="12" cy="8" r="5" />
      <path d="M20 21a8 8 0 0 0-16 0" />
    </svg>
  ),
  settings: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
    </svg>
  ),
};

export function LeftRail({ activeItem, onNavigate, onOpenLibrary, onOpenSearch }: LeftRailProps) {
  const handleNav = useCallback(
    (item: string) => {
      if (item === "library") onOpenLibrary();
      else if (item === "search") onOpenSearch();
      else onNavigate(item);
    },
    [onNavigate, onOpenLibrary, onOpenSearch]
  );

  return (
    <div className="left-rail">
      <RailButton icon={ICONS.document} label="Document" active={activeItem === "document"} onClick={() => handleNav("document")} />
      <RailButton icon={ICONS.library} label="Library" active={false} onClick={() => handleNav("library")} />
      <RailButton icon={ICONS.search} label="Search" active={false} onClick={() => handleNav("search")} />
      <div className="rail-separator" />
      <RailButton icon={ICONS.trails} label="Trails" active={false} onClick={() => handleNav("trails")} />
      <RailButton icon={ICONS.compound} label="Compound" active={false} onClick={() => handleNav("compound")} />
      <RailButton icon={ICONS.annotate} label="Annotations" active={false} onClick={() => handleNav("annotate")} />
      <RailButton icon={ICONS.provenance} label="Provenance" active={false} onClick={() => handleNav("provenance")} />
      <div className="rail-separator" />
      <RailButton icon={ICONS.identity} label="Identity" active={false} onClick={() => handleNav("identity")} />
      <RailButton icon={ICONS.settings} label="Settings" active={false} onClick={() => handleNav("settings")} />
    </div>
  );
}
