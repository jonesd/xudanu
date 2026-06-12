# LLM Integration

## Overview

Xudanu integrates LLM capabilities directly into the server, enabling AI-assisted
features like document narration, auto-titling, and writing feedback. The system
supports two backends:

- **GitHub Models** (default) — free-tier OpenAI-compatible API (gpt-4o-mini)
- **Ollama** — self-hosted, runs locally

All LLM calls are **non-blocking**. Narration and writing feedback release the server
mutex before calling the model. Auto-title runs in a background tokio task.

LLM features are **disabled by default** — the server starts fine without any API key.
Set `GITHUB_TOKEN` to enable them. The frontend hides LLM buttons when disabled.

## Enabling / Disabling

LLM support is controlled by a single environment variable:

```bash
# Enable LLM features (GitHub Models)
GITHUB_TOKEN=ghp_your_token cargo run --features serde,server

# Disable — server works normally, LLM buttons hidden in UI
cargo run --features serde,server
```

Internally, `ollama::get_client()` lazily checks for `GITHUB_TOKEN` on first use. If
absent, it returns `None` and all LLM dispatch paths return a friendly message
instead. The frontend checks `llm_enabled` in `server_stats` and hides the Narrate
and Feedback buttons when false.

This means:
- No crash if the token is missing
- No wasted API calls
- Users who don't want AI features simply don't set the env var
- The `llm_enabled` flag is exposed in `ServerInfoPayload` for UI and tooling

## Current Features

### Diff Narration

Clicking **Narrate** in the toolbar sends the previous snapshot and current document
text to the LLM, which returns a 1-3 sentence summary of what changed.

**How it works:**

1. Each document tracks a `narration_snapshot` — the text as of the last narration
2. On click, the server extracts both the snapshot and current text, then releases
   its mutex
3. The LLM compares old vs. new and describes the changes
4. The snapshot updates to the current text, so next narration describes only the
   intervening edits
5. If no snapshot exists (first narration), the old version is empty — the LLM
   summarizes the whole document

**Frontend:** Button shows "Thinking..." while waiting, then displays narration
text below the editor.

### Auto-Title

When a new work is created with at least 20 characters of content, the server
asynchronously asks the LLM to generate an 8-word title. The title is set on the
work automatically — no user action needed.

**How it works:**

1. `WorkCreate` returns the new work ID
2. `spawn_auto_title()` checks if LLM is enabled, then fires a background tokio task
3. The task reads the work content, builds a title prompt (truncated to 2000 chars),
   and calls the LLM
4. The result is set as the work title via `set_work_title()`
5. If the LLM call fails or LLM is disabled, the work keeps its default title

### Writing Feedback

Clicking **Feedback** sends the full document text to the LLM, which returns
constructive feedback as 3-5 bullet points covering clarity, structure, and
persuasiveness.

**How it works:**

1. The server extracts the current document text (up to 4000 chars), releases mutex
2. The LLM acts as a "writing coach" and reviews the document
3. Feedback is displayed with `white-space: pre-wrap` to preserve bullet formatting
4. If the document is empty, returns "(No content to review.)" without calling the LLM

## Usage Tracking

Every LLM call is tracked by `LlmUsageTracker` — a thread-safe, in-memory counter
that records:

- **Feature type** (narration, auto_title, writing_feedback)
- **Prompt size** (characters sent)
- **Response size** (characters received)
- **Timestamp**

Usage is exposed in `server_stats` under `llm_usage`:

```json
{
  "llm_usage": {
    "total_requests": 12,
    "total_prompt_chars": 48500,
    "total_response_chars": 3200,
    "by_feature": {
      "narration": { "requests": 5, "prompt_chars": 30000, "response_chars": 1500 },
      "auto_title": { "requests": 4, "prompt_chars": 8500, "response_chars": 120 },
      "writing_feedback": { "requests": 3, "prompt_chars": 10000, "response_chars": 1580 }
    },
    "recent": [
      { "feature": "narration", "prompt_chars": 5200, "response_chars": 280, "timestamp_secs": 1748200000 }
    ]
  }
}
```

