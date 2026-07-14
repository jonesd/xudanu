use std::sync::Arc;
use std::sync::Mutex;

use super::grandmap::Id;
use super::props::{bert_flags_for, sensor_flags_for, PropFinder, IS_SENSOR_WAITING_FLAG};
use super::recorder::RecorderId;

#[derive(Debug, Clone)]
struct CanopyCacheInner {
    cached_crum: Option<Arc<Mutex<CanopyCrumData>>>,
    cached_root: Option<Arc<Mutex<CanopyCrumData>>>,
    cached_path: Vec<Arc<Mutex<CanopyCrumData>>>,
}

impl CanopyCacheInner {
    fn new() -> Self {
        CanopyCacheInner {
            cached_crum: None,
            cached_root: None,
            cached_path: Vec::new(),
        }
    }

    fn _clear(&mut self) {
        self.cached_crum = None;
        self.cached_root = None;
        self.cached_path.clear();
    }

    fn path_for(&mut self, crum: &Arc<Mutex<CanopyCrumData>>) -> Vec<Arc<Mutex<CanopyCrumData>>> {
        if let Some(ref cached) = self.cached_crum {
            if Arc::ptr_eq(cached, crum) {
                return self.cached_path.clone();
            }
        }
        self.cached_crum = Some(crum.clone());
        self.cached_path.clear();
        let mut cur = Some(crum.clone());
        while let Some(c) = cur {
            self.cached_root = Some(c.clone());
            self.cached_path.push(c.clone());
            let parent = c.lock().unwrap_or_else(|e| e.into_inner()).parent.clone();
            cur = parent;
        }
        self.cached_path.clone()
    }

    fn root_for(&mut self, crum: &Arc<Mutex<CanopyCrumData>>) -> Arc<Mutex<CanopyCrumData>> {
        self.path_for(crum);
        self.cached_root.clone().unwrap_or_else(|| crum.clone())
    }

    fn _update_cache_for_parent(
        &mut self,
        child: &Arc<Mutex<CanopyCrumData>>,
        parent: &Arc<Mutex<CanopyCrumData>>,
    ) {
        if self.cached_path.iter().any(|c| Arc::ptr_eq(c, child)) {
            if !self.cached_path.iter().any(|c| Arc::ptr_eq(c, parent)) {
                self.cached_path.push(parent.clone());
            }
            if let Some(ref root) = self.cached_root {
                if Arc::ptr_eq(root, child) {
                    self.cached_root = Some(parent.clone());
                }
            }
        }
    }

    fn _update_cache_for(&mut self, crum: &Arc<Mutex<CanopyCrumData>>) {
        if let Some(ref cached) = self.cached_crum {
            if Arc::ptr_eq(cached, crum) {
                self._clear();
            }
        }
    }

    fn is_cached_path_valid(&self) -> bool {
        self.cached_crum.is_some()
    }
}

#[derive(Debug)]
pub struct CanopyCrumData {
    child1: Option<Arc<Mutex<CanopyCrumData>>>,
    child2: Option<Arc<Mutex<CanopyCrumData>>>,
    parent: Option<Arc<Mutex<CanopyCrumData>>>,
    min_h: i64,
    max_h: i64,
    own_flags: u32,
    flags: u32,
    ref_count: u64,
    kind: CanopyCrumKind,
    cache: Arc<Mutex<CanopyCacheInner>>,
    recorders: Vec<RecorderId>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CanopyCrumKind {
    Bert,
    Sensor,
}

impl CanopyCrumData {
    fn new_leaf(flags: u32, kind: CanopyCrumKind, cache: Arc<Mutex<CanopyCacheInner>>) -> Self {
        CanopyCrumData {
            child1: None,
            child2: None,
            parent: None,
            min_h: 0,
            max_h: 0,
            own_flags: flags,
            flags,
            ref_count: 0,
            kind,
            cache,
            recorders: Vec::new(),
        }
    }

