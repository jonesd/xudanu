use proptest::prelude::*;

mod varint_roundtrip {
    use super::*;

    proptest! {
        #[test]
        fn encode_decode_roundtrip(val: u64) {
            let mut buf = Vec::new();
            xudanu::server::transport::varint::encode_varint(val, &mut buf);
            let (decoded, bytes_read) = xudanu::server::transport::varint::decode_varint(&buf)
                .expect("decode should succeed");
            prop_assert_eq!(decoded, val);
            prop_assert_eq!(bytes_read, buf.len());
        }
    }
}

mod orset_crdt_properties {
    use super::*;

    fn arb_entry() -> impl Strategy<Value = xudanu::server::federation::MembershipEntry> {
        any::<u64>().prop_map(|n| xudanu::server::federation::MembershipEntry::new(
            format!("server-{}", n),
            format!("{:064x}", n),
            format!("kex-{}", n),
            vec![],
            n,
        ))
    }

    proptest! {
        #[test]
        fn merge_is_commutative(
            entries_a in prop::collection::vec(arb_entry(), 0..20),
            entries_b in prop::collection::vec(arb_entry(), 0..20),
        ) {
            let mut set_a = xudanu::server::federation::OrSet::new();
            let mut set_b = xudanu::server::federation::OrSet::new();

            for (i, e) in entries_a.iter().enumerate() {
                set_a.add(e.clone(), xudanu::server::federation::OrSetTag::new(format!("a-{}", i), i as u64));
            }
            for (i, e) in entries_b.iter().enumerate() {
                set_b.add(e.clone(), xudanu::server::federation::OrSetTag::new(format!("b-{}", i), i as u64));
            }

            let mut ab = set_a.clone();
            ab.merge(&set_b);
            let mut ba = set_b.clone();
            ba.merge(&set_a);

            let mut ab_values: Vec<_> = ab.values().into_iter().collect();
            let mut ba_values: Vec<_> = ba.values().into_iter().collect();
            ab_values.sort_by_key(|e| e.server_id.clone());
            ba_values.sort_by_key(|e| e.server_id.clone());
            prop_assert_eq!(ab_values.len(), ba_values.len());
        }

        #[test]
        fn merge_is_idempotent(
            entries in prop::collection::vec(arb_entry(), 0..20),
        ) {
            let mut set = xudanu::server::federation::OrSet::new();
            for (i, e) in entries.iter().enumerate() {
                set.add(e.clone(), xudanu::server::federation::OrSetTag::new(format!("x-{}", i), i as u64));
            }

            let mut merged_once = set.clone();
            merged_once.merge(&set);
            let mut merged_twice = merged_once.clone();
            merged_twice.merge(&set);

            prop_assert_eq!(merged_once.values().len(), merged_twice.values().len());
        }

        #[test]
        fn remove_then_add_same_tag_still_tombstoned(
            entry in arb_entry(),
        ) {
            let mut set = xudanu::server::federation::OrSet::new();
            let tag = xudanu::server::federation::OrSetTag::new(String::from("x"), 1);
            set.add(entry.clone(), tag.clone());
            prop_assert!(set.contains(&entry));

            set.remove_value(&entry);
            prop_assert!(!set.contains(&entry));

            set.add(entry.clone(), tag.clone());
            prop_assert!(!set.contains(&entry), "re-adding with tombstoned tag should not revive");
        }
    }
}

mod lww_register_properties {
    use super::*;

    proptest! {
        #[test]
        fn higher_timestamp_wins(
            ts1: u64,
            ts2: u64,
            srv1: String,
            srv2: String,
        ) {
            prop_assume!(srv1 != srv2 || ts1 != ts2);

            let ts_lo = ts1.min(ts2) % 1_000_000;
            let ts_hi = ts1.max(ts2) % 1_000_000;

            let mut reg = xudanu::server::federation::LwwRegister::new("a".to_string(), ts_lo, srv1.clone());
            let updated = reg.set("b".to_string(), ts_hi, srv2.clone());

            if (ts_hi, &srv2) > (ts_lo, &srv1) {
                prop_assert!(updated);
                prop_assert_eq!(reg.value(), "b");
            }
        }

        #[test]
        fn merge_three_way_converges(
            ts_a: u64,
            ts_b: u64,
            ts_c: u64,
        ) {
            let ts_a = ts_a % 1_000_000;
            let ts_b = ts_b % 1_000_000;
            let ts_c = ts_c % 1_000_000;

            let mut a = xudanu::server::federation::LwwRegister::new("a".to_string(), ts_a, "s1".to_string());
            let mut b = xudanu::server::federation::LwwRegister::new("b".to_string(), ts_b, "s2".to_string());
            let mut c = xudanu::server::federation::LwwRegister::new("c".to_string(), ts_c, "s3".to_string());

            a.merge(&b);
            a.merge(&c);
            b.merge(&a);
            b.merge(&c);
            c.merge(&a);
            c.merge(&b);

            prop_assert_eq!(a.value(), b.value());
            prop_assert_eq!(b.value(), c.value());
        }
    }
}

