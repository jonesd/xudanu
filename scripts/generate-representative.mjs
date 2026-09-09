#!/usr/bin/env node
// generate-representative.mjs — seed genre-true corpora for H(G)
// profiling. Four types, each producing a characteristic link/
// transclusion/revision structure (see docs/dev/representative-corpora.md).
//
// Usage: node generate-representative.mjs <corpus-type> [ws-url]
//   corpus-type: seminar | debate | edition | vault
//   default ws-url: ws://127.0.0.1:8081/xudanu?format=json
//
// Each corpus is DETERMINISTIC (fixed content, no RNG) so profiles
// are reproducible. All content is original prose.
import WebSocket from "ws";

const TYPE = process.argv[2];
const URL = process.argv[3] || "ws://127.0.0.1:8081/xudanu?format=json";
const ORIGIN = "http://127.0.0.1:8081";

if (!["seminar", "debate", "edition", "vault"].includes(TYPE)) {
  console.error("Usage: generate-representative.mjs <seminar|debate|edition|vault> [ws-url]");
  process.exit(1);
}

const ws = new WebSocket(URL, { headers: { origin: ORIGIN } });
let nextId = 1;
const pending = new Map();

function request(op, payload) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 30000);
    pending.set(id, { resolve, reject, timeout: t, op });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}
function value(resp) {
  let v = resp && typeof resp === "object" && "value" in resp ? resp.value : resp;
  while (v && typeof v === "object" && typeof v.type === "string" && "value" in v) v = v.value;
  return v;
}

ws.on("message", (data) => {
  try {
    let s = data.toString();
    const b = s.indexOf("{");
    if (b > 0) s = s.slice(b);
    const frame = JSON.parse(s);
    if (frame.type === "response") {
      const p = pending.get(frame.id);
      if (p) { clearTimeout(p.timeout); pending.delete(frame.id); p.resolve(frame); }
    } else if (frame.type === "error") {
      const p = pending.get(frame.id);
      if (p) { clearTimeout(p.timeout); pending.delete(frame.id); p.reject(new Error(`${p.op}: ${frame.message}`)); }
    }
  } catch { /* ignore */ }
});
ws.on("close", () => { for (const p of pending.values()) { clearTimeout(p.timeout); p.reject(new Error("socket closed")); } pending.clear(); });

async function mkWork(server, sid, title, text) {
  const w = value(await request("work_create", { edition: { text } }));
  console.log(`  work ${title} = ${w}`);
  return w;
}

async function link(server, sid, type, from, to, fromText, toText) {
  const fi = fromText ? fromText.indexOf(fromText.trim().split(/\s+/).slice(0, 6).join(" ")) : 0;
  const ti = toText ? toText.indexOf(toText.trim().split(/\s+/).slice(0, 6).join(" ")) : 0;
  const r = value(await request("link_create", {
    origin: from, destination: to,
    origin_ref: { kind: "single", work_context: from, excerpt: (fromText || "").slice(0, 80), start_position: Math.max(0, fi), end_position: Math.max(0, fi) + Math.min(40, (fromText || "").length) },
    destination_ref: { kind: "single", work_context: to, excerpt: (toText || "").slice(0, 80), start_position: Math.max(0, ti), end_position: Math.max(0, ti) + Math.min(40, (toText || "").length) },
    types: [type],
  }));
  return r;
}

async function transclude(server, sid, workId, position, sourceId, sourceText, startMarker, endMarker) {
  const si = sourceText.indexOf(startMarker);
  const ei = endMarker ? sourceText.indexOf(endMarker, si) : si + startMarker.length;
  await request("element_insert", {
    work_id: workId, position,
    element: { type: "transclusion", transclusion_source: sourceId, transclusion_start: Math.max(0, si), transclusion_end: Math.max(si + 10, ei) },
  });
}

async function revise(server, sid, workId, text) {
  await request("work_grab", { work_id: workId }).catch(() => {});
  await request("work_revise", { work_id: workId, edition: { text } });
}

// ── ORIGINAL CONTENT LIBRARY ─────────────────────────────────────────
// Every work below is original prose, written for this generator.
// No third-party content. Themes chosen to exercise different
// link structures naturally.

