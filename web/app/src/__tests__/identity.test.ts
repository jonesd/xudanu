import { describe, it, expect } from "vitest";
import { validatePassword, passwordStrength } from "../components/IdentityPanel";

describe("validatePassword", () => {
  it("rejects short passwords", () => {
    expect(validatePassword("Ab1")).not.toBeNull();
    expect(validatePassword("Ab1")).toContain("10 characters");
  });

  it("requires at least 10 characters", () => {
    expect(validatePassword("Abcdefg9")).not.toBeNull();
    expect(validatePassword("Abcdefghi9")).toBeNull();
  });

  it("requires an uppercase letter", () => {
    expect(validatePassword("abcdefghi9")).not.toBeNull();
    expect(validatePassword("abcdefghi9")).toContain("uppercase");
  });

  it("requires a lowercase letter", () => {
    expect(validatePassword("ABCDEFGHI9")).not.toBeNull();
    expect(validatePassword("ABCDEFGHI9")).toContain("lowercase");
  });

  it("requires a digit", () => {
    expect(validatePassword("Abcdefghij")).not.toBeNull();
    expect(validatePassword("Abcdefghij")).toContain("digit");
  });

  it("accepts a valid password", () => {
    expect(validatePassword("Hello12345")).toBeNull();
    expect(validatePassword("MyP@ssw0rd!")).toBeNull();
  });

  it("rejects empty string", () => {
    const err = validatePassword("");
    expect(err).not.toBeNull();
    expect(err).toContain("10 characters");
  });
});

describe("passwordStrength", () => {
  it("returns empty label for empty password", () => {
    const s = passwordStrength("");
    expect(s.score).toBe(0);
    expect(s.label).toBe("");
  });

  it("returns Weak for short simple passwords", () => {
    const s = passwordStrength("abc");
    expect(s.label).toBe("Weak");
    expect(s.score).toBeLessThanOrEqual(1);
  });

  it("returns Fair for medium passwords", () => {
    const s = passwordStrength("Hello12345");
    expect(s.label).toBe("Fair");
    expect(s.score).toBeGreaterThan(1);
    expect(s.score).toBeLessThanOrEqual(3);
  });

  it("returns Strong for complex passwords", () => {
    const s = passwordStrength("MyV3ryStr0ng!Pass");
    expect(s.label).toBe("Strong");
    expect(s.score).toBeGreaterThanOrEqual(4);
  });

  it("score includes length bonus for >=16 chars", () => {
    const shortPw = passwordStrength("Hello12345");
    const longPw = passwordStrength("Hello12345Extra!");
    expect(longPw.score).toBeGreaterThan(shortPw.score);
  });

  it("score includes special character bonus", () => {
    const without = passwordStrength("Hello12345");
    const withSpecial = passwordStrength("Hello12345!");
    expect(withSpecial.score).toBeGreaterThanOrEqual(without.score);
  });
});
