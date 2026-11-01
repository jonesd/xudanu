import { useCallback, useEffect, useState } from "react";
import type {
  CrdtSyncClient,
  SkillClaimEntry,
  WhoAmIEntry,
  WorkListEntry,
} from "../api/crdt_sync";

// FR-158 Stage A2: the claims panel. List/detail with grade badges
// and evidence work-links — no graph (endorsement edges are v2,
// where they join the FR-22 person nodes in the map). Read side is
// any session; claiming and endorsing need an identity. Endorse
// obeys the two-person rule (you never endorse your own claim) and
// one-per-identity (Retract replaces Endorse once you have).

interface Props {
  client: CrdtSyncClient | null;
  identity: WhoAmIEntry | null;
  currentWorkId: number | null;
  works: WorkListEntry[];
  onSelectWork: (workId: number) => void;
}

export function hexWorkId(workId: number): string {
  return workId.toString(16);
}

export function parseWorkHex(hex: string): number | null {
  if (!/^[0-9a-fA-F]+$/.test(hex)) return null;
  const n = parseInt(hex, 16);
  return Number.isSafeInteger(n) ? n : null;
}

/** Two-person rule: a claim's subject never endorses it. */
export function canEndorse(claim: SkillClaimEntry, myClubId: number | null): boolean {
  return myClubId !== null && claim.subject !== myClubId;
}

export function iHaveEndorsed(claim: SkillClaimEntry, myClubId: number | null): boolean {
  return myClubId !== null && claim.endorsers.includes(myClubId);
}

const BADGE: Record<string, { label: string; background: string; color: string }> = {
  claimed: { label: "claimed", background: "#30363d", color: "#e8e6e0" },
  verified: { label: "verified", background: "#39d2c0", color: "#0d1117" },
};

function GradeBadge({ grade }: { grade: string }) {
  const style = BADGE[grade] ?? BADGE.claimed;
  return (
    <span
      title={
        grade === "verified"
          ? "A peer has endorsed this claim"
          : "Self-asserted; no peer endorsement yet"
      }
      style={{
        background: style.background,
        color: style.color,
        borderRadius: 8,
        fontSize: 10,
        fontWeight: 700,
        padding: "1px 7px",
        verticalAlign: "middle",
        whiteSpace: "nowrap",
      }}
    >
      {style.label}
    </span>
  );
}

function EvidenceChips({
  claim,
  works,
  onSelectWork,
}: {
  claim: SkillClaimEntry;
  works: WorkListEntry[];
  onSelectWork: (workId: number) => void;
}) {
  return (
    <div style={{ display: "flex", flexWrap: "wrap", gap: 4, marginTop: 4 }}>
      {claim.evidence.map((e, i) => {
        const id = parseWorkHex(e.work_id);
        const title = id !== null ? works.find((w) => w.work_id === id)?.title : undefined;
        const label = title ? `0x${e.work_id} ${title}` : `0x${e.work_id}`;
        return (
          <button
            key={`${e.work_id}-${i}`}
            type="button"
            className="ws-action-btn"
            style={{ fontSize: 11, padding: "1px 7px" }}
            title={e.note || "evidence work"}
            onClick={() => {
              if (id !== null) onSelectWork(id);
            }}
          >
            {label}
          </button>
        );
      })}
    </div>
  );
}

