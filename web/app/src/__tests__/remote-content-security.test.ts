import { describe, it, expect } from "vitest";
import {
  isPrivateIp,
  isBlockedAddress,
  sanitizeAddress,
  buildRemoteWorksUrl,
  buildRemoteWorkUrl,
  sanitizeRemoteText,
  sanitizeRemoteTitle,
  sanitizeHref,
  validateRemoteWorksResponse,
  validateRemoteWorkResponse,
  MAX_REMOTE_TEXT_CHARS,
  MAX_REMOTE_TITLE_CHARS,
} from "../security/remote-content";

describe("isPrivateIp", () => {
  it("blocks 127.x.x.x loopback", () => {
    expect(isPrivateIp("127.0.0.1")).toBe(true);
    expect(isPrivateIp("127.255.255.255")).toBe(true);
  });

  it("blocks 10.x.x.x private", () => {
    expect(isPrivateIp("10.0.0.1")).toBe(true);
    expect(isPrivateIp("10.255.255.255")).toBe(true);
  });

  it("blocks 172.16-31.x.x private", () => {
    expect(isPrivateIp("172.16.0.1")).toBe(true);
    expect(isPrivateIp("172.31.255.255")).toBe(true);
  });

  it("allows 172.15.x.x (public)", () => {
    expect(isPrivateIp("172.15.0.1")).toBe(false);
  });

  it("allows 172.32.x.x (public)", () => {
    expect(isPrivateIp("172.32.0.1")).toBe(false);
  });

  it("blocks 192.168.x.x private", () => {
    expect(isPrivateIp("192.168.1.1")).toBe(true);
    expect(isPrivateIp("192.168.0.0")).toBe(true);
  });

  it("blocks 169.254.x.x link-local", () => {
    expect(isPrivateIp("169.254.1.1")).toBe(true);
  });

  it("blocks 0.x.x.x", () => {
    expect(isPrivateIp("0.0.0.0")).toBe(true);
    expect(isPrivateIp("0.1.2.3")).toBe(true);
  });

  it("blocks IPv6 loopback", () => {
    expect(isPrivateIp("::1")).toBe(true);
    expect(isPrivateIp("[::1]")).toBe(true);
  });

  it("blocks IPv6 unspecified", () => {
    expect(isPrivateIp("::")).toBe(true);
  });

  it("blocks IPv6 ULA fc00::/7", () => {
    expect(isPrivateIp("fc00::1")).toBe(true);
    expect(isPrivateIp("fd00::1")).toBe(true);
  });

  it("blocks IPv6 link-local fe80::/10", () => {
    expect(isPrivateIp("fe80::1")).toBe(true);
  });

  it("allows public IPs", () => {
    expect(isPrivateIp("8.8.8.8")).toBe(false);
    expect(isPrivateIp("1.1.1.1")).toBe(false);
    expect(isPrivateIp("93.184.216.34")).toBe(false);
  });

  it("blocks CGNAT 100.64.0.0/10", () => {
    expect(isPrivateIp("100.64.0.1")).toBe(true);
    expect(isPrivateIp("100.127.255.255")).toBe(true);
  });

  it("allows 100.63.x.x (public)", () => {
    expect(isPrivateIp("100.63.255.255")).toBe(false);
  });

  it("allows 100.128.x.x (public)", () => {
    expect(isPrivateIp("100.128.0.1")).toBe(false);
  });
});