    fn new_parent(
        first: Arc<Mutex<CanopyCrumData>>,
        second: Arc<Mutex<CanopyCrumData>>,
        kind: CanopyCrumKind,
        cache: Arc<Mutex<CanopyCacheInner>>,
    ) -> Self {
        let child_min_h = first
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .min_h
            .min(second.lock().unwrap_or_else(|e| e.into_inner()).min_h);
        let child_max_h = first
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .max_h
            .max(second.lock().unwrap_or_else(|e| e.into_inner()).max_h);
        CanopyCrumData {
            child1: Some(first.clone()),
            child2: Some(second.clone()),
            parent: None,
            min_h: child_min_h - 1,
            max_h: child_max_h + 1,
            own_flags: 0,
            flags: first.lock().unwrap_or_else(|e| e.into_inner()).flags
                | second.lock().unwrap_or_else(|e| e.into_inner()).flags,
            ref_count: 0,
            kind,
            cache,
            recorders: Vec::new(),
        }
    }

    pub fn is_leaf(&self) -> bool {
        self.child1.is_none() && self.child2.is_none()
    }

    pub fn flags(&self) -> u32 {
        self.flags
    }

    pub fn own_flags(&self) -> u32 {
        self.own_flags
    }

    pub fn height_diff(&self) -> i64 {
        self.max_h - self.min_h
    }

    pub fn min_height(&self) -> i64 {
        self.min_h
    }

    pub fn max_height(&self) -> i64 {
        self.max_h
    }

    pub fn add_pointer(&mut self) {
        self.ref_count += 1;
    }

    pub fn remove_pointer(&mut self) {
        if self.ref_count > 0 {
            self.ref_count -= 1;
        }
    }

    pub fn ref_count(&self) -> u64 {
        self.ref_count
    }

    pub fn kind(&self) -> CanopyCrumKind {
        self.kind
    }

    pub fn parent(&self) -> Option<&Arc<Mutex<CanopyCrumData>>> {
        self.parent.as_ref()
    }

    pub fn child1(&self) -> Option<&Arc<Mutex<CanopyCrumData>>> {
        self.child1.as_ref()
    }

    pub fn child2(&self) -> Option<&Arc<Mutex<CanopyCrumData>>> {
        self.child2.as_ref()
    }

    fn _clone_shallow(&self) -> Self {
        CanopyCrumData {
            child1: self.child1.clone(),
            child2: self.child2.clone(),
            parent: self.parent.clone(),
            min_h: self.min_h,
            max_h: self.max_h,
            own_flags: self.own_flags,
            flags: self.flags,
            ref_count: self.ref_count,
            kind: self.kind,
            cache: self.cache.clone(),
            recorders: self.recorders.clone(),
        }
    }

    pub fn recorders(&self) -> &[RecorderId] {
        &self.recorders
    }

    pub fn has_recorders(&self) -> bool {
        !self.recorders.is_empty()
    }

    pub fn install_recorders(&mut self, ids: &[RecorderId]) {
        for id in ids {
            if !self.recorders.contains(id) {
                self.recorders.push(*id);
            }
        }
        if !self.recorders.is_empty() {
            self.own_flags |= IS_SENSOR_WAITING_FLAG;
        }
    }

    pub fn remove_recorders(&mut self, ids: &[RecorderId]) {
        self.recorders.retain(|r| !ids.contains(r));
        if self.recorders.is_empty() {
            self.own_flags &= !IS_SENSOR_WAITING_FLAG;
        }
    }

    fn _set_parent(&mut self, p: Option<Arc<Mutex<CanopyCrumData>>>) {
        self.parent = p;
    }

    pub fn set_own_flags(&mut self, new_flags: u32) {
        self.own_flags = new_flags;
    }

    pub fn change_canopy(&mut self) -> bool {
        let old = self.flags;
        let new_flags = self.own_flags
            | self
                .child1
                .as_ref()
                .map_or(0, |c| c.lock().unwrap_or_else(|e| e.into_inner()).flags)
            | self
                .child2
                .as_ref()
                .map_or(0, |c| c.lock().unwrap_or_else(|e| e.into_inner()).flags);
        self.flags = new_flags;
        new_flags != old
    }