function ClaimCard({
  claim,
  identity,
  works,
  busy,
  onSelectWork,
  onEndorse,
  onUnendorse,
}: {
  claim: SkillClaimEntry;
  identity: WhoAmIEntry | null;
  works: WorkListEntry[];
  busy: boolean;
  onSelectWork: (workId: number) => void;
  onEndorse: (claim: SkillClaimEntry) => void;
  onUnendorse: (claim: SkillClaimEntry) => void;
}) {
  const myClub = identity?.club_id ?? null;
  const mine = claim.subject === myClub;
  const endorsed = iHaveEndorsed(claim, myClub);
  return (
    <div
      style={{
        border: "1px solid #30363d",
        borderRadius: 8,
        padding: "8px 10px",
        marginTop: 8,
        background: "#161b22",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
        <strong>{claim.skill}</strong>
        <GradeBadge grade={claim.grade} />
        <span style={{ marginLeft: "auto", fontSize: 11, color: "var(--text-dim)" }}>
          {new Date(claim.created_at * 1000).toLocaleDateString()}
        </span>
      </div>
      {claim.summary && (
        <div style={{ fontSize: "calc(var(--ws-font, 14px) - 1px)", marginTop: 3 }}>
          {claim.summary}
        </div>
      )}
      <EvidenceChips claim={claim} works={works} onSelectWork={onSelectWork} />
      <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 6, flexWrap: "wrap" }}>
        <span style={{ fontSize: 11, color: "var(--text-dim)" }}>
          {claim.endorsements === 0
            ? "no endorsements yet"
            : `${claim.endorsements} endorsement${claim.endorsements === 1 ? "" : "s"}: club ${claim.endorsers.join(", club ")}`}
        </span>
        <span style={{ marginLeft: "auto", display: "flex", gap: 6 }}>
          {mine ? (
            <span style={{ fontSize: 11, color: "var(--text-dim)" }} title="Two-person rule: peers endorse your claim; you cannot.">
              your claim
            </span>
          ) : identity === null ? (
            <span style={{ fontSize: 11, color: "var(--text-dim)" }}>log in to endorse</span>
          ) : endorsed ? (
            <button
              type="button"
              className="ws-action-btn"
              disabled={busy}
              onClick={() => onUnendorse(claim)}
            >
              Retract endorsement
            </button>
          ) : (
            <button
              type="button"
              className="ws-action-btn"
              disabled={busy}
              onClick={() => onEndorse(claim)}
            >
              Endorse
            </button>
          )}
        </span>
      </div>
    </div>
  );
}

type Tab = "mine" | "find";

