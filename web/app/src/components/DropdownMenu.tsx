import { useState, useRef, useEffect, type ReactNode } from "react";

interface DropdownMenuProps {
  label: ReactNode;
  className?: string;
  disabled?: boolean;
  active?: boolean;
  children: ReactNode;
}

export function DropdownMenu({ label, className, disabled, active, children }: DropdownMenuProps) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [open]);

  return (
    <div ref={ref} className={`dropdown-menu ${className || ""} ${active ? "dropdown-active" : ""}`}>
      <button
        type="button"
        className="dropdown-toggle"
        disabled={disabled}
        onClick={() => setOpen((o) => !o)}
      >
        {label}
      </button>
      {open && (
        <div className="dropdown-panel" onClick={(e) => e.stopPropagation()}>
          {typeof children === "function" ? (children as (close: () => void) => ReactNode)(() => setOpen(false)) : children}
        </div>
      )}
    </div>
  );
}

interface DropdownItemProps {
  onClick?: () => void;
  disabled?: boolean;
  checked?: boolean;
  children: ReactNode;
}

export function DropdownItem({ onClick, disabled, checked, children }: DropdownItemProps) {
  return (
    <button
      type="button"
      className={`dropdown-item ${checked ? "dropdown-item-checked" : ""}`}
      disabled={disabled}
      onClick={onClick}
    >
      {checked != null && <span className="dropdown-check">{checked ? "✓" : ""}</span>}
      {children}
    </button>
  );
}

interface DropdownSeparatorProps {}

export function DropdownSeparator(_props: DropdownSeparatorProps) {
  return <div className="dropdown-separator" />;
}

interface DropdownLabelProps {
  children: ReactNode;
}

export function DropdownLabel({ children }: DropdownLabelProps) {
  return <div className="dropdown-label">{children}</div>;
}
