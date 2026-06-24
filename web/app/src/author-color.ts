const AUTHOR_COLORS = [
  "#e06c75", "#61afef", "#98c379", "#c678dd", "#e5c07b",
  "#56b6c2", "#d19a66", "#be5046", "#7ec8e3", "#c3e88d",
  "#ff6b6b", "#4ecdc4", "#ffe66d", "#a8e6cf", "#ff8b94",
  "#9b59b6", "#3498db", "#e74c3c", "#2ecc71", "#f39c12",
  "#1abc9c", "#e67e22", "#34495e", "#16a085", "#27ae60",
];

function hashString(s: string): number {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  // Extra mixing for better distribution with short strings
  h ^= h >>> 16;
  h = Math.imul(h, 0x21f0aaad);
  h ^= h >>> 15;
  return h >>> 0;
}

export function authorColor(key: string): string {
  return AUTHOR_COLORS[hashString(key) % AUTHOR_COLORS.length];
}
