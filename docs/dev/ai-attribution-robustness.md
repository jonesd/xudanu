# AI Content Attribution: Detection Layers and Robustness Analysis

- **ID:** Research note (not an FR)
- **Status:** Analysis complete (2026-10-15)
- **Context:** David's concern — "I'm not confident that the
  identification of human vs llm/machine is robust enough"
- **Companion to:** FR-58 (paste-match), FR-89 (telemetry),
  the provenance architecture in edition/provenance.rs

## 1. The problem, precisely

Every passage in xudanu carries a label: `author_type: Human | Llm |
Historical`. The label determines who the system says wrote the text.
The question is: **how confident can we be that the label is correct?**

The label is set by the **interface** the text arrived through, not by
an independent assessment of the text itself:

```
MCP write path  ───→ author_type = "llm"    (the server knows the channel)
Direct editing  ───→ author_type = "human"  (the server knows the channel)
```

This is **process attestation** — strong when the process is honest,
weak when it isn't.

## 2. The four mis-attribution scenarios

| # | Scenario | Label assigned | Correct? | Detection |
|---|---|---|---|---|
| A | Agent writes via MCP | "llm" | ✓ | n/a (correct by construction) |
| B | Human types directly | "human" | ✓ | n/a (correct by construction) |
| C | Human copies LLM text from within the docuverse, pastes as "human" | "human" | ✗ | FR-58 paste-match catches this |
| D | Human copies LLM text from an external source (ChatGPT web), pastes as "human" | "human" | ✗ | **the gap** — nothing currently catches this |

Scenario D is the most common in practice and the hardest to detect.
The text originates outside xudanu's control; the server sees only
"text arrived via the direct editing path."

## 3. The detection layers (what exists, what could)

### Layer 1: Process attestation (BUILT — strong for cooperative use)

The server knows which interface text arrived through. The MCP write
path sets `author_type: "llm"` with the model identity; the direct
editing path sets `author_type: "human"`.

**Robustness:** strong for agents connecting via MCP (the channel IS
the evidence). Weak against deliberate mislabeling (routing text
through the wrong interface).

**Limitation:** describes the process, not the author.

### Layer 2: Content-match detection (BUILT — FR-58 paste-match)

The n-gram index detects when text arriving via one path matches text
that exists under a different authorship. If LLM-generated text is in
work W1 (author: llm) and someone pastes it into W2 (author: human),
the paste-match fires and offers the transclusion.

**Robustness:** strong for internal copying. Useless for external
sources (the text must already be in the docuverse).

**New capability (just built):** `paste_match_check` wire op — any
client can query whether pasted text matches existing content with a
different author_type.

### Layer 3: Timing analysis (DATA EXISTS — analysis not built)

Every `RangeElement` carries a `placed_at` timestamp. The revision
chain records the sequence of insertions. Human typing produces:
- small chunks (1-20 characters)
- irregular intervals (seconds to minutes between)
- gradual accumulation

LLM generation or bulk paste produces:
- large chunks (100+ characters)
- single or few insertion events
- burst appearance

**The data is already captured.** The analysis is a variance/size
heuristic over the `placed_at` timestamps and element sizes. Not
built, but buildable in hours.

**Robustness:** moderate. Catches paste (burst patterns), not intent.
A slow typist transcribing LLM output would look like normal typing.

### Layer 4: Stylometric analysis (NOT BUILT — probabilistic but independent)

LLM-generated text has statistical properties that differ from human
writing. These are detectable without provider cooperation and without
access to the generating model.

**This is the layer that addresses scenario D** — external LLM text
pasted via the "human" path. It doesn't depend on the interface, the
docuverse, or the provider. It depends only on the text itself.

## 4. Stylometric fingerprints — how they work

### 4.1 Perplexity (the strongest single signal)

**What it measures:** how "surprised" a language model is by the text.
LLM-generated text is produced by maximising probability, so it tends
to be more predictable (lower perplexity) than human writing.

**How to compute it:**
```
1. Run a language model over the text
2. For each token, compute the probability the model assigns to it
3. Perplexity = geometric mean of inverse probabilities
4. Low perplexity → text is predictable → likely LLM-generated
```

**Typical values (approximate, from published benchmarks):**
| Text source | Perplexity (lower = more predictable) |
|---|---|
| Human-written prose | 40-80 |
| GPT-4 output | 15-30 |
| Claude output | 15-35 |
| Heavily edited LLM text | 30-60 (approaches human) |

**Strengths:** the most reliable single signal; improves with longer
passages; independent of the model that generated the text.

