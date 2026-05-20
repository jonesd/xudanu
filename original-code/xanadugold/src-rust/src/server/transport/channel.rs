use crate::server::SessionId;
use crate::server::detector::Detector;
use super::protocol::EventPayload;

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
