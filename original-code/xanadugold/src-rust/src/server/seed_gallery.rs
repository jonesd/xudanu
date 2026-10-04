//! FR-40 story 6: the Gallery of Unusual Connections — a museum of
//! exotic link structures seeded as real works with real links.
//! Nine exhibit rooms across three wings, a lobby whose floor plan
//! is itself wired with links, a published Curator's Tour trail
//! threading the rooms, and the exhibition gathers layer (a
//! "Gathers" link type binding cover and members into one
//! indicated set). Seedable into ANY server by one flag
//! (`--seed-gallery`), and included in `--seed-links-demo` so the
//! base demo gets everything.
//!
//! Ports scripts/seed-gallery-unusual.mjs and
//! scripts/seed-exhibition-gathers.mjs; the .mjs versions remain
//! for development against a running server.

use crate::edition::links::{HyperLink, HyperRef};
use crate::edition::{Edition, RangeElement};
use crate::server::server::Server;
use crate::server::SessionId;

fn span_of(text: &str, marker: &str) -> (i64, i64) {
    let i = text
        .find(marker)
        .unwrap_or_else(|| panic!("seed marker not found: {}", &marker[..marker.len().min(24)]));
    (i as i64, (i + marker.len()) as i64)
}

fn ref_span(work: u64, excerpt: &str, (s, e): (i64, i64)) -> HyperRef {
    // The excerpt rides as the ref's material edition — the honest
    // server-side form; payloads and tooltips read it from there.
    HyperRef::single(Some(Edition::from_text(excerpt)), Some(work), None, None)
        .with_span(Some(s), Some(e))
}

fn ref_at(work: u64, text: &str, marker: &str, excerpt: &str) -> HyperRef {
    ref_span(work, excerpt, span_of(text, marker))
}

fn work_ref(work: u64) -> HyperRef {
    HyperRef::single(None, Some(work), None, None)
}

fn make_work(server: &mut Server, sid: SessionId, title: &str, text: &str) -> u64 {
    let id = server
        .create_work(sid, Edition::from_text(text))
        .expect("gallery: work_create");
    server.set_work_title(id, title.to_string());
    let _ = server.work_publish(sid, id);
    // Showcase works are read-only: editing locked to the admin club
    // so the public gallery cannot be defaced.
    let admin = server.system_clubs().admin_club;
    server.work_set_edit_club_force(id, Some(admin));
    id
}

fn make_link(
    server: &mut Server,
    sid: SessionId,
    origin_ref: HyperRef,
    dest_ref: HyperRef,
    types: &[u64],
) -> u64 {
    let link = HyperLink::make(types.to_vec(), origin_ref, dest_ref);
    server
        .create_link_with_hyperlink_homed(sid, link, None)
        .expect("gallery: link_create")
}

const ANNEX_SPECTRUM: &str = "Six Voices\n\nA comment: the spectrum sentence stacks its connections in lanes, one color per kind.\n\nA reference: every color is a different KIND of connection, not a different strength.\n\nA disagreement: six at once is showing off; two well-chosen links say more.\n\nA quotation: 'The color is the type, and the type is the claim.'\n\nA see-also: lanes stack because connections overlap — text carries many relations at once.\n\nA web link: the sixth voice points outward, off the gallery grounds.";

const ANNEX_JUNCTION: &str = "The Convergence\n\nEverything reaches the same place eventually. The junction word gathers roads; some arrive, some depart.";

const ANNEX_ARRIVAL: &str = "An Arrival\n\nOne of several roads that end at the junction word. Watch the right margin: incoming connections stack there.";

const ANNEX_OUTER: &str = "The Outer Room\n\nThe whole sentence is the scope of one connection. Big scopes are legal; they hold rooms, not just sentences.";

const ANNEX_INNER: &str = "The Inner Alcove\n\nA smaller scope inside the larger one. Nesting is not hierarchy — the inner link knows nothing of the outer; they merely overlap.";

const ANNEX_GENE_1965: &str = "The Original Pronouncement\n\nFilms, prose, poems, news, all branching and intertwining — the literature of tomorrow will be a literature of connection, and the connections will be visible, traversable, and permanent.";

const ANNEX_GENE_1974: &str = "The First Echo\n\nA literature of connection, visible, traversable, and permanent — so the pronouncement ran, and this echo quotes it faithfully, nine years on.";

