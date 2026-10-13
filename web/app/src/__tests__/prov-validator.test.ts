import { describe, it, expect } from "vitest";
import { JSDOM } from "jsdom";
import { buildProvValidatorHtml } from "../prov-validator";

/**
 * The forensic core: the validator page runs entirely client-side.
 * We boot the generated page in its own JSDOM (scripts enabled) and
 * drive the page's own doVal() with crafted PROV-JSON documents —
 * every validation branch, the same environment users get.
 */

function bootPage(): JSDOM {
  return new JSDOM(buildProvValidatorHtml("{}"), { runScripts: "dangerously" });
}

function validate(dom: JSDOM, docJson: string): { ok: boolean; errors: string[] } {
  const d = dom.window.document;
  (d.getElementById("output") as HTMLTextAreaElement).value = docJson;
  dom.window.eval("doVal()");
  const results = d.getElementById("results")!;
  const badge = d.getElementById("badge")!;
  const ok = results.className.includes("ok");
  return {
    ok,
    errors: ok ? [] : Array.from(results.querySelectorAll("li")).map((li) => li.textContent || ""),
    badge: badge.textContent || "",
  } as { ok: boolean; errors: string[] };
}

describe("buildProvValidatorHtml — page structure", () => {
  it("embeds the PROV-JSON payload JSON-escaped with the W3C schema", () => {
    const html = buildProvValidatorHtml('{"entity":{"e1":{"$":"a\\"b","type":"string"}}}');
    expect(html).toContain("PROV-JSON Validator");
    expect(html).toContain("var OUTPUT_JSON = ");
    expect(html).toContain("openprovenance.org/prov-json/schema#");
    expect(html).toContain("Runs entirely in your browser");
  });

  it("the page self-validates the embedded payload on load", async () => {
    const dom = new JSDOM(buildProvValidatorHtml('{"entity":{}}'), { runScripts: "dangerously" });
    await new Promise((r) => setTimeout(r, 200)); // window.onload's 100ms
    expect(dom.window.document.getElementById("results")!.className).toContain("ok");
  });
});

describe("the embedded validator — forensic branches", () => {
  it("accepts a complete, well-formed document", () => {
    const r = validate(bootPage(), JSON.stringify({
      prefix: {},
      entity: { doc: { "prov:value": "hello" } },
      agent: { author: { "prov:name": { $: "reader", lang: "en" } } },
      activity: { edit: { "prov:startTime": "2026-10-05T10:00:00Z", "prov:endTime": "2026-10-05T11:00:00Z" } },
      wasGeneratedBy: { g1: { "prov:entity": "doc", "prov:activity": "edit", "prov:time": "2026-10-05T11:00:00Z" } },
      used: { u1: { "prov:activity": "edit", "prov:entity": "doc" } },
      wasAttributedTo: { a1: { "prov:entity": "doc", "prov:agent": "author" } },
      wasAssociatedWith: { w1: { "prov:activity": "edit", "prov:agent": "author" } },
      wasDerivedFrom: { d1: { "prov:generatedEntity": "doc", "prov:usedEntity": "doc" } },
    }));
    expect(r.ok).toBe(true);
    expect(r.errors).toEqual([]);
  });

  it("rejects invalid JSON outright", () => {
    const r = validate(bootPage(), "{not json");
    expect(r.ok).toBe(false);
    expect(r.errors.some((e) => e.includes("JSON parse error"))).toBe(true);
  });

  it("rejects a non-object root", () => {
    const r = validate(bootPage(), "[1,2,3]");
    expect(r.errors.some((e) => e.includes("root must be object"))).toBe(true);
  });

  it("flags non-object entities and agents", () => {
    const r = validate(bootPage(), JSON.stringify({ entity: { bad: "scalar" }, agent: { also: null } }));
    expect(r.errors.some((e) => e.includes("entity.bad: must be object"))).toBe(true);
    expect(r.errors.some((e) => e.includes("agent.also: must be object"))).toBe(true);
  });

  it("flags non-string activity times but accepts string ones", () => {
    const bad = validate(bootPage(), JSON.stringify({ activity: { a1: { "prov:startTime": 42 } } }));
    expect(bad.errors.some((e) => e.includes("startTime: must be string"))).toBe(true);
    const good = validate(bootPage(), JSON.stringify({ activity: { a1: { "prov:startTime": "t", "prov:endTime": "t2" } } }));
    expect(good.ok).toBe(true);
  });

  it("flags missing and mistyped required relation fields across all five relations", () => {
    const r = validate(bootPage(), JSON.stringify({
      wasGeneratedBy: { g1: {} },
      used: { u1: {} },
      wasAttributedTo: { a1: { "prov:entity": "e" } },
      wasDerivedFrom: { d1: {} },
      wasAssociatedWith: { w1: { "prov:activity": 9 } },
    }));
    expect(r.errors.some((e) => e.includes('g1: missing "prov:entity"'))).toBe(true);
    expect(r.errors.some((e) => e.includes('u1: missing "prov:activity"'))).toBe(true);
    expect(r.errors.some((e) => e.includes('a1: missing "prov:agent"'))).toBe(true);
    expect(r.errors.some((e) => e.includes('d1: missing "prov:generatedEntity"'))).toBe(true);
    expect(r.errors.some((e) => e.includes('d1: missing "prov:usedEntity"'))).toBe(true);
    expect(r.errors.some((e) => e.includes("prov:activity: must be string"))).toBe(true);
  });

  it("literal validation: attribute literals missing $, missing type/lang, unexpected keys, arrays", () => {
    // Entity ATTRIBUTES are literals: malformed shapes must be
    // attribute VALUES (entity -> attr -> literal), not entities.
    const r = validate(bootPage(), JSON.stringify({
      entity: {
        e1: { noDollar: { type: "string" } },
        e2: { noType: { $: 5 } },
        e3: { extra: { $: 1, type: "int", bogus: true } },
        e4: { arr: [null, "ok", { $: 1, type: "int" }] },
      },
    }));
    expect(r.errors.some((e) => e.includes('noDollar: literal needs "$"'))).toBe(true);
    expect(r.errors.some((e) => e.includes('noType: literal needs "type" or "lang"'))).toBe(true);
    expect(r.errors.some((e) => e.includes('extra: unexpected "bogus"'))).toBe(true);
    expect(r.errors.some((e) => e.includes("arr[0]: must not be null"))).toBe(true);
    expect(r.errors.some((e) => e.includes("arr[1]"))).toBe(false); // plain string is fine
  });

  it("typed and internationalized literals both validate", () => {
    const r = validate(bootPage(), JSON.stringify({
      entity: { e1: { v: { $: 3, type: "int" } } },
      agent: { a1: { n: { $: "nom", lang: "fr" } } },
    }));
    expect(r.ok).toBe(true);
  });

  it("the bundle key must be an object when present", () => {
    const r = validate(bootPage(), JSON.stringify({ bundle: [1] }));
    expect(r.errors.some((e) => e.includes(".bundle: must be object"))).toBe(true);
    const okBundle = validate(bootPage(), JSON.stringify({ bundle: { b1: { entity: {} } } }));
    expect(okBundle.ok).toBe(true);
  });

  it("scalar and boolean literal values pass without wrappers", () => {
    const r = validate(bootPage(), JSON.stringify({ entity: { e: { n: 5, s: "x", b: true, arr: [1, "two", false] } } }));
    expect(r.ok).toBe(true);
  });
});
