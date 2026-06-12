use std::collections::HashSet;
use std::sync::{Arc, Mutex};

use super::canopy::CanopyCrumData;
use super::recorder::{AgendaItem, RecorderId};

#[derive(Debug)]
enum HoistPhase {
    Hoisting {
        crum: Arc<Mutex<CanopyCrumData>>,
        cargo: HashSet<RecorderId>,
    },
    Propagating {
        crum: Arc<Mutex<CanopyCrumData>>,
    },
    Done,
}

#[derive(Debug)]
pub struct RecorderHoister {
    phase: HoistPhase,
}

impl RecorderHoister {
    pub fn new(crum: Arc<Mutex<CanopyCrumData>>, cargo: HashSet<RecorderId>) -> Self {
        if cargo.is_empty() {
            RecorderHoister {
                phase: HoistPhase::Propagating { crum },
            }
        } else {
            RecorderHoister {
                phase: HoistPhase::Hoisting { crum, cargo },
            }
        }
    }

    pub fn make(
        crum: Arc<Mutex<CanopyCrumData>>,
        recorders: Vec<RecorderId>,
    ) -> Box<dyn AgendaItem> {
        let cargo: HashSet<RecorderId> = recorders.into_iter().collect();
        Box::new(RecorderHoister::new(crum, cargo))
    }

    pub fn cargo_len(&self) -> usize {
        match &self.phase {
            HoistPhase::Hoisting { cargo, .. } => cargo.len(),
            _ => 0,
        }
    }

    pub fn is_propagating(&self) -> bool {
        matches!(self.phase, HoistPhase::Propagating { .. })
    }

    pub fn is_hoisting(&self) -> bool {
        matches!(self.phase, HoistPhase::Hoisting { .. })
    }
}

impl AgendaItem for RecorderHoister {
    fn step(&mut self) -> bool {
        match &mut self.phase {
            HoistPhase::Done => false,

            HoistPhase::Propagating { crum } => {
                let changed = crum.lock().unwrap().change_canopy();
                let parent = crum.lock().unwrap().parent().cloned();
                match (parent, changed) {
                    (Some(p), true) => {
                        *crum = p;
                        true
                    }
                    _ => {
                        self.phase = HoistPhase::Done;
                        false
                    }
                }
            }

            HoistPhase::Hoisting { crum, cargo } => {
                if cargo.is_empty() {
                    self.phase = HoistPhase::Done;
                    return false;
                }

                let props_changed = crum.lock().unwrap().change_canopy();

                let parent = crum.lock().unwrap().parent().cloned();
                let Some(parent_crum) = parent else {
                    self.phase = HoistPhase::Done;
                    return false;
                };

                let (child1, child2) = {
                    let guard = parent_crum.lock().unwrap();
                    (guard.child1().cloned(), guard.child2().cloned())
                };

                if let Some(ref c1) = child1 {
                    let c1_set: HashSet<RecorderId> =
                        c1.lock().unwrap().recorders().iter().copied().collect();
                    cargo.retain(|r| c1_set.contains(r));
                }
                if let Some(ref c2) = child2 {
                    let c2_set: HashSet<RecorderId> =
                        c2.lock().unwrap().recorders().iter().copied().collect();
                    cargo.retain(|r| c2_set.contains(r));
                }

                if cargo.is_empty() {
                    if !props_changed {
                        self.phase = HoistPhase::Done;
                        return false;
                    }
                    self.phase = HoistPhase::Propagating { crum: parent_crum };
                    return true;
                }

                let cargo_vec: Vec<RecorderId> = cargo.iter().copied().collect();
                if let Some(ref c1) = child1 {
                    c1.lock().unwrap().remove_recorders(&cargo_vec);
                    c1.lock().unwrap().change_canopy();
                }
                if let Some(ref c2) = child2 {
                    c2.lock().unwrap().remove_recorders(&cargo_vec);
                    c2.lock().unwrap().change_canopy();
                }

                {
                    let parent_guard = parent_crum.lock().unwrap();
                    let existing: HashSet<RecorderId> =
                        parent_guard.recorders().iter().copied().collect();
                    cargo.retain(|r| !existing.contains(r));
                }

                let cargo_empty_after_wipe = cargo.is_empty();
                if !cargo_empty_after_wipe {
                    let install_vec: Vec<RecorderId> = cargo.iter().copied().collect();
                    parent_crum.lock().unwrap().install_recorders(&install_vec);
                }

                *crum = parent_crum.clone();

                if cargo_empty_after_wipe {
                    if props_changed {
                        self.phase = HoistPhase::Propagating { crum: parent_crum };
                        return true;
                    }
                    self.phase = HoistPhase::Done;
                    return false;
                }

                true
            }
        }
    }