const ANNEX_GENE_1987: &str = "The Second Echo\n\nThe echo of the echo: this passage quotes the First Echo, which quoted the Original. Nothing was copied; each hop is a connection you can walk backward.";

const ANNEX_REBUTTAL: &str = "The Rebuttal\n\nAll three claims rest on four-week windows measured in a seasonal trough. One year-over-year view would dissolve the entire constellation; the pattern is the window, not the world.";

const ANNEX_SOURCE: &str =
    "The Source\n\nThe primary material: one measurement, taken carefully, reported honestly.";

const ANNEX_CONTEXT: &str = "The Context\n\nThe measurement was taken during the retiming window — signage replaced, crews rerouted, the corridor briefly a different corridor.";

const ANNEX_COUNTER: &str = "The Counterpoint\n\nA careful reader holds that the five-way junction overstates the case: most connections are binary, and the general form is rare on purpose.";

const ANNEX_GLOSS: &str = "The Gloss\n\nFive ends, five roles: source, context, counterpoint, gloss, and the room you stand in. The names are chosen by the linker; the roles are whatever the argument needs.";

const ANNEX_AGAINST: &str = "The Case Against Tides\n\nTide tables are predictions wearing the costume of memories.\n\nThe schedule survived three administrations because nobody dared own it — that is not permanence, that is neglect.\n\nA ferry that always runs late is not reliable; it is merely predictable.\n\nTo live by the tide is to mistake a rhythm for a promise.";

const ANNEX_NOTE_1: &str = "The Margin Note\n\nThis note attaches to the CONNECTION itself, not to any passage: the dispute is about which window is honest, and neither document names its own.";

const ANNEX_NOTE_2: &str = "The Note on the Note\n\nAnd this note attaches to that note's connection — commentary all the way down. At every depth, the thing being discussed remains addressable.";

const R1_TEXT: &str = "Six kinds of connection share this one sentence, and the light that never goes out falls equally on every word of it: a comment that doubts, a reference that grounds, a disagreement that pushes back, a quotation that borrows, a see-also that gestures sideways, and a web link that leaves the gallery altogether.\n\nHow to read it: hover any underline — the tooltip names the kind and the far end. The lanes stack because the scopes overlap; the colors differ because the CLAIMS differ.\n\nWhat to try: put your cursor inside the sentence and watch the bottom bar offer every connection at once.";

const R2_TEXT: &str = "One word can be a station. The word everywhere below is the meeting point of five departing connections — five colors, five destinations, one span of text — and two other documents arrive at it too, stacking the right-hand margin.\n\nEverything connects everywhere, or so the station claims.\n\nHow to read it: the underlines stack in lanes under the single word; the margin bars on the left count the departures, and on the right the arrivals.\n\nWhat to try: hover the word and step through each connection in the tooltip.";

const R3_TEXT: &str = "A connection can hold a whole sentence, and another connection can live inside it, and a third can straddle the border between them, so that nesting and crossing happen in the same breath.\n\nHow to read it: the outer ribbon runs the full sentence; the inner ribbon starts partway in; the crossing ribbon begins inside the first and ends inside the second. None of them know about each other — text simply carries them all.\n\nWhat to try: click each underline and notice they go to three different rooms.";

const R4_TEXT: &str = "The passage below was not copied from the Original; it is connected to the Second Echo, which is connected to the First Echo, which is connected to the Original Pronouncement of 1965. Walk the underlines backward — each hop is a quotation link, each hop honest about where it came from.\n\nA literature of connection, visible, traversable, and permanent — carried here by three hops of quotation, 1965 to 1974 to 1987 to this room.\n\nHow to read it: hover the passage, follow the connection; in the far room, hover again; the chain continues until you reach the Original.\n\nWhat to try: open Compare on this link — three generations side by side.";

const R5_TEXT: &str = "Below is an ordinary disagreement. But open the Connections panel and press the comment symbol on its row: commentary can attach to the CONNECTION itself. The Margin Note does exactly that — and the Note on the Note attaches to that commentary's connection. Three levels deep, every one addressable.\n\nThe four-week window flatters the throughput numbers, and this sentence is what the argument is about.\n\nHow to read it: in the panel, rows carrying a small arrow chip are attached-to-a-connection; follow them down.\n\nWhat to try: hover the arrow-chip rows to see which connection each note discusses.";

