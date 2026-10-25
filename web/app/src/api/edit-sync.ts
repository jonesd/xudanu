import type { TextDeltaOp } from "./text_buffer";
import type { ChangeHighlight, SaveState } from "./protocol";

/** Origin of a visible text transition, for consumers that care
 * (cursor rebase treats all sources identically). */
export type TextDeltaSource = "local" | "remote" | "server";

/**
 * EditSyncEngine — the text/delta/offline sync core, extracted from
 * CrdtSyncClient. Owns: document text state, the one-in-flight delta
 * queue (FR-150), the echo-race guard, offline-first persistence,
 * and reconnect reconciliation (FR-69 S2).
 *
 * The engine NEVER touches WebSocket, offline-cache, or React — the
 * owning client supplies everything through EditSyncHost. That is the
 * seam that makes the offline/reconnect races testable as pure
 * logic, lets both editors share one sync core, and (FR-88) gives
 * the wasm engine a slot to take over delta computation later.
 */
export interface EditSyncHost {
  sendRequest(op: string, payload?: object): Promise<unknown>;
  /** True when the underlying socket is OPEN right now. */
  isSocketOpen(): boolean;
  /** True when the client considers itself connected. */
  isConnected(): boolean;
  getWorkBeId(): number;
  getCacheMeta(): { title: string; starred: boolean };
}

export class EditSyncEngine {
  private readonly host: EditSyncHost;

  private text = "";
  private deltaInFlight = false;
  private pendingServerText: string | null = null;
  /** Echo-race guard: text of the most recent locally-originated
   * delta that has been acked, and when. Server full-text updates
   * arriving shortly after an ack often carry PRE-edit text (the
   * materialization broadcast lags the delta apply); accepting them
   * resurrected deleted text. */
  private lastAckedLocalText: string | null = null;
  private lastAckedAt = 0;
  /** FR-69 S2: true between a user edit (setText) and its server
   * acknowledgement — protects offline-typed text from being
   * clobbered by full-state broadcasts. */
  private hasUnsyncedLocalEdits = false;
  private pushRetryTimer: ReturnType<typeof setTimeout> | null = null;
  private saveState: SaveState = "idle";
  private saveStateTimer: ReturnType<typeof setTimeout> | null = null;
  private recentChanges: ChangeHighlight[] = [];
  private textListeners = new Set<(text: string) => void>();
  private editCommitListeners = new Set<(info: { inserted: number; deleted: number; net: number; total: number }) => void>();
  private saveStateListeners = new Set<(state: SaveState) => void>();
  private changeHighlightListeners = new Set<(changes: ChangeHighlight[]) => void>();
  private textDeltaListeners = new Set<(ops: TextDeltaOp[], source: TextDeltaSource) => void>();

  /** CRDT session opened for the current work — the client sets
   * this at open/close/switch time; text paths are inert until the
   * session is live. */
  crdtReady = false;
  /** Set when the current text came from the offline mirror. */
  offlineReading = false;

  constructor(host: EditSyncHost) {
    this.host = host;
  }

  hasUnsynced(): boolean {
    return this.hasUnsyncedLocalEdits;
  }

  getText(): string {
    return this.text;
  }

  setText(newText: string): void {
    if (newText === this.text) return;
    const prev = this.text;
    this.text = newText;
    this.hasUnsyncedLocalEdits = true;

    if (this.crdtReady) {
      this.flushTextDelta();
    }

    this.notifyTextDelta(diffToOps(prev, newText), "local");
    this.textListeners.forEach((cb) => cb(newText));
  }

  /** ONE delta in flight, ever (see flushTextDelta for why).
   * Offline: the delta is not sent — the edited text persists to
   * the offline cache (IndexedDB), and the existing reconciliation
   * path (reconnect: local state differs → push local) replays it
   * when the server returns. The user types normally, unaware. */
  private flushTextDelta(): void {
    if (this.deltaInFlight) return;
    // OFFLINE FIRST: persist regardless of the delta base (a page
    // reload while offline loses lastAckedLocalText — the user's
    // post-reload edits still need to survive another reload).
    if (!this.host.isSocketOpen()) {
      this.hasUnsyncedLocalEdits = true;
      import("../offline-cache").then(({ cacheDocument }) => {
        const meta = this.host.getCacheMeta();
        cacheDocument({
          work_id: this.host.getWorkBeId(),
          title: meta.title,
          text: this.text,
          starred: meta.starred,
        }).catch(() => {});
      });
      return;
    }
    const base = this.lastAckedLocalText;
    if (base === null || base === this.text) return;
    this.sendTextDelta(base, this.text);
  }

