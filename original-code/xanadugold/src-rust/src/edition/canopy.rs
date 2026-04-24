use std::cell::RefCell;
use std::rc::Rc;

use super::props::{
    bert_flags_for, sensor_flags_for, PropFinder,
};
use super::grandmap::Id;

#[derive(Debug, Clone)]
struct CanopyCacheInner {
    cached_crum: Option<Rc<RefCell<CanopyCrumData>>>,
    cached_root: Option<Rc<RefCell<CanopyCrumData>>>,
    cached_path: Vec<Rc<RefCell<CanopyCrumData>>>,
}

impl CanopyCacheInner {
    fn new() -> Self {
        CanopyCacheInner {
            cached_crum: None,
            cached_root: None,
            cached_path: Vec::new(),
        }
    }

    fn clear(&mut self) {
        self.cached_crum = None;
        self.cached_root = None;
        self.cached_path.clear();
    }

    fn path_for(&mut self, crum: &Rc<RefCell<CanopyCrumData>>) -> Vec<Rc<RefCell<CanopyCrumData>>> {
        if let Some(ref cached) = self.cached_crum {
            if Rc::ptr_eq(cached, crum) {
                return self.cached_path.clone();
            }
        }
        self.cached_crum = Some(crum.clone());
        self.cached_path.clear();
        let mut cur = Some(crum.clone());
        while let Some(c) = cur {
            self.cached_root = Some(c.clone());
            self.cached_path.push(c.clone());
            let parent = c.borrow().parent.clone();
            cur = parent;
        }
        self.cached_path.clone()
    }

    fn root_for(&mut self, crum: &Rc<RefCell<CanopyCrumData>>) -> Rc<RefCell<CanopyCrumData>> {
        self.path_for(crum);
        self.cached_root.clone().unwrap_or_else(|| crum.clone())
    }

    fn update_cache_for_parent(
        &mut self,
        child: &Rc<RefCell<CanopyCrumData>>,
        parent: &Rc<RefCell<CanopyCrumData>>,
    ) {
        if self.cached_path.iter().any(|c| Rc::ptr_eq(c, child)) {
            if !self.cached_path.iter().any(|c| Rc::ptr_eq(c, parent)) {
                self.cached_path.push(parent.clone());
            }
            if let Some(ref root) = self.cached_root {
                if Rc::ptr_eq(root, child) {
                    self.cached_root = Some(parent.clone());
                }
            }
        }
    }

    fn update_cache_for(&mut self, crum: &Rc<RefCell<CanopyCrumData>>) {
        if let Some(ref cached) = self.cached_crum {
            if Rc::ptr_eq(cached, crum) {
                self.clear();
            }
        }
    }}

#[derive(Debug)]
pub struct CanopyCrumData {
    child1: Option<Rc<RefCell<CanopyCrumData>>>,
    child2: Option<Rc<RefCell<CanopyCrumData>>>,
    parent: Option<Rc<RefCell<CanopyCrumData>>>,
    min_h: i64,
    max_h: i64,
    own_flags: u32,
    flags: u32,
    ref_count: u64,
    kind: CanopyCrumKind,
    cache: Rc<RefCell<CanopyCacheInner>>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CanopyCrumKind {
    Bert,
    Sensor,
}

impl CanopyCrumData {
    fn new_leaf(flags: u32, kind: CanopyCrumKind, cache: Rc<RefCell<CanopyCacheInner>>) -> Self {
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
        }
    }