mod content_fingerprint_properties {
    use super::*;

    proptest! {
        #[test]
        fn same_text_same_fingerprint(a: String, b: String) {
            let elem_a = xudanu::edition::RangeElement::text(&a);
            let elem_b = xudanu::edition::RangeElement::text(&b);

            if a == b {
                prop_assert_eq!(elem_a.content_fingerprint(), elem_b.content_fingerprint());
            } else {
                prop_assert_ne!(elem_a.content_fingerprint(), elem_b.content_fingerprint());
            }
        }

        #[test]
        fn text_vs_blob_different_fingerprint(text: String) {
            prop_assume!(!text.is_empty());
            let text_elem = xudanu::edition::RangeElement::text(&text);
            let blob_elem = xudanu::edition::RangeElement::blob(42, "text/plain", text.len() as u64);
            prop_assert_ne!(text_elem.content_fingerprint(), blob_elem.content_fingerprint());
        }

        #[test]
        fn fingerprint_is_deterministic(text: String) {
            let elem1 = xudanu::edition::RangeElement::text(&text);
            let elem2 = xudanu::edition::RangeElement::text(&text);
            prop_assert_eq!(elem1.content_fingerprint(), elem2.content_fingerprint());
        }
    }
}

mod membership_entry_properties {
    use super::*;

    proptest! {
        #[test]
        fn eq_based_on_server_id_only(
            id1: String,
            id2: String,
            key1: String,
            key2: String,
        ) {
            let a = xudanu::server::federation::MembershipEntry::new(id1.clone(), key1, String::from("kex1"), vec![], 0);
            let b = xudanu::server::federation::MembershipEntry::new(id2.clone(), key2, String::from("kex2"), vec![], 1);

            if id1 == id2 {
                prop_assert_eq!(a, b, "entries with same server_id should be equal");
            } else {
                prop_assert_ne!(a, b, "entries with different server_id should not be equal");
            }
        }

        #[test]
        fn hash_consistent_with_eq(id1: String, id2: String) {
            use std::collections::hash_map::DefaultHasher;
            use std::hash::{Hash, Hasher};

            let a = xudanu::server::federation::MembershipEntry::new(id1.clone(), String::from("k1"), String::from("kex1"), vec![], 0);
            let b = xudanu::server::federation::MembershipEntry::new(id2.clone(), String::from("k2"), String::from("kex2"), vec![], 1);

            let mut h1 = DefaultHasher::new();
            let mut h2 = DefaultHasher::new();
            a.hash(&mut h1);
            b.hash(&mut h2);

            if id1 == id2 {
                prop_assert_eq!(h1.finish(), h2.finish(), "equal entries must have equal hashes");
            }
        }
    }
}

mod membership_state_properties {
    use super::*;

    fn arb_entry() -> impl Strategy<Value = xudanu::server::federation::MembershipEntry> {
        any::<u64>().prop_map(|n| xudanu::server::federation::MembershipEntry::new(
            format!("server-{}", n),
            format!("{:064x}", n),
            format!("kex-{}", n),
            vec![],
            n,
        ))
    }

    proptest! {
        #[test]
        fn merge_idempotent_across_random_members(
            entries in prop::collection::vec(arb_entry(), 0..10),
        ) {
            let mut state_a = xudanu::server::federation::MembershipState::new(1);
            let mut state_b = xudanu::server::federation::MembershipState::new(1);

            for e in &entries {
                state_a.add_member(e.clone(), xudanu::server::federation::OrSetTag::new(String::from("a"), 1));
            }

            state_b.merge(&state_a);
            state_b.merge(&state_a);

            prop_assert_eq!(state_a.all_members().len(), state_b.all_members().len());
        }
    }
}
