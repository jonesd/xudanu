import { useState, useCallback, useRef, useEffect } from "react";
import { TextBuffer, type SearchMatch } from "../api/text_buffer";

interface SearchPanelProps {
  buffer: TextBuffer;
  onJumpToMatch: (charOffset: number) => void;
  onClose: () => void;
}

export function SearchPanel({ buffer, onJumpToMatch, onClose }: SearchPanelProps) {
  const [query, setQuery] = useState("");
  const [caseSensitive, setCaseSensitive] = useState(false);
  const [matches, setMatches] = useState<SearchMatch[]>([]);
  const [currentMatch, setCurrentMatch] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  useEffect(() => {
    const results = buffer.search(query, caseSensitive);
    setMatches(results);
    setCurrentMatch(0);
  }, [query, caseSensitive, buffer]);

  const next = useCallback(() => {
    if (matches.length === 0) return;
    const nextIdx = (currentMatch + 1) % matches.length;
    setCurrentMatch(nextIdx);
    onJumpToMatch(matches[nextIdx].start);
  }, [matches, currentMatch, onJumpToMatch]);

  const prev = useCallback(() => {
    if (matches.length === 0) return;
    const prevIdx = (currentMatch - 1 + matches.length) % matches.length;
    setCurrentMatch(prevIdx);
    onJumpToMatch(matches[prevIdx].start);
  }, [matches, currentMatch, onJumpToMatch]);

  useEffect(() => {
    if (matches.length > 0) {
      onJumpToMatch(matches[currentMatch].start);
    }
  }, [currentMatch, matches]);

  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        onClose();
      } else if (e.key === "Enter") {
        e.preventDefault();
        if (e.shiftKey) {
          prev();
        } else {
          next();
        }
      } else if ((e.ctrlKey || e.metaKey) && e.key === "g") {
        e.preventDefault();
        if (e.shiftKey) {
          prev();
        } else {
          next();
        }
      }
    };
    document.addEventListener("keydown", handleKey);
    return () => document.removeEventListener("keydown", handleKey);
  }, [next, prev, onClose]);

  return (
    <div className="search-panel">
      <div className="search-input-row">
        <input
          ref={inputRef}
          type="text"
          className="search-input"
          placeholder="Search document..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <button
          className={`search-option${caseSensitive ? " active" : ""}`}
          onClick={() => setCaseSensitive(!caseSensitive)}
          title="Case sensitive"
        >
          Aa
        </button>
        <span className="search-count">
          {matches.length > 0 ? `${currentMatch + 1}/${matches.length}` : "0/0"}
        </span>
        <button className="search-nav" onClick={prev} disabled={matches.length === 0}>
          ↑
        </button>
        <button className="search-nav" onClick={next} disabled={matches.length === 0}>
          ↓
        </button>
        <button className="search-close" onClick={onClose}>
          ×
        </button>
      </div>
    </div>
  );
}
