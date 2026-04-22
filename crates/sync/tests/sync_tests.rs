use xudanu_sync::protocol::SyncProtocol;
use xudanu_sync::awareness::{Awareness, AwarenessState};
use xudanu_sync::message;
use xudanu_core::state_vector::StateVector;
use xudanu_types::*;

fn make_site(id: u8) -> SiteId {
    let mut bytes = [0u8; 32];
    bytes[0] = id;
    SiteId::from_bytes(bytes)
}

// ── State Vector Sync ──

#[test]
fn test_sync_step1_creation() {
    let mut sv = StateVector::new();
    let site = make_site(1);
    sv.set(site, 5);

    let protocol = SyncProtocol::new(sv);
    let msg = protocol.create_sync_step1(site);

    assert_eq!(msg.sender_site, site);
    match &msg.message_type {
        xudanu_sync::message::SyncMessageType::StateVector(sv_msg) => {
            assert_eq!(sv_msg.state_vector.len(), 1);
            assert_eq!(sv_msg.state_vector[0], (site, 5));
        }
        _ => panic!("Expected StateVector message"),
    }
}

#[test]
fn test_empty_state_vector_sync() {
    let sv = StateVector::new();
    let protocol = SyncProtocol::new(sv);
    let site = make_site(1);
    let msg = protocol.create_sync_step1(site);

    match &msg.message_type {
        xudanu_sync::message::SyncMessageType::StateVector(sv_msg) => {
            assert!(sv_msg.state_vector.is_empty());
        }
        _ => panic!("Expected StateVector message"),
    }
}

#[test]
fn test_changes_message() {
    let sv = StateVector::new();
    let mut protocol = SyncProtocol::new(sv);
    let site = make_site(1);
    let author: AuthorId = [1u8; 32];

    let mut changes = Vec::new();
    let change = Change::unsigned(
        author,
        site,
        vec![],
        vec![],
        HybridTimestamp::now(1),
        1,
    );
    changes.push(change);

    let msg = protocol.create_changes_message(changes, site, author);

    match &msg.message_type {
        xudanu_sync::message::SyncMessageType::Changes(cmsg) => {
            assert_eq!(cmsg.changes.len(), 1);
            assert!(cmsg.requires_ack);
        }
        _ => panic!("Expected Changes message"),
    }
}

#[test]
fn test_protocol_local_state_vector() {
    let mut sv = StateVector::new();
    let site = make_site(1);
    sv.set(site, 10);

    let protocol = SyncProtocol::new(sv.clone());
    let result = protocol.local_state_vector();
    assert_eq!(result.get(&site), 10);
}

#[test]
fn test_protocol_update_state_vector() {
    let mut sv = StateVector::new();
    let site = make_site(1);
    sv.set(site, 5);

    let mut protocol = SyncProtocol::new(sv);

    let mut new_sv = StateVector::new();
    new_sv.set(site, 10);
    new_sv.set(make_site(2), 3);
    protocol.update_local_state_vector(new_sv);

    let result = protocol.local_state_vector();
    assert_eq!(result.get(&site), 10);
    assert_eq!(result.get(&make_site(2)), 3);
}

// ── Awareness ──

#[test]
fn test_awareness_basic() {
    let mut awareness = Awareness::new();
    assert_eq!(awareness.client_count(), 0);

    let state = AwarenessState {
        client_id: 1,
        user_name: "Alice".to_string(),
        user_color: "#ff0000".to_string(),
        cursor: None,
        selection: None,
        is_typing: false,
        author: [1u8; 32],
    };

    awareness.set_local_state(state);
    assert_eq!(awareness.client_count(), 1);
    assert!(awareness.get_state(1).is_some());
    assert_eq!(awareness.get_state(1).unwrap().user_name, "Alice");
}

#[test]
fn test_awareness_multiple_clients() {
    let mut awareness = Awareness::new();

    for i in 0..5 {
        awareness.set_local_state(AwarenessState {
            client_id: i,
            user_name: format!("User {}", i),
            user_color: format!("#{:06x}", i * 111111),
            cursor: None,
            selection: None,
            is_typing: false,
            author: [i as u8; 32],
        });
    }

    assert_eq!(awareness.client_count(), 5);
}

#[test]
fn test_awareness_remove_client() {
    let mut awareness = Awareness::new();

    awareness.set_local_state(AwarenessState {
        client_id: 1,
        user_name: "Alice".to_string(),
        user_color: "#ff0000".to_string(),
        cursor: None,
        selection: None,
        is_typing: false,
        author: [1u8; 32],
    });

    assert_eq!(awareness.client_count(), 1);
    awareness.remove_client(1);
    assert_eq!(awareness.client_count(), 0);
    assert!(awareness.get_state(1).is_none());
}

#[test]
fn test_awareness_update_replaces() {
    let mut awareness = Awareness::new();

    awareness.set_local_state(AwarenessState {
        client_id: 1,
        user_name: "Alice".to_string(),
        user_color: "#ff0000".to_string(),
        cursor: None,
        selection: None,
        is_typing: false,
        author: [1u8; 32],
    });

    awareness.set_local_state(AwarenessState {
        client_id: 1,
        user_name: "Alice Updated".to_string(),
        user_color: "#00ff00".to_string(),
        cursor: None,
        selection: None,
        is_typing: true,
        author: [1u8; 32],
    });

    assert_eq!(awareness.client_count(), 1);
    assert_eq!(awareness.get_state(1).unwrap().user_name, "Alice Updated");
    assert!(awareness.get_state(1).unwrap().is_typing);
}

#[test]
fn test_awareness_apply_remote() {
    let mut awareness = Awareness::new();

    let remote_state = AwarenessState {
        client_id: 42,
        user_name: "Bob".to_string(),
        user_color: "#0000ff".to_string(),
        cursor: None,
        selection: None,
        is_typing: false,
        author: [2u8; 32],
    };

    awareness.apply_remote(remote_state);
    assert_eq!(awareness.client_count(), 1);
    assert_eq!(awareness.get_state(42).unwrap().user_name, "Bob");
}

#[test]
fn test_awareness_iterate_all_states() {
    let mut awareness = Awareness::new();

    for i in 0..3 {
        awareness.set_local_state(AwarenessState {
            client_id: i,
            user_name: format!("User {}", i),
            user_color: "#000000".to_string(),
            cursor: None,
            selection: None,
            is_typing: false,
            author: [i as u8; 32],
        });
    }

    let states: Vec<_> = awareness.all_states().collect();
    assert_eq!(states.len(), 3);
}

#[test]
fn test_awareness_remove_nonexistent() {
    let mut awareness = Awareness::new();
    awareness.remove_client(999);
    assert_eq!(awareness.client_count(), 0);
}
