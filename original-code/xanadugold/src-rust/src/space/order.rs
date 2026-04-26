use super::traits::*;
use std::cmp::Ordering;

pub struct ReverseOrder<P: Position> {
    inner: Box<dyn OrderSpec<Position = P>>,
}

impl<P: Position> ReverseOrder<P> {
    pub fn new(inner: Box<dyn OrderSpec<Position = P>>) -> Self {
        ReverseOrder { inner }
    }
}

impl<P: Position> OrderSpec for ReverseOrder<P> {
    type Position = P;

    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool {
        self.inner.follows(b, a)
    }

    fn compare(&self, a: &Self::Position, b: &Self::Position) -> Option<Ordering> {
        self.inner.compare(b, a).map(|o| o.reverse())
    }
}

impl<P: Position> std::fmt::Debug for ReverseOrder<P> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ReverseOrder").finish()
    }
}

impl<P: Position> PartialEq for ReverseOrder<P> {
    fn eq(&self, _other: &Self) -> bool {
        true
    }
}

impl<P: Position> Eq for ReverseOrder<P> {}

impl<P: Position> std::hash::Hash for ReverseOrder<P> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        "ReverseOrder".hash(state);
    }
}

pub struct ChainedOrder<P: Position> {
    pub primary: Box<dyn OrderSpec<Position = P>>,
    pub secondary: Box<dyn OrderSpec<Position = P>>,
}

impl<P: Position> ChainedOrder<P> {
    pub fn new(
        primary: Box<dyn OrderSpec<Position = P>>,
        secondary: Box<dyn OrderSpec<Position = P>>,
    ) -> Self {
        ChainedOrder { primary, secondary }
    }
}

impl<P: Position> OrderSpec for ChainedOrder<P> {
    type Position = P;

    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool {
        match self.primary.compare(a, b) {
            Some(Ordering::Greater) | Some(Ordering::Equal) => true,
            Some(Ordering::Less) => false,
            None => self.secondary.follows(a, b),
        }
    }
}

impl<P: Position> std::fmt::Debug for ChainedOrder<P> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ChainedOrder").finish()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::space::integer::*;

    #[test]
    fn reverse_order_follows() {
        let inner = IntegerAscending;
        let rev: ReverseOrder<IntegerPos> = ReverseOrder::new(Box::new(inner));
        assert!(rev.follows(&IntegerPos(3), &IntegerPos(5)));
        assert!(!rev.follows(&IntegerPos(5), &IntegerPos(3)));
        assert!(rev.follows(&IntegerPos(5), &IntegerPos(5)));
    }

    #[test]
    fn reverse_order_compare() {
        let inner = IntegerAscending;
        let rev: ReverseOrder<IntegerPos> = ReverseOrder::new(Box::new(inner));
        assert_eq!(rev.compare(&IntegerPos(3), &IntegerPos(5)), Some(Ordering::Less));
        assert_eq!(rev.compare(&IntegerPos(5), &IntegerPos(3)), Some(Ordering::Greater));
        assert_eq!(rev.compare(&IntegerPos(5), &IntegerPos(5)), Some(Ordering::Equal));
    }

    #[test]
    fn reverse_of_ascending_is_descending() {
        let asc = IntegerAscending;
        let rev: ReverseOrder<IntegerPos> = ReverseOrder::new(Box::new(asc));
        let desc = IntegerDescending;
        let a = IntegerPos(3);
        let b = IntegerPos(5);
        assert_eq!(rev.follows(&a, &b), desc.follows(&a, &b));
        assert_eq!(rev.follows(&b, &a), desc.follows(&b, &a));
        assert_eq!(rev.follows(&a, &a), desc.follows(&a, &a));
    }

    #[test]
    fn double_reverse_is_original() {
        let asc = IntegerAscending;
        let rev1: ReverseOrder<IntegerPos> = ReverseOrder::new(Box::new(asc));
        let _rev2: ReverseOrder<IntegerPos> = ReverseOrder::new(Box::new(rev1));
        let a = IntegerPos(3);
        let b = IntegerPos(5);
        assert!(_rev2.follows(&b, &a));
        assert!(!_rev2.follows(&a, &b));
    }
}