const SEMINAR_ATOMS = [
  ["Spatial Memory in Navigation", "Spatial memory operates on landmark-based and grid-based systems simultaneously. Landmarks provide anchor points for orientation, while grid cells in the entorhinal cortex encode metric distances. The interplay allows flexible navigation even when familiar landmarks are removed or displaced."],
  ["The Role of Boundary Cells", "Boundary cells fire when the animal is near environmental edges, providing a geometric frame independent of landmarks. Unlike place cells, they remap predictably when boundaries move. This suggests they encode the container rather than the contents."],
  ["Cognitive Maps and Flexibility", "Tolman's cognitive map hypothesis proposed that learning creates internal spatial models rather than stimulus-response chains. Modern evidence from replay studies supports this: the hippocampus simulates novel shortcut routes during rest, implying map-like rather than route-like representations."],
  ["Replay and Consolidation", "During sharp-wave ripples in slow-wave sleep, the hippocampus replays recent experience in compressed sequences. Forward replay consolidates memories; reverse replay may serve credit assignment. Both operate on the same neural substrate as navigation, suggesting shared machinery."],
  ["Grid Cell Arithmetic", "Grid cells form hexagonal firing fields at multiple scales. The theoretical minimum for 2D position encoding is three grids; the brain uses more, providing redundancy. The hexagonal lattice may be an optimal packing solution rather than a biological accident."],
  ["Landmark Stability and Remapping", "Place fields can remap when environmental cues change. The threshold for remapping is context-dependent: small changes cause rate remapping, large changes cause global remapping. This graded response suggests place cells integrate multiple reference frames."],
  ["Navigation Without Vision", "Blind navigers use vestibular and proprioceptive inputs to update position estimates. Human echolocation demonstrates that spatial maps can be built from non-visual inputs. The grid cell system appears modality-agnostic, encoding position from whatever sensory stream is available."],
  ["Time Cells in the Hippocampus", "Time cells fire in sequence during delay periods, providing temporal ordering independent of spatial location. They interleave with place cells in the same neural population. This suggests a unified spatiotemporal code rather than separate maps for space and time."],
  ["Predictive Coding and Navigation", "The brain may generate predictions about upcoming sensory input during navigation. When predictions fail (surprise), prediction errors drive model updates. This framework unifies spatial learning with general perceptual inference."],
  ["Development of Spatial Cognition", "Spatial abilities develop in stages: egocentric navigation precedes allocentric. Children under four rely on landmark-based strategies; grid-cell-like representations emerge later. This developmental trajectory mirrors the evolutionary hierarchy of spatial systems."],
];

const SEMINAR_HUBS = [
  ["Hub: Spatial Representation", "This hub collects notes on how the brain represents spatial information. The core tension is between map-like and route-like representations. The atoms below address different aspects of this question from cellular, behavioural, and computational perspectives."],
  ["Hub: Memory Consolidation", "Notes on how spatial memories are stabilized over time. Replay is the central mechanism. The relationship between waking experience and sleep-dependent consolidation is a recurring theme."],
  ["Hub: Predictive Models", "The hypothesis that navigation is a special case of predictive inference. If the brain builds generative models of its environment, spatial maps are model parameters rather than separate modules."],
];

const SEMINAR_TRAILS = [
  ["Trail: From Grid Cells to Cognitive Maps", "This trail sequences the seminar atoms into an argument: grid cells provide the metric substrate, place cells provide the anchor, boundary cells provide the container, and replay consolidates the map into a flexible internal model."],
  ["Trail: Predictive Navigation", "An alternative reading: navigation is prediction, not representation. The trail traces the argument from Tolman through replay studies to predictive coding."],
];

