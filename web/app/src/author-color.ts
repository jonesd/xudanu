const AUTHOR_COLORS = [
  "#e06c75", "#61afef", "#98c379", "#c678dd", "#e5c07b",
  "#56b6c2", "#d19a66", "#be5046", "#7ec8e3", "#c3e88d",
];

function hashString(s: string): number {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

export function authorColor(key: string): string {
  return AUTHOR_COLORS[hashString(key) % AUTHOR_COLORS.length];
}
