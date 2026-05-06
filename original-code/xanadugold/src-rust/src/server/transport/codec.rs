use serde::Deserialize;
use crate::edition::{BeId, XnRegion, RangeElement};
use crate::server::lock::LockCredential;

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
    fn encode_response(&self, request_id: u16, value: &ResponseValue) -> Result<Vec<u8>, ProtocolError>;
    fn encode_error(&self, request_id: u16, code: ErrorCode, message: &str) -> Result<Vec<u8>, ProtocolError>;
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
        let msg_type = MessageType::from_byte(data[1])
            .ok_or(FrameParseError::InvalidMessageType(data[1]))?;
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
            MessageType::Unsubscribe => {
                Ok(IncomingMessage::Unsubscribe(ParsedUnsubscribe { request_id }))
            }
            _ => Err(FrameParseError::InvalidMessageType(data[1]).into()),
        }
    }

    fn encode_response(&self, request_id: u16, value: &ResponseValue) -> Result<Vec<u8>, ProtocolError> {
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

    fn encode_error(&self, request_id: u16, code: ErrorCode, message: &str) -> Result<Vec<u8>, ProtocolError> {
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
        Ok(vec![PROTOCOL_VERSION, MessageType::Heartbeat.as_byte(), 0x00, 0x00])
    }

    fn is_text(&self) -> bool {
        false
    }
}