  /** Server-authoritative text adoption: sets local text AND the
   * delta base (lastAckedLocalText) — the queue cannot send without
   * a base, and the base must equal what the server actually has. */
  adoptServerText(t: string): void {
    const prev = this.text;
    this.text = t;
    this.lastAckedLocalText = t;
    // Work open/load: adopting over EMPTY text is not a rebase event.
    // Consumers' server lists (annotations, attribution) are measured
    // against the incoming text already — rebasing them through the
    // insert-everything diff would shift every span past the document
    // end. Observed as code_block styling lost after a work switch
    // when the annotation_list response beat crdt_sync_open. Mid-
    // session adoptions (echo recovery, prev non-empty) keep firing:
    // those diffs are meaningful.
    if (prev !== "") {
      this.notifyTextDelta(diffToOps(prev, t), "server");
    }
    this.textListeners.forEach((cb) => cb(t));
  }

  setTextLocal(newText: string): void {
    if (newText === this.text) return;
    const prev = this.text;
    this.text = newText;
    this.notifyTextDelta(diffToOps(prev, newText), "local");
    this.textListeners.forEach((cb) => cb(newText));
  }

  /** Reconnect-push bookkeeping: assign local text without firing
   * listeners (the open flow fires them once, after the merge). */
  setTextSilent(newText: string): void {
    this.text = newText;
  }

  /** The open response proved the server's view IS ours — clear the
   * unsynced guard (adopt alone does not; the reconnect push keeps
   * it armed until the real acknowledgement). */
  markSynced(): void {
    this.hasUnsyncedLocalEdits = false;
  }

  /** Serve the cached mirror read-only (offline open with no
   * in-memory text). Caller guarantees unsynced-local-edits is
   * false — never serve a stale cache over offline-typed text. */
  serveOfflineCache(text: string): void {
    this.text = text;
    this.offlineReading = true;
    this.textListeners.forEach((cb) => cb(this.text));
  }

  /** Fire text listeners with the current text (initial open). */
  notifyText(): void {
    this.textListeners.forEach((cb) => cb(this.text));
  }

  /** Clear text + change highlights for a work switch. */
  resetText(): void {
    this.text = "";
    this.recentChanges = [];
    this.textListeners.forEach((cb) => cb(""));
  }

  /** Socket dropped: the CRDT session and any in-flight delta are
   * gone. The unacked-local guard intentionally survives — it is
   * what makes the offline-typed text reconcile on return. */
  resetConnectionState(): void {
    this.crdtReady = false;
    this.deltaInFlight = false;
    this.pendingServerText = null;
  }

  onTextChange(cb: (text: string) => void): () => void {
    this.textListeners.add(cb);
    return () => { this.textListeners.delete(cb); };
  }

  /** Fired when a text edit is ACKNOWLEDGED by the server — the
   * authoritative "this change is now real" moment. */
  onEditCommit(cb: (info: { inserted: number; deleted: number; net: number; total: number }) => void): () => void {
    this.editCommitListeners.add(cb);
    return () => { this.editCommitListeners.delete(cb); };
  }

  onSaveStateChange(cb: (state: SaveState) => void): () => void {
    this.saveStateListeners.add(cb);
    return () => { this.saveStateListeners.delete(cb); };
  }

  onChangeHighlights(cb: (changes: ChangeHighlight[]) => void): () => void {
    this.changeHighlightListeners.add(cb);
    return () => { this.changeHighlightListeners.delete(cb); };
  }

  /** Fired once per VISIBLE text transition (never per send attempt
   * — retries and rollbacks do not double-fire). Consumers rebase
   * positions/spans through the ops. Sources: "local" (own edit),
   * "remote" (another session's delta), "server" (full-state
   * adoption, diffed). */
  onTextDeltaApplied(cb: (ops: TextDeltaOp[], source: TextDeltaSource) => void): () => void {
    this.textDeltaListeners.add(cb);
    return () => { this.textDeltaListeners.delete(cb); };
  }

  private notifyTextDelta(ops: TextDeltaOp[], source: TextDeltaSource): void {
    if (ops.length === 0) return;
    this.textDeltaListeners.forEach((cb) => cb(ops, source));
  }

  getSaveState(): SaveState {
    return this.saveState;
  }

  private setSaveState(state: SaveState): void {
    if (this.saveState === state) return;
    this.saveState = state;
    if (this.saveStateTimer) {
      clearTimeout(this.saveStateTimer);
      this.saveStateTimer = null;
    }
    this.saveStateListeners.forEach((cb) => cb(state));
  }

