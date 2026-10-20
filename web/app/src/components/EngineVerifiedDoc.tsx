import { useEffect, useState } from "react";
import { engineReady } from "../engine-wasm-loader";

/**
 * FR-148b: the verified document viewer — the read-only mobile
 * surface in miniature. Fetch a public work, VERIFY its content
 * hash with the wasm engine (blake3), and render only what
 * verifies. Tampered or unverifiable content renders as an error,
 * never as text — the same discipline as the cross-server trust
 * ladder, applied to every fetch.
 */
export interface VerifiedDoc {
  title: string;
  text: string;
  tumbler?: string;
  originServerName?: string;
}

type State =
  | { kind: "loading" }
  | { kind: "verified"; doc: VerifiedDoc }
  | { kind: "error"; message: string };

export function EngineVerifiedDoc({
  url,
  onVerified,
}: {
  url: string;
  /** Optional hook for callers (e.g. cache the verified doc). */
  onVerified?: (doc: VerifiedDoc) => void;
}) {
  const [state, setState] = useState<State>({ kind: "loading" });

  useEffect(() => {
    let alive = true;
    setState({ kind: "loading" });
    (async () => {
      try {
        const resp = await fetch(url);
        if (!resp.ok) throw new Error(`origin returned ${resp.status}`);
        const data = (await resp.json()) as {
          title?: string;
          text?: string;
          content_hash?: string;
          tumbler?: string;
        };
        if (typeof data.text !== "string") {
          throw new Error("response carries no text");
        }
        // The verification gate: wasm blake3 over the received text
        // must match the origin's declared hash. No hash declared →
        // unverifiable → error (fail closed).
        if (typeof data.content_hash !== "string" || !data.content_hash) {
          throw new Error("origin declared no content hash — unverifiable");
        }
        const engine = await engineReady();
        const enc = new TextEncoder();
        const ok = engine.verify_blake3(enc.encode(data.text), data.content_hash);
        if (!ok) throw new Error("content hash mismatch — document tampered or corrupted");
        const doc: VerifiedDoc = {
          title: data.title ?? "untitled",
          text: data.text,
          tumbler: data.tumbler,
        };
        if (alive) {
          setState({ kind: "verified", doc });
          onVerified?.(doc);
        }
      } catch (e) {
        if (alive) {
          setState({
            kind: "error",
            message: e instanceof Error ? e.message : "verification failed",
          });
        }
      }
    })();
    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [url]);

  if (state.kind === "loading") {
    return <div style={{ padding: 24, color: "var(--text-dim)", fontSize: 13 }}>fetching + verifying…</div>;
  }
  if (state.kind === "error") {
    return (
      <div role="alert" style={{ padding: 24, color: "var(--red)", fontSize: 13 }}>
        ✗ {state.message}
      </div>
    );
  }
  return (
    <article data-testid="engine-verified-doc" style={{ padding: 24 }}>
      <header style={{ marginBottom: 12 }}>
        <h2 style={{ margin: 0, fontSize: 17 }}>{state.doc.title}</h2>
        <div style={{ fontSize: 11, color: "var(--green)", marginTop: 4 }}>
          ✓ content verified (blake3, wasm engine)
          {state.doc.tumbler ? (
            <span style={{ color: "var(--text-dim)", marginLeft: 8, fontFamily: "monospace" }}>
              {state.doc.tumbler}
            </span>
          ) : null}
        </div>
      </header>
      <pre style={{ whiteSpace: "pre-wrap", fontFamily: "inherit", margin: 0, lineHeight: 1.7 }}>
        {state.doc.text}
      </pre>
    </article>
  );
}

export default EngineVerifiedDoc;