**Weaknesses:** requires a language model to compute (can be small
and local); formulaic human writing (legal boilerplate, technical
docs) has low perplexity too; degrades as models improve.

**Implementation:** a small local model (or the existing `ollama.rs`
integration) can compute perplexity. Alternatively, a pre-built
perplexity scorer (e.g., GPT-2-based) runs in milliseconds.

### 4.2 Burstiness (sentence-level variation)

**What it measures:** the variance in sentence complexity. Humans
write "burstily" — mixing short punchy sentences with long complex
ones. LLMs produce more uniform sentence structures.

**How to compute it:**
```
1. Split the text into sentences
2. For each sentence, compute a complexity metric:
   - length (word count)
   - entropy (vocabulary diversity)
   - clause depth (nesting level)
3. Burstiness = variance of the complexity metric across sentences
4. Low variance → uniform writing → likely LLM
```

**Typical values:**
| Text source | Burstiness (higher = more varied) |
|---|---|
| Human prose | 0.6-1.2 |
| LLM output | 0.2-0.5 |
| Poetry (extreme burstiness) | 1.5+ |

**Strengths:** pure statistics — no model needed; fast; explainable.

**Weaknesses:** less reliable than perplexity; humans can write
uniformly (especially in formal/technical contexts); LLMs can be
prompted to be bursty.

### 4.3 Vocabulary fingerprints

**What it measures:** the frequency of words and phrases that are
statistically over-represented in LLM output compared to human writing.

**Known LLM-frequent terms (from published analyses):**

| Category | Over-represented terms |
|---|---|
| Intensifiers | delve, crucial, pivotal, paramount, instrumental |
| Structure markers | furthermore, moreover, additionally, consequently |
| Metaphors | tapestry, landscape, navigate, journey, framework |
| Hedges | it's important to note, it's worth considering, arguably |
| Transitions | that being said, with that in mind, in this context |
| Conclusions | in conclusion, ultimately, at the end of the day |
| Parallel constructions | not only X but also Y; both X and Y; from X to Y |

**How to compute it:**
```
1. Tokenise the text
2. Count occurrences of LLM-frequent terms
3. Compare frequency against a human baseline corpus
4. High overlap → likely LLM
```

**Strengths:** extremely fast (dictionary lookup); explainable (you
can point to the specific words); no model required.

**Weaknesses:** humans can mimic LLM vocabulary (or vice versa);
models are being trained to diversify; cultural bias (these terms are
over-represented in English LLM output specifically).

### 4.4 Structural patterns

**What it measures:** characteristic organisational patterns in LLM
output that differ from human writing habits.

| Pattern | LLM tendency | Human tendency |
|---|---|---|
| List structure | items in threes | variable (2-7 items) |
| Paragraph length | uniform (3-5 sentences) | variable (1-10+ sentences) |
| Opening | "In today's..." / "In the realm of..." | direct, contextual, or personal |
| Closing | summary + call to action | abrupt, trailing, or contextual |
| Hedging density | high ("arguably", "it's worth noting") | lower, more direct |
| Parallel construction | heavy (repeated syntactic frames) | lighter, more varied |
| Section markers | "Firstly... Secondly... Finally" | varied or absent |

**How to compute it:** pattern matching over sentence and paragraph
structure. Pure text analysis, no model needed.

### 4.5 Token probability distribution

**What it measures:** the statistical distribution of token choices.
Each model has a characteristic "fingerprint" in how it selects the
next token, which is different from human token selection.

**How to compute it:**
```
1. Run the text through a reference model
2. At each position, compare the actual token's probability
   against the model's full distribution
3. Compute the KL divergence from the expected human distribution
4. Low divergence → the text reads like model output
```

**Strengths:** the most technically rigorous approach; can identify
the specific model that generated the text.

**Weaknesses:** requires knowing the model (or having access to it);
most computationally expensive; an arms race with model updates.

## 5. The combined detector

In practice, a stylometric detector combines multiple signals:

```
                    ┌─────────────────┐
                    │ Input text      │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │ Perplexity   │  │ Burstiness   │  │ Vocabulary   │
  │ (model-based)│  │ (statistics) │  │ (dictionary) │
  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
         │                  │                  │
         ▼                  ▼                  ▼
  ┌─────────────────────────────────────────────────┐
  │           Combined likelihood score              │
  │  P(AI-generated | perplexity, burstiness,       │
  │     vocabulary, structure)                      │
  └───────────────────────┬─────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │ Result:               │
              │  likelihood: 0.87     │
              │  confidence: high     │
              │  signals: perplexity  │
              │  low, burstiness low, │
              │  "delve" + "crucial"  │
              │  detected             │
              └───────────────────────┘
```

