import { ClassicClient } from "./client";

/** Phase D editing adapter. The UI speaks only to this interface,
 *  so a CRDT-backed implementation can replace grab/revise later
 *  without touching the views. */
export interface WorkEditor {
  /** Acquire the right to edit (grab the work). Rejects with
   *  code "not_grabbed"/"grab_failed" style WireError when held. */
  begin(workId: number): Promise<void>;
  /** Persist `text` as a new edition and relinquish the hold. */
  commit(workId: number, text: string): Promise<void>;
  /** Abandon the edit and relinquish the hold. */
  cancel(workId: number): Promise<void>;
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
