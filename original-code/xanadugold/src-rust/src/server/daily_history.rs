//! Daily narrative history — auto-generated summary of what changed,
//! grouped by topic cluster (connected components in the link graph).
//! Design: docs/dev/daily-history.md.

use std::collections::{BTreeMap, HashMap, HashSet};

use crate::server::server::Server;

/// Generate the daily history text from the server state.
/// Returns None if there's nothing to record.
pub fn generate_daily_history(server: &Server) -> Option<(String, Vec<u64>)> {
    let today = chrono::Utc::now().format("%Y-%m-%d").to_string();
    let title = format!("Daily History — {}", today);

    // Don't create if today's history already exists.
    let exists = server
        .works
        .values()
        .any(|ws| ws.cached_title().contains(&title));
    if exists {
        return None;
    }

    // Collect works touched today (revised or created).
    // Use the attribution log for recency; fall back to revision
    // timestamps. For simplicity: scan works whose current revision
    // was created in the last 24h.
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let day_ago = now.saturating_sub(86_400);

    let mut touched: Vec<u64> = Vec::new();
    for (id, ws) in server.works.iter() {
        // Skip existing history works.
        if ws.cached_title().contains("Daily History") {
            continue;
        }
        // Check if the current edition has any provenance from
        // today (element-level timestamps).
        let recent = server
            .work_edition(*id)
            .map(|ed| {
                ed.all_entries().iter().any(|(_, c)| {
                    c.provenance
                        .as_ref()
                        .map(|p| p.timestamp >= day_ago)
                        .unwrap_or(false)
                })
            })
            .unwrap_or(false);
        if recent {
            touched.push(*id);
        }
    }
    if touched.is_empty() {
        return None;
    }

    // Build the link graph among touched works.
    let touched_set: HashSet<u64> = touched.iter().copied().collect();
    let mut adj: HashMap<u64, HashSet<u64>> = HashMap::new();
    let mut link_records: Vec<(u64, u64, String)> = Vec::new();

    for ls in server.links.values() {
        let link = &ls.link;
        let label = link
            .link_types()
            .first()
            .and_then(|t| match t {
                1 => Some("comment"),
                2 => Some("reference"),
                3 => Some("disagreement"),
                4 => Some("quotation"),
                5 => Some("see-also"),
                6 => Some("web"),
                _ => Some("custom"),
            })
            .unwrap_or("untyped")
            .to_string();
        let mut srcs: Vec<u64> = Vec::new();
        for atts in link.ends().values() {
            for r in atts {
                if let Some(w) = r.work_context() {
                    if touched_set.contains(&w) {
                        srcs.push(w);
                    }
                }
            }
        }
        srcs.sort_unstable();
        srcs.dedup();
        for (i, &a) in srcs.iter().enumerate() {
            for &b in &srcs[i + 1..] {
                adj.entry(a).or_default().insert(b);
                adj.entry(b).or_default().insert(a);
                link_records.push((a, b, label.clone()));
            }
        }
    }

    // Connected components = topic clusters.
    let mut seen: HashSet<u64> = HashSet::new();
    let mut clusters: Vec<Vec<u64>> = Vec::new();
    for &w in &touched {
        if seen.contains(&w) {
            continue;
        }
        let mut cluster = Vec::new();
        let mut stack = vec![w];
        seen.insert(w);
        while let Some(c) = stack.pop() {
            cluster.push(c);
            if let Some(nbrs) = adj.get(&c) {
                for &nb in nbrs {
                    if seen.insert(nb) {
                        stack.push(nb);
                    }
                }
            }
        }
        cluster.sort_unstable();
        clusters.push(cluster);
    }
    // Largest cluster first.
    clusters.sort_by(|a, b| b.len().cmp(&a.len()));

    // Build the narrative.
    let mut lines = String::new();
    lines.push_str(&format!("{}\n\n", title));
    lines.push_str("Summary of today's activity, grouped by connected topic clusters.\n\n");

    for (ci, cluster) in clusters.iter().enumerate() {
        let topic_label = if cluster.len() == 1 {
            let title = server
                .works
                .get(&cluster[0])
                .map(|ws| ws.cached_title().to_string())
                .unwrap_or_else(|| format!("work {:x}", cluster[0]));
            format!("Standalone: {}", truncate(&title, 40))
        } else {
            // Use the most-linked work's title as the cluster label.
            let hub = cluster
                .iter()
                .max_by_key(|&&w| adj.get(&w).map(|s| s.len()).unwrap_or(0))
                .copied()
                .unwrap_or(cluster[0]);
            let title = server
                .works
                .get(&hub)
                .map(|ws| ws.cached_title().to_string())
                .unwrap_or_else(|| format!("hub {:x}", hub));
            format!("Topic: {}", truncate(&title, 50))
        };

        lines.push_str(&format!("{}\n", topic_label));

        for &wid in cluster {
            let title = server
                .works
                .get(&wid)
                .map(|ws| ws.cached_title().to_string())
                .unwrap_or_else(|| format!("work {:x}", wid));
            let rev_count = server.work_revision_count(wid).unwrap_or(0);
            if rev_count <= 1 {
                lines.push_str(&format!("- Created: \"{}\"\n", truncate(&title, 60)));
            } else {
                lines.push_str(&format!(
                    "- Revised: \"{}\" (rev {})\n",
                    truncate(&title, 60),
                    rev_count
                ));
            }
        }

        // Links within this cluster.
        let cluster_set: HashSet<u64> = cluster.iter().copied().collect();
        for (a, b, label) in &link_records {
            if cluster_set.contains(a) && cluster_set.contains(b) {
                let ta = work_title(server, a);
                let tb = work_title(server, b);
                lines.push_str(&format!(
                    "- Linked: \"{}\" →{}→ \"{}\"\n",
                    truncate(&ta, 30),
                    label,
                    truncate(&tb, 30)
                ));
            }
        }

        // Transclusions into cluster works.
        for &wid in cluster {
            if let Ok(ed) = server.work_edition(wid) {
                for (_, carrier) in ed.all_entries() {
                    if let crate::edition::range_element::RangeElement::Transclusion {
                        source_work_id,
                        ..
                    } = &carrier.element
                    {
                        let src_title = work_title(server, source_work_id);
                        lines.push_str(&format!(
                            "- Transcluded: from \"{}\" into \"{}\"\n",
                            truncate(&src_title, 30),
                            truncate(&work_title(server, &wid), 30)
                        ));
                    }
                }
            }
        }

        if ci < clusters.len() - 1 {
            lines.push('\n');
        }
    }

    Some((lines, touched))
}

