import { describe, it, expect, beforeEach } from "vitest";
import { CrdtSyncClient } from "../api/crdt_sync";

function mkClient() {
  const client = new CrdtSyncClient("ws://test", 1);
  const requests: Array<{ op: string; payload: unknown }> = [];
  client.sendRequest = async (op: string, payload: unknown) => {
    requests.push({ op, payload });
    if (op === "link_create") return { value: { value: 0x77 } };
    if (op === "link_query") return { type: "response", value: [{ link_id: 1 }] };
    return { value: { value: null } };
  };
  return { client, requests };
}

describe("CrdtSyncClient FR-40 methods", () => {
  let harness: ReturnType<typeof mkClient>;
  beforeEach(() => {
    harness = mkClient();
  });

  it("linkAddEnd sends named end with HyperRefPayload shape", async () => {
    await harness.client.linkAddEnd(5, "Comparison3", {
      workContext: 0x30,
      excerpt: "shared passage",
      start: 3,
      end: 17,
    });
    const req = harness.requests[0];
    expect(req.op).toBe("link_add_end");
    expect(req.payload).toEqual({
      link_id: 5,
      end_name: "Comparison3",
      end_ref: {
        kind: "single",
        work_context: 0x30,
        original_context: null,
        path_context: null,
        excerpt: "shared passage",
        start_position: 3,
        end_position: 17,
      },
    });
  });

  it("linkRemoveEnd sends link_id and end_name", async () => {
    await harness.client.linkRemoveEnd(5, "Comparison3");
    expect(harness.requests[0]).toEqual({
      op: "link_remove_end",
      payload: { link_id: 5, end_name: "Comparison3" },
    });
  });

  it("linkQuery defaults empty specs and returns entries", async () => {
    const res = await harness.client.linkQuery({ type_ids: [4] });
    expect(res).toEqual([{ link_id: 1 }]);
    expect(harness.requests[0].payload).toEqual({
      from_spec: {},
      to_spec: {},
      type_ids: [4],
      home_spec: {},
    });
  });

  it("linkQuery passes through work specs", async () => {
    await harness.client.linkQuery({
      from_spec: { work_ids: [1, 2] },
      to_spec: { author: 7 },
    });
    expect(harness.requests[0].payload).toMatchObject({
      from_spec: { work_ids: [1, 2] },
      to_spec: { author: 7 },
    });
  });

  it("registerLinkType sends type_id, name, definition_work", async () => {
    await harness.client.registerLinkType(0x99, "Certification", 0x99);
    expect(harness.requests[0]).toEqual({
      op: "link_type_register",
      payload: { type_id: 0x99, name: "Certification", definition_work: 0x99 },
    });
  });

  it("linkCreate passes home_document when given, omits when not", async () => {
    await harness.client.linkCreate(1, 2);
    expect(harness.requests[0].payload).not.toHaveProperty("home_document");
    await harness.client.linkCreate(1, 2, undefined, undefined, 3);
    expect(harness.requests[1].payload).toHaveProperty("home_document", 3);
  });
});
