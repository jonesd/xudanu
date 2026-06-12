#[cfg(test)]
mod tests {
    use crate::space::cross::*;
    use crate::space::cross_n::*;
    use crate::space::integer::*;
    use crate::space::sequence::*;
    use crate::space::traits::*;
    use crate::space::arrangement::Arrangement;

    // =========================================================
    // Part 1: Tumbler Addressing
    // =========================================================

    // 1A. Deep decomposition
    // Gold address: server . work . edition . position . element

    #[test]
    fn tumbler_5_level_decomposition() {
        let addr = Sequence::from_numbers(vec![1, 0, 5, 0, 3, 0, 2, 0, 7]);
        let server = addr.first();
        assert_eq!(server, Sequence::one(1));

        let rest1 = addr.rest();
        let work = rest1.first();
        assert_eq!(work.at(2), 5);

        let rest2 = rest1.rest();
        let edition = rest2.first();
        assert_eq!(edition.at(4), 3);

        let rest3 = rest2.rest();
        let position = rest3.first();
        assert_eq!(position.at(6), 2);

        let rest4 = rest3.rest();
        let element = rest4.first();
        assert_eq!(element.at(8), 7);

        let final_rest = rest4.rest();
        assert!(final_rest.is_zero());
    }

    #[test]
    fn tumbler_5_level_recompose() {
        let server = Sequence::one(1);
        let work = Sequence::one(5);
        let edition = Sequence::one(3);
        let position = Sequence::one(2);
        let element = Sequence::one(7);

        let addr = server
            .with_rest(&work)
            .with_rest(&edition)
            .with_rest(&position)
            .with_rest(&element);

        assert_eq!(
            addr,
            Sequence::from_numbers(vec![1, 0, 5, 0, 3, 0, 2, 0, 7])
        );
    }

    #[test]
    fn tumbler_decompose_recompose_roundtrip_3_level() {
        let original = Sequence::from_numbers(vec![3, 0, 7, 0, 2]);
        let a = original.first();
        let rest_a = original.rest();
        let b = rest_a.first();
        let rest_b = rest_a.rest();
        let c = rest_b.first();

        assert_eq!(a, Sequence::one(3));
        assert_eq!(b.at(2), 7);
        assert_eq!(c.at(4), 2);

        let rebuilt = a.with_rest(&b).with_rest(&c);
        assert_eq!(rebuilt, original);
    }

    #[test]
    fn tumbler_from_dotted_5_levels() {
        let addr = Sequence::from_dotted("1.5.3.2.7");
        assert_eq!(addr.at(0), 1);
        assert_eq!(addr.at(1), 0);
        assert_eq!(addr.at(2), 5);
        assert_eq!(addr.at(3), 0);
        assert_eq!(addr.at(4), 3);
        assert_eq!(addr.at(5), 0);
        assert_eq!(addr.at(6), 2);
        assert_eq!(addr.at(7), 0);
        assert_eq!(addr.at(8), 7);
    }

    #[test]
    fn tumbler_display_roundtrip() {
        let addr = Sequence::from_dotted("3.7.2");
        let displayed = format!("{}", addr);
        assert_eq!(displayed, "3.0.7.0.2");
    }

    #[test]
    fn tumbler_single_component() {
        let addr = Sequence::from_dotted("42");
        assert_eq!(addr, Sequence::one(42));
        assert_eq!(addr.first(), addr);
        assert!(addr.rest().is_zero());
    }

    #[test]
    fn tumbler_zero_address() {
        let zero = Sequence::zero();
        assert!(zero.first().is_zero());
        assert!(zero.rest().is_zero());
        let with_rest = zero.with_rest(&Sequence::zero());
        assert_eq!(with_rest.numbers(), &[0]);
    }

    // 1B. Prefix queries for hierarchical lookup

    #[test]
    fn prefix_query_finds_all_under_server() {
        let space = SequenceSpace::new();
        let server_prefix = Sequence::one(1);
        let region = space.prefixed_by(&server_prefix, 0);

        assert!(region.contains_sequence(&Sequence::from_dotted("1.5")));
        assert!(region.contains_sequence(&Sequence::from_dotted("1.5.3")));
        assert!(region.contains_sequence(&Sequence::from_dotted("1.99.42")));
        assert!(!region.contains_sequence(&Sequence::from_dotted("2.5")));
    }

    #[test]
    fn prefix_query_server_work_level() {
        let space = SequenceSpace::new();
        let prefix = Sequence::from_numbers(vec![1, 0, 5]);
        let region = space.prefixed_by(&prefix, 2);

        assert!(region.contains_sequence(&Sequence::from_dotted("1.5.3")));
        assert!(region.contains_sequence(&Sequence::from_dotted("1.5.7")));
        assert!(!region.contains_sequence(&Sequence::from_dotted("1.3.7")));
    }

    #[test]
    fn prefix_query_narrow_to_edition() {
        let space = SequenceSpace::new();
        let prefix = Sequence::from_numbers(vec![1, 0, 5, 0, 3]);
        let region = space.prefixed_by(&prefix, 4);

        assert!(region.contains_sequence(&Sequence::from_dotted("1.5.3.2")));
        assert!(region.contains_sequence(&Sequence::from_dotted("1.5.3.99")));
        assert!(!region.contains_sequence(&Sequence::from_dotted("1.5.7.2")));
    }

