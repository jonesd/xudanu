//! H(G) hypertextuality profiling — Adamski, Błocki, Pisarski,
//! Szewczyk (HT '26). Ten-coordinate profile over a Xudanu corpus;
//! methodology strings ship in the output so papers can cite the
//! exact formulas. Design authority: docs/dev/hg-profile.md.

use std::collections::{BTreeMap, HashMap, HashSet};

use crate::server::server::Server;

#[derive(Debug, Clone, serde::Serialize)]
pub struct HgProfile {
    pub relation_density: f64,
    pub reverse_traversability: f64,
    pub reverse_traversability_mutual: f64,
    pub decentralisation: f64,
    pub modularity: f64,
    pub relation_type_heterogeneity: f64,
    pub transclusion_multicontextuality: f64,
    pub structural_entropy: f64,
    pub path_compactness: f64,
    pub structural_robustness: f64,
    pub generative_capacity: f64,
    pub node_count: usize,
    pub edge_count: usize,
    pub self_edges: usize,
    pub label_histogram: BTreeMap<String, usize>,
    pub transclusion_count: usize,
    pub transcluded_sources: usize,
    pub mean_contexts_per_source: f64,
    pub xudanu_version: String,
    pub methodology: BTreeMap<&'static str, String>,
}

fn shannon_entropy_normalized(counts: &[usize]) -> f64 {
    let total: usize = counts.iter().sum();
    if total == 0 || counts.len() <= 1 {
        return 0.0;
    }
    let n = total as f64;
    let h: f64 = counts
        .iter()
        .filter(|&&c| c > 0)
        .map(|&c| {
            let p = c as f64 / n;
            -p * p.ln()
        })
        .sum();
    (h / (counts.len() as f64).ln()).clamp(0.0, 1.0)
}

/// Undirected adjacency with parallel-edge weights + edge labels.
struct Graph {
    nodes: Vec<u64>,
    /// node -> [(neighbour, weight, label_index)]
    adj: HashMap<u64, Vec<(u64, usize, usize)>>,
    labels: Vec<String>,
    label_counts: Vec<usize>,
    /// directed pair set for mutuality + directed density
    directed: HashSet<(u64, u64)>,
    edge_count: usize,
    self_edges: usize,
}

impl Graph {
    fn add(&mut self, from: u64, to: u64, label: &str) {
        if from == to {
            self.self_edges += 1;
            return;
        }
        let li = match self.labels.iter().position(|l| l == label) {
            Some(i) => i,
            None => {
                self.labels.push(label.to_string());
                self.label_counts.push(0);
                self.labels.len() - 1
            }
        };
        self.label_counts[li] += 1;
        self.directed.insert((from, to));
        self.adj.entry(from).or_default().push((to, 1, li));
        self.adj.entry(to).or_default().push((from, 1, li));
        self.edge_count += 1;
    }

    fn degree(&self, n: &u64) -> usize {
        self.adj
            .get(n)
            .map(|v| v.iter().map(|(_, w, _)| w).sum())
            .unwrap_or(0)
    }

    fn connected_components(&self) -> Vec<Vec<u64>> {
        let mut seen: HashSet<u64> = HashSet::new();
        let mut comps = Vec::new();
        for &n in &self.nodes {
            if seen.contains(&n) {
                continue;
            }
            let mut comp = Vec::new();
            let mut stack = vec![n];
            seen.insert(n);
            while let Some(c) = stack.pop() {
                comp.push(c);
                if let Some(nbrs) = self.adj.get(&c) {
                    for &(nb, _, _) in nbrs {
                        if seen.insert(nb) {
                            stack.push(nb);
                        }
                    }
                }
            }
            comp.sort_unstable();
            comps.push(comp);
        }
        comps
    }

    /// Label-propagation communities (deterministic: id order,
    /// smallest-label tie-break).
    fn communities(&self) -> Vec<Vec<u64>> {
        let mut labels: HashMap<u64, u64> = self
            .nodes
            .iter()
            .enumerate()
            .map(|(i, &n)| (n, i as u64))
            .collect();
        for _ in 0..20 {
            let mut changed = false;
            for &n in &self.nodes {
                let mut counts: BTreeMap<u64, usize> = BTreeMap::new();
                if let Some(nbrs) = self.adj.get(&n) {
                    for &(nb, w, _) in nbrs {
                        *counts.entry(labels[&nb]).or_insert(0) += w;
                    }
                }
                if counts.is_empty() {
                    continue;
                }
                let best = counts
                    .iter()
                    .max_by_key(|(l, c)| (*c, std::cmp::Reverse(**l)))
                    .map(|(l, _)| *l);
                if let Some(b) = best {
                    if labels[&n] != b {
                        labels.insert(n, b);
                        changed = true;
                    }
                }
            }
            if !changed {
                break;
            }
        }
        let mut by_label: BTreeMap<u64, Vec<u64>> = BTreeMap::new();
        for &n in &self.nodes {
            by_label.entry(labels[&n]).or_default().push(n);
        }
        by_label.into_values().collect()
    }

