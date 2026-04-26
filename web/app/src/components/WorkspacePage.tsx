import { useState, useEffect, useCallback } from "react";
import type { WorkspaceListItem, BranchItem, DocumentResponse } from "../types/api";
import * as api from "../api/client";
import { BranchPanel } from "../components/BranchPanel";
import { DocumentRenderer } from "../components/DocumentRenderer";
import { DebugPanel } from "../components/DebugPanel";

export function WorkspacePage() {
  const [workspaces, setWorkspaces] = useState<WorkspaceListItem[]>([]);
  const [selectedWs, setSelectedWs] = useState<WorkspaceListItem | null>(null);
  const [branches, setBranches] = useState<BranchItem[]>([]);
  const [selectedBranch, setSelectedBranch] = useState<BranchItem | null>(null);
  const [document, setDocument] = useState<DocumentResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [showDebug, setShowDebug] = useState(false);

  useEffect(() => {
    api
      .listWorkspaces()
      .then(async (ws) => {
        if (ws.length === 0) {
          const resp = await api.createWorkspace({ name: "Welcome" });
          const initial: WorkspaceListItem = {
            workspaceId: resp.workspaceId,
            name: "Welcome",
          };
          setWorkspaces([initial]);
          setSelectedWs(initial);
        } else {
          setWorkspaces(ws);
          setSelectedWs(ws[0]);
        }
      })
      .catch((e) => setError(e.message));
  }, []);

  const refreshDocument = useCallback(async () => {
    if (!selectedWs) return;
    try {
      const bs = await api.listBranches(selectedWs.workspaceId);
      setBranches(bs);
      const updated = bs.find((b) => b.branchId === selectedBranch?.branchId);
      if (updated) {
        setSelectedBranch(updated);
        const doc = await api.getDocument(selectedWs.workspaceId, updated.headTraceId);
        setDocument(doc);
      }
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    }
  }, [selectedWs, selectedBranch]);

  useEffect(() => {
    if (!selectedWs) return;
    setSelectedBranch(null);
    setDocument(null);
    api
      .listBranches(selectedWs.workspaceId)
      .then((bs) => {
        setBranches(bs);
        if (bs.length > 0) setSelectedBranch(bs[0]);
      })
      .catch((e) => setError(e.message));
  }, [selectedWs]);

  useEffect(() => {
    if (!selectedWs || !selectedBranch) return;
    setDocument(null);
    api
      .getDocument(selectedWs.workspaceId, selectedBranch.headTraceId)
      .then(setDocument)
      .catch((e) => setError(e.message));
  }, [selectedWs, selectedBranch]);

  const handleBranchSelect = useCallback(
    (branch: BranchItem) => setSelectedBranch(branch),
    [],
  );

  const handleCreateWorkspace = useCallback(() => {
    const name = prompt("Workspace name:");
    if (!name) return;
    api
      .createWorkspace({ name })
      .then((resp) => {
        const newItem: WorkspaceListItem = {
          workspaceId: resp.workspaceId,
          name,
        };
        setWorkspaces((prev) => [...prev, newItem]);
        setSelectedWs(newItem);
      })
      .catch((e) => setError(e.message));
  }, []);

  return (
    <div className="workspace-page">
      <header className="workspace-header">
        <h1>
          {selectedWs ? selectedWs.name : "No workspace"}
        </h1>
        <div className="header-actions">
          <button
            onClick={() => setShowDebug((d) => !d)}
            type="button"
            className={showDebug ? "debug-toggle-active" : ""}
          >
            Debug
          </button>
          <button onClick={handleCreateWorkspace} type="button">
            New Workspace
          </button>
        </div>
      </header>

      {error && <div className="error">{error}</div>}

      <div className="workspace-body">
        <BranchPanel
          branches={branches}
          selectedBranchId={selectedBranch?.branchId ?? null}
          onSelect={handleBranchSelect}
        />

        <main className="document-area">
          {document ? (
            <DocumentRenderer response={document} onContentChanged={refreshDocument} />
          ) : selectedBranch ? (
            <div className="loading">Loading...</div>
          ) : (
            <div className="loading">Select a branch</div>
          )}
        </main>
      </div>

      {selectedWs && (
        <DebugPanel workspaceId={selectedWs.workspaceId} visible={showDebug} />
      )}
    </div>
  );
}
