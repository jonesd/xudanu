import { useState } from "react";

interface PermissionBadgeProps {
  canEdit: boolean;
  isAnonymous: boolean;
  identityName: string | null;
  isPublished: boolean;
  editOpen: boolean;
  isGrabbed: boolean;
  isOwner: boolean;
  documentTitle: string | null;
}

type AccessLevel = "anonymous" | "editor" | "reader";

function getAccessLevel(props: PermissionBadgeProps): AccessLevel {
  if (props.isAnonymous) return "anonymous";
  if (props.canEdit) return "editor";
  return "reader";
}

const LEVEL_CONFIG: Record<AccessLevel, { color: string; bg: string; label: string; icon: string }> = {
  anonymous: { color: "#58a6ff", bg: "rgba(88,166,255,0.12)", label: "Sign in", icon: "?" },
  editor: { color: "#3fb950", bg: "rgba(63,185,80,0.12)", label: "Editable", icon: "✎" },
  reader: { color: "#d29922", bg: "rgba(210,153,34,0.12)", label: "Read-only", icon: "👁" },
};

export function PermissionBadge(props: PermissionBadgeProps) {
  const [hovered, setHovered] = useState(false);
  const level = getAccessLevel(props);
  const cfg = LEVEL_CONFIG[level];

  const canPublish = props.isOwner;
  const canShare = props.isOwner;
  const canDelete = props.isOwner;

  return (
    <div
      className="perm-badge-container"
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      <div
        className="perm-badge"
        style={{
          display: "inline-flex",
          alignItems: "center",
          gap: 4,
          padding: "2px 8px",
          borderRadius: 10,
          fontSize: 11,
          fontWeight: 600,
          cursor: "default",
          color: cfg.color,
          background: cfg.bg,
          border: `1px solid ${cfg.color}44`,
          userSelect: "none",
        }}
      >
        <span style={{ fontSize: 10 }}>{cfg.icon}</span>
        {cfg.label}
      </div>

      {hovered && (
        <div
          className="perm-overlay"
          style={{
            position: "absolute",
            top: "100%",
            left: 0,
            marginTop: 4,
            zIndex: 1000,
            background: "#161b22",
            border: "1px solid #30363d",
            borderRadius: 8,
            padding: "12px 16px",
            fontSize: 12,
            lineHeight: 1.8,
            minWidth: 240,
            maxWidth: 320,
            boxShadow: "0 8px 24px rgba(0,0,0,0.4)",
            color: "#c9d1d9",
          }}
        >
          <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 8, color: "#e6edf3" }}>
            Your Access
          </div>

          <div style={{ marginBottom: 6, color: "#8b949e" }}>
            Signed in as:{" "}
            <span style={{ color: props.identityName ? "#e6edf3" : "#8b949e", fontWeight: 600 }}>
              {props.identityName || "Anonymous"}
            </span>
          </div>

          {props.documentTitle && (
            <div style={{ marginBottom: 6, color: "#8b949e" }}>
              Document:{" "}
              <span style={{ color: "#e6edf3" }}>
                {props.documentTitle.length > 40
                  ? props.documentTitle.slice(0, 40) + "…"
                  : props.documentTitle}
              </span>
            </div>
          )}

          <div style={{ borderTop: "1px solid #21262d", marginTop: 8, paddingTop: 8 }}>
            <PermRow label="Can read" granted={true} />
            <PermRow label="Can edit" granted={props.canEdit} />
            <PermRow label="Can publish" granted={canPublish} />
            <PermRow label="Can share" granted={canShare} />
            <PermRow label="Can delete" granted={canDelete} />
          </div>

          <div style={{ borderTop: "1px solid #21262d", marginTop: 8, paddingTop: 8, color: "#8b949e" }}>
            <div>
              Status:{" "}
              <span style={{ color: props.isPublished ? "#3fb950" : "#d29922", fontWeight: 600 }}>
                {props.isPublished ? "Published" : "Private"}
              </span>
            </div>
            {props.isPublished && (
              <div>
                Edit access:{" "}
                <span style={{ color: "#c9d1d9" }}>
                  {props.editOpen ? "Anyone can edit" : "Owner only"}
                </span>
              </div>
            )}
            {props.isGrabbed && (
              <div style={{ color: "#f85149" }}>
                ⚠ Currently grabbed by another session
              </div>
            )}
          </div>

          {!props.canEdit && !props.isAnonymous && (
            <div style={{ marginTop: 8, paddingTop: 8, borderTop: "1px solid #21262d", color: "#8b949e", fontSize: 11 }}>
              {props.isPublished
                ? "This document is published but you don't have edit access. Ask the owner to enable open editing."
                : "This is a private document owned by another user."}
            </div>
          )}

          {props.isAnonymous && (
            <div style={{ marginTop: 8, paddingTop: 8, borderTop: "1px solid #21262d", color: "#58a6ff", fontSize: 11 }}>
              Sign in to create and edit documents.
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function PermRow({ label, granted }: { label: string; granted: boolean }) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
      <span style={{ color: "#8b949e" }}>{label}</span>
      <span style={{ fontWeight: 600, color: granted ? "#3fb950" : "#484f58" }}>
        {granted ? "✓ Yes" : "✗ No"}
      </span>
    </div>
  );
}