    #[test]
    fn prefix_intersect_with_range() {
        let space = SequenceSpace::new();
        let prefix = space.prefixed_by(&Sequence::one(1), 0);
        let range = SequenceRegion::interval(
            Sequence::from_dotted("1.5"),
            Sequence::from_dotted("1.10"),
        );
        let intersection = prefix.intersect(&range);

        assert!(intersection.contains_sequence(&Sequence::from_dotted("1.7")));
        assert!(!intersection.contains_sequence(&Sequence::from_dotted("1.11")));
        assert!(!intersection.contains_sequence(&Sequence::from_dotted("2.5")));
    }

    // 1C. Navigation: ascending/descending across tumbler addresses

    #[test]
    fn tumbler_lexicographic_order() {
        let a = Sequence::from_dotted("1.2");
        let b = Sequence::from_dotted("1.3");
        let c = Sequence::from_dotted("2.0");
        assert_eq!(a.compare_to(&b), std::cmp::Ordering::Less);
        assert_eq!(b.compare_to(&c), std::cmp::Ordering::Less);
        assert_eq!(a.compare_to(&c), std::cmp::Ordering::Less);
    }

    #[test]
    fn tumbler_order_different_depth() {
        let shallow = Sequence::from_dotted("1");
        let deep = Sequence::from_dotted("1.1");
        assert_eq!(shallow.compare_to(&deep), std::cmp::Ordering::Less);
    }

    #[test]
    fn tumbler_order_same_prefix_different_rest() {
        let a = Sequence::from_dotted("1.2.3");
        let b = Sequence::from_dotted("1.2.5");
        assert_eq!(a.compare_to(&b), std::cmp::Ordering::Less);
    }

    #[test]
    fn tumbler_arrangement_sorted() {
        let positions = vec![
            SequencePos(Sequence::from_dotted("3.1")),
            SequencePos(Sequence::from_dotted("1.5")),
            SequencePos(Sequence::from_dotted("1.2")),
            SequencePos(Sequence::from_dotted("2.7")),
        ];
        let arr = Arrangement::new(
            |a, b| a.0.compare_to(&b.0),
            positions,
        );
        assert_eq!(arr.position_at(0).unwrap().0, Sequence::from_dotted("1.2"));
        assert_eq!(arr.position_at(1).unwrap().0, Sequence::from_dotted("1.5"));
        assert_eq!(arr.position_at(2).unwrap().0, Sequence::from_dotted("2.7"));
        assert_eq!(arr.position_at(3).unwrap().0, Sequence::from_dotted("3.1"));
    }

    // 1D. Region set algebra on tumbler addresses

    #[test]
    fn tumbler_interval_excludes_endpoints() {
        let r = SequenceRegion::interval(
            Sequence::from_dotted("1.2"),
            Sequence::from_dotted("1.5"),
        );
        assert!(r.contains_sequence(&Sequence::from_dotted("1.3")));
        assert!(!r.contains_sequence(&Sequence::from_dotted("1.5")));
        assert!(!r.contains_sequence(&Sequence::from_dotted("1.1")));
    }

    #[test]
    fn tumbler_region_complement() {
        let r = SequenceRegion::interval(
            Sequence::from_dotted("2"),
            Sequence::from_dotted("5"),
        );
        let c = r.complement();
        assert!(c.contains_sequence(&Sequence::from_dotted("1")));
        assert!(c.contains_sequence(&Sequence::from_dotted("5")));
        assert!(!c.contains_sequence(&Sequence::from_dotted("3")));
    }

    #[test]
    fn tumbler_region_union_disjoint() {
        let a = SequenceRegion::interval(
            Sequence::from_dotted("1.2"),
            Sequence::from_dotted("1.4"),
        );
        let b = SequenceRegion::interval(
            Sequence::from_dotted("1.7"),
            Sequence::from_dotted("1.9"),
        );
        let u = a.union_with(&b);
        assert!(u.contains_sequence(&Sequence::from_dotted("1.3")));
        assert!(u.contains_sequence(&Sequence::from_dotted("1.8")));
        assert!(!u.contains_sequence(&Sequence::from_dotted("1.5")));
    }

    #[test]
    fn tumbler_region_minus() {
        let full = SequenceRegion::above(Sequence::one(1), true);
        let excluded = SequenceRegion::interval(
            Sequence::from_dotted("1.5"),
            Sequence::from_dotted("1.10"),
        );
        let result = full.minus(&excluded);
        assert!(result.contains_sequence(&Sequence::from_dotted("1.3")));
        assert!(!result.contains_sequence(&Sequence::from_dotted("1.7")));
        assert!(result.contains_sequence(&Sequence::from_dotted("1.11")));
    }