const R6_TEXT: &str = "Three claims, one rebuttal. The three underlined passages below are not three connections — they are three passages of ONE end, gathered; the chips in the margin read 1 of 3, 2 of 3, 3 of 3. The far end is a single paragraph in the Rebuttal annex that answers all three at once.\n\nFirst: throughput improved forty percent under the retiming, with no incident rise.\n\nSecond: escalations fell to a three-year low under the new triage rota.\n\nThird: maintenance costs per corridor-mile dropped twelve percent.\n\nHow to read it: hover any member passage — the chip says which passage of how many; click any member to reach the same far end.\n\nWhat to try: select another sentence here and Gather it into the set; the chips renumber.";

const R7_TEXT: &str = "One connection, five named ends. The passage below is one end; the others are the Source (what was measured), the Context (what else was happening), the Counterpoint (the objection), and the Gloss (what the shape means). The names were chosen when the link was made — ends are roles, not positions.\n\nThe measurement was taken once, carefully, and means something different in each of the four other rooms it touches.\n\nHow to read it: the Connections panel lists every end by name; Compare shows all five windows side by side.\n\nWhat to try: open Compare and read the same fact from five positions.";

const R8_TEXT: &str = "Two documents, four disagreements, both directions. The underlined passages below dispute the Case Against Tides, and two of its passages dispute this room right back — so the left margin carries departures and the right margin carries arrivals, and Compare sets the whole quarrel side by side.\n\nA rhythm kept for a century is a promise, whatever the pessimists say.\n\nThe tide has never once failed to announce itself.\n\nHow to read it: red is disagreement; both documents show both margins, because a dispute is bidirectional by nature.\n\nWhat to try: press Compare on any disagreement row — the shared structure of the quarrel appears at a glance.";

const R9_TEXT: &str = "The two barred passages in this room are not quotations and not links — they are windows. Live transclusions: the text you see is the text that lives in the other document, and if its author revises, this window revises with it.\n\nHow to read it: the vertical bar marks a window; hover to see where the text actually lives.\n\nWhat to try: open the Original Pronouncement and edit the passage — return here and the window will have moved with it.";

const LOBBY_TEXT: &str = "THE GALLERY OF UNUSUAL CONNECTIONS\n\nThree wings, nine rooms, one tour. Every exhibit is a live structure — nothing here is a picture of a link; everything is the thing itself. The room names below are wired: click one to walk there.\n\nWING I · FORM — the shapes a connection can take.\nRoom 1: The Spectrum Sentence — six kinds of connection on one sentence.\nRoom 2: The Junction Word — one word, five departures, two arrivals.\nRoom 3: The Nested Scope — a link inside a link, and one across the border.\n\nWING II · DEPTH — connection leading to connection.\nRoom 4: Genealogy of a Quotation — 1965 to 1974 to 1987 to this gallery.\nRoom 5: A Link About a Link — commentary attached to connections, three deep.\n\nWING III · CONTENTION — many ends, many voices.\nRoom 6: The Rebuttal Constellation — three passages, one end, one answer.\nRoom 7: The Five-Way Junction — one connection, five named ends.\nRoom 8: The Standing Dispute — four disagreements, both directions.\n\nTHE FABRIC — beyond links.\nRoom 9: The Live Window — transclusions: windows, not copies.\n\nThe Curator's Tour (in the Trails panel) threads the rooms in order. The annexes hold the far ends; every underline in every room leads somewhere real.";

const GATHERS_DEF_TEXT: &str = "Gathers\n\nA gathers link asserts exhibition membership: the origin is the exhibition COVER, the destination is a MEMBER. The unit is referenceable from anywhere (the cover is a work), membership is bidirectional for free, and the boundary is an indication — never a barrier — when a reader crosses the member set.";

