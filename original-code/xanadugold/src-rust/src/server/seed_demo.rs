//! FR-40: the built-in links demo — the entire course, playground,
//! gallery works, and companion corpus, seedable into ANY server by
//! one flag (`--seed-links-demo`), no external tooling. Ships with
//! the release binary so end users can recreate the demo over and
//! over: wipe the data dir, restart with the flag, everything
//! returns (the screenshots in docs/links-gallery.md are this data).
//!
//! Ports scripts/demo-links-{course,playground,gallery,seed}.mjs;
//! the .mjs versions remain for development against a running
//! server.

use crate::edition::links::{HyperLink, HyperRef};
use crate::edition::Edition;
use crate::server::server::Server;
use crate::server::SessionId;

fn span_of(text: &str, marker: &str) -> (i64, i64) {
    let i = text
        .find(marker)
        .unwrap_or_else(|| panic!("seed marker not found: {}", &marker[..marker.len().min(24)]));
    (i as i64, (i + marker.len()) as i64)
}

fn ref_at(work: u64, text: &str, marker: &str, excerpt: &str) -> HyperRef {
    let (s, e) = span_of(text, marker);
    // The excerpt rides as the ref's material edition — the honest
    // server-side form; payloads and tooltips read it from there.
    HyperRef::single(Some(Edition::from_text(excerpt)), Some(work), None, None)
        .with_span(Some(s), Some(e))
}

fn make_work(server: &mut Server, sid: SessionId, text: &str) -> u64 {
    server
        .create_work(sid, Edition::from_text(text))
        .expect("demo: work_create")
}

fn make_link(
    server: &mut Server,
    sid: SessionId,
    origin: u64,
    dest: u64,
    origin_ref: HyperRef,
    types: &[u64],
) -> u64 {
    let link = HyperLink::make(
        types.to_vec(),
        origin_ref,
        HyperRef::single(None, Some(dest), None, None),
    );
    server
        .create_link_with_hyperlink_homed(sid, link, None)
        .expect("demo: link_create")
}

fn add_named_end(server: &mut Server, sid: SessionId, link: u64, name: &str, r: HyperRef) {
    server
        .link_add_end(sid, link, name, r)
        .expect("demo: link_add_end");
}

fn gather(server: &mut Server, sid: SessionId, link: u64, end: &str, r: HyperRef) {
    server
        .link_end_add_attachment(sid, link, end, r)
        .expect("demo: gather");
}

fn set_types(server: &mut Server, sid: SessionId, link: u64, types: &[u64]) {
    server
        .link_set_types(sid, link, types.to_vec())
        .expect("demo: link_set_types");
}

const COMPANION: &str = "Lesson Companion\n\nA garden is not a photograph; it is a performance that repeats daily.\n\nThe greenhouse kept the same plants for six years, and regulars began greeting them like staff.\n\nAnyone who says a map is the territory has never maintained either.";

const COMPANION_B: &str = "Second Companion\n\nTide tables are predictions wearing the costume of memories.\n\nThe ferry schedule survived three administrations because nobody dared own it.";

const L1_TEXT: &str = "Links Lesson 1 — The Simple Link\n\nA link is a typed connection between two passages. This sentence is a live one: its underline connects to a line in the Lesson Companion. Single-click the underline to jump there; hover it to see what kind of connection it is.\n\nYour task: Select this sentence and click the Link button, choose any type, and pick Lesson Companion as the target.\n\nWhen your own underline appears, you have made a link. That is the whole primitive — everything fancier is more of these, arranged with intent.";

const L2_TEXT: &str = "Links Lesson 2 — Three Ends on One Connection\n\nThe link you made had two ends. A link can have any number: this sentence is one end of a THREE-ended connection whose other ends live in both companions. One connection, three places.\n\nYour task: Select this sentence, click Link, and on the final step use Additional ends to add a second target — you will have made a three-ended connection.\n\nThree ends is not a chain and not a list — it is one claim involving several places at once, like a comparison. Read every link as a sentence with blanks: the type is the verb, and each end fills one blank.";