    #[test]
    fn tumbler_above_inclusive_exclusive() {
        let inc = SequenceRegion::above(Sequence::from_dotted("1.5"), true);
        let exc = SequenceRegion::above(Sequence::from_dotted("1.5"), false);
        assert!(inc.contains_sequence(&Sequence::from_dotted("1.5")));
        assert!(!exc.contains_sequence(&Sequence::from_dotted("1.5")));
        assert!(exc.contains_sequence(&Sequence::from_dotted("1.6")));
    }

    #[test]
    fn tumbler_below_inclusive_exclusive() {
        let inc = SequenceRegion::below(Sequence::from_dotted("3"), true);
        let exc = SequenceRegion::below(Sequence::from_dotted("3"), false);
        assert!(inc.contains_sequence(&Sequence::from_dotted("3")));
        assert!(!exc.contains_sequence(&Sequence::from_dotted("3")));
        assert!(exc.contains_sequence(&Sequence::from_dotted("2")));
    }

    // 1E. DSP (displacement) on tumbler addresses

    #[test]
    fn tumbler_dsp_shift_navigates_between_works() {
        let base = SequencePos(Sequence::from_dotted("1.3.5"));
        let dsp = SequenceDsp::new(2, Sequence::zero());
        let shifted = dsp.of(&base);
        assert_eq!(shifted.0.at(0), 0);
        assert_eq!(shifted.0.at(1), 0);
        assert_eq!(shifted.0.at(2), 1);
        assert_eq!(shifted.0.at(3), 0);
        assert_eq!(shifted.0.at(4), 3);
        assert_eq!(shifted.0.at(5), 0);
        assert_eq!(shifted.0.at(6), 5);
    }

    #[test]
    fn tumbler_dsp_translate_adds_offset() {
        let base = SequencePos(Sequence::from_dotted("1.3"));
        let offset = Sequence::two(10, 0);
        let dsp = SequenceDsp::new(0, offset);
        let shifted = dsp.of(&base);
        assert_eq!(shifted.0.at(0), 11);
        assert_eq!(shifted.0.at(1), 0);
        assert_eq!(shifted.0.at(2), 3);
    }

    #[test]
    fn tumbler_dsp_inverse_roundtrip() {
        let dsp = SequenceDsp::new(2, Sequence::from_numbers(vec![10, 0, 5]));
        let inv = dsp.inverse();
        let pos = SequencePos(Sequence::from_dotted("3.7.2"));
        let roundtrip = inv.of(&dsp.of(&pos));
        assert_eq!(roundtrip.0, pos.0);
    }

    // 1F. Sequence arithmetic

    #[test]
    fn sequence_plus_overlapping() {
        let a = Sequence::from_numbers(vec![1, 0, 3]);
        let b = Sequence::from_numbers(vec![1, 0, 5]);
        let sum = a.plus(&b);
        assert_eq!(sum.at(0), 2);
        assert_eq!(sum.at(1), 0);
        assert_eq!(sum.at(2), 8);
    }

    #[test]
    fn sequence_minus_same_is_zero() {
        let a = Sequence::from_dotted("1.3.5");
        let diff = a.minus(&a);
        assert!(diff.is_zero());
    }

    #[test]
    fn sequence_plus_commutative() {
        let a = Sequence::from_dotted("1.3");
        let b = Sequence::from_dotted("2.5");
        assert_eq!(a.plus(&b), b.plus(&a));
    }

    // =========================================================
    // Part 2: Multi-Dimensional Endorsement Regions
    // =========================================================

    // 2A. CrossSpace2 with ID × Token (typed 2D)

    #[test]
    fn endorsement_2d_space_creates_positions() {
        let space = CrossSpace2::new(IntegerSpace::new(), IntegerSpace::new());
        let pos = space.position(IntegerPos(1), IntegerPos(10));
        assert_eq!(pos.0, IntegerPos(1));
        assert_eq!(pos.1, IntegerPos(10));
    }

    #[test]
    fn endorsement_2d_box_contains() {
        let space = CrossSpace2::new(IntegerSpace::new(), IntegerSpace::new());
        let region = space.box_region(
            IntegerRegion::interval(1, 10),
            IntegerRegion::interval(100, 200),
        );
        assert!(region.contains(&Tuple2(IntegerPos(5), IntegerPos(150))));
        assert!(!region.contains(&Tuple2(IntegerPos(0), IntegerPos(150))));
        assert!(!region.contains(&Tuple2(IntegerPos(5), IntegerPos(99))));
    }

    #[test]
    fn endorsement_2d_project_club_axis() {
        let space = CrossSpace2::new(IntegerSpace::new(), IntegerSpace::new());
        let region = space.box_region(
            IntegerRegion::interval(1, 5),
            IntegerRegion::interval(10, 20),
        );
        let club_proj = region.projection_a();
        assert!(club_proj.contains(&IntegerPos(3)));
        assert!(!club_proj.contains(&IntegerPos(5)));
        let token_proj = region.projection_b();
        assert!(token_proj.contains(&IntegerPos(15)));
        assert!(!token_proj.contains(&IntegerPos(20)));
    }

