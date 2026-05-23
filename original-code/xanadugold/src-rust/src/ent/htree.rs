use std::collections::HashSet;
use std::sync::Arc;
use std::sync::Mutex;

use crate::edition::canopy::{compute_join, is_le, BertCanopy, CanopyCrumData};
use crate::edition::props::PropFinder;
use crate::ent::trace::TracePosition;

static mut HCRUM_SEQUENCE: u32 = 0;

fn next_hcrum_sequence() -> u32 {
    unsafe {
        HCRUM_SEQUENCE = (HCRUM_SEQUENCE.wrapping_add(1)) & 0x07FFFFFF;
        HCRUM_SEQUENCE
    }
}

pub trait HPart: std::fmt::Debug + Send {
    fn h_crum(&self) -> Option<Arc<Mutex<HUpperCrumData>>>;
}

#[derive(Debug)]
pub struct HistoryCrumBase {
    hash: u32,
}

impl HistoryCrumBase {
    pub fn new() -> Self {
        HistoryCrumBase {
            hash: next_hcrum_sequence(),
        }
    }

    pub fn hash(&self) -> u32 {
        self.hash
    }
}

#[derive(Debug)]
pub struct HUpperCrumData {
    hcut: TracePosition,
    o_parents: Vec<Arc<Mutex<dyn HPart>>>,
    bert_crum: Arc<Mutex<CanopyCrumData>>,
    base: HistoryCrumBase,
    _bert_canopy: BertCanopy,
}

impl HUpperCrumData {
    pub fn new(
        hcut: TracePosition,
        bert_crum: Arc<Mutex<CanopyCrumData>>,
        bert_canopy: BertCanopy,
    ) -> Self {
        bert_crum
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .add_pointer();
        HUpperCrumData {
            hcut,
            o_parents: Vec::new(),
            bert_crum,
            base: HistoryCrumBase::new(),
            _bert_canopy: bert_canopy,
        }
    }

    pub fn from_two(
        first: Arc<Mutex<dyn HPart>>,
        second: Arc<Mutex<dyn HPart>>,
        hcut: TracePosition,
        bert_canopy: BertCanopy,
    ) -> Self {
        let first_bert = first
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .h_crum()
            .map(|c| {
                c.lock()
                    .unwrap_or_else(|e| e.into_inner())
                    .bert_crum
                    .clone()
            })
            .unwrap_or_else(|| bert_canopy.make_crum(0));
        let second_bert = second
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .h_crum()
            .map(|c| {
                c.lock()
                    .unwrap_or_else(|e| e.into_inner())
                    .bert_crum
                    .clone()
            })
            .unwrap_or_else(|| bert_canopy.make_crum(0));
        let bert_crum = compute_join(&first_bert, &second_bert);
        bert_crum
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .add_pointer();

        let mut data = HUpperCrumData {
            hcut,
            o_parents: Vec::new(),
            bert_crum,
            base: HistoryCrumBase::new(),
            _bert_canopy: bert_canopy,
        };
        data.add_o_parent(first);
        data.add_o_parent(second);
        data
    }

    pub fn hcut(&self) -> TracePosition {
        self.hcut
    }

    pub fn bert_crum(&self) -> &Arc<Mutex<CanopyCrumData>> {
        &self.bert_crum
    }

    pub fn o_parents(&self) -> &[Arc<Mutex<dyn HPart>>] {
        &self.o_parents
    }

    pub fn add_o_parent(&mut self, new_parent: Arc<Mutex<dyn HPart>>) {
        if let Some(hc) = new_parent
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .h_crum()
        {
            self.update_bert_canopy(
                &hc.lock()
                    .unwrap_or_else(|e| e.into_inner())
                    .bert_crum
                    .clone(),
            );
        }
        self.o_parents.push(new_parent);
    }

    pub fn remove_o_parent(&mut self, parent: &Arc<Mutex<dyn HPart>>) {
        self.o_parents.retain(|p| !Arc::ptr_eq(p, parent));
    }

    pub fn is_empty(&self) -> bool {
        self.o_parents.is_empty()
    }

    pub fn in_trace(&self, trace: &TracePosition) -> bool {
        if self.hcut.is_equal(trace) {
            return true;
        }
        for op in &self.o_parents {
            if let Some(hc) = op.lock().unwrap_or_else(|e| e.into_inner()).h_crum() {
                if hc.lock().unwrap_or_else(|e| e.into_inner()).in_trace(trace) {
                    return true;
                }
            }
        }
        false
    }