const DEBATE_POSITIONS = [
  ["Position A: Grids Are Primary", "The hexagonal firing of grid cells is not epiphenomenal. The lattice structure provides an efficient basis for position encoding, and its presence across species suggests convergent evolution. Grid cells are the computational primitive from which place cells and boundary cells derive.\n\nEvidence: the periodicity of grid fields matches the theoretical optimum for 2D encoding; grid scale increases dorsally in discrete steps; grid disruption impairs path integration before affecting landmark navigation.\n\nCounter-argument acknowledged: place cells can exist without grid input in some preparations. However, these may be vestigial or driven by alternative metric sources.\n\nConclusion: grids are the metric engine; place and boundary cells provide the content."],
  ["Position B: Boundaries Are Primary", "The brain's primary spatial reference is the geometric boundary, not an abstract metric grid. Boundary cells are the earliest developing spatial neurons, present before grid cells mature. They are also the most robust to environmental manipulation.\n\nEvidence: boundary-selective firing appears in pre-navigation animals; boundary shifts cause immediate place-field remapping while grid fields are slower to update; lesions of boundary-responsive regions impair navigation more than grid-specific regions.\n\nCounter-argument acknowledged: boundary cells alone cannot support path integration without a metric component.\n\nConclusion: boundaries provide the structural frame; grids calibrate the metric but are secondary."],
  ["Position C: Neither — Predictive Models", "The debate between grids and boundaries presupposes modular decomposition. A third position: navigation is a prediction problem, and what we call grids and boundaries are emergent properties of a predictive model, not dedicated modules.\n\nEvidence: grid-like responses appear in trained recurrent networks without spatial priors; place fields form in artificial environments with novel geometry; the same neural populations encode non-spatial sequences.\n\nConclusion: the modularity debate is a category error. The brain does not have a spatial module; it has a general inference engine that learns spatial structure."],
];

const DEBATE_EVIDENCE = [
  ["E: Hafting et al. Grid Cell Study", "Hafting and colleagues recorded from the medial entorhinal cortex in freely moving rats. They found neurons with hexagonal firing fields at multiple spatial scales. The lattice was invariant to environment changes, suggesting an intrinsic metric."],
  ["E: Lever et al. Boundary Cell Study", "Lever and colleagues demonstrated that boundary cells in the subiculum respond to environmental edges. When a boundary was moved, place fields shifted predictably. When a new boundary was inserted, new place fields formed near it."],
  ["E: Tolman's Cognitive Map", "Tolman's classic maze experiments showed that rats could take novel shortcuts, implying an internal spatial map rather than a chain of learned turns. The finding was controversial in its time but is now foundational."],
  ["E: Replay Studies", "Wilson and McNaughton showed that hippocampal place cells replay their daytime firing sequences during sleep. Diba and Buzsáki later demonstrated both forward and reverse replay. This suggests active consolidation of spatial memories."],
  ["E: Banino et al. Vector Navigation", "Banino and colleagues trained a recurrent network to navigate. Grid-like firing patterns emerged spontaneously in the network's representations, suggesting that hexagonal encoding is a natural solution to the navigation problem, not a hardwired biological module."],
  ["E: Stensola et al. Grid Module Organization", "Stensola and colleagues showed that grid cells are organized into discrete modules with distinct scales. The relationship between adjacent scales follows a geometric progression, suggesting a hierarchical encoding scheme."],
  ["E: Developmental Timeline", "Wills and colleagues showed that place cells are functional before grid cells mature. This developmental sequence challenges the view that grids drive place cell formation."],
  ["E: Predictive Network Evidence", "Multiple groups have shown that predictive learning in recurrent networks produces spatial representations resembling place and grid cells. These results support the emergent-model hypothesis."],
];

const EDITION_SOURCE = `The Lighthouse Keeper's Log

Chapter 1: The Northern Chain

The northern chain runs from the sandbar light to the broken tower at Cape Verity. Eleven stations, each manned in rotation by a crew that reads weather in the behavior of birds. This log is their working document, amended in the margins over nine winters.

The lamp is a contract with the horizon. Trimmed high, it promises a fixed point to anything afloat. Trimmed low in fog, it becomes a rumor of itself. Keepers argue about the correct trim the way other trades argue about tools.

Chapter 2: Fuel Discipline

A station holds forty days of oil at winter burn. The logbook is a ledger of small decisions: half-light on clear nights, full burn when the barometer falls, and the terrible arithmetic of the last week. Every story the crew tells about running dark ends with the relief boat arriving on day forty-one.

Chapter 3: The Signal Tower

The tower at Cape Verity leans two degrees to the east. The chart corrects for this; the birds do not. From its gallery, on the four clear days of a northern February, you can see the whole chain at once: eleven lights in a gentle arc, each one a different keeper's judgment of the same night.

Chapter 4: Letters and Duplicates

Each station keeps a duplicate log, and the relief boat carries the copies. The history of every night exists twice, on different shelves, in different handwriting. When a log is lost, the duplicate is transcribed back by hand — a week of copying, done gladly.

Chapter 5: The Lean

The lean has become a landmark. Sailors take a bearing on the lean itself. Two degrees of imperfection, kept faithfully for thirty years, is now a navigational truth.`;