    fn is_complete(&self) -> bool {
        matches!(self.phase, HoistPhase::Done)
    }

    fn as_any(&self) -> &dyn std::any::Any {
        self
    }

    fn as_any_mut(&mut self) -> &mut dyn std::any::Any {
        self
    }
}

pub fn check_recorders<F>(
    crum: &Arc<Mutex<CanopyCrumData>>,
    mut check_fn: F,
) -> Vec<RecorderId>
where
    F: FnMut(RecorderId) -> bool,
{
    let mut matching = Vec::new();
    check_recorders_recursive(crum, &mut check_fn, &mut matching);
    matching
}

fn check_recorders_recursive<F>(
    crum: &Arc<Mutex<CanopyCrumData>>,
    check_fn: &mut F,
    matching: &mut Vec<RecorderId>,
) where
    F: FnMut(RecorderId) -> bool,
{
    let (recorders, child1, child2) = {
        let guard = crum.lock().unwrap();
        (
            guard.recorders().to_vec(),
            guard.child1().cloned(),
            guard.child2().cloned(),
        )
    };

    for id in recorders {
        if check_fn(id) {
            matching.push(id);
        }
    }

    if let Some(ref c1) = child1 {
        check_recorders_recursive(c1, check_fn, matching);
    }
    if let Some(ref c2) = child2 {
        check_recorders_recursive(c2, check_fn, matching);
    }
}

