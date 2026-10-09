import { ClassicClient } from "./client";

/** Phase D editing adapter. The UI speaks only to this interface,
 *  so implementations can be swapped without touching the views. */
export interface WorkEditor {
  /** Acquire the right to edit. Rejects with a WireError when held. */
  begin(workId: number): Promise<void>;
  /** Persist `text` and relinquish the hold. */
  commit(workId: number, text: string): Promise<void>;
  /** Abandon the edit and relinquish the hold. */
  cancel(workId: number): Promise<void>;
}

/** Minimal text delta in the wire's op vocabulary: retain/delete/
 *  insert with a single common-prefix/suffix replacement region —
 *  the same shape the workspace's collaborative editor sends. */
function diffOps(
  oldText: string,
  newText: string,
): Array<{ type: string; count?: number; text?: string }> {
  if (oldText === newText) return [];
  if (oldText.length === 0) {
    return [{ type: "insert", text: newText }];
  }
  let prefix = 0;
  const maxPrefix = Math.min(oldText.length, newText.length);
  while (prefix < maxPrefix && oldText[prefix] === newText[prefix]) prefix++;
  let suffix = 0;
  const maxSuffix = Math.min(oldText.length, newText.length) - prefix;
  while (suffix < maxSuffix && oldText[oldText.length - 1 - suffix] === newText[newText.length - 1 - suffix]) suffix++;
  const deleteLen = oldText.length - prefix - suffix;
  const insertText = newText.slice(prefix, newText.length - suffix);
  const ops: Array<{ type: string; count?: number; text?: string }> = [];
  if (prefix > 0) ops.push({ type: "retain", count: prefix });
  if (deleteLen > 0) ops.push({ type: "delete", count: deleteLen });
  if (insertText.length > 0) ops.push({ type: "insert", text: insertText });
  if (suffix > 0) ops.push({ type: "retain", count: suffix });
  return ops;
}

/** The CRDT-path editor: grabs invisibly on begin, saves through
 *  `work_revise_delta` (so the server migrates link spans and
 *  transclusion anchors with the edit), releases on commit/cancel.
 *  This is the same op flow as the workspace editor, minus the live
 *  subscription — no lock ceremony reaches the user. */
export class CrdtEditor implements WorkEditor {
  private client: ClassicClient;
  private original = new Map<number, string>();

  constructor(client: ClassicClient) {
    this.client = client;
  }

  async begin(workId: number): Promise<void> {
    await this.client.grab(workId);
    try {
      const text = await this.client.readWork(workId);
      this.original.set(workId, text);
    } catch (e) {
      await this.client.release(workId).catch(() => {});
      throw e;
    }
  }

  async commit(workId: number, text: string): Promise<void> {
    const original = this.original.get(workId);
    this.original.delete(workId);
    if (original !== undefined && original !== text) {
      await this.client.reviseDelta(workId, diffOps(original, text));
      await this.client.release(workId).catch(() => {});
    } else if (original === undefined) {
      // No baseline captured (should not happen) — full-edition save.
      await this.client.saveAndRelease(workId, text);
    } else {
      await this.client.release(workId).catch(() => {});
    }
  }

  async cancel(workId: number): Promise<void> {
    this.original.delete(workId);
    await this.client.release(workId).catch(() => {});
  }
}

export class GrabReviseEditor implements WorkEditor {
  private client: ClassicClient;

  constructor(client: ClassicClient) {
    this.client = client;
  }

  async begin(workId: number): Promise<void> {
    await this.client.grab(workId);
  }

  async commit(workId: number, text: string): Promise<void> {
    await this.client.saveAndRelease(workId, text);
  }

  async cancel(workId: number): Promise<void> {
    try {
      await this.client.release(workId);
    } catch {
      /* already released or never grabbed — nothing to hold */
    }
  }
}