    /// Mean shortest path over reachable ordered pairs (exact BFS).
    fn mean_shortest_path(&self) -> f64 {
        let mut total = 0usize;
        let mut pairs = 0usize;
        for &s in &self.nodes {
            let mut dist: HashMap<u64, usize> = HashMap::new();
            dist.insert(s, 0);
            let mut queue = std::collections::VecDeque::from(vec![s]);
            while let Some(c) = queue.pop_front() {
                let dc = dist[&c];
                if let Some(nbrs) = self.adj.get(&c) {
                    for &(nb, _, _) in nbrs {
                        if !dist.contains_key(&nb) {
                            dist.insert(nb, dc + 1);
                            total += dc + 1;
                            pairs += 1;
                            queue.push_back(nb);
                        }
                    }
                }
            }
        }
        if pairs == 0 {
            0.0
        } else {
            total as f64 / pairs as f64
        }
    }
}

const TYPE_NAMES: &[(u64, &str)] = &[
    (1, "comment"),
    (2, "reference"),
    (3, "disagreement"),
    (4, "quotation"),
    (5, "see-also"),
    (6, "web"),
];

fn type_label(types: &[u64]) -> String {
    types
        .first()
        .and_then(|t| {
            TYPE_NAMES
                .iter()
                .find(|(id, _)| id == t)
                .map(|(_, n)| n.to_string())
        })
        .unwrap_or_else(|| "custom".to_string())
}

