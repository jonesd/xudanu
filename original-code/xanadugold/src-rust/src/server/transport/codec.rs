use crate::edition::{BeId, RangeElement, XnRegion};
use crate::server::lock::LockCredential;
use serde::Deserialize;

use super::protocol::*;
use super::varint;

#[derive(Debug)]
pub enum ProtocolError {
    FrameParse(FrameParseError),
    Serialization(String),
}

impl std::fmt::Display for ProtocolError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ProtocolError::FrameParse(e) => write!(f, "frame parse: {}", e),
            ProtocolError::Serialization(s) => write!(f, "serialization: {}", s),
        }
    }
}

impl std::error::Error for ProtocolError {}

impl From<FrameParseError> for ProtocolError {
    fn from(e: FrameParseError) -> Self {
        ProtocolError::FrameParse(e)
    }
}

impl From<varint::VarintError> for ProtocolError {
    fn from(e: varint::VarintError) -> Self {
        ProtocolError::FrameParse(FrameParseError::PayloadDecode(e.to_string()))
    }
}

/// WireCodec abstracts the serialization format for WebSocket frames.
///
/// Two implementations are provided:
///
/// - **BinaryCodec**: Uses a compact binary format with a 4-byte header
///   `[version, msg_type, request_id_hi, request_id_lo]` followed by
///   LEB128 varint-encoded lengths and postcard-serialized payloads.
///   Used for production where bandwidth matters.
///
/// - **JsonCodec**: Uses human-readable JSON text frames. Each frame is a
///   JSON object with fields like `{"v":1, "type":"request", "id":42,
///   "op":"work.revise", "payload":{...}}`. Easier for third-party
///   integrations, debugging, and prototyping.
///
/// Both codecs produce/consume the same `WireRequest`/`WireResponse`/
/// `WireEvent` types. The codec selection happens once at WebSocket
/// upgrade time (via query parameter `?format=json` or subprotocol
/// negotiation). After that, all frames on that connection use the
/// chosen format.
///
/// ## Binary Frame Layout
///
/// ```text
/// [1B version][1B msg_type][2B request_id BE][payload...]
///
/// REQUEST payload:
///   [varint: operation code u16]
///   [varint: payload length]
///   [postcard-encoded WireRequest variant payload]
///
/// RESPONSE payload:
///   [varint: payload length]
///   [postcard-encoded ResponseValue]
///
/// ERROR payload:
///   [varint: message length]
///   [UTF-8 error message bytes]
///
/// EVENT payload:
///   [varint: payload length]
///   [postcard-encoded WireEvent]
///
/// SUBSCRIBE payload:
///   [varint: payload length]
///   [postcard-encoded SubscribeRequest]
/// ```
///
/// ## JSON Frame Layout
///
/// ```json
/// {"v":1, "type":"request", "id":42, "op":"work_revise",
///  "payload":{"work_id":123, "edition":{...}}}
/// ```
///
/// ```json
/// {"v":1, "type":"response", "id":42,
///  "value":{"type":"humber", "value":2}}
/// ```
///
/// ```json
/// {"v":1, "type":"error", "id":42,
///  "code":"not_grabbed", "message":"work 123 not grabbed"}
/// ```
///
/// ```json
/// {"v":1, "type":"event", "id":7,
///  "event":{"type":"work_revised",
///           "payload":{"work_be_id":123,"revision":2,"session_id":1}}}
/// ```
pub trait WireCodec: Send + Sync + std::fmt::Debug {
    fn decode_request(&self, data: &[u8]) -> Result<IncomingMessage, ProtocolError>;
    fn encode_response(
        &self,
        request_id: u16,
        value: &ResponseValue,
    ) -> Result<Vec<u8>, ProtocolError>;
    fn encode_error(
        &self,
        request_id: u16,
        code: ErrorCode,
        message: &str,
    ) -> Result<Vec<u8>, ProtocolError>;
    fn encode_event(&self, event: &WireEvent) -> Result<Vec<u8>, ProtocolError>;
    fn encode_heartbeat(&self) -> Result<Vec<u8>, ProtocolError>;
    fn is_text(&self) -> bool;
}

#[derive(Debug, Clone)]
pub struct BinaryCodec;

impl WireCodec for BinaryCodec {
    fn decode_request(&self, data: &[u8]) -> Result<IncomingMessage, ProtocolError> {
        if data.len() < 4 {
            return Err(FrameParseError::TruncatedFrame.into());
        }
        let version = data[0];
        if version != PROTOCOL_VERSION {
            return Err(FrameParseError::UnsupportedVersion(version).into());
        }
        let msg_type =
            MessageType::from_byte(data[1]).ok_or(FrameParseError::InvalidMessageType(data[1]))?;
        let request_id = u16::from_be_bytes([data[2], data[3]]);
        let payload = &data[4..];

        match msg_type {
            MessageType::Heartbeat => Ok(IncomingMessage::Heartbeat),
            MessageType::Request => {
                let (op_code, n) = varint::decode_varint(payload)?;
                let op_u16 = op_code as u16;
                let op = OperationCode::from_u16(op_u16)
                    .ok_or(FrameParseError::UnknownOperation(op_u16))?;
                let _rest = &payload[n..];
                let wire_req = self.decode_wire_request(op, &payload[n..])?;
                Ok(IncomingMessage::Request(ParsedRequest {
                    request_id,
                    inner: wire_req,
                }))
            }
            MessageType::Subscribe => {
                let sub: SubscribeRequest = postcard::from_bytes(payload)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(IncomingMessage::Subscribe(ParsedSubscribe {
                    request_id,
                    subscribe: sub,
                }))
            }
            MessageType::Unsubscribe => Ok(IncomingMessage::Unsubscribe(ParsedUnsubscribe {
                request_id,
            })),
            _ => Err(FrameParseError::InvalidMessageType(data[1]).into()),
        }
    }

    fn encode_response(
        &self,
        request_id: u16,
        value: &ResponseValue,
    ) -> Result<Vec<u8>, ProtocolError> {
        if let ResponseValue::BlobData(data) = value {
            let mut buf = vec![PROTOCOL_VERSION, MessageType::Response.as_byte()];
            buf.extend_from_slice(&request_id.to_be_bytes());
            super::varint::encode_varint(data.len() as u64, &mut buf);
            buf.extend_from_slice(data);
            return Ok(buf);
        }
        let payload = postcard::to_allocvec(value)
            .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
        let mut buf = vec![PROTOCOL_VERSION, MessageType::Response.as_byte()];
        buf.extend_from_slice(&request_id.to_be_bytes());
        buf.extend_from_slice(&payload);
        Ok(buf)
    }

    fn encode_error(
        &self,
        request_id: u16,
        code: ErrorCode,
        message: &str,
    ) -> Result<Vec<u8>, ProtocolError> {
        let mut buf = vec![PROTOCOL_VERSION, MessageType::Error.as_byte()];
        buf.extend_from_slice(&request_id.to_be_bytes());
        buf.push(code as u8);
        let msg_bytes = message.as_bytes();
        varint::encode_varint(msg_bytes.len() as u64, &mut buf);
        buf.extend_from_slice(msg_bytes);
        Ok(buf)
    }

    fn encode_event(&self, event: &WireEvent) -> Result<Vec<u8>, ProtocolError> {
        let payload = postcard::to_allocvec(event)
            .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
        let mut buf = vec![PROTOCOL_VERSION, MessageType::Event.as_byte()];
        buf.extend_from_slice(&event.subscription_id.to_be_bytes());
        buf.extend_from_slice(&payload);
        Ok(buf)
    }

    fn encode_heartbeat(&self) -> Result<Vec<u8>, ProtocolError> {
        Ok(vec![
            PROTOCOL_VERSION,
            MessageType::Heartbeat.as_byte(),
            0x00,
            0x00,
        ])
    }

    fn is_text(&self) -> bool {
        false
    }
}