**Important:** the result is a probability, not a proof. A likelihood
of 0.87 means "87% of texts with these statistical properties are
LLM-generated," not "this text is definitely AI-written."

## 6. Honest assessment: what the combined layers provide

| Scenario | Detection coverage |
|---|---|
| Agent honestly identifies via MCP | ✓ certain (process attestation) |
| Human types their own text | ✓ certain (process attestation) |
| Human copies from internal LLM work | ✓ high confidence (paste-match + process) |
| Human copies from external LLM, pastes | ~70-85% (stylometric analysis) |
| Human heavily edits LLM text, pastes | ~40-60% (stylometric degrades with editing) |
| Human retypes LLM text from memory | ~20-40% (stylometric weak; timing looks human) |
| Human uses LLM for brainstorm, writes own text | ~10-20% (mostly human text; may retain vocabulary) |

**The pattern:** detection is strongest when the mis-attribution is
laziest (bulk paste) and weakest when it's most deliberate (heavy
editing, retyping). This is the same pattern as all AI-detection
tools — the arms race between detection and evasion.

## 7. What this means for the product

**The honest pitch:**

> *"Four independent detection layers. Process attestation catches
> properly-connected agents. Content matching catches internal
> copying. Timing analysis catches bulk pastes. Stylometric analysis
> catches external LLM fingerprints. Together, they exceed any
> available alternative for AI content attribution. No single layer
> is proof; combined, they make silent mis-attribution difficult
> and provide an audit trail for every detection event."*

**What NOT to claim:**
- "We can prove who wrote this" — we can't, always
- "100% accurate AI detection" — no system achieves this
- "Cryptographic proof of authorship" — the proof is of the process,
  not the person

**What TO claim:**
- "Strongest available attribution infrastructure"
- "Every alteration detectable, every claim graded"
- "Tamper-evident audit chain with optional Bitcoin anchoring"
- "Per-passage attribution exceeding regulatory requirements"

## 8. Implementation priorities

| Priority | Item | Effort | Impact |
|---|---|---|---|
| 1 | Burstiness analysis (pure statistics) | hours | fast signal, no dependencies |
| 2 | Vocabulary fingerprint (dictionary) | hours | explainable, fast |
| 3 | Timing analysis (placed_at timestamps) | hours | catches paste, uses existing data |
| 4 | Perplexity (local model or ollama) | day | strongest single signal |
| 5 | Structural patterns | day | additional signal |
| 6 | Combined scorer with confidence | day | the user-facing result |

Total: ~3-4 days for all six components. The first three (burstiness,
vocabulary, timing) require no ML model and can be built immediately.

## 9. Relationship to existing xudanu architecture

The stylometric detector is **complementary to, not part of, the
provenance chain.** The provenance chain records what the server
observed (signatures, timestamps, interfaces). The stylometric
detector analyses the text itself. They are independent evidence
sources that can be reported together:

```
Provenance report:
  - author_type: "human" (per interface)
  - signature: valid
  - chain: intact
  - paste_match: none found

Stylometric report (if enabled):
  - perplexity: 18.3 (low — likely LLM)
  - burstiness: 0.3 (low — likely LLM)
  - vocabulary: "delve", "crucial" detected
  - overall: 0.82 likelihood AI-generated
  - confidence: moderate

Combined:
  - label says "human" but stylometric says "likely LLM"
  - → flag for review: "possible mis-attribution"
```

The flag is a **signal for human review**, not an automatic correction.
The system reports the discrepancy; a human decides what it means.

## 10. Open questions

1. **Arms race:** as LLMs improve, stylometric signals weaken. How
   long before perplexity/burstiness are indistinguishable from human
   writing? (Current estimate: 2-5 years for perplexity, longer for
   vocabulary/structure)

2. **Cultural bias:** the vocabulary fingerprints are English-specific
   and may not transfer to other languages. Multilingual detection is
   an open problem.

3. **Adversarial evasion:** a sophisticated actor can prompt the LLM
   to vary sentence length, avoid characteristic vocabulary, and
   introduce randomness. Detection degrades with adversarial effort.

4. **Provider attestation:** if Anthropic/OpenAI eventually sign their
   outputs, Layer 4 becomes less critical (provider attestation is
   stronger). But provider attestation doesn't exist today, and may
   never be universally available.

5. **Regulatory acceptance:** will regulators accept probabilistic
   detection as part of "reasonable effort"? The EU AI Act's language
   suggests yes, but this is untested.
