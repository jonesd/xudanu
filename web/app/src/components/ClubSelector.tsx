import { useState, useEffect, useRef, useCallback } from "react";
import type { CrdtSyncClient } from "../api/crdt_sync";

export interface ClubInfo {
  id: number;
  name: string;
}

interface ClubSelectorProps {
  clientRef: React.RefObject<CrdtSyncClient | null>;
  connected: boolean;
  publicClubId: number;
  /** Current selected club ID, or null for "private" */
  value: number | null;
  /** Called when user selects a club. null = private, publicClubId = public */
  onChange: (clubId: number | null) => void;
  /** Compact mode for inline use (badges), vs full mode for panels */
  compact?: boolean;
  /** Label for the private option */
  privateLabel?: string;
}

export function ClubSelector({
  clientRef,
  connected,
  publicClubId,
  value,
  onChange,
  compact = false,
  privateLabel = "Just me",
}: ClubSelectorProps) {
  const [clubs, setClubs] = useState<ClubInfo[]>([]);
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  const loadClubs = useCallback(async () => {
    if (!connected || !clientRef.current) return;
    try {
      const entries = await clientRef.current.fetchClubNames(0, 100);
      setClubs(entries.map(([name, id]) => ({ id, name })));
    } catch {
      /* ignore */
    }
  }, [connected, clientRef]);

  useEffect(() => {
    if (open) loadClubs();
  }, [open, loadClubs]);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    if (open) document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [open]);

  const currentLabel = (() => {
    if (value === null) return privateLabel;
    if (value === publicClubId) return "Public";
    const club = clubs.find((c) => c.id === value);
    return club?.name || `club:${value.toString(16)}`;
  })();

  const currentIcon = value === null ? "🔒" : value === publicClubId ? "🌐" : "👥";

  if (compact) {
    return (
      <div ref={ref} style={{ position: "relative", display: "inline-block" }}>
        <button
          onClick={() => setOpen(!open)}
          style={{
            background: "rgba(128,128,128,0.08)",
            border: "1px solid rgba(128,128,128,0.15)",
            borderRadius: "4px",
            padding: "2px 8px",
            fontSize: "11px",
            cursor: "pointer",
            color: "inherit",
            display: "flex",
            alignItems: "center",
            gap: "4px",
          }}
        >
          <span style={{ fontSize: "10px" }}>{currentIcon}</span>
          {currentLabel}
          <span style={{ opacity: 0.4, fontSize: "9px" }}>{"\u25BE"}</span>
        </button>
        {open && (
          <ClubDropdown
            clubs={clubs}
            value={value}
            publicClubId={publicClubId}
            privateLabel={privateLabel}
            onChange={(v) => {
              onChange(v);
              setOpen(false);
            }}
          />
        )}
      </div>
    );
  }

  return (
    <div ref={ref} style={{ position: "relative" }}>
      <button
        onClick={() => setOpen(!open)}
        style={{
          width: "100%",
          background: "rgba(128,128,128,0.05)",
          border: "1px solid rgba(128,128,128,0.2)",
          borderRadius: "6px",
          padding: "8px 12px",
          fontSize: "13px",
          cursor: "pointer",
          color: "inherit",
          display: "flex",
          alignItems: "center",
          gap: "8px",
          textAlign: "left",
        }}
      >
        <span style={{ fontSize: "14px" }}>{currentIcon}</span>
        <span style={{ flex: 1 }}>{currentLabel}</span>
        <span style={{ opacity: 0.4, fontSize: "11px" }}>{"\u25BE"}</span>
      </button>
      {open && (
        <ClubDropdown
          clubs={clubs}
          value={value}
          publicClubId={publicClubId}
          privateLabel={privateLabel}
          onChange={(v) => {
            onChange(v);
            setOpen(false);
          }}
        />
      )}
    </div>
  );
}

function ClubDropdown({
  clubs,
  value,
  publicClubId,
  privateLabel,
  onChange,
}: {
  clubs: ClubInfo[];
  value: number | null;
  publicClubId: number;
  privateLabel: string;
  onChange: (v: number | null) => void;
}) {
  const isSelected = (clubId: number | null) => clubId === value;

  return (
    <div
      style={{
        position: "absolute",
        top: "100%",
        left: 0,
        right: 0,
        marginTop: "4px",
        background: "#fff",
        border: "1px solid rgba(128,128,128,0.2)",
        borderRadius: "8px",
        boxShadow: "0 10px 30px rgba(0,0,0,0.15)",
        zIndex: 1000,
        maxHeight: "300px",
        overflowY: "auto",
        minWidth: "200px",
      }}
    >
      <div
        style={{
          padding: "6px 12px",
          fontSize: "10px",
          fontWeight: 600,
          textTransform: "uppercase",
          letterSpacing: "0.05em",
          opacity: 0.4,
        }}
      >
        Visibility
      </div>

      <DropdownRow
        icon={"\u{1F310}"}
        label="Everyone (Public)"
        selected={isSelected(publicClubId)}
        onClick={() => onChange(publicClubId)}
      />
      <DropdownRow
        icon={"\u{1F512}"}
        label={privateLabel}
        selected={isSelected(null)}
        onClick={() => onChange(null)}
      />

      {clubs.filter((c) => c.id !== publicClubId && c.id !== 0).length > 0 && (
        <>
          <div
            style={{
              borderTop: "1px solid rgba(128,128,128,0.1)",
              margin: "4px 0",
            }}
          />
          <div
            style={{
              padding: "6px 12px",
              fontSize: "10px",
              fontWeight: 600,
              textTransform: "uppercase",
              letterSpacing: "0.05em",
              opacity: 0.4,
            }}
          >
            Clubs
          </div>
          {clubs
            .filter((c) => c.id !== publicClubId && c.id !== 0)
            .map((club) => (
              <DropdownRow
                key={club.id}
                icon={"\u{1F465}"}
                label={club.name}
                sublabel={`#${club.id.toString(16).padStart(4, "0")}`}
                selected={isSelected(club.id)}
                onClick={() => onChange(club.id)}
              />
            ))}
        </>
      )}
    </div>
  );
}

function DropdownRow({
  icon,
  label,
  sublabel,
  selected,
  onClick,
}: {
  icon: string;
  label: string;
  sublabel?: string;
  selected: boolean;
  onClick: () => void;
}) {
  return (
    <div
      onClick={onClick}
      style={{
        padding: "7px 12px",
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        gap: "8px",
        fontSize: "13px",
        background: selected ? "rgba(67,97,238,0.08)" : "transparent",
      }}
      onMouseEnter={(e) => {
        if (!selected) e.currentTarget.style.background = "rgba(128,128,128,0.06)";
      }}
      onMouseLeave={(e) => {
        if (!selected) e.currentTarget.style.background = "transparent";
      }}
    >
      <span style={{ fontSize: "13px", width: "18px", textAlign: "center" }}>
        {selected ? "\u2713" : icon}
      </span>
      <span style={{ flex: 1 }}>
        {label}
        {sublabel && (
          <span style={{ marginLeft: "6px", fontSize: "10px", opacity: 0.4 }}>
            {sublabel}
          </span>
        )}
      </span>
    </div>
  );
}