  /**
   * Full-state broadcast (crdt_text_update) while our CRDT session
   * is live. Three races live here: in-flight queueing, the stale
   * echo window, and unsynced-local push-back.
   */
  handleServerTextUpdate(newText: string): void {
    if (this.deltaInFlight) {
      // FR-69 S2 / S-4: while an unsynced push is in flight, a
      // broadcast is the PRE-PUSH server view — queueing it as
      // pending would overwrite local text right after our own
      // ack. Drop it; post-ack divergence arrives as a fresh
      // broadcast. (Queueing stays correct for plain typing.)
      if (!this.hasUnsyncedLocalEdits) {
        this.pendingServerText = newText;
      }
    } else if (newText !== this.text) {
      // Echo-race guard: shortly after OUR acked edit, a
      // broadcast whose text differs from what we sent is a
      // stale materialization (pre-edit snapshot) — applying it
      // would resurrect deleted text. Drop it; the next genuine
      // server-side change (another user) arrives later than
      // this window.
      const echoWindowMs = 2500;
      const recentAck = Date.now() - this.lastAckedAt < echoWindowMs;
      const isStaleEcho =
        recentAck &&
        this.lastAckedLocalText !== null &&
        newText !== this.lastAckedLocalText &&
        newText !== this.text;
      if (isStaleEcho) {
        // Safety: if the text keeps disagreeing after the window,
        // reconcile with a full fetch rather than looping.
        console.warn("[crdt] dropping stale text echo", {
          len: newText.length,
          ackedLen: this.lastAckedLocalText?.length,
        });
      } else if (this.hasUnsyncedLocalEdits) {
        // FR-69 S2: local edits exist that the server has NEVER
        // acknowledged (typed during an outage). A full-state
        // broadcast here is the server's pre-offline view;
        // adopting it would clobber unsynced work. Keep local
        // and push a delta to converge the server to us.
        console.warn(
          "[crdt] server full-state differs while local edits are unacked — pushing local",
          { localLen: this.text.length, serverLen: newText.length },
        );
        this.sendTextDelta(newText, this.text, { protectLocal: true });
      } else {
        this.adoptServerText(newText);
      }
    }
  }

  /** Remote delta (crdt_text_delta from another session). Applies
   * against local text; a malformed/lost-base delta falls back to a
   * full-state refresh. */
  applyRemoteDelta(
    ops: Array<{ type: string; count?: number; text?: string }>,
    author: string,
  ): void {
    try {
      const newText = applyDeltaOps(this.text, ops);
      if (newText !== this.text) {
        const changes = this.computeChangesFromDelta(ops);
        if (changes.length > 0) {
          const now = Date.now();
          for (const c of changes) {
            this.recentChanges.push({ ...c, timestamp: now, author });
          }
          this.recentChanges = this.recentChanges.filter(
            (c) => now - c.timestamp < 5000,
          );
          this.changeHighlightListeners.forEach((cb) =>
            cb([...this.recentChanges]),
          );
        }
        this.text = newText;
        this.notifyTextDelta(ops, "remote");
        this.textListeners.forEach((cb) => cb(newText));
      }
    } catch {
      void this.refreshText();
    }
  }

  async refreshText(): Promise<void> {
    if (!this.crdtReady) return;
    try {
      await this.host.sendRequest("crdt_sync_full_state", {
        work_id: this.host.getWorkBeId(),
      });
    } catch {
      // ignore
    }
  }

  private computeChangesFromDelta(
    ops: Array<{ type: string; count?: number; text?: string }>,
  ): Array<{ start: number; end: number }> {
    const changes: Array<{ start: number; end: number }> = [];
    let offset = 0;
    for (const op of ops) {
      if (op.type === "retain") {
        offset += op.count ?? 0;
      } else if (op.type === "insert") {
        const len = op.text?.length ?? 0;
        if (len > 0) {
          changes.push({ start: offset, end: offset + len });
          offset += len;
        }
      }
    }
    return changes;
  }