The tracker keeps the last 50 requests in `recent` for monitoring. This helps users
stay within the GitHub Models free tier (15 req/min, 150 req/day).

**Implementation:** `LlmUsageTracker` uses `AtomicU64` for counters and a `Mutex` for
per-feature breakdown and recent entries. It's stored in a `OnceLock` singleton and
accessed via `ollama::usage_tracker()`. The `generate_tracked()` method on `LlmClient`
records usage automatically — callers don't need to do anything extra.

## Setup

### GitHub Models (Recommended)

GitHub Models provides free API access to models like `gpt-4o-mini` through an
OpenAI-compatible endpoint. Rate limits: 15 requests/min, 150 requests/day.

**Steps:**

1. Create a GitHub Personal Access Token with the `models:read` scope:
   - Go to **Settings → Developer settings → Fine-grained tokens → Generate new token**
   - Under **Permissions → Account permissions**, enable **Models: Read**
   - Copy the token

2. Start the server with the token:
   ```bash
   GITHUB_TOKEN=ghp_your_token_here cargo run --features serde,server
   ```

3. The frontend will show Narrate and Feedback buttons when connected.

**Security:** The token is read from `GITHUB_TOKEN` on first LLM call. It is never
written to disk, logged, or embedded in source code. If the env var is missing, LLM
features are simply disabled — no crash, no error.

### Ollama (Self-Hosted)

Ollama runs models locally — no API key needed, no rate limits, but you need
GPU/CPU resources and the model downloaded.

**Steps:**