    pub fn change_height(&mut self) -> bool {
        let old_min = self.min_h;
        let old_max = self.max_h;
        if let (Some(ref c1), Some(ref c2)) = (&self.child1, &self.child2) {
            self.min_h = c1
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .min_h
                .min(c2.lock().unwrap_or_else(|e| e.into_inner()).min_h)
                - 1;
            self.max_h = c1
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .max_h
                .max(c2.lock().unwrap_or_else(|e| e.into_inner()).max_h)
                + 1;
        }
        self.min_h != old_min || self.max_h != old_max
    }

    fn include_canopy(
        crum: &Arc<Mutex<CanopyCrumData>>,
        other: Arc<Mutex<CanopyCrumData>>,
    ) -> Arc<Mutex<CanopyCrumData>> {
        let is_leaf = crum.lock().unwrap_or_else(|e| e.into_inner()).is_leaf();
        let other_is_leaf = other.lock().unwrap_or_else(|e| e.into_inner()).is_leaf();
        let height_diff = crum.lock().unwrap_or_else(|e| e.into_inner()).height_diff();
        let other_h = other
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .height_diff();

        if is_leaf && other_is_leaf && height_diff == 0 {
            return Self::make_parent(crum, other);
        }
        if other_h < height_diff {
            let child1 = crum
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .child1
                .clone();
            let child2 = crum
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .child2
                .clone();
            if let (Some(c1), Some(c2)) = (child1, child2) {
                let c1_hd = c1.lock().unwrap_or_else(|e| e.into_inner()).height_diff();
                let c2_hd = c2.lock().unwrap_or_else(|e| e.into_inner()).height_diff();
                if c1_hd > c2_hd {
                    return Self::include_canopy(&c1, other);
                } else {
                    return Self::include_canopy(&c2, other);
                }
            }
        }
        Self::make_parent(crum, other)
    }

    fn make_parent(
        a: &Arc<Mutex<CanopyCrumData>>,
        b: Arc<Mutex<CanopyCrumData>>,
    ) -> Arc<Mutex<CanopyCrumData>> {
        let cache = a.lock().unwrap_or_else(|e| e.into_inner()).cache.clone();
        let kind = a.lock().unwrap_or_else(|e| e.into_inner()).kind;
        let parent = Arc::new(Mutex::new(CanopyCrumData::new_parent(
            a.clone(),
            b.clone(),
            kind,
            cache.clone(),
        )));
        a.lock().unwrap_or_else(|e| e.into_inner()).parent = Some(parent.clone());
        b.lock().unwrap_or_else(|e| e.into_inner()).parent = Some(parent.clone());
        cache
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            ._update_cache_for_parent(a, &parent);
        cache
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            ._update_cache_for_parent(&b, &parent);
        parent
    }
}

pub fn is_le(crum: &Arc<Mutex<CanopyCrumData>>, other: &Arc<Mutex<CanopyCrumData>>) -> bool {
    if Arc::ptr_eq(crum, other) {
        return true;
    }
    let cache = crum.lock().unwrap_or_else(|e| e.into_inner()).cache.clone();
    {
        let guard = cache.lock().unwrap_or_else(|e| e.into_inner());
        if guard.is_cached_path_valid() {
            for c in &guard.cached_path {
                if Arc::ptr_eq(c, other) {
                    return true;
                }
            }
        }
    }
    let mut cur = crum
        .lock()
        .unwrap_or_else(|e| e.into_inner())
        .parent
        .clone();
    while let Some(p) = cur {
        if Arc::ptr_eq(&p, other) {
            return true;
        }
        cur = p.lock().unwrap_or_else(|e| e.into_inner()).parent.clone();
    }
    false
}

pub fn compute_join(
    crum: &Arc<Mutex<CanopyCrumData>>,
    other: &Arc<Mutex<CanopyCrumData>>,
) -> Arc<Mutex<CanopyCrumData>> {
    if Arc::ptr_eq(crum, other) {
        return crum.clone();
    }
    if is_le(crum, other) {
        return other.clone();
    }
    if is_le(other, crum) {
        return crum.clone();
    }
    let root = CanopyCrumData::include_canopy(crum, other.clone());
    root
}

pub fn find_root(crum: &Arc<Mutex<CanopyCrumData>>) -> Arc<Mutex<CanopyCrumData>> {
    let cache = crum.lock().unwrap_or_else(|e| e.into_inner()).cache.clone();
    {
        let guard = cache.lock().unwrap_or_else(|e| e.into_inner());
        if let Some(ref cached_crum) = guard.cached_crum {
            if Arc::ptr_eq(cached_crum, crum) {
                if let Some(ref root) = guard.cached_root {
                    let root_parent = root
                        .lock()
                        .unwrap_or_else(|e| e.into_inner())
                        .parent
                        .clone();
                    if root_parent.is_none() {
                        return root.clone();
                    }
                }
            }
        }
    }
    let mut cur = crum.clone();
    loop {
        let parent = cur.lock().unwrap_or_else(|e| e.into_inner()).parent.clone();
        match parent {
            Some(p) => cur = p,
            None => return cur,
        }
    }
}

pub fn propagate_flags(crum: &Arc<Mutex<CanopyCrumData>>) {
    let mut current = Some(crum.clone());
    while let Some(c) = current {
        let c_guard = &mut c.lock().unwrap_or_else(|e| e.into_inner());
        let changed = c_guard.change_canopy();
        if !changed {
            break;
        }
        current = c_guard.parent.clone();
    }
}

pub fn propagate_height(crum: &Arc<Mutex<CanopyCrumData>>) {
    let mut current = Some(crum.clone());
    while let Some(c) = current {
        let changed = c.lock().unwrap_or_else(|e| e.into_inner()).change_height();
        if changed {
            current = c.lock().unwrap_or_else(|e| e.into_inner()).parent.clone();
        } else {
            break;
        }
    }
}

#[derive(Debug, Clone)]
pub struct BertCanopy {
    cache: Arc<Mutex<CanopyCacheInner>>,
}

impl BertCanopy {
    pub fn new() -> Self {
        BertCanopy {
            cache: Arc::new(Mutex::new(CanopyCacheInner::new())),
        }
    }