pub fn collect_all_recorders(crum: &Arc<Mutex<CanopyCrumData>>) -> Vec<RecorderId> {
    check_recorders(crum, |_| true)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::canopy::SensorCanopy;
    use crate::edition::props::IS_SENSOR_WAITING_FLAG;

    fn build_tree(canopy: &SensorCanopy) -> (Arc<Mutex<CanopyCrumData>>, Vec<Arc<Mutex<CanopyCrumData>>>) {
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        let c = canopy.make_crum(0);
        let d = canopy.make_crum(0);

        let ab = canopy.join(&a, &b);
        let cd = canopy.join(&c, &d);
        let _root = canopy.join(&ab, &cd);

        (a.clone(), vec![a, b, c, d])
    }

    fn crum_recorders(crum: &Arc<Mutex<CanopyCrumData>>) -> Vec<RecorderId> {
        crum.lock().unwrap().recorders().to_vec()
    }

    fn run_to_completion(hoister: &mut RecorderHoister) -> usize {
        let mut steps = 0;
        while hoister.step() {
            steps += 1;
            assert!(steps < 50, "hoister should not loop forever");
        }
        assert!(hoister.is_complete());
        steps
    }

    #[test]
    fn hoister_single_recorder_propagates_flags() {
        let canopy = SensorCanopy::new();
        let (leaf, _) = build_tree(&canopy);

        leaf.lock().unwrap().install_recorders(&[42]);
        assert!(leaf.lock().unwrap().own_flags() & IS_SENSOR_WAITING_FLAG != 0);

        let mut hoister = RecorderHoister::new(leaf.clone(), HashSet::from([42]));
        assert!(hoister.is_hoisting());
        run_to_completion(&mut hoister);
    }

    #[test]
    fn hoister_empty_cargo_transitions_to_propagating() {
        let canopy = SensorCanopy::new();
        let (leaf, _) = build_tree(&canopy);

        leaf.lock().unwrap().install_recorders(&[1]);

        let mut hoister = RecorderHoister::new(leaf.clone(), HashSet::new());
        assert!(hoister.is_propagating());
        run_to_completion(&mut hoister);
    }

    #[test]
    fn check_recorders_filters() {
        let canopy = SensorCanopy::new();
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        a.lock().unwrap().install_recorders(&[10, 20]);
        b.lock().unwrap().install_recorders(&[20, 30]);
        let root = canopy.join(&a, &b);

        let evens = check_recorders(&root, |id| id % 2 == 0);
        assert_eq!(evens, vec![10, 20, 20, 30]);
    }

    #[test]
    fn hoister_stops_at_root() {
        let canopy = SensorCanopy::new();
        let (leaf, _) = build_tree(&canopy);

        leaf.lock().unwrap().install_recorders(&[1]);

        let mut hoister = RecorderHoister::new(leaf.clone(), HashSet::from([1]));
        run_to_completion(&mut hoister);
    }

    #[test]
    fn hoister_removes_from_children_and_installs_at_parent() {
        let canopy = SensorCanopy::new();
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        a.lock().unwrap().install_recorders(&[10]);
        b.lock().unwrap().install_recorders(&[10]);
        let parent = canopy.join(&a, &b);

        let mut hoister = RecorderHoister::new(a.clone(), HashSet::from([10]));
        run_to_completion(&mut hoister);

        assert!(crum_recorders(&a).is_empty());
        assert!(crum_recorders(&b).is_empty());
        let root = crate::edition::canopy::find_root(&a);
        assert!(crum_recorders(&root).contains(&10));
    }

    #[test]
    fn hoister_transitions_to_propagating_on_empty_cargo() {
        let canopy = SensorCanopy::new();
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        a.lock().unwrap().install_recorders(&[5]);
        let _parent = canopy.join(&a, &b);

        let mut hoister = RecorderHoister::new(a.clone(), HashSet::from([5]));
        run_to_completion(&mut hoister);
    }

    #[test]
    fn hoister_handles_already_present_at_parent() {
        let canopy = SensorCanopy::new();
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        a.lock().unwrap().install_recorders(&[77]);
        b.lock().unwrap().install_recorders(&[77]);
        let parent = canopy.join(&a, &b);
        parent.lock().unwrap().install_recorders(&[77]);

        let mut hoister = RecorderHoister::new(a.clone(), HashSet::from([77]));
        run_to_completion(&mut hoister);

        assert!(crum_recorders(&a).is_empty());
        assert!(crum_recorders(&b).is_empty());
        assert!(crum_recorders(&parent).contains(&77));
    }

    #[test]
    fn check_recorders_finds_all_in_subtree() {
        let canopy = SensorCanopy::new();
        let (leaf_a, leaves) = build_tree(&canopy);
        let leaf_b = leaves[1].clone();
        let leaf_c = leaves[2].clone();

        leaf_a.lock().unwrap().install_recorders(&[1, 2]);
        leaf_b.lock().unwrap().install_recorders(&[3]);
        leaf_c.lock().unwrap().install_recorders(&[2, 4]);

        let root = crate::edition::canopy::find_root(&leaf_a);
        let found = check_recorders(&root, |_| true);
        assert_eq!(found.len(), 5);
    }

    #[test]
    fn check_recorders_empty_crum() {
        let canopy = SensorCanopy::new();
        let crum = canopy.make_crum(0);
        let found = check_recorders(&crum, |_| true);
        assert!(found.is_empty());
    }

    #[test]
    fn collect_all_recorders_works() {
        let canopy = SensorCanopy::new();
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        a.lock().unwrap().install_recorders(&[1]);
        b.lock().unwrap().install_recorders(&[2, 3]);
        let parent = canopy.join(&a, &b);
        parent.lock().unwrap().install_recorders(&[4]);

        let all = collect_all_recorders(&parent);
        assert_eq!(all.len(), 4);
    }

    #[test]
    fn hoister_make_returns_boxed_item() {
        let canopy = SensorCanopy::new();
        let crum = canopy.make_crum(0);
        crum.lock().unwrap().install_recorders(&[1]);

        let mut item = RecorderHoister::make(crum.clone(), vec![1]);
        assert!(!item.is_complete());
        while item.step() {}
        assert!(item.is_complete());
    }

    #[test]
    fn hoister_multi_level_tree() {
        let canopy = SensorCanopy::new();
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        let c = canopy.make_crum(0);
        let d = canopy.make_crum(0);
        a.lock().unwrap().install_recorders(&[42]);
        b.lock().unwrap().install_recorders(&[42]);
        let ab = canopy.join(&a, &b);
        let cd = canopy.join(&c, &d);
        let _root = canopy.join(&ab, &cd);

        let mut hoister = RecorderHoister::new(a.clone(), HashSet::from([42]));
        run_to_completion(&mut hoister);

        assert!(crum_recorders(&a).is_empty());
        assert!(crum_recorders(&b).is_empty());
        assert!(crum_recorders(&ab).contains(&42));
    }

    #[test]
    fn hoister_multi_level_tree_hoists_to_root() {
        let canopy = SensorCanopy::new();
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        let c = canopy.make_crum(0);
        let d = canopy.make_crum(0);
        a.lock().unwrap().install_recorders(&[42]);
        b.lock().unwrap().install_recorders(&[42]);
        c.lock().unwrap().install_recorders(&[42]);
        d.lock().unwrap().install_recorders(&[42]);
        let ab = canopy.join(&a, &b);
        let cd = canopy.join(&c, &d);
        let root = canopy.join(&ab, &cd);

        let mut h1 = RecorderHoister::new(a.clone(), HashSet::from([42]));
        run_to_completion(&mut h1);

        assert!(crum_recorders(&ab).contains(&42));
        assert!(crum_recorders(&a).is_empty());
        assert!(crum_recorders(&b).is_empty());

        let mut h2 = RecorderHoister::new(c.clone(), HashSet::from([42]));
        run_to_completion(&mut h2);

        assert!(crum_recorders(&root).contains(&42));
        assert!(crum_recorders(&ab).is_empty());
        assert!(crum_recorders(&cd).is_empty());
        assert!(crum_recorders(&c).is_empty());
        assert!(crum_recorders(&d).is_empty());
    }

    #[test]
    fn hoister_updates_canopy_flags() {
        let canopy = SensorCanopy::new();
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        a.lock().unwrap().install_recorders(&[1]);
        b.lock().unwrap().install_recorders(&[1]);
        let parent = canopy.join(&a, &b);
        let root_parent = {
            let c = canopy.make_crum(0);
            let d = canopy.make_crum(0);
            let cd = canopy.join(&c, &d);
            canopy.join(&parent, &cd)
        };

        let mut hoister = RecorderHoister::new(a.clone(), HashSet::from([1]));
        run_to_completion(&mut hoister);

        let final_root_flags = root_parent.lock().unwrap().flags();
        assert!(
            final_root_flags & IS_SENSOR_WAITING_FLAG != 0,
            "root should show SENSOR_WAITING after hoisting"
        );
    }

    #[test]
    fn hoister_multiple_recorders_in_cargo() {
        let canopy = SensorCanopy::new();
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        a.lock().unwrap().install_recorders(&[10, 20, 30]);
        b.lock().unwrap().install_recorders(&[10, 20, 30]);
        let parent = canopy.join(&a, &b);

        let mut hoister = RecorderHoister::new(a.clone(), HashSet::from([10, 20, 30]));
        run_to_completion(&mut hoister);

        assert!(crum_recorders(&a).is_empty());
        assert!(crum_recorders(&b).is_empty());
        let root = crate::edition::canopy::find_root(&a);
        let root_recs = crum_recorders(&root);
        assert!(root_recs.contains(&10));
        assert!(root_recs.contains(&20));
        assert!(root_recs.contains(&30));
    }

    #[test]
    fn hoister_partial_cargo_match() {
        let canopy = SensorCanopy::new();
        let a = canopy.make_crum(0);
        let b = canopy.make_crum(0);
        a.lock().unwrap().install_recorders(&[1, 2, 3]);
        b.lock().unwrap().install_recorders(&[1, 3]);
        let _parent = canopy.join(&a, &b);

        let mut hoister = RecorderHoister::new(a.clone(), HashSet::from([1, 2, 3]));
        run_to_completion(&mut hoister);

        let root = crate::edition::canopy::find_root(&a);
        let root_recs = crum_recorders(&root);
        assert!(root_recs.contains(&1));
        assert!(root_recs.contains(&3));
        assert!(!root_recs.contains(&2));
    }

    #[test]
    fn recording_agent_installs_and_creates_hoister() {
        let canopy = SensorCanopy::new();
        let crum = canopy.make_crum(0);

        let agent = canopy.recording_agent(&crum, 99);
        assert!(agent.is_some());
        assert!(crum.lock().unwrap().recorders().contains(&99));

        let mut item = agent.unwrap();
        while item.step() {}
        assert!(item.is_complete());
    }

    #[test]
    fn recording_agent_skips_duplicate() {
        let canopy = SensorCanopy::new();
        let crum = canopy.make_crum(0);
        crum.lock().unwrap().install_recorders(&[50]);

        let agent = canopy.recording_agent(&crum, 50);
        assert!(agent.is_none());
    }
}