1. [Install Ollama](https://ollama.ai) and start it:
   ```bash
   ollama serve
   ```

2. Pull a model:
   ```bash
   ollama pull llama3.1
   ```

3. Change the client initialization in `src/server/ollama.rs`:
   ```rust
   // In get_client(), replace the GITHUB_TOKEN check with:
   Some(LlmClient::ollama_default())
   ```
   (Or wire it to a config flag — currently the backend is chosen at compile time.)

**Tradeoffs:**
- No rate limits, no network dependency
- Slower inference (depends on your hardware)
- Blocks the tokio runtime during generation (up to 120s timeout)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Browser                                                │
│  ├── llmEnabled from server_stats → show/hide buttons   │
│  ├── "Narrate" button → diffNarration(workId)           │
│  ├── "Feedback" button → writingFeedback(workId)        │
│  ├── "Thinking..." / "Reviewing..." state while waiting │
│  └── Results displayed below editor                     │
├─────────────────────────────────────────────────────────┤
│  WebSocket (JSON protocol)                              │
│  ├── work_diff_narration { work_id }                    │
│  ├── work_writing_feedback { work_id }                  │
│  └── server_stats → { llm_enabled, llm_usage }          │
├─────────────────────────────────────────────────────────┤
│  Server                                                 │
│  ├── ollama::get_client() → Option<LlmClient>           │
│  │   └── None if GITHUB_TOKEN not set                   │
│  ├── dispatch_narration()                               │
│  │   ├── Extract snapshot + current text (mutex)        │
│  │   ├── Release mutex                                  │
│  │   ├── llm.generate_tracked(Narration, prompt)        │
│  │   └── Update narration snapshot (mutex)              │
│  ├── dispatch_writing_feedback()                        │
│  │   ├── Extract current text (mutex)                   │
│  │   ├── Release mutex                                  │
│  │   └── llm.generate_tracked(WritingFeedback, prompt)  │
│  ├── spawn_auto_title() (tokio::spawn, background)      │
│  │   ├── Check llm enabled                              │
│  │   ├── llm.generate_tracked(AutoTitle, prompt)        │
│  │   └── set_work_title()                               │
│  └── ollama.rs:                                         │
│      ├── LlmClient, LlmBackend (GitHub/Ollama)          │
│      ├── LlmUsageTracker (OnceLock singleton)           │
│      ├── get_client(), llm_enabled(), usage_tracker()   │
│      └── generate_tracked() → generate() + record()     │
└─────────────────────────────────────────────────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `src/server/ollama.rs` | `LlmClient`, `LlmBackend`, `LlmUsageTracker`, prompt builders, `get_client()`, `llm_enabled()` |
| `src/server/transport/dispatch.rs` | `dispatch_narration()`, `dispatch_writing_feedback()`, `spawn_auto_title()` |
| `src/server/otree_crdt.rs` | `narration_snapshot()`, `set_narration_snapshot()` |
| `src/server/transport/protocol.rs` | `WorkDiffNarration` (0x031C), `WorkWritingFeedback` (0x031D), `NarrationResult`, `WritingFeedbackResult`, `llm_enabled` in `ServerInfoPayload` |
| `src/server/transport/codec.rs` | JSON deserialization for narration and feedback requests |
| `web/app/src/components/WorkspacePage.tsx` | LLM buttons (conditionally shown), narration + feedback panels |
| `web/app/src/hooks/useCrdtSync.ts` | `narrateDiff()`, `getWritingFeedback()`, `llmEnabled` state |
| `web/app/src/api/crdt_sync.ts` | `diffNarration()`, `writingFeedback()` client methods |

## Potential Future Features

These are natural extensions of the existing `LlmClient` infrastructure. Each would
need a prompt builder (like `build_narration_prompt`), a dispatch path (like
`dispatch_narration`), and a new `LlmFeature` variant for usage tracking.

### Find Related Documents

Send the current document + titles/summaries of all other works to the LLM. Ask which
documents are topically related. This provides semantic similarity that the existing
content watch system (exact fingerprint matching + Jaccard word overlap) cannot.

**Prompt sketch:** "Here is a document and a list of other works (title + preview).
Which 3-5 are topically related? For each, explain why."

**Data needed:** `list_works_with_titles()` + first N chars of each work's content.
Same dispatch pattern as writing feedback.

**API cost:** One call per request. Prompt size scales with number of works (~100 chars
per work for title + preview). For 20 works, ~2-3K chars prompt.

### Link Suggestion

Builds on Find Related — for each related document, the LLM suggests where to create
bidirectional links and identifies passages worth transcluding.

**Prompt sketch:** "Here is document A and related document B. Suggest specific links
between them: which passages in A should link to which sections of B, and vice versa."

**Implementation:** Two-phase — first Find Related, then for each related doc, a
link suggestion call. Could be expensive (N+1 calls). Consider batching or limiting
to top 3 related docs.

### Document Summary

Generate a 2-3 sentence summary for any work — useful for the works list view, search
results, or link previews. Could run on-demand or automatically when a work reaches a
stable state (no edits for N minutes).

**Prompt sketch:** "Summarize this document in 2-3 sentences. Focus on the main
argument and key conclusions."

**Cheapest feature:** One prompt, one short response. Could be cached on the work
object and regenerated on significant edits.

### Non-Human Author Attribution

Tag LLM-generated content with a special provenance marker. When the LLM contributes
substantive text (not just narration or titles), the attribution system could mark
those elements with `author_type: "llm"` alongside the human author who triggered it.
This preserves the Xanadu principle of knowing who wrote what, extended to AI
contributors.

**Implementation:** Add an `author_type` field to `ElementProvenance` and tag
elements inserted via LLM-assisted features differently from human-typed content.

### Content Watch Enhancement

The existing content watch system uses Jaccard similarity on text to detect related
documents. The LLM could improve match quality by doing semantic comparison —
understanding that "climate policy" and "carbon regulation" are related even without
shared keywords.

**Implementation:** When a content watch triggers (fingerprint match + Jaccard filter),
optionally run an LLM call to score semantic similarity before sending the notification.
This adds latency but improves precision.

### Writing Assistance

In-editor suggestions: sentence completion, grammar fixes, style improvements. Would
require a streaming LLM connection and careful integration with the CRDT editing
pipeline to avoid conflicts with human typing.

**Challenge:** Latency must be under 500ms to feel responsive. GitHub Models free
tier may not be fast enough. Ollama on local GPU would be better for this use case.