/// Seed the Gallery of Unusual Connections and its exhibition
/// gathers layer. Idempotent guard: does nothing when the lobby
/// work already exists (works are titled explicitly).
pub fn seed_gallery(server: &mut Server) {
    let sid = server.connect();
    let _ = server.login_public(sid);
    // Seed with system authority: the seeder is boot-time server
    // code, not a remote user — the edit policy must not gate it
    // (owner-only servers refuse public work_create otherwise).
    let sc = *server.system_clubs();
    let mut clubs = std::collections::HashSet::new();
    clubs.insert(sc.admin_club);
    clubs.insert(sc.access_club);
    clubs.insert(sc.public_club);
    if let Some(sess) = server.sessions.get_mut(&sid) {
        sess.set_key_master(crate::server::keymaster::KeyMaster::make_all(clubs));
    }
    // Idempotency: the lobby's title already present -> already seeded.
    let marker = "Gallery — Lobby: The Gallery of Unusual Connections";
    let already = server
        .works
        .values()
        .any(|ws| ws.cached_title().contains(marker));
    if already {
        tracing::info!("[seed-gallery] already seeded — skipping");
        return;
    }

    // ---- Annex companions (the far ends)
    let annex_spectrum = make_work(server, sid, "Gallery Annex — Six Voices", ANNEX_SPECTRUM);
    let annex_junction = make_work(
        server,
        sid,
        "Gallery Annex — The Convergence",
        ANNEX_JUNCTION,
    );
    let annex_arrival = make_work(server, sid, "Gallery Annex — An Arrival", ANNEX_ARRIVAL);
    let annex_outer = make_work(server, sid, "Gallery Annex — The Outer Room", ANNEX_OUTER);
    let annex_inner = make_work(server, sid, "Gallery Annex — The Inner Alcove", ANNEX_INNER);
    let gene_1965 = make_work(
        server,
        sid,
        "Gallery Annex — The Original Pronouncement (1965)",
        ANNEX_GENE_1965,
    );
    let gene_1974 = make_work(
        server,
        sid,
        "Gallery Annex — The First Echo (1974)",
        ANNEX_GENE_1974,
    );
    let gene_1987 = make_work(
        server,
        sid,
        "Gallery Annex — The Second Echo (1987)",
        ANNEX_GENE_1987,
    );
    let annex_rebuttal = make_work(server, sid, "Gallery Annex — The Rebuttal", ANNEX_REBUTTAL);
    let annex_source = make_work(server, sid, "Gallery Annex — The Source", ANNEX_SOURCE);
    let annex_context = make_work(server, sid, "Gallery Annex — The Context", ANNEX_CONTEXT);
    let annex_counter = make_work(
        server,
        sid,
        "Gallery Annex — The Counterpoint",
        ANNEX_COUNTER,
    );
    let annex_gloss = make_work(server, sid, "Gallery Annex — The Gloss", ANNEX_GLOSS);
    let annex_against = make_work(
        server,
        sid,
        "Gallery Annex — The Case Against Tides",
        ANNEX_AGAINST,
    );
    let annex_note_1 = make_work(server, sid, "Gallery Annex — The Margin Note", ANNEX_NOTE_1);
    let annex_note_2 = make_work(
        server,
        sid,
        "Gallery Annex — The Note on the Note",
        ANNEX_NOTE_2,
    );

    // ---- Room 1: The Spectrum Sentence
    let r1 = make_work(
        server,
        sid,
        "Gallery — Wing I · Room 1: The Spectrum Sentence",
        R1_TEXT,
    );
    for (m, t, ex) in [
        (
            "the light that never goes out falls equally on every word of it",
            1u64,
            "the whole spectrum, commented",
        ),
        (
            "a comment that doubts, a reference that grounds",
            2,
            "comment and reference, cited",
        ),
        (
            "a disagreement that pushes back",
            3,
            "the disagreement, disputed",
        ),
        ("a quotation that borrows", 4, "the quotation, quoted"),
        (
            "a see-also that gestures sideways",
            5,
            "the see-also, sidelong",
        ),
        ("leaves the gallery altogether", 6, "the outward web link"),
    ] {
        make_link(
            server,
            sid,
            ref_at(r1, R1_TEXT, m, ex),
            work_ref(annex_spectrum),
            &[t],
        );
    }

    // ---- Room 2: The Junction Word
    let r2 = make_work(
        server,
        sid,
        "Gallery — Wing I · Room 2: The Junction Word",
        R2_TEXT,
    );
    let junction = span_of(R2_TEXT, "everywhere");
    for (t, ex) in [
        (1u64, "the junction, commented"),
        (2, "the junction, referenced"),
        (3, "the junction, disputed"),
        (4, "the junction, quoted"),
        (5, "the junction, seen also"),
    ] {
        make_link(
            server,
            sid,
            ref_span(r2, ex, junction),
            work_ref(annex_junction),
            &[t],
        );
    }
    // two arrivals: other documents link INTO the same word
    let a1 = span_of(ANNEX_ARRIVAL, "roads that end at the junction word");
    make_link(
        server,
        sid,
        ref_span(annex_arrival, "an arrival from the annex", a1),
        ref_span(r2, "the junction word itself", junction),
        &[2],
    );
    let a2 = span_of(ANNEX_JUNCTION, "The junction word gathers roads");
    make_link(
        server,
        sid,
        ref_span(annex_junction, "the convergence arrives", a2),
        ref_span(r2, "the junction word, again", junction),
        &[5],
    );

    // ---- Room 3: The Nested Scope
    let r3 = make_work(
        server,
        sid,
        "Gallery — Wing I · Room 3: The Nested Scope",
        R3_TEXT,
    );
    make_link(
        server,
        sid,
        ref_at(
            r3,
            R3_TEXT,
            "A connection can hold a whole sentence, and another connection can live inside it, and a third can straddle the border between them, so that nesting and crossing happen in the same breath.",
            "the outer scope, whole sentence",
        ),
        work_ref(annex_outer),
        &[2],
    );
    make_link(
        server,
        sid,
        ref_at(
            r3,
            R3_TEXT,
            "another connection can live inside it",
            "the inner scope, one clause",
        ),
        work_ref(annex_inner),
        &[4],
    );
    make_link(
        server,
        sid,
        ref_at(
            r3,
            R3_TEXT,
            "can live inside it, and a third can straddle",
            "the crossing scope, border-straddling",
        ),
        work_ref(annex_outer),
        &[5],
    );

    // ---- Room 4: Genealogy of a Quotation
    let r4 = make_work(
        server,
        sid,
        "Gallery — Wing II · Room 4: Genealogy of a Quotation",
        R4_TEXT,
    );
    let p_1965 = span_of(
        ANNEX_GENE_1965,
        "a literature of connection, and the connections will be visible, traversable, and permanent",
    );
    let p_1974 = span_of(
        ANNEX_GENE_1974,
        "A literature of connection, visible, traversable, and permanent",
    );
    let p_1987 = span_of(
        ANNEX_GENE_1987,
        "quotes the First Echo, which quoted the Original",
    );
    let p_room4 = span_of(R4_TEXT, "carried here by three hops of quotation");
    make_link(
        server,
        sid,
        ref_span(gene_1974, "the first echo quotes the original", p_1974),
        ref_span(gene_1965, "the original pronouncement", p_1965),
        &[4],
    );
    make_link(
        server,
        sid,
        ref_span(gene_1987, "the second echo quotes the first", p_1987),
        ref_span(gene_1974, "the first echo's passage", p_1974),
        &[4],
    );
    make_link(
        server,
        sid,
        ref_span(r4, "the room quotes the second echo", p_room4),
        ref_span(gene_1987, "the second echo's passage", p_1987),
        &[4],
    );

    // ---- Room 5: A Link About a Link
    let r5 = make_work(
        server,
        sid,
        "Gallery — Wing II · Room 5: A Link About a Link",
        R5_TEXT,
    );
    let r5_pass = span_of(
        R5_TEXT,
        "The four-week window flatters the throughput numbers",
    );
    let dispute = make_link(
        server,
        sid,
        ref_span(r5, "the disputed window claim", r5_pass),
        work_ref(annex_rebuttal),
        &[3],
    );
    let n1 = span_of(ANNEX_NOTE_1, "This note attaches to the CONNECTION itself");
    let note_link = make_link(
        server,
        sid,
        ref_span(annex_note_1, "the margin note on the dispute", n1),
        work_ref(r5),
        &[1],
    );
    server
        .link_end_add_attachment(
            sid,
            note_link,
            "Connection",
            HyperRef::link_attachment(dispute, Some(r5)),
        )
        .expect("gallery: link_end_add_attachment");
    let n2 = span_of(ANNEX_NOTE_2, "this note attaches to that note's connection");
    let note_link_2 = make_link(
        server,
        sid,
        ref_span(annex_note_2, "the note on the note", n2),
        work_ref(annex_note_1),
        &[1],
    );
    server
        .link_end_add_attachment(
            sid,
            note_link_2,
            "Connection",
            HyperRef::link_attachment(note_link, Some(r5)),
        )
        .expect("gallery: link_end_add_attachment");

    // ---- Room 6: The Rebuttal Constellation
    let r6 = make_work(
        server,
        sid,
        "Gallery — Wing III · Room 6: The Rebuttal Constellation",
        R6_TEXT,
    );
    let m1 = span_of(
        R6_TEXT,
        "throughput improved forty percent under the retiming, with no incident rise",
    );
    let m2 = span_of(
        R6_TEXT,
        "escalations fell to a three-year low under the new triage rota",
    );
    let m3 = span_of(
        R6_TEXT,
        "maintenance costs per corridor-mile dropped twelve percent",
    );
    let reb = span_of(
        ANNEX_REBUTTAL,
        "One year-over-year view would dissolve the entire constellation",
    );
    let constellation = make_link(
        server,
        sid,
        ref_span(r6, "member one of three", m1),
        ref_span(annex_rebuttal, "the single rebuttal", reb),
        &[3],
    );
    server
        .link_end_add_attachment(
            sid,
            constellation,
            "LeftEnd",
            ref_span(r6, "member two of three", m2),
        )
        .expect("gallery: link_end_add_attachment");
    server
        .link_end_add_attachment(
            sid,
            constellation,
            "LeftEnd",
            ref_span(r6, "member three of three", m3),
        )
        .expect("gallery: link_end_add_attachment");

    // ---- Room 7: The Five-Way Junction
    let r7 = make_work(
        server,
        sid,
        "Gallery — Wing III · Room 7: The Five-Way Junction",
        R7_TEXT,
    );
    let r7_p = span_of(R7_TEXT, "The measurement was taken once, carefully");
    let src_p = span_of(
        ANNEX_SOURCE,
        "one measurement, taken carefully, reported honestly",
    );
    let ctx_p = span_of(ANNEX_CONTEXT, "the corridor briefly a different corridor");
    let cpt_p = span_of(ANNEX_COUNTER, "the general form is rare on purpose");
    let glo_p = span_of(ANNEX_GLOSS, "the roles are whatever the argument needs");
    let junction5 = make_link(
        server,
        sid,
        ref_span(r7, "this room, the fifth end", r7_p),
        ref_span(annex_source, "the source end", src_p),
        &[5],
    );
    server
        .link_add_end(
            sid,
            junction5,
            "Context",
            ref_span(annex_context, "the context end", ctx_p),
        )
        .expect("gallery: link_add_end");
    server
        .link_add_end(
            sid,
            junction5,
            "Counterpoint",
            ref_span(annex_counter, "the counterpoint end", cpt_p),
        )
        .expect("gallery: link_add_end");
    server
        .link_add_end(
            sid,
            junction5,
            "Gloss",
            ref_span(annex_gloss, "the gloss end", glo_p),
        )
        .expect("gallery: link_add_end");

    // ---- Room 8: The Standing Dispute
    let r8 = make_work(
        server,
        sid,
        "Gallery — Wing III · Room 8: The Standing Dispute",
        R8_TEXT,
    );
    let out1 = span_of(R8_TEXT, "A rhythm kept for a century is a promise");
    let out2 = span_of(R8_TEXT, "The tide has never once failed to announce itself");
    let in_self = span_of(
        R8_TEXT,
        "the left margin carries departures and the right margin carries arrivals",
    );
    let against1 = span_of(
        ANNEX_AGAINST,
        "Tide tables are predictions wearing the costume of memories",
    );
    let against2 = span_of(
        ANNEX_AGAINST,
        "A ferry that always runs late is not reliable; it is merely predictable",
    );
    let in1 = span_of(ANNEX_AGAINST, "that is not permanence, that is neglect");
    let in2 = span_of(
        ANNEX_AGAINST,
        "To live by the tide is to mistake a rhythm for a promise",
    );
    make_link(
        server,
        sid,
        ref_span(r8, "rhythm-as-promise, asserted", out1),
        ref_span(annex_against, "the neglect charge, disputed", in1),
        &[3],
    );
    make_link(
        server,
        sid,
        ref_span(r8, "the tide's punctuality, asserted", out2),
        ref_span(
            annex_against,
            "predictable-not-reliable, disputed",
            against2,
        ),
        &[3],
    );
    make_link(
        server,
        sid,
        ref_span(
            annex_against,
            "costume of memories, counterasserted",
            against1,
        ),
        ref_span(r8, "the margins sentence, disputed here", in_self),
        &[3],
    );
    make_link(
        server,
        sid,
        ref_span(annex_against, "rhythm-vs-promise, counterasserted", in2),
        ref_span(r8, "the promise sentence, disputed here", out1),
        &[3],
    );

    // ---- Room 9: The Live Window (transclusions, not links)
    let r9_title = "Gallery — The Fabric · Room 9: The Live Window";
    let r9 = make_work(server, sid, r9_title, R9_TEXT);
    let win_1965 = span_of(
        ANNEX_GENE_1965,
        "a literature of connection, and the connections will be visible, traversable, and permanent",
    );
    let win_reb = span_of(ANNEX_REBUTTAL, "the pattern is the window, not the world");
    let pos1 = R9_TEXT
        .find("not quotations and not links")
        .expect("gallery: r9 pos1") as i64;
    let pos2_tail = "if its author revises, this window revises with it";
    let pos2 = (R9_TEXT.find(pos2_tail).expect("gallery: r9 pos2") + pos2_tail.len()) as i64;
    server
        .element_insert(
            sid,
            r9,
            pos1,
            RangeElement::transclusion(gene_1965, win_1965.0 as usize, win_1965.1 as usize),
        )
        .expect("gallery: element_insert");
    server
        .element_insert(
            sid,
            r9,
            pos2,
            RangeElement::transclusion(annex_rebuttal, win_reb.0 as usize, win_reb.1 as usize),
        )
        .expect("gallery: element_insert");
    // element_insert clobbers the cached title (server re-derives it
    // from the revised edition — known bug); re-set it after placing.
    server.set_work_title(r9, r9_title.to_string());

    // ---- The Lobby (the floor plan)
    let lobby_title = "Gallery — Lobby: The Gallery of Unusual Connections";
    let lobby = make_work(server, sid, lobby_title, LOBBY_TEXT);
    let room_targets = [
        ("Room 1: The Spectrum Sentence", r1),
        ("Room 2: The Junction Word", r2),
        ("Room 3: The Nested Scope", r3),
        ("Room 4: Genealogy of a Quotation", r4),
        ("Room 5: A Link About a Link", r5),
        ("Room 6: The Rebuttal Constellation", r6),
        ("Room 7: The Five-Way Junction", r7),
        ("Room 8: The Standing Dispute", r8),
        ("Room 9: The Live Window", r9),
    ];
    let mut floor_plan_links = Vec::new();
    for (label, target) in room_targets {
        let excerpt = format!("{} (floor plan)", label);
        let lid = make_link(
            server,
            sid,
            ref_at(lobby, LOBBY_TEXT, label, &excerpt),
            work_ref(target),
            &[2],
        );
        floor_plan_links.push(lid);
    }

    // ---- The Curator's Tour, published (visible to every reader).
    let trail = server
        .trail_create(
            sid,
            "The Curator's Tour".to_string(),
            Some(
                "Nine rooms of unusual connection, lobby to live window. Every exhibit is the thing itself."
                    .to_string(),
            ),
            vec![],
        )
        .expect("gallery: trail_create");
    for (work, note) in [
        (
            lobby,
            "Begin in the lobby: the floor plan is wired with links",
        ),
        (r1, "Wing I · Form — six kinds at once"),
        (r2, "one word, many connections"),
        (r3, "scopes nest and cross"),
        (r4, "Wing II · Depth — quotation genealogy"),
        (r5, "commentary on connections"),
        (r6, "Wing III · Contention — gathered passages"),
        (r7, "five named ends"),
        (r8, "the standing dispute"),
        (r9, "The Fabric — windows, not copies"),
    ] {
        server
            .trail_add_stop(sid, trail, work, None, None, Some(note.to_string()), None)
            .expect("gallery: trail_add_stop");
    }
    let _ = server.trail_publish(sid, trail);

    // ---- Exhibition gathers: the lobby is the COVER, every room
    // and annex a MEMBER, bound by the "Gathers" link type (the
    // definition work IS the type).
    let gathers_def = make_work(
        server,
        sid,
        "Gallery — Link Type: Gathers",
        GATHERS_DEF_TEXT,
    );
    match server.register_link_type_checked(
        sid,
        gathers_def,
        "Gathers".to_string(),
        Some(gathers_def),
    ) {
        Ok(()) => tracing::info!(
            "[seed-gallery] link type {} \"Gathers\" registered (the work IS the type)",
            gathers_def
        ),
        Err(e) => tracing::info!("[seed-gallery] type registration skipped: {}", e),
    }
    let gathers = gathers_def;
    for lid in floor_plan_links {
        server
            .link_set_types(sid, lid, vec![gathers])
            .expect("gallery: link_set_types");
    }
    let annex_span = span_of(LOBBY_TEXT, "annexes");
    let annexes = [
        annex_spectrum,
        annex_junction,
        annex_arrival,
        annex_outer,
        annex_inner,
        gene_1965,
        gene_1974,
        gene_1987,
        annex_rebuttal,
        annex_source,
        annex_context,
        annex_counter,
        annex_gloss,
        annex_against,
        annex_note_1,
        annex_note_2,
    ];
    let mut annex_links = 0;
    for annex in annexes {
        make_link(
            server,
            sid,
            ref_span(lobby, "the annexes, gathered", annex_span),
            work_ref(annex),
            &[gathers],
        );
        annex_links += 1;
    }
    tracing::info!(
        "[seed-gallery] exhibition ready: cover={:x} members={} (cover + rooms + annexes), gathers links={}",
        lobby,
        1 + room_targets.len() + annexes.len(),
        annex_links
    );

    tracing::info!(
        "[seed-gallery] gallery ready: lobby={:x} rooms={:?} annexes={} trail={} gathers_type={}",
        lobby,
        [r1, r2, r3, r4, r5, r6, r7, r8, r9],
        annexes.len(),
        trail,
        gathers
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn seed_creates_gallery_trail_and_links() {
        let mut server = Server::new();
        seed_gallery(&mut server);
        let titles: Vec<String> = server
            .works
            .values()
            .map(|ws| ws.cached_title().to_string())
            .collect();
        for needle in [
            "Gallery — Lobby: The Gallery of Unusual Connections",
            "Gallery — Wing I · Room 1: The Spectrum Sentence",
            "Gallery — Wing I · Room 2: The Junction Word",
            "Gallery — Wing I · Room 3: The Nested Scope",
            "Gallery — Wing II · Room 4: Genealogy of a Quotation",
            "Gallery — Wing II · Room 5: A Link About a Link",
            "Gallery — Wing III · Room 6: The Rebuttal Constellation",
            "Gallery — Wing III · Room 7: The Five-Way Junction",
            "Gallery — Wing III · Room 8: The Standing Dispute",
            "Gallery — The Fabric · Room 9: The Live Window",
            "Gallery Annex — Six Voices",
            "Gallery Annex — The Rebuttal",
            "Gallery Annex — The Note on the Note",
            "Gallery — Link Type: Gathers",
        ] {
            assert!(
                titles.iter().any(|t| t == needle),
                "gallery work missing {}",
                needle
            );
        }
        // 6 + 7 + 3 + 3 + 3 + 1 + 1 + 4 + 9 floor plan + 16 gathers
        assert!(
            server.links.len() >= 53,
            "expected at least 53 gallery links, got {}",
            server.links.len()
        );
        // The gathered end on the constellation: 3 attachments.
        let gathered = server
            .links
            .values()
            .map(|ls| ls.link.clone())
            .find(|l| l.attachment_count("LeftEnd") == 3)
            .expect("a 3-passage gathered end is seeded");
        assert_eq!(gathered.attachment_count("LeftEnd"), 3);
        // The five-way junction: 5 named ends.
        let five_way = server
            .links
            .values()
            .map(|ls| ls.link.clone())
            .find(|l| {
                let names = l.end_names();
                names.len() == 5
                    && names.contains(&"Context")
                    && names.contains(&"Counterpoint")
                    && names.contains(&"Gloss")
            })
            .expect("the five-way junction is seeded");
        assert_eq!(five_way.end_names().len(), 5);
        // The Curator's Tour exists, published, 10 stops in order.
        let trail = server
            .trails
            .values()
            .find(|t| t.name == "The Curator's Tour")
            .expect("curator's tour seeded");
        assert!(trail.published, "the curator's tour is published");
        assert_eq!(trail.stops.len(), 10);
        // The Gathers type is registered and equals its definition work.
        let def_id = server
            .works
            .iter()
            .find(|(_, ws)| ws.cached_title() == "Gallery — Link Type: Gathers")
            .map(|(id, _)| *id)
            .expect("gathers definition work");
        assert_eq!(server.link_type_definition(def_id), Some(def_id));
    }

    #[test]
    fn seed_is_idempotent() {
        let mut server = Server::new();
        seed_gallery(&mut server);
        let works_before = server.works.len();
        let links_before = server.links.len();
        seed_gallery(&mut server);
        assert_eq!(server.works.len(), works_before, "no duplicate works");
        assert_eq!(server.links.len(), links_before, "no duplicate links");
    }
}
