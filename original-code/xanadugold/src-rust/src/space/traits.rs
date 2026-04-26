use std::cmp::Ordering;
use std::fmt::Debug;
use std::hash::Hash;

pub trait Space: Debug + Clone + PartialEq + Eq + Hash + Send + Sync + 'static {
    type Position: Position<Region = Self::Region>;
    type Region: Region<Position = Self::Position>;
    type Dsp: Dsp<Position = Self::Position, Region = Self::Region>;

    fn empty_region(&self) -> Self::Region;
    fn full_region(&self) -> Self::Region;
    fn identity_dsp(&self) -> Self::Dsp;
    fn ascending(&self) -> Box<dyn OrderSpec<Position = Self::Position>>;
    fn descending(&self) -> Box<dyn OrderSpec<Position = Self::Position>>;
}

pub trait Position: Debug + Clone + PartialEq + Eq + Hash + Send + Sync + 'static {
    type Region: Region<Position = Self>;

    fn as_region(&self) -> Self::Region;
}

pub trait Region: Debug + Clone + PartialEq + Eq + Hash + Send + Sync + 'static {
    type Position: Position<Region = Self>;

    fn is_empty(&self) -> bool;
    fn is_full(&self) -> bool;
    fn contains(&self, pos: &Self::Position) -> bool;
    fn intersects(&self, other: &Self) -> bool;
    fn intersect(&self, other: &Self) -> Self;
    fn union_with(&self, other: &Self) -> Self;
    fn complement(&self) -> Self;
    fn minus(&self, other: &Self) -> Self;
    fn is_simple(&self) -> bool;
    fn count(&self) -> Option<usize>;
}

pub trait Dsp: Debug + Clone + PartialEq + Eq + Hash + Send + Sync + 'static {
    type Position: Position<Region = Self::Region>;
    type Region: Region<Position = Self::Position>;

    fn of(&self, pos: &Self::Position) -> Self::Position;
    fn of_all(&self, region: &Self::Region) -> Self::Region;
    fn inverse(&self) -> Self;
    fn compose(&self, other: &Self) -> Self;
}

pub trait OrderSpec: Debug + Send + Sync + 'static {
    type Position: Position;

    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool;

    fn compare(&self, a: &Self::Position, b: &Self::Position) -> Option<Ordering> {
        match (self.follows(a, b), self.follows(b, a)) {
            (true, true) => Some(Ordering::Equal),
            (true, false) => Some(Ordering::Greater),
            (false, true) => Some(Ordering::Less),
            (false, false) => None,
        }
    }
}