const EDITION_TRANS_A = `The Lighthouse Keeper's Log — Translation A

This translation preserves the original paragraph structure and aims for formal accuracy. The translator's note on Chapter 3 is appended below.`;

const EDITION_TRANS_B = `The Lighthouse Keeper's Log — Translation B

This translation prioritizes readability and natural English idiom over formal equivalence. The translator's note on Chapter 4 is appended below.`;

const EDITION_COMMENTARY = [
  ["Commentary: The Lamp as Contract", "The metaphor in Chapter 1 is precise: the lamp is not a convenience but a covenant. The keeper's obligation is not to be visible but to be predictable. This reading connects to the maritime law concept of a 'charted light' — one whose position, character, and period are published. The keeper who varies the trim is in breach of a published contract."],
  ["Commentary: Fuel as Moral Arithmetic", "Chapter 2's 'terrible arithmetic' is not metaphor but ethics. The choice between visibility and endurance is the choice between serving the present sailor and serving the future one. The fact that every story of running dark ends with rescue on day forty-one is the narrator's way of saying: the gamble always loses eventually."],
  ["Commentary: The Lean as Truth", "Chapter 5 is the philosophical heart of the work. The lean, an imperfection, becomes more reliable than a perfect tower would be, precisely because it is unique. Two degrees of deviation from the ideal is more identifiable than zero degrees. This is an argument for the value of imperfection in systems design."],
];

const VAULT_DAILIES = [
  ["Day 01: Project Kickoff", "Defined the scope: build a spatial navigation model using grid cell principles. Read three foundational papers. The central question is whether hexagonal encoding is a biological accident or a mathematical inevitability."],
  ["Day 02: Literature Survey Begins", "Indexed Hafting et al. and Stensola et al. The modular organization of grid scales is the most striking finding. Each module operates at a different resolution, like a multi-scale image pyramid."],
  ["Day 03: Boundary Cell Surprise", "The Lever paper challenges the grid-first assumption. Boundary cells appear developmentally earlier. If they provide the frame, grids calibrate it rather than create it."],
  ["Day 04: Predictive Model Hypothesis", "The Banino paper is the turning point. Grid-like responses emerge in trained recurrent networks. This suggests hexagonal encoding is a natural solution, not a biological hardwire. Need to read more about predictive coding."],
  ["Day 05: Tolman Revisited", "Re-read Tolman's 1948 paper. The cognitive map hypothesis was radical for its time. The key insight: animals can take novel shortcuts, implying map-like rather than route-like representations."],
  ["Day 06: Replay and Consolidation", "Replay studies show the hippocampus simulates routes during rest. Forward and reverse replay serve different functions: consolidation and credit assignment. This is active computation, not passive replay."],
  ["Day 07: Weekly Synthesis", "Synthesized the week's reading. The three-position structure emerged: grids-primary, boundaries-primary, predictive-models. Each has evidence. None is definitively resolved. The predictive position is the most interesting because it subsumes the others."],
  ["Day 08: Developmental Evidence", "Wills et al. show place cells before grid cells. This is a serious challenge to grid-primacy. However, it may mean the metric system develops later than the structural one — not that grids are unnecessary."],
  ["Day 09: Modelling Discussion", "Discussed implementation with the team. If we build a predictive model, the grid patterns should emerge from training rather than being hardwired. This is a testable prediction."],
  ["Day 10: The Boundary Problem", "Realized that boundary cells may encode something more fundamental than edges: they encode containment. A boundary is not just a wall; it is the edge of the representable space."],
  ["Day 11: Time Cells", "Time cells fire in sequence during delays, interleaved with place cells. This suggests a unified spatiotemporal code. Navigation is not purely spatial; it is temporal as well."],
  ["Day 12: Weekly Synthesis 2", "Week 2 synthesis: the predictive framework is winning. Grid cells, place cells, boundary cells, and time cells can all be understood as emergent properties of a system that learns to predict its sensory inputs."],
  ["Day 13: Blind Navigation", "The modality-agnostic finding is important. Spatial maps can be built from vestibular, proprioceptive, or even echolocation inputs. The grid system doesn't care about the modality."],
  ["Day 14: Draft Outline", "Started the project outline as a trail. Five sections: introduction, three positions, synthesis. The synthesis will argue for the predictive model position using evidence from all three."],
  ["Day 15: Literature Complete", "The literature review is complete. Eight evidence works indexed and linked. Three positions drafted. The trail sequences them into an argument."],
  ["Day 16: Writing Begins", "Started the paper. The introduction frames the question. The three positions are sections 2-4. Section 5 is the synthesis and prediction."],
  ["Day 17: AI-Assisted Section", "Used AI to help draft the section on predictive coding. The suggestion to connect Tolman's cognitive map to modern predictive frameworks was valuable. The section is stronger for the collaboration."],
  ["Day 18: Revision Day", "Revised all sections. The argument is tighter. The three-position structure works well: each position is stated fairly, evidence is presented, and the synthesis earns its conclusion."],
  ["Day 19: Final Synthesis", "The final section connects back to the opening. The lamp as contract (from a reading earlier in the month) becomes the metaphor for what the brain does: it makes a contract with the future by building a model."],
  ["Day 20: Retrospective", "Project complete. Twenty days of daily notes, eight evidence works, three position papers, one synthesis. The trail from kickoff to conclusion is clear. The AI-assisted notes are marked and distinguishable from the human-authored ones."],
];