impl BinaryCodec {
    fn decode_wire_request(
        &self,
        op: OperationCode,
        data: &[u8],
    ) -> Result<WireRequest, ProtocolError> {
        if data.is_empty() {
            return self.request_without_payload(op);
        }
        let (len, n) = varint::decode_varint(data)?;
        let end = n
            .checked_add(len as usize)
            .ok_or_else(|| FrameParseError::PayloadDecode("payload length overflow".into()))?;
        if end > data.len() {
            return Err(
                FrameParseError::PayloadDecode("payload extends beyond frame".into()).into(),
            );
        }
        let payload_data = &data[n..end];
        match op {
            OperationCode::SessionConnect => Ok(WireRequest::SessionConnect),
            OperationCode::SessionDisconnect => Ok(WireRequest::SessionDisconnect),
            OperationCode::SessionLoginPublic => Ok(WireRequest::SessionLoginPublic),
            OperationCode::SessionTicketIssue => Ok(WireRequest::SessionTicketIssue),
            OperationCode::WorkGrab
            | OperationCode::WorkRelease
            | OperationCode::WorkIsGrabbed
            | OperationCode::WorkGrabber
            | OperationCode::WorkRequestGrab
            | OperationCode::WorkCancelGrabRequest
            | OperationCode::WorkGrabWaiters
            | OperationCode::WorkCanRead
            | OperationCode::WorkCanRevise
            | OperationCode::WorkReadClub
            | OperationCode::WorkEditClub
            | OperationCode::WorkRevisionCount
            | OperationCode::WorkSponsors
            | OperationCode::WorkOwner => {
                let id: BeId = postcard::from_bytes(payload_data)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                self.work_id_request(op, id)
            }
            OperationCode::WorkGetEdition
            | OperationCode::WorkPublish
            | OperationCode::WorkUnpublish
            | OperationCode::WorkIrrevocablyUnpublish
            | OperationCode::WorkIsPublished
            | OperationCode::WorkGhost
            | OperationCode::CrdtSyncClose
            | OperationCode::CrdtSyncFullState
            | OperationCode::CrdtSyncMaterialize
            | OperationCode::CrdtSyncSubscriberCount
            | OperationCode::CrdtSyncOpen
            | OperationCode::CrdtAwarenessGet
            | OperationCode::AttestationReport
            | OperationCode::WorkSummary
            | OperationCode::WorkVersionTimeline => {
                let id: BeId = postcard::from_bytes(payload_data)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                self.work_id_request(op, id)
            }
            OperationCode::ClubGet
            | OperationCode::ClubNameById
            | OperationCode::ClubClearCredential
            | OperationCode::ClubMembers => {
                let id: BeId = postcard::from_bytes(payload_data)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                self.club_id_request(op, id)
            }
            OperationCode::CrdtSyncUpdate => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    update: Vec<u8>,
                }
                let args: Args = serde_json::from_slice(payload_data)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrdtSyncUpdate {
                    work_id: args.work_id,
                    update: args.update,
                })
            }
            OperationCode::CrdtSyncDiff => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    state_vector: Vec<u8>,
                }
                let args: Args = serde_json::from_slice(payload_data)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrdtSyncDiff {
                    work_id: args.work_id,
                    state_vector: args.state_vector,
                })
            }
            OperationCode::CrdtAwarenessUpdate => {
                let req: serde_json::Value = serde_json::from_slice(payload_data)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                let wire: WireRequest = serde_json::from_value(req)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(wire)
            }
            OperationCode::CrdtRegisterAuthor => {
                let req: serde_json::Value = serde_json::from_slice(payload_data)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                let wire: WireRequest = serde_json::from_value(req)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(wire)
            }
            _ => {
                let req: serde_json::Value = serde_json::from_slice(payload_data)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                let wire: WireRequest = serde_json::from_value(req)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(wire)
            }
        }
    }

    fn request_without_payload(&self, op: OperationCode) -> Result<WireRequest, ProtocolError> {
        match op {
            OperationCode::SessionConnect => Ok(WireRequest::SessionConnect),
            OperationCode::SessionDisconnect => Ok(WireRequest::SessionDisconnect),
            OperationCode::SessionLoginPublic => Ok(WireRequest::SessionLoginPublic),
            OperationCode::SessionTicketIssue => Ok(WireRequest::SessionTicketIssue),
            OperationCode::ClubNames => Ok(WireRequest::ClubNames {
                offset: None,
                limit: None,
            }),
            OperationCode::AdminRecorderList => Ok(WireRequest::AdminRecorderList),
            OperationCode::AdminServerHealth => Ok(WireRequest::AdminServerHealth),
            OperationCode::CryptoGetPublicKey => Ok(WireRequest::CryptoGetPublicKey),
            OperationCode::CryptoKeyRotation => Ok(WireRequest::CryptoKeyRotation),
            OperationCode::CryptoKeyHistory => Ok(WireRequest::CryptoKeyHistory),
            OperationCode::FederationInfo => Ok(WireRequest::FederationInfo),
            OperationCode::FederationPeers => Ok(WireRequest::FederationPeers),
            OperationCode::MembershipSync => Ok(WireRequest::MembershipSync),
            OperationCode::MembershipLeave => Ok(WireRequest::MembershipLeave),
            OperationCode::MembershipList => Ok(WireRequest::MembershipList),
            OperationCode::GovernanceSeal => Ok(WireRequest::GovernanceSeal),
            OperationCode::GovernanceLog => Ok(WireRequest::GovernanceLog),
            OperationCode::GovernanceStatus => Ok(WireRequest::GovernanceStatus),
            OperationCode::AdminIsAcceptingConnections => {
                Ok(WireRequest::AdminIsAcceptingConnections)
            }
            OperationCode::AttributionLogStatus => Ok(WireRequest::AttributionLogStatus),
            OperationCode::AdminActiveSessions => Ok(WireRequest::AdminActiveSessions),
            OperationCode::AdminShutdown => Ok(WireRequest::AdminShutdown),
            OperationCode::AdminGrants => Ok(WireRequest::AdminGrants),
            OperationCode::AdminServerInfo => Ok(WireRequest::AdminServerInfo),
            OperationCode::ServerStats => Ok(WireRequest::ServerStats),
            OperationCode::MetricsSnapshot => Ok(WireRequest::MetricsSnapshot),
            OperationCode::WorkList => Ok(WireRequest::WorkList {
                offset: None,
                limit: None,
            }),
            OperationCode::BlobStats => Ok(WireRequest::BlobStats),
            OperationCode::LabelCreate => Ok(WireRequest::LabelCreate),
            OperationCode::WorkGraph => Ok(WireRequest::WorkGraph {
                center_work_id: None,
                max_nodes: 0,
            }),
            OperationCode::TrailList => Ok(WireRequest::TrailList),
            OperationCode::TrailListCategories => Ok(WireRequest::TrailListCategories),
            _ => Err(FrameParseError::MissingPayload.into()),
        }
    }

    fn work_id_request(&self, op: OperationCode, id: BeId) -> Result<WireRequest, ProtocolError> {
        match op {
            OperationCode::WorkGetEdition => Ok(WireRequest::WorkGetEdition { work_id: id }),
            OperationCode::WorkGrab => Ok(WireRequest::WorkGrab { work_id: id }),
            OperationCode::WorkRelease => Ok(WireRequest::WorkRelease { work_id: id }),
            OperationCode::WorkIsGrabbed => Ok(WireRequest::WorkIsGrabbed { work_id: id }),
            OperationCode::WorkGrabber => Ok(WireRequest::WorkGrabber { work_id: id }),
            OperationCode::WorkRequestGrab => Ok(WireRequest::WorkRequestGrab { work_id: id }),
            OperationCode::WorkCancelGrabRequest => {
                Ok(WireRequest::WorkCancelGrabRequest { work_id: id })
            }
            OperationCode::WorkGrabWaiters => Ok(WireRequest::WorkGrabWaiters { work_id: id }),
            OperationCode::WorkCanRead => Ok(WireRequest::WorkCanRead { work_id: id }),
            OperationCode::WorkCanRevise => Ok(WireRequest::WorkCanRevise { work_id: id }),
            OperationCode::WorkReadClub => Ok(WireRequest::WorkReadClub { work_id: id }),
            OperationCode::WorkEditClub => Ok(WireRequest::WorkEditClub { work_id: id }),
            OperationCode::WorkHistoryClub => Ok(WireRequest::WorkHistoryClub { work_id: id }),
            OperationCode::WorkRevisionCount => Ok(WireRequest::WorkRevisionCount { work_id: id }),
            OperationCode::WorkSponsors => Ok(WireRequest::WorkSponsors { work_id: id }),
            OperationCode::WorkOwner => Ok(WireRequest::WorkOwner { work_id: id }),
            OperationCode::WorkPublish => Ok(WireRequest::WorkPublish { work_id: id }),
            OperationCode::WorkUnpublish => Ok(WireRequest::WorkUnpublish { work_id: id }),
            OperationCode::WorkIrrevocablyUnpublish => {
                Ok(WireRequest::WorkIrrevocablyUnpublish { work_id: id })
            }
            OperationCode::WorkArchive => Ok(WireRequest::WorkArchive { work_id: id }),
            OperationCode::WorkUnarchive => Ok(WireRequest::WorkUnarchive { work_id: id }),
            OperationCode::WorkIsPublished => Ok(WireRequest::WorkIsPublished { work_id: id }),
            OperationCode::WorkGhost => Ok(WireRequest::WorkGhost { work_id: id }),
            OperationCode::CrdtSyncOpen => Ok(WireRequest::CrdtSyncOpen { work_id: id }),
            OperationCode::CrdtSyncClose => Ok(WireRequest::CrdtSyncClose { work_id: id }),
            OperationCode::CrdtSyncFullState => Ok(WireRequest::CrdtSyncFullState { work_id: id }),
            OperationCode::CrdtSyncMaterialize => {
                Ok(WireRequest::CrdtSyncMaterialize { work_id: id })
            }
            OperationCode::CrdtSyncSubscriberCount => {
                Ok(WireRequest::CrdtSyncSubscriberCount { work_id: id })
            }
            OperationCode::CrdtSyncText => Ok(WireRequest::CrdtSyncText { work_id: id }),
            OperationCode::CrdtAwarenessGet => Ok(WireRequest::CrdtAwarenessGet { work_id: id }),
            OperationCode::AttestationReport => Ok(WireRequest::AttestationReport { work_id: id }),
            OperationCode::WorkSummary => Ok(WireRequest::WorkSummary { work_id: id }),
            OperationCode::WorkVersionTimeline => {
                Ok(WireRequest::WorkVersionTimeline { work_id: id })
            }
            _ => Err(FrameParseError::MissingPayload.into()),
        }
    }

    fn club_id_request(&self, op: OperationCode, id: BeId) -> Result<WireRequest, ProtocolError> {
        match op {
            OperationCode::ClubGet => Ok(WireRequest::ClubGet { club_id: id }),
            OperationCode::ClubNameById => Ok(WireRequest::ClubNameById { club_id: id }),
            OperationCode::ClubClearCredential => {
                Ok(WireRequest::ClubClearCredential { club_id: id })
            }
            OperationCode::ClubMembers => Ok(WireRequest::ClubMembers { club_id: id }),
            _ => Err(FrameParseError::MissingPayload.into()),
        }
    }
}

#[derive(Debug, Clone)]
pub struct JsonCodec;

impl WireCodec for JsonCodec {
    fn decode_request(&self, data: &[u8]) -> Result<IncomingMessage, ProtocolError> {
        let frame: WireFrame = serde_json::from_slice(data)
            .map_err(|e| ProtocolError::Serialization(e.to_string()))?;

        if frame.v != PROTOCOL_VERSION {
            return Err(FrameParseError::UnsupportedVersion(frame.v).into());
        }

        let request_id = frame.id;

        match frame.msg_type.as_str() {
            "heartbeat" => Ok(IncomingMessage::Heartbeat),
            "request" => {
                let op_str = frame.op.as_deref().ok_or(FrameParseError::MissingPayload)?;
                let op = serde_json::from_value(serde_json::Value::String(op_str.to_string()))
                    .map_err(|e| FrameParseError::PayloadDecode(e.to_string()))?;
                let wire_req = self.build_wire_request(op, frame.payload)?;
                Ok(IncomingMessage::Request(ParsedRequest {
                    request_id,
                    inner: wire_req,
                }))
            }
            "subscribe" => {
                let payload = frame.payload.ok_or(FrameParseError::MissingPayload)?;
                let sub: SubscribeRequest = serde_json::from_value(payload)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(IncomingMessage::Subscribe(ParsedSubscribe {
                    request_id,
                    subscribe: sub,
                }))
            }
            "unsubscribe" => Ok(IncomingMessage::Unsubscribe(ParsedUnsubscribe {
                request_id,
            })),
            _ => Err(FrameParseError::InvalidMessageType(0).into()),
        }
    }

    fn encode_response(
        &self,
        request_id: u16,
        value: &ResponseValue,
    ) -> Result<Vec<u8>, ProtocolError> {
        if let ResponseValue::BlobData(data) = value {
            let b64 = crate::edition::base64_encode(&data);
            let frame = WireFrame {
                v: PROTOCOL_VERSION,
                msg_type: "response".to_string(),
                id: request_id,
                op: None,
                payload: None,
                value: Some(ResponseValue::String(b64)),
                code: None,
                message: None,
                event: None,
            };
            return serde_json::to_vec(&frame)
                .map_err(|e| ProtocolError::Serialization(e.to_string()));
        }
        let frame = WireFrame {
            v: PROTOCOL_VERSION,
            msg_type: "response".to_string(),
            id: request_id,
            op: None,
            payload: None,
            value: Some(value.clone()),
            code: None,
            message: None,
            event: None,
        };
        serde_json::to_vec(&frame).map_err(|e| ProtocolError::Serialization(e.to_string()))
    }

    fn encode_error(
        &self,
        request_id: u16,
        code: ErrorCode,
        message: &str,
    ) -> Result<Vec<u8>, ProtocolError> {
        let frame = WireFrame {
            v: PROTOCOL_VERSION,
            msg_type: "error".to_string(),
            id: request_id,
            op: None,
            payload: None,
            value: None,
            code: Some(code),
            message: Some(message.to_string()),
            event: None,
        };
        serde_json::to_vec(&frame).map_err(|e| ProtocolError::Serialization(e.to_string()))
    }