    pub fn any_passes(&self, finder: &PropFinder) -> bool {
        let flags = self
            .bert_crum
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .flags();
        if !finder.does_pass(flags) {
            return false;
        }
        for op in &self.o_parents {
            if let Some(hc) = op.lock().unwrap_or_else(|e| e.into_inner()).h_crum() {
                if hc
                    .lock()
                    .unwrap_or_else(|e| e.into_inner())
                    .any_passes(finder)
                {
                    return true;
                }
            }
        }
        false
    }

    pub fn delayed_store_backfollow(
        crum: &Arc<Mutex<HUpperCrumData>>,
        finder: &PropFinder,
        hcrum_cache: &mut HashSet<u32>,
        visitor: &mut dyn FnMut(&Arc<Mutex<HUpperCrumData>>),
    ) {
        let hash = crum.lock().unwrap_or_else(|e| e.into_inner()).base.hash;
        if hcrum_cache.contains(&hash) {
            return;
        }
        hcrum_cache.insert(hash);
        Self::actual_delayed_store_backfollow(crum, finder, hcrum_cache, visitor);
    }

    fn actual_delayed_store_backfollow(
        crum: &Arc<Mutex<HUpperCrumData>>,
        finder: &PropFinder,
        hcrum_cache: &mut HashSet<u32>,
        visitor: &mut dyn FnMut(&Arc<Mutex<HUpperCrumData>>),
    ) {
        let new_finder = {
            let data = crum.lock().unwrap_or_else(|e| e.into_inner());
            let crum_flags = data
                .bert_crum
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .flags();
            finder.pass(crum_flags)
        };
        if new_finder.is_empty() {
            return;
        }
        visitor(crum);

        let o_parents: Vec<Arc<Mutex<dyn HPart>>> = crum
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .o_parents
            .clone();
        for loaf in &o_parents {
            if let Some(hc) = loaf.lock().unwrap_or_else(|e| e.into_inner()).h_crum() {
                Self::delayed_store_backfollow(&hc, &new_finder, hcrum_cache, visitor);
            }
        }
    }

    pub fn propagate_b_crum(&mut self, new_b_crum: &Arc<Mutex<CanopyCrumData>>) -> bool {
        if is_le(&self.bert_crum, new_b_crum) {
            return false;
        }
        self.bert_crum = new_b_crum.clone();
        true
    }