    #[test]
    fn endorsement_2d_intersect_overlapping() {
        let space = CrossSpace2::new(IntegerSpace::new(), IntegerSpace::new());
        let a = space.box_region(
            IntegerRegion::interval(1, 5),
            IntegerRegion::interval(10, 20),
        );
        let b = space.box_region(
            IntegerRegion::interval(3, 8),
            IntegerRegion::interval(15, 25),
        );
        let c = a.intersect(&b);
        assert!(c.contains(&Tuple2(IntegerPos(4), IntegerPos(17))));
        assert!(!c.contains(&Tuple2(IntegerPos(2), IntegerPos(17))));
        assert!(!c.contains(&Tuple2(IntegerPos(4), IntegerPos(12))));
    }

    #[test]
    fn endorsement_2d_union_preserves_both() {
        let space = CrossSpace2::new(IntegerSpace::new(), IntegerSpace::new());
        let a = space.box_region(
            IntegerRegion::interval(1, 3),
            IntegerRegion::singleton(10),
        );
        let b = space.box_region(
            IntegerRegion::singleton(5),
            IntegerRegion::interval(20, 30),
        );
        let u = a.union_with(&b);
        assert!(u.contains(&Tuple2(IntegerPos(2), IntegerPos(10))));
        assert!(u.contains(&Tuple2(IntegerPos(5), IntegerPos(25))));
    }

    #[test]
    fn endorsement_2d_complement() {
        let space = CrossSpace2::new(IntegerSpace::new(), IntegerSpace::new());
        let r = space.box_region(
            IntegerRegion::interval(1, 5),
            IntegerRegion::interval(10, 20),
        );
        let c = r.complement();
        assert!(!c.contains(&Tuple2(IntegerPos(3), IntegerPos(15))));
        assert!(c.contains(&Tuple2(IntegerPos(0), IntegerPos(15))));
        assert!(c.contains(&Tuple2(IntegerPos(3), IntegerPos(25))));
    }

    #[test]
    fn endorsement_2d_minus() {
        let space = CrossSpace2::new(IntegerSpace::new(), IntegerSpace::new());
        let a = space.box_region(
            IntegerRegion::interval(1, 10),
            IntegerRegion::interval(1, 100),
        );
        let b = space.box_region(
            IntegerRegion::singleton(5),
            IntegerRegion::interval(20, 30),
        );
        let diff = a.minus(&b);
        assert!(diff.contains(&Tuple2(IntegerPos(4), IntegerPos(25))));
        assert!(!diff.contains(&Tuple2(IntegerPos(5), IntegerPos(25))));
        assert!(diff.contains(&Tuple2(IntegerPos(5), IntegerPos(35))));
    }

    #[test]
    fn endorsement_2d_count_finite() {
        let space = CrossSpace2::new(IntegerSpace::new(), IntegerSpace::new());
        let r = space.box_region(
            IntegerRegion::interval(0, 3),
            IntegerRegion::interval(0, 5),
        );
        assert_eq!(r.count(), Some(15));
    }

    // 2B. CrossSpace2 with Sequence × Integer (tumbler × token)

    #[test]
    fn endorsement_tumbler_token_space() {
        let space = CrossSpace2::new(SequenceSpace::new(), IntegerSpace::new());
        let pos = space.position(
            SequencePos(Sequence::from_dotted("1.5.3")),
            IntegerPos(42),
        );
        let region = space.box_region(
            SequenceRegion::prefixed_by(&Sequence::one(1), 0),
            IntegerRegion::interval(10, 100),
        );
        assert!(region.contains(&pos));
        let outside = space.position(
            SequencePos(Sequence::from_dotted("2.1")),
            IntegerPos(50),
        );
        assert!(!region.contains(&outside));
    }

    #[test]
    fn endorsement_tumbler_token_project_token_axis() {
        let space = CrossSpace2::new(SequenceSpace::new(), IntegerSpace::new());
        let region = space.box_region(
            SequenceRegion::prefixed_by(&Sequence::from_numbers(vec![1, 0, 5]), 2),
            IntegerRegion::interval(100, 200),
        );
        let token_proj = region.projection_b();
        assert!(token_proj.contains(&IntegerPos(150)));
        assert!(!token_proj.contains(&IntegerPos(99)));
    }

    // 2C. CrossSpaceN with 3+ dimensions (ID × Token × Position)

