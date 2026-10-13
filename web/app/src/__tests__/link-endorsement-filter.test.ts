import { describe, it, expect } from "vitest";
import {
  vouchersOf,
  hasVouch,
  endorserOptions,
  passesEndorserFilter,
  applyEndorserFilter,
  type EndorseableLink,
} from "../link-endorsement-filter";

function mkLink(overrides: Partial<EndorseableLink> = {}): EndorseableLink {
  return {
    endorsements: [],
    endorsement_count: 0,
    link_contested: false,
    ...overrides,
  };
}

const authorEndorsement = { club_id: 1, kind: "author", timestamp: 100 };
const vouch = (club_id: number, name?: string) => ({
  club_id,
  name: name ?? null,
  kind: "vouch",
  timestamp: 200,
});

describe("FR-87 §16.12 — endorser filter helpers", () => {
  describe("vouchersOf", () => {
    it("excludes the author's auto-endorsement (provenance, not reputation)", () => {
      const link = mkLink({ endorsements: [authorEndorsement, vouch(7, "Reviewer")] });
      const vouchers = vouchersOf(link);
      expect(vouchers).toHaveLength(1);
      expect(vouchers[0].club_id).toBe(7);
    });

    it("returns empty for author-only links", () => {
      expect(vouchersOf(mkLink({ endorsements: [authorEndorsement] }))).toHaveLength(0);
    });
  });

  describe("hasVouch", () => {
    it("true when a third-party vouch is present", () => {
      expect(hasVouch(mkLink({ endorsements: [authorEndorsement, vouch(7)] }))).toBe(true);
    });

    it("false when only the author endorsed", () => {
      expect(hasVouch(mkLink({ endorsements: [authorEndorsement] }))).toBe(false);
    });

    it("false for an empty trust chain", () => {
      expect(hasVouch(mkLink())).toBe(false);
    });

    it("falls back to endorsement_count when the named list is absent", () => {
      // count = author + n vouches → 2+ means a third-party vouch
      expect(hasVouch(mkLink({ endorsement_count: 2 }))).toBe(true);
      expect(hasVouch(mkLink({ endorsement_count: 1 }))).toBe(false);
      expect(hasVouch(mkLink({}))).toBe(false);
    });
  });

  describe("endorserOptions", () => {
    it("collects distinct endorsers with per-link counts", () => {
      const links = [
        mkLink({ endorsements: [authorEndorsement, vouch(7, "Reviewer"), vouch(8, "Curator")] }),
        mkLink({ endorsements: [authorEndorsement, vouch(7, "Reviewer")] }),
      ];
      const opts = endorserOptions(links);
      expect(opts.map((o) => o.club_id)).toEqual([7, 8]);
      expect(opts[0].count).toBe(2);
      expect(opts[1].count).toBe(1);
    });

    it("counts an endorser once per link even with duplicate entries", () => {
      const links = [mkLink({ endorsements: [vouch(7), vouch(7)] })];
      expect(endorserOptions(links)[0].count).toBe(1);
    });

    it("sorts by vouch count descending, named-first within ties", () => {
      const links = [
        mkLink({ endorsements: [vouch(1, null), vouch(2, "Named")] }),
        mkLink({ endorsements: [vouch(2, "Named")] }),
      ];
      const opts = endorserOptions(links);
      expect(opts[0].club_id).toBe(2); // 2 vouches
      expect(opts[1].club_id).toBe(1); // unnamed, fewer
    });

    it("backfills a name learned from a later link", () => {
      const links = [
        mkLink({ endorsements: [vouch(9)] }),
        mkLink({ endorsements: [vouch(9, "Late Name")] }),
      ];
      expect(endorserOptions(links)[0].name).toBe("Late Name");
    });
  });

  describe("passesEndorserFilter", () => {
    const link = mkLink({
      endorsements: [authorEndorsement, vouch(7, "Reviewer")],
    });

    it('"any" passes everything', () => {
      expect(passesEndorserFilter(link, "any")).toBe(true);
      expect(passesEndorserFilter(mkLink(), "any")).toBe(true);
    });

    it('"vouched" requires a third-party vouch', () => {
      expect(passesEndorserFilter(link, "vouched")).toBe(true);
      expect(
        passesEndorserFilter(mkLink({ endorsements: [authorEndorsement] }), "vouched"),
      ).toBe(false);
    });

    it("a club id matches only that endorser's vouches", () => {
      expect(passesEndorserFilter(link, 7)).toBe(true);
      expect(passesEndorserFilter(link, 8)).toBe(false);
    });

    it("the author's club id is not a vouch match", () => {
      expect(passesEndorserFilter(link, 1)).toBe(false);
    });
  });

  describe("applyEndorserFilter", () => {
    it("intersects at the call site with whatever else filters the list", () => {
      const links = [
        mkLink({ endorsements: [vouch(7)] }),
        mkLink({ endorsements: [authorEndorsement] }),
        mkLink({ endorsements: [vouch(8)] }),
      ];
      expect(applyEndorserFilter(links, "any")).toHaveLength(3);
      expect(applyEndorserFilter(links, "vouched")).toHaveLength(2);
      expect(applyEndorserFilter(links, 7)).toHaveLength(1);
    });

    it("returns the same element type (callers keep their fields)", () => {
      const links = [{ ...mkLink({ endorsements: [vouch(7)] }), link_id: 42 }];
      const out = applyEndorserFilter(links, 7);
      expect(out[0].link_id).toBe(42);
    });
  });
});
