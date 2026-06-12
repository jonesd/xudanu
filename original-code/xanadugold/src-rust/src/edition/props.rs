use std::collections::HashMap;
use std::sync::atomic::{AtomicU32, Ordering};

use super::grandmap::Id;
use super::xn_region::XnRegion;

pub const PUBLIC_CLUB_FLAG: u32 = 0x00000001;
pub const OTHER_CLUBS_FLAG: u32 = 0x00000002;
pub const OTHER_ENDORSEMENTS_FLAG: u32 = 0x00000004;
pub const FIRST_ENDORSEMENT_FLAG: u32 = 0x00000008;
pub const IS_SENSOR_WAITING_FLAG: u32 = 0x04000000;
pub const IS_NOT_PARTIALIZABLE_FLAG: u32 = 0x08000000;
pub const IS_PARTIAL_FLAG: u32 = 0x08000000;

const MAX_ENDORSEMENT_FLAGS: usize = 23;

static ENDORSEMENT_FLAG_MAP: std::sync::OnceLock<std::sync::RwLock<HashMap<i64, u32>>> =
    std::sync::OnceLock::new();
static NEXT_ENDORSEMENT_BIT: AtomicU32 = AtomicU32::new(0);

fn endorsement_flag_map() -> &'static std::sync::RwLock<HashMap<i64, u32>> {
    ENDORSEMENT_FLAG_MAP.get_or_init(|| std::sync::RwLock::new(HashMap::new()))
}

pub fn endorsement_flag_for(id_number: i64) -> Option<u32> {
    let map = endorsement_flag_map().read().unwrap();
    map.get(&id_number).copied()
}

pub fn use_endorsement_flag(id_number: i64) -> u32 {
    {
        let map = endorsement_flag_map().read().unwrap();
        if let Some(&flag) = map.get(&id_number) {
            return flag;
        }
    }
    let mut map = endorsement_flag_map().write().unwrap();
    if let Some(&flag) = map.get(&id_number) {
        return flag;
    }
    let bit = NEXT_ENDORSEMENT_BIT.fetch_add(1, Ordering::SeqCst);
    if bit as usize >= MAX_ENDORSEMENT_FLAGS {
        return OTHER_ENDORSEMENTS_FLAG;
    }
    let flag = FIRST_ENDORSEMENT_FLAG << bit;
    map.insert(id_number, flag);
    flag
}

pub fn permissions_flags(permissions: &[Id]) -> u32 {
    if permissions.is_empty() {
        return 0;
    }
    let mut result = 0u32;
    let mut has_public = false;
    let mut has_other = false;
    for id in permissions {
        if id.space.0 == 0 && id.number == 0 {
            has_public = true;
        } else {
            has_other = true;
        }
    }
    if has_public {
        result |= PUBLIC_CLUB_FLAG;
    }
    if has_other {
        result |= OTHER_CLUBS_FLAG;
    }
    result
}

pub fn permissions_region(authority_clubs: &[u64]) -> XnRegion {
    let flags = permissions_flags(
        &authority_clubs
            .iter()
            .map(|&c| Id::global(c as i64))
            .collect::<Vec<_>>(),
    );
    if flags == 0 {
        XnRegion::empty()
    } else {
        XnRegion::singleton(flags as i64)
    }
}

pub fn endorsements_flags(endorsements: &[Id]) -> u32 {
    if endorsements.is_empty() {
        return 0;
    }
    let mut result = 0u32;
    let mut has_untracked = false;
    for id in endorsements {
        if let Some(flag) = endorsement_flag_for(id.number) {
            result |= flag;
        } else {
            has_untracked = true;
        }
    }
    if has_untracked {
        result |= OTHER_ENDORSEMENTS_FLAG;
    }
    result
}