impl BinaryCodec {
    fn decode_wire_request(&self, op: OperationCode, data: &[u8]) -> Result<WireRequest, ProtocolError> {
        if data.is_empty() {
            return self.request_without_payload(op);
        }
        let (len, n) = varint::decode_varint(data)?;
        let end = n.checked_add(len as usize).ok_or_else(|| FrameParseError::PayloadDecode("payload length overflow".into()))?;
        if end > data.len() {
            return Err(FrameParseError::PayloadDecode("payload extends beyond frame".into()).into());
        }
        let payload_data = &data[n..end];
        match op {
            OperationCode::SessionConnect => Ok(WireRequest::SessionConnect),
            OperationCode::SessionDisconnect => Ok(WireRequest::SessionDisconnect),
            OperationCode::SessionLoginPublic => Ok(WireRequest::SessionLoginPublic),
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
            | OperationCode::WorkIsPublished => {
                let id: BeId = postcard::from_bytes(payload_data)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                self.work_id_request(op, id)
            }
            OperationCode::ClubGet
            | OperationCode::ClubNameById => {
                let id: BeId = postcard::from_bytes(payload_data)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                self.club_id_request(op, id)
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
            OperationCode::ClubNames => Ok(WireRequest::ClubNames),
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
             OperationCode::AdminIsAcceptingConnections => Ok(WireRequest::AdminIsAcceptingConnections),
             OperationCode::AdminActiveSessions => Ok(WireRequest::AdminActiveSessions),
             OperationCode::AdminShutdown => Ok(WireRequest::AdminShutdown),
             OperationCode::AdminGrants => Ok(WireRequest::AdminGrants),
             OperationCode::AdminServerInfo => Ok(WireRequest::AdminServerInfo),
             OperationCode::ServerStats => Ok(WireRequest::ServerStats),
             OperationCode::WorkList => Ok(WireRequest::WorkList),
             OperationCode::BlobStats => Ok(WireRequest::BlobStats),
             OperationCode::LabelCreate => Ok(WireRequest::LabelCreate),
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
            OperationCode::WorkCancelGrabRequest => Ok(WireRequest::WorkCancelGrabRequest { work_id: id }),
            OperationCode::WorkGrabWaiters => Ok(WireRequest::WorkGrabWaiters { work_id: id }),
            OperationCode::WorkCanRead => Ok(WireRequest::WorkCanRead { work_id: id }),
            OperationCode::WorkCanRevise => Ok(WireRequest::WorkCanRevise { work_id: id }),
            OperationCode::WorkReadClub => Ok(WireRequest::WorkReadClub { work_id: id }),
            OperationCode::WorkEditClub => Ok(WireRequest::WorkEditClub { work_id: id }),
            OperationCode::WorkRevisionCount => Ok(WireRequest::WorkRevisionCount { work_id: id }),
            OperationCode::WorkSponsors => Ok(WireRequest::WorkSponsors { work_id: id }),
            OperationCode::WorkOwner => Ok(WireRequest::WorkOwner { work_id: id }),
            OperationCode::WorkPublish => Ok(WireRequest::WorkPublish { work_id: id }),
            OperationCode::WorkUnpublish => Ok(WireRequest::WorkUnpublish { work_id: id }),
            OperationCode::WorkIrrevocablyUnpublish => Ok(WireRequest::WorkIrrevocablyUnpublish { work_id: id }),
            OperationCode::WorkIsPublished => Ok(WireRequest::WorkIsPublished { work_id: id }),
            _ => Err(FrameParseError::MissingPayload.into()),
        }
    }

    fn club_id_request(&self, op: OperationCode, id: BeId) -> Result<WireRequest, ProtocolError> {
        match op {
            OperationCode::ClubGet => Ok(WireRequest::ClubGet { club_id: id }),
            OperationCode::ClubNameById => Ok(WireRequest::ClubNameById { club_id: id }),
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
            "unsubscribe" => {
                Ok(IncomingMessage::Unsubscribe(ParsedUnsubscribe { request_id }))
            }
            _ => Err(FrameParseError::InvalidMessageType(0).into()),
        }
    }

    fn encode_response(&self, request_id: u16, value: &ResponseValue) -> Result<Vec<u8>, ProtocolError> {
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
        serde_json::to_vec(&frame)
            .map_err(|e| ProtocolError::Serialization(e.to_string()))
    }

    fn encode_error(&self, request_id: u16, code: ErrorCode, message: &str) -> Result<Vec<u8>, ProtocolError> {
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
        serde_json::to_vec(&frame)
            .map_err(|e| ProtocolError::Serialization(e.to_string()))
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
        serde_json::to_vec(&frame)
            .map_err(|e| ProtocolError::Serialization(e.to_string()))
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
        serde_json::to_vec(&frame)
            .map_err(|e| ProtocolError::Serialization(e.to_string()))
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
        let no_payload_ops = [
            OperationCode::SessionConnect,
            OperationCode::SessionDisconnect,
            OperationCode::SessionLoginPublic,
            OperationCode::ClubNames,
            OperationCode::AdminIsAcceptingConnections,
            OperationCode::AdminActiveSessions,
            OperationCode::AdminShutdown,
            OperationCode::AdminGrants,
            OperationCode::AdminServerInfo,
            OperationCode::ServerStats,
            OperationCode::WorkList,
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
        ];
        if no_payload_ops.contains(&op) {
            return match op {
                OperationCode::SessionConnect => Ok(WireRequest::SessionConnect),
                OperationCode::SessionDisconnect => Ok(WireRequest::SessionDisconnect),
                OperationCode::SessionLoginPublic => Ok(WireRequest::SessionLoginPublic),
                OperationCode::ClubNames => Ok(WireRequest::ClubNames),
                OperationCode::AdminIsAcceptingConnections => Ok(WireRequest::AdminIsAcceptingConnections),
                OperationCode::AdminActiveSessions => Ok(WireRequest::AdminActiveSessions),
                OperationCode::AdminShutdown => Ok(WireRequest::AdminShutdown),
                OperationCode::AdminGrants => Ok(WireRequest::AdminGrants),
                OperationCode::AdminServerInfo => Ok(WireRequest::AdminServerInfo),
                OperationCode::ServerStats => Ok(WireRequest::ServerStats),
                OperationCode::WorkList => Ok(WireRequest::WorkList),
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
                _ => unreachable!(),
            };
        }

        let p = payload.ok_or(FrameParseError::MissingPayload)?;

        match op {
            OperationCode::SessionLogin => {
                #[derive(Deserialize)]
                struct Args { club_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::SessionLogin { club_id: args.club_id })
            }
            OperationCode::SessionLoginByName => {
                #[derive(Deserialize)]
                struct Args { club_name: String }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::SessionLoginByName { club_name: args.club_name })
            }
            OperationCode::SessionAuthenticate => {
                let args: serde_json::Value = p;
                #[derive(Deserialize)]
                struct Args { club_id: BeId, credential: LockCredential }
                let a: Args = serde_json::from_value(args)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::SessionAuthenticate { club_id: a.club_id, credential: a.credential })
            }
            OperationCode::ServerGetById => {
                #[derive(Deserialize)]
                struct Args { id: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ServerGetById { id: args.id })
            }
            OperationCode::ServerGetByBeId => {
                #[derive(Deserialize)]
                struct Args { be_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ServerGetByBeId { be_id: args.be_id })
            }
            OperationCode::ClubCreate => {
                #[derive(Deserialize)]
                struct Args { description: EditionPayload }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubCreate { description: args.description })
            }
            OperationCode::ClubCreateNamed => {
                #[derive(Deserialize)]
                struct Args { name: String, description: EditionPayload }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubCreateNamed { name: args.name, description: args.description })
            }
            OperationCode::ClubGet => {
                #[derive(Deserialize)]
                struct Args { club_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubGet { club_id: args.club_id })
            }
            OperationCode::ClubByName | OperationCode::ClubIdByName => {
                #[derive(Deserialize)]
                struct Args { name: String }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubIdByName { name: args.name })
            }
            OperationCode::ClubNameById => {
                #[derive(Deserialize)]
                struct Args { club_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubNameById { club_id: args.club_id })
            }
            OperationCode::WorkCreate => {
                #[derive(Deserialize)]
                struct Args { edition: EditionPayload }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkCreate { edition: args.edition })
            }
            OperationCode::WorkGetEdition => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkGetEdition { work_id: args.work_id })
            }
            OperationCode::WorkRevise => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, edition: EditionPayload }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRevise { work_id: args.work_id, edition: args.edition })
            }
            OperationCode::WorkReviseDelta => {
                use super::protocol::TextDeltaOp;
                #[derive(Deserialize)]
                struct Args { work_id: BeId, base_revision: u64, ops: Vec<TextDeltaOp> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkReviseDelta { work_id: args.work_id, base_revision: args.base_revision, ops: args.ops })
            }
            OperationCode::WorkGrab => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkGrab { work_id: args.work_id })
            }
            OperationCode::WorkRelease => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRelease { work_id: args.work_id })
            }
            OperationCode::WorkIsGrabbed => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkIsGrabbed { work_id: args.work_id })
            }
            OperationCode::WorkGrabber => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkGrabber { work_id: args.work_id })
            }
            OperationCode::WorkRequestGrab => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRequestGrab { work_id: args.work_id })
            }
            OperationCode::WorkCancelGrabRequest => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkCancelGrabRequest { work_id: args.work_id })
            }
            OperationCode::WorkGrabWaiters => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkGrabWaiters { work_id: args.work_id })
            }
            OperationCode::WorkCanRead => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkCanRead { work_id: args.work_id })
            }
            OperationCode::WorkCanRevise => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkCanRevise { work_id: args.work_id })
            }
            OperationCode::WorkSetReadClub => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, club_id: Option<BeId> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSetReadClub { work_id: args.work_id, club_id: args.club_id })
            }
            OperationCode::WorkSetEditClub => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, club_id: Option<BeId> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSetEditClub { work_id: args.work_id, club_id: args.club_id })
            }
            OperationCode::WorkPublish => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkPublish { work_id: args.work_id })
            }
            OperationCode::WorkUnpublish => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkUnpublish { work_id: args.work_id })
            }
            OperationCode::WorkIrrevocablyUnpublish => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkIrrevocablyUnpublish { work_id: args.work_id })
            }
            OperationCode::WorkIsPublished => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkIsPublished { work_id: args.work_id })
            }
            OperationCode::ClubSetDefaultReadClub => {
                #[derive(Deserialize)]
                struct Args { club_id: BeId, default_read_club: Option<BeId> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubSetDefaultReadClub { club_id: args.club_id, default_read_club: args.default_read_club })
            }
            OperationCode::ClubSetDefaultEditClub => {
                #[derive(Deserialize)]
                struct Args { club_id: BeId, default_edit_club: Option<BeId> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ClubSetDefaultEditClub { club_id: args.club_id, default_edit_club: args.default_edit_club })
            }
            OperationCode::WorkReadClub => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkReadClub { work_id: args.work_id })
            }
            OperationCode::WorkEditClub => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkEditClub { work_id: args.work_id })
            }
            OperationCode::WorkRevisionCount => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRevisionCount { work_id: args.work_id })
            }
            OperationCode::WorkFetchRevision => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, number: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkFetchRevision { work_id: args.work_id, number: args.number })
            }
            OperationCode::WorkSponsor => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, club_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSponsor { work_id: args.work_id, club_id: args.club_id })
            }
            OperationCode::WorkUnsponsor => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, club_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkUnsponsor { work_id: args.work_id, club_id: args.club_id })
            }
            OperationCode::WorkSponsors => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkSponsors { work_id: args.work_id })
            }
            OperationCode::WorkOwner => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkOwner { work_id: args.work_id })
            }
            OperationCode::EditionStore => {
                #[derive(Deserialize)]
                struct Args { edition: EditionPayload }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionStore { edition: args.edition })
            }
            OperationCode::EditionGet => {
                #[derive(Deserialize)]
                struct Args { be_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionGet { be_id: args.be_id })
            }
            OperationCode::AdminAcceptConnections => {
                #[derive(Deserialize)]
                struct Args { accept: bool }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminAcceptConnections { accept: args.accept })
            }
            OperationCode::AdminIsAcceptingConnections => {
                Ok(WireRequest::AdminIsAcceptingConnections)
            }
            OperationCode::AdminActiveSessions => {
                Ok(WireRequest::AdminActiveSessions)
            }
            OperationCode::AdminShutdown => {
                Ok(WireRequest::AdminShutdown)
            }
            OperationCode::AdminGrant => {
                #[derive(Deserialize)]
                struct Args { club_id: BeId, region_start: i64, region_end: i64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminGrant { club_id: args.club_id, region_start: args.region_start, region_end: args.region_end })
            }
            OperationCode::AdminRevokeGrant => {
                #[derive(Deserialize)]
                struct Args { club_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminRevokeGrant { club_id: args.club_id })
            }
            OperationCode::AdminGrants => {
                Ok(WireRequest::AdminGrants)
            }
            OperationCode::AdminServerInfo => {
                Ok(WireRequest::AdminServerInfo)
            }
            OperationCode::ServerStats => {
                Ok(WireRequest::ServerStats)
            }
            OperationCode::WorkListByOwner => {
                #[derive(Deserialize)]
                struct Args { owner: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkListByOwner { owner: args.owner })
            }
            OperationCode::LinkCreate => {
                #[derive(Deserialize)]
                struct Args { origin: BeId, destination: BeId, origin_ref: Option<HyperRefPayload>, destination_ref: Option<HyperRefPayload> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkCreate { origin: args.origin, destination: args.destination, origin_ref: args.origin_ref, destination_ref: args.destination_ref })
            }
            OperationCode::LinkGet => {
                #[derive(Deserialize)]
                struct Args { link_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkGet { link_id: args.link_id })
            }
            OperationCode::LinkUpdate => {
                #[derive(Deserialize)]
                struct Args { link_id: BeId, origin_ref: Option<HyperRefPayload>, destination_ref: Option<HyperRefPayload> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkUpdate { link_id: args.link_id, origin_ref: args.origin_ref, destination_ref: args.destination_ref })
            }
            OperationCode::LinkDelete => {
                #[derive(Deserialize)]
                struct Args { link_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkDelete { link_id: args.link_id })
            }
            OperationCode::LinkListForWork => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LinkListForWork { work_id: args.work_id })
            }
            OperationCode::FindTranscluders => {
                #[derive(Deserialize)]
                struct Args { content_be_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FindTranscluders { content_be_id: args.content_be_id })
            }
            OperationCode::FindWorksForContent => {
                #[derive(Deserialize)]
                struct Args { content_be_id: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FindWorksForContent { content_be_id: args.content_be_id })
            }
            OperationCode::FindTextTranscluders => {
                #[derive(Deserialize)]
                struct Args { text: String }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FindTextTranscluders { text: args.text })
            }
            OperationCode::FindSharedRegions => {
                #[derive(Deserialize)]
                struct Args { work_a: BeId, work_b: BeId, filter_text: Option<String> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FindSharedRegions { work_a: args.work_a, work_b: args.work_b, filter_text: args.filter_text })
            }
            OperationCode::BlobUpload => {
                #[derive(Deserialize)]
                struct Args { data: String, mime_type: String }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BlobUpload { data: args.data, mime_type: args.mime_type })
            }
            OperationCode::BlobGet => {
                #[derive(Deserialize)]
                struct Args { #[serde(deserialize_with = "super::protocol::u64_hex::deserialize")] content_hash: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BlobGet { content_hash: args.content_hash })
            }
            OperationCode::BlobGetPreview => {
                #[derive(Deserialize)]
                struct Args { #[serde(deserialize_with = "super::protocol::u64_hex::deserialize")] content_hash: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BlobGetPreview { content_hash: args.content_hash })
            }
            OperationCode::BlobExists => {
                #[derive(Deserialize)]
                struct Args { #[serde(deserialize_with = "super::protocol::u64_hex::deserialize")] content_hash: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BlobExists { content_hash: args.content_hash })
            }
            OperationCode::BlobInfo => {
                #[derive(Deserialize)]
                struct Args { #[serde(deserialize_with = "super::protocol::u64_hex::deserialize")] content_hash: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::BlobInfo { content_hash: args.content_hash })
            }
            OperationCode::OverlayApply => {
                #[derive(Deserialize)]
                struct Args { #[serde(deserialize_with = "super::protocol::u64_hex::deserialize")] base_hash: u64, ops: Vec<crate::edition::ImageOp>, mime_type: String }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::OverlayApply { base_hash: args.base_hash, ops: args.ops, mime_type: args.mime_type })
            }
            OperationCode::OverlayGet => {
                #[derive(Deserialize)]
                struct Args { #[serde(deserialize_with = "super::protocol::u64_hex::deserialize")] overlay_hash: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::OverlayGet { overlay_hash: args.overlay_hash })
            }
            OperationCode::LabelCreate => {
                Ok(WireRequest::LabelCreate)
            }
            OperationCode::LabelGetPositions => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, label_id: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::LabelGetPositions { work_id: args.work_id, label_id: args.label_id })
            }
            OperationCode::EditionRelabel => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, label_id: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionRelabel { work_id: args.work_id, label_id: args.label_id })
            }
            OperationCode::EditionRebind => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, position: i64, new_edition: EditionPayload }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionRebind { work_id: args.work_id, position: args.position, new_edition: args.new_edition })
            }
            OperationCode::CanMakeIdentical => {
                #[derive(Deserialize)]
                struct Args { source_work_id: BeId, target_work_id: BeId, position: Option<i64> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CanMakeIdentical { source_work_id: args.source_work_id, target_work_id: args.target_work_id, position: args.position })
            }
            OperationCode::MakeRangeIdentical => {
                #[derive(Deserialize)]
                struct Args { source_work_id: BeId, target_work_id: BeId, region: Option<XnRegion> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::MakeRangeIdentical { source_work_id: args.source_work_id, target_work_id: args.target_work_id, region: args.region })
            }
            OperationCode::IdentityUnify => {
                #[derive(Deserialize)]
                struct Args { source_id: u64, target_id: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::IdentityUnify { source_id: args.source_id, target_id: args.target_id })
            }
            OperationCode::IdentityResolve => {
                #[derive(Deserialize)]
                struct Args { id: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::IdentityResolve { id: args.id })
            }
            OperationCode::EditionRetrieve => {
                use super::protocol::RetrieveFlagsPayload;
                #[derive(Deserialize)]
                struct Args { work_id: BeId, region: Option<XnRegion>, flags: Option<RetrieveFlagsPayload> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionRetrieve { work_id: args.work_id, region: args.region, flags: args.flags })
            }
            OperationCode::EditionCost => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, method: Option<String> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionCost { work_id: args.work_id, method: args.method })
            }
            OperationCode::ContentSharedRegion => {
                #[derive(Deserialize)]
                struct Args { work_a: BeId, work_b: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ContentSharedRegion { work_a: args.work_a, work_b: args.work_b })
            }
            OperationCode::ContentMapSharedTo => {
                #[derive(Deserialize)]
                struct Args { work_a: BeId, work_b: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ContentMapSharedTo { work_a: args.work_a, work_b: args.work_b })
            }
            OperationCode::ContentMapSharedOnto => {
                #[derive(Deserialize)]
                struct Args { work_a: BeId, work_b: BeId }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::ContentMapSharedOnto { work_a: args.work_a, work_b: args.work_b })
            }
            OperationCode::PositionsOf => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, element: RangeElement }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::PositionsOf { work_id: args.work_id, element: args.element })
            }
            OperationCode::RangeTranscluders => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, region: Option<XnRegion>, direct_only: Option<bool> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::RangeTranscluders { work_id: args.work_id, region: args.region, direct_only: args.direct_only })
            }
            OperationCode::RangeWorks => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, region: Option<XnRegion> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::RangeWorks { work_id: args.work_id, region: args.region })
            }
            OperationCode::OrderedBundles => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, region: Option<XnRegion> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::OrderedBundles { work_id: args.work_id, region: args.region })
            }
            OperationCode::TransclusionDepth => {
                #[derive(Deserialize)]
                struct Args { work_id: BeId, position: i64, max_depth: Option<usize> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::TransclusionDepth { work_id: args.work_id, position: args.position, max_depth: args.max_depth })
            }
            OperationCode::AdminRecorderCreate => {
                #[derive(Deserialize)]
                struct Args { kind: String, direct_only: Option<bool>, region: Option<XnRegion> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminRecorderCreate { kind: args.kind, direct_only: args.direct_only, region: args.region })
            }
            OperationCode::AdminRecorderRecord => {
                #[derive(Deserialize)]
                struct Args { recorder_id: u64, element: RangeElement }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminRecorderRecord { recorder_id: args.recorder_id, element: args.element })
            }
            OperationCode::AdminRecorderList => {
                Ok(WireRequest::AdminRecorderList)
            }
            OperationCode::AdminRecorderGet => {
                #[derive(Deserialize)]
                struct Args { recorder_id: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::AdminRecorderGet { recorder_id: args.recorder_id })
            }
            OperationCode::AdminServerHealth => {
                Ok(WireRequest::AdminServerHealth)
            }
            OperationCode::CryptoGetPublicKey => {
                Ok(WireRequest::CryptoGetPublicKey)
            }
            OperationCode::CryptoSignData => {
                #[derive(Deserialize)]
                struct Args { data: Vec<u8> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CryptoSignData { data: args.data })
            }
            OperationCode::CryptoVerifySignature => {
                #[derive(Deserialize)]
                struct Args { data: Vec<u8>, signature: Vec<u8> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::CryptoVerifySignature { data: args.data, signature: args.signature })
            }
            OperationCode::CryptoKeyRotation => {
                Ok(WireRequest::CryptoKeyRotation)
            }
            OperationCode::CryptoKeyHistory => {
                Ok(WireRequest::CryptoKeyHistory)
            }
            OperationCode::WorkEndorse => {
                #[derive(Deserialize)]
                struct Args { work_id: u64, endorsements: Vec<(u64, u64)> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkEndorse { work_id: args.work_id, endorsements: args.endorsements })
            }
            OperationCode::WorkRetract => {
                #[derive(Deserialize)]
                struct Args { work_id: u64, endorsements: Vec<(u64, u64)> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkRetract { work_id: args.work_id, endorsements: args.endorsements })
            }
            OperationCode::WorkEndorsements => {
                #[derive(Deserialize)]
                struct Args { work_id: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::WorkEndorsements { work_id: args.work_id })
            }
            OperationCode::EditionEndorse => {
                #[derive(Deserialize)]
                struct Args { edition_id: u64, endorsements: Vec<(u64, u64)> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionEndorse { edition_id: args.edition_id, endorsements: args.endorsements })
            }
            OperationCode::EditionRetract => {
                #[derive(Deserialize)]
                struct Args { edition_id: u64, endorsements: Vec<(u64, u64)> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionRetract { edition_id: args.edition_id, endorsements: args.endorsements })
            }
            OperationCode::EditionEndorsements => {
                #[derive(Deserialize)]
                struct Args { edition_id: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionEndorsements { edition_id: args.edition_id })
            }
            OperationCode::EditionVisibleEndorsements => {
                #[derive(Deserialize)]
                struct Args { edition_id: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionVisibleEndorsements { edition_id: args.edition_id })
            }
            OperationCode::EditionTotalEndorsements => {
                #[derive(Deserialize)]
                struct Args { edition_id: u64 }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EditionTotalEndorsements { edition_id: args.edition_id })
            }
            OperationCode::FederationInfo => {
                Ok(WireRequest::FederationInfo)
            }
            OperationCode::FederationPeers => {
                Ok(WireRequest::FederationPeers)
            }
            OperationCode::FederatedTransclusionQuery => {
                #[derive(Deserialize)]
                struct Args { content_fingerprint_hex: String, #[serde(default)] direct_only: bool }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FederatedTransclusionQuery {
                    content_fingerprint_hex: args.content_fingerprint_hex,
                    direct_only: args.direct_only,
                })
            }
            OperationCode::FederatedContentFetch => {
                #[derive(Deserialize)]
                struct Args { content_fingerprint_hex: String }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::FederatedContentFetch {
                    content_fingerprint_hex: args.content_fingerprint_hex,
                })
            }
            OperationCode::EndorsementSync => {
                #[derive(Deserialize)]
                struct Args { work_fingerprint: String }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EndorsementSync {
                    work_fingerprint: args.work_fingerprint,
                })
            }
            OperationCode::EndorsementAdd => {
                #[derive(Deserialize)]
                struct Args { work_fingerprint: String, club_id: u64, token_id: u64 }
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
                struct Args { work_fingerprint: String, club_id: u64, token_id: u64 }
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
                struct Args { work_fingerprint: String }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::EndorsementQuery {
                    work_fingerprint: args.work_fingerprint,
                })
            }
            OperationCode::StateSync => {
                #[derive(Deserialize)]
                struct Args { #[serde(default)] work_fingerprints: Vec<String> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::StateSync {
                    work_fingerprints: args.work_fingerprints,
                })
            }
            OperationCode::StateAlternatives => {
                #[derive(Deserialize)]
                struct Args { work_fingerprint: String }
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
                Ok(WireRequest::MembershipJoinRequest {
                    entry: args.entry,
                })
            }
            OperationCode::MembershipJoinResponse
            | OperationCode::MembershipSyncResult => {
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
                struct Args { server_id: String }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::MembershipEndorseAccept {
                    server_id: args.server_id,
                })
            }
            OperationCode::MembershipVerify => {
                #[derive(Deserialize)]
                struct Args { server_id: String }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::MembershipVerify {
                    server_id: args.server_id,
                })
            }
            OperationCode::GovernancePropose => {
                #[derive(Deserialize)]
                struct Args { transactions: Vec<crate::server::federation::GovernanceTx> }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::GovernancePropose {
                    transactions: args.transactions,
                })
            }
            OperationCode::GovernancePrepare => {
                #[derive(Deserialize)]
                struct Args { vote: crate::server::federation::PbftVote }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::GovernancePrepare {
                    vote: args.vote,
                })
            }
            OperationCode::GovernanceCommit => {
                #[derive(Deserialize)]
                struct Args { vote: crate::server::federation::PbftVote }
                let args: Args = serde_json::from_value(p)
                    .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
                Ok(WireRequest::GovernanceCommit {
                    vote: args.vote,
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
        let encoded = codec.encode_response(42, &ResponseValue::Humber(7)).unwrap();
        let s = String::from_utf8(encoded).unwrap();
        assert!(s.contains("\"id\":42"));
    }

    #[test]
    fn json_codec_error_roundtrip() {
        let codec = JsonCodec;
        let encoded = codec.encode_error(10, ErrorCode::NotAuthorized, "denied").unwrap();
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
}
