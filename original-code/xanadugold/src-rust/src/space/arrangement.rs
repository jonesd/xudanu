use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct Arrangement<P> {
    positions: Vec<P>,
    index: HashMap<usize, usize>,
}

impl<P: PartialEq + Clone> Arrangement<P> {
    pub fn new(order: impl Fn(&P, &P) -> std::cmp::Ordering, positions: Vec<P>) -> Self {
        let mut sorted = positions;
        sorted.sort_by(order);
        let index: HashMap<usize, usize> = sorted
            .iter()
            .enumerate()
            .map(|(i, _)| (i, i))
            .collect();
        Arrangement {
            positions: sorted,
            index,
        }
    }

    pub fn from_sorted(positions: Vec<P>) -> Self {
        let index: HashMap<usize, usize> = (0..positions.len()).map(|i| (i, i)).collect();
        Arrangement { positions, index }
    }

    pub fn len(&self) -> usize {
        self.positions.len()
    }

    pub fn is_empty(&self) -> bool {
        self.positions.is_empty()
    }

    pub fn position_at(&self, index: usize) -> Option<&P> {
        self.positions.get(index)
    }

    pub fn index_of(&self, pos: &P) -> Option<usize> {
        self.positions.iter().position(|p| p == pos)
    }

    pub fn positions(&self) -> &[P] {
        &self.positions
    }

    pub fn slice(&self, start: usize, end: usize) -> &[P] {
        if start >= self.positions.len() {
            return &[];
        }
        let end = end.min(self.positions.len());
        &self.positions[start..end]
    }

    pub fn copy_elements<T: Clone>(
        &self,
        source: &[T],
        target: &mut Vec<T>,
        start: usize,
        count: usize,
    ) {
        let end = (start + count).min(source.len());
        for i in start..end {
            target.push(source[i].clone());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn arrangement_index_of() {
        let arr = Arrangement::from_sorted(vec![10i64, 20, 30, 40, 50]);
        assert_eq!(arr.index_of(&20), Some(1));
        assert_eq!(arr.index_of(&99), None);
    }

    #[test]
    fn arrangement_position_at() {
        let arr = Arrangement::from_sorted(vec![10i64, 20, 30]);
        assert_eq!(arr.position_at(0), Some(&10));
        assert_eq!(arr.position_at(2), Some(&30));
        assert_eq!(arr.position_at(3), None);
    }

    #[test]
    fn arrangement_slice() {
        let arr = Arrangement::from_sorted(vec![10i64, 20, 30, 40, 50]);
        let slice = arr.slice(1, 4);
        assert_eq!(slice, &[20, 30, 40]);
    }

    #[test]
    fn arrangement_sorted_order() {
        let arr = Arrangement::new(
            |a: &i64, b: &i64| a.cmp(b),
            vec![50i64, 30, 10, 40, 20],
        );
        assert_eq!(arr.position_at(0), Some(&10));
        assert_eq!(arr.position_at(4), Some(&50));
    }

    #[test]
    fn arrangement_copy_elements() {
        let arr = Arrangement::from_sorted(vec![10i64, 20, 30]);
        let source = vec!["a", "b", "c"];
        let mut target = Vec::new();
        arr.copy_elements(&source, &mut target, 1, 2);
        assert_eq!(target, vec!["b", "c"]);
    }

    #[test]
    fn arrangement_empty() {
        let arr: Arrangement<i64> = Arrangement::from_sorted(vec![]);
        assert!(arr.is_empty());
        assert_eq!(arr.len(), 0);
    }
}