pub fn hg_profile(server: &Server) -> HgProfile {
    let nodes: Vec<u64> = server.works.keys().copied().collect();
    let mut g = Graph {
        nodes: nodes.clone(),
        adj: HashMap::new(),
        labels: Vec::new(),
        label_counts: Vec::new(),
        directed: HashSet::new(),
        edge_count: 0,
        self_edges: 0,
    };

    // Link edges: every end's source-work -> every other end's
    // source-work (typed). Multi-ended links contribute their full
    // end-set as one connected claim.
    for ls in server.links.values() {
        let link = &ls.link;
        let label = type_label(link.link_types());
        let mut srcs: Vec<u64> = Vec::new();
        for atts in link.ends().values() {
            for r in atts {
                if let Some(w) = r.work_context() {
                    srcs.push(w);
                }
            }
        }
        srcs.sort_unstable();
        srcs.dedup();
        for (i, &a) in srcs.iter().enumerate() {
            for &b in &srcs[i + 1..] {
                g.add(a, b, &label);
            }
        }
    }

    // Transclusion edges: includer -> source.
    let mut trans_sources: HashSet<u64> = HashSet::new();
    let mut trans_contexts: HashMap<u64, usize> = HashMap::new();
    let mut transclusion_count = 0usize;
    for &wid in &nodes {
        let Ok(ed) = server.work_edition(wid) else {
            continue;
        };
        for (_, carrier) in ed.all_entries() {
            if let crate::edition::range_element::RangeElement::Transclusion {
                source_work_id,
                ..
            } = &carrier.element
            {
                transclusion_count += 1;
                trans_sources.insert(*source_work_id);
                *trans_contexts.entry(*source_work_id).or_insert(0) += 1;
                g.add(wid, *source_work_id, "transclusion");
            }
        }
    }

    let v = nodes.len().max(1);
    let e = g.edge_count;

    // 1. d
    let relation_density = if v > 1 {
        e as f64 / (v * (v - 1)) as f64
    } else {
        0.0
    };

    // 2. rho_rt — systemic (query answerable by model) and mutual.
    let reverse_traversability = if e > 0 { 1.0 } else { 0.0 };
    let mutual = g
        .directed
        .iter()
        .filter(|(a, b)| g.directed.contains(&(*b, *a)))
        .count();
    let reverse_traversability_mutual = if e > 0 { mutual as f64 / e as f64 } else { 0.0 };

    // 3. D = 1 - HHI(degree shares)
    let degrees: Vec<usize> = nodes.iter().map(|n| g.degree(n)).collect();
    let total_deg: usize = degrees.iter().sum();
    let decentralisation = if total_deg > 0 {
        let hhi: f64 = degrees
            .iter()
            .map(|&d| {
                let s = d as f64 / total_deg as f64;
                s * s
            })
            .sum();
        (1.0 - hhi).clamp(0.0, 1.0)
    } else {
        1.0
    };

    // 4. Q modularity (label propagation).
    let m: usize = e; // undirected total edge weight
    let modularity = if m > 0 {
        let comms = g.communities();
        let mut q = 0.0;
        for comp in &comms {
            let set: HashSet<u64> = comp.iter().copied().collect();
            let mut e_c = 0usize;
            let mut deg_c = 0usize;
            for &n in comp {
                if let Some(nbrs) = g.adj.get(&n) {
                    for &(nb, w, _) in nbrs {
                        deg_c += w;
                        if set.contains(&nb) {
                            e_c += w;
                        }
                    }
                }
            }
            // internal edges counted twice in adjacency
            let e_c = e_c / 2;
            q += e_c as f64 / m as f64 - (deg_c as f64 / (2.0 * m as f64)).powi(2);
        }
        q.clamp(-0.5, 1.0)
    } else {
        0.0
    };

    // 5. eta
    let relation_type_heterogeneity = shannon_entropy_normalized(&g.label_counts);

    // 6. theta
    let transclusion_multicontextuality = trans_sources.len() as f64 / v as f64;
    let mean_contexts_per_source = if trans_sources.is_empty() {
        0.0
    } else {
        trans_sources
            .iter()
            .map(|s| trans_contexts[s] as f64)
            .sum::<f64>()
            / trans_sources.len() as f64
    };

    // 7. S — entropy of the degree-value frequency distribution.
    let mut degree_value_counts: BTreeMap<usize, usize> = BTreeMap::new();
    for &d in &degrees {
        *degree_value_counts.entry(d).or_insert(0) += 1;
    }
    let structural_entropy =
        shannon_entropy_normalized(&degree_value_counts.values().copied().collect::<Vec<_>>());

    // 8. P
    let mean_path = g.mean_shortest_path();
    let path_compactness = 1.0 / (1.0 + mean_path);

    // 9. kappa — giant component after top-1% hub removal.
    let structural_robustness = {
        let comps = g.connected_components();
        let giant_before = comps.iter().map(|c| c.len()).max().unwrap_or(0);
        if giant_before == 0 {
            0.0
        } else {
            let mut by_degree: Vec<(u64, usize)> =
                nodes.iter().map(|&n| (n, g.degree(&n))).collect();
            by_degree.sort_by(|a, b| b.1.cmp(&a.1));
            let remove = (v.max(100) / 100).max(1);
            let removed: HashSet<u64> = by_degree.iter().take(remove).map(|(n, _)| *n).collect();
            let mut adj2: HashMap<u64, Vec<u64>> = HashMap::new();
            for (n, nbrs) in &g.adj {
                if removed.contains(n) {
                    continue;
                }
                for &(nb, _, _) in nbrs {
                    if !removed.contains(&nb) {
                        adj2.entry(*n).or_default().push(nb);
                    }
                }
            }
            // largest component of adj2
            let mut seen: HashSet<u64> = HashSet::new();
            let mut giant_after = 0usize;
            let live: Vec<u64> = nodes
                .iter()
                .copied()
                .filter(|n| !removed.contains(n))
                .collect();
            for &n in &live {
                if seen.contains(&n) {
                    continue;
                }
                let mut size = 0;
                let mut stack = vec![n];
                seen.insert(n);
                while let Some(c) = stack.pop() {
                    size += 1;
                    if let Some(nbrs) = adj2.get(&c) {
                        for &nb in nbrs {
                            if seen.insert(nb) {
                                stack.push(nb);
                            }
                        }
                    }
                }
                giant_after = giant_after.max(size);
            }
            giant_after as f64 / giant_before as f64
        }
    };

    // 10. gamma — nodes with version history (static lower bound).
    let evolved = nodes
        .iter()
        .filter(|&&n| {
            server
                .work_revision_count(n)
                .map(|c| c > 1)
                .unwrap_or(false)
        })
        .count();
    let generative_capacity = evolved as f64 / v as f64;

    let mut label_histogram = BTreeMap::new();
    for (l, c) in g.labels.iter().zip(g.label_counts.iter()) {
        label_histogram.insert(l.clone(), *c);
    }

    let mut methodology = BTreeMap::new();
    methodology.insert(
        "relation_density",
        "|E| / (|V|*(|V|-1)), directed, self-edges excluded".into(),
    );
    methodology.insert(
        "reverse_traversability",
        "systemic: fraction of edges whose reverse query the data model answers (links store both ends; backfollow for transclusions). Xudanu = 1.0 by construction".into(),
    );
    methodology.insert(
        "reverse_traversability_mutual",
        "fraction of ordered pairs with represented edges in both directions (structural reading; comparable to IRA 8.99e-5 in Adamski et al.)".into(),
    );
    methodology.insert(
        "decentralisation",
        "1 - HHI(degree shares), undirected degrees".into(),
    );
    methodology.insert(
        "modularity",
        "Q over label-propagation communities (id-order, smallest-label tie-break)".into(),
    );
    methodology.insert(
        "relation_type_heterogeneity",
        "H(link-type label distribution) / ln(k)".into(),
    );
    methodology.insert(
        "transclusion_multicontextuality",
        "(works that are the source of >=1 inline transclusion) / |V|".into(),
    );
    methodology.insert(
        "structural_entropy",
        "H(frequency distribution of degree values) / ln(K)".into(),
    );
    methodology.insert(
        "path_compactness",
        "1 / (1 + mean shortest path), exact BFS".into(),
    );
    methodology.insert(
        "structural_robustness",
        "giant component after targeted top-1% hub removal / before".into(),
    );
    methodology.insert(
        "generative_capacity",
        "fraction of works with revision_count > 1 (static-corpus lower bound of the live property)".into(),
    );

    HgProfile {
        relation_density,
        reverse_traversability,
        reverse_traversability_mutual,
        decentralisation,
        modularity,
        relation_type_heterogeneity,
        transclusion_multicontextuality,
        structural_entropy,
        path_compactness,
        structural_robustness,
        generative_capacity,
        node_count: v,
        edge_count: e,
        self_edges: g.self_edges,
        label_histogram,
        transclusion_count,
        transcluded_sources: trans_sources.len(),
        mean_contexts_per_source,
        xudanu_version: env!("CARGO_PKG_VERSION").to_string(),
        methodology,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::Edition;

    fn server_with(base: &str) -> (Server, crate::server::SessionId, u64, u64) {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let a = server.create_work(sid, Edition::from_text(base)).unwrap();
        let b = server
            .create_work(sid, Edition::from_text("second work for profiling"))
            .unwrap();
        (server, sid, a, b)
    }

    #[test]
    fn two_works_one_typed_link() {
        let (mut server, sid, a, b) = server_with("alpha doc");
        server
            .create_link_with_hyperlink_homed(
                sid,
                crate::edition::links::HyperLink::make(
                    vec![1],
                    crate::edition::links::HyperRef::single(None, Some(a), None, None),
                    crate::edition::links::HyperRef::single(None, Some(b), None, None),
                ),
                None,
            )
            .unwrap();
        let p = hg_profile(&server);
        assert_eq!(p.node_count, 2);
        assert!(p.edge_count >= 1);
        assert_eq!(p.reverse_traversability, 1.0, "systemic by construction");
        assert!(
            (p.relation_density - 0.5).abs() < 1e-9,
            "1 edge / 2 possible"
        );
        assert_eq!(p.transclusion_multicontextuality, 0.0);
        assert_eq!(p.label_histogram.get("comment"), Some(&1));
    }

    #[test]
    fn heterogeneity_rises_with_second_type() {
        let (mut server, sid, a, b) = server_with("alpha doc");
        server
            .create_link_with_hyperlink_homed(
                sid,
                crate::edition::links::HyperLink::make(
                    vec![1],
                    crate::edition::links::HyperRef::single(None, Some(a), None, None),
                    crate::edition::links::HyperRef::single(None, Some(b), None, None),
                ),
                None,
            )
            .unwrap();
        let p1 = hg_profile(&server);
        server
            .create_link_with_hyperlink_homed(
                sid,
                crate::edition::links::HyperLink::make(
                    vec![4],
                    crate::edition::links::HyperRef::single(None, Some(a), None, None),
                    crate::edition::links::HyperRef::single(None, Some(b), None, None),
                ),
                None,
            )
            .unwrap();
        let p2 = hg_profile(&server);
        assert!(p2.relation_type_heterogeneity > p1.relation_type_heterogeneity);
    }

    #[test]
    fn transclusion_gives_nonzero_theta() {
        let (mut server, sid, a, b) = server_with("alpha doc");
        // Inline transclusion b -> a via element_insert.
        server
            .element_insert(
                sid,
                b,
                0,
                crate::edition::range_element::RangeElement::Transclusion {
                    source_work_id: a,
                    char_start: 0,
                    char_end: 5,
                    placed_at: 0,
                    placed_by: None,
                    content_hash: None,
                    source_revision: None,
                },
            )
            .unwrap();
        let p = hg_profile(&server);
        assert!(p.transclusion_count >= 1);
        assert!(
            (p.transclusion_multicontextuality - 0.5).abs() < 1e-9,
            "1 of 2 works transcluded"
        );
        assert_eq!(p.label_histogram.get("transclusion"), Some(&1));
    }
}
