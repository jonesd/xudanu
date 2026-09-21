// Memory cost analysis of Xudanu link structures.
// Run: cargo run --features server --bin link-memory-analysis

fn main() {
    println!("═══════════════════════════════════════════════════════════════");
    println!("  Xudanu Link Memory Cost Analysis");
    println!("═══════════════════════════════════════════════════════════════");
    println!();

    // ── HyperRef (one end of a link) ─────────────────────────────
    // Fixed fields:
    //   kind: enum                  ~1-8 bytes
    //   work_context: Option<u64>    16 bytes (8 data + 1 tag, padded)
    //   original_context: Option<u64> 16 bytes
    //   path_context: Option<Path>   24 bytes (enum with variants)
    //   start_position: Option<i64>  16 bytes
    //   end_position: Option<i64>    16 bytes
    // Subtotal fixed: ~88 bytes
    //
    // Heap-allocated fields (when present):
    //   provenance_chain: Vec        24 bytes (empty) + N × ~64 bytes
    //   cross_server_ref: Option     8 bytes + ~300 bytes when present
    //   origin_tumbler: Option<String> 8 bytes + string length
    //
    // Minimum HyperRef (local, simple span, no provenance):
    let hyperref_min = 88; // fixed only, no heap allocs
    let hyperref_typical = 88 + 24 + 8; // + empty Vec + no cross-server
    let hyperref_cross_server = hyperref_typical + 300; // + CrossServerRef

    println!("HyperRef (one link end):");
    println!("  Minimum (local span):     {hyperref_min:>4} bytes");
    println!("  Typical (local + vec):    {hyperref_typical:>4} bytes");
    println!("  Cross-server:           {hyperref_cross_server:>4} bytes (+ tumbler string)");
    println!();

    // ── HyperLink (the link itself) ──────────────────────────────
    // HashMap<String, Vec<HyperRef>>:
    //   HashMap overhead:          ~48 bytes (empty)
    //   Per entry: key String     ~24 + "LeftEnd".len() bytes
    //              value Vec      ~24 bytes
    //              HyperRef       ~88 bytes minimum
    //   Two-ended link: 2 entries
    // link_types: Vec<u64>:       ~24 bytes + 8 × types
    //
    // Two-ended link (simplest):
    let hyperlink_2end = 48 + (24 + 8 + 24 + hyperref_min) * 2 + 24 + 8;
    // N-ended link:
    let hyperlink_nend = |n: usize| 48 + (24 + 8 + 24 + hyperref_min) * n + 24 + 8;
    // End-set (multiple attachments per end):
    let hyperlink_gathered = |ends: usize, attachments: usize| {
        48 + (24 + 8 + 24 + hyperref_min * attachments) * ends + 24 + 8
    };

    println!("HyperLink:");
    println!("  Two-ended (simple):       {hyperlink_2end:>4} bytes");
    println!("  Three-ended:              {hyperlink_nend(3):>4} bytes");
    println!("  Gathered 2×3:           {hyperlink_gathered(2, 3):>4} bytes (2 ends, 3 attachments each)");
    println!("  Gathered 2×10:          {hyperlink_gathered(2, 10):>4} bytes");
    println!();

    // ── LinkState (server-side wrapper) ──────────────────────────
    // HyperLink:                  hyperlink_2end bytes
    // origin: BeId (u64)           8 bytes
    // destination: Option<BeId>    16 bytes
    // home_document: Option<BeId>  16 bytes
    // cross_server_notify: Option  8 + ~32 bytes
    // author_club: Option<BeId>    16 bytes
    // endorsements: Vec            24 bytes + N × ~80 bytes each
    let linkstate_base = hyperlink_2end + 8 + 16 + 16 + 8 + 16 + 24;

    println!("LinkState (server wrapper around HyperLink):");
    println!("  Base (no endorsements):   {linkstate_base:>4} bytes");
    println!("  + 1 endorsement:          {:>4} bytes", linkstate_base + 80);
    println!("  + 3 endorsements:         {:>4} bytes", linkstate_base + 240);
    println!();

    // ── Index overhead ───────────────────────────────────────────
    // links: HashMap<BeId, LinkState>
    //   HashMap overhead: ~80 bytes empty, ~48 bytes per slot
    //   With N entries: ~N × 48 + N × sizeof(LinkState)
    //
    // work_to_links: HashMap<BeId, HashSet<BeId>>
    //   Per work: ~48 bytes (HashMap) + ~48 bytes (HashSet) + N × 8 bytes
    //
    // Total per-link index cost:
    let index_cost_per_link = 48 + 8; // HashMap slot + work_to_links entry
    println!("Index overhead per link:");
    println!("  links HashMap slot:       {index_cost_per_link:>4} bytes");
    println!();

    // ── Total per-link cost ─────────────────────────────────────
    let total_simple = linkstate_base + index_cost_per_link;
    let total_3end = hyperlink_nend(3) + 8 + 16 + 16 + 8 + 16 + 24 + index_cost_per_link;
    let total_gathered = hyperlink_gathered(2, 3) + 8 + 16 + 16 + 8 + 16 + 24 + index_cost_per_link;

    println!("═══════════════════════════════════════════════════════════════");
    println!("TOTAL COST PER LINK (in-memory, including indexes):");
    println!("═══════════════════════════════════════════════════════════════");
    println!("  Two-ended simple:         {total_simple:>4} bytes  ({:.1} bytes/end)", total_simple as f64 / 2.0);
    println!("  Three-ended:              {total_3end:>4} bytes  ({:.1} bytes/end)", total_3end as f64 / 3.0);
    println!("  Gathered 2×3:           {total_gathered:>4} bytes  ({:.1} bytes/attachment)", total_gathered as f64 / 6.0);
    println!("  Cross-server:          {}  bytes  (+300 for CrossServerRef)", total_simple + 300);
    println!();

    // ── Capacity table ───────────────────────────────────────────
    println!("Capacity at different memory budgets:");
    println!("{:<12} {:>12} {:>12} {:>12}", "Memory", "2-ended", "3-ended", "Gathered 2×3");
    println!("{}", "─".repeat(52));
    for &gb in &[1u64, 4, 8, 16, 32, 64, 128, 256] {
        let bytes = gb * 1_073_741_824;
        let simple_cap = bytes / total_simple as u64;
        let tri_cap = bytes / total_3end as u64;
        let gathered_cap = bytes / total_gathered as u64;
        let fmt = |n: u64| {
            if n >= 1_000_000_000 {
                format!("{:.1}B", n as f64 / 1e9)
            } else if n >= 1_000_000 {
                format!("{:.0}M", n as f64 / 1e6)
            } else if n >= 1_000 {
                format!("{:.0}K", n as f64 / 1e3)
            } else {
                format!("{n}")
            }
        };
        println!("{gb:<12} {:>12} {:>12} {:>12}", "{gb}GB", fmt(simple_cap), fmt(tri_cap), fmt(gathered_cap));
    }

    println!();
    println!("Notes:");
    println!("  • Cross-server links cost ~2× (CrossServerRef adds hash, sig, excerpt)");
    println!("  • Endorsements add ~80 bytes each (signer + signature)");
    println!("  • Provenance chains add ~64 bytes per hop");
    println!("  • These are IN-MEMORY costs; persisted chunks are ~50% smaller");
    println!("    (postcard serialization, no HashMap/HashSet overhead)");
    println!("  • Gold's FeMultiRef was simpler (~40 bytes per end) but had");
    println!("    no provenance, no endorsements, no cross-server refs");
}