describe("isBlockedAddress", () => {
  it("blocks localhost", () => {
    expect(isBlockedAddress("localhost")).toBe(true);
    expect(isBlockedAddress("LOCALHOST")).toBe(true);
  });

  it("blocks 127.0.0.1 with port", () => {
    expect(isBlockedAddress("127.0.0.1:8080")).toBe(true);
  });

  it("blocks with http prefix", () => {
    expect(isBlockedAddress("http://127.0.0.1:8080")).toBe(true);
    expect(isBlockedAddress("https://localhost")).toBe(true);
  });

  it("blocks metadata endpoints", () => {
    expect(isBlockedAddress("metadata.google.internal")).toBe(true);
  });

  it("blocks 169.254.169.254 (AWS metadata)", () => {
    expect(isBlockedAddress("169.254.169.254")).toBe(true);
  });

  it("blocks IPv6 loopback", () => {
    expect(isBlockedAddress("::1")).toBe(true);
    expect(isBlockedAddress("[::1]")).toBe(true);
  });

  it("allows public domains", () => {
    expect(isBlockedAddress("example.com")).toBe(false);
    expect(isBlockedAddress("alice.example.com:8081")).toBe(false);
  });

  it("allows public IPs", () => {
    expect(isBlockedAddress("93.184.216.34")).toBe(false);
  });

  it("blocks hex-encoded IPs", () => {
    expect(isBlockedAddress("0x7f000001")).toBe(true);
    expect(isBlockedAddress("0x0a000001")).toBe(true);
  });

  it("blocks decimal-encoded IPs", () => {
    expect(isBlockedAddress("2130706433")).toBe(true);
    expect(isBlockedAddress("0")).toBe(true);
  });
});

describe("sanitizeAddress", () => {
  it("parses simple hostname", () => {
    expect(sanitizeAddress("alice.example.com")).toEqual({ host: "alice.example.com", port: 8080 });
  });

  it("parses hostname with port", () => {
    expect(sanitizeAddress("alice.example.com:9090")).toEqual({ host: "alice.example.com", port: 9090 });
  });

  it("strips http:// prefix", () => {
    expect(sanitizeAddress("http://alice.example.com:9090")).toEqual({ host: "alice.example.com", port: 9090 });
  });

  it("strips https:// prefix", () => {
    expect(sanitizeAddress("https://alice.example.com")).toEqual({ host: "alice.example.com", port: 8080 });
  });

  it("defaults port to 8080", () => {
    expect(sanitizeAddress("example.com")?.port).toBe(8080);
  });

  it("lowercases host", () => {
    expect(sanitizeAddress("ALICE.EXAMPLE.COM")?.host).toBe("alice.example.com");
  });

  it("rejects empty string", () => {
    expect(sanitizeAddress("")).toBeNull();
  });

  it("rejects whitespace-only", () => {
    expect(sanitizeAddress("   ")).toBeNull();
  });

  it("rejects localhost", () => {
    expect(sanitizeAddress("localhost")).toBeNull();
    expect(sanitizeAddress("localhost:8080")).toBeNull();
  });

  it("rejects 127.0.0.1", () => {
    expect(sanitizeAddress("127.0.0.1")).toBeNull();
    expect(sanitizeAddress("127.0.0.1:8080")).toBeNull();
  });

  it("rejects 10.x.x.x", () => {
    expect(sanitizeAddress("10.0.0.1")).toBeNull();
  });

  it("rejects 192.168.x.x", () => {
    expect(sanitizeAddress("192.168.1.1")).toBeNull();
  });

  it("rejects 0.0.0.0", () => {
    expect(sanitizeAddress("0.0.0.0")).toBeNull();
  });

  it("rejects ::1", () => {
    expect(sanitizeAddress("::1")).toBeNull();
  });

  it("rejects spaces in address", () => {
    expect(sanitizeAddress("alice example.com")).toBeNull();
  });

  it("rejects backtick in host", () => {
    expect(sanitizeAddress("alice`example.com")).toBeNull();
  });

  it("rejects dollar sign in host", () => {
    expect(sanitizeAddress("alice$example.com")).toBeNull();
  });

  it("rejects angle brackets in host", () => {
    expect(sanitizeAddress("alice<example.com")).toBeNull();
    expect(sanitizeAddress("alice>example.com")).toBeNull();
  });

  it("rejects invalid port (zero)", () => {
    expect(sanitizeAddress("example.com:0")).toBeNull();
  });

  it("rejects invalid port (negative)", () => {
    expect(sanitizeAddress("example.com:-1")).toBeNull();
  });

  it("rejects invalid port (>65535)", () => {
    expect(sanitizeAddress("example.com:99999")).toBeNull();
  });

  it("rejects non-numeric port", () => {
    expect(sanitizeAddress("example.com:abc")).toBeNull();
  });

  it("rejects multiple colons (non-IPv6)", () => {
    expect(sanitizeAddress("example.com:80:80")).toBeNull();
  });

  it("rejects overly long hostname", () => {
    expect(sanitizeAddress("a".repeat(254) + ".com")).toBeNull();
  });

  it("strips trailing slash and path", () => {
    expect(sanitizeAddress("example.com/path")?.host).toBe("example.com");
  });

  it("strips query string", () => {
    expect(sanitizeAddress("example.com?x=1")?.host).toBe("example.com");
  });

  it("strips fragment", () => {
    expect(sanitizeAddress("example.com#frag")?.host).toBe("example.com");
  });

  it("accepts valid multi-level domain", () => {
    expect(sanitizeAddress("a.b.c.example.com")?.host).toBe("a.b.c.example.com");
  });

  it("rejects hostname starting with hyphen", () => {
    expect(sanitizeAddress("-example.com")).toBeNull();
  });

  it("rejects hostname ending with hyphen", () => {
    expect(sanitizeAddress("example-.com")).toBeNull();
  });

  it("rejects IPv4 octet > 255", () => {
    expect(sanitizeAddress("1.2.3.999")).toBeNull();
  });

  it("accepts IPv6 address in brackets with port", () => {
    const result = sanitizeAddress("[2001:db8::1]:8080");
    expect(result?.port).toBe(8080);
    expect(result?.host).toContain("2001:db8::1");
  });

  it("rejects AWS metadata endpoint", () => {
    expect(sanitizeAddress("169.254.169.254")).toBeNull();
  });

  it("rejects Google cloud metadata endpoint", () => {
    expect(sanitizeAddress("metadata.google.internal")).toBeNull();
  });

  it("rejects hex-encoded loopback", () => {
    expect(sanitizeAddress("0x7f000001")).toBeNull();
  });

  it("rejects decimal-encoded loopback", () => {
    expect(sanitizeAddress("2130706433")).toBeNull();
  });
});