    pub fn make_crum(&self, flags: u32) -> Arc<Mutex<CanopyCrumData>> {
        Arc::new(Mutex::new(CanopyCrumData::new_leaf(
            flags,
            CanopyCrumKind::Bert,
            self.cache.clone(),
        )))
    }

    pub fn make_crum_for(
        &self,
        permissions: Option<&[Id]>,
        endorsements: Option<&[Id]>,
        is_not_partializable: bool,
        is_sensor_waiting: bool,
    ) -> Arc<Mutex<CanopyCrumData>> {
        let flags = bert_flags_for(
            permissions,
            endorsements,
            is_not_partializable,
            is_sensor_waiting,
        );
        self.make_crum(flags)
    }

    pub fn join(
        &self,
        a: &Arc<Mutex<CanopyCrumData>>,
        b: &Arc<Mutex<CanopyCrumData>>,
    ) -> Arc<Mutex<CanopyCrumData>> {
        compute_join(a, b)
    }

    pub fn root_of(&self, crum: &Arc<Mutex<CanopyCrumData>>) -> Arc<Mutex<CanopyCrumData>> {
        self.cache
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .root_for(crum)
    }

    pub fn propagate(&self, crum: &Arc<Mutex<CanopyCrumData>>) {
        propagate_flags(crum);
        propagate_height(crum);
    }
}

impl Default for BertCanopy {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug)]
pub struct SensorCanopy {
    cache: Arc<Mutex<CanopyCacheInner>>,
}

impl SensorCanopy {
    pub fn new() -> Self {
        SensorCanopy {
            cache: Arc::new(Mutex::new(CanopyCacheInner::new())),
        }
    }

    pub fn make_crum(&self, flags: u32) -> Arc<Mutex<CanopyCrumData>> {
        Arc::new(Mutex::new(CanopyCrumData::new_leaf(
            flags,
            CanopyCrumKind::Sensor,
            self.cache.clone(),
        )))
    }