fn work_title(server: &Server, id: &u64) -> String {
    server
        .works
        .get(id)
        .map(|ws| ws.cached_title().to_string())
        .unwrap_or_else(|| format!("work {:x}", id))
}

fn truncate(s: &str, max: usize) -> &str {
    if s.len() <= max {
        s
    } else {
        let mut end = max;
        while end > 0 && !s.is_char_boundary(end) {
            end -= 1;
        }
        &s[..end]
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::Edition;

    fn setup() -> Server {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        server
    }

    #[test]
    fn multi_project_grouping() {
        let mut server = setup();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        // Project A: 3 interconnected works
        let a1 = server
            .create_work(sid, Edition::from_text("Grid Cells"))
            .unwrap();
        let a2 = server
            .create_work(sid, Edition::from_text("Boundary Cells"))
            .unwrap();
        let a3 = server
            .create_work(sid, Edition::from_text("Place Fields"))
            .unwrap();
        server.work_grab(sid, a1).unwrap();
        server
            .work_revise(sid, a1, Edition::from_text("Grid Cells v2"))
            .unwrap();
        server.work_grab(sid, a2).unwrap();
        server
            .work_revise(sid, a2, Edition::from_text("Boundary Cells v2"))
            .unwrap();
        // Link a1 ↔ a2 (same project)
        server
            .create_link_with_hyperlink_homed(
                sid,
                crate::edition::links::HyperLink::make(
                    vec![2],
                    crate::edition::links::HyperRef::single(None, Some(a1), None, None),
                    crate::edition::links::HyperRef::single(None, Some(a2), None, None),
                ),
                None,
            )
            .unwrap();

        // Project B: 2 interconnected works (different topic)
        let b1 = server
            .create_work(sid, Edition::from_text("Compliance Position A"))
            .unwrap();
        let b2 = server
            .create_work(sid, Edition::from_text("Compliance Position B"))
            .unwrap();
        server.work_grab(sid, b1).unwrap();
        server
            .work_revise(sid, b1, Edition::from_text("Compliance Position A v2"))
            .unwrap();
        // Link b1 ↔ b2 (separate cluster)
        server
            .create_link_with_hyperlink_homed(
                sid,
                crate::edition::links::HyperLink::make(
                    vec![3],
                    crate::edition::links::HyperRef::single(None, Some(b1), None, None),
                    crate::edition::links::HyperRef::single(None, Some(b2), None, None),
                ),
                None,
            )
            .unwrap();

        // Standalone work (no links)
        let c1 = server
            .create_work(sid, Edition::from_text("Random note"))
            .unwrap();
        server.work_grab(sid, c1).unwrap();
        server
            .work_revise(sid, c1, Edition::from_text("Random note v2"))
            .unwrap();

        let result = generate_daily_history(&server);
        assert!(result.is_some(), "history generated");
        let (text, touched) = result.unwrap();

        // All touched works included
        assert!(touched.contains(&a1) && touched.contains(&b1) && touched.contains(&c1));

        // Grouped: project A works together, project B separate
        assert!(text.contains("Topic:"), "topic headers present");
        assert!(
            text.matches("Topic:").count() >= 2 || text.contains("Standalone:"),
            "multiple clusters detected"
        );
        // The two projects are not merged into one cluster
        let a1_pos = text.find("Grid Cells").unwrap_or(0);
        let b1_pos = text.find("Compliance Position").unwrap_or(0);
        let a2_pos = text.find("Boundary Cells").unwrap_or(0);
        // a1 and a2 should be in the same cluster (closer than b1)
        assert!(
            (a1_pos as i64 - a2_pos as i64).abs() < (a1_pos as i64 - b1_pos as i64).abs(),
            "linked works grouped together, separate projects apart"
        );
    }

    #[test]
    fn no_changes_no_history() {
        let server = Server::new();
        assert!(generate_daily_history(&server).is_none());
    }

    #[test]
    fn existing_history_not_duplicated() {
        let mut server = setup();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let w = server
            .create_work(sid, Edition::from_text("fresh work"))
            .unwrap();
        server.work_grab(sid, w).unwrap();
        server
            .work_revise(sid, w, Edition::from_text("fresh work v2"))
            .unwrap();

        // Pre-create today's history
        let today = chrono::Utc::now().format("%Y-%m-%d").to_string();
        let title = format!("Daily History — {}", today);
        let _hw = server.create_work(sid, Edition::from_text(&title)).unwrap();

        assert!(generate_daily_history(&server).is_none(), "no duplicate");
    }
}