describe("buildRemoteWorksUrl", () => {
  it("builds correct URL", () => {
    expect(buildRemoteWorksUrl("alice.example.com", 8081)).toBe(
      "http://alice.example.com:8081/api/public/works",
    );
  });
});

describe("buildRemoteWorkUrl", () => {
  it("builds correct URL for numeric work ID", () => {
    expect(buildRemoteWorkUrl("alice.example.com", 8081, "42")).toBe(
      "http://alice.example.com:8081/api/public/work/42",
    );
  });

  it("builds correct URL for hex work ID", () => {
    expect(buildRemoteWorkUrl("alice.example.com", 8081, "aabbccdd")).toBe(
      "http://alice.example.com:8081/api/public/work/aabbccdd",
    );
  });

  it("strips slashes from work ID (path traversal prevention)", () => {
    const url = buildRemoteWorkUrl("alice.example.com", 8081, "../../etc/passwd");
    expect(url).not.toContain("..");
    expect(url).not.toContain("//etc");
    expect(url).not.toContain("/etc/");
    expect(url).not.toContain("/passwd");
    expect(url).toMatch(/^http:\/\/alice\.example\.com:8081\/api\/public\/work\//);
  });

  it("strips special characters from work ID", () => {
    const url = buildRemoteWorkUrl("alice.example.com", 8081, "test<script>alert(1)</script>");
    expect(url).not.toContain("<");
    expect(url).not.toContain(">");
    expect(url).not.toContain("(");
    expect(url).not.toContain(")");
  });

  it("returns empty for work ID that is only special chars", () => {
    expect(buildRemoteWorkUrl("alice.example.com", 8081, "../../")).toBe("");
    expect(buildRemoteWorkUrl("alice.example.com", 8081, "<>")).toBe("");
  });
});

describe("sanitizeRemoteText", () => {
  it("returns string as-is (React handles escaping)", () => {
    expect(sanitizeRemoteText("Hello world")).toBe("Hello world");
  });

  it("preserves HTML-like content as text", () => {
    const result = sanitizeRemoteText("<script>alert(1)</script>");
    expect(result).toBe("<script>alert(1)</script>");
  });

  it("truncates at MAX_REMOTE_TEXT_CHARS", () => {
    const long = "A".repeat(MAX_REMOTE_TEXT_CHARS + 1000);
    const result = sanitizeRemoteText(long);
    expect(result.length).toBe(MAX_REMOTE_TEXT_CHARS);
  });

  it("returns empty for non-string", () => {
    expect(sanitizeRemoteText(null)).toBe("");
    expect(sanitizeRemoteText(undefined)).toBe("");
    expect(sanitizeRemoteText(123)).toBe("");
    expect(sanitizeRemoteText({})).toBe("");
    expect(sanitizeRemoteText([])).toBe("");
  });
});

describe("sanitizeRemoteTitle", () => {
  it("returns clean title", () => {
    expect(sanitizeRemoteTitle("My Document")).toBe("My Document");
  });

  it("strips control characters", () => {
    expect(sanitizeRemoteTitle("Hello\x00World")).toBe("HelloWorld");
    expect(sanitizeRemoteTitle("Test\x07Bell")).toBe("TestBell");
    expect(sanitizeRemoteTitle("Tab\tHere")).toBe("Tab\tHere");
  });

  it("strips DEL character", () => {
    expect(sanitizeRemoteTitle("Hi\x7f")).toBe("Hi");
  });

  it("truncates at MAX_REMOTE_TITLE_CHARS", () => {
    const long = "A".repeat(MAX_REMOTE_TITLE_CHARS + 100);
    expect(sanitizeRemoteTitle(long).length).toBe(MAX_REMOTE_TITLE_CHARS);
  });

  it("returns empty for non-string", () => {
    expect(sanitizeRemoteTitle(null)).toBe("");
    expect(sanitizeRemoteTitle(42)).toBe("");
  });

  it("trims whitespace", () => {
    expect(sanitizeRemoteTitle("  Hello  ")).toBe("Hello");
  });
});

describe("sanitizeHref", () => {
  it("allows https URLs", () => {
    expect(sanitizeHref("https://example.com")).toBe("https://example.com/");
  });

  it("allows http URLs", () => {
    expect(sanitizeHref("http://example.com")).toBe("http://example.com/");
  });

  it("allows fragment links", () => {
    expect(sanitizeHref("#section")).toBe("#section");
  });

  it("blocks javascript: protocol", () => {
    expect(sanitizeHref("javascript:alert(1)")).toBe("");
    expect(sanitizeHref("JavaScript:alert(1)")).toBe("");
    expect(sanitizeHref("  javascript:alert(1)  ")).toBe("");
  });

  it("blocks data: protocol", () => {
    expect(sanitizeHref("data:text/html,<script>alert(1)</script>")).toBe("");
  });

  it("blocks vbscript: protocol", () => {
    expect(sanitizeHref("vbscript:msgbox(1)")).toBe("");
  });

  it("blocks file: protocol", () => {
    expect(sanitizeHref("file:///etc/passwd")).toBe("");
  });

  it("blocks about: protocol", () => {
    expect(sanitizeHref("about:blank")).toBe("");
  });

  it("blocks localhost URLs", () => {
    expect(sanitizeHref("http://localhost:8080/admin")).toBe("");
  });

  it("blocks private IP URLs", () => {
    expect(sanitizeHref("http://192.168.1.1/admin")).toBe("");
    expect(sanitizeHref("http://10.0.0.1/")).toBe("");
  });

  it("blocks malformed URLs", () => {
    expect(sanitizeHref("not a url")).toBe("");
    expect(sanitizeHref("")).toBe("");
  });
});

describe("validateRemoteWorksResponse", () => {
  it("validates well-formed response", () => {
    const data = {
      works: [
        { work_id: "1", title: "Doc 1", revision: 3, char_count: 100 },
        { work_id: "2", title: "Doc 2", revision: 1, char_count: 50 },
      ],
    };
    const result = validateRemoteWorksResponse(data);
    expect(result).toHaveLength(2);
    expect(result[0]).toEqual({ work_id: "1", title: "Doc 1", revision: 3, char_count: 100 });
  });

  it("returns empty for null", () => {
    expect(validateRemoteWorksResponse(null)).toEqual([]);
  });

  it("returns empty for non-object", () => {
    expect(validateRemoteWorksResponse("hello")).toEqual([]);
    expect(validateRemoteWorksResponse(42)).toEqual([]);
  });

  it("returns empty when works is not an array", () => {
    expect(validateRemoteWorksResponse({ works: "not array" })).toEqual([]);
    expect(validateRemoteWorksResponse({})).toEqual([]);
  });

  it("skips entries with missing work_id", () => {
    const result = validateRemoteWorksResponse({
      works: [{ work_id: "", title: "Empty ID" }, { title: "No ID" }],
    });
    expect(result).toEqual([]);
  });

  it("skips entries with injection characters in work_id", () => {
    const result = validateRemoteWorksResponse({
      works: [
        { work_id: "1;DROP TABLE", title: "SQLi", revision: 1, char_count: 1 },
        { work_id: "ok", title: "Good", revision: 1, char_count: 1 },
      ],
    });
    expect(result).toHaveLength(1);
    expect(result[0].work_id).toBe("ok");
  });

  it("skips non-object entries in array", () => {
    const result = validateRemoteWorksResponse({
      works: ["string", 42, null, { work_id: "1", title: "Good", revision: 1, char_count: 1 }],
    });
    expect(result).toHaveLength(1);
  });

  it("defaults revision and char_count to 0 if missing", () => {
    const result = validateRemoteWorksResponse({
      works: [{ work_id: "1", title: "Doc" }],
    });
    expect(result[0].revision).toBe(0);
    expect(result[0].char_count).toBe(0);
  });

  it("sanitizes titles", () => {
    const result = validateRemoteWorksResponse({
      works: [{ work_id: "1", title: "Test\x00Bad", revision: 1, char_count: 1 }],
    });
    expect(result[0].title).toBe("TestBad");
  });

  it("limits to MAX_REMOTE_WORKS_COUNT entries", () => {
    const works = Array.from({ length: 1000 }, (_, i) => ({
      work_id: String(i),
      title: `Doc ${i}`,
      revision: 1,
      char_count: 1,
    }));
    const result = validateRemoteWorksResponse({ works });
    expect(result.length).toBeLessThanOrEqual(500);
  });
});

describe("validateRemoteWorkResponse", () => {
  it("validates well-formed response", () => {
    const result = validateRemoteWorkResponse({ text: "Hello", title: "Doc" });
    expect(result).toEqual({ text: "Hello", title: "Doc" });
  });

  it("returns null for null input", () => {
    expect(validateRemoteWorkResponse(null)).toBeNull();
  });

  it("returns null for non-object", () => {
    expect(validateRemoteWorkResponse("hello")).toBeNull();
    expect(validateRemoteWorkResponse(42)).toBeNull();
  });

  it("returns null when both text and title are empty", () => {
    expect(validateRemoteWorkResponse({})).toBeNull();
    expect(validateRemoteWorkResponse({ text: "", title: "" })).toBeNull();
  });

  it("returns result when only text is present", () => {
    const result = validateRemoteWorkResponse({ text: "Some text" });
    expect(result).toEqual({ text: "Some text", title: "" });
  });

  it("returns result when only title is present", () => {
    const result = validateRemoteWorkResponse({ title: "Some title" });
    expect(result).toEqual({ text: "", title: "Some title" });
  });

  it("sanitizes non-string text to empty", () => {
    const result = validateRemoteWorkResponse({ text: 123, title: "Doc" });
    expect(result).toEqual({ text: "", title: "Doc" });
  });

  it("truncates long text", () => {
    const long = "X".repeat(MAX_REMOTE_TEXT_CHARS + 500);
    const result = validateRemoteWorkResponse({ text: long, title: "Doc" });
    expect(result!.text.length).toBe(MAX_REMOTE_TEXT_CHARS);
  });

  it("strips control chars from title", () => {
    const result = validateRemoteWorkResponse({ text: "hi", title: "Test\x07Bell" });
    expect(result!.title).toBe("TestBell");
  });
});