export function SkillsPanel({ client, identity, currentWorkId, works, onSelectWork }: Props) {
  const [tab, setTab] = useState<Tab>("mine");
  const [myClaims, setMyClaims] = useState<SkillClaimEntry[]>([]);
  const [searchInput, setSearchInput] = useState("");
  const [searchedSkill, setSearchedSkill] = useState<string | null>(null);
  const [skillClaims, setSkillClaims] = useState<SkillClaimEntry[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busyClaim, setBusyClaim] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [formSkill, setFormSkill] = useState("");
  const [formSummary, setFormSummary] = useState("");
  const [formNote, setFormNote] = useState("");
  const [citeCurrent, setCiteCurrent] = useState(true);

  const myClub = identity?.club_id ?? null;

  const refreshMine = useCallback(async () => {
    if (!client || myClub === null) return;
    try {
      const res = await client.skillListByClub(myClub);
      setMyClaims(res.claims);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  }, [client, myClub]);

  useEffect(() => {
    void refreshMine();
  }, [refreshMine]);

  const runSearch = useCallback(async () => {
    if (!client) return;
    const q = searchInput.trim();
    if (!q) return;
    setLoading(true);
    setError(null);
    try {
      const res = await client.skillListBySkill(q);
      setSkillClaims(res.claims);
      setSearchedSkill(res.skill ?? q);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [client, searchInput]);

  const endorse = async (claim: SkillClaimEntry) => {
    if (!client) return;
    setBusyClaim(claim.claim);
    setError(null);
    try {
      await client.skillEndorse(claim.claim);
      await Promise.all([refreshMine(), searchedSkill !== null ? runSearch() : Promise.resolve()]);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusyClaim(null);
    }
  };

  const unendorse = async (claim: SkillClaimEntry) => {
    if (!client) return;
    setBusyClaim(claim.claim);
    setError(null);
    try {
      await client.skillUnendorse(claim.claim);
      await Promise.all([refreshMine(), searchedSkill !== null ? runSearch() : Promise.resolve()]);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusyClaim(null);
    }
  };

  const submit = async () => {
    if (!client || myClub === null) return;
    setError(null);
    const evidence: Array<{ work_id: string; note: string }> = [];
    if (citeCurrent && currentWorkId !== null) {
      evidence.push({ work_id: hexWorkId(currentWorkId), note: formNote.trim() });
    }
    if (evidence.length === 0) {
      setError("a claim anchors to evidence: open a work to cite, or log in");
      return;
    }
    try {
      const created = await client.skillClaimSubmit(
        myClub,
        formSkill,
        formSummary,
        evidence,
      );
      setMyClaims((prev) => [created, ...prev.filter((c) => c.claim !== created.claim)]);
      setShowForm(false);
      setFormSkill("");
      setFormSummary("");
      setFormNote("");
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  };

  const claims = tab === "mine" ? myClaims : skillClaims;

  return (
    <div className="ws-trails-tab">
      <div className="ws-trails-tab-header">
        <span>Skills claims</span>
      </div>
      <div style={{ fontSize: "calc(var(--ws-font, 14px) - 1px)", color: "var(--text-dim)", margin: "4px 0 8px" }}>
        Who knows what, with receipts: claims anchor to works, peers endorse them, grades are earned.
      </div>
      <div className="ws-tabs" style={{ marginBottom: 8 }}>
        <button className={`ws-tab ${tab === "mine" ? "active" : ""}`} onClick={() => setTab("mine")}>
          {myClub !== null ? `My claims (${myClaims.length})` : "My claims"}
        </button>
        <button className={`ws-tab ${tab === "find" ? "active" : ""}`} onClick={() => setTab("find")}>
          Find by skill
        </button>
      </div>

      {tab === "mine" && (
        <>
          {myClub === null ? (
            <div className="ws-placeholder">
              <div className="ws-placeholder-label">
                Log in to file claims and endorse peers. Reading claims needs no login.
              </div>
            </div>
          ) : (
            <>
              <button
                type="button"
                className="ws-action-btn"
                style={{ width: "100%", justifyContent: "center" }}
                onClick={() => setShowForm((v) => !v)}
              >
                {showForm ? "Cancel" : "Claim a skill"}
              </button>
              {showForm && (
                <div style={{ border: "1px solid #30363d", borderRadius: 8, padding: 10, marginTop: 8, display: "grid", gap: 6 }}>
                  <input
                    placeholder="skill (e.g. Rust, derivatives pricing)"
                    value={formSkill}
                    onChange={(e) => setFormSkill(e.target.value)}
                    style={{ background: "#0d1117", border: "1px solid #30363d", borderRadius: 6, color: "#e8e6e0", padding: "4px 8px" }}
                  />
                  <input
                    placeholder="summary (optional, ≤280 chars)"
                    value={formSummary}
                    onChange={(e) => setFormSummary(e.target.value)}
                    style={{ background: "#0d1117", border: "1px solid #30363d", borderRadius: 6, color: "#e8e6e0", padding: "4px 8px" }}
                  />
                  <input
                    placeholder="what about the evidence demonstrates it (optional)"
                    value={formNote}
                    onChange={(e) => setFormNote(e.target.value)}
                    style={{ background: "#0d1117", border: "1px solid #30363d", borderRadius: 6, color: "#e8e6e0", padding: "4px 8px" }}
                  />
                  <label style={{ fontSize: 12, color: "var(--text-dim)", display: "flex", gap: 6, alignItems: "center" }}>
                    <input type="checkbox" checked={citeCurrent} onChange={(e) => setCiteCurrent(e.target.checked)} />
                    {currentWorkId !== null
                      ? `cite open work 0x${hexWorkId(currentWorkId)} as evidence`
                      : "cite the open work as evidence (none open)"}
                  </label>
                  <button
                    type="button"
                    className="ws-action-btn"
                    style={{ justifyContent: "center" }}
                    disabled={!formSkill.trim() || (!citeCurrent || currentWorkId === null)}
                    onClick={() => void submit()}
                  >
                    Submit claim
                  </button>
                </div>
              )}
              {myClaims.length === 0 && !showForm && (
                <div className="ws-placeholder">
                  <div className="ws-placeholder-label">No claims yet. Claim a skill, anchored to a work.</div>
                </div>
              )}
            </>
          )}
        </>
      )}

      {tab === "find" && (
        <div style={{ display: "flex", gap: 6, marginBottom: 4 }}>
          <input
            placeholder="skill tag (e.g. rust)"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") void runSearch();
            }}
            style={{ flex: 1, background: "#0d1117", border: "1px solid #30363d", borderRadius: 6, color: "#e8e6e0", padding: "4px 8px" }}
          />
          <button type="button" className="ws-action-btn" onClick={() => void runSearch()}>
            Search
          </button>
        </div>
      )}

      {error && (
        <div style={{ color: "#f85149", fontSize: 12, margin: "6px 0" }}>{error}</div>
      )}

      {tab === "find" && searchedSkill !== null && !loading && (
        <div style={{ fontSize: 12, color: "var(--text-dim)", marginTop: 6 }}>
          {skillClaims.length === 0
            ? `nobody claims "${searchedSkill}" yet`
            : `${skillClaims.length} claim${skillClaims.length === 1 ? "" : "s"} for "${searchedSkill}"`}
        </div>
      )}

      {claims.map((c) => (
        <ClaimCard
          key={c.claim}
          claim={c}
          identity={identity}
          works={works}
          busy={busyClaim === c.claim}
          onSelectWork={onSelectWork}
          onEndorse={(cl) => void endorse(cl)}
          onUnendorse={(cl) => void unendorse(cl)}
        />
      ))}
    </div>
  );
}
