use serde::{Deserialize, Serialize};

use crate::edition::{BeId, Edition, RangeElement, XnRegion, ImageOp};
use crate::server::lock::LockCredential;

pub const PROTOCOL_VERSION: u8 = 0x02;
pub const MIN_SUPPORTED_VERSION: u8 = 0x01;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum MessageType {
    Handshake   = 0x00,
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
            0x00 => Some(MessageType::Handshake),
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HandshakeRequest {
    pub client_version: u8,
    pub client_capabilities: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HandshakeResponse {
    pub server_version: u8,
    pub negotiated_version: u8,
    pub server_id: String,
    pub server_capabilities: Vec<String>,
}

impl HandshakeResponse {
    pub fn accepted(client_version: u8) -> Self {
        let negotiated = client_version.min(PROTOCOL_VERSION);
        HandshakeResponse {
            server_version: PROTOCOL_VERSION,
            negotiated_version: negotiated.max(MIN_SUPPORTED_VERSION),
            server_id: format!("xudanu-{}", env!("CARGO_PKG_VERSION")),
            server_capabilities: vec![
                "json".to_string(),
                "binary".to_string(),
                "detector_events".to_string(),
                "admin".to_string(),
            ],
        }
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

    AdminAcceptConnections,
    AdminIsAcceptingConnections,
    AdminActiveSessions,
    AdminShutdown,
    AdminGrant,
    AdminRevokeGrant,
    AdminGrants,
    AdminServerInfo,

    WorkList,
    WorkListByOwner,

    WorkReviseDelta,

    LinkCreate,
    LinkGet,
    LinkUpdate,
    LinkDelete,
    LinkListForWork,

    FindTranscluders,
    FindWorksForContent,
    FindTextTranscluders,
    FindSharedRegions,

    ServerStats,

    BlobUpload,
    BlobGet,
    BlobGetPreview,
    BlobExists,
    BlobInfo,
    BlobStats,
    OverlayApply,
    OverlayGet,
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
            0x0314 => Some(OperationCode::WorkList),
            0x0315 => Some(OperationCode::WorkListByOwner),
            0x0316 => Some(OperationCode::WorkReviseDelta),

            0x0401 => Some(OperationCode::EditionStore),
            0x0402 => Some(OperationCode::EditionGet),

            0x0501 => Some(OperationCode::AdminAcceptConnections),
            0x0502 => Some(OperationCode::AdminIsAcceptingConnections),
            0x0503 => Some(OperationCode::AdminActiveSessions),
            0x0504 => Some(OperationCode::AdminShutdown),
            0x0505 => Some(OperationCode::AdminGrant),
            0x0506 => Some(OperationCode::AdminRevokeGrant),
            0x0507 => Some(OperationCode::AdminGrants),
            0x0508 => Some(OperationCode::AdminServerInfo),

            0x0701 => Some(OperationCode::LinkCreate),
            0x0702 => Some(OperationCode::LinkGet),
            0x0703 => Some(OperationCode::LinkUpdate),
            0x0704 => Some(OperationCode::LinkDelete),
            0x0705 => Some(OperationCode::LinkListForWork),

            0x0801 => Some(OperationCode::FindTranscluders),
            0x0802 => Some(OperationCode::FindWorksForContent),
            0x0803 => Some(OperationCode::FindTextTranscluders),
            0x0804 => Some(OperationCode::FindSharedRegions),

            0x0601 => Some(OperationCode::ServerStats),

            0x0901 => Some(OperationCode::BlobUpload),
            0x0902 => Some(OperationCode::BlobGet),
            0x0903 => Some(OperationCode::BlobGetPreview),
            0x0904 => Some(OperationCode::BlobExists),
            0x0905 => Some(OperationCode::BlobInfo),
            0x0906 => Some(OperationCode::BlobStats),

            0x0a01 => Some(OperationCode::OverlayApply),
            0x0a02 => Some(OperationCode::OverlayGet),

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

            OperationCode::AdminAcceptConnections    => 0x0501,
            OperationCode::AdminIsAcceptingConnections => 0x0502,
            OperationCode::AdminActiveSessions        => 0x0503,
            OperationCode::AdminShutdown              => 0x0504,
            OperationCode::AdminGrant                 => 0x0505,
            OperationCode::AdminRevokeGrant           => 0x0506,
            OperationCode::AdminGrants                => 0x0507,
            OperationCode::AdminServerInfo            => 0x0508,

            OperationCode::WorkList                    => 0x0314,
            OperationCode::WorkListByOwner             => 0x0315,
            OperationCode::WorkReviseDelta             => 0x0316,

            OperationCode::LinkCreate                  => 0x0701,
            OperationCode::LinkGet                     => 0x0702,
            OperationCode::LinkUpdate                  => 0x0703,
            OperationCode::LinkDelete                  => 0x0704,
            OperationCode::LinkListForWork             => 0x0705,

            OperationCode::FindTranscluders            => 0x0801,
            OperationCode::FindWorksForContent         => 0x0802,
            OperationCode::FindTextTranscluders        => 0x0803,
            OperationCode::FindSharedRegions           => 0x0804,

            OperationCode::ServerStats => 0x0601,

            OperationCode::BlobUpload      => 0x0901,
            OperationCode::BlobGet          => 0x0902,
            OperationCode::BlobGetPreview   => 0x0903,
            OperationCode::BlobExists       => 0x0904,
            OperationCode::BlobInfo         => 0x0905,
            OperationCode::BlobStats        => 0x0906,

            OperationCode::OverlayApply      => 0x0a01,
            OperationCode::OverlayGet        => 0x0a02,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum TextDeltaOp {
    Retain { count: u64 },
    Insert { text: String },
    Delete { count: u64 },
}

pub fn apply_text_delta(text: &str, ops: &[TextDeltaOp]) -> String {
    let chars: Vec<char> = text.chars().collect();
    let mut result = String::with_capacity(text.len() + 64);
    let mut pos = 0usize;
    for op in ops {
        match op {
            TextDeltaOp::Retain { count } => {
                let end = (pos + *count as usize).min(chars.len());
                for ch in &chars[pos..end] {
                    result.push(*ch);
                }
                pos = end;
            }
            TextDeltaOp::Insert { text: t } => {
                result.push_str(t);
            }
            TextDeltaOp::Delete { count } => {
                pos = (pos + *count as usize).min(chars.len());
            }
        }
    }
    if pos < chars.len() {
        for ch in &chars[pos..] {
            result.push(*ch);
        }
    }
    result
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

    AdminAcceptConnections { accept: bool },
    AdminIsAcceptingConnections,
    AdminActiveSessions,
    AdminShutdown,
    AdminGrant { club_id: BeId, region_start: i64, region_end: i64 },
    AdminRevokeGrant { club_id: BeId },
    AdminGrants,
    AdminServerInfo,

    WorkList,
    WorkListByOwner { owner: BeId },

    WorkReviseDelta { work_id: BeId, base_revision: u64, ops: Vec<TextDeltaOp> },

    LinkCreate { origin: BeId, destination: BeId, origin_ref: Option<HyperRefPayload>, destination_ref: Option<HyperRefPayload> },
    LinkGet { link_id: BeId },
    LinkUpdate { link_id: BeId, origin_ref: Option<HyperRefPayload>, destination_ref: Option<HyperRefPayload> },
    LinkDelete { link_id: BeId },
    LinkListForWork { work_id: BeId },

    FindTranscluders { content_be_id: BeId },
    FindWorksForContent { content_be_id: BeId },
    FindTextTranscluders { text: String },
    FindSharedRegions { work_a: BeId, work_b: BeId },

    ServerStats,

    BlobUpload { data: String, mime_type: String },
    BlobGet { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] content_hash: u64 },
    BlobGetPreview { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] content_hash: u64 },
    BlobExists { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] content_hash: u64 },
    BlobInfo { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] content_hash: u64 },
    BlobStats,
    OverlayApply { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] base_hash: u64, ops: Vec<ImageOp>, mime_type: String },
    OverlayGet { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] overlay_hash: u64 },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EditionPayload {
    Text(String),
    Entries(Vec<(i64, RangeElement)>),
    Empty,
}