    fn update_bert_canopy(&mut self, b_crum: &Arc<Mutex<CanopyCrumData>>) {
        if !is_le(&self.bert_crum, b_crum) {
            let old = self.bert_crum.clone();
            self.bert_crum = compute_join(&old, b_crum);
            self.bert_crum
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .add_pointer();
            old.lock()
                .unwrap_or_else(|e| e.into_inner())
                .remove_pointer();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::props::PUBLIC_CLUB_FLAG;
    use crate::ent::branch::BranchStore;

    fn make_trace(pos: u32) -> TracePosition {
        let mut store = BranchStore::new();
        let (branch_id, _) = store.create_root();
        TracePosition::new(branch_id, pos)
    }

    #[test]
    fn h_upper_crum_new() {
        let canopy = BertCanopy::new();
        let bert = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let trace = make_trace(1);
        let hcrum = Arc::new(Mutex::new(HUpperCrumData::new(
            trace,
            bert,
            BertCanopy::new(),
        )));
        assert!(hcrum.lock().unwrap_or_else(|e| e.into_inner()).is_empty());
        assert_eq!(
            hcrum
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .o_parents()
                .len(),
            0
        );
    }

    #[test]
    fn h_upper_crum_add_remove_o_parent() {
        let canopy = BertCanopy::new();
        let bert = canopy.make_crum(0);
        let trace = make_trace(1);

        #[derive(Debug)]
        struct MockPart {
            hcrum: Option<Arc<Mutex<HUpperCrumData>>>,
        }
        impl HPart for MockPart {
            fn h_crum(&self) -> Option<Arc<Mutex<HUpperCrumData>>> {
                self.hcrum.clone()
            }
        }

        let mut hcrum = HUpperCrumData::new(trace, bert, BertCanopy::new());
        let trace2 = make_trace(2);
        let bert2 = canopy.make_crum(0);
        let child_hcrum = Arc::new(Mutex::new(HUpperCrumData::new(
            trace2,
            bert2,
            BertCanopy::new(),
        )));
        let part: Arc<Mutex<dyn HPart>> = Arc::new(Mutex::new(MockPart {
            hcrum: Some(child_hcrum),
        }));
        hcrum.add_o_parent(part.clone());
        assert_eq!(hcrum.o_parents().len(), 1);
        assert!(!hcrum.is_empty());

        hcrum.remove_o_parent(&part);
        assert!(hcrum.is_empty());
    }

    #[test]
    fn h_upper_crum_in_trace() {
        let canopy = BertCanopy::new();
        let trace = make_trace(5);
        let bert = canopy.make_crum(0);
        let hcrum = Arc::new(Mutex::new(HUpperCrumData::new(
            trace,
            bert,
            BertCanopy::new(),
        )));
        assert!(hcrum
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .in_trace(&make_trace(5)));
    }

    #[test]
    fn h_upper_crum_delayed_store_backfollow_visits() {
        let canopy = BertCanopy::new();
        let trace = make_trace(1);
        let bert = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let hcrum = Arc::new(Mutex::new(HUpperCrumData::new(
            trace,
            bert,
            BertCanopy::new(),
        )));

        let finder = PropFinder::open();
        let mut cache = HashSet::new();
        let mut visited = Vec::new();
        HUpperCrumData::delayed_store_backfollow(&hcrum, &finder, &mut cache, &mut |c| {
            visited.push(c.lock().unwrap_or_else(|e| e.into_inner()).base.hash);
        });
        assert_eq!(visited.len(), 1);
    }

    #[test]
    fn h_upper_crum_delayed_store_backfollow_caches() {
        let canopy = BertCanopy::new();
        let trace = make_trace(1);
        let bert = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let hcrum = Arc::new(Mutex::new(HUpperCrumData::new(
            trace,
            bert,
            BertCanopy::new(),
        )));

        let finder = PropFinder::open();
        let mut cache = HashSet::new();
        cache.insert(hcrum.lock().unwrap_or_else(|e| e.into_inner()).base.hash);
        let mut visited = Vec::new();
        HUpperCrumData::delayed_store_backfollow(&hcrum, &finder, &mut cache, &mut |c| {
            visited.push(c.lock().unwrap_or_else(|e| e.into_inner()).base.hash);
        });
        assert_eq!(visited.len(), 0);
    }

    #[test]
    fn h_upper_crum_propagate_b_crum() {
        let canopy = BertCanopy::new();
        let bert1 = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let trace = make_trace(1);
        let mut hcrum = HUpperCrumData::new(trace, bert1.clone(), BertCanopy::new());

        let bert2 = canopy.make_crum(0);
        let join = compute_join(&bert1, &bert2);
        // bert1 is already LE of join, so no propagation needed
        assert!(!hcrum.propagate_b_crum(&join));

        // A fresh crum that is NOT LE of bert1 should propagate
        let bert3 = canopy.make_crum(0);
        assert!(hcrum.propagate_b_crum(&bert3));
    }

    #[test]
    fn h_upper_crum_propagate_b_crum_already_le() {
        let canopy = BertCanopy::new();
        let bert1 = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let trace = make_trace(1);
        let mut hcrum = HUpperCrumData::new(trace, bert1.clone(), BertCanopy::new());

        assert!(!hcrum.propagate_b_crum(&bert1));
    }

    #[test]
    fn any_passes_with_children() {
        let canopy = BertCanopy::new();
        let trace = make_trace(1);
        let bert = canopy.make_crum(PUBLIC_CLUB_FLAG);

        #[derive(Debug)]
        struct LeafPart;
        impl HPart for LeafPart {
            fn h_crum(&self) -> Option<Arc<Mutex<HUpperCrumData>>> {
                None
            }
        }

        let mut hcrum = HUpperCrumData::new(trace, bert, BertCanopy::new());
        let child: Arc<Mutex<dyn HPart>> = Arc::new(Mutex::new(LeafPart));
        hcrum.add_o_parent(child);

        let finder = PropFinder::open();
        // open finder does_pass the flags, but child has no h_crum
        // so any_passes depends on at least one child's h_crum passing
        // Since the child has no h_crum, it returns false
        assert!(!hcrum.any_passes(&finder));

        let closed = PropFinder::closed();
        assert!(!hcrum.any_passes(&closed));
    }

    #[test]
    fn any_passes_empty() {
        let canopy = BertCanopy::new();
        let trace = make_trace(1);
        let bert = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let hcrum = Arc::new(Mutex::new(HUpperCrumData::new(
            trace,
            bert,
            BertCanopy::new(),
        )));

        let finder = PropFinder::open();
        assert!(!hcrum
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .any_passes(&finder));
    }
}
