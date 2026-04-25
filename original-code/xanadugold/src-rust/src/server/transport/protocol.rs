use serde::{Deserialize, Serialize};

use crate::edition::{BeId, Edition, RangeElement, XnRegion};
use crate::server::lock::LockCredential;

pub const PROTOCOL_VERSION: u8 = 0x01;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum MessageType {
    Request     = 0x01,
    Response    = 0x02,
    Error       = 0x03,
    Event       = 0x04,
    Subscribe   = 0x05,
    Unsubscribe = 0x06,
    Heartbeat   = 0x07,
}

impl MessageType {
    pub fn from_byte(b: u8) -> Option<Self> {
        match b {
            0x01 => Some(MessageType::Request),
            0x02 => Some(MessageType::Response),
            0x03 => Some(MessageType::Error),
            0x04 => Some(MessageType::Event),
            0x05 => Some(MessageType::Subscribe),
            0x06 => Some(MessageType::Unsubscribe),
            0x07 => Some(MessageType::Heartbeat),
            _ => None,
        }
    }

    pub fn as_byte(self) -> u8 {
        self as u8
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OperationCode {
    SessionConnect,
    SessionDisconnect,
    SessionLogin,
    SessionLoginByName,
    SessionAuthenticate,
    SessionLoginPublic,

    ServerGetById,
    ServerGetByBeId,

    ClubCreate,
    ClubCreateNamed,
    ClubGet,
    ClubByName,
    ClubIdByName,
    ClubNameById,
    ClubNames,

    WorkCreate,
    WorkGetEdition,
    WorkRevise,
    WorkGrab,
    WorkRelease,
    WorkIsGrabbed,
    WorkGrabber,
    WorkCanRead,
    WorkCanRevise,
    WorkSetReadClub,
    WorkSetEditClub,
    WorkReadClub,
    WorkEditClub,
    WorkRevisionCount,
    WorkFetchRevision,
    WorkSponsor,
    WorkUnsponsor,
    WorkSponsors,
    WorkOwner,

    EditionStore,
    EditionGet,
}

impl OperationCode {
    pub fn from_u16(code: u16) -> Option<Self> {
        match code {
            0x0001 => Some(OperationCode::SessionConnect),
            0x0002 => Some(OperationCode::SessionDisconnect),
            0x0003 => Some(OperationCode::SessionLogin),
            0x0004 => Some(OperationCode::SessionLoginByName),
            0x0005 => Some(OperationCode::SessionAuthenticate),
            0x0006 => Some(OperationCode::SessionLoginPublic),

            0x0101 => Some(OperationCode::ServerGetById),
            0x0102 => Some(OperationCode::ServerGetByBeId),

            0x0201 => Some(OperationCode::ClubCreate),
            0x0202 => Some(OperationCode::ClubCreateNamed),
            0x0203 => Some(OperationCode::ClubGet),
            0x0204 => Some(OperationCode::ClubByName),
            0x0205 => Some(OperationCode::ClubIdByName),
            0x0206 => Some(OperationCode::ClubNameById),
            0x0207 => Some(OperationCode::ClubNames),

            0x0301 => Some(OperationCode::WorkCreate),
            0x0302 => Some(OperationCode::WorkGetEdition),
            0x0303 => Some(OperationCode::WorkRevise),
            0x0304 => Some(OperationCode::WorkGrab),
            0x0305 => Some(OperationCode::WorkRelease),
            0x0306 => Some(OperationCode::WorkIsGrabbed),
            0x0307 => Some(OperationCode::WorkGrabber),
            0x0308 => Some(OperationCode::WorkCanRead),
            0x0309 => Some(OperationCode::WorkCanRevise),
            0x030A => Some(OperationCode::WorkSetReadClub),
            0x030B => Some(OperationCode::WorkSetEditClub),
            0x030C => Some(OperationCode::WorkReadClub),
            0x030D => Some(OperationCode::WorkEditClub),
            0x030E => Some(OperationCode::WorkRevisionCount),
            0x030F => Some(OperationCode::WorkFetchRevision),
            0x0310 => Some(OperationCode::WorkSponsor),
            0x0311 => Some(OperationCode::WorkUnsponsor),
            0x0312 => Some(OperationCode::WorkSponsors),
            0x0313 => Some(OperationCode::WorkOwner),

            0x0401 => Some(OperationCode::EditionStore),
            0x0402 => Some(OperationCode::EditionGet),

            _ => None,
        }
    }

    pub fn to_u16(self) -> u16 {
        match self {
            OperationCode::SessionConnect     => 0x0001,
            OperationCode::SessionDisconnect  => 0x0002,
            OperationCode::SessionLogin       => 0x0003,
            OperationCode::SessionLoginByName => 0x0004,
            OperationCode::SessionAuthenticate=> 0x0005,
            OperationCode::SessionLoginPublic => 0x0006,

            OperationCode::ServerGetById  => 0x0101,
            OperationCode::ServerGetByBeId=> 0x0102,

            OperationCode::ClubCreate     => 0x0201,
            OperationCode::ClubCreateNamed=> 0x0202,
            OperationCode::ClubGet        => 0x0203,
            OperationCode::ClubByName     => 0x0204,
            OperationCode::ClubIdByName   => 0x0205,
            OperationCode::ClubNameById   => 0x0206,
            OperationCode::ClubNames      => 0x0207,

            OperationCode::WorkCreate        => 0x0301,
            OperationCode::WorkGetEdition    => 0x0302,
            OperationCode::WorkRevise        => 0x0303,
            OperationCode::WorkGrab          => 0x0304,
            OperationCode::WorkRelease       => 0x0305,
            OperationCode::WorkIsGrabbed     => 0x0306,
            OperationCode::WorkGrabber       => 0x0307,
            OperationCode::WorkCanRead       => 0x0308,
            OperationCode::WorkCanRevise     => 0x0309,
            OperationCode::WorkSetReadClub   => 0x030A,
            OperationCode::WorkSetEditClub   => 0x030B,
            OperationCode::WorkReadClub      => 0x030C,
            OperationCode::WorkEditClub      => 0x030D,
            OperationCode::WorkRevisionCount => 0x030E,
            OperationCode::WorkFetchRevision => 0x030F,
            OperationCode::WorkSponsor       => 0x0310,
            OperationCode::WorkUnsponsor     => 0x0311,
            OperationCode::WorkSponsors      => 0x0312,
            OperationCode::WorkOwner         => 0x0313,

            OperationCode::EditionStore => 0x0401,
            OperationCode::EditionGet   => 0x0402,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum WireRequest {
    SessionConnect,
    SessionDisconnect,
    SessionLogin {
        club_id: BeId,
    },
    SessionLoginByName {
        club_name: String,
    },
    SessionAuthenticate {
        club_id: BeId,
        credential: LockCredential,
    },
    SessionLoginPublic,

    ServerGetById { id: u64 },
    ServerGetByBeId { be_id: BeId },

    ClubCreate { description: EditionPayload },
    ClubCreateNamed { name: String, description: EditionPayload },
    ClubGet { club_id: BeId },
    ClubByName { name: String },
    ClubIdByName { name: String },
    ClubNameById { club_id: BeId },
    ClubNames,

    WorkCreate { edition: EditionPayload },
    WorkGetEdition { work_id: BeId },
    WorkRevise { work_id: BeId, edition: EditionPayload },
    WorkGrab { work_id: BeId },
    WorkRelease { work_id: BeId },
    WorkIsGrabbed { work_id: BeId },
    WorkGrabber { work_id: BeId },
    WorkCanRead { work_id: BeId },
    WorkCanRevise { work_id: BeId },
    WorkSetReadClub { work_id: BeId, club_id: Option<BeId> },
    WorkSetEditClub { work_id: BeId, club_id: Option<BeId> },
    WorkReadClub { work_id: BeId },
    WorkEditClub { work_id: BeId },
    WorkRevisionCount { work_id: BeId },
    WorkFetchRevision { work_id: BeId, number: u64 },
    WorkSponsor { work_id: BeId, club_id: BeId },
    WorkUnsponsor { work_id: BeId, club_id: BeId },
    WorkSponsors { work_id: BeId },
    WorkOwner { work_id: BeId },

    EditionStore { edition: EditionPayload },
    EditionGet { be_id: BeId },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EditionPayload {
    Text(String),
    Entries(Vec<(i64, RangeElement)>),
    Empty,
}

impl EditionPayload {
    pub fn to_edition(&self) -> crate::edition::Edition {
        match self {
            EditionPayload::Text(s) => Edition::from_text(s),
            EditionPayload::Entries(entries) => {
                let mut ed = Edition::empty();
                for (pos, elem) in entries {
                    ed = ed.with(*pos, elem.clone());
                }
                ed
            }
            EditionPayload::Empty => Edition::empty(),
        }
    }

    pub fn from_edition(edition: &Edition) -> Self {
        let entries: Vec<(i64, RangeElement)> = edition
            .all_entries()
            .into_iter()
            .map(|(pos, carrier)| (pos, carrier.element.clone()))
            .collect();
        if entries.is_empty() {
            EditionPayload::Empty
        } else {
            EditionPayload::Entries(entries)
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "value", rename_all = "snake_case")]
pub enum ResponseValue {
    Void,
    Id(BeId),
    Humber(u64),
    Boolean(bool),
    String(String),
    Edition(EditionPayload),
    RangeElement(Option<RangeElement>),
    Region(XnRegion),
    Ids(Vec<BeId>),
    ClubNames(Vec<(String, BeId)>),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ErrorCode {
    NotAuthorized,
    NotFound,
    AlreadyExists,
    NotGrabbed,
    AlreadyGrabbed,
    SessionRequired,
    InvalidArgument,
    TypeMismatch,
    LockFailed,
    SessionNotFound,
    WorkNotFound,
    ClubNotFound,
    EditionNotFound,
    Internal,
    ProtocolError,
}

impl ErrorCode {
    pub fn from_server_error(err: &crate::server::ServerError) -> Self {
        match err {
            crate::server::ServerError::NotAuthorized => ErrorCode::NotAuthorized,
            crate::server::ServerError::NotFound(_) => ErrorCode::NotFound,
            crate::server::ServerError::AlreadyExists(_) => ErrorCode::AlreadyExists,
            crate::server::ServerError::NotGrabbed(_) => ErrorCode::NotGrabbed,
            crate::server::ServerError::AlreadyGrabbed { .. } => ErrorCode::AlreadyGrabbed,
            crate::server::ServerError::SessionRequired => ErrorCode::SessionRequired,
            crate::server::ServerError::InvalidArgument(_) => ErrorCode::InvalidArgument,
            crate::server::ServerError::TypeMismatch { .. } => ErrorCode::TypeMismatch,
            crate::server::ServerError::LockFailed(_) => ErrorCode::LockFailed,
            crate::server::ServerError::SessionNotFound(_) => ErrorCode::SessionNotFound,
            crate::server::ServerError::WorkNotFound(_) => ErrorCode::WorkNotFound,
            crate::server::ServerError::ClubNotFound(_) => ErrorCode::ClubNotFound,
            crate::server::ServerError::EditionNotFound(_) => ErrorCode::EditionNotFound,
            crate::server::ServerError::Internal(_) => ErrorCode::Internal,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum DetectorType {
    Status,
    Revision,
    Fill,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct SubscribeRequest {
    pub detector_type: DetectorType,
    pub target_id: BeId,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(u8)]
pub enum EventCode {
    WorkGrabbed   = 0x01,
    WorkReleased  = 0x02,
    WorkRevised   = 0x03,
    RangeFilled   = 0x04,
    ElementFilled = 0x05,
    Done          = 0x06,
}

impl EventCode {
    pub fn from_byte(b: u8) -> Option<Self> {
        match b {
            0x01 => Some(EventCode::WorkGrabbed),
            0x02 => Some(EventCode::WorkReleased),
            0x03 => Some(EventCode::WorkRevised),
            0x04 => Some(EventCode::RangeFilled),
            0x05 => Some(EventCode::ElementFilled),
            0x06 => Some(EventCode::Done),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct WireEvent {
    pub subscription_id: u16,
    pub event: EventPayload,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "payload", rename_all = "snake_case")]
pub enum EventPayload {
    WorkGrabbed { work_be_id: BeId, session_id: u64 },
    WorkReleased { work_be_id: BeId, session_id: u64 },
    WorkRevised { work_be_id: BeId, revision: u64, session_id: u64 },
    RangeFilled { edition_be_id: BeId, region: XnRegion },
    ElementFilled { element_be_id: BeId },
    Done { operation_id: u64 },
}

impl EventPayload {
    pub fn from_event(event: &crate::server::Event) -> Self {
        match event {
            crate::server::Event::WorkGrabbed { work_be_id, session_id } => {
                EventPayload::WorkGrabbed { work_be_id: *work_be_id, session_id: session_id.as_u64() }
            }
            crate::server::Event::WorkReleased { work_be_id, session_id } => {
                EventPayload::WorkReleased { work_be_id: *work_be_id, session_id: session_id.as_u64() }
            }
            crate::server::Event::WorkRevised { work_be_id, revision, session_id } => {
                EventPayload::WorkRevised { work_be_id: *work_be_id, revision: *revision, session_id: session_id.as_u64() }
            }
            crate::server::Event::RangeFilled { edition_be_id, region } => {
                EventPayload::RangeFilled { edition_be_id: *edition_be_id, region: region.clone() }
            }
            crate::server::Event::ElementFilled { element_be_id } => {
                EventPayload::ElementFilled { element_be_id: *element_be_id }
            }
            crate::server::Event::Done { operation_id } => {
                EventPayload::Done { operation_id: *operation_id }
            }
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WireFrame {
    pub v: u8,
    #[serde(rename = "type")]
    pub msg_type: String,
    pub id: u16,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub op: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub payload: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub value: Option<ResponseValue>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub code: Option<ErrorCode>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub message: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub event: Option<EventPayload>,
}

#[derive(Debug, Clone)]
pub struct ParsedRequest {
    pub request_id: u16,
    pub inner: WireRequest,
}

#[derive(Debug, Clone)]
pub struct ParsedResponse {
    pub request_id: u16,
    pub value: ResponseValue,
}

#[derive(Debug, Clone)]
pub struct ParsedError {
    pub request_id: u16,
    pub code: ErrorCode,
    pub message: String,
}

#[derive(Debug, Clone)]
pub struct ParsedSubscribe {
    pub request_id: u16,
    pub subscribe: SubscribeRequest,
}

#[derive(Debug, Clone)]
pub struct ParsedUnsubscribe {
    pub request_id: u16,
}

#[derive(Debug, Clone)]
pub enum IncomingMessage {
    Request(ParsedRequest),
    Subscribe(ParsedSubscribe),
    Unsubscribe(ParsedUnsubscribe),
    Heartbeat,
}

#[derive(Debug, Clone, PartialEq)]
pub enum FrameParseError {
    TruncatedFrame,
    UnsupportedVersion(u8),
    InvalidMessageType(u8),
    UnknownOperation(u16),
    PayloadDecode(String),
    MissingPayload,
}

impl std::fmt::Display for FrameParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            FrameParseError::TruncatedFrame => write!(f, "truncated frame"),
            FrameParseError::UnsupportedVersion(v) => write!(f, "unsupported version: {}", v),
            FrameParseError::InvalidMessageType(t) => write!(f, "invalid message type: {}", t),
            FrameParseError::UnknownOperation(code) => write!(f, "unknown operation: {:04x}", code),
            FrameParseError::PayloadDecode(s) => write!(f, "payload decode error: {}", s),
            FrameParseError::MissingPayload => write!(f, "missing payload"),
        }
    }
}

impl std::error::Error for FrameParseError {}