pub fn init_endorsement_flags() {
    use_endorsement_flag(crate::edition::wrapper::TEXT_TOKEN as i64);
    use_endorsement_flag(crate::edition::wrapper::SET_TOKEN as i64);
    use_endorsement_flag(crate::edition::wrapper::PATH_TOKEN as i64);
    use_endorsement_flag(crate::edition::wrapper::HYPERLINK_TOKEN as i64);
    use_endorsement_flag(crate::edition::wrapper::HYPERREF_TOKEN as i64);
}

#[derive(Debug, Clone, PartialEq)]
pub struct BertProp {
    permissions: Vec<Id>,
    endorsements: Vec<Id>,
    is_sensor_waiting: bool,
    is_not_partializable: bool,
}

impl BertProp {
    pub fn new(
        permissions: Vec<Id>,
        endorsements: Vec<Id>,
        is_sensor_waiting: bool,
        is_not_partializable: bool,
    ) -> Self {
        BertProp {
            permissions,
            endorsements,
            is_sensor_waiting,
            is_not_partializable,
        }
    }

    pub fn make() -> Self {
        BertProp {
            permissions: Vec::new(),
            endorsements: Vec::new(),
            is_sensor_waiting: false,
            is_not_partializable: false,
        }
    }

    pub fn permissions_prop(permissions: Vec<Id>) -> Self {
        BertProp {
            permissions,
            endorsements: Vec::new(),
            is_sensor_waiting: false,
            is_not_partializable: false,
        }
    }

    pub fn endorsements_prop(endorsements: Vec<Id>) -> Self {
        BertProp {
            permissions: Vec::new(),
            endorsements,
            is_sensor_waiting: false,
            is_not_partializable: false,
        }
    }

    pub fn detector_waiting_prop() -> Self {
        BertProp {
            permissions: Vec::new(),
            endorsements: Vec::new(),
            is_sensor_waiting: true,
            is_not_partializable: false,
        }
    }

    pub fn cannot_partialize_prop() -> Self {
        BertProp {
            permissions: Vec::new(),
            endorsements: Vec::new(),
            is_sensor_waiting: false,
            is_not_partializable: true,
        }
    }

    pub fn permissions(&self) -> &[Id] {
        &self.permissions
    }

    pub fn endorsements(&self) -> &[Id] {
        &self.endorsements
    }

    pub fn is_sensor_waiting(&self) -> bool {
        self.is_sensor_waiting
    }

    pub fn is_not_partializable(&self) -> bool {
        self.is_not_partializable
    }

    pub fn is_empty(&self) -> bool {
        self.permissions.is_empty()
            && self.endorsements.is_empty()
            && !self.is_sensor_waiting
            && !self.is_not_partializable
    }

    pub fn flags(&self) -> u32 {
        let mut result = 0u32;
        result |= permissions_flags(&self.permissions);
        result |= endorsements_flags(&self.endorsements);
        if self.is_sensor_waiting {
            result |= IS_SENSOR_WAITING_FLAG;
        }
        if self.is_not_partializable {
            result |= IS_NOT_PARTIALIZABLE_FLAG;
        }
        result
    }

    pub fn with(&self, other: &BertProp) -> BertProp {
        let mut perms = self.permissions.clone();
        for p in &other.permissions {
            if !perms.contains(p) {
                perms.push(p.clone());
            }
        }
        let mut endos = self.endorsements.clone();
        for e in &other.endorsements {
            if !endos.contains(e) {
                endos.push(e.clone());
            }
        }
        BertProp {
            permissions: perms,
            endorsements: endos,
            is_sensor_waiting: self.is_sensor_waiting || other.is_sensor_waiting,
            is_not_partializable: self.is_not_partializable || other.is_not_partializable,
        }
    }
}

pub fn bert_flags_for(
    permissions: Option<&[Id]>,
    endorsements: Option<&[Id]>,
    is_not_partializable: bool,
    is_sensor_waiting: bool,
) -> u32 {
    let mut result = 0u32;
    if let Some(perms) = permissions {
        result |= permissions_flags(perms);
    }
    if let Some(endos) = endorsements {
        result |= endorsements_flags(endos);
    }
    if is_not_partializable {
        result |= IS_NOT_PARTIALIZABLE_FLAG;
    }
    if is_sensor_waiting {
        result |= IS_SENSOR_WAITING_FLAG;
    }
    result
}