    pub fn make_crum_for(
        &self,
        permissions: Option<&[Id]>,
        endorsements: Option<&[Id]>,
        is_partial: bool,
    ) -> Arc<Mutex<CanopyCrumData>> {
        let flags = sensor_flags_for(permissions, endorsements, is_partial);
        self.make_crum(flags)
    }

    pub fn join(
        &self,
        a: &Arc<Mutex<CanopyCrumData>>,
        b: &Arc<Mutex<CanopyCrumData>>,
    ) -> Arc<Mutex<CanopyCrumData>> {
        compute_join(a, b)
    }

    pub fn root_of(&self, crum: &Arc<Mutex<CanopyCrumData>>) -> Arc<Mutex<CanopyCrumData>> {
        self.cache
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .root_for(crum)
    }

    pub fn propagate(&self, crum: &Arc<Mutex<CanopyCrumData>>) {
        propagate_flags(crum);
        propagate_height(crum);
    }

    pub fn recording_agent(
        &self,
        crum: &Arc<Mutex<CanopyCrumData>>,
        recorder_id: RecorderId,
    ) -> Option<Box<dyn super::recorder::AgendaItem>> {
        let already_present = crum.lock().unwrap().recorders().contains(&recorder_id);
        if already_present {
            return None;
        }
        crum.lock().unwrap().install_recorders(&[recorder_id]);
        Some(super::hoist::RecorderHoister::make(
            crum.clone(),
            vec![recorder_id],
        ))
    }
}

impl Default for SensorCanopy {
    fn default() -> Self {
        Self::new()
    }
}

