import { useState, useEffect, useCallback } from "react";
import { storageGet, storageSet } from "../safe-storage";
import {
  cacheStats,
  getCacheLimitMb,
  setCacheLimitMb,
  MIN_CACHE_LIMIT_MB,
  MAX_CACHE_LIMIT_MB,
  type CacheStats,
} from "../offline-cache";

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
    const raw = storageGet(STORAGE_KEY);
    if (raw) return { ...DEFAULTS, ...JSON.parse(raw) };
  } catch { /* parse error */ }
  return { ...DEFAULTS };
}

export function saveDocPreferences(prefs: DocPreferences) {
  storageSet(STORAGE_KEY, JSON.stringify(prefs));
}

interface DocumentSettingsProps {
  visible: boolean;
  onClose: () => void;
  prefs: DocPreferences;
  onPrefsChange: (prefs: DocPreferences) => void;
  networkEnabled: boolean;
  externalLinksEnabled: boolean;
  isAdmin: boolean;
  onSetNetworkEnabled: (enabled: boolean) => Promise<void>;
  onSetExternalLinksEnabled: (enabled: boolean) => Promise<void>;
}

export function DocumentSettings({ visible, onClose, prefs, onPrefsChange, networkEnabled, externalLinksEnabled, isAdmin, onSetNetworkEnabled, onSetExternalLinksEnabled }: DocumentSettingsProps) {
  const [local, setLocal] = useState(prefs);
  const [netBusy, setNetBusy] = useState(false);
  const [cacheLimit, setCacheLimit] = useState(getCacheLimitMb());
  const [stats, setStats] = useState<CacheStats | null>(null);

  const refreshStats = useCallback(() => {
    cacheStats().then(setStats).catch(() => setStats(null));
  }, []);

  useEffect(() => {
    if (visible) refreshStats();
  }, [visible, refreshStats]);

  const fmtMB = (bytes: number) => {
    const mb = bytes / (1024 * 1024);
    return mb >= 1 ? `${mb.toFixed(1)} MB` : `${(bytes / 1024).toFixed(0)} KB`;
  };

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

          <div className="settings-section">
            <h3>Links in documents</h3>
            <div className="settings-row">
              <div>
                <span>Allow external web links</span>
                <div className="settings-sub">
                  {externalLinksEnabled
                    ? "http(s) URLs in documents open in a new tab."
                    : "Locked down (default): links to this server navigate in-app; external URLs stay plain text."}
                </div>
              </div>
              <button
                type="button"
                role="switch"
                aria-checked={externalLinksEnabled}
                className={`settings-switch ${externalLinksEnabled ? "on" : ""}`}
                disabled={!isAdmin}
                title={isAdmin ? undefined : "Admin sign-in required"}
                onClick={() => void onSetExternalLinksEnabled(!externalLinksEnabled)}
              >
                <span className="settings-switch-knob" />
              </button>
            </div>
          </div>
          <div className="settings-section">
            <h3>Offline reading</h3>
            <div className="settings-row">
              <div>
                <span>Cache size</span>
                <div className="settings-sub">
                  {stats
                    ? `${stats.documents} document(s) cached (${stats.starred} starred) using ${fmtMB(stats.totalBytes)}`
                    : "Recently read documents are kept for offline reading; starred works are always kept."}
                  {stats?.overBudget && " — over budget (starred set exceeds the limit)"}
                </div>
              </div>
              <span className="settings-range-value">{cacheLimit} MB</span>
            </div>
            <input
              type="range"
              min={MIN_CACHE_LIMIT_MB}
              max={MAX_CACHE_LIMIT_MB}
              step={10}
              value={cacheLimit}
              onChange={(e) => {
                const v = Number(e.target.value);
                setCacheLimit(v);
                setCacheLimitMb(v);
                refreshStats();
              }}
              style={{ width: "100%" }}
              aria-label="Offline cache size in megabytes"
            />
            <div className="settings-sub" style={{ display: "flex", justifyContent: "space-between" }}>
              <span>{MIN_CACHE_LIMIT_MB} MB</span>
              <span>{MAX_CACHE_LIMIT_MB} MB</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