    #[test]
    fn endorsement_3d_space_creation() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        assert_eq!(space.dimension(), 3);
        let pos = space.position(vec![
            DynPosition::integer(1),
            DynPosition::integer(10),
            DynPosition::integer(100),
        ]);
        let coords = pos.as_composite().unwrap();
        assert_eq!(coords[0].as_integer().unwrap(), 1);
        assert_eq!(coords[1].as_integer().unwrap(), 10);
        assert_eq!(coords[2].as_integer().unwrap(), 100);
    }

    #[test]
    fn endorsement_3d_box_contains() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let region = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 5)),
            CrossRegionN::axis_integer(IntegerRegion::interval(10, 20)),
            CrossRegionN::axis_integer(IntegerRegion::interval(100, 200)),
        ]);
        assert!(space.contains(&region, &[
            DynPosition::integer(3),
            DynPosition::integer(15),
            DynPosition::integer(150),
        ]));
        assert!(!space.contains(&region, &[
            DynPosition::integer(0),
            DynPosition::integer(15),
            DynPosition::integer(150),
        ]));
        assert!(!space.contains(&region, &[
            DynPosition::integer(3),
            DynPosition::integer(25),
            DynPosition::integer(150),
        ]));
    }

    #[test]
    fn endorsement_3d_intersect() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let a = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
        ]);
        let b = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(5, 15)),
            CrossRegionN::axis_integer(IntegerRegion::interval(3, 7)),
            CrossRegionN::axis_integer(IntegerRegion::interval(5, 8)),
        ]);
        let c = a.intersect(&b);
        assert!(space.contains(&c, &[
            DynPosition::integer(7),
            DynPosition::integer(5),
            DynPosition::integer(6),
        ]));
        assert!(!space.contains(&c, &[
            DynPosition::integer(2),
            DynPosition::integer(5),
            DynPosition::integer(6),
        ]));
        assert!(!space.contains(&c, &[
            DynPosition::integer(7),
            DynPosition::integer(8),
            DynPosition::integer(6),
        ]));
    }

    #[test]
    fn endorsement_3d_union() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let a = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 5)),
            CrossRegionN::axis_integer(IntegerRegion::singleton(1)),
            CrossRegionN::axis_integer(IntegerRegion::singleton(100)),
        ]);
        let b = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(10, 15)),
            CrossRegionN::axis_integer(IntegerRegion::singleton(2)),
            CrossRegionN::axis_integer(IntegerRegion::singleton(200)),
        ]);
        let u = a.union_with(&b);
        assert!(space.contains(&u, &[
            DynPosition::integer(3),
            DynPosition::integer(1),
            DynPosition::integer(100),
        ]));
        assert!(space.contains(&u, &[
            DynPosition::integer(12),
            DynPosition::integer(2),
            DynPosition::integer(200),
        ]));
    }

    #[test]
    fn endorsement_3d_complement() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let r = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
        ]);
        let c = r.complement();
        assert!(!space.contains(&c, &[
            DynPosition::integer(5),
            DynPosition::integer(5),
            DynPosition::integer(5),
        ]));
    }

    #[test]
    fn endorsement_3d_minus() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let a = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 100)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 100)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 100)),
        ]);
        let b = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::singleton(50)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 100)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 100)),
        ]);
        let diff = a.minus(&b);
        assert!(space.contains(&diff, &[
            DynPosition::integer(25),
            DynPosition::integer(50),
            DynPosition::integer(50),
        ]));
        assert!(!space.contains(&diff, &[
            DynPosition::integer(50),
            DynPosition::integer(50),
            DynPosition::integer(50),
        ]));
    }

    // 2D. Mixed axis types (Integer × Sequence × Real)

    #[test]
    fn mixed_3d_space_integer_sequence_real() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::sequence(),
            CrossSpaceNSlot::real(),
        ]);
        assert_eq!(space.dimension(), 3);

        let full = space.full_region();
        assert!(full.is_full());

        let empty = space.empty_region();
        assert!(empty.is_empty());
    }

    #[test]
    fn mixed_3d_contains() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::sequence(),
            CrossSpaceNSlot::real(),
        ]);
        let region = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 5)),
            CrossRegionN::axis_sequence(SequenceRegion::prefixed_by(&Sequence::one(1), 0)),
            CrossRegionN::axis_real(crate::space::real::RealRegion::interval(0.0, 1.0, true, true)),
        ]);
        assert!(space.contains(&region, &[
            DynPosition::integer(3),
            DynPosition::sequence(Sequence::from_dotted("1.5")),
            DynPosition::real(0.5),
        ]));
        assert!(!space.contains(&region, &[
            DynPosition::integer(0),
            DynPosition::sequence(Sequence::from_dotted("1.5")),
            DynPosition::real(0.5),
        ]));
        assert!(!space.contains(&region, &[
            DynPosition::integer(3),
            DynPosition::sequence(Sequence::from_dotted("2.5")),
            DynPosition::real(0.5),
        ]));
    }

    // 2E. Nested cross products (Cross inside CrossSpaceN)

    #[test]
    fn nested_cross_space_4d_via_nesting() {
        let inner = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let outer = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::Cross(Box::new(inner)),
            CrossSpaceNSlot::integer(),
        ]);
        assert_eq!(outer.dimension(), 3);
    }

    // 2F. CrossRegionN set algebra properties

    #[test]
    fn cross_region_n_double_complement() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let r = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(5, 20)),
        ]);
        let double = r.complement().complement();
        assert!(space.contains(&double, &[DynPosition::integer(5), DynPosition::integer(10)]));
        assert!(!space.contains(&double, &[DynPosition::integer(0), DynPosition::integer(10)]));
    }

    #[test]
    fn cross_region_n_union_complement_is_full() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let r = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(5, 20)),
        ]);
        let u = r.union_with(&r.complement());
        assert!(space.contains(&u, &[DynPosition::integer(0), DynPosition::integer(0)]));
        assert!(space.contains(&u, &[DynPosition::integer(5), DynPosition::integer(10)]));
        assert!(space.contains(&u, &[DynPosition::integer(100), DynPosition::integer(100)]));
    }

    #[test]
    fn cross_region_n_intersect_complement_is_empty() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let r = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(5, 20)),
        ]);
        let i = r.intersect(&r.complement());
        assert!(i.is_empty());
    }

    #[test]
    fn cross_region_n_minus_self_is_empty() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let r = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(5, 20)),
        ]);
        let diff = r.minus(&r);
        assert!(diff.is_empty());
    }

    #[test]
    fn cross_region_n_intersect_identity() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let r = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(5, 20)),
        ]);
        assert_eq!(r.intersect(&r), r);
    }

    #[test]
    fn cross_region_n_union_identity() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let r = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(5, 20)),
        ]);
        let u = r.union_with(&r);
        assert!(space.contains(&u, &[DynPosition::integer(5), DynPosition::integer(10)]));
        assert!(!space.contains(&u, &[DynPosition::integer(0), DynPosition::integer(10)]));
    }

    #[test]
    fn cross_region_n_intersect_commutative() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let a = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
        ]);
        let b = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(5, 15)),
            CrossRegionN::axis_integer(IntegerRegion::interval(3, 7)),
        ]);
        assert_eq!(a.intersect(&b), b.intersect(&a));
    }

    #[test]
    fn cross_region_n_union_commutative() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let a = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 5)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 5)),
        ]);
        let b = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(3, 8)),
            CrossRegionN::axis_integer(IntegerRegion::interval(3, 8)),
        ]);
        let ab = a.union_with(&b);
        let ba = b.union_with(&a);
        assert!(space.contains(&ab, &[DynPosition::integer(2), DynPosition::integer(2)]));
        assert!(space.contains(&ab, &[DynPosition::integer(7), DynPosition::integer(7)]));
        assert!(space.contains(&ba, &[DynPosition::integer(2), DynPosition::integer(2)]));
        assert!(space.contains(&ba, &[DynPosition::integer(7), DynPosition::integer(7)]));
    }

    // 2G. Per-axis filtering: "all endorsements from club X with tokens in range Y"

    #[test]
    fn per_club_endorsement_region() {
        let club_id = 42u64;
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let region = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::singleton(club_id as i64)),
            CrossRegionN::axis_integer(IntegerRegion::interval(100, 200)),
        ]);
        assert!(space.contains(&region, &[
            DynPosition::integer(club_id as i64),
            DynPosition::integer(150),
        ]));
        assert!(!space.contains(&region, &[
            DynPosition::integer(99),
            DynPosition::integer(150),
        ]));
        assert!(!space.contains(&region, &[
            DynPosition::integer(club_id as i64),
            DynPosition::integer(99),
        ]));
    }

    #[test]
    fn per_club_endorsement_intersect_two_clubs() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let club_a = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::singleton(1)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 100)),
        ]);
        let club_b = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::singleton(2)),
            CrossRegionN::axis_integer(IntegerRegion::interval(50, 200)),
        ]);
        let intersection = club_a.intersect(&club_b);
        assert!(
            intersection.is_empty(),
            "different clubs should produce empty intersection on club axis"
        );
    }

    // =========================================================
    // Part 3: Space Flexibility
    // =========================================================

    // 3A. 1D space
    #[test]
    fn space_1d_integer() {
        let space = CrossSpaceN::new(vec![CrossSpaceNSlot::integer()]);
        assert_eq!(space.dimension(), 1);
        let region = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
        ]);
        assert!(space.contains(&region, &[DynPosition::integer(5)]));
        assert!(!space.contains(&region, &[DynPosition::integer(15)]));
    }

    // 3B. 5D space
    #[test]
    fn space_5d_integer() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        assert_eq!(space.dimension(), 5);
        let region = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
        ]);
        assert!(space.contains(&region, &[
            DynPosition::integer(5),
            DynPosition::integer(3),
            DynPosition::integer(7),
            DynPosition::integer(1),
            DynPosition::integer(9),
        ]));
        assert!(!space.contains(&region, &[
            DynPosition::integer(5),
            DynPosition::integer(3),
            DynPosition::integer(11),
            DynPosition::integer(1),
            DynPosition::integer(9),
        ]));
    }

    // 3C. Mixed types: Integer × Real × Sequence
    #[test]
    fn space_3d_mixed_operations() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::real(),
            CrossSpaceNSlot::sequence(),
        ]);
        let a = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_real(crate::space::real::RealRegion::interval(0.0, 1.0, true, true)),
            CrossRegionN::axis_sequence(SequenceRegion::prefixed_by(&Sequence::one(1), 0)),
        ]);
        let b = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(5, 15)),
            CrossRegionN::axis_real(crate::space::real::RealRegion::interval(0.5, 2.0, true, true)),
            CrossRegionN::axis_sequence(SequenceRegion::prefixed_by(&Sequence::one(1), 0)),
        ]);
        let c = a.intersect(&b);
        assert!(space.contains(&c, &[
            DynPosition::integer(7),
            DynPosition::real(0.7),
            DynPosition::sequence(Sequence::from_dotted("1.3")),
        ]));
        assert!(!space.contains(&c, &[
            DynPosition::integer(3),
            DynPosition::real(0.7),
            DynPosition::sequence(Sequence::from_dotted("1.3")),
        ]));
    }

    // 3D. Dynamic position type dispatch
    #[test]
    fn dyn_position_type_checks() {
        let int_pos = DynPosition::integer(42);
        assert_eq!(int_pos.as_integer(), Some(42));
        assert_eq!(int_pos.as_real(), None);
        assert!(int_pos.as_composite().is_none());

        let real_pos = DynPosition::real(3.14);
        assert_eq!(real_pos.as_real(), Some(3.14));
        assert_eq!(real_pos.as_integer(), None);

        let seq_pos = DynPosition::sequence(Sequence::from_dotted("1.3.5"));
        assert_eq!(seq_pos.as_integer(), None);
        assert!(seq_pos.as_composite().is_none());

        let comp = DynPosition::composite(vec![
            DynPosition::integer(1),
            DynPosition::real(2.0),
        ]);
        let parts = comp.as_composite().unwrap();
        assert_eq!(parts.len(), 2);
    }

    // 3E. CrossRegionN per-axis access
    #[test]
    fn cross_region_n_per_axis_access() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let region = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 5)),
            CrossRegionN::axis_integer(IntegerRegion::interval(10, 20)),
            CrossRegionN::axis_integer(IntegerRegion::interval(100, 200)),
        ]);
        assert_eq!(region.axis_count(), 3);
        assert!(region.axis(0).is_some());
        assert!(region.axis(1).is_some());
        assert!(region.axis(2).is_some());
        assert!(region.axis(3).is_none());
    }

    // 3F. Ordering across mixed dimensions
    #[test]
    fn cross_order_n_lexicographic() {
        let order = CrossOrderN::ascending(3);
        let a = vec![DynPosition::integer(1), DynPosition::integer(2), DynPosition::integer(3)];
        let b = vec![DynPosition::integer(1), DynPosition::integer(3), DynPosition::integer(0)];
        let c = vec![DynPosition::integer(2), DynPosition::integer(0), DynPosition::integer(0)];
        assert_eq!(order.compare(&a, &b), Some(std::cmp::Ordering::Less));
        assert_eq!(order.compare(&b, &c), Some(std::cmp::Ordering::Less));
    }

    #[test]
    fn cross_order_n_descending() {
        let order = CrossOrderN::descending(2);
        let a = vec![DynPosition::integer(5), DynPosition::integer(3)];
        let b = vec![DynPosition::integer(3), DynPosition::integer(7)];
        assert_eq!(order.compare(&a, &b), Some(std::cmp::Ordering::Less));
    }

    // 3G. DSP inverse on N-dimensional space
    #[test]
    fn cross_dsp_n_inverse_roundtrip() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let dsp = space.identity_dsp();
        let inv = dsp.inverse();
        assert_eq!(dsp.axis_count(), 3);
        assert_eq!(inv.axis_count(), 3);
    }

    // =========================================================
    // Part 4: Endorsement-CrossRegion Integration Scenarios
    // =========================================================

    // These test the integration patterns for wiring CrossRegionN
    // into the endorsement system.

    #[test]
    fn endorsement_region_from_club_token_pairs() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let mut region = space.empty_region();
        let pairs = [(1i64, 10i64), (1, 20), (2, 30), (3, 40)];
        for &(club, token) in &pairs {
            let single = space.box_region(vec![
                CrossRegionN::axis_integer(IntegerRegion::singleton(club)),
                CrossRegionN::axis_integer(IntegerRegion::singleton(token)),
            ]);
            region = region.union_with(&single);
        }
        for &(club, token) in &pairs {
            assert!(space.contains(&region, &[
                DynPosition::integer(club),
                DynPosition::integer(token),
            ]));
        }
        assert!(!space.contains(&region, &[
            DynPosition::integer(4),
            DynPosition::integer(50),
        ]));
    }

    #[test]
    fn endorsement_region_intersect_two_sets() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let set_a = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 5)),
            CrossRegionN::axis_integer(IntegerRegion::interval(10, 50)),
        ]);
        let set_b = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(3, 8)),
            CrossRegionN::axis_integer(IntegerRegion::interval(20, 60)),
        ]);
        let shared = set_a.intersect(&set_b);
        assert!(space.contains(&shared, &[
            DynPosition::integer(4),
            DynPosition::integer(30),
        ]));
        assert!(!space.contains(&shared, &[
            DynPosition::integer(2),
            DynPosition::integer(30),
        ]));
        assert!(!space.contains(&shared, &[
            DynPosition::integer(4),
            DynPosition::integer(15),
        ]));
    }

    #[test]
    fn endorsement_region_filter_by_club() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let all_endorsements = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(100, 500)),
        ]);
        let club_filter = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::singleton(3)),
            CrossRegionN::axis_integer(IntegerRegion::full()),
        ]);
        let filtered = all_endorsements.intersect(&club_filter);
        assert!(space.contains(&filtered, &[
            DynPosition::integer(3),
            DynPosition::integer(200),
        ]));
        assert!(!space.contains(&filtered, &[
            DynPosition::integer(5),
            DynPosition::integer(200),
        ]));
    }

    #[test]
    fn endorsement_region_exclude_club() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let all_endorsements = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(1, 10)),
            CrossRegionN::axis_integer(IntegerRegion::interval(100, 500)),
        ]);
        let excluded = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::singleton(5)),
            CrossRegionN::axis_integer(IntegerRegion::full()),
        ]);
        let remaining = all_endorsements.minus(&excluded);
        assert!(space.contains(&remaining, &[
            DynPosition::integer(3),
            DynPosition::integer(200),
        ]));
        assert!(!space.contains(&remaining, &[
            DynPosition::integer(5),
            DynPosition::integer(200),
        ]));
    }

    #[test]
    fn endorsement_region_token_range_per_club() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let club_1_tokens = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::singleton(1)),
            CrossRegionN::axis_integer(IntegerRegion::interval(100, 200)),
        ]);
        let club_2_tokens = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::singleton(2)),
            CrossRegionN::axis_integer(IntegerRegion::interval(300, 400)),
        ]);
        let combined = club_1_tokens.union_with(&club_2_tokens);
        assert!(space.contains(&combined, &[
            DynPosition::integer(1),
            DynPosition::integer(150),
        ]));
        assert!(space.contains(&combined, &[
            DynPosition::integer(2),
            DynPosition::integer(350),
        ]));
        assert!(!space.contains(&combined, &[
            DynPosition::integer(1),
            DynPosition::integer(350),
        ]));
    }

    #[test]
    fn endorsement_tumbler_region_2d_sequence_integer() {
        let space = CrossSpace2::new(SequenceSpace::new(), IntegerSpace::new());
        let region = space.box_region(
            SequenceRegion::prefixed_by(&Sequence::from_numbers(vec![1, 0, 5]), 2),
            IntegerRegion::interval(10, 100),
        );
        assert!(region.contains(&Tuple2(
            SequencePos(Sequence::from_dotted("1.5.3")),
            IntegerPos(50),
        )));
        assert!(!region.contains(&Tuple2(
            SequencePos(Sequence::from_dotted("1.3.3")),
            IntegerPos(50),
        )));
        assert!(!region.contains(&Tuple2(
            SequencePos(Sequence::from_dotted("1.5.3")),
            IntegerPos(5),
        )));
    }

    #[test]
    fn endorsement_tumbler_region_projection() {
        let space = CrossSpace2::new(SequenceSpace::new(), IntegerSpace::new());
        let region = space.box_region(
            SequenceRegion::prefixed_by(&Sequence::from_numbers(vec![1, 0, 5]), 2),
            IntegerRegion::interval(10, 100),
        );
        let seq_proj = region.projection_a();
        assert!(seq_proj.contains_sequence(&Sequence::from_dotted("1.5.3")));
        assert!(!seq_proj.contains_sequence(&Sequence::from_dotted("2.5.3")));
        let token_proj = region.projection_b();
        assert!(token_proj.contains(&IntegerPos(50)));
        assert!(!token_proj.contains(&IntegerPos(5)));
    }

    // =========================================================
    // Part 5: Stress / Scale tests
    // =========================================================

    #[test]
    fn stress_tumbler_10_level_decompose_recompose() {
        let mut nums = Vec::new();
        for i in 1..=10 {
            if i > 1 {
                nums.push(0);
            }
            nums.push(i);
        }
        let addr = Sequence::from_numbers(nums);

        let mut current = addr.clone();
        let mut parts = Vec::new();
        loop {
            let first = current.first();
            let rest = current.rest();
            parts.push(first);
            if rest.is_zero() {
                break;
            }
            current = rest;
        }
        assert_eq!(parts.len(), 10);

        let rebuilt = parts.iter().rev().skip(1).fold(parts[9].clone(), |acc, p| {
            p.with_rest(&acc)
        });
        assert_eq!(rebuilt, addr);
    }

    #[test]
    fn stress_prefix_query_large_region() {
        let space = SequenceSpace::new();
        let prefix = Sequence::one(1);
        let region = space.prefixed_by(&prefix, 0);

        for i in 1..100 {
            let addr = Sequence::from_numbers(vec![1, 0, i]);
            assert!(region.contains_sequence(&addr));
        }
        assert!(!region.contains_sequence(&Sequence::from_numbers(vec![2, 0, 1])));
    }

    #[test]
    fn stress_cross_region_n_4d_set_ops() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::integer(),
        ]);
        let r = space.box_region(vec![
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 100)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 100)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 100)),
            CrossRegionN::axis_integer(IntegerRegion::interval(0, 100)),
        ]);
        assert!(!r.is_empty());
        assert!(!r.is_full());
        let c = r.complement();
        let back = c.complement();
        assert!(space.contains(&back, &[DynPosition::integer(50), DynPosition::integer(50), DynPosition::integer(50), DynPosition::integer(50)]));
        assert!(!space.contains(&back, &[DynPosition::integer(200), DynPosition::integer(50), DynPosition::integer(50), DynPosition::integer(50)]));
    }
}