pub fn walk_northward<F>(crum: &Arc<Mutex<CanopyCrumData>>, finder: &PropFinder, visitor: &mut F)
where
    F: FnMut(&Arc<Mutex<CanopyCrumData>>) -> bool,
{
    if finder.is_empty() {
        return;
    }
    let crum_flags = crum.lock().unwrap_or_else(|e| e.into_inner()).flags();
    if !finder.does_pass(crum_flags) {
        return;
    }
    if visitor(crum) {
        return;
    }
    if let Some(ref c1) = crum.lock().unwrap_or_else(|e| e.into_inner()).child1 {
        walk_northward(c1, finder, visitor);
    }
    if let Some(ref c2) = crum.lock().unwrap_or_else(|e| e.into_inner()).child2 {
        walk_northward(c2, finder, visitor);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::props::{
        IS_NOT_PARTIALIZABLE_FLAG, IS_SENSOR_WAITING_FLAG, PUBLIC_CLUB_FLAG,
    };

    #[test]
    fn bert_canopy_make_crum() {
        let canopy = BertCanopy::new();
        let crum = canopy.make_crum(PUBLIC_CLUB_FLAG);
        assert!(crum.lock().unwrap_or_else(|e| e.into_inner()).is_leaf());
        assert_eq!(
            crum.lock().unwrap_or_else(|e| e.into_inner()).flags(),
            PUBLIC_CLUB_FLAG
        );
        assert_eq!(
            crum.lock().unwrap_or_else(|e| e.into_inner()).kind(),
            CanopyCrumKind::Bert
        );
    }

    #[test]
    fn bert_canopy_make_crum_for() {
        let canopy = BertCanopy::new();
        let crum = canopy.make_crum_for(Some(&[Id::global(0)]), None, false, false);
        assert_eq!(
            crum.lock().unwrap_or_else(|e| e.into_inner()).flags(),
            PUBLIC_CLUB_FLAG
        );
    }

    #[test]
    fn canopy_crum_add_remove_pointer() {
        let canopy = BertCanopy::new();
        let crum = canopy.make_crum(0);
        assert_eq!(
            crum.lock().unwrap_or_else(|e| e.into_inner()).ref_count(),
            0
        );
        crum.lock().unwrap_or_else(|e| e.into_inner()).add_pointer();
        assert_eq!(
            crum.lock().unwrap_or_else(|e| e.into_inner()).ref_count(),
            1
        );
        crum.lock()
            .unwrap_or_else(|e| e.into_inner())
            .remove_pointer();
        assert_eq!(
            crum.lock().unwrap_or_else(|e| e.into_inner()).ref_count(),
            0
        );
    }

    #[test]
    fn bert_canopy_join_two_leaves() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let b = canopy.make_crum(IS_SENSOR_WAITING_FLAG);
        let join = canopy.join(&a, &b);
        assert!(!join.lock().unwrap_or_else(|e| e.into_inner()).is_leaf());
        assert_eq!(
            join.lock().unwrap_or_else(|e| e.into_inner()).flags(),
            PUBLIC_CLUB_FLAG | IS_SENSOR_WAITING_FLAG
        );
    }

    #[test]
    fn bert_canopy_join_same_is_noop() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let join = canopy.join(&a, &a);
        assert!(Arc::ptr_eq(&a, &join));
    }

    #[test]
    fn is_le_direct() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(PUBLIC_CLUB_FLAG);
        assert!(is_le(&a, &a));
    }

    #[test]
    fn is_le_parent() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let b = canopy.make_crum(IS_SENSOR_WAITING_FLAG);
        let join = canopy.join(&a, &b);
        assert!(is_le(&a, &join));
        assert!(is_le(&b, &join));
        assert!(!is_le(&join, &a));
    }

    #[test]
    fn find_root_single() {
        let canopy = BertCanopy::new();
        let crum = canopy.make_crum(0);
        let root = find_root(&crum);
        assert!(Arc::ptr_eq(&crum, &root));
    }

    #[test]
    fn find_root_after_join() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(1);
        let b = canopy.make_crum(2);
        let join = canopy.join(&a, &b);
        assert!(Arc::ptr_eq(&find_root(&a), &join));
        assert!(Arc::ptr_eq(&find_root(&b), &join));
    }

    #[test]
    fn change_canopy_propagates() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let b = canopy.make_crum(0);
        let join = canopy.join(&a, &b);
        a.lock().unwrap_or_else(|e| e.into_inner()).set_own_flags(0);
        canopy.propagate(&a);
        assert_eq!(a.lock().unwrap_or_else(|e| e.into_inner()).flags(), 0);
        assert_eq!(join.lock().unwrap_or_else(|e| e.into_inner()).flags(), 0);
    }

    #[test]
    fn sensor_canopy_make_crum() {
        let canopy = SensorCanopy::new();
        let crum = canopy.make_crum(crate::edition::props::IS_PARTIAL_FLAG);
        assert!(crum.lock().unwrap_or_else(|e| e.into_inner()).is_leaf());
        assert_eq!(
            crum.lock().unwrap_or_else(|e| e.into_inner()).kind(),
            CanopyCrumKind::Sensor
        );
    }

    #[test]
    fn walk_northward_finds_leaves() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let b = canopy.make_crum(IS_SENSOR_WAITING_FLAG);
        let _join = canopy.join(&a, &b);

        let finder = PropFinder::open();
        let mut found = Vec::new();
        walk_northward(&find_root(&a), &finder, &mut |crum| {
            if crum.lock().unwrap_or_else(|e| e.into_inner()).is_leaf() {
                found.push(crum.lock().unwrap_or_else(|e| e.into_inner()).flags());
            }
            false
        });
        assert_eq!(found.len(), 2);
    }

    #[test]
    fn walk_northward_prunes_on_closed_finder() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let b = canopy.make_crum(IS_NOT_PARTIALIZABLE_FLAG);
        let _join = canopy.join(&a, &b);

        let finder = PropFinder::closed();
        let mut found = Vec::new();
        walk_northward(&find_root(&a), &finder, &mut |crum| {
            if crum.lock().unwrap_or_else(|e| e.into_inner()).is_leaf() {
                found.push(crum.lock().unwrap_or_else(|e| e.into_inner()).flags());
            }
            false
        });
        assert_eq!(found.len(), 0);
    }

    #[test]
    fn height_after_join() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        let join = canopy.join(&a, &b);
        assert!(join.lock().unwrap_or_else(|e| e.into_inner()).height_diff() >= 2);
    }
}
