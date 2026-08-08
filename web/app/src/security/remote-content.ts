export const MAX_REMOTE_TEXT_CHARS = 100_000;
export const MAX_REMOTE_TITLE_CHARS = 500;
export const MAX_REMOTE_FETCH_TIMEOUT_MS = 10_000;
export const MAX_REMOTE_WORKS_COUNT = 500;

const PRIVATE_IP_PATTERNS: RegExp[] = [
  /^127\./,
  /^10\./,
  /^172\.(1[6-9]|2[0-9]|3[01])\./,
  /^192\.168\./,
  /^169\.254\./,
  /^0\./,
  /^100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\./,
];

const BLOCKED_HOSTNAMES = new Set([
  "metadata.google.internal",
]);

const LOOPBACK_HOSTNAMES = new Set([
  "localhost",
  "ip6-localhost",
  "ip6-loopback",
]);

export function isPrivateIp(ip: string): boolean {
  if (ip === "0.0.0.0" || ip === "::" || ip === "::1" || ip === "[::1]") return true;
  for (const pat of PRIVATE_IP_PATTERNS) {
    if (pat.test(ip)) return true;
  }
  if (ip.startsWith("fc") || ip.startsWith("fd") || ip.startsWith("fe80")) return true;
  return false;
}

export function isBlockedAddress(rawAddr: string): boolean {
  let addr = rawAddr.trim().toLowerCase();
  addr = addr.replace(/^https?:\/\//, "");

  let host: string;
  if (addr.startsWith("[")) {
    const close = addr.indexOf("]");
    host = close !== -1 ? addr.substring(1, close) : addr.replace(/^\[/, "");
  } else if ((addr.match(/:/g) || []).length > 1) {
    host = addr.split("/")[0];
  } else {
    host = addr.split(":")[0].split("/")[0];
  }

  if (BLOCKED_HOSTNAMES.has(host)) return true;
  if (LOOPBACK_HOSTNAMES.has(host)) return true;
  if (isPrivateIp(host)) return true;

  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(host)) {
    if (isPrivateIp(host)) return true;
  }

  if (/^0x[0-9a-f]+$/i.test(host)) {
    const n = parseInt(host, 16);
    if (n === 0 || n === 0x7f000001) return true;
    const a = (n >> 24) & 0xff;
    if (a === 10 || a === 127 || a === 0) return true;
    if (a === 172) {
      const b = (n >> 16) & 0xff;
      if (b >= 16 && b <= 31) return true;
    }
    if (a === 192) {
      const b = (n >> 16) & 0xff;
      if (b === 168) return true;
    }
  }

  if (/^\d+$/.test(host)) {
    const n = parseInt(host, 10);
    if (n === 0 || n === 2130706433) return true;
  }

  return false;
}

export function sanitizeAddress(rawAddr: string, options?: { allowBlocked?: boolean }): { host: string; port: number } | null {
  if (!rawAddr || typeof rawAddr !== "string") return null;

  let addr = rawAddr.trim();
  if (!addr) return null;

  if (/\s/.test(addr)) return null;

  addr = addr.replace(/^https?:\/\//, "");

  let host: string;
  let port: number | undefined;

  if (addr.startsWith("[")) {
    const close = addr.indexOf("]");
    if (close === -1) return null;
    host = addr.substring(1, close).toLowerCase();
    const rest = addr.substring(close + 1);
    if (rest.startsWith(":")) {
      const p = parseInt(rest.substring(1), 10);
      if (isNaN(p) || p < 1 || p > 65535) return null;
      port = p;
    }
  } else {
    const colonCount = (addr.match(/:/g) || []).length;
    if (colonCount > 1) return null;
    const colonIdx = addr.indexOf(":");
    if (colonIdx !== -1) {
      host = addr.substring(0, colonIdx).toLowerCase();
      const p = parseInt(addr.substring(colonIdx + 1), 10);
      if (isNaN(p) || p < 1 || p > 65535) return null;
      port = p;
    } else {
      host = addr.toLowerCase();
    }
  }

  host = host.split("/")[0].split("?")[0].split("#")[0];

  if (!host) return null;
  if (host.length > 253) return null;

  if (/[`${}'"\\<>]/.test(host)) return null;

  if (!options?.allowBlocked && isBlockedAddress(host)) return null;

  const hostnameRegex = /^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$/;
  const ipv4Regex = /^\d{1,3}(\.\d{1,3}){3}$/;
  const ipv6Regex = /^[0-9a-f:]+$/;

  if (!hostnameRegex.test(host) && !ipv4Regex.test(host) && !ipv6Regex.test(host)) {
    return null;
  }

  if (ipv4Regex.test(host)) {
    const parts = host.split(".").map((p) => parseInt(p, 10));
    if (parts.some((p) => p > 255)) return null;
  }

  return { host, port: port ?? 8080 };
}

export function buildSafeUrl(host: string, port: number, pathSegments: string[]): string {
  const cleanSegments = pathSegments
    .map((seg) => String(seg).replace(/[^a-zA-Z0-9_-]/g, ""))
    .filter((seg) => seg.length > 0);
  const scheme = typeof window !== "undefined" && window.location.protocol === "https:" ? "https" : "http";
  return `${scheme}://${host}:${port}/${cleanSegments.join("/")}`;
}

export function buildRemoteWorksUrl(host: string, port: number): string {
  return buildSafeUrl(host, port, ["api", "public", "works"]);
}

export function buildRemoteWorkUrl(host: string, port: number, workId: string): string {
  const safeId = String(workId).replace(/[^a-zA-Z0-9_-]/g, "");
  if (!safeId) return "";
  const scheme = typeof window !== "undefined" && window.location.protocol === "https:" ? "https" : "http";
  return `${scheme}://${host}:${port}/api/public/work/${safeId}`;
}

export function sanitizeRemoteText(text: unknown): string {
  if (typeof text !== "string") return "";
  const truncated = text.slice(0, MAX_REMOTE_TEXT_CHARS);
  return truncated;
}

export function sanitizeRemoteTitle(title: unknown): string {
  if (typeof title !== "string") return "";
  const cleaned = title.replace(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/g, "").trim();
  return cleaned.slice(0, MAX_REMOTE_TITLE_CHARS);
}

const DANGEROUS_PROTOCOLS = /^(javascript|data|vbscript|file|about):/i;

export function sanitizeHref(href: string): string {
  if (!href || typeof href !== "string") return "";
  const trimmed = href.trim();
  if (DANGEROUS_PROTOCOLS.test(trimmed)) return "";
  if (trimmed.startsWith("#")) return trimmed;
  if (/^https?:\/\//i.test(trimmed)) {
    const url = (() => {
      try {
        return new URL(trimmed);
      } catch {
        return null;
      }
    })();
    if (!url) return "";
    if (isBlockedAddress(url.hostname)) return "";
    return url.toString();
  }
  return "";
}

export interface RemoteWork {
  work_id: string;
  title: string;
  revision: number;
  char_count: number;
}

export function validateRemoteWorksResponse(data: unknown): RemoteWork[] {
  if (!data || typeof data !== "object") return [];
  const obj = data as Record<string, unknown>;
  const works = obj.works;
  if (!Array.isArray(works)) return [];

  const result: RemoteWork[] = [];
  for (const w of works.slice(0, MAX_REMOTE_WORKS_COUNT)) {
    if (!w || typeof w !== "object") continue;
    const item = w as Record<string, unknown>;
    const workId = String(item.work_id ?? "").trim();
    if (!workId || workId.length > 200) continue;
    if (!/^[a-zA-Z0-9_-]+$/.test(workId)) continue;
    result.push({
      work_id: workId,
      title: sanitizeRemoteTitle(item.title),
      revision: typeof item.revision === "number" ? item.revision : 0,
      char_count: typeof item.char_count === "number" ? item.char_count : 0,
    });
  }
  return result;
}

export function validateRemoteWorkResponse(data: unknown): { text: string; title: string } | null {
  if (!data || typeof data !== "object") return null;
  const obj = data as Record<string, unknown>;
  const text = sanitizeRemoteText(obj.text);
  const title = sanitizeRemoteTitle(obj.title);
  if (!text && !title) return null;
  return { text, title };
}
