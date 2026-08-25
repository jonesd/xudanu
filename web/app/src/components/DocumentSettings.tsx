import { useState, useEffect } from "react";

export interface DocPreferences {
  fontSize: number;
  lineHeight: number;
  defaultViewMode: "editing" | "reading";
}

const STORAGE_KEY = "xudanu-doc-prefs";

const DEFAULTS: DocPreferences = {
  fontSize: 15,
  lineHeight: 1.7,
  defaultViewMode: "editing",
};

export function loadDocPreferences(): DocPreferences {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return { ...DEFAULTS, ...JSON.parse(raw) };
  } catch { /* parse error */ }
  return { ...DEFAULTS };
}

export function saveDocPreferences(prefs: DocPreferences) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(prefs));
}

interface DocumentSettingsProps {
  visible: boolean;
  onClose: () => void;
  prefs: DocPreferences;
  onPrefsChange: (prefs: DocPreferences) => void;
  networkEnabled: boolean;
  isAdmin: boolean;
  onSetNetworkEnabled: (enabled: boolean) => Promise<void>;
}

export function DocumentSettings({ visible, onClose, prefs, onPrefsChange, networkEnabled, isAdmin, onSetNetworkEnabled }: DocumentSettingsProps) {
  const [local, setLocal] = useState(prefs);
  const [netBusy, setNetBusy] = useState(false);

  useEffect(() => {
    setLocal(prefs);
  }, [prefs, visible]);

  if (!visible) return null;

  const update = (partial: Partial<DocPreferences>) => {
    const next = { ...local, ...partial };
    setLocal(next);
    onPrefsChange(next);
    saveDocPreferences(next);
  };

  return (
    <div className="settings-overlay" onClick={onClose}>
      <div className="settings-modal" onClick={(e) => e.stopPropagation()}>
        <div className="settings-header">
          <h2>Settings</h2>
          <button type="button" className="settings-close" onClick={onClose}>×</button>
        </div>

        <div className="settings-body">
          <div className="settings-section">
            <h3>Editor</h3>
            <label className="settings-row">
              <span>Font size</span>
              <div className="settings-range-group">
                <input
                  type="range"
                  min={12}
                  max={24}
                  value={local.fontSize}
                  onChange={(e) => update({ fontSize: Number(e.target.value) })}
                />
                <span className="settings-range-value">{local.fontSize}px</span>
              </div>
            </label>
            <label className="settings-row">
              <span>Line height</span>
              <div className="settings-range-group">
                <input
                  type="range"
                  min={1.2}
                  max={2.4}
                  step={0.1}
                  value={local.lineHeight}
                  onChange={(e) => update({ lineHeight: Number(e.target.value) })}
                />
                <span className="settings-range-value">{local.lineHeight.toFixed(1)}</span>
              </div>
            </label>
          </div>

          <div className="settings-section">
            <h3>Behavior</h3>
            <label className="settings-row">
              <span>Default view</span>
              <select
                value={local.defaultViewMode}
                onChange={(e) => update({ defaultViewMode: e.target.value as "editing" | "reading" })}
                className="settings-select"
              >
                <option value="editing">Editing</option>
                <option value="reading">Reading</option>
              </select>
            </label>
          </div>

          <div className="settings-section">
            <h3>Xudanu network</h3>
            <div className="settings-row">
              <div>
                <span>Connect to other servers</span>
                <div className="settings-sub">
                  {networkEnabled
                    ? "Cross-server links, federation sync, and the server directory are active."
                    : "Single-player mode (default): this server makes no outbound connections to other xudanu servers."}
                </div>
              </div>
              <button
                type="button"
                role="switch"
                aria-checked={networkEnabled}
                className={`settings-switch ${networkEnabled ? "on" : ""}`}
                disabled={!isAdmin || netBusy}
                title={isAdmin ? undefined : "Admin sign-in required"}
                onClick={async () => {
                  setNetBusy(true);
                  try {
                    await onSetNetworkEnabled(!networkEnabled);
                  } finally {
                    setNetBusy(false);
                  }
                }}
              >
                <span className="settings-switch-knob" />
              </button>
            </div>
            <div className={`settings-net-status ${networkEnabled ? "on" : "off"}`}>
              {networkEnabled ? "● Network: ON" : "● Network: OFF (single-player)"}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