const VAULT_SYNTHESIS = [
  ["Synthesis: The Three-Position Debate", "This synthesis work collects the strongest evidence for each position and reveals where they agree and disagree. All three positions accept the empirical findings; they differ in interpretation."],
  ["Synthesis: Predictive Framework Wins", "This work argues that the predictive model position subsumes the other two. Grids emerge from prediction; boundaries emerge from prediction; the modularity debate is a category error."],
  ["Synthesis: Implementation Directions", "Practical notes on building a navigation system. If the predictive hypothesis is correct, we should train a recurrent model and expect grid-like representations to emerge spontaneously."],
  ["Synthesis: Open Questions", "What this project did not resolve. The relationship between grid cells and conscious spatial awareness. Whether the predictive framework extends to social navigation. What happens to the model during sleep."],
];

// ── CORPUS GENERATORS ────────────────────────────────────────────────

async function genSeminar() {
  console.log("=== Research Seminar (Zettelkasten) ===");
  const sid = value(await request("session_connect"));
  await request("session_login_public");

  const atoms = [];
  for (const [title, body] of SEMINAR_ATOMS) {
    const id = await mkWork(null, sid, title, body);
    atoms.push({ id, title, body });
  }

  const hubs = [];
  for (const [title, body] of SEMINAR_HUBS) {
    const id = await mkWork(null, sid, title, body);
    hubs.push({ id, title, body });
  }

  const trails = [];
  for (const [title, body] of SEMINAR_TRAILS) {
    const id = await mkWork(null, sid, title, body);
    trails.push({ id, title, body });
  }

  // Links: atoms -> hubs (Reference), hubs -> trails (See Also)
  // atoms -> atoms where related (See Also)
  const hubAssignments = [
    [0, 1, 3, 4, 5, 8, 9],  // Spatial Representation
    [0, 3, 5, 6],             // Memory Consolidation  
    [0, 3, 8],                // Predictive Models
  ];
  for (let h = 0; h < hubs.length; h++) {
    for (const ai of hubAssignments[h]) {
      await link(null, sid, 2, atoms[ai].id, hubs[h].id, atoms[ai].body, hubs[h].body);
    }
  }
  for (const t of trails) {
    await link(null, sid, 5, hubs[0].id, t.id, hubs[0].body, t.body);
  }
  // a few cross-atom links
  await link(null, sid, 5, atoms[0].id, atoms[4].id, atoms[0].body, atoms[4].body);
  await link(null, sid, 5, atoms[1].id, atoms[5].id, atoms[1].body, atoms[5].body);
  await link(null, sid, 5, atoms[3].id, atoms[7].id, atoms[3].body, atoms[7].body);

  // Trails revised (the MOC evolves)
  await revise(null, sid, trails[0].id, trails[0].body + "\n\nRevised: added the time-cell connection after reviewing Day 11 notes.");
  await revise(null, sid, trails[1].id, trails[1].body + "\n\nRevised: strengthened the predictive argument after the Banino evidence.");

  // One transclusion: a trail includes an atom's definition
  await transclude(null, sid, trails[0].id, 50, atoms[4].id, atoms[4].body, "Grid cells form", "The hexagonal lattice");

  console.log(`Seminar: ${atoms.length} atoms, ${hubs.length} hubs, ${trails.length} trails`);
  return { atoms, hubs, trails };
}