    fn encode_event(&self, event: &WireEvent) -> Result<Vec<u8>, ProtocolError> {
        let frame = WireFrame {
            v: PROTOCOL_VERSION,
            msg_type: "event".to_string(),
            id: event.subscription_id,
            op: None,
            payload: None,
            value: None,
            code: None,
            message: None,
            event: Some(event.event.clone()),
        };
        serde_json::to_vec(&frame).map_err(|e| ProtocolError::Serialization(e.to_string()))
    }

    fn encode_heartbeat(&self) -> Result<Vec<u8>, ProtocolError> {
        let frame = WireFrame {
            v: PROTOCOL_VERSION,
            msg_type: "heartbeat".to_string(),
            id: 0,
            op: None,
            payload: None,
            value: None,
            code: None,
            message: None,
            event: None,
        };
        serde_json::to_vec(&frame).map_err(|e| ProtocolError::Serialization(e.to_string()))
    }

    fn is_text(&self) -> bool {
        true
    }
}

impl JsonCodec {
    fn build_wire_request(
        &self,
        op: OperationCode,
        payload: Option<serde_json::Value>,
    ) -> Result<WireRequest, ProtocolError> {
        match op {
            OperationCode::WorkList | OperationCode::ClubNames => {
                #[derive(Deserialize)]
                struct Pagination {
                    #[cfg_attr(feature = "serde", serde(default))]
                    offset: Option<u32>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    limit: Option<u32>,
                }
                let (offset, limit) = match payload {
                    Some(p) => {
                        let args: Pagination = serde_json::from_value(p)
                            .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                        (args.offset, args.limit)
                    }
                    None => (None, None),
                };
                return match op {
                    OperationCode::WorkList => Ok(WireRequest::WorkList { offset, limit }),
                    OperationCode::ClubNames => Ok(WireRequest::ClubNames { offset, limit }),
                    _ => unreachable!(),
                };
            }
            _ => {}
        }

        let no_payload_ops = [
            OperationCode::SessionConnect,
            OperationCode::SessionDisconnect,
            OperationCode::SessionLoginPublic,
            OperationCode::SessionTicketIssue,
            OperationCode::AdminActiveSessions,
            OperationCode::AdminShutdown,
            OperationCode::AdminGrants,
            OperationCode::AdminServerInfo,
            OperationCode::ServerStats,
            OperationCode::BlobStats,
            OperationCode::LabelCreate,
            OperationCode::AdminRecorderList,
            OperationCode::AdminServerHealth,
            OperationCode::CryptoGetPublicKey,
            OperationCode::CryptoKeyRotation,
            OperationCode::CryptoKeyHistory,
            OperationCode::FederationInfo,
            OperationCode::FederationPeers,
            OperationCode::MembershipSync,
            OperationCode::MembershipLeave,
            OperationCode::MembershipList,
            OperationCode::GovernanceSeal,
            OperationCode::GovernanceLog,
            OperationCode::GovernanceStatus,
            OperationCode::ClubWhoAmI,
            OperationCode::AttributionLogStatus,
            OperationCode::HistoricalAuthorList,
            OperationCode::SourcePatternList,
            OperationCode::WorkGraph,
            OperationCode::TrailList,
            OperationCode::TrailListCategories,
            OperationCode::WorkListArchived,
            OperationCode::ConnectionPinsGet,
            #[cfg(feature = "serde")]
            OperationCode::ServerDirectoryList,
            #[cfg(feature = "serde")]
            OperationCode::AdminAuditTail,
            #[cfg(feature = "serde")]
            OperationCode::AdminClubsList,
            #[cfg(feature = "serde")]
            OperationCode::AdminNetworkStatus,
        ];
        if no_payload_ops.contains(&op) {
            return match op {
                OperationCode::SessionConnect => Ok(WireRequest::SessionConnect),
                OperationCode::SessionDisconnect => Ok(WireRequest::SessionDisconnect),
                OperationCode::SessionLoginPublic => Ok(WireRequest::SessionLoginPublic),
                OperationCode::SessionTicketIssue => Ok(WireRequest::SessionTicketIssue),
                OperationCode::AdminIsAcceptingConnections => {
                    Ok(WireRequest::AdminIsAcceptingConnections)
                }
                OperationCode::AdminActiveSessions => Ok(WireRequest::AdminActiveSessions),
                OperationCode::AdminShutdown => Ok(WireRequest::AdminShutdown),
                OperationCode::AdminGrants => Ok(WireRequest::AdminGrants),
                OperationCode::AdminServerInfo => Ok(WireRequest::AdminServerInfo),
                OperationCode::ServerStats => Ok(WireRequest::ServerStats),
                OperationCode::BlobStats => Ok(WireRequest::BlobStats),
                OperationCode::LabelCreate => Ok(WireRequest::LabelCreate),
                OperationCode::AdminRecorderList => Ok(WireRequest::AdminRecorderList),
                OperationCode::AdminServerHealth => Ok(WireRequest::AdminServerHealth),
                OperationCode::CryptoGetPublicKey => Ok(WireRequest::CryptoGetPublicKey),
                OperationCode::CryptoKeyRotation => Ok(WireRequest::CryptoKeyRotation),
                OperationCode::CryptoKeyHistory => Ok(WireRequest::CryptoKeyHistory),
                OperationCode::FederationInfo => Ok(WireRequest::FederationInfo),
                OperationCode::FederationPeers => Ok(WireRequest::FederationPeers),
                OperationCode::MembershipSync => Ok(WireRequest::MembershipSync),
                OperationCode::MembershipLeave => Ok(WireRequest::MembershipLeave),
                OperationCode::MembershipList => Ok(WireRequest::MembershipList),
                OperationCode::GovernanceSeal => Ok(WireRequest::GovernanceSeal),
                OperationCode::GovernanceLog => Ok(WireRequest::GovernanceLog),
                OperationCode::GovernanceStatus => Ok(WireRequest::GovernanceStatus),
                OperationCode::ClubWhoAmI => Ok(WireRequest::ClubWhoAmI),
                OperationCode::AttributionLogStatus => Ok(WireRequest::AttributionLogStatus),
                OperationCode::HistoricalAuthorList => Ok(WireRequest::HistoricalAuthorList),
                OperationCode::SourcePatternList => Ok(WireRequest::SourcePatternList),
                OperationCode::WorkGraph => Ok(WireRequest::WorkGraph {
                    center_work_id: None,
                    max_nodes: 0,
                }),
                OperationCode::TrailList => Ok(WireRequest::TrailList),
                OperationCode::TrailListCategories => Ok(WireRequest::TrailListCategories),
                OperationCode::WorkListArchived => Ok(WireRequest::WorkListArchived),
                OperationCode::ConnectionPinsGet => Ok(WireRequest::ConnectionPinsGet),
                #[cfg(feature = "serde")]
                OperationCode::ServerDirectoryList => Ok(WireRequest::ServerDirectoryList),
                #[cfg(feature = "serde")]
                OperationCode::AdminAuditTail => Ok(WireRequest::AdminAuditTail),
                #[cfg(feature = "serde")]
                OperationCode::AdminClubsList => Ok(WireRequest::AdminClubsList),
                #[cfg(feature = "serde")]
                OperationCode::AdminNetworkStatus => Ok(WireRequest::AdminNetworkStatus),
                // SECURITY: list/match drift must degrade to a protocol
                // error, never panic. A reachable unreachable!() here is
                // a remote DoS (found 2026-08-25: admin_clubs_list hung
                // the WS handler).
                _ => {
                    return Err(FrameParseError::PayloadDecode(format!(
                        "op {:?} listed as payload-less but has no decode arm",
                        op
                    ))
                    .into())
                }
            };
        }

        let p = payload.ok_or(FrameParseError::MissingPayload)?;

        match op {
            OperationCode::SessionLogin => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::SessionLogin {
                    club_id: args.club_id,
                })
            }
            OperationCode::SessionLoginByName => {
                #[derive(Deserialize)]
                struct Args {
                    club_name: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::SessionLoginByName {
                    club_name: args.club_name,
                })
            }
            OperationCode::SessionAuthenticate => {
                let args: serde_json::Value = p;
                #[derive(Deserialize)]
                struct Args {
                    credential: LockCredential,
                }
                let a: Args = serde_json::from_value(args)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::SessionAuthenticate {
                    credential: a.credential,
                })
            }
            OperationCode::SessionTicketRedeem => {
                #[derive(Deserialize)]
                struct Args {
                    ticket: Vec<u8>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::SessionTicketRedeem {
                    ticket: args.ticket,
                })
            }
            OperationCode::ServerGetById => {
                #[derive(Deserialize)]
                struct Args {
                    id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ServerGetById { id: args.id })
            }
            OperationCode::ServerGetByBeId => {
                #[derive(Deserialize)]
                struct Args {
                    be_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ServerGetByBeId { be_id: args.be_id })
            }
            OperationCode::ClubCreate => {
                #[derive(Deserialize)]
                struct Args {
                    description: EditionPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubCreate {
                    description: args.description,
                })
            }
            OperationCode::ClubCreateNamed => {
                #[derive(Deserialize)]
                struct Args {
                    name: String,
                    description: EditionPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubCreateNamed {
                    name: args.name,
                    description: args.description,
                })
            }
            OperationCode::ClubGet => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubGet {
                    club_id: args.club_id,
                })
            }
            OperationCode::ClubByName | OperationCode::ClubIdByName => {
                #[derive(Deserialize)]
                struct Args {
                    name: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubIdByName { name: args.name })
            }
            OperationCode::ClubNameById => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubNameById {
                    club_id: args.club_id,
                })
            }
            OperationCode::WorkCreate => {
                #[derive(Deserialize)]
                struct Args {
                    edition: EditionPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkCreate {
                    edition: args.edition,
                })
            }
            OperationCode::WorkGetEdition => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkGetEdition {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkRevise => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    edition: EditionPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRevise {
                    work_id: args.work_id,
                    edition: args.edition,
                })
            }
            OperationCode::WorkReviseDelta => {
                use super::protocol::TextDeltaOp;
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    base_revision: u64,
                    ops: Vec<TextDeltaOp>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkReviseDelta {
                    work_id: args.work_id,
                    base_revision: args.base_revision,
                    ops: args.ops,
                })
            }
            OperationCode::WorkGrab => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkGrab {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkRelease => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRelease {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkSaveAndRelease => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    edition: EditionPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSaveAndRelease {
                    work_id: args.work_id,
                    edition: args.edition,
                })
            }
            OperationCode::WorkForceRelease => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkForceRelease {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkIsGrabbed => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkIsGrabbed {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkGrabber => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkGrabber {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkRequestGrab => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRequestGrab {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkCancelGrabRequest => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkCancelGrabRequest {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkGrabWaiters => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkGrabWaiters {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkCanRead => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkCanRead {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkCanRevise => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkCanRevise {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkSetReadClub => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    club_id: Option<BeId>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSetReadClub {
                    work_id: args.work_id,
                    club_id: args.club_id,
                })
            }
            OperationCode::WorkSetEditClub => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    club_id: Option<BeId>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSetEditClub {
                    work_id: args.work_id,
                    club_id: args.club_id,
                })
            }
            OperationCode::WorkSetHistoryClub => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    club_id: Option<BeId>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSetHistoryClub {
                    work_id: args.work_id,
                    club_id: args.club_id,
                })
            }
            OperationCode::WorkTransclusionChain => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    char_start: usize,
                    char_end: usize,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkTransclusionChain {
                    work_id: args.work_id,
                    char_start: args.char_start,
                    char_end: args.char_end,
                })
            }
            OperationCode::WorkPublish => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkPublish {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkDiffNarration => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkDiffNarration {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkWritingFeedback => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkWritingFeedback {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkSuggestTitle => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSuggestTitle {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkSetTitle => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    title: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSetTitle {
                    work_id: args.work_id,
                    title: args.title,
                })
            }
            OperationCode::LatticeShadowEnroll => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LatticeShadowEnroll {
                    work_id: args.work_id,
                })
            }
            OperationCode::LatticeShadowStatus => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LatticeShadowStatus {
                    work_id: args.work_id,
                })
            }
            OperationCode::LatticeShadowClear => Ok(WireRequest::LatticeShadowClear {}),
            OperationCode::LatticePrimaryPromote => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LatticePrimaryPromote {
                    work_id: args.work_id,
                })
            }
            OperationCode::LatticePrimaryDemote => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LatticePrimaryDemote {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkAutoTag => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkAutoTag {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkBacklinks => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkBacklinks {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkUnpublish => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkUnpublish {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkIrrevocablyUnpublish => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkIrrevocablyUnpublish {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkArchive => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkArchive {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkUnarchive => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkUnarchive {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkIsPublished => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkIsPublished {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkMerge => {
                #[derive(Deserialize)]
                struct Args {
                    base_work_id: BeId,
                    a_work_id: BeId,
                    b_work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkMerge {
                    base_work_id: args.base_work_id,
                    a_work_id: args.a_work_id,
                    b_work_id: args.b_work_id,
                })
            }
            OperationCode::WorkGhost => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkGhost {
                    work_id: args.work_id,
                })
            }
            OperationCode::ClubSetDefaultReadClub => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                    default_read_club: Option<BeId>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubSetDefaultReadClub {
                    club_id: args.club_id,
                    default_read_club: args.default_read_club,
                })
            }
            OperationCode::ClubSetDefaultEditClub => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                    default_edit_club: Option<BeId>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubSetDefaultEditClub {
                    club_id: args.club_id,
                    default_edit_club: args.default_edit_club,
                })
            }
            OperationCode::ClubSetPassword => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                    password: Vec<u8>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubSetPassword {
                    club_id: args.club_id,
                    password: args.password,
                })
            }
            OperationCode::ClubClearCredential => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubClearCredential {
                    club_id: args.club_id,
                })
            }
            OperationCode::ClubCreatePersonal => {
                #[derive(Deserialize)]
                struct Args {
                    display_name: String,
                    password: Option<Vec<u8>>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubCreatePersonal {
                    display_name: args.display_name,
                    password: args.password,
                })
            }
            OperationCode::ClubAddMember => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                    member_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubAddMember {
                    club_id: args.club_id,
                    member_id: args.member_id,
                })
            }
            OperationCode::ClubRemoveMember => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                    member_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubRemoveMember {
                    club_id: args.club_id,
                    member_id: args.member_id,
                })
            }
            OperationCode::ClubMembers => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubMembers {
                    club_id: args.club_id,
                })
            }
            OperationCode::WorkReadClub => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkReadClub {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkEditClub => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkEditClub {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkRevisionCount => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRevisionCount {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkFetchRevision => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    number: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkFetchRevision {
                    work_id: args.work_id,
                    number: args.number,
                })
            }
            OperationCode::WorkFetchRevisionRange => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    from: u64,
                    to: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkFetchRevisionRange {
                    work_id: args.work_id,
                    from: args.from,
                    to: args.to,
                })
            }
            OperationCode::WorkSponsor => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    club_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSponsor {
                    work_id: args.work_id,
                    club_id: args.club_id,
                })
            }
            OperationCode::WorkUnsponsor => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    club_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkUnsponsor {
                    work_id: args.work_id,
                    club_id: args.club_id,
                })
            }
            OperationCode::WorkSponsors => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSponsors {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkOwner => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkOwner {
                    work_id: args.work_id,
                })
            }
            OperationCode::EditionStore => {
                #[derive(Deserialize)]
                struct Args {
                    edition: EditionPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionStore {
                    edition: args.edition,
                })
            }
            OperationCode::EditionGet => {
                #[derive(Deserialize)]
                struct Args {
                    be_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionGet { be_id: args.be_id })
            }
            OperationCode::AdminAcceptConnections => {
                #[derive(Deserialize)]
                struct Args {
                    accept: bool,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminAcceptConnections {
                    accept: args.accept,
                })
            }
            OperationCode::AdminIsAcceptingConnections => {
                Ok(WireRequest::AdminIsAcceptingConnections)
            }
            OperationCode::AdminActiveSessions => Ok(WireRequest::AdminActiveSessions),
            OperationCode::AdminShutdown => Ok(WireRequest::AdminShutdown),
            OperationCode::AdminGrant => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                    region_start: i64,
                    region_end: i64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminGrant {
                    club_id: args.club_id,
                    region_start: args.region_start,
                    region_end: args.region_end,
                })
            }
            OperationCode::AdminRevokeGrant => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminRevokeGrant {
                    club_id: args.club_id,
                })
            }
            OperationCode::AdminGrants => Ok(WireRequest::AdminGrants),
            OperationCode::AdminServerInfo => Ok(WireRequest::AdminServerInfo),
            OperationCode::ServerStats => Ok(WireRequest::ServerStats),
            OperationCode::WorkList => {
                #[derive(Deserialize)]
                struct Args {
                    #[cfg_attr(feature = "serde", serde(default))]
                    offset: Option<u32>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    limit: Option<u32>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkList {
                    offset: args.offset,
                    limit: args.limit,
                })
            }
            OperationCode::ClubNames => {
                #[derive(Deserialize)]
                struct Args {
                    #[cfg_attr(feature = "serde", serde(default))]
                    offset: Option<u32>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    limit: Option<u32>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubNames {
                    offset: args.offset,
                    limit: args.limit,
                })
            }
            OperationCode::WorkListByOwner => {
                #[derive(Deserialize)]
                struct Args {
                    owner: BeId,
                    #[cfg_attr(feature = "serde", serde(default))]
                    offset: Option<u32>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    limit: Option<u32>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkListByOwner {
                    owner: args.owner,
                    offset: args.offset,
                    limit: args.limit,
                })
            }
            OperationCode::LinkCreate => {
                #[derive(Deserialize)]
                struct Args {
                    origin: BeId,
                    destination: BeId,
                    origin_ref: Option<HyperRefPayload>,
                    destination_ref: Option<HyperRefPayload>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    link_types: Vec<u64>,
                    #[serde(default)]
                    home_document: Option<BeId>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkCreate {
                    origin: args.origin,
                    destination: args.destination,
                    origin_ref: args.origin_ref,
                    destination_ref: args.destination_ref,
                    link_types: args.link_types,
                    home_document: args.home_document,
                })
            }
            OperationCode::LinkGet => {
                #[derive(Deserialize)]
                struct Args {
                    link_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkGet {
                    link_id: args.link_id,
                })
            }
            OperationCode::LinkUpdate => {
                #[derive(Deserialize)]
                struct Args {
                    link_id: BeId,
                    origin_ref: Option<HyperRefPayload>,
                    destination_ref: Option<HyperRefPayload>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkUpdate {
                    link_id: args.link_id,
                    origin_ref: args.origin_ref,
                    destination_ref: args.destination_ref,
                })
            }
            OperationCode::LinkDelete => {
                #[derive(Deserialize)]
                struct Args {
                    link_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkDelete {
                    link_id: args.link_id,
                })
            }
            OperationCode::LinkListForWork => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    #[cfg_attr(feature = "serde", serde(default))]
                    offset: Option<u32>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    limit: Option<u32>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkListForWork {
                    work_id: args.work_id,
                    offset: args.offset,
                    limit: args.limit,
                })
            }
            OperationCode::LinkAddEnd => {
                #[derive(Deserialize)]
                struct Args {
                    link_id: BeId,
                    end_name: String,
                    end_ref: super::protocol::HyperRefPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkAddEnd {
                    link_id: args.link_id,
                    end_name: args.end_name,
                    end_ref: args.end_ref,
                })
            }
            OperationCode::LinkRemoveEnd => {
                #[derive(Deserialize)]
                struct Args {
                    link_id: BeId,
                    end_name: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkRemoveEnd {
                    link_id: args.link_id,
                    end_name: args.end_name,
                })
            }
            OperationCode::LinkEndAddAttachment => {
                #[derive(Deserialize)]
                struct Args {
                    link_id: BeId,
                    end_name: String,
                    attachment: super::protocol::HyperRefPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkEndAddAttachment {
                    link_id: args.link_id,
                    end_name: args.end_name,
                    attachment: args.attachment,
                })
            }
            OperationCode::LinkEndRemoveAttachment => {
                #[derive(Deserialize)]
                struct Args {
                    link_id: BeId,
                    end_name: String,
                    attachment: super::protocol::HyperRefPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkEndRemoveAttachment {
                    link_id: args.link_id,
                    end_name: args.end_name,
                    attachment: args.attachment,
                })
            }
            OperationCode::LinkSetTypes => {
                #[derive(Deserialize)]
                struct Args {
                    link_id: BeId,
                    #[cfg_attr(feature = "serde", serde(default))]
                    link_types: Vec<u64>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkSetTypes {
                    link_id: args.link_id,
                    link_types: args.link_types,
                })
            }
            OperationCode::LinkTypeRegister => {
                #[derive(Deserialize)]
                struct Args {
                    type_id: u64,
                    name: String,
                    #[serde(default)]
                    definition_work: Option<BeId>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkTypeRegister {
                    type_id: args.type_id,
                    name: args.name,
                    definition_work: args.definition_work,
                })
            }
            OperationCode::LinkTypeList => Ok(WireRequest::LinkTypeList),
            OperationCode::LinkQuery => {
                #[derive(Deserialize, Default)]
                struct SpecArgs {
                    #[serde(default)]
                    work_ids: Vec<BeId>,
                    #[serde(default)]
                    author: Option<BeId>,
                }
                #[derive(Deserialize)]
                struct Args {
                    #[serde(default)]
                    from_spec: SpecArgs,
                    #[serde(default)]
                    to_spec: SpecArgs,
                    #[serde(default)]
                    type_ids: Vec<u64>,
                    #[serde(default)]
                    home_spec: SpecArgs,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                let to_spec = |s: SpecArgs| super::protocol::LinkEndpointSpecPayload {
                    work_ids: s.work_ids,
                    author: s.author,
                };
                Ok(WireRequest::LinkQuery {
                    from_spec: to_spec(args.from_spec),
                    to_spec: to_spec(args.to_spec),
                    type_ids: args.type_ids,
                    home_spec: to_spec(args.home_spec),
                })
            }
            OperationCode::FindTranscluders => {
                #[derive(Deserialize)]
                struct Args {
                    content_be_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FindTranscluders {
                    content_be_id: args.content_be_id,
                })
            }
            OperationCode::FindWorksForContent => {
                #[derive(Deserialize)]
                struct Args {
                    content_be_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FindWorksForContent {
                    content_be_id: args.content_be_id,
                })
            }
            OperationCode::FindTextTranscluders => {
                #[derive(Deserialize)]
                struct Args {
                    text: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FindTextTranscluders { text: args.text })
            }
            OperationCode::FindSharedRegions => {
                #[derive(Deserialize)]
                struct Args {
                    work_a: BeId,
                    work_b: BeId,
                    filter_text: Option<String>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FindSharedRegions {
                    work_a: args.work_a,
                    work_b: args.work_b,
                    filter_text: args.filter_text,
                })
            }
            OperationCode::SharedCrumRegions => {
                #[derive(Deserialize)]
                struct Args {
                    work_ids: Vec<BeId>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::SharedCrumRegions {
                    work_ids: args.work_ids,
                })
            }
            OperationCode::SpanKeyResolve => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    key: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::SpanKeyResolve {
                    work_id: args.work_id,
                    key: args.key,
                })
            }
            OperationCode::CompoundFollowBack => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    local_char: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CompoundFollowBack {
                    work_id: args.work_id,
                    local_char: args.local_char,
                })
            }
            OperationCode::WorkDiffRegions => {
                #[derive(Deserialize)]
                struct Args {
                    work_a: BeId,
                    work_b: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkDiffRegions {
                    work_a: args.work_a,
                    work_b: args.work_b,
                })
            }
            OperationCode::BlobUpload => {
                #[derive(Deserialize)]
                struct Args {
                    data: String,
                    mime_type: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BlobUpload {
                    data: args.data,
                    mime_type: args.mime_type,
                })
            }
            OperationCode::BlobGet => {
                #[derive(Deserialize)]
                struct Args {
                    content_hash: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BlobGet {
                    content_hash: args.content_hash,
                })
            }
            OperationCode::BlobGetPreview => {
                #[derive(Deserialize)]
                struct Args {
                    content_hash: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BlobGetPreview {
                    content_hash: args.content_hash,
                })
            }
            OperationCode::BlobExists => {
                #[derive(Deserialize)]
                struct Args {
                    content_hash: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BlobExists {
                    content_hash: args.content_hash,
                })
            }
            OperationCode::BlobInfo => {
                #[derive(Deserialize)]
                struct Args {
                    content_hash: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BlobInfo {
                    content_hash: args.content_hash,
                })
            }
            OperationCode::OverlayApply => {
                #[derive(Deserialize)]
                struct Args {
                    base_hash: u64,
                    ops: Vec<crate::edition::ImageOp>,
                    mime_type: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::OverlayApply {
                    base_hash: args.base_hash,
                    ops: args.ops,
                    mime_type: args.mime_type,
                })
            }
            OperationCode::OverlayGet => {
                #[derive(Deserialize)]
                struct Args {
                    overlay_hash: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::OverlayGet {
                    overlay_hash: args.overlay_hash,
                })
            }
            OperationCode::LabelCreate => Ok(WireRequest::LabelCreate),
            OperationCode::LabelGetPositions => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    label_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LabelGetPositions {
                    work_id: args.work_id,
                    label_id: args.label_id,
                })
            }
            OperationCode::EditionRelabel => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    label_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionRelabel {
                    work_id: args.work_id,
                    label_id: args.label_id,
                })
            }
            OperationCode::EditionRebind => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    position: i64,
                    new_edition: EditionPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionRebind {
                    work_id: args.work_id,
                    position: args.position,
                    new_edition: args.new_edition,
                })
            }
            OperationCode::CanMakeIdentical => {
                #[derive(Deserialize)]
                struct Args {
                    source_work_id: BeId,
                    target_work_id: BeId,
                    position: Option<i64>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CanMakeIdentical {
                    source_work_id: args.source_work_id,
                    target_work_id: args.target_work_id,
                    position: args.position,
                })
            }
            OperationCode::MakeRangeIdentical => {
                #[derive(Deserialize)]
                struct Args {
                    source_work_id: BeId,
                    target_work_id: BeId,
                    region: Option<XnRegion>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::MakeRangeIdentical {
                    source_work_id: args.source_work_id,
                    target_work_id: args.target_work_id,
                    region: args.region,
                })
            }
            OperationCode::IdentityUnify => {
                #[derive(Deserialize)]
                struct Args {
                    source_id: u64,
                    target_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::IdentityUnify {
                    source_id: args.source_id,
                    target_id: args.target_id,
                })
            }
            OperationCode::IdentityResolve => {
                #[derive(Deserialize)]
                struct Args {
                    id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::IdentityResolve { id: args.id })
            }
            OperationCode::EditionRetrieve => {
                use super::protocol::RetrieveFlagsPayload;
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    region: Option<XnRegion>,
                    flags: Option<RetrieveFlagsPayload>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionRetrieve {
                    work_id: args.work_id,
                    region: args.region,
                    flags: args.flags,
                })
            }
            OperationCode::EditionCost => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    method: Option<String>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionCost {
                    work_id: args.work_id,
                    method: args.method,
                })
            }
            OperationCode::ElementInsert => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    position: i64,
                    element: super::protocol::RangeElementPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ElementInsert {
                    work_id: args.work_id,
                    position: args.position,
                    element: args.element,
                })
            }
            OperationCode::CrossServerSpanRefresh => {
                #[derive(Deserialize)]
                struct Args {
                    source_work: BeId,
                    #[serde(default)]
                    update: bool,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrossServerSpanRefresh {
                    source_work: args.source_work,
                    update: args.update,
                })
            }
            OperationCode::TransclusionPlaceCrossServer => {
                #[derive(Deserialize)]
                struct Args {
                    dest_work: BeId,
                    #[serde(default)]
                    cursor: usize,
                    tumbler: String,
                    span_start: usize,
                    span_end: usize,
                    #[serde(default)]
                    title_hint: Option<String>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TransclusionPlaceCrossServer {
                    dest_work: args.dest_work,
                    cursor: args.cursor,
                    tumbler: args.tumbler,
                    span_start: args.span_start,
                    span_end: args.span_end,
                    title_hint: args.title_hint,
                })
            }
            OperationCode::ElementUpdate => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    char_position: usize,
                    element: super::protocol::RangeElementPayload,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ElementUpdate {
                    work_id: args.work_id,
                    char_position: args.char_position,
                    element: args.element,
                })
            }
            OperationCode::ResolveInlineTransclusions => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ResolveInlineTransclusions {
                    work_id: args.work_id,
                })
            }
            OperationCode::MigrateCompoundToInline => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::MigrateCompoundToInline {
                    work_id: args.work_id,
                })
            }
            OperationCode::ElementRemoveTransclusion => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    source_work_id: BeId,
                    char_start: usize,
                    char_end: usize,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ElementRemoveTransclusion {
                    work_id: args.work_id,
                    source_work_id: args.source_work_id,
                    char_start: args.char_start,
                    char_end: args.char_end,
                })
            }
            OperationCode::AttributionQueryResolved => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AttributionQueryResolved {
                    work_id: args.work_id,
                })
            }
            OperationCode::RenderTransclusions => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::RenderTransclusions {
                    work_id: args.work_id,
                })
            }
            OperationCode::AnnotationCreate => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    annotation_id: u64,
                    kind: String,
                    payload: String,
                    #[cfg_attr(feature = "serde", serde(default))]
                    char_start: usize,
                    #[cfg_attr(feature = "serde", serde(default))]
                    char_end: usize,
                    #[cfg_attr(feature = "serde", serde(default))]
                    is_private: bool,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AnnotationCreate {
                    work_id: args.work_id,
                    annotation_id: args.annotation_id,
                    kind: args.kind,
                    payload: args.payload,
                    char_start: args.char_start,
                    char_end: args.char_end,
                    is_private: args.is_private,
                })
            }
            OperationCode::AnnotationDelete => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    annotation_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AnnotationDelete {
                    work_id: args.work_id,
                    annotation_id: args.annotation_id,
                })
            }
            OperationCode::AnnotationAttachNode => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    annotation_id: u64,
                    node_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AnnotationAttachNode {
                    work_id: args.work_id,
                    annotation_id: args.annotation_id,
                    node_id: args.node_id,
                })
            }
            OperationCode::AnnotationAttachSpan => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    annotation_id: u64,
                    span_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AnnotationAttachSpan {
                    work_id: args.work_id,
                    annotation_id: args.annotation_id,
                    span_id: args.span_id,
                })
            }
            OperationCode::AnnotationGet => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    annotation_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AnnotationGet {
                    work_id: args.work_id,
                    annotation_id: args.annotation_id,
                })
            }
            OperationCode::AnnotationList => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AnnotationList {
                    work_id: args.work_id,
                })
            }
            OperationCode::ContentSharedRegion => {
                #[derive(Deserialize)]
                struct Args {
                    work_a: BeId,
                    work_b: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ContentSharedRegion {
                    work_a: args.work_a,
                    work_b: args.work_b,
                })
            }
            OperationCode::ContentMapSharedTo => {
                #[derive(Deserialize)]
                struct Args {
                    work_a: BeId,
                    work_b: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ContentMapSharedTo {
                    work_a: args.work_a,
                    work_b: args.work_b,
                })
            }
            OperationCode::ContentMapSharedOnto => {
                #[derive(Deserialize)]
                struct Args {
                    work_a: BeId,
                    work_b: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ContentMapSharedOnto {
                    work_a: args.work_a,
                    work_b: args.work_b,
                })
            }
            OperationCode::PositionsOf => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    element: RangeElement,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::PositionsOf {
                    work_id: args.work_id,
                    element: args.element,
                })
            }
            OperationCode::RangeTranscluders => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    region: Option<XnRegion>,
                    direct_only: Option<bool>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::RangeTranscluders {
                    work_id: args.work_id,
                    region: args.region,
                    direct_only: args.direct_only,
                })
            }
            OperationCode::RangeWorks => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    region: Option<XnRegion>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::RangeWorks {
                    work_id: args.work_id,
                    region: args.region,
                })
            }
            OperationCode::OrderedBundles => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    region: Option<XnRegion>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::OrderedBundles {
                    work_id: args.work_id,
                    region: args.region,
                })
            }
            OperationCode::TransclusionDepth => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    position: i64,
                    max_depth: Option<usize>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TransclusionDepth {
                    work_id: args.work_id,
                    position: args.position,
                    max_depth: args.max_depth,
                })
            }
            OperationCode::FindExcerptPositions => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    excerpt: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FindExcerptPositions {
                    work_id: args.work_id,
                    excerpt: args.excerpt,
                })
            }
            OperationCode::VersionIsBefore => {
                #[derive(Deserialize)]
                struct Args {
                    work_a: BeId,
                    work_b: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::VersionIsBefore {
                    work_a: args.work_a,
                    work_b: args.work_b,
                })
            }
            OperationCode::VersionAncestors => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::VersionAncestors {
                    work_id: args.work_id,
                })
            }
            OperationCode::VersionDescendants => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::VersionDescendants {
                    work_id: args.work_id,
                })
            }
            OperationCode::VersionTracePosition => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::VersionTracePosition {
                    work_id: args.work_id,
                })
            }
            OperationCode::ProvenanceAncestry => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ProvenanceAncestry {
                    work_id: args.work_id,
                })
            }
            OperationCode::AdminRecorderCreate => {
                #[derive(Deserialize)]
                struct Args {
                    kind: String,
                    direct_only: Option<bool>,
                    region: Option<XnRegion>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminRecorderCreate {
                    kind: args.kind,
                    direct_only: args.direct_only,
                    region: args.region,
                })
            }
            OperationCode::AdminRecorderRecord => {
                #[derive(Deserialize)]
                struct Args {
                    recorder_id: u64,
                    element: RangeElement,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminRecorderRecord {
                    recorder_id: args.recorder_id,
                    element: args.element,
                })
            }
            OperationCode::AdminRecorderList => Ok(WireRequest::AdminRecorderList),
            OperationCode::AdminRecorderGet => {
                #[derive(Deserialize)]
                struct Args {
                    recorder_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminRecorderGet {
                    recorder_id: args.recorder_id,
                })
            }
            OperationCode::AdminServerHealth => Ok(WireRequest::AdminServerHealth),
            OperationCode::CryptoGetPublicKey => Ok(WireRequest::CryptoGetPublicKey),
            OperationCode::CryptoSignData => {
                #[derive(Deserialize)]
                struct Args {
                    data: Vec<u8>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CryptoSignData { data: args.data })
            }
            OperationCode::CryptoVerifySignature => {
                #[derive(Deserialize)]
                struct Args {
                    data: Vec<u8>,
                    signature: Vec<u8>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CryptoVerifySignature {
                    data: args.data,
                    signature: args.signature,
                })
            }
            OperationCode::CryptoKeyRotation => Ok(WireRequest::CryptoKeyRotation),
            OperationCode::CryptoKeyHistory => Ok(WireRequest::CryptoKeyHistory),
            OperationCode::WorkEndorse => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                    endorsements: Vec<(u64, u64)>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkEndorse {
                    work_id: args.work_id,
                    endorsements: args.endorsements,
                })
            }
            OperationCode::WorkRetract => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                    endorsements: Vec<(u64, u64)>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRetract {
                    work_id: args.work_id,
                    endorsements: args.endorsements,
                })
            }
            OperationCode::WorkEndorsements => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkEndorsements {
                    work_id: args.work_id,
                })
            }
            OperationCode::EditionEndorse => {
                #[derive(Deserialize)]
                struct Args {
                    edition_id: u64,
                    endorsements: Vec<(u64, u64)>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionEndorse {
                    edition_id: args.edition_id,
                    endorsements: args.endorsements,
                })
            }
            OperationCode::EditionRetract => {
                #[derive(Deserialize)]
                struct Args {
                    edition_id: u64,
                    endorsements: Vec<(u64, u64)>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionRetract {
                    edition_id: args.edition_id,
                    endorsements: args.endorsements,
                })
            }
            OperationCode::EditionEndorsements => {
                #[derive(Deserialize)]
                struct Args {
                    edition_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionEndorsements {
                    edition_id: args.edition_id,
                })
            }
            OperationCode::EditionVisibleEndorsements => {
                #[derive(Deserialize)]
                struct Args {
                    edition_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionVisibleEndorsements {
                    edition_id: args.edition_id,
                })
            }
            OperationCode::EditionTotalEndorsements => {
                #[derive(Deserialize)]
                struct Args {
                    edition_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionTotalEndorsements {
                    edition_id: args.edition_id,
                })
            }
            OperationCode::FederationInfo => Ok(WireRequest::FederationInfo),
            OperationCode::FederationPeers => Ok(WireRequest::FederationPeers),
            OperationCode::FederatedTransclusionQuery => {
                #[derive(Deserialize)]
                struct Args {
                    content_fingerprint_hex: String,
                    #[cfg_attr(feature = "serde", serde(default))]
                    direct_only: bool,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FederatedTransclusionQuery {
                    content_fingerprint_hex: args.content_fingerprint_hex,
                    direct_only: args.direct_only,
                })
            }
            OperationCode::FederatedContentFetch => {
                #[derive(Deserialize)]
                struct Args {
                    content_fingerprint_hex: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FederatedContentFetch {
                    content_fingerprint_hex: args.content_fingerprint_hex,
                })
            }
            OperationCode::EndorsementSync => {
                #[derive(Deserialize)]
                struct Args {
                    work_fingerprint: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EndorsementSync {
                    work_fingerprint: args.work_fingerprint,
                })
            }
            OperationCode::EndorsementAdd => {
                #[derive(Deserialize)]
                struct Args {
                    work_fingerprint: String,
                    club_id: u64,
                    token_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EndorsementAdd {
                    work_fingerprint: args.work_fingerprint,
                    club_id: args.club_id,
                    token_id: args.token_id,
                })
            }
            OperationCode::EndorsementRetract => {
                #[derive(Deserialize)]
                struct Args {
                    work_fingerprint: String,
                    club_id: u64,
                    token_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EndorsementRetract {
                    work_fingerprint: args.work_fingerprint,
                    club_id: args.club_id,
                    token_id: args.token_id,
                })
            }
            OperationCode::EndorsementQuery => {
                #[derive(Deserialize)]
                struct Args {
                    work_fingerprint: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EndorsementQuery {
                    work_fingerprint: args.work_fingerprint,
                })
            }
            OperationCode::StateSync => {
                #[derive(Deserialize)]
                struct Args {
                    #[cfg_attr(feature = "serde", serde(default))]
                    work_fingerprints: Vec<String>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::StateSync {
                    work_fingerprints: args.work_fingerprints,
                })
            }
            OperationCode::StateAlternatives => {
                #[derive(Deserialize)]
                struct Args {
                    work_fingerprint: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::StateAlternatives {
                    work_fingerprint: args.work_fingerprint,
                })
            }
            OperationCode::MembershipJoinRequest => {
                #[derive(Deserialize)]
                struct Args {
                    entry: crate::server::federation::MembershipEntry,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::MembershipJoinRequest { entry: args.entry })
            }
            OperationCode::MembershipJoinResponse | OperationCode::MembershipSyncResult => {
                Err(FrameParseError::PayloadDecode("server-only response op".into()).into())
            }
            OperationCode::MembershipEndorseOffer => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: String,
                    proof: crate::server::federation::EndorsementProof,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::MembershipEndorseOffer {
                    server_id: args.server_id,
                    proof: args.proof,
                })
            }
            OperationCode::MembershipEndorseAccept => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::MembershipEndorseAccept {
                    server_id: args.server_id,
                })
            }
            OperationCode::MembershipVerify => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::MembershipVerify {
                    server_id: args.server_id,
                })
            }
            OperationCode::GovernancePropose => {
                #[derive(Deserialize)]
                struct Args {
                    transactions: Vec<crate::server::federation::GovernanceTx>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::GovernancePropose {
                    transactions: args.transactions,
                })
            }
            OperationCode::GovernancePrepare => {
                #[derive(Deserialize)]
                struct Args {
                    vote: crate::server::federation::PbftVote,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::GovernancePrepare { vote: args.vote })
            }
            OperationCode::GovernanceCommit => {
                #[derive(Deserialize)]
                struct Args {
                    vote: crate::server::federation::PbftVote,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::GovernanceCommit { vote: args.vote })
            }
            OperationCode::CrdtSyncOpen
            | OperationCode::CrdtSyncClose
            | OperationCode::CrdtSyncFullState
            | OperationCode::CrdtSyncMaterialize
            | OperationCode::CrdtSyncSubscriberCount
            | OperationCode::CrdtSyncText
            | OperationCode::CrdtAwarenessGet
            | OperationCode::AttestationReport => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                match op {
                    OperationCode::CrdtSyncOpen => Ok(WireRequest::CrdtSyncOpen {
                        work_id: args.work_id,
                    }),
                    OperationCode::CrdtSyncClose => Ok(WireRequest::CrdtSyncClose {
                        work_id: args.work_id,
                    }),
                    OperationCode::CrdtSyncFullState => Ok(WireRequest::CrdtSyncFullState {
                        work_id: args.work_id,
                    }),
                    OperationCode::CrdtSyncMaterialize => Ok(WireRequest::CrdtSyncMaterialize {
                        work_id: args.work_id,
                    }),
                    OperationCode::CrdtSyncSubscriberCount => {
                        Ok(WireRequest::CrdtSyncSubscriberCount {
                            work_id: args.work_id,
                        })
                    }
                    OperationCode::CrdtSyncText => Ok(WireRequest::CrdtSyncText {
                        work_id: args.work_id,
                    }),
                    OperationCode::CrdtAwarenessGet => Ok(WireRequest::CrdtAwarenessGet {
                        work_id: args.work_id,
                    }),
                    OperationCode::AttestationReport => Ok(WireRequest::AttestationReport {
                        work_id: args.work_id,
                    }),
                    _ => unreachable!(),
                }
            }
            OperationCode::CrdtSyncUpdate => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    update: Vec<u8>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrdtSyncUpdate {
                    work_id: args.work_id,
                    update: args.update,
                })
            }
            OperationCode::CrdtSyncDiff => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    state_vector: Vec<u8>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrdtSyncDiff {
                    work_id: args.work_id,
                    state_vector: args.state_vector,
                })
            }
            OperationCode::CrdtAwarenessUpdate => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    #[cfg_attr(feature = "serde", serde(default))]
                    state: Option<crate::server::crdt_manager::AwarenessState>,
                    awareness: Option<crate::server::crdt_manager::AwarenessState>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                let awareness = args.awareness.or(args.state).unwrap_or_else(|| {
                    crate::server::crdt_manager::AwarenessState {
                        session_id: 0,
                        user_name: String::new(),
                        club_id: None,
                        author_public_key: None,
                        cursor: None,
                        selection: None,
                        is_typing: false,
                    }
                });
                Ok(WireRequest::CrdtAwarenessUpdate {
                    work_id: args.work_id,
                    awareness,
                })
            }
            OperationCode::CrdtRegisterAuthor => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrdtRegisterAuthor {
                    work_id: args.work_id,
                    public_key: [0u8; 32],
                    display_name: String::new(),
                })
            }
            OperationCode::AttributionQuery => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    start: Option<i64>,
                    end: Option<i64>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AttributionQuery {
                    work_id: args.work_id,
                    start: args.start,
                    end: args.end,
                })
            }
            OperationCode::AttributionVerify => {
                #[derive(Deserialize)]
                struct Args {
                    author_public_key: Vec<u8>,
                    signature: Vec<u8>,
                    timestamp: u64,
                    server_id: Vec<u8>,
                    span_fingerprint_hex: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AttributionVerify {
                    author_public_key: args.author_public_key,
                    signature: args.signature,
                    timestamp: args.timestamp,
                    server_id: args.server_id,
                    span_fingerprint_hex: args.span_fingerprint_hex,
                })
            }
            OperationCode::HistoricalAuthorRegister => {
                #[derive(Deserialize)]
                struct Args {
                    name: String,
                    display_name: String,
                    birth_year: Option<i32>,
                    death_year: Option<i32>,
                    external_ids: std::collections::HashMap<String, String>,
                    source_bibliography: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::HistoricalAuthorRegister {
                    name: args.name,
                    display_name: args.display_name,
                    birth_year: args.birth_year,
                    death_year: args.death_year,
                    external_ids: args.external_ids,
                    source_bibliography: args.source_bibliography,
                })
            }
            OperationCode::HistoricalAuthorGet => {
                #[derive(Deserialize)]
                struct Args {
                    author_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::HistoricalAuthorGet {
                    author_id: args.author_id,
                })
            }
            OperationCode::HistoricalAuthorSearch => {
                #[derive(Deserialize)]
                struct Args {
                    query: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::HistoricalAuthorSearch { query: args.query })
            }
            OperationCode::ImportSourceWork => {
                #[derive(Deserialize)]
                struct Args {
                    author_id: BeId,
                    title: String,
                    text: String,
                    edition_info: String,
                    skip_prefix_lines: u64,
                    skip_suffix_lines: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ImportSourceWork {
                    author_id: args.author_id,
                    title: args.title,
                    text: args.text,
                    edition_info: args.edition_info,
                    skip_prefix_lines: args.skip_prefix_lines,
                    skip_suffix_lines: args.skip_suffix_lines,
                })
            }
            OperationCode::ImportEpub => {
                #[derive(Deserialize)]
                struct Args {
                    epub_data: Vec<u8>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    title: Option<String>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    author: Option<String>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    skip_prefix_lines: u64,
                    #[cfg_attr(feature = "serde", serde(default))]
                    skip_suffix_lines: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ImportEpub {
                    epub_data: args.epub_data,
                    title: args.title,
                    author: args.author,
                    skip_prefix_lines: args.skip_prefix_lines,
                    skip_suffix_lines: args.skip_suffix_lines,
                })
            }
            OperationCode::SourceDetect => {
                #[derive(Deserialize)]
                struct Args {
                    text: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::SourceDetect { text: args.text })
            }
            OperationCode::WorkListByAuthor => {
                #[derive(Deserialize)]
                struct Args {
                    author_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkListByAuthor {
                    author_id: args.author_id,
                })
            }
            OperationCode::ContentMatch => {
                #[derive(Deserialize)]
                struct Args {
                    text: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ContentMatch { text: args.text })
            }
            OperationCode::WorkApplySourceAttribution => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                    historical_author_id: u64,
                    source_work_id: Option<u64>,
                    paste_start: Option<usize>,
                    paste_end: Option<usize>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkApplySourceAttribution {
                    work_id: args.work_id,
                    historical_author_id: args.historical_author_id,
                    source_work_id: args.source_work_id,
                    paste_start: args.paste_start,
                    paste_end: args.paste_end,
                })
            }
            OperationCode::WorkApplyTransclusionAttribution => {
                #[derive(Deserialize)]
                struct Args {
                    link_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkApplyTransclusionAttribution {
                    link_id: args.link_id,
                })
            }
            OperationCode::WorkTextRange => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                    start_char: u64,
                    end_char: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkTextRange {
                    work_id: args.work_id,
                    start_char: args.start_char,
                    end_char: args.end_char,
                })
            }
            OperationCode::WorkOutline => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkOutline {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkSearch => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                    query: String,
                    #[cfg_attr(feature = "serde", serde(default))]
                    max_results: Option<u64>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSearch {
                    work_id: args.work_id,
                    query: args.query,
                    max_results: args.max_results,
                })
            }
            OperationCode::WorkGoto => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                    #[cfg_attr(feature = "serde", serde(default))]
                    line: Option<u64>,
                    #[cfg_attr(feature = "serde", serde(default, alias = "target_line"))]
                    char: Option<u64>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    context_lines: Option<u64>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkGoto {
                    work_id: args.work_id,
                    line: args.line,
                    char: args.char,
                    context_lines: args.context_lines,
                })
            }
            OperationCode::WorkSummary => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSummary {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkVersionTimeline => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkVersionTimeline {
                    work_id: args.work_id,
                })
            }
            OperationCode::PassageComposition => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                    start: u64,
                    end: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::PassageComposition {
                    work_id: args.work_id,
                    start: args.start,
                    end: args.end,
                })
            }
            OperationCode::GlobalTextSearch => {
                #[derive(Deserialize)]
                struct Args {
                    query: String,
                    #[cfg_attr(feature = "serde", serde(default))]
                    max_results: Option<u64>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::GlobalTextSearch {
                    query: args.query,
                    max_results: args.max_results,
                })
            }
            OperationCode::SeedDemoAttribution => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    #[serde(default)]
                    author_count: Option<u32>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::SeedDemoAttribution {
                    work_id: args.work_id,
                    author_count: args.author_count,
                })
            }
            OperationCode::WorkStar => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkStar {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkSetSource => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    is_source: bool,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSetSource {
                    work_id: args.work_id,
                    is_source: args.is_source,
                })
            }
            OperationCode::WebFetchSanitize => {
                #[derive(Deserialize)]
                struct Args {
                    url: String,
                    #[serde(default)]
                    max_chars: Option<u64>,
                    #[serde(default)]
                    import_as_source: Option<bool>,
                    #[serde(default)]
                    title: Option<String>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WebFetchSanitize {
                    url: args.url,
                    max_chars: args.max_chars,
                    import_as_source: args.import_as_source,
                    title: args.title,
                })
            }
            OperationCode::WorkUnstar => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkUnstar {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkIsStarred => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkIsStarred {
                    work_id: args.work_id,
                })
            }
            OperationCode::ConnectionPinSet => {
                #[derive(Deserialize)]
                struct Args {
                    key: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ConnectionPinSet { key: args.key })
            }
            OperationCode::ConnectionPinUnset => {
                #[derive(Deserialize)]
                struct Args {
                    key: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ConnectionPinUnset { key: args.key })
            }
            OperationCode::ConnectionPinsGet => Ok(WireRequest::ConnectionPinsGet),
            OperationCode::CrossServerBacklinksGet => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrossServerBacklinksGet {
                    work_id: args.work_id,
                })
            }
            OperationCode::TrailCreate => {
                #[derive(Deserialize)]
                struct Args {
                    name: String,
                    #[cfg_attr(feature = "serde", serde(default))]
                    introduction: Option<String>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    categories: Vec<String>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailCreate {
                    name: args.name,
                    introduction: args.introduction,
                    categories: args.categories,
                })
            }
            OperationCode::TrailDelete => {
                #[derive(Deserialize)]
                struct Args {
                    trail_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailDelete {
                    trail_id: args.trail_id,
                })
            }
            OperationCode::TrailRename => {
                #[derive(Deserialize)]
                struct Args {
                    trail_id: BeId,
                    name: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailRename {
                    trail_id: args.trail_id,
                    name: args.name,
                })
            }
            OperationCode::TrailAddStop => {
                #[derive(Deserialize)]
                struct Args {
                    trail_id: BeId,
                    work_id: BeId,
                    #[cfg_attr(feature = "serde", serde(default))]
                    char_start: Option<u64>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    char_end: Option<u64>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    note: Option<String>,
                    #[cfg_attr(feature = "serde", serde(default))]
                    server_domain: Option<String>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailAddStop {
                    trail_id: args.trail_id,
                    work_id: args.work_id,
                    char_start: args.char_start,
                    char_end: args.char_end,
                    note: args.note,
                    server_domain: args.server_domain,
                })
            }
            OperationCode::TrailRemoveStop => {
                #[derive(Deserialize)]
                struct Args {
                    trail_id: BeId,
                    stop_index: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailRemoveStop {
                    trail_id: args.trail_id,
                    stop_index: args.stop_index,
                })
            }
            OperationCode::TrailReorderStops => {
                #[derive(Deserialize)]
                struct Args {
                    trail_id: BeId,
                    stop_order: Vec<u64>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailReorderStops {
                    trail_id: args.trail_id,
                    stop_order: args.stop_order,
                })
            }
            OperationCode::TrailGet => {
                #[derive(Deserialize)]
                struct Args {
                    trail_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailGet {
                    trail_id: args.trail_id,
                })
            }
            OperationCode::TrailDerivedWork => {
                #[derive(Deserialize)]
                struct Args {
                    trail_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailDerivedWork {
                    trail_id: args.trail_id,
                })
            }
            OperationCode::TrailPublish => {
                #[derive(Deserialize)]
                struct Args {
                    trail_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailPublish {
                    trail_id: args.trail_id,
                })
            }
            OperationCode::TrailUnpublish => {
                #[derive(Deserialize)]
                struct Args {
                    trail_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailUnpublish {
                    trail_id: args.trail_id,
                })
            }
            OperationCode::TrailUpdate => {
                #[derive(Deserialize)]
                struct Args {
                    trail_id: BeId,
                    introduction: Option<String>,
                    categories: Vec<String>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailUpdate {
                    trail_id: args.trail_id,
                    introduction: args.introduction,
                    categories: args.categories,
                })
            }
            OperationCode::TrailListPublished => {
                #[derive(Deserialize)]
                struct Args {
                    category: Option<String>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TrailListPublished {
                    category: args.category,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::ProvJsonExport => {
                #[derive(Deserialize)]
                struct Args {
                    #[cfg_attr(feature = "serde", serde(default))]
                    work_id: Option<u64>,
                    include_federation: bool,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ProvJsonExport {
                    work_id: args.work_id,
                    include_federation: args.include_federation,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::ServerDirectoryList => Ok(WireRequest::ServerDirectoryList),
            #[cfg(feature = "serde")]
            OperationCode::ServerDirectoryAdd => {
                #[derive(Deserialize)]
                struct Args {
                    address: String,
                    #[cfg_attr(feature = "serde", serde(default))]
                    port: Option<u16>,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ServerDirectoryAdd {
                    address: args.address,
                    port: args.port,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::ServerDirectoryRemove => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ServerDirectoryRemove {
                    server_id: args.server_id,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::ServerDirectorySetTrust => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: String,
                    trusted: bool,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ServerDirectorySetTrust {
                    server_id: args.server_id,
                    trusted: args.trusted,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::NetworkSetEnabled => {
                #[derive(Deserialize)]
                struct Args {
                    enabled: bool,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::NetworkSetEnabled {
                    enabled: args.enabled,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::ExternalLinksSetEnabled => {
                #[derive(Deserialize)]
                struct Args {
                    enabled: bool,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ExternalLinksSetEnabled {
                    enabled: args.enabled,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::WorkAdminDelete => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkAdminDelete {
                    work_id: args.work_id,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::AdminEditPolicySet => {
                #[derive(Deserialize)]
                struct Args {
                    policy: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminEditPolicySet {
                    policy: args.policy,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::AdminSessionKick => {
                #[derive(Deserialize)]
                struct Args {
                    session_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminSessionKick {
                    session_id: args.session_id,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::AdminAuditTail => Ok(WireRequest::AdminAuditTail),
            #[cfg(feature = "serde")]
            OperationCode::AdminClubsList => Ok(WireRequest::AdminClubsList),
            #[cfg(feature = "serde")]
            OperationCode::AdminNetworkStatus => Ok(WireRequest::AdminNetworkStatus),
            #[cfg(feature = "serde")]
            OperationCode::AdminServerProbe => {
                #[derive(Deserialize)]
                struct Args {
                    server_key: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminServerProbe {
                    server_key: args.server_key,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::AdminGrantAdmin => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminGrantAdmin {
                    club_id: args.club_id,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::AdminRevokeAdmin => {
                #[derive(Deserialize)]
                struct Args {
                    club_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminRevokeAdmin {
                    club_id: args.club_id,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::CrossServerResolve => {
                #[derive(Deserialize)]
                struct Args {
                    tumbler: String,
                    content_hash_hex: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrossServerResolve {
                    tumbler: args.tumbler,
                    content_hash_hex: args.content_hash_hex,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::CrossServerFetchWork => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: String,
                    work_id: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrossServerFetchWork {
                    server_id: args.server_id,
                    work_id: args.work_id,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::CrossServerListWorks => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrossServerListWorks {
                    server_id: args.server_id,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::FederatedSearch => {
                #[derive(Deserialize)]
                struct Args {
                    query: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FederatedSearch { query: args.query })
            }
            #[cfg(feature = "serde")]
            OperationCode::FetchIntroductions => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FetchIntroductions {
                    server_id: args.server_id,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::AddDiscoveredServer => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: u64,
                    address: String,
                    name: String,
                    verifying_key: String,
                    introduced_by: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AddDiscoveredServer {
                    server_id: args.server_id,
                    address: args.address,
                    name: args.name,
                    verifying_key: args.verifying_key,
                    introduced_by: args.introduced_by,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::CrossServerLinkCreate => {
                #[derive(Deserialize)]
                struct Args {
                    local_work_id: u64,
                    remote_tumbler: String,
                    remote_title: String,
                    remote_server_name: String,
                    remote_server_id: u64,
                    link_type: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrossServerLinkCreate {
                    local_work_id: args.local_work_id,
                    remote_tumbler: args.remote_tumbler,
                    remote_title: args.remote_title,
                    remote_server_name: args.remote_server_name,
                    remote_server_id: args.remote_server_id,
                    link_type: args.link_type,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::CrossServerLinkList => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CrossServerLinkList {
                    work_id: args.work_id,
                })
            }
            #[cfg(feature = "serde")]
            OperationCode::FetchRemoteIdentity => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: String,
                    club_name: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FetchRemoteIdentity {
                    server_id: args.server_id,
                    club_name: args.club_name,
                })
            }
            OperationCode::TumblerResolve => {
                #[derive(Deserialize)]
                struct Args {
                    tumbler: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TumblerResolve {
                    tumbler: args.tumbler,
                })
            }
            OperationCode::BloomFilterGet => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BloomFilterGet {
                    server_id: args.server_id,
                })
            }
            OperationCode::BloomFilterCheck => {
                #[derive(Deserialize)]
                struct Args {
                    server_id: String,
                    work_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BloomFilterCheck {
                    server_id: args.server_id,
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkKindGet => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkKindGet {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkKindSet => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    kind: crate::edition::WorkKind,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkKindSet {
                    work_id: args.work_id,
                    kind: args.kind,
                })
            }
            OperationCode::WorkLicenseGet => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkLicenseGet {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkLicenseSet => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    license: crate::edition::License,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkLicenseSet {
                    work_id: args.work_id,
                    license: args.license,
                })
            }
            OperationCode::WorkListByKind => {
                #[derive(Deserialize)]
                struct Args {
                    kind: crate::edition::WorkKind,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkListByKind { kind: args.kind })
            }
            OperationCode::WorkSetText => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    text: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSetText {
                    work_id: args.work_id,
                    text: args.text,
                })
            }
            OperationCode::WorkRevisionsList => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRevisionsList {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkBlobList => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkBlobList {
                    work_id: args.work_id,
                })
            }
            OperationCode::WorkTextAtRevision => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    revision_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkTextAtRevision {
                    work_id: args.work_id,
                    revision_id: args.revision_id,
                })
            }
            OperationCode::WorkRevisionDescribe => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    revision_id: u64,
                    description: String,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRevisionDescribe {
                    work_id: args.work_id,
                    revision_id: args.revision_id,
                    description: args.description,
                })
            }
            OperationCode::WorkRevisionMarkNotable => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    revision_id: u64,
                    notable: bool,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRevisionMarkNotable {
                    work_id: args.work_id,
                    revision_id: args.revision_id,
                    notable: args.notable,
                })
            }
            OperationCode::WorkRevisionRollback => {
                #[derive(Deserialize)]
                struct Args {
                    work_id: BeId,
                    target_revision_id: u64,
                }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRevisionRollback {
                    work_id: args.work_id,
                    target_revision_id: args.target_revision_id,
                })
            }
            _ => Err(FrameParseError::MissingPayload.into()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::Edition;

    #[test]
    fn json_codec_heartbeat_roundtrip() {
        let codec = JsonCodec;
        let hb = codec.encode_heartbeat().unwrap();
        assert!(codec.is_text());
        let s = String::from_utf8(hb.clone()).unwrap();
        assert!(s.contains("heartbeat"));
    }

    #[test]
    fn json_codec_response_roundtrip() {
        let codec = JsonCodec;
        let encoded = codec
            .encode_response(42, &ResponseValue::Humber(7))
            .unwrap();
        let s = String::from_utf8(encoded).unwrap();
        assert!(s.contains("\"id\":42"));
    }

    #[test]
    fn json_codec_error_roundtrip() {
        let codec = JsonCodec;
        let encoded = codec
            .encode_error(10, ErrorCode::NotAuthorized, "denied")
            .unwrap();
        let s = String::from_utf8(encoded).unwrap();
        assert!(s.contains("not_authorized"));
    }

    #[test]
    fn binary_codec_heartbeat() {
        let codec = BinaryCodec;
        let hb = codec.encode_heartbeat().unwrap();
        assert_eq!(hb[0], PROTOCOL_VERSION);
        assert_eq!(hb[1], MessageType::Heartbeat.as_byte());
        assert!(!codec.is_text());
    }

    #[test]
    fn binary_codec_response() {
        let codec = BinaryCodec;
        let encoded = codec.encode_response(42, &ResponseValue::Void).unwrap();
        assert_eq!(encoded[0], PROTOCOL_VERSION);
        assert_eq!(encoded[1], MessageType::Response.as_byte());
        let req_id = u16::from_be_bytes([encoded[2], encoded[3]]);
        assert_eq!(req_id, 42);
    }

    #[test]
    fn binary_codec_error() {
        let codec = BinaryCodec;
        let encoded = codec.encode_error(5, ErrorCode::NotFound, "gone").unwrap();
        assert_eq!(encoded[1], MessageType::Error.as_byte());
    }

    #[test]
    fn operation_code_roundtrip() {
        let ops = vec![
            OperationCode::SessionConnect,
            OperationCode::WorkRevise,
            OperationCode::WorkGrab,
            OperationCode::EditionStore,
            OperationCode::ClubNames,
        ];
        for op in ops {
            let code = op.to_u16();
            let back = OperationCode::from_u16(code);
            assert_eq!(Some(op), back, "roundtrip failed for {:?}", op);
        }
    }

    #[test]
    fn edition_payload_text_roundtrip() {
        let ed = Edition::from_text("hello");
        let payload = EditionPayload::from_edition(&ed);
        let back = payload.to_edition();
        assert_eq!(back.to_text(), "hello");
    }

    #[test]
    fn edition_payload_empty_roundtrip() {
        let ed = Edition::empty();
        let payload = EditionPayload::from_edition(&ed);
        assert!(matches!(payload, EditionPayload::Empty));
        let back = payload.to_edition();
        assert!(back.is_empty());
    }

    #[test]
    fn json_codec_decode_heartbeat() {
        let codec = JsonCodec;
        let frame = br#"{"v":2,"type":"heartbeat","id":0}"#;
        let msg = codec.decode_request(frame).unwrap();
        assert!(matches!(msg, IncomingMessage::Heartbeat));
    }

    #[test]
    fn json_codec_decode_request_session_login_public() {
        let codec = JsonCodec;
        let frame = br#"{"v":2,"type":"request","id":7,"op":"session_login_public"}"#;
        let msg = codec.decode_request(frame).unwrap();
        match msg {
            IncomingMessage::Request(req) => {
                assert_eq!(req.request_id, 7);
                assert!(matches!(req.inner, WireRequest::SessionLoginPublic));
            }
            other => panic!("expected Request, got {:?}", other),
        }
    }

    #[test]
    fn json_codec_decode_request_work_create() {
        let codec = JsonCodec;
        let frame =
            br#"{"v":2,"type":"request","id":3,"op":"work_create","payload":{"edition":"empty"}}"#;
        let msg = codec.decode_request(frame).unwrap();
        match msg {
            IncomingMessage::Request(req) => {
                assert_eq!(req.request_id, 3);
                assert!(matches!(req.inner, WireRequest::WorkCreate { .. }));
            }
            other => panic!("expected Request, got {:?}", other),
        }
    }

    #[test]
    fn json_codec_encode_event_roundtrip() {
        let codec = JsonCodec;
        let event = WireEvent {
            subscription_id: 5,
            event: EventPayload::Done { operation_id: 42 },
        };
        let encoded = codec.encode_event(&event).unwrap();
        let s = String::from_utf8(encoded).unwrap();
        assert!(s.contains("\"type\":\"event\""));
        assert!(s.contains("\"id\":5"));
        assert!(s.contains("\"type\":\"done\""));
        assert!(s.contains("\"operation_id\":42"));
    }

    #[test]
    fn json_codec_decode_rejects_malformed_json() {
        let codec = JsonCodec;
        let bad = b"{not valid json";
        let err = codec.decode_request(bad).unwrap_err();
        assert!(matches!(err, ProtocolError::Serialization(_)));
    }

    #[test]
    fn json_codec_decode_rejects_unsupported_version() {
        let codec = JsonCodec;
        let frame = br#"{"v":99,"type":"heartbeat","id":0}"#;
        let err = codec.decode_request(frame).unwrap_err();
        assert!(matches!(
            err,
            ProtocolError::FrameParse(FrameParseError::UnsupportedVersion(99))
        ));
    }

    #[test]
    fn protocol_error_frame_parse_display() {
        let err = ProtocolError::FrameParse(FrameParseError::TruncatedFrame);
        assert_eq!(err.to_string(), "frame parse: truncated frame");
    }

    #[test]
    fn protocol_error_serialization_display() {
        let err = ProtocolError::Serialization("bad payload".to_string());
        assert_eq!(err.to_string(), "serialization: bad payload");
    }

    #[test]
    fn protocol_error_from_frame_parse_error() {
        let source = FrameParseError::MissingPayload;
        let err: ProtocolError = source.into();
        assert!(matches!(
            err,
            ProtocolError::FrameParse(FrameParseError::MissingPayload)
        ));
    }
}