    fn new_parent(
        first: Rc<RefCell<CanopyCrumData>>,
        second: Rc<RefCell<CanopyCrumData>>,
        kind: CanopyCrumKind,
        cache: Rc<RefCell<CanopyCacheInner>>,
    ) -> Self {
        let child_min_h = first.borrow().min_h.min(second.borrow().min_h);
        let child_max_h = first.borrow().max_h.max(second.borrow().max_h);
        CanopyCrumData {
            child1: Some(first.clone()),
            child2: Some(second.clone()),
            parent: None,
            min_h: child_min_h - 1,
            max_h: child_max_h + 1,
            own_flags: 0,
            flags: first.borrow().flags | second.borrow().flags,
            ref_count: 0,
            kind,
            cache,
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

    pub fn parent(&self) -> Option<&Rc<RefCell<CanopyCrumData>>> {
        self.parent.as_ref()
    }

    pub fn child1(&self) -> Option<&Rc<RefCell<CanopyCrumData>>> {
        self.child1.as_ref()
    }

    pub fn child2(&self) -> Option<&Rc<RefCell<CanopyCrumData>>> {
        self.child2.as_ref()
    }

    fn clone_shallow(&self) -> Self {
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
        }
    }

    fn set_parent(&mut self, p: Option<Rc<RefCell<CanopyCrumData>>>) {
        self.parent = p;
    }

    fn set_own_flags(&mut self, new_flags: u32) {
        self.own_flags = new_flags;
    }

    pub fn change_canopy(&mut self) -> bool {
        let old = self.flags;
        let new_flags = self.own_flags
            | self.child1.as_ref().map_or(0, |c| c.borrow().flags)
            | self.child2.as_ref().map_or(0, |c| c.borrow().flags);
        self.flags = new_flags;
        new_flags != old
    }

    pub fn change_height(&mut self) -> bool {
        let old_min = self.min_h;
        let old_max = self.max_h;
        if let (Some(ref c1), Some(ref c2)) = (&self.child1, &self.child2) {
            self.min_h = c1.borrow().min_h.min(c2.borrow().min_h) - 1;
            self.max_h = c1.borrow().max_h.max(c2.borrow().max_h) + 1;
        }
        self.min_h != old_min || self.max_h != old_max
    }

    fn include_canopy(
        crum: &Rc<RefCell<CanopyCrumData>>,
        other: Rc<RefCell<CanopyCrumData>>,
    ) -> Rc<RefCell<CanopyCrumData>> {
        let is_leaf = crum.borrow().is_leaf();
        let other_is_leaf = other.borrow().is_leaf();
        let height_diff = crum.borrow().height_diff();
        let other_h = other.borrow().height_diff();

        if is_leaf && other_is_leaf && height_diff == 0 {
            return Self::make_parent(crum, other);
        }
        if other_h < height_diff {
            let child1 = crum.borrow().child1.clone();
            let child2 = crum.borrow().child2.clone();
            if let (Some(c1), Some(c2)) = (child1, child2) {
                let c1_hd = c1.borrow().height_diff();
                let c2_hd = c2.borrow().height_diff();
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
        a: &Rc<RefCell<CanopyCrumData>>,
        b: Rc<RefCell<CanopyCrumData>>,
    ) -> Rc<RefCell<CanopyCrumData>> {
        let cache = a.borrow().cache.clone();
        let kind = a.borrow().kind;
        let parent = Rc::new(RefCell::new(CanopyCrumData::new_parent(
            a.clone(),
            b.clone(),
            kind,
            cache,
        )));
        a.borrow_mut().parent = Some(parent.clone());
        b.borrow_mut().parent = Some(parent.clone());
        parent
    }
}

pub fn is_le(
    crum: &Rc<RefCell<CanopyCrumData>>,
    other: &Rc<RefCell<CanopyCrumData>>,
) -> bool {
    if Rc::ptr_eq(crum, other) {
        return true;
    }
    let mut cur = crum.borrow().parent.clone();
    while let Some(p) = cur {
        if Rc::ptr_eq(&p, other) {
            return true;
        }
        cur = p.borrow().parent.clone();
    }
    false
}

pub fn compute_join(
    crum: &Rc<RefCell<CanopyCrumData>>,
    other: &Rc<RefCell<CanopyCrumData>>,
) -> Rc<RefCell<CanopyCrumData>> {
    if Rc::ptr_eq(crum, other) {
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

pub fn find_root(crum: &Rc<RefCell<CanopyCrumData>>) -> Rc<RefCell<CanopyCrumData>> {
    let mut cur = crum.clone();
    loop {
        let parent = cur.borrow().parent.clone();
        match parent {
            Some(p) => cur = p,
            None => return cur,
        }
    }
}

pub fn propagate_flags(crum: &Rc<RefCell<CanopyCrumData>>) {
    let mut current = Some(crum.clone());
    while let Some(c) = current {
        let changed = c.borrow_mut().change_canopy();
        if changed {
            current = c.borrow().parent.clone();
        } else {
            break;
        }
    }
}

pub fn propagate_height(crum: &Rc<RefCell<CanopyCrumData>>) {
    let mut current = Some(crum.clone());
    while let Some(c) = current {
        let changed = c.borrow_mut().change_height();
        if changed {
            current = c.borrow().parent.clone();
        } else {
            break;
        }
    }
}

#[derive(Debug)]
pub struct BertCanopy {
    cache: Rc<RefCell<CanopyCacheInner>>,
}

impl BertCanopy {
    pub fn new() -> Self {
        BertCanopy {
            cache: Rc::new(RefCell::new(CanopyCacheInner::new())),
        }
    }

    pub fn make_crum(&self, flags: u32) -> Rc<RefCell<CanopyCrumData>> {
        Rc::new(RefCell::new(CanopyCrumData::new_leaf(
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
    ) -> Rc<RefCell<CanopyCrumData>> {
        let flags = bert_flags_for(permissions, endorsements, is_not_partializable, is_sensor_waiting);
        self.make_crum(flags)
    }

    pub fn join(
        &self,
        a: &Rc<RefCell<CanopyCrumData>>,
        b: &Rc<RefCell<CanopyCrumData>>,
    ) -> Rc<RefCell<CanopyCrumData>> {
        compute_join(a, b)
    }

    pub fn root_of(&self, crum: &Rc<RefCell<CanopyCrumData>>) -> Rc<RefCell<CanopyCrumData>> {
        self.cache.borrow_mut().root_for(crum)
    }

    pub fn propagate(&self, crum: &Rc<RefCell<CanopyCrumData>>) {
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
    cache: Rc<RefCell<CanopyCacheInner>>,
}

impl SensorCanopy {
    pub fn new() -> Self {
        SensorCanopy {
            cache: Rc::new(RefCell::new(CanopyCacheInner::new())),
        }
    }

    pub fn make_crum(&self, flags: u32) -> Rc<RefCell<CanopyCrumData>> {
        Rc::new(RefCell::new(CanopyCrumData::new_leaf(
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
    ) -> Rc<RefCell<CanopyCrumData>> {
        let flags = sensor_flags_for(permissions, endorsements, is_partial);
        self.make_crum(flags)
    }

    pub fn join(
        &self,
        a: &Rc<RefCell<CanopyCrumData>>,
        b: &Rc<RefCell<CanopyCrumData>>,
    ) -> Rc<RefCell<CanopyCrumData>> {
        compute_join(a, b)
    }

    pub fn root_of(&self, crum: &Rc<RefCell<CanopyCrumData>>) -> Rc<RefCell<CanopyCrumData>> {
        self.cache.borrow_mut().root_for(crum)
    }

    pub fn propagate(&self, crum: &Rc<RefCell<CanopyCrumData>>) {
        propagate_flags(crum);
        propagate_height(crum);
    }
}

impl Default for SensorCanopy {
    fn default() -> Self {
        Self::new()
    }
}

pub fn walk_northward<F>(
    crum: &Rc<RefCell<CanopyCrumData>>,
    finder: &PropFinder,
    visitor: &mut F,
) where
    F: FnMut(&Rc<RefCell<CanopyCrumData>>) -> bool,
{
    if finder.is_empty() {
        return;
    }
    let crum_flags = crum.borrow().flags();
    if !finder.does_pass(crum_flags) {
        return;
    }
    if visitor(crum) {
        return;
    }
    if let Some(ref c1) = crum.borrow().child1 {
        walk_northward(c1, finder, visitor);
    }
    if let Some(ref c2) = crum.borrow().child2 {
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
        assert!(crum.borrow().is_leaf());
        assert_eq!(crum.borrow().flags(), PUBLIC_CLUB_FLAG);
        assert_eq!(crum.borrow().kind(), CanopyCrumKind::Bert);
    }

    #[test]
    fn bert_canopy_make_crum_for() {
        let canopy = BertCanopy::new();
        let crum = canopy.make_crum_for(
            Some(&[Id::global(0)]),
            None,
            false,
            false,
        );
        assert_eq!(crum.borrow().flags(), PUBLIC_CLUB_FLAG);
    }

    #[test]
    fn canopy_crum_add_remove_pointer() {
        let canopy = BertCanopy::new();
        let crum = canopy.make_crum(0);
        assert_eq!(crum.borrow().ref_count(), 0);
        crum.borrow_mut().add_pointer();
        assert_eq!(crum.borrow().ref_count(), 1);
        crum.borrow_mut().remove_pointer();
        assert_eq!(crum.borrow().ref_count(), 0);
    }

    #[test]
    fn bert_canopy_join_two_leaves() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let b = canopy.make_crum(IS_SENSOR_WAITING_FLAG);
        let join = canopy.join(&a, &b);
        assert!(!join.borrow().is_leaf());
        assert_eq!(
            join.borrow().flags(),
            PUBLIC_CLUB_FLAG | IS_SENSOR_WAITING_FLAG
        );
    }

    #[test]
    fn bert_canopy_join_same_is_noop() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let join = canopy.join(&a, &a);
        assert!(Rc::ptr_eq(&a, &join));
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
        assert!(Rc::ptr_eq(&crum, &root));
    }

    #[test]
    fn find_root_after_join() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(1);
        let b = canopy.make_crum(2);
        let join = canopy.join(&a, &b);
        assert!(Rc::ptr_eq(&find_root(&a), &join));
        assert!(Rc::ptr_eq(&find_root(&b), &join));
    }

    #[test]
    fn change_canopy_propagates() {
        let canopy = BertCanopy::new();
        let a = canopy.make_crum(PUBLIC_CLUB_FLAG);
        let b = canopy.make_crum(0);
        let join = canopy.join(&a, &b);
        a.borrow_mut().set_own_flags(0);
        canopy.propagate(&a);
        assert_eq!(a.borrow().flags(), 0);
        assert_eq!(join.borrow().flags(), 0);
    }

    #[test]
    fn sensor_canopy_make_crum() {
        let canopy = SensorCanopy::new();
        let crum = canopy.make_crum(crate::edition::props::IS_PARTIAL_FLAG);
        assert!(crum.borrow().is_leaf());
        assert_eq!(crum.borrow().kind(), CanopyCrumKind::Sensor);
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
            if crum.borrow().is_leaf() {
                found.push(crum.borrow().flags());
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
            if crum.borrow().is_leaf() {
                found.push(crum.borrow().flags());
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
        assert!(join.borrow().height_diff() >= 2);
    }
}