async function genDebate() {
  console.log("=== Policy Debate (Legal/Compliance) ===");
  const sid = value(await request("session_connect"));
  await request("session_login_public");

  const positions = [];
  for (const [title, body] of DEBATE_POSITIONS) {
    const id = await mkWork(null, sid, title, body);
    positions.push({ id, title, body });
  }

  const evidence = [];
  for (const [title, body] of DEBATE_EVIDENCE) {
    const id = await mkWork(null, sid, title, body);
    evidence.push({ id, title, body });
  }

  // Disagreement links: position <-> position
  await link(null, sid, 3, positions[0].id, positions[1].id, positions[0].body, positions[1].body);
  await link(null, sid, 3, positions[1].id, positions[2].id, positions[1].body, positions[2].body);
  await link(null, sid, 3, positions[0].id, positions[2].id, positions[0].body, positions[2].body);

  // Quotation links: position -> evidence
  const evidenceMap = [
    [0, 1, 3, 5], // position A cites these
    [1, 2, 6],    // position B cites these
    [4, 7, 3],    // position C cites these
  ];
  for (let p = 0; p < positions.length; p++) {
    for (const ei of evidenceMap[p]) {
      await link(null, sid, 4, positions[p].id, evidence[ei].id, positions[p].body, evidence[ei].body);
    }
  }

  // Comment links: evidence -> evidence (supporting/contradicting)
  await link(null, sid, 1, evidence[0].id, evidence[5].id, evidence[0].body, evidence[5].body);
  await link(null, sid, 1, evidence[1].id, evidence[6].id, evidence[1].body, evidence[6].body);
  await link(null, sid, 1, evidence[4].id, evidence[7].id, evidence[4].body, evidence[7].body);

  // Transclusions: positions include evidence passages by reference
  await transclude(null, sid, positions[0].id, 100, evidence[0].id, evidence[0].body, "Hafting and colleagues", "hexagonal firing fields");
  await transclude(null, sid, positions[1].id, 100, evidence[1].id, evidence[1].body, "Lever and colleagues", "predictably");
  await transclude(null, sid, positions[2].id, 100, evidence[4].id, evidence[4].body, "Banino and colleagues", "spontaneously");

  // Positions revised
  await revise(null, sid, positions[0].id, positions[0].body + "\n\nRevised: acknowledged the developmental evidence more fully.");
  await revise(null, sid, positions[1].id, positions[1].body + "\n\nRevised: strengthened the boundary-cell priority claim.");

  console.log(`Debate: ${positions.length} positions, ${evidence.length} evidence works`);
  return { positions, evidence };
}

