use serde::{Deserialize, Serialize};

use crate::edition::{BeId, Edition, RangeElement, XnRegion, ImageOp, Bundle};
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
    WorkSaveAndRelease,
    WorkForceRelease,
    WorkIsGrabbed,
    WorkGrabber,
    WorkRequestGrab,
    WorkCancelGrabRequest,
    WorkGrabWaiters,
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
    WorkPublish,
    WorkUnpublish,
    WorkIrrevocablyUnpublish,
    WorkIsPublished,

    ClubSetDefaultReadClub,
    ClubSetDefaultEditClub,

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

    LabelCreate,
    LabelGetPositions,
    EditionRelabel,
    EditionRebind,
    CanMakeIdentical,
    MakeRangeIdentical,
    IdentityUnify,
    IdentityResolve,

    EditionRetrieve,
    EditionCost,

    ContentSharedRegion,
    ContentMapSharedTo,
    ContentMapSharedOnto,
    PositionsOf,

    RangeTranscluders,
    RangeWorks,
    OrderedBundles,
    TransclusionDepth,

    AdminRecorderCreate,
    AdminRecorderRecord,
    AdminRecorderList,
    AdminRecorderGet,
    AdminServerHealth,
    CryptoGetPublicKey,
    CryptoSignData,
    CryptoVerifySignature,
    CryptoKeyRotation,
    CryptoKeyHistory,
    WorkEndorse,
    WorkRetract,
    WorkEndorsements,
    EditionEndorse,
    EditionRetract,
    EditionEndorsements,
    EditionVisibleEndorsements,
    EditionTotalEndorsements,

    FederationInfo,
    FederationPeers,
    FederatedTransclusionQuery,
    FederatedContentFetch,

    EndorsementSync,
    EndorsementAdd,
    EndorsementRetract,
    EndorsementQuery,
    StateSync,
    StateAlternatives,

    MembershipJoinRequest,
    MembershipJoinResponse,
    MembershipEndorseOffer,
    MembershipEndorseAccept,
    MembershipSync,
    MembershipSyncResult,
    MembershipLeave,
    MembershipList,
    MembershipVerify,

    GovernancePropose,
    GovernancePrepare,
    GovernanceCommit,
    GovernanceSeal,
    GovernanceLog,
    GovernanceStatus,

    CrdtSyncOpen,
    CrdtSyncClose,
    CrdtSyncUpdate,
    CrdtSyncDiff,
    CrdtSyncFullState,
    CrdtSyncMaterialize,
    CrdtSyncSubscriberCount,

    CrdtAwarenessUpdate,
    CrdtAwarenessGet,
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
            0x0333 => Some(OperationCode::WorkSaveAndRelease),
            0x0334 => Some(OperationCode::WorkForceRelease),
            0x0330 => Some(OperationCode::WorkRequestGrab),
            0x0331 => Some(OperationCode::WorkCancelGrabRequest),
            0x0332 => Some(OperationCode::WorkGrabWaiters),
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
            0x0317 => Some(OperationCode::WorkPublish),
            0x0318 => Some(OperationCode::WorkUnpublish),
            0x0319 => Some(OperationCode::WorkIrrevocablyUnpublish),
            0x031A => Some(OperationCode::WorkIsPublished),
            0x0314 => Some(OperationCode::WorkList),
            0x0315 => Some(OperationCode::WorkListByOwner),
            0x0316 => Some(OperationCode::WorkReviseDelta),

            0x0208 => Some(OperationCode::ClubSetDefaultReadClub),
            0x0209 => Some(OperationCode::ClubSetDefaultEditClub),

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

            0x0b01 => Some(OperationCode::LabelCreate),
            0x0b02 => Some(OperationCode::LabelGetPositions),
            0x0b03 => Some(OperationCode::EditionRelabel),
            0x0b04 => Some(OperationCode::EditionRebind),
            0x0b05 => Some(OperationCode::CanMakeIdentical),
            0x0b06 => Some(OperationCode::MakeRangeIdentical),
            0x0b07 => Some(OperationCode::IdentityUnify),
            0x0b08 => Some(OperationCode::IdentityResolve),

            0x0c01 => Some(OperationCode::EditionRetrieve),
            0x0c02 => Some(OperationCode::EditionCost),

            0x0e01 => Some(OperationCode::ContentSharedRegion),
            0x0e02 => Some(OperationCode::ContentMapSharedTo),
            0x0e03 => Some(OperationCode::ContentMapSharedOnto),
            0x0e04 => Some(OperationCode::PositionsOf),

            0x0f01 => Some(OperationCode::RangeTranscluders),
            0x0f02 => Some(OperationCode::RangeWorks),
            0x0f03 => Some(OperationCode::OrderedBundles),
            0x0f04 => Some(OperationCode::TransclusionDepth),

            0x1101 => Some(OperationCode::AdminRecorderCreate),
            0x1102 => Some(OperationCode::AdminRecorderRecord),
            0x1103 => Some(OperationCode::AdminRecorderList),
            0x1104 => Some(OperationCode::AdminRecorderGet),
            0x1105 => Some(OperationCode::AdminServerHealth),

            0x1201 => Some(OperationCode::CryptoGetPublicKey),
            0x1202 => Some(OperationCode::CryptoSignData),
            0x1203 => Some(OperationCode::CryptoVerifySignature),
            0x1204 => Some(OperationCode::CryptoKeyRotation),
            0x1205 => Some(OperationCode::CryptoKeyHistory),

            0x1301 => Some(OperationCode::WorkEndorse),
            0x1302 => Some(OperationCode::WorkRetract),
            0x1303 => Some(OperationCode::WorkEndorsements),
            0x1304 => Some(OperationCode::EditionEndorse),
            0x1305 => Some(OperationCode::EditionRetract),
            0x1306 => Some(OperationCode::EditionEndorsements),
            0x1307 => Some(OperationCode::EditionVisibleEndorsements),
            0x1308 => Some(OperationCode::EditionTotalEndorsements),

            0x1401 => Some(OperationCode::FederationInfo),
            0x1402 => Some(OperationCode::FederationPeers),
            0x1701 => Some(OperationCode::FederatedTransclusionQuery),
            0x1702 => Some(OperationCode::FederatedContentFetch),

            0x1801 => Some(OperationCode::EndorsementSync),
            0x1802 => Some(OperationCode::EndorsementAdd),
            0x1803 => Some(OperationCode::EndorsementRetract),
            0x1804 => Some(OperationCode::EndorsementQuery),
            0x1805 => Some(OperationCode::StateSync),
            0x1806 => Some(OperationCode::StateAlternatives),

            0x1901 => Some(OperationCode::MembershipJoinRequest),
            0x1902 => Some(OperationCode::MembershipJoinResponse),
            0x1903 => Some(OperationCode::MembershipEndorseOffer),
            0x1904 => Some(OperationCode::MembershipEndorseAccept),
            0x1905 => Some(OperationCode::MembershipSync),
            0x1906 => Some(OperationCode::MembershipSyncResult),
            0x1907 => Some(OperationCode::MembershipLeave),
            0x1908 => Some(OperationCode::MembershipList),
            0x1909 => Some(OperationCode::MembershipVerify),

            0x1B01 => Some(OperationCode::GovernancePropose),
            0x1B02 => Some(OperationCode::GovernancePrepare),
            0x1B03 => Some(OperationCode::GovernanceCommit),
            0x1B04 => Some(OperationCode::GovernanceSeal),
            0x1B05 => Some(OperationCode::GovernanceLog),
            0x1B06 => Some(OperationCode::GovernanceStatus),

            0x1C01 => Some(OperationCode::CrdtSyncOpen),
            0x1C02 => Some(OperationCode::CrdtSyncClose),
            0x1C03 => Some(OperationCode::CrdtSyncUpdate),
            0x1C04 => Some(OperationCode::CrdtSyncDiff),
            0x1C05 => Some(OperationCode::CrdtSyncFullState),
            0x1C06 => Some(OperationCode::CrdtSyncMaterialize),
            0x1C07 => Some(OperationCode::CrdtSyncSubscriberCount),

            0x1C08 => Some(OperationCode::CrdtAwarenessUpdate),
            0x1C09 => Some(OperationCode::CrdtAwarenessGet),

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
            OperationCode::WorkSaveAndRelease => 0x0333,
            OperationCode::WorkForceRelease  => 0x0334,
            OperationCode::WorkRequestGrab     => 0x0330,
            OperationCode::WorkCancelGrabRequest => 0x0331,
            OperationCode::WorkGrabWaiters    => 0x0332,
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
            OperationCode::WorkPublish       => 0x0317,
            OperationCode::WorkUnpublish     => 0x0318,
            OperationCode::WorkIrrevocablyUnpublish => 0x0319,
            OperationCode::WorkIsPublished        => 0x031A,

            OperationCode::ClubSetDefaultReadClub  => 0x0208,
            OperationCode::ClubSetDefaultEditClub  => 0x0209,

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

            OperationCode::LabelCreate           => 0x0b01,
            OperationCode::LabelGetPositions     => 0x0b02,
            OperationCode::EditionRelabel        => 0x0b03,
            OperationCode::EditionRebind         => 0x0b04,
            OperationCode::CanMakeIdentical      => 0x0b05,
            OperationCode::MakeRangeIdentical    => 0x0b06,
            OperationCode::IdentityUnify         => 0x0b07,
            OperationCode::IdentityResolve       => 0x0b08,

            OperationCode::EditionRetrieve => 0x0c01,
            OperationCode::EditionCost     => 0x0c02,

            OperationCode::ContentSharedRegion => 0x0e01,
            OperationCode::ContentMapSharedTo => 0x0e02,
            OperationCode::ContentMapSharedOnto => 0x0e03,
            OperationCode::PositionsOf => 0x0e04,

            OperationCode::RangeTranscluders => 0x0f01,
            OperationCode::RangeWorks => 0x0f02,
            OperationCode::OrderedBundles => 0x0f03,
            OperationCode::TransclusionDepth => 0x0f04,

            OperationCode::AdminRecorderCreate => 0x1101,
            OperationCode::AdminRecorderRecord => 0x1102,
            OperationCode::AdminRecorderList => 0x1103,
            OperationCode::AdminRecorderGet => 0x1104,
            OperationCode::AdminServerHealth => 0x1105,

            OperationCode::CryptoGetPublicKey => 0x1201,
            OperationCode::CryptoSignData => 0x1202,
            OperationCode::CryptoVerifySignature => 0x1203,
            OperationCode::CryptoKeyRotation => 0x1204,
            OperationCode::CryptoKeyHistory => 0x1205,

            OperationCode::WorkEndorse => 0x1301,
            OperationCode::WorkRetract => 0x1302,
            OperationCode::WorkEndorsements => 0x1303,
            OperationCode::EditionEndorse => 0x1304,
            OperationCode::EditionRetract => 0x1305,
            OperationCode::EditionEndorsements => 0x1306,
            OperationCode::EditionVisibleEndorsements => 0x1307,
            OperationCode::EditionTotalEndorsements => 0x1308,

            OperationCode::FederationInfo => 0x1401,
            OperationCode::FederationPeers => 0x1402,
            OperationCode::FederatedTransclusionQuery => 0x1701,
            OperationCode::FederatedContentFetch => 0x1702,

            OperationCode::EndorsementSync => 0x1801,
            OperationCode::EndorsementAdd => 0x1802,
            OperationCode::EndorsementRetract => 0x1803,
            OperationCode::EndorsementQuery => 0x1804,
            OperationCode::StateSync => 0x1805,
            OperationCode::StateAlternatives => 0x1806,

            OperationCode::MembershipJoinRequest => 0x1901,
            OperationCode::MembershipJoinResponse => 0x1902,
            OperationCode::MembershipEndorseOffer => 0x1903,
            OperationCode::MembershipEndorseAccept => 0x1904,
            OperationCode::MembershipSync => 0x1905,
            OperationCode::MembershipSyncResult => 0x1906,
            OperationCode::MembershipLeave => 0x1907,
            OperationCode::MembershipList => 0x1908,
            OperationCode::MembershipVerify => 0x1909,

            OperationCode::GovernancePropose => 0x1B01,
            OperationCode::GovernancePrepare => 0x1B02,
            OperationCode::GovernanceCommit => 0x1B03,
            OperationCode::GovernanceSeal => 0x1B04,
            OperationCode::GovernanceLog => 0x1B05,
            OperationCode::GovernanceStatus => 0x1B06,

            OperationCode::CrdtSyncOpen => 0x1C01,
            OperationCode::CrdtSyncClose => 0x1C02,
            OperationCode::CrdtSyncUpdate => 0x1C03,
            OperationCode::CrdtSyncDiff => 0x1C04,
            OperationCode::CrdtSyncFullState => 0x1C05,
            OperationCode::CrdtSyncMaterialize => 0x1C06,
            OperationCode::CrdtSyncSubscriberCount => 0x1C07,

            OperationCode::CrdtAwarenessUpdate => 0x1C08,
            OperationCode::CrdtAwarenessGet => 0x1C09,
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
    WorkSaveAndRelease { work_id: BeId, edition: EditionPayload },
    WorkForceRelease { work_id: BeId },
    WorkIsGrabbed { work_id: BeId },
    WorkGrabber { work_id: BeId },
    WorkRequestGrab { work_id: BeId },
    WorkCancelGrabRequest { work_id: BeId },
    WorkGrabWaiters { work_id: BeId },
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
    WorkPublish { work_id: BeId },
    WorkUnpublish { work_id: BeId },
    WorkIrrevocablyUnpublish { work_id: BeId },
    WorkIsPublished { work_id: BeId },

    ClubSetDefaultReadClub { club_id: BeId, default_read_club: Option<BeId> },
    ClubSetDefaultEditClub { club_id: BeId, default_edit_club: Option<BeId> },

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
    FindSharedRegions { work_a: BeId, work_b: BeId, filter_text: Option<String> },

    ServerStats,

    BlobUpload { data: String, mime_type: String },
    BlobGet { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] content_hash: u64 },
    BlobGetPreview { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] content_hash: u64 },
    BlobExists { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] content_hash: u64 },
    BlobInfo { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] content_hash: u64 },
    BlobStats,
    OverlayApply { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] base_hash: u64, ops: Vec<ImageOp>, mime_type: String },
    OverlayGet { #[serde(serialize_with = "u64_hex::serialize", deserialize_with = "u64_hex::deserialize")] overlay_hash: u64 },

    LabelCreate,
    LabelGetPositions { work_id: BeId, label_id: u64 },
    EditionRelabel { work_id: BeId, label_id: u64 },
    EditionRebind { work_id: BeId, position: i64, new_edition: EditionPayload },
    CanMakeIdentical { source_work_id: BeId, target_work_id: BeId, position: Option<i64> },
    MakeRangeIdentical { source_work_id: BeId, target_work_id: BeId, region: Option<XnRegion> },
    IdentityUnify { source_id: u64, target_id: u64 },
    IdentityResolve { id: u64 },

    EditionRetrieve { work_id: BeId, region: Option<XnRegion>, flags: Option<RetrieveFlagsPayload> },
    EditionCost { work_id: BeId, method: Option<String> },

    ContentSharedRegion { work_a: BeId, work_b: BeId },
    ContentMapSharedTo { work_a: BeId, work_b: BeId },
    ContentMapSharedOnto { work_a: BeId, work_b: BeId },
    PositionsOf { work_id: BeId, element: RangeElement },

    RangeTranscluders { work_id: BeId, region: Option<XnRegion>, direct_only: Option<bool> },
    RangeWorks { work_id: BeId, region: Option<XnRegion> },
    OrderedBundles { work_id: BeId, region: Option<XnRegion> },
    TransclusionDepth { work_id: BeId, position: i64, max_depth: Option<usize> },

    AdminRecorderCreate { kind: String, direct_only: Option<bool>, region: Option<XnRegion> },
    AdminRecorderRecord { recorder_id: u64, element: RangeElement },
    AdminRecorderList,
    AdminRecorderGet { recorder_id: u64 },
    AdminServerHealth,
    CryptoGetPublicKey,
    CryptoSignData { data: Vec<u8> },
    CryptoVerifySignature { data: Vec<u8>, signature: Vec<u8> },
    CryptoKeyRotation,
    CryptoKeyHistory,
    WorkEndorse { work_id: BeId, endorsements: Vec<(u64, u64)> },
    WorkRetract { work_id: BeId, endorsements: Vec<(u64, u64)> },
    WorkEndorsements { work_id: BeId },
    EditionEndorse { edition_id: BeId, endorsements: Vec<(u64, u64)> },
    EditionRetract { edition_id: BeId, endorsements: Vec<(u64, u64)> },
    EditionEndorsements { edition_id: BeId },
    EditionVisibleEndorsements { edition_id: BeId },
    EditionTotalEndorsements { edition_id: BeId },

    FederationInfo,
    FederationPeers,
    FederatedTransclusionQuery { content_fingerprint_hex: String, direct_only: bool },
    FederatedContentFetch { content_fingerprint_hex: String },

    EndorsementSync { work_fingerprint: String },
    EndorsementAdd { work_fingerprint: String, club_id: u64, token_id: u64 },
    EndorsementRetract { work_fingerprint: String, club_id: u64, token_id: u64 },
    EndorsementQuery { work_fingerprint: String },
    StateSync { work_fingerprints: Vec<String> },
    StateAlternatives { work_fingerprint: String },

    MembershipJoinRequest {
        entry: crate::server::federation::MembershipEntry,
    },
    MembershipEndorseOffer {
        server_id: String,
        proof: crate::server::federation::EndorsementProof,
    },
    MembershipEndorseAccept {
        server_id: String,
    },
    MembershipSync,
    MembershipLeave,
    MembershipList,
    MembershipVerify {
        server_id: String,
    },

    GovernancePropose {
        transactions: Vec<crate::server::federation::GovernanceTx>,
    },
    GovernancePrepare {
        vote: crate::server::federation::PbftVote,
    },
    GovernanceCommit {
        vote: crate::server::federation::PbftVote,
    },
    GovernanceSeal,
    GovernanceLog,
    GovernanceStatus,

    CrdtSyncOpen { work_id: BeId },
    CrdtSyncClose { work_id: BeId },
    CrdtSyncUpdate { work_id: BeId, update: Vec<u8> },
    CrdtSyncDiff { work_id: BeId, state_vector: Vec<u8> },
    CrdtSyncFullState { work_id: BeId },
    CrdtSyncMaterialize { work_id: BeId },
    CrdtSyncSubscriberCount { work_id: BeId },

    CrdtAwarenessUpdate { work_id: BeId, state: crate::server::crdt_manager::AwarenessState },
    CrdtAwarenessGet { work_id: BeId },
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
    LabelInfo { label_id: u64 },
    LabelPositions { label_id: u64, positions: XnRegion },
    CanMakeIdenticalResult { result: String },
    MakeRangeIdenticalResult { outcome: String, failed_count: u64, failed: EditionPayload },
    IdentityResolveResult { resolved_id: u64 },
    BundleResults { bundles: Vec<BundlePayload> },
    StorageCostResult { total_bytes: u64, unique_bytes: u64, shared_bytes: u64, share_count: u64, billed_bytes: u64, method: String },
    SharedRegionResult { region: XnRegion },
    SharedMappingResult { pairs: Vec<(i64, i64)> },
    PositionsOfResult { region: XnRegion },
    RangeTranscludersResult { edition_ids: Vec<BeId>, work_ids: Vec<BeId>, region: XnRegion },
    RangeWorksResult { work_ids: Vec<BeId>, region: XnRegion },
    OrderedBundlesResult { bundles: Vec<BundlePayload> },
    TransclusionDepthResult { depth: usize },
    RecorderCreateResult { recorder_id: u64 },
    RecorderRecordResult { recorded: bool },
    RecorderListResult { recorders: Vec<RecorderInfoPayload> },
    RecorderGetResult { recorder: Option<RecorderInfoPayload> },
    ServerHealthResult {
        operation_count: u64,
        active_recorders: usize,
        total_recorded: usize,
        blob_count: usize,
        link_count: usize,
        uptime_secs: u64,
    },
    CryptoPublicKeyResult {
        key_id: u64,
        verifying_key: Vec<u8>,
        kex_key: Vec<u8>,
        server_id: String,
    },
    CryptoSignResult {
        signature: Vec<u8>,
        key_id: u64,
    },
    CryptoVerifyResult {
        valid: bool,
    },
    CryptoKeyRotationResult {
        new_key_id: u64,
    },
    CryptoKeyHistoryResult {
        server_id: String,
        current_key_id: u64,
        entry_count: usize,
        entries: Vec<KeyHistoryEntryPayload>,
    },
    EndorsementResult { endorsements: Vec<(u64, u64)> },
    FederationInfoResult {
        server_id: String,
        federation_domain: String,
        key_id: u64,
        verifying_key: Vec<u8>,
        kex_key: Vec<u8>,
        mode: String,
        peers: Vec<FederationPeerPayload>,
        work_count: usize,
        edition_count: usize,
    },
    FederationPeersResult {
        peers: Vec<String>,
    },
    FederatedTransclusionResult {
        results: Vec<crate::server::federation::FederatedTransclusionEntry>,
    },
    FederatedContentFetchResult {
        found: bool,
        edition_payload: Option<EditionPayload>,
        blob_data: Option<String>,
        blob_mime_type: Option<String>,
    },

    EndorsementSyncResult {
        endorsements: Vec<(u64, u64, String)>,
        tombstones: Vec<(u64, u64, String)>,
    },
    EndorsementAddResult {
        tag_server_id: String,
        tag_counter: u64,
    },
    EndorsementRetractResult {},
    EndorsementQueryResult {
        endorsements: Vec<(u64, u64, String)>,
        tombstones: Vec<(u64, u64, String)>,
    },
    StateSyncResult {
        states: Vec<crate::server::federation::ReconcileState>,
    },
    StateAlternativesResult {
        alternatives: Vec<crate::server::federation::AlternativeEdition>,
        current_key: String,
    },

    MembershipJoinResult {
        result: crate::server::federation::JoinResult,
    },
    MembershipEndorseOfferResult {
        accepted: bool,
    },
    MembershipEndorseAcceptResult {},
    MembershipSyncResult {
        members: Vec<crate::server::federation::MembershipEntry>,
    },
    MembershipLeaveResult {},
    MembershipListResult {
        members: Vec<crate::server::federation::MembershipEntry>,
    },
    MembershipVerifyResult {
        verify: crate::server::federation::MembershipVerifyResult,
    },

    GovernanceProposeResult {
        proposal: Option<crate::server::federation::GovernanceProposal>,
    },
    GovernancePrepareResult {
        phase: String,
    },
    GovernanceCommitResult {
        phase: String,
    },
    GovernanceSealResult {
        batch: Option<crate::server::federation::SealedBatch>,
    },
    GovernanceLogResult {
        log: Vec<crate::server::federation::SealedBatch>,
    },
    GovernanceStatusResult {
        view: u64,
        sequence: u64,
        cluster_size: usize,
        quorum: usize,
        is_leader: bool,
        leader_id: Option<String>,
        pending: bool,
    },

    CrdtSyncOpenResult {
        state_vector: Vec<u8>,
        current_text: String,
    },
    CrdtSyncUpdateResult {
        relay_count: usize,
    },
    CrdtSyncDiffResult {
        update: Vec<u8>,
    },
    CrdtSyncFullStateResult {
        state: Vec<u8>,
    },
    CrdtSyncMaterializeResult {
        revision: u64,
    },
    CrdtSyncSubscriberCountResult {
        count: usize,
    },

    CrdtAwarenessUpdateResult {
        relay_count: usize,
    },
    CrdtAwarenessGetResult {
        states: Vec<crate::server::crdt_manager::AwarenessState>,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KeyHistoryEntryPayload {
    pub key_id: u64,
    pub not_before: u64,
    pub not_after: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FederationPeerPayload {
    pub server_id: String,
    pub address: String,
    pub connected: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RetrieveFlagsPayload {
    pub ignore_total_ordering: Option<bool>,
    pub ignore_array_ordering: Option<bool>,
    pub separate_owners: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum BundlePayload {
    Element { region: XnRegion, element: RangeElement },
    Array { region: XnRegion, elements: Vec<RangeElement> },
    PlaceHolder { region: XnRegion },
}

impl BundlePayload {
    pub fn from_bundle(bundle: &Bundle) -> Self {
        match bundle {
            Bundle::Element { region, element } => BundlePayload::Element {
                region: region.clone(),
                element: element.clone(),
            },
            Bundle::Array { region, elements } => BundlePayload::Array {
                region: region.clone(),
                elements: elements.clone(),
            },
            Bundle::PlaceHolder { region } => BundlePayload::PlaceHolder {
                region: region.clone(),
            },
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkListEntry {
    pub work_id: BeId,
    pub owner: Option<BeId>,
    pub revision_count: u64,
    pub is_grabbed: bool,
    #[serde(default, skip_serializing_if = "String::is_empty")]
    pub title: String,
    #[serde(default)]
    pub read_club: Option<BeId>,
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
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub path_context: Option<Vec<RangeElementPayload>>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub excerpt: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RangeElementPayload {
    #[serde(rename = "type")]
    pub elem_type: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub text: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub label_id: Option<BeId>,
}

impl RangeElementPayload {
    pub fn from_range_element(re: &crate::edition::RangeElement) -> Self {
        match re {
            crate::edition::RangeElement::Text { text } => RangeElementPayload {
                elem_type: "text".to_string(),
                text: Some(text.clone()),
                label_id: None,
            },
            crate::edition::RangeElement::Label { label_id, inner } => RangeElementPayload {
                elem_type: "label".to_string(),
                text: inner.as_text().map(|s| s.to_string()),
                label_id: Some(label_id.0),
            },
            _ => RangeElementPayload {
                elem_type: "other".to_string(),
                text: None,
                label_id: None,
            },
        }
    }
}

impl HyperRefPayload {
    pub fn from_hyper_ref(hr: &crate::edition::links::HyperRef) -> Self {
        let path_context = hr.path_context().map(|p| {
            p.labels().iter().map(RangeElementPayload::from_range_element).collect()
        });
        let excerpt = hr.excerpt().and_then(|ed| {
            let entries = ed.all_entries();
            let text: String = entries.iter()
                .filter_map(|(_, c)| c.element.as_text())
                .collect();
            if text.is_empty() { None } else { Some(text) }
        });
        HyperRefPayload {
            kind: if hr.is_single() { "single".to_string() } else { "multi".to_string() },
            work_context: hr.work_context(),
            original_context: hr.original_context(),
            path_context,
            excerpt,
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecorderInfoPayload {
    pub id: u64,
    pub kind: String,
    pub direct_only: bool,
    pub result_count: usize,
    pub is_extinct: bool,
    pub reference_count: u64,
    pub created_at: u64,
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
    Unauthorized,
    ServerShuttingDown,
    NotAcceptingConnections,
    IrrevocablyRemoved,
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
            crate::server::ServerError::Unauthorized(_) => ErrorCode::Unauthorized,
            crate::server::ServerError::ServerShuttingDown => ErrorCode::ServerShuttingDown,
            crate::server::ServerError::NotAcceptingConnections => ErrorCode::NotAcceptingConnections,
            crate::server::ServerError::ReadClubIrrevocablyRemoved(_) => ErrorCode::IrrevocablyRemoved,
            crate::server::ServerError::NotOwner(_) => ErrorCode::NotAuthorized,
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
