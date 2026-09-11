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
    /// H(G) Q4 (Adamski et al.): author-type-labeled content counts.
    pub author_type_counts: BTreeMap<String, usize>,
    /// H(G) Q4: per-author-type sub-graph profiles. Key = "human",
    /// "llm:model-name", "historical", or "unattributed".
    pub hg_by_author: BTreeMap<String, HgSubProfile>,
    pub methodology: BTreeMap<&'static str, String>,
}

/// Per-author-type sub-profile: the same core coordinates computed
/// on the edge partition attributed to that author type. Nodes are
/// shared across all partitions; only edges differ.
#[derive(Debug, Clone, serde::Serialize)]
pub struct HgSubProfile {
    pub edge_count: usize,
    pub relation_density: f64,
    pub reverse_traversability_mutual: f64,
    pub decentralisation: f64,
    pub modularity: f64,
    pub relation_type_heterogeneity: f64,
    pub structural_entropy: f64,
    pub path_compactness: f64,
    pub structural_robustness: f64,
    pub node_count: usize,
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
    match types.first() {
        Some(t) => TYPE_NAMES
            .iter()
            .find(|(id, _)| id == t)
            .map(|(_, n)| n.to_string())
            .unwrap_or_else(|| format!("type-{}", t)),
        None => "untyped".to_string(),
    }
}

/// H(G) profile scoped to a region (None = all works). Regions Phase C:
/// when the region club carries a tumbler prefix, membership is
/// prefix-based (nested); legacy club matching still includes Phase 1
/// works stamped with the region club.
pub fn hg_profile_region(server: &Server, region: Option<u64>) -> HgProfile {
    let prefix = region.and_then(|club| server.club_region_prefix(club));
    let nodes: Vec<u64> = server
        .works
        .iter()
        .filter(|(_, ws)| {
            region.is_none()
                || ws.region == region
                || prefix
                    .as_deref()
                    .map(|p| {
                        ws.work()
                            .tumbler_path_override()
                            .map(|t| t.starts_with(p))
                            .unwrap_or(false)
                    })
                    .unwrap_or(false)
        })
        .map(|(id, _)| *id)
        .collect();
    hg_profile_nodes(server, nodes)
}

/// H(G) profile scoped to a tumbler prefix (regions Phase C): all works
/// whose tumbler paths fall under the prefix.
pub fn hg_profile_prefix(server: &Server, prefix: &[u64]) -> HgProfile {
    let nodes: Vec<u64> = server
        .works
        .iter()
        .filter(|(_, ws)| {
            ws.work()
                .tumbler_path_override()
                .map(|t| t.starts_with(prefix))
                .unwrap_or(false)
        })
        .map(|(id, _)| *id)
        .collect();
    hg_profile_nodes(server, nodes)
}

/// H(G) profile on a specific set of works (the nodes are the
/// works; edges are derived from links/transclusions between them).
pub fn hg_profile_nodes(server: &Server, nodes: Vec<u64>) -> HgProfile {
    hg_profile_impl(server, nodes)
}

pub fn hg_profile(server: &Server) -> HgProfile {
    let nodes: Vec<u64> = server.works.keys().copied().collect();
    hg_profile_impl(server, nodes)
}