#[derive(Debug, Clone, PartialEq)]
pub struct SensorProp {
    relevant_permissions: Vec<Id>,
    relevant_endorsements: Vec<Id>,
    is_partial: bool,
}

impl SensorProp {
    pub fn new(
        relevant_permissions: Vec<Id>,
        relevant_endorsements: Vec<Id>,
        is_partial: bool,
    ) -> Self {
        SensorProp {
            relevant_permissions,
            relevant_endorsements,
            is_partial,
        }
    }

    pub fn make() -> Self {
        SensorProp {
            relevant_permissions: Vec::new(),
            relevant_endorsements: Vec::new(),
            is_partial: false,
        }
    }

    pub fn partial() -> Self {
        SensorProp {
            relevant_permissions: Vec::new(),
            relevant_endorsements: Vec::new(),
            is_partial: true,
        }
    }

    pub fn relevant_permissions(&self) -> &[Id] {
        &self.relevant_permissions
    }

    pub fn relevant_endorsements(&self) -> &[Id] {
        &self.relevant_endorsements
    }

    pub fn is_partial(&self) -> bool {
        self.is_partial
    }

    pub fn flags(&self) -> u32 {
        let mut result = 0u32;
        result |= permissions_flags(&self.relevant_permissions);
        result |= endorsements_flags(&self.relevant_endorsements);
        if self.is_partial {
            result |= IS_PARTIAL_FLAG;
        }
        result
    }

    pub fn with(&self, other: &SensorProp) -> SensorProp {
        let mut perms = self.relevant_permissions.clone();
        for p in &other.relevant_permissions {
            if !perms.contains(p) {
                perms.push(p.clone());
            }
        }
        let mut endos = self.relevant_endorsements.clone();
        for e in &other.relevant_endorsements {
            if !endos.contains(e) {
                endos.push(e.clone());
            }
        }
        SensorProp {
            relevant_permissions: perms,
            relevant_endorsements: endos,
            is_partial: self.is_partial || other.is_partial,
        }
    }
}