const L3_TEXT: &str = "Links Lesson 3 — Gathering Passages into One End\n\nThe step change: one END can itself hold several passages. The three underlined sentences below are not three links — they are THREE PASSAGES OF ONE END. The green chips by the margin read, for example, 2 of 3: passage two of three, nothing more sequential than that. A gathered end fills one blank of the link's sentence JOINTLY, like three quotes filling the same blank.\n\nOne performance that repeats daily, and the schedule nobody dared own.\n\nHover any of the three: gathered passage 1 of 3.\n\nYour task, twice: Select this sentence and click the green Gather button, then choose Your First End. Now select this sentence as well and Gather it into the same end.\n\nWatch the chips appear the moment your second passage lands: your two sentences and this marked one become a set of three.";

const L4_TEXT: &str = "Links Lesson 4 — Commenting on a Connection\n\nPassages can be commented on; so can connections. Open the Links panel on the right and find the row for this lesson's demonstration link — the row lists its type (See Also) and its ends. Press the green comment symbol on that row and write a sentence about the CONNECTION itself.\n\nYour remark becomes a link whose end attaches to the link — a link about a link. It will show in the Links panel as a row carrying a small arrow chip meaning attached-to-a-connection.\n\nNobody expects you to remember the machinery; remember only that anything on the page — passage or connection — can be argued with, and the argument is itself addressable.";

const L5_TEXT: &str = "Links Lesson 5 — Reading the Connected Document\n\nYou now make links; here is how to read one. On this very page: single-click an underline to jump to its far end; hover for the type and, on gathered ends, which passage of how many; put your cursor inside an underlined passage and the bottom bar offers numbered jumps to its siblings; scroll and the green margin chips keep your place (2 of 3 and so on).\n\nIn the Links panel, the two-arrows button on any multi-ended row opens COMPARE: every end side by side, shared passages highlighted — the nearest thing to transpointing windows the web affords.\n\nYour task: press compare on this page's demonstration row, and spend one minute reading both documents at once.";

const SANDBOX_TEXT: &str = "Links Sandbox — Make Your Own\n\nNo tasks here, only recipes in order of ambition.\n\nOne. Select a sentence, press Link, pick a type. The fast path.\n\nTwo. Same, but use Additional ends for a three-way comparison.\n\nThree. Link once, then select other sentences and press Gather to grow that end into a set. Aim for 4 of 4.\n\nFour. In the Links panel, comment on one of your connections.\n\nFive. Compare everything you made. Then delete something and watch what survives.\n\nWhen the shapes feel natural, you have the whole vocabulary: link, gather, describe, comment, compare.";