  sendTextDelta(oldText: string, newText: string, opts?: { protectLocal?: boolean }): void {
    if (oldText === newText) return;

    const ops = diffToOps(oldText, newText);
    let insertLen = 0;
    let deleteLen = 0;
    for (const op of ops) {
      if (op.type === "insert") insertLen += (op.text ?? "").length;
      else if (op.type === "delete") deleteLen += op.count ?? 0;
    }

    this.deltaInFlight = true;
    this.setSaveState("saving");
    this.host.sendRequest("work_revise_delta", {
      work_id: this.host.getWorkBeId(),
      base_revision: 0,
      ops,
    }).then(() => {
      this.deltaInFlight = false;
      this.lastAckedLocalText = newText;
      this.lastAckedAt = Date.now();
      this.hasUnsyncedLocalEdits = false;
      this.setSaveState("saved");
      // The system speaks: every committed edit announces its size so
      // a cut, an undo restore, or a stray deletion is visible the
      // moment it lands instead of being discovered as missing text.
      const info = { inserted: insertLen, deleted: deleteLen, net: insertLen - deleteLen, total: newText.length };
      this.editCommitListeners.forEach((cb) => cb(info));
      this.saveStateTimer = setTimeout(() => this.setSaveState("idle"), 2000);
      if (this.pendingServerText !== null) {
        const serverText = this.pendingServerText;
        this.pendingServerText = null;
        if (serverText !== this.text) {
          this.adoptServerText(serverText);
        }
      }
      // Queue drain: edits that arrived while this delta was in
      // flight now send against the fresh base — one in flight,
      // ever. (Concurrent work_revise_delta requests raced on the
      // server and produced MIRRORED text when per-keystroke
      // typing fired N at once — the iOS bug, FR-150.)
      if (this.text !== this.lastAckedLocalText) {
        this.flushTextDelta();
      }
    }).catch((e) => {
      this.deltaInFlight = false;
      this.setSaveState("error");
      const msg = String(e?.message || e || "");
      if (msg.includes("WebSocket not open") || msg.includes("connection closed") || msg.includes("timed out")) {
        console.warn("Text delta not sent (will sync on reconnect):", msg);
      } else if (opts?.protectLocal) {
        // FR-69 S2 / S-1: this delta CARRIES the user's only copy
        // (reconnect push of offline edits). Never roll back — the
        // oldText here is the server view, not a state the user was
        // in. Keep local, stay dirty, retry once shortly (the merge
        // will also re-fire on the next open).
        console.warn("[crdt] push failed; keeping local text, will retry:", msg);
        this.hasUnsyncedLocalEdits = true;
        if (this.pushRetryTimer == null) {
          this.pushRetryTimer = setTimeout(() => {
            this.pushRetryTimer = null;
            if (this.hasUnsyncedLocalEdits && this.crdtReady && this.host.isConnected()) {
              this.sendTextDelta(oldText, this.text, { protectLocal: true });
            }
          }, 2000);
        }
      } else {
        console.error("Failed to send text delta:", e);
        this.text = oldText;
        this.textListeners.forEach((cb) => cb(oldText));
      }
    });
  }
}

/** Minimal consuming delta between two texts: retain the common
 * prefix, one delete, one insert, retain the common suffix. The
 * exact ops sendTextDelta puts on the wire — shared so cursor/span
 * consumers rebase against the same shape. */
export function diffToOps(oldText: string, newText: string): TextDeltaOp[] {
  if (oldText === newText) return [];
  const prefix = commonPrefix(oldText, newText);
  const oldRemaining = oldText.slice(prefix);
  const newRemaining = newText.slice(prefix);
  const suffix = commonSuffix(oldRemaining, newRemaining);
  const deleteLen = oldText.length - prefix - suffix;
  const insertText = newText.slice(prefix, newText.length - suffix);

  const ops: TextDeltaOp[] = [];
  if (prefix > 0) {
    ops.push({ type: "retain", count: prefix });
  }
  if (deleteLen > 0) {
    ops.push({ type: "delete", count: deleteLen });
  }
  if (insertText.length > 0) {
    ops.push({ type: "insert", text: insertText });
  }
  if (suffix > 0) {
    ops.push({ type: "retain", count: suffix });
  }
  return ops;
}

function commonPrefix(a: string, b: string): number {
  let i = 0;
  const len = Math.min(a.length, b.length);
  while (i < len && a.charCodeAt(i) === b.charCodeAt(i)) i++;
  return i;
}

function commonSuffix(a: string, b: string): number {
  let i = 0;
  const aLen = a.length;
  const bLen = b.length;
  while (i < aLen && i < bLen && a.charCodeAt(aLen - 1 - i) === b.charCodeAt(bLen - 1 - i)) i++;
  return i;
}

function applyDeltaOps(
  text: string,
  ops: Array<{ type: string; count?: number; text?: string }>,
): string {
  let result = "";
  let pos = 0;
  for (const op of ops) {
    switch (op.type) {
      case "retain": {
        const count = op.count ?? 0;
        if (pos + count > text.length)
          throw new Error(`delta retain out of bounds: pos=${pos} count=${count} len=${text.length}`);
        result += text.slice(pos, pos + count);
        pos += count;
        break;
      }
      case "delete": {
        const count = op.count ?? 0;
        if (pos + count > text.length)
          throw new Error(`delta delete out of bounds: pos=${pos} count=${count} len=${text.length}`);
        pos += count;
        break;
      }
      case "insert": {
        result += op.text ?? "";
        break;
      }
    }
  }
  if (pos !== text.length)
    throw new Error(`delta did not consume full text: pos=${pos} len=${text.length}`);
  return result;
}
