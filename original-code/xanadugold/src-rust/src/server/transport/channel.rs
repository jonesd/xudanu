use super::protocol::EventPayload;
use crate::server::detector::Detector;
use crate::server::SessionId;

#[derive(Debug, Clone)]
pub struct EventMessage {
    pub session_id: SessionId,
    pub subscription_id: u16,
    pub event: EventPayload,
}

pub struct ChannelDetector {
    session_id: SessionId,
    subscription_id: u16,
    sender: tokio::sync::mpsc::UnboundedSender<EventMessage>,
}

impl ChannelDetector {
    pub fn new(
        session_id: SessionId,
        sender: tokio::sync::mpsc::UnboundedSender<EventMessage>,
    ) -> Self {
        ChannelDetector {
            session_id,
            subscription_id: 0,
            sender,
        }
    }

    pub fn new_with_sub(
        session_id: SessionId,
        subscription_id: u16,
        sender: tokio::sync::mpsc::UnboundedSender<EventMessage>,
    ) -> Self {
        ChannelDetector {
            session_id,
            subscription_id,
            sender,
        }
    }

    pub fn send_content_match(
        &self,
        fossil_id: u64,
        edition_be_id: crate::edition::BeId,
        is_direct: bool,
        work_be_id: Option<crate::edition::BeId>,
        title: Option<String>,
    ) {
        let msg = EventMessage {
            session_id: self.session_id,
            subscription_id: self.subscription_id,
            event: EventPayload::ContentMatch {
                fossil_id,
                edition_be_id,
                is_direct,
                work_be_id,
                title,
            },
        };
        let _ = self.sender.send(msg);
    }
}

impl Detector for ChannelDetector {
    fn on_event(&mut self, event: &crate::server::Event) {
        let msg = EventMessage {
            session_id: self.session_id,
            subscription_id: self.subscription_id,
            event: EventPayload::from_event(event),
        };
        let _ = self.sender.send(msg);
    }

    fn subscription_id(&self) -> u16 {
        self.subscription_id
    }
}

impl std::fmt::Debug for ChannelDetector {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ChannelDetector")
            .field("session_id", &self.session_id)
            .field("subscription_id", &self.subscription_id)
            .finish()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::BeId;
    use crate::server::Event;
    use tokio::sync::mpsc;

    #[test]
    fn new_defaults_subscription_id_zero() {
        let (tx, _rx) = mpsc::unbounded_channel::<EventMessage>();
        let det = ChannelDetector::new(SessionId::new(1), tx);
        assert_eq!(det.subscription_id(), 0);
    }

    #[test]
    fn new_with_sub_sets_custom_subscription_id() {
        let (tx, _rx) = mpsc::unbounded_channel::<EventMessage>();
        let det = ChannelDetector::new_with_sub(SessionId::new(2), 42, tx);
        assert_eq!(det.subscription_id(), 42);
    }

    #[test]
    fn on_event_delivers_message() {
        let (tx, mut rx) = mpsc::unbounded_channel::<EventMessage>();
        let mut det = ChannelDetector::new(SessionId::new(7), tx);

        det.on_event(&Event::Done { operation_id: 99 });

        let msg = rx.try_recv().expect("message should be delivered");
        assert_eq!(msg.session_id, SessionId::new(7));
        assert_eq!(msg.subscription_id, 0);
        match msg.event {
            EventPayload::Done { operation_id } => assert_eq!(operation_id, 99),
            other => panic!("expected Done, got {:?}", other),
        }
    }

    #[test]
    fn on_event_uses_custom_subscription_id() {
        let (tx, mut rx) = mpsc::unbounded_channel::<EventMessage>();
        let mut det = ChannelDetector::new_with_sub(SessionId::new(3), 5, tx);

        det.on_event(&Event::Done { operation_id: 1 });

        let msg = rx.try_recv().unwrap();
        assert_eq!(msg.subscription_id, 5);
    }

    #[test]
    fn send_content_match_delivers_payload() {
        let (tx, mut rx) = mpsc::unbounded_channel::<EventMessage>();
        let det = ChannelDetector::new_with_sub(SessionId::new(10), 3, tx);

        det.send_content_match(
            7,
            100 as BeId,
            true,
            Some(200 as BeId),
            Some("test title".to_string()),
        );

        let msg = rx.try_recv().expect("content match should be delivered");
        assert_eq!(msg.session_id, SessionId::new(10));
        assert_eq!(msg.subscription_id, 3);
        match msg.event {
            EventPayload::ContentMatch {
                fossil_id,
                edition_be_id,
                is_direct,
                work_be_id,
                title,
            } => {
                assert_eq!(fossil_id, 7);
                assert_eq!(edition_be_id, 100);
                assert!(is_direct);
                assert_eq!(work_be_id, Some(200));
                assert_eq!(title, Some("test title".to_string()));
            }
            other => panic!("expected ContentMatch, got {:?}", other),
        }
    }

    #[test]
    fn send_content_match_without_receiver_does_not_panic() {
        let (tx, rx) = mpsc::unbounded_channel::<EventMessage>();
        let det = ChannelDetector::new(SessionId::new(1), tx);

        drop(rx);

        det.send_content_match(1, 1, false, None, None);
    }

    #[test]
    fn on_event_without_receiver_does_not_panic() {
        let (tx, rx) = mpsc::unbounded_channel::<EventMessage>();
        let mut det = ChannelDetector::new(SessionId::new(1), tx);

        drop(rx);

        det.on_event(&Event::Done { operation_id: 0 });
    }
}