/// Seed the complete links demo. Idempotent guard: does nothing when
/// a lesson work already exists (works are titled by first line).
pub fn seed_links_demo(server: &mut Server) {
    let sid = server.connect();
    if server.login_public(sid).is_err() {
        tracing::warn!("[seed-links-demo] public login refused (owner-only policy?) — skipping");
        return;
    }
    // Idempotency: lesson 1's title already present -> already seeded.
    let marker = "Links Lesson 1 — The Simple Link";
    let already = server
        .works
        .values()
        .any(|ws| ws.cached_title().contains(marker));
    if already {
        tracing::info!("[seed-links-demo] already seeded — skipping");
        return;
    }

    let companion = make_work(server, sid, COMPANION);
    let companion_b = make_work(server, sid, COMPANION_B);

    // ---- Lesson 1
    let l1 = make_work(server, sid, L1_TEXT);
    let demo1 = ref_at(
        l1,
        L1_TEXT,
        "its underline connects to a line in the Lesson Companion",
        "a live one",
    );
    let link1 = make_link(server, sid, l1, companion, demo1, &[2]);

    // ---- Lesson 2 (three-ended)
    let l2 = make_work(server, sid, L2_TEXT);
    let demo2 = ref_at(
        l2,
        L2_TEXT,
        "this sentence is one end of a THREE-ended connection",
        "one end of three",
    );
    let link2 = make_link(server, sid, l2, companion, demo2, &[5]);
    add_named_end(
        server,
        sid,
        link2,
        "Context",
        ref_at(
            companion_b,
            COMPANION_B,
            "Tide tables are predictions wearing the costume of memories.",
            "tide tables",
        ),
    );

    // ---- Lesson 3 (gathered end + gather target)
    let l3 = make_work(server, sid, L3_TEXT);
    let m1 = "One performance that repeats daily, and the schedule nobody dared own.";
    let m2 = "Hover any of the three: gathered passage 1 of 3.";
    let m3 = "A gathered end fills one blank of the link's sentence JOINTLY";
    let demo3 = ref_at(l3, L3_TEXT, m1, "passage one");
    let link3 = make_link(server, sid, l3, companion, demo3, &[3]);
    gather(
        server,
        sid,
        link3,
        "LeftEnd",
        ref_at(l3, L3_TEXT, m2, "passage two"),
    );
    gather(
        server,
        sid,
        link3,
        "LeftEnd",
        ref_at(l3, L3_TEXT, m3, "passage three"),
    );
    // The reader's gather target.
    let target = make_link(
        server,
        sid,
        l3,
        companion_b,
        ref_at(l3, L3_TEXT, m3, "seed passage"),
        &[4],
    );
    server
        .link_end_add_attachment(
            sid,
            target,
            "Your First End",
            ref_at(l3, L3_TEXT, m2, "seed"),
        )
        .expect("demo: gather target");

    // ---- Lesson 4 (comment target)
    let l4 = make_work(server, sid, L4_TEXT);
    let demo4 = ref_at(
        l4,
        L4_TEXT,
        "this lesson's demonstration link",
        "the demo row",
    );
    let link4 = make_link(server, sid, l4, companion, demo4, &[5]);

    // ---- Lesson 5 (compare row, three-ended)
    let l5 = make_work(server, sid, L5_TEXT);
    let demo5 = ref_at(
        l5,
        L5_TEXT,
        "single-click an underline to jump to its far end",
        "the reading toolkit",
    );
    let link5 = make_link(server, sid, l5, companion, demo5, &[2]);
    add_named_end(
        server,
        sid,
        link5,
        "Context",
        ref_at(
            companion_b,
            COMPANION_B,
            "The ferry schedule survived three administrations",
            "the ferry schedule",
        ),
    );

    let sandbox = make_work(server, sid, SANDBOX_TEXT);

    // ---- The trail, published (visible to every reader).
    let trail = server
        .trail_create(
            sid,
            "The Links Course".to_string(),
            Some("Five short lessons from the simple link to gathered end-sets, then a sandbox. Each lesson carries a live demonstration and one task.".to_string()),
            vec![],
        )
        .expect("demo: trail_create");
    for (work, note) in [
        (l1, "The simple link"),
        (l2, "Three ends"),
        (l3, "Gathering passages"),
        (l4, "Comment on a connection"),
        (l5, "The reading toolkit"),
        (sandbox, "Sandbox"),
    ] {
        server
            .trail_add_stop(sid, trail, work, None, None, Some(note.to_string()), None)
            .expect("demo: trail_add_stop");
    }
    let _ = server.trail_publish(sid, trail);

    tracing::info!(
        "[seed-links-demo] course ready: lessons={:?} sandbox={} trail={} demo links={:?}",
        [l1, l2, l3, l4, l5],
        sandbox,
        trail,
        [link1, link2, link3, link4, link5]
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn seed_creates_course_and_trail() {
        let mut server = Server::new();
        seed_links_demo(&mut server);
        let titles: Vec<String> = server
            .works
            .values()
            .map(|ws| ws.cached_title().to_string())
            .collect();
        for needle in [
            "Links Lesson 1",
            "Links Lesson 2",
            "Links Lesson 3",
            "Links Lesson 4",
            "Links Lesson 5",
            "Links Sandbox",
            "Lesson Companion",
            "Second Companion",
        ] {
            assert!(
                titles.iter().any(|t| t.contains(needle)),
                "seeded corpus missing {}",
                needle
            );
        }
        // The gathered end on lesson 3's demo link: 3 attachments.
        let gathered = server
            .links
            .values()
            .map(|ls| ls.link.clone())
            .find(|l| l.attachment_count("LeftEnd") == 3)
            .expect("a 3-passage gathered end is seeded");
        assert_eq!(gathered.attachment_count("LeftEnd"), 3);
        // The trail exists and is published.
        let trail = server
            .trails
            .values()
            .find(|t| t.name == "The Links Course")
            .expect("course trail seeded");
        assert!(trail.published, "the course trail is published");
        assert_eq!(trail.stops.len(), 6);
    }

    #[test]
    fn seed_is_idempotent() {
        let mut server = Server::new();
        seed_links_demo(&mut server);
        let works_before = server.works.len();
        let links_before = server.links.len();
        seed_links_demo(&mut server);
        assert_eq!(server.works.len(), works_before, "no duplicate works");
        assert_eq!(server.links.len(), links_before, "no duplicate links");
    }
}