pub fn sensor_flags_for(
    permissions: Option<&[Id]>,
    endorsements: Option<&[Id]>,
    is_partial: bool,
) -> u32 {
    let mut result = 0u32;
    if let Some(perms) = permissions {
        result |= permissions_flags(perms);
    }
    if let Some(endos) = endorsements {
        result |= endorsements_flags(endos);
    }
    if is_partial {
        result |= IS_PARTIAL_FLAG;
    }
    result
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PropChangeKind {
    Bert,
    CannotPartialize,
    DetectorWaiting,
    Endorsements,
    Permissions,
    Sensor,
}

impl PropChangeKind {
    pub fn is_full(&self) -> bool {
        matches!(self, PropChangeKind::Bert | PropChangeKind::Sensor)
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum Prop {
    Bert(BertProp),
    Sensor(SensorProp),
}

impl Prop {
    pub fn flags(&self) -> u32 {
        match self {
            Prop::Bert(bp) => bp.flags(),
            Prop::Sensor(sp) => sp.flags(),
        }
    }

    pub fn with(&self, other: &Prop) -> Prop {
        match (self, other) {
            (Prop::Bert(a), Prop::Bert(b)) => Prop::Bert(a.with(b)),
            (Prop::Sensor(a), Prop::Sensor(b)) => Prop::Sensor(a.with(b)),
            _ => self.clone(),
        }
    }

    pub fn changed(&self, change: PropChangeKind, new_prop: &Prop) -> Prop {
        match change {
            PropChangeKind::Permissions => match (self, new_prop) {
                (Prop::Bert(old), Prop::Bert(new_p)) => Prop::Bert(BertProp::new(
                    new_p.permissions.clone(),
                    old.endorsements.clone(),
                    old.is_sensor_waiting,
                    old.is_not_partializable,
                )),
                (Prop::Sensor(old), Prop::Sensor(new_p)) => Prop::Sensor(SensorProp::new(
                    new_p.relevant_permissions.clone(),
                    old.relevant_endorsements.clone(),
                    old.is_partial,
                )),
                _ => self.clone(),
            },
            PropChangeKind::Endorsements => match (self, new_prop) {
                (Prop::Bert(old), Prop::Bert(new_p)) => Prop::Bert(BertProp::new(
                    old.permissions.clone(),
                    new_p.endorsements.clone(),
                    old.is_sensor_waiting,
                    old.is_not_partializable,
                )),
                (Prop::Sensor(old), Prop::Sensor(new_p)) => Prop::Sensor(SensorProp::new(
                    old.relevant_permissions.clone(),
                    new_p.relevant_endorsements.clone(),
                    old.is_partial,
                )),
                _ => self.clone(),
            },
            PropChangeKind::CannotPartialize => match (self, new_prop) {
                (Prop::Bert(old), Prop::Bert(new_p)) => Prop::Bert(BertProp::new(
                    old.permissions.clone(),
                    old.endorsements.clone(),
                    old.is_sensor_waiting,
                    new_p.is_not_partializable,
                )),
                _ => self.clone(),
            },
            PropChangeKind::DetectorWaiting => match (self, new_prop) {
                (Prop::Bert(old), Prop::Bert(new_p)) => Prop::Bert(BertProp::new(
                    old.permissions.clone(),
                    old.endorsements.clone(),
                    new_p.is_sensor_waiting,
                    old.is_not_partializable,
                )),
                _ => self.clone(),
            },
            PropChangeKind::Bert | PropChangeKind::Sensor => new_prop.clone(),
        }
    }

    pub fn are_equal_props(&self, change: PropChangeKind, other: &Prop) -> bool {
        match change {
            PropChangeKind::Permissions => match (self, other) {
                (Prop::Bert(a), Prop::Bert(b)) => a.permissions == b.permissions,
                (Prop::Sensor(a), Prop::Sensor(b)) => {
                    a.relevant_permissions == b.relevant_permissions
                }
                _ => false,
            },
            PropChangeKind::Endorsements => match (self, other) {
                (Prop::Bert(a), Prop::Bert(b)) => a.endorsements == b.endorsements,
                (Prop::Sensor(a), Prop::Sensor(b)) => {
                    a.relevant_endorsements == b.relevant_endorsements
                }
                _ => false,
            },
            PropChangeKind::CannotPartialize => match (self, other) {
                (Prop::Bert(a), Prop::Bert(b)) => a.is_not_partializable == b.is_not_partializable,
                _ => false,
            },
            PropChangeKind::DetectorWaiting => match (self, other) {
                (Prop::Bert(a), Prop::Bert(b)) => a.is_sensor_waiting == b.is_sensor_waiting,
                _ => false,
            },
            PropChangeKind::Bert | PropChangeKind::Sensor => self == other,
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct ClosedPropFinder;

#[derive(Debug, Clone, PartialEq)]
pub struct OpenPropFinder;

#[derive(Debug, Clone)]
pub struct BackfollowFinder {
    permissions_filter: Option<XnRegion>,
    endorsements_filter: Option<XnRegion>,
}

#[derive(Debug, Clone)]
pub struct SensorFinder;

#[derive(Debug, Clone)]
pub struct CannotPartializeFinder;

#[derive(Debug, Clone)]
pub enum PropFinder {
    Closed,
    Open,
    Backfollow(BackfollowFinder),
    Sensor(SensorFinder),
    CannotPartialize(CannotPartializeFinder),
}

impl PropFinder {
    pub fn closed() -> Self {
        PropFinder::Closed
    }

    pub fn open() -> Self {
        PropFinder::Open
    }

    pub fn backfollow_permissions(permissions_filter: XnRegion) -> Self {
        PropFinder::Backfollow(BackfollowFinder {
            permissions_filter: Some(permissions_filter),
            endorsements_filter: None,
        })
    }

    pub fn backfollow_full(permissions_filter: XnRegion, endorsements_filter: XnRegion) -> Self {
        PropFinder::Backfollow(BackfollowFinder {
            permissions_filter: Some(permissions_filter),
            endorsements_filter: Some(endorsements_filter),
        })
    }

    pub fn sensor() -> Self {
        PropFinder::Sensor(SensorFinder)
    }

    pub fn cannot_partialize() -> Self {
        PropFinder::CannotPartialize(CannotPartializeFinder)
    }

    pub fn flags(&self) -> u32 {
        match self {
            PropFinder::Closed => 0,
            PropFinder::Open => !0u32,
            PropFinder::Backfollow(f) => {
                let mut flags = 0u32;
                if let Some(ref pf) = f.permissions_filter {
                    if !pf.is_empty() {
                        flags |= PUBLIC_CLUB_FLAG | OTHER_CLUBS_FLAG;
                    }
                }
                if let Some(ref ef) = f.endorsements_filter {
                    if !ef.is_empty() {
                        flags |= PUBLIC_CLUB_FLAG
                            | OTHER_CLUBS_FLAG
                            | OTHER_ENDORSEMENTS_FLAG
                            | FIRST_ENDORSEMENT_FLAG;
                    }
                }
                if flags == 0 {
                    !0u32
                } else {
                    flags
                }
            }
            PropFinder::Sensor(_) => !0u32,
            PropFinder::CannotPartialize(_) => IS_NOT_PARTIALIZABLE_FLAG,
        }
    }

    pub fn is_empty(&self) -> bool {
        matches!(self, PropFinder::Closed)
    }

    pub fn is_full(&self) -> bool {
        matches!(self, PropFinder::Open)
    }

    pub fn does_pass(&self, parent_flags: u32) -> bool {
        (self.flags() | parent_flags) != 0
    }

    pub fn pass(&self, crum_flags: u32) -> PropFinder {
        if self.does_pass(crum_flags) {
            self.clone()
        } else {
            PropFinder::Closed
        }
    }

    pub fn match_prop(&self, prop: &Prop) -> bool {
        match self {
            PropFinder::Closed => false,
            PropFinder::Open => true,
            PropFinder::Backfollow(f) => match prop {
                Prop::Bert(_) => {
                    let perms_match = match &f.permissions_filter {
                        Some(pf) => !pf.is_empty(),
                        None => true,
                    };
                    let endos_match = match &f.endorsements_filter {
                        Some(ef) => !ef.is_empty(),
                        None => true,
                    };
                    perms_match && endos_match
                }
                _ => false,
            },
            PropFinder::Sensor(_) => true,
            PropFinder::CannotPartialize(_) => match prop {
                Prop::Bert(bp) => bp.is_not_partializable,
                _ => false,
            },
        }
    }
}

impl PartialEq for PropFinder {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (PropFinder::Closed, PropFinder::Closed) => true,
            (PropFinder::Open, PropFinder::Open) => true,
            (PropFinder::Sensor(_), PropFinder::Sensor(_)) => true,
            (PropFinder::CannotPartialize(_), PropFinder::CannotPartialize(_)) => true,
            (PropFinder::Backfollow(a), PropFinder::Backfollow(b)) => {
                a.permissions_filter == b.permissions_filter
                    && a.endorsements_filter == b.endorsements_filter
            }
            _ => false,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FilterRegion {
    region: XnRegion,
}

impl FilterRegion {
    pub fn new(region: XnRegion) -> Self {
        FilterRegion { region }
    }

    pub fn empty() -> Self {
        FilterRegion {
            region: XnRegion::empty(),
        }
    }

    pub fn full() -> Self {
        FilterRegion {
            region: XnRegion::full(),
        }
    }

    pub fn match_region(&self, other: &XnRegion) -> bool {
        if self.region.is_full() {
            return true;
        }
        if self.region.is_empty() {
            return false;
        }
        !self.region.intersect(other).is_empty()
    }

    pub fn region(&self) -> &XnRegion {
        &self.region
    }

    pub fn is_empty(&self) -> bool {
        self.region.is_empty()
    }

    pub fn is_full(&self) -> bool {
        self.region.is_full()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bert_prop_empty() {
        let bp = BertProp::make();
        assert!(bp.is_empty());
        assert_eq!(bp.flags(), 0);
    }

    #[test]
    fn bert_prop_with_permissions() {
        let public = Id::global(0);
        let bp = BertProp::permissions_prop(vec![public]);
        assert!(!bp.is_empty());
        assert_eq!(bp.flags() & PUBLIC_CLUB_FLAG, PUBLIC_CLUB_FLAG);
    }

    #[test]
    fn bert_prop_sensor_waiting() {
        let bp = BertProp::detector_waiting_prop();
        assert!(bp.is_sensor_waiting());
        assert!(!bp.is_not_partializable());
        assert_eq!(bp.flags() & IS_SENSOR_WAITING_FLAG, IS_SENSOR_WAITING_FLAG);
    }

    #[test]
    fn bert_prop_cannot_partialize() {
        let bp = BertProp::cannot_partialize_prop();
        assert!(bp.is_not_partializable());
        assert_eq!(
            bp.flags() & IS_NOT_PARTIALIZABLE_FLAG,
            IS_NOT_PARTIALIZABLE_FLAG
        );
    }

    #[test]
    fn bert_prop_with_merges() {
        let a = BertProp::permissions_prop(vec![Id::global(0)]);
        let b = BertProp::detector_waiting_prop();
        let merged = a.with(&b);
        assert!(merged.is_sensor_waiting());
        assert!(!merged.permissions.is_empty());
    }

    #[test]
    fn sensor_prop_empty() {
        let sp = SensorProp::make();
        assert!(!sp.is_partial());
        assert_eq!(sp.flags(), 0);
    }

    #[test]
    fn sensor_prop_partial() {
        let sp = SensorProp::partial();
        assert!(sp.is_partial());
        assert_eq!(sp.flags() & IS_PARTIAL_FLAG, IS_PARTIAL_FLAG);
    }

    #[test]
    fn sensor_prop_with() {
        let a = SensorProp::new(vec![Id::global(1)], Vec::new(), false);
        let b = SensorProp::new(vec![Id::global(2)], Vec::new(), true);
        let merged = a.with(&b);
        assert!(merged.is_partial());
        assert_eq!(merged.relevant_permissions.len(), 2);
    }

    #[test]
    fn prop_finder_closed() {
        let f = PropFinder::closed();
        assert!(f.is_empty());
        assert!(!f.is_full());
        assert!(!f.does_pass(0));
        assert!(f.does_pass(!0u32));
    }

    #[test]
    fn prop_finder_open() {
        let f = PropFinder::open();
        assert!(f.is_full());
        assert!(!f.is_empty());
        assert!(f.does_pass(0));
        assert!(f.does_pass(!0u32));
    }

    #[test]
    fn prop_finder_pass_returns_closed_on_both_zero() {
        let f = PropFinder::closed();
        let result = f.pass(0);
        assert!(result.is_empty());
    }

    #[test]
    fn prop_finder_pass_closed_nonzero_flags() {
        let f = PropFinder::closed();
        let result = f.pass(PUBLIC_CLUB_FLAG);
        assert!(result.is_empty());
    }

    #[test]
    fn prop_finder_pass_returns_self_on_match() {
        let f = PropFinder::cannot_partialize();
        let result = f.pass(IS_NOT_PARTIALIZABLE_FLAG);
        assert!(!result.is_empty());
    }

    #[test]
    fn prop_finder_pass_always_passes_with_flags() {
        let f = PropFinder::cannot_partialize();
        let result = f.pass(0);
        assert!(!result.is_empty());
    }

    #[test]
    fn prop_finder_backfollow_permissions() {
        let f = PropFinder::backfollow_permissions(XnRegion::full());
        assert!(!f.is_empty());
        assert!(f.does_pass(PUBLIC_CLUB_FLAG));
    }

    #[test]
    fn prop_finder_sensor() {
        let f = PropFinder::sensor();
        assert!(!f.is_empty());
        assert!(f.does_pass(0));
    }

    #[test]
    fn prop_changed_permissions() {
        let old = Prop::Bert(BertProp::make());
        let new = Prop::Bert(BertProp::permissions_prop(vec![Id::global(0)]));
        let result = old.changed(PropChangeKind::Permissions, &new);
        match result {
            Prop::Bert(bp) => {
                assert!(!bp.permissions.is_empty());
                assert!(bp.endorsements.is_empty());
            }
            _ => panic!("expected Bert"),
        }
    }

    #[test]
    fn prop_are_equal_permissions() {
        let a = Prop::Bert(BertProp::permissions_prop(vec![Id::global(0)]));
        let b = Prop::Bert(BertProp::permissions_prop(vec![Id::global(0)]));
        let c = Prop::Bert(BertProp::permissions_prop(vec![Id::global(1)]));
        assert!(a.are_equal_props(PropChangeKind::Permissions, &b));
        assert!(!a.are_equal_props(PropChangeKind::Permissions, &c));
    }

    #[test]
    fn use_endorsement_flag_assigns_bits() {
        let flag1 = use_endorsement_flag(100);
        let flag2 = use_endorsement_flag(200);
        assert_ne!(flag1, flag2);
        assert_eq!(flag1 & flag2, 0);
        let flag1_again = use_endorsement_flag(100);
        assert_eq!(flag1, flag1_again);
    }

    #[test]
    fn permissions_flags_public() {
        let flags = permissions_flags(&[Id::global(0)]);
        assert_eq!(flags, PUBLIC_CLUB_FLAG);
    }

    #[test]
    fn permissions_flags_other() {
        let flags = permissions_flags(&[Id::global(42)]);
        assert_eq!(flags, OTHER_CLUBS_FLAG);
    }

    #[test]
    fn permissions_flags_mixed() {
        let flags = permissions_flags(&[Id::global(0), Id::global(42)]);
        assert_eq!(flags, PUBLIC_CLUB_FLAG | OTHER_CLUBS_FLAG);
    }

    #[test]
    fn filter_region_match() {
        let f = FilterRegion::new(XnRegion::interval(0, 100));
        assert!(f.match_region(&XnRegion::interval(50, 150)));
        assert!(!f.match_region(&XnRegion::interval(200, 300)));
    }

    #[test]
    fn filter_region_full_matches_everything() {
        let f = FilterRegion::full();
        assert!(f.match_region(&XnRegion::empty()));
        assert!(f.match_region(&XnRegion::interval(0, 100)));
    }

    #[test]
    fn filter_region_empty_matches_nothing() {
        let f = FilterRegion::empty();
        assert!(!f.match_region(&XnRegion::interval(0, 100)));
    }

    #[test]
    fn bert_flags_for_combines() {
        let flags = bert_flags_for(Some(&[Id::global(0)]), Some(&[Id::global(1)]), true, true);
        assert_eq!(flags & PUBLIC_CLUB_FLAG, PUBLIC_CLUB_FLAG);
        assert_eq!(flags & IS_NOT_PARTIALIZABLE_FLAG, IS_NOT_PARTIALIZABLE_FLAG);
        assert_eq!(flags & IS_SENSOR_WAITING_FLAG, IS_SENSOR_WAITING_FLAG);
    }

    #[test]
    fn test_sensor_flags_for() {
        let flags = crate::edition::props::sensor_flags_for(Some(&[Id::global(0)]), None, true);
        assert_eq!(flags & PUBLIC_CLUB_FLAG, PUBLIC_CLUB_FLAG);
        assert_eq!(flags & IS_PARTIAL_FLAG, IS_PARTIAL_FLAG);
    }
}
