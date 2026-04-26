import { useState, useEffect } from "react";

interface DebugAssertion {
  id: number;
  traceId: string;
  branchId: number;
  position: number;
  payloadType: string;
  payloadSummary: string;
}

interface DebugBranch {
  branchId: number;
  lastPosition: number;
  parentTraces: string[] | null;
}

interface DebugData {
  workspaceId: string;
  assertions: DebugAssertion[];
  branches: DebugBranch[];
}

interface DebugPanelProps {
  workspaceId: string;
  visible: boolean;
}

export function DebugPanel({ workspaceId, visible }: DebugPanelProps) {
  const [data, setData] = useState<DebugData | null>(null);
  const [tab, setTab] = useState<"assertions" | "branches">("assertions");

  useEffect(() => {
    if (!visible) return;
    fetch(`/api/workspaces/${workspaceId}/debug`)
      .then((r) => r.json())
      .then(setData)
      .catch(console.error);
  }, [visible, workspaceId]);

  if (!visible || !data) return null;

  return (
    <div className="debug-panel">
      <div className="debug-tabs">
        <button
          className={tab === "assertions" ? "debug-tab-active" : ""}
          onClick={() => setTab("assertions")}
        >
          Assertions ({data.assertions.length})
        </button>
        <button
          className={tab === "branches" ? "debug-tab-active" : ""}
          onClick={() => setTab("branches")}
        >
          Branches ({data.branches.length})
        </button>
      </div>

      {tab === "assertions" && (
        <table className="debug-table">
          <thead>
            <tr>
              <th>#</th>
              <th>Trace</th>
              <th>Type</th>
              <th>Details</th>
            </tr>
          </thead>
          <tbody>
            {data.assertions.map((a) => (
              <tr key={a.id}>
                <td className="debug-id">{a.id}</td>
                <td className="debug-trace">
                  <span className="debug-badge">{a.traceId}</span>
                  <span className="debug-pos-detail">
                    b{a.branchId}:p{a.position}
                  </span>
                </td>
                <td className="debug-type">{a.payloadType}</td>
                <td className="debug-summary">{a.payloadSummary}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {tab === "branches" && (
        <table className="debug-table">
          <thead>
            <tr>
              <th>Branch</th>
              <th>Last Pos</th>
              <th>Kind</th>
              <th>Parents</th>
            </tr>
          </thead>
          <tbody>
            {data.branches.map((b) => (
              <tr key={b.branchId}>
                <td className="debug-id">b{b.branchId}</td>
                <td>{b.lastPosition}</td>
                <td>
                  {b.parentTraces === null
                    ? "Root"
                    : b.parentTraces.length === 1
                      ? "Tree"
                      : "Dag"}
                </td>
                <td className="debug-summary">
                  {b.parentTraces
                    ?.map((p) => (
                      <span key={p} className="debug-badge">
                        {p}
                      </span>
                    ))
                    .reduce(
                      (acc, el, i) =>
                        i === 0 ? (
                          [el]
                        ) : (
                          <>
                            {acc} + {el}
                          </>
                        ),
                      null as React.ReactNode,
                    )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
