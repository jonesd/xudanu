import type { BranchItem } from "../types/api";

interface BranchPanelProps {
  branches: BranchItem[];
  selectedBranchId: string | null;
  onSelect: (branch: BranchItem) => void;
}

export function BranchPanel({
  branches,
  selectedBranchId,
  onSelect,
}: BranchPanelProps) {
  return (
    <aside className="branch-panel">
      <h2>Branches</h2>
      <ul>
        {branches.map((b) => (
          <li
            key={b.branchId}
            className={
              selectedBranchId === b.branchId ? "branch-selected" : ""
            }
          >
            <button onClick={() => onSelect(b)} type="button">
              {b.name}
            </button>
          </li>
        ))}
      </ul>
    </aside>
  );
}
