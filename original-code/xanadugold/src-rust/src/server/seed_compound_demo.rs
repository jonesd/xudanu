//! FR-55 T5: the compound-documents demo — seedable into any server
//! with one flag (`--seed-compound-demo`), the same pattern as the
//! links demo. Creates two source works plus one compound essay
//! that quotes them, demonstrating the keyed-segment story:
//! live-edit survival, drift honesty, exact follow-back.
//! The compound is self-referential — an essay about transclusion
//! that IS transclusion.

use crate::edition::compound::{CompoundEdition, CompoundElement};
use crate::edition::Edition;
use crate::server::server::Server;
use crate::server::SessionId;

const SOURCE_A: &str = "Gold Interview Notes \u{2014} fragments from a conversation\n\nThe interviewer asked about the deepest difference between the web and what we were building. Ted kept returning to the idea that the deep structure of literature is tumblered \u{2014} connections go both ways, and nothing is ever fully severed. What he meant was that in a properly-built hypertext, removal of a connection is itself a visible act.\n\nRoger talked about the enfilade \u{2014} the tree that carries its own identity at every node. You compare two subtrees in one operation. You never scan the whole document to find out if something changed.\n\nThe conversation drifted to provenance. Who wrote this sentence? Can you prove it? The answer, in the old system, was structural: every character carried their author's signature. Not metadata bolted on afterwards \u{2014} identity at the point of creation.\n\nThe web gave us one-way links. We wanted two-way connection. The web gave us copy-paste quotation. We wanted live transclusion. The web gave us page views. We wanted transpointing windows.";

const SOURCE_B: &str = "Technical Design Notes \u{2014} the enfilade pays rent\n\nThe measured numbers from the crum-based comparison work:\n\nIdentical editions at one hundred thousand lines diff in three microseconds. A single root-crum comparison \u{2014} no tree walk, no scan.\n\nEdits scale with divergence, not size. One edit in a hundred-thousand-line document costs four hundred microseconds. The cost of a diff is proportional to what changed, not to how big the document is.\n\nSpan keys are tumbler-stable addresses assigned at content creation. They never mutate \u{2014} offsets shift on every edit, keys do not. This is what makes compound documents reliable.\n\nThe lesson: the data structure is not an implementation detail. It is the product.";

const COMPOUND_TEXT: &str = "The Connected Document\nAn essay about transclusion, built from transclusion.\n\nThis document is not what it appears to be. It looks like a normal essay. But every quotation in it is a live connection to another document. When those documents change, this one knows.\n\nEdit the sources. Come back. Watch what happens.\n\n\u{00A7}1. The Old Idea\n\nThe insight predates the web by decades. ";

const COMPOUND_S1_END: &str = "\n\nThat was the design: connection as a first-class structural fact.\n\n\u{00A7}2. The Modern Proof\n\nWe measure by benchmark. ";

const COMPOUND_S2_END: &str = "\n\nThe numbers are not approximations \u{2014} they are what Gold's team would have predicted from the algebra alone.\n\n\u{00A7}3. What It Means\n\nThe practical consequence is trust. ";

const COMPOUND_FOOTER: &str = "\n\nA quotation that cannot break is not a quotation. It is a connection.\n\n\u{00A7}4. Try It\n\nOpen 'Gold Interview Notes' and insert text at the very beginning. Then come back here. Nothing will be wrong.\n\nThen rewrite a quoted passage in the source. Come back. The segment will be flagged \u{2014} visible, honest, never silently incorrect.\n\nClick any quotation to follow it back to its exact origin.";

fn find_and_span(text: &str, marker: &str) -> (usize, usize) {
    let i = text.find(marker).unwrap_or_else(|| {
        panic!(
            "compound demo: marker not found: {}",
            &marker[..marker.len().min(40)]
        )
    });
    (i, i + marker.len())
}

pub fn seed_compound_demo(server: &mut Server) {
    let sid = server.connect();
    if server.login_public(sid).is_err() {
        tracing::warn!("[seed-compound-demo] public login refused \u{2014} skipping");
        return;
    }

    let marker = "The Connected Document";
    let already = server
        .works
        .values()
        .any(|ws| ws.cached_title().contains(marker));
    if already {
        tracing::info!("[seed-compound-demo] already seeded \u{2014} skipping");
        return;
    }

    let src_a = make_work(server, sid, SOURCE_A, "Gold Interview Notes");
    let src_b = make_work(server, sid, SOURCE_B, "Technical Design Notes");

    let (qa1_s, qa1_e) = find_and_span(SOURCE_A, "the deep structure of literature is tumblered");
    let (qa2_s, qa2_e) =
        find_and_span(SOURCE_A, "every character carried their author's signature");
    let (qb1_s, qb1_e) = find_and_span(
        SOURCE_B,
        "The cost of a diff is proportional to what changed",
    );
    let (qb2_s, qb2_e) = find_and_span(SOURCE_B, "They never mutate");

    let compound_work = make_work(server, sid, COMPOUND_TEXT, "The Connected Document");

    let mut ed = CompoundEdition::empty();
    ed.push(CompoundElement::text(COMPOUND_TEXT));
    ed.push(CompoundElement::span(src_a, qa1_s, qa1_e));
    ed.push(CompoundElement::text(COMPOUND_S1_END));
    ed.push(CompoundElement::span(src_b, qb1_s, qb1_e));
    ed.push(CompoundElement::text(" \u{2014} and \u{2014} "));
    ed.push(CompoundElement::span(src_a, qa2_s, qa2_e));
    ed.push(CompoundElement::text(COMPOUND_S2_END));
    ed.push(CompoundElement::span(src_b, qb2_s, qb2_e));
    ed.push(CompoundElement::text(COMPOUND_FOOTER));

    server
        .set_compound_edition(compound_work, ed, sid)
        .expect("demo: set_compound_edition");

    tracing::info!(
        "[seed-compound-demo] seeded: 'The Connected Document' + 'Gold Interview Notes' + 'Technical Design Notes' \u{2014} {} segments",
        server.compound_segments.get(&compound_work).map(|s| s.len()).unwrap_or(0),
    );
}

fn make_work(server: &mut Server, sid: SessionId, text: &str, title: &str) -> u64 {
    let id = server
        .create_work(sid, Edition::from_text(text))
        .expect("demo: work_create");
    server.set_work_title(id, title.to_string());
    id
}