async function genEdition() {
  console.log("=== Edition & Translation (Literary/Scholarly) ===");
  const sid = value(await request("session_connect"));
  await request("session_login_public");

  const source = await mkWork(null, sid, "The Lighthouse Keeper's Log", EDITION_SOURCE);

  const transA = await mkWork(null, sid, "Log — Translation A", EDITION_TRANS_A);
  const transB = await mkWork(null, sid, "Log — Translation B", EDITION_TRANS_B);

  const commentaries = [];
  for (const [title, body] of EDITION_COMMENTARY) {
    const id = await mkWork(null, sid, title, body);
    commentaries.push({ id, title, body });
  }

  // Translation alignment transclusions (dense θ)
  await transclude(null, sid, transA, 80, source, EDITION_SOURCE, "The northern chain runs", "nine winters");
  await transclude(null, sid, transA, 200, source, EDITION_SOURCE, "A station holds", "day forty-one");
  await transclude(null, sid, transB, 80, source, EDITION_SOURCE, "The northern chain runs", "nine winters");
  await transclude(null, sid, transB, 200, source, EDITION_SOURCE, "The tower at Cape Verity", "the same night");

  // Commentary → source (Quotation)
  for (const c of commentaries) {
    await link(null, sid, 4, c.id, source, c.body, EDITION_SOURCE);
  }

  // Translation ↔ translation (See Also)
  await link(null, sid, 5, transA, transB, EDITION_TRANS_A, EDITION_TRANS_B);

  // Translations revised
  await revise(null, sid, transA, EDITION_TRANS_A + "\n\nTranslator's revision: refined the 'contract' metaphor in Ch.1.");
  await revise(null, sid, transB, EDITION_TRANS_B + "\n\nTranslator's revision: clarified the 'terrible arithmetic' in Ch.2.");

  console.log(`Edition: 1 source, 2 translations, ${commentaries.length} commentaries`);
  return { source, transA, transB, commentaries };
}

async function genVault() {
  console.log("=== AI-Augmented Vault (Millard-style) ===");
  const sid = value(await request("session_connect"));
  await request("session_login_public");

  const dailies = [];
  for (const [title, body] of VAULT_DAILIES) {
    const id = await mkWork(null, sid, title, body);
    dailies.push({ id, title, body });
  }

  const syntheses = [];
  for (const [title, body] of VAULT_SYNTHESIS) {
    const id = await mkWork(null, sid, title, body);
    syntheses.push({ id, title, body });
  }

  // Links: daily → synthesis (Reference)
  const synthMap = [
    [0, 1, 2, 3, 4, 5, 6],         // Three-Position Debate
    [3, 4, 6, 10, 11, 12, 14],      // Predictive Framework Wins
    [8, 9, 12, 13],                  // Implementation Directions
    [14, 15, 16, 17, 18, 19],       // Open Questions
  ];
  for (let s = 0; s < syntheses.length; s++) {
    for (const di of synthMap[s]) {
      await link(null, sid, 2, dailies[di].id, syntheses[s].id, dailies[di].body, syntheses[s].body);
    }
  }

  // Comment links: daily → daily (AI proposals, human notes)
  await link(null, sid, 1, dailies[3].id, dailies[4].id, dailies[3].body, dailies[4].body);
  await link(null, sid, 1, dailies[6].id, dailies[7].id, dailies[6].body, dailies[7].body);
  await link(null, sid, 1, dailies[11].id, dailies[12].id, dailies[11].body, dailies[12].body);

  // Transclusions: synthesis works include daily passages
  await transclude(null, sid, syntheses[0].id, 60, dailies[6].id, dailies[6].body, "Synthesized the week's reading", "None is definitively resolved");
  await transclude(null, sid, syntheses[1].id, 60, dailies[11].id, dailies[11].body, "Week 2 synthesis", "predict its sensory inputs");

  // Syntheses heavily revised (the vault evolves)
  for (let i = 0; i < syntheses.length; i++) {
    const extra = `\n\nRevision ${i + 1}: refined after reviewing the full project arc.`;
    await revise(null, sid, syntheses[i].id, syntheses[i].body + extra);
    await revise(null, sid, syntheses[i].id, syntheses[i].body + extra + `\nRevision ${i + 2}: final polish.`);
  }

  console.log(`Vault: ${dailies.length} dailies, ${syntheses.length} syntheses`);
  return { dailies, syntheses };
}

// ── MAIN ─────────────────────────────────────────────────────────────
(async () => {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");
  console.log("connected\n");

  const prefix = `[${TYPE.toUpperCase()}]`;
  switch (TYPE) {
    case "seminar": await genSeminar(); break;
    case "debate": await genDebate(); break;
    case "edition": await genEdition(); break;
    case "vault": await genVault(); break;
  }

  console.log(`\n${prefix} READY — run 'xudanu-server hg-profile' after next checkpoint`);
  ws.close();
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