fn hg_profile_impl(server: &Server, nodes: Vec<u64>) -> HgProfile {
    // Induced subgraph: edges count only when BOTH endpoints are in the
    // node set. For the full profile this is a no-op; for region
    // sub-profiles it keeps cross-region edges out (the per-region
    // edge-leak bug).
    let node_set: std::collections::HashSet<u64> = nodes.iter().copied().collect();
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
                    if node_set.contains(&w) {
                        srcs.push(w);
                    }
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

    // Transclusion edges + author-type census (H(G) Q4).
    let mut trans_sources: HashSet<u64> = HashSet::new();
    let mut trans_contexts: HashMap<u64, usize> = HashMap::new();
    let mut transclusion_count = 0usize;
    let mut author_type_counts: BTreeMap<String, usize> = BTreeMap::new();
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
                if node_set.contains(source_work_id) {
                    trans_sources.insert(*source_work_id);
                    *trans_contexts.entry(*source_work_id).or_insert(0) += 1;
                    g.add(wid, *source_work_id, "transclusion");
                }
            }
            if let Some(prov) = &carrier.provenance {
                let key = match prov.author_type {
                    crate::edition::provenance::AuthorType::Human => "human",
                    crate::edition::provenance::AuthorType::Llm => "llm",
                    crate::edition::provenance::AuthorType::Historical => "historical",
                };
                *author_type_counts.entry(key.to_string()).or_insert(0) += 1;
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

    // H(G) Q4: per-author-type sub-graph profiles.
    // Step 1: resolve each work's dominant author type.
    let work_author: HashMap<u64, String> = {
        let mut m = HashMap::new();
        for &wid in &nodes {
            let Ok(ed) = server.work_edition(wid) else {
                continue;
            };
            let mut counts: BTreeMap<String, usize> = BTreeMap::new();
            for (_, carrier) in ed.all_entries() {
                if let Some(prov) = &carrier.provenance {
                    let key = match prov.author_type {
                        crate::edition::provenance::AuthorType::Human => "human".to_string(),
                        crate::edition::provenance::AuthorType::Llm => {
                            format!("llm:{}", prov.llm_model.as_deref().unwrap_or("unknown"))
                        }
                        crate::edition::provenance::AuthorType::Historical => {
                            "historical".to_string()
                        }
                    };
                    *counts.entry(key).or_insert(0) += 1;
                }
            }
            if let Some((dominant, _)) = counts.iter().max_by_key(|(_, c)| **c) {
                m.insert(wid, dominant.clone());
            }
        }
        m
    };

    // Step 2: collect all edges with their origin-work attribution.
    // (Re-scan links + transclusions, tagging each edge.)
    let mut edges_by_author: BTreeMap<String, Vec<(u64, u64, String)>> = BTreeMap::new();
    let author_of = |wid: u64| -> String {
        work_author
            .get(&wid)
            .cloned()
            .unwrap_or_else(|| "unattributed".to_string())
    };

    for ls in server.links.values() {
        let link = &ls.link;
        let label = type_label(link.link_types());
        let mut srcs: Vec<u64> = Vec::new();
        for atts in link.ends().values() {
            for r in atts {
                if let Some(w) = r.work_context() {
                    if node_set.contains(&w) {
                        srcs.push(w);
                    }
                }
            }
        }
        // Link creator = the LEFT end's work (where the link was
        // authored). Attribute the edge to the LEFT-end work's
        // author, not the sorted-first (which loses creator info).
        let origin_wid = link
            .ends()
            .get("LeftEnd")
            .and_then(|v| v.first())
            .and_then(|r| r.work_context())
            .or_else(|| srcs.first().copied());
        let creator_author = origin_wid
            .map(|w| author_of(w))
            .unwrap_or_else(|| "unattributed".to_string());
        srcs.sort_unstable();
        srcs.dedup();
        for (i, &a) in srcs.iter().enumerate() {
            for &b in &srcs[i + 1..] {
                let key = creator_author.clone();
                edges_by_author
                    .entry(key)
                    .or_default()
                    .push((a, b, label.clone()));
            }
        }
    }
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
                if !node_set.contains(source_work_id) {
                    continue;
                }
                let key = author_of(wid);
                edges_by_author.entry(key).or_default().push((
                    wid,
                    *source_work_id,
                    "transclusion".to_string(),
                ));
            }
        }
    }

    // Step 3: compute sub-profiles per author type.
    let mut hg_by_author: BTreeMap<String, HgSubProfile> = BTreeMap::new();
    for (author_key, edges) in &edges_by_author {
        if edges.is_empty() {
            continue;
        }
        let mut sg = Graph {
            nodes: nodes.clone(),
            adj: HashMap::new(),
            labels: Vec::new(),
            label_counts: Vec::new(),
            directed: HashSet::new(),
            edge_count: 0,
            self_edges: 0,
        };
        for (a, b, label) in edges {
            sg.add(*a, *b, label);
        }
        let sv = nodes.len().max(1);
        let se = sg.edge_count;
        let sub = HgSubProfile {
            edge_count: se,
            relation_density: if sv > 1 {
                se as f64 / (sv * (sv - 1)) as f64
            } else {
                0.0
            },
            reverse_traversability_mutual: {
                let mut count = 0;
                for (a, b) in &sg.directed {
                    if sg.directed.contains(&(*b, *a)) {
                        count += 1;
                    }
                }
                if se > 0 {
                    count as f64 / se as f64
                } else {
                    0.0
                }
            },
            decentralisation: {
                let degrees: Vec<usize> = nodes.iter().map(|n| sg.degree(n)).collect();
                let total: usize = degrees.iter().sum();
                if total > 0 {
                    let hhi: f64 = degrees
                        .iter()
                        .map(|&d| {
                            let s = d as f64 / total as f64;
                            s * s
                        })
                        .sum();
                    (1.0 - hhi).clamp(0.0, 1.0)
                } else {
                    1.0
                }
            },
            modularity: {
                let m = se;
                if m > 0 {
                    let comms = sg.communities();
                    let mut q = 0.0;
                    for comp in &comms {
                        let set: HashSet<u64> = comp.iter().copied().collect();
                        let mut e_c = 0usize;
                        let mut deg_c = 0usize;
                        for &n in comp {
                            if let Some(nbrs) = sg.adj.get(&n) {
                                for &(nb, w, _) in nbrs {
                                    deg_c += w;
                                    if set.contains(&nb) {
                                        e_c += w;
                                    }
                                }
                            }
                        }
                        q +=
                            (e_c / 2) as f64 / m as f64 - (deg_c as f64 / (2.0 * m as f64)).powi(2);
                    }
                    q.clamp(-0.5, 1.0)
                } else {
                    0.0
                }
            },
            relation_type_heterogeneity: shannon_entropy_normalized(&sg.label_counts),
            structural_entropy: {
                let degrees: Vec<usize> = nodes.iter().map(|n| sg.degree(n)).collect();
                let mut dvc: BTreeMap<usize, usize> = BTreeMap::new();
                for &d in &degrees {
                    *dvc.entry(d).or_insert(0) += 1;
                }
                shannon_entropy_normalized(&dvc.values().copied().collect::<Vec<_>>())
            },
            path_compactness: {
                let mp = sg.mean_shortest_path();
                1.0 / (1.0 + mp)
            },
            structural_robustness: {
                let comps = sg.connected_components();
                let giant = comps.iter().map(|c| c.len()).max().unwrap_or(0);
                if giant == 0 {
                    0.0
                } else {
                    let mut by_deg: Vec<(u64, usize)> =
                        nodes.iter().map(|&n| (n, sg.degree(&n))).collect();
                    by_deg.sort_by(|a, b| b.1.cmp(&a.1));
                    let rm = (sv.max(100) / 100).max(1);
                    let removed: HashSet<u64> = by_deg.iter().take(rm).map(|(n, _)| *n).collect();
                    let mut adj2: HashMap<u64, Vec<u64>> = HashMap::new();
                    for (n, nbrs) in &sg.adj {
                        if removed.contains(n) {
                            continue;
                        }
                        for &(nb, _, _) in nbrs {
                            if !removed.contains(&nb) {
                                adj2.entry(*n).or_default().push(nb);
                            }
                        }
                    }
                    let mut seen = HashSet::new();
                    let mut giant_after = 0;
                    for &n in nodes.iter().filter(|n| !removed.contains(n)) {
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
                    giant_after as f64 / giant as f64
                }
            },
            node_count: sv,
        };
        hg_by_author.insert(author_key.clone(), sub);
    }

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
        author_type_counts,
        hg_by_author,
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
    fn prefix_profile_is_induced_subgraph() {
        // Regions Phase C + edge-leak regression: a region's profile must
        // count only edges whose BOTH endpoints are in the region —
        // cross-region links belong to no single region's subgraph.
        let mut server = Server::new();
        let admin = server.connect();
        server.login_public(admin).unwrap();
        server.grant_admin_authority(admin).unwrap();
        let club_a = server
            .create_named_club(admin, "region-a", Edition::empty())
            .unwrap();
        let club_b = server
            .create_named_club(admin, "region-b", Edition::empty())
            .unwrap();
        server.region_create(admin, club_a, None).unwrap();
        server.region_create(admin, club_b, None).unwrap();

        let sid_a = server.connect();
        server.login_public(sid_a).unwrap();
        server.session_set_region(sid_a, Some(club_a)).unwrap();
        let a1 = server.create_work(sid_a, Edition::from_text("a1")).unwrap();
        let a2 = server.create_work(sid_a, Edition::from_text("a2")).unwrap();

        let sid_b = server.connect();
        server.login_public(sid_b).unwrap();
        server.session_set_region(sid_b, Some(club_b)).unwrap();
        let b1 = server.create_work(sid_b, Edition::from_text("b1")).unwrap();

        let link = |server: &mut Server, sid, x, y| {
            server
                .create_link_with_hyperlink_homed(
                    sid,
                    crate::edition::links::HyperLink::make(
                        vec![1],
                        crate::edition::links::HyperRef::single(None, Some(x), None, None),
                        crate::edition::links::HyperRef::single(None, Some(y), None, None),
                    ),
                    None,
                )
                .unwrap();
        };
        // Internal A link, and a cross link a1—b1. The cross link is
        // authored by the region-less admin session — region write
        // enforcement (Phase C permeability) forbids region sessions
        // from linking across regions.
        link(&mut server, sid_a, a1, a2);
        link(&mut server, admin, a1, b1);

        let full = hg_profile(&server);
        let region_a = hg_profile_prefix(&server, &[1]);
        assert_eq!(region_a.node_count, 2);
        assert!(
            region_a.edge_count < full.edge_count,
            "region sub-profile must exclude the cross-region edge"
        );
        assert_eq!(
            region_a.edge_count, 1,
            "exactly the one internal edge remains"
        );
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

/// H(G) Q4 armor: per-author sub-profiles computed correctly.
#[cfg(test)]
mod hg_author_tests {
    use super::*;
    use crate::edition::Edition;

    #[test]
    fn per_author_partitioned() {
        let mut server = Server::new();
        let human = server.connect();
        server.login_public(human).unwrap();
        let a = server
            .create_work(human, Edition::from_text("human work a"))
            .unwrap();
        let b = server
            .create_work(human, Edition::from_text("human work b"))
            .unwrap();
        // Element provenance stamps on first revise; create alone doesn't.
        server.work_grab(human, a).unwrap();
        server
            .work_revise(human, a, Edition::from_text("human work a"))
            .unwrap();
        server.work_grab(human, b).unwrap();
        server
            .work_revise(human, b, Edition::from_text("human work b"))
            .unwrap();

        // LLM session creates work c
        let llm = server.connect();
        server.login_public(llm).unwrap();
        server
            .session_set_author_type(
                llm,
                crate::edition::provenance::AuthorType::Llm,
                Some("test-model".to_string()),
            )
            .unwrap();
        let c = server
            .create_work(llm, Edition::from_text("llm work c"))
            .unwrap();
        // Use the public API: grab + revise
        server.work_grab(llm, c).unwrap();
        server
            .work_revise(llm, c, Edition::from_text("llm work c, revised"))
            .unwrap();

        // Human links a↔b, LLM links c→a
        server
            .create_link_with_hyperlink_homed(
                human,
                crate::edition::links::HyperLink::make(
                    vec![2],
                    crate::edition::links::HyperRef::single(None, Some(a), None, None),
                    crate::edition::links::HyperRef::single(None, Some(b), None, None),
                ),
                None,
            )
            .unwrap();
        server
            .create_link_with_hyperlink_homed(
                llm,
                crate::edition::links::HyperLink::make(
                    vec![1],
                    crate::edition::links::HyperRef::single(None, Some(c), None, None),
                    crate::edition::links::HyperRef::single(None, Some(a), None, None),
                ),
                None,
            )
            .unwrap();

        let p = hg_profile(&server);
        // Debug: check the element-level census first
        assert!(
            p.author_type_counts.contains_key("llm"),
            "LLM tagged in element census: {:?}",
            p.author_type_counts
        );
        assert!(
            p.hg_by_author.contains_key("human"),
            "human sub-profile present: {:?}",
            p.hg_by_author.keys()
        );
        assert!(
            p.hg_by_author.contains_key("llm:test-model"),
            "llm sub-profile present: {:?}",
            p.hg_by_author.keys()
        );
        let human_sub = &p.hg_by_author["human"];
        assert!(human_sub.edge_count >= 1, "human edges partitioned");
        let llm_sub = &p.hg_by_author["llm:test-model"];
        assert!(llm_sub.edge_count >= 1, "llm edges partitioned");
    }

    #[test]
    fn unattributed_works_bucketed() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let a = server
            .create_work(sid, Edition::from_text("work a"))
            .unwrap();
        let b = server
            .create_work(sid, Edition::from_text("work b"))
            .unwrap();
        server
            .create_link_with_hyperlink_homed(
                sid,
                crate::edition::links::HyperLink::make(
                    vec![2],
                    crate::edition::links::HyperRef::single(None, Some(a), None, None),
                    crate::edition::links::HyperRef::single(None, Some(b), None, None),
                ),
                None,
            )
            .unwrap();
        let p = hg_profile(&server);
        // Works created without revise_work carry no ElementProvenance,
        // so they're unattributed (create_work doesn't stamp elements).
        assert!(
            !p.hg_by_author.is_empty(),
            "at least one sub-profile exists: {:?}",
            p.hg_by_author.keys()
        );
    }
}