fn is_contiguous_text(entries: &[(i64, RangeElement)]) -> bool {
    if entries.is_empty() {
        return true;
    }
    for (i, (pos, elem)) in entries.iter().enumerate() {
        if *pos != i as i64 {
            return false;
        }
        if elem.as_text().is_none() {
            return false;
        }
    }
    true
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
        } else if is_contiguous_text(&entries) {
            let s: String = entries.iter().map(|(_, e)| {
                e.as_text().unwrap_or("")
            }).collect();
            EditionPayload::Text(s)
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
    SessionInfos(Vec<SessionInfoPayload>),
    ServerInfo(ServerInfoPayload),
    Grants(Vec<GrantPayload>),
    WorkList(Vec<WorkListEntry>),
    LinkInfo(LinkPayload),
    LinkList(Vec<LinkPayload>),
    TransclusionResults(Vec<TransclusionResultPayload>),
    WorkIds(Vec<BeId>),
    TextTransclusionResults(Vec<TextTransclusionResultPayload>),
    SharedRegions(Vec<SharedRegionPayload>),
    BlobMeta(BlobMetaPayload),
    BlobData(Vec<u8>),
    BlobStatsInfo(BlobStatsPayload),
    OverlayInfo(OverlayPayload),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkListEntry {
    pub work_id: BeId,
    pub owner: Option<BeId>,
    pub revision_count: u64,
    pub is_grabbed: bool,
    #[serde(default, skip_serializing_if = "String::is_empty")]
    pub title: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LinkPayload {
    pub link_id: BeId,
    pub origin: BeId,
    pub destination: BeId,
    pub origin_ref: Option<HyperRefPayload>,
    pub destination_ref: Option<HyperRefPayload>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HyperRefPayload {
    pub kind: String,
    pub work_context: Option<BeId>,
    pub original_context: Option<BeId>,
}

impl HyperRefPayload {
    pub fn from_hyper_ref(hr: &crate::edition::links::HyperRef) -> Self {
        HyperRefPayload {
            kind: if hr.is_single() { "single".to_string() } else { "multi".to_string() },
            work_context: hr.work_context(),
            original_context: hr.original_context(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransclusionResultPayload {
    pub element_type: String,
    pub element_id: BeId,
    pub is_direct: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextTransclusionResultPayload {
    pub work_id: BeId,
    pub owner: Option<BeId>,
    pub revision_count: u64,
    pub matches: Vec<TextMatchPayload>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextMatchPayload {
    pub start: i64,
    pub end: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SharedRegionPayload {
    pub work_id: BeId,
    pub start_a: i64,
    pub end_a: i64,
    pub start_b: i64,
    pub end_b: i64,
    pub text: String,
}

pub mod u64_hex {
    use serde::{Serializer, Deserializer, de::Error};
    pub fn serialize<S: Serializer>(v: &u64, s: S) -> Result<S::Ok, S::Error> {
        s.serialize_str(&format!("{:016x}", v))
    }
    pub fn deserialize<'de, D: Deserializer<'de>>(d: D) -> Result<u64, D::Error> {
        let s = <String as serde::Deserialize>::deserialize(d)?;
        u64::from_str_radix(&s, 16).map_err(D::Error::custom)
    }
}

pub mod u64_option_hex {
    use serde::{Serializer, Deserializer, de::Error};
    pub fn serialize<S: Serializer>(v: &Option<u64>, s: S) -> Result<S::Ok, S::Error> {
        match v {
            Some(n) => s.serialize_some(&format!("{:016x}", n)),
            None => s.serialize_none(),
        }
    }
    pub fn deserialize<'de, D: Deserializer<'de>>(d: D) -> Result<Option<u64>, D::Error> {
        let opt: Option<String> = <Option<String> as serde::Deserialize>::deserialize(d)?;
        match opt {
            Some(s) => Ok(Some(u64::from_str_radix(&s, 16).map_err(D::Error::custom)?)),
            None => Ok(None),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlobMetaPayload {
    #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")]
    pub content_hash: u64,
    pub byte_size: u64,
    pub mime_type: String,
    #[serde(serialize_with = "u64_option_hex::serialize", deserialize_with = "u64_option_hex::deserialize")]
    pub preview_hash: Option<u64>,
    pub width: Option<u32>,
    pub height: Option<u32>,
}

impl BlobMetaPayload {
    pub fn from_blob_meta(meta: &crate::edition::BlobMeta) -> Self {
        BlobMetaPayload {
            content_hash: meta.hash_u64(),
            byte_size: meta.byte_size,
            mime_type: meta.mime_type.clone(),
            preview_hash: meta.preview_hash.map(|h| crate::edition::u64_from_hash(&h)),
            width: meta.metadata.get("width").and_then(|v| v.parse().ok()),
            height: meta.metadata.get("height").and_then(|v| v.parse().ok()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlobStatsPayload {
    pub total_blobs: u64,
    pub total_bytes: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OverlayPayload {
    #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")]
    pub overlay_hash: u64,
    #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")]
    pub base_hash: u64,
    pub operations: Vec<ImageOp>,
    pub mime_type: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionInfoPayload {
    pub session_id: u64,
    pub is_logged_in: bool,
    pub authority_clubs: Vec<BeId>,
    pub initial_login: Option<BeId>,
    pub grabbed_work_count: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerInfoPayload {
    pub version: String,
    pub session_count: usize,
    pub work_count: usize,
    pub club_count: usize,
    pub edition_count: usize,
    pub is_accepting_connections: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrantPayload {
    pub club_id: BeId,
    pub region_start: i64,
    pub region_end: i64,
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
    AdminRequired,
    ServerShuttingDown,
    NotAcceptingConnections,
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
            crate::server::ServerError::AdminRequired => ErrorCode::AdminRequired,
            crate::server::ServerError::ServerShuttingDown => ErrorCode::ServerShuttingDown,
            crate::server::ServerError::NotAcceptingConnections => ErrorCode::NotAcceptingConnections,
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
