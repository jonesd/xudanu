import { useState, useEffect, useCallback } from "react";
import type { CrdtSyncClient } from "../api/crdt_sync";
import { useDraggable } from "../hooks/useDraggable";

interface Props {
  client: CrdtSyncClient | null;
  currentWorkId: number | null;
  onSelectWork: (workId: number) => void;
  onClose: () => void;
}

interface GeneNode {
  id: number;
  title: string;
  isCurrent: boolean;
}

function hexId(id: number): string {
  return id.toString(16).padStart(4, "0");
}

export function VersionGenealogyPanel({ client, currentWorkId, onSelectWork, onClose }: Props) {
  const { drag, onMouseDown, dialogRef } = useDraggable();
  const [ancestors, setAncestors] = useState<GeneNode[]>([]);
  const [descendants, setDescendants] = useState<GeneNode[]>([]);
  const [currentTitle, setCurrentTitle] = useState("");
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    if (!client || !currentWorkId) return;
    setLoading(true);
    try {
      const [ancIds, descIds] = await Promise.all([
        client.versionAncestors(currentWorkId),
        client.versionDescendants(currentWorkId),
      ]);

      const works = await client.fetchWorkList();
      const titleMap = new Map(works.map((w) => [w.work_id, w.title || "Untitled"]));

      const buildNodes = (ids: number[]): GeneNode[] =>
        ids.map((id) => ({
          id,
          title: titleMap.get(id) || `Work ${hexId(id)}`,
          isCurrent: false,
        }));

      setAncestors(buildNodes(ancIds));
      setDescendants(buildNodes(descIds));
      setCurrentTitle(titleMap.get(currentWorkId) || `Work ${hexId(currentWorkId)}`);
    } catch (e) {
      console.error("Genealogy load failed:", e);
    }
    setLoading(false);
  }, [client, currentWorkId]);

  useEffect(() => {
    load();
  }, [load]);

  const renderNode = (node: GeneNode, isCurrent = false) => {
    return (
      <div
        key={node.id}
        className={`gene-node ${isCurrent ? "gene-node-current" : ""}`}
        onClick={() => { onSelectWork(node.id); onClose(); }}
        title={node.title}
      >
        <span className="gene-node-title">
          {node.title.length > 28 ? node.title.slice(0, 28) + "\u2026" : node.title}
        </span>
        <span className="gene-node-id">{hexId(node.id)}</span>
      </div>
    );
  };

  return (
    <div className="panel-overlay" onClick={onClose}>
      <div
        ref={dialogRef}
        className="panel-dialog"
        style={{
          transform: `translate(${drag.offsetX}px, ${drag.offsetY}px)`,
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div
          className="panel-header"
          onMouseDown={onMouseDown}
          style={{ cursor: "grab", userSelect: "none" }}>
          <span className="panel-title">Version Genealogy</span>
          <button type="button" className="panel-close" onClick={onClose}>{"\u00d7"}</button>
        </div>
        <div className="panel-body">
          {loading ? (
            <div className="panel-empty">Loading genealogy...</div>
          ) : ancestors.length === 0 && descendants.length === 0 ? (
            <div className="panel-empty">
              This document has no ancestors or descendants.
              <br />
              <span style={{ fontSize: 12, color: "#6b7280" }}>
                Ancestry is tracked when content is transcluded between documents.
              </span>
            </div>
          ) : (
            <>
              {ancestors.length > 0 && (
                <>
                  <div className="gene-section-label">Ancestors ({ancestors.length})</div>
                  <div className="gene-section-hint">
                    Documents this work was derived from
                  </div>
                  <div className="gene-list">
                    {ancestors.map((n) => renderNode(n))}
                  </div>
                  <div className="gene-connector">{"\u2193"}</div>
                </>
              )}

              <div className="gene-current">
                {renderNode({ id: currentWorkId!, title: currentTitle, isCurrent: true }, true)}
              </div>

              {descendants.length > 0 && (
                <>
                  <div className="gene-connector">{"\u2193"}</div>
                  <div className="gene-section-label">Descendants ({descendants.length})</div>
                  <div className="gene-section-hint">
                    Documents derived from this work
                  </div>
                  <div className="gene-list">
                    {descendants.map((n) => renderNode(n))}
                  </div>
                </>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
