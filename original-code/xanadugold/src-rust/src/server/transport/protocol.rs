use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use crate::edition::{BeId, Bundle, Edition, ImageOp, RangeElement, XnRegion};
use crate::server::lock::LockCredential;

pub const PROTOCOL_VERSION: u8 = 0x02;
pub const MIN_SUPPORTED_VERSION: u8 = 0x01;

#[cfg(feature = "serde")]
fn deserialize_u64_flexible<'de, D>(deserializer: D) -> Result<u64, D::Error>
where
    D: serde::Deserializer<'de>,
{
    use serde::de::Error;
    #[derive(Deserialize)]
    #[cfg_attr(feature = "serde", serde(untagged))]
    enum NumOrStr {
        Num(u64),
        Str(String),
    }
    match NumOrStr::deserialize(deserializer)? {
        NumOrStr::Num(n) => Ok(n),
        NumOrStr::Str(s) => {
            if let Some(hex) = s.strip_prefix("0x") {
                u64::from_str_radix(hex, 16)
                    .map_err(|e| Error::custom(format!("invalid hex u64: {}", e)))
            } else {
                s.parse::<u64>()
                    .map_err(|e| Error::custom(format!("invalid u64: {}", e)))
            }
        }
    }
}

fn deserialize_optional_u64_string<'de, D>(deserializer: D) -> Result<Option<u64>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    use serde::de::Error;
    let opt: Option<serde_json::Value> = Option::deserialize(deserializer)?;
    match opt {
        None | Some(serde_json::Value::Null) => Ok(None),
        Some(serde_json::Value::String(s)) => {
            if let Some(hex) = s.strip_prefix("0x") {
                u64::from_str_radix(hex, 16)
                    .map(Some)
                    .map_err(|e| Error::custom(format!("invalid hex u64: {}", e)))
            } else {
                s.parse::<u64>()
                    .map(Some)
                    .map_err(|e| Error::custom(format!("invalid u64: {}", e)))
            }
        }
        Some(serde_json::Value::Number(n)) => n
            .as_u64()
            .map(Some)
            .ok_or_else(|| Error::custom("u64 value out of range")),
        Some(v) => v
            .to_string()
            .parse::<u64>()
            .map(Some)
            .map_err(|e| Error::custom(format!("invalid u64: {}", e))),
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum MessageType {
    Handshake = 0x00,
    Request = 0x01,
    Response = 0x02,
    Error = 0x03,
    Event = 0x04,
    Subscribe = 0x05,
    Unsubscribe = 0x06,
    Heartbeat = 0x07,
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
#[cfg_attr(feature = "serde", serde(rename_all = "snake_case"))]
pub enum OperationCode {
    SessionConnect,
    SessionDisconnect,
    SessionLogin,
    SessionLoginByName,
    SessionAuthenticate,
    SessionLoginPublic,
    SessionTicketIssue,
    SessionTicketRedeem,

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
    WorkSetHistoryClub,
    WorkReadClub,
    WorkEditClub,
    WorkHistoryClub,
    WorkTransclusionChain,
    WorkRevisionCount,
    WorkFetchRevision,
    WorkSponsor,
    WorkUnsponsor,
    WorkSponsors,
    WorkStar,
    WorkSetSource,
    WebFetchSanitize,
    WorkUnstar,
    WorkIsStarred,
    ConnectionPinSet,
    ConnectionPinUnset,
    ConnectionPinsGet,
    CrossServerBacklinksGet,
    WorkGraph,
    WorkKindGet,
    WorkKindSet,
    WorkLicenseGet,
    WorkLicenseSet,
    WorkListByKind,
    WorkSetText,
    WorkRevisionsList,
    WorkBlobList,
    WorkTextAtRevision,
    WorkRevisionDescribe,
    WorkRevisionMarkNotable,
    WorkRevisionRollback,
    TrailCreate,
    TrailDelete,
    TrailRename,
    TrailAddStop,
    TrailRemoveStop,
    TrailReorderStops,
    TrailList,
    TrailGet,
    WorkOwner,
    WorkPublish,
    WorkUnpublish,
    WorkIrrevocablyUnpublish,
    WorkArchive,
    WorkUnarchive,
    WorkListArchived,
    WorkIsPublished,
    WorkMerge,
    WorkGhost,

    WorkFetchRevisionRange,

    ClubSetDefaultReadClub,
    ClubSetDefaultEditClub,

    ClubSetPassword,
    ClubClearCredential,
    ClubCreatePersonal,
    ClubWhoAmI,
    ClubAddMember,
    ClubRemoveMember,
    ClubMembers,
    ClubRoster,

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
    WorkDiffNarration,
    WorkWritingFeedback,
    WorkSuggestTitle,
    WorkSetTitle,
    WorkAutoTag,
    WorkBacklinks,

    LinkCreate,
    LinkGet,
    LinkUpdate,
    LinkDelete,
    LinkListForWork,
    LinkAddEnd,
    LinkRemoveEnd,
    LinkSetTypes,
    LinkTypeRegister,
    LinkTypeList,
    LinkQuery,

    FindExcerptPositions,

    FindTranscluders,
    FindWorksForContent,
    FindTextTranscluders,
    FindSharedRegions,
    WorkDiffRegions,

    ServerStats,
    MetricsSnapshot,

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
    ElementInsert,
    TransclusionPlaceCrossServer,
    CrossServerSpanRefresh,
    ElementUpdate,
    RenderTransclusions,

    AnnotationCreate,
    AnnotationDelete,
    AnnotationAttachNode,
    AnnotationAttachSpan,
    AnnotationGet,
    AnnotationList,

    ContentSharedRegion,
    ContentMapSharedTo,
    ContentMapSharedOnto,
    PositionsOf,

    RangeTranscluders,
    RangeWorks,
    OrderedBundles,
    TransclusionDepth,

    VersionIsBefore,
    VersionAncestors,
    VersionDescendants,
    VersionTracePosition,

    ProvenanceAncestry,

    AdminRecorderCreate,
    AdminRecorderRecord,
    AdminRecorderList,
    AdminRecorderGet,
    AdminServerHealth,
    ResolveInlineTransclusions,
    MigrateCompoundToInline,
    ElementRemoveTransclusion,
    AttributionQueryResolved,
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
    CrdtSyncText,

    CrdtAwarenessUpdate,
    CrdtAwarenessGet,

    CrdtRegisterAuthor,

    AttributionQuery,
    AttributionVerify,
    AttributionLogStatus,
    AttestationReport,
    WorkTextRange,
    WorkOutline,
    WorkSearch,
    WorkGoto,

    #[cfg(feature = "serde")]
    ProvJsonExport,
    #[cfg(feature = "serde")]
    ServerDirectoryList,
    #[cfg(feature = "serde")]
    ServerDirectoryAdd,
    #[cfg(feature = "serde")]
    ServerDirectoryRemove,
    #[cfg(feature = "serde")]
    ServerDirectorySetTrust,
    NetworkSetEnabled,
    ExternalLinksSetEnabled,
    #[cfg(feature = "serde")]
    CrossServerResolve,
    #[cfg(feature = "serde")]
    CrossServerFetchWork,
    #[cfg(feature = "serde")]
    CrossServerListWorks,
    #[cfg(feature = "serde")]
    FederatedSearch,
    #[cfg(feature = "serde")]
    FetchIntroductions,
    #[cfg(feature = "serde")]
    AddDiscoveredServer,
    #[cfg(feature = "serde")]
    CrossServerLinkCreate,
    #[cfg(feature = "serde")]
    CrossServerLinkList,
    #[cfg(feature = "serde")]
    FetchRemoteIdentity,
    #[cfg(feature = "serde")]
    TumblerResolve,
    #[cfg(feature = "serde")]
    BloomFilterGet,
    #[cfg(feature = "serde")]
    BloomFilterCheck,
    #[cfg(feature = "serde")]
    FederationAttestationCreate,
    #[cfg(feature = "serde")]
    FederationAttestationVerify,
    #[cfg(feature = "serde")]
    FederationBundleExport,
    #[cfg(feature = "serde")]
    ClusterVerificationCreate,
    #[cfg(feature = "serde")]
    CrossServerSignatureVerify,

    HistoricalAuthorRegister,
    HistoricalAuthorGet,
    HistoricalAuthorSearch,
    HistoricalAuthorList,

    ImportSourceWork,
    ImportEpub,

    SourceDetect,
    SourcePatternList,
    WorkListByAuthor,
    ContentMatch,
    WorkApplySourceAttribution,
    WorkApplyTransclusionAttribution,

    WorkSummary,
    WorkVersionTimeline,
    PassageComposition,
    GlobalTextSearch,
    SeedDemoAttribution,

    TrailUpdate,
    TrailPublish,
    TrailUnpublish,
    TrailListPublished,
    TrailListCategories,
    TrailDerivedWork,
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
            0x0007 => Some(OperationCode::SessionTicketIssue),
            0x0008 => Some(OperationCode::SessionTicketRedeem),

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
            0x031F => Some(OperationCode::WorkSetHistoryClub),
            0x030C => Some(OperationCode::WorkReadClub),
            0x030D => Some(OperationCode::WorkEditClub),
            0x0320 => Some(OperationCode::WorkHistoryClub),
            0x0321 => Some(OperationCode::WorkTransclusionChain),
            0x030E => Some(OperationCode::WorkRevisionCount),
            0x030F => Some(OperationCode::WorkFetchRevision),
            0x0310 => Some(OperationCode::WorkSponsor),
            0x0311 => Some(OperationCode::WorkUnsponsor),
            0x0312 => Some(OperationCode::WorkSponsors),
            0x0313 => Some(OperationCode::WorkOwner),
            0x0317 => Some(OperationCode::WorkPublish),
            0x0318 => Some(OperationCode::WorkUnpublish),
            0x0319 => Some(OperationCode::WorkIrrevocablyUnpublish),
            0x031C => Some(OperationCode::WorkArchive),
            0x031D => Some(OperationCode::WorkUnarchive),
            0x031E => Some(OperationCode::WorkListArchived),
            0x0322 => Some(OperationCode::WorkMerge),
            0x0323 => Some(OperationCode::WorkGhost),
            0x031A => Some(OperationCode::WorkIsPublished),
            0x031B => Some(OperationCode::WorkFetchRevisionRange),
            0x0314 => Some(OperationCode::WorkList),
            0x0315 => Some(OperationCode::WorkListByOwner),
            0x0316 => Some(OperationCode::WorkReviseDelta),
            0x0335 => Some(OperationCode::WorkStar),
            0x0351 => Some(OperationCode::WorkSetSource),
            0x0352 => Some(OperationCode::WebFetchSanitize),
            0x0336 => Some(OperationCode::WorkUnstar),
            0x0337 => Some(OperationCode::WorkIsStarred),
            0x0338 => Some(OperationCode::WorkGraph),
            0x0B01 => Some(OperationCode::WorkKindGet),
            0x0B02 => Some(OperationCode::WorkKindSet),
            0x0B05 => Some(OperationCode::WorkLicenseGet),
            0x0B06 => Some(OperationCode::WorkLicenseSet),
            0x0B03 => Some(OperationCode::WorkListByKind),
            0x0B04 => Some(OperationCode::WorkSetText),
            0x0C01 => Some(OperationCode::WorkRevisionsList),
            0x0C07 => Some(OperationCode::WorkBlobList),
            0x0C02 => Some(OperationCode::WorkTextAtRevision),
            0x0C03 => Some(OperationCode::WorkRevisionDescribe),
            0x0C04 => Some(OperationCode::WorkRevisionMarkNotable),
            0x0C05 => Some(OperationCode::WorkRevisionRollback),
            0x0339 => Some(OperationCode::TrailCreate),
            0x033a => Some(OperationCode::TrailDelete),
            0x033b => Some(OperationCode::TrailRename),
            0x033c => Some(OperationCode::TrailAddStop),
            0x033d => Some(OperationCode::TrailRemoveStop),
            0x033e => Some(OperationCode::TrailReorderStops),
            0x033f => Some(OperationCode::TrailList),
            0x0340 => Some(OperationCode::TrailGet),
            0x0344 => Some(OperationCode::TrailUpdate),
            0x0345 => Some(OperationCode::TrailPublish),
            0x0346 => Some(OperationCode::TrailUnpublish),
            0x0347 => Some(OperationCode::TrailListPublished),
            0x0348 => Some(OperationCode::TrailListCategories),
            0x0349 => Some(OperationCode::TrailDerivedWork),
            0x0349 => Some(OperationCode::ConnectionPinSet),
            0x034a => Some(OperationCode::ConnectionPinUnset),
            0x034b => Some(OperationCode::ConnectionPinsGet),
            0x034c => Some(OperationCode::CrossServerBacklinksGet),
            0x0341 => Some(OperationCode::WorkDiffNarration),
            0x0342 => Some(OperationCode::WorkWritingFeedback),
            0x034e => Some(OperationCode::WorkSuggestTitle),
            0x034f => Some(OperationCode::WorkSetTitle),
            0x0350 => Some(OperationCode::WorkAutoTag),
            0x0343 => Some(OperationCode::WorkBacklinks),

            0x0208 => Some(OperationCode::ClubSetDefaultReadClub),
            0x0209 => Some(OperationCode::ClubSetDefaultEditClub),
            0x020A => Some(OperationCode::ClubSetPassword),
            0x020B => Some(OperationCode::ClubClearCredential),
            0x020C => Some(OperationCode::ClubCreatePersonal),
            0x020D => Some(OperationCode::ClubWhoAmI),
            0x020E => Some(OperationCode::ClubAddMember),
            0x020F => Some(OperationCode::ClubRemoveMember),
            0x0210 => Some(OperationCode::ClubMembers),
            0x0211 => Some(OperationCode::ClubRoster),

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
            0x0706 => Some(OperationCode::FindExcerptPositions),
            0x0707 => Some(OperationCode::LinkAddEnd),
            0x0708 => Some(OperationCode::LinkRemoveEnd),
            0x0709 => Some(OperationCode::LinkSetTypes),
            0x070A => Some(OperationCode::LinkTypeRegister),
            0x070B => Some(OperationCode::LinkTypeList),
            0x070C => Some(OperationCode::LinkQuery),

            0x0801 => Some(OperationCode::FindTranscluders),
            0x0802 => Some(OperationCode::FindWorksForContent),
            0x0803 => Some(OperationCode::FindTextTranscluders),
            0x0804 => Some(OperationCode::FindSharedRegions),
            0x0805 => Some(OperationCode::WorkDiffRegions),

            0x0805 => Some(OperationCode::ProvenanceAncestry),

            0x0601 => Some(OperationCode::ServerStats),
            0x0602 => Some(OperationCode::MetricsSnapshot),

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
            0x0c0B => Some(OperationCode::ElementInsert),
            0x0c0C => Some(OperationCode::TransclusionPlaceCrossServer),
            0x0c0D => Some(OperationCode::CrossServerSpanRefresh),
            0x0c0C => Some(OperationCode::ElementUpdate),
            0x0c0C => Some(OperationCode::RenderTransclusions),
            0x0c03 => Some(OperationCode::AnnotationCreate),
            0x0c04 => Some(OperationCode::AnnotationDelete),
            0x0c05 => Some(OperationCode::AnnotationAttachNode),
            0x0c06 => Some(OperationCode::AnnotationAttachSpan),
            0x0c09 => Some(OperationCode::AnnotationGet),
            0x0c0A => Some(OperationCode::AnnotationList),

            0x0e01 => Some(OperationCode::ContentSharedRegion),
            0x0e02 => Some(OperationCode::ContentMapSharedTo),
            0x0e03 => Some(OperationCode::ContentMapSharedOnto),
            0x0e04 => Some(OperationCode::PositionsOf),

            0x0f01 => Some(OperationCode::RangeTranscluders),
            0x0f02 => Some(OperationCode::RangeWorks),
            0x0f03 => Some(OperationCode::OrderedBundles),
            0x0f04 => Some(OperationCode::TransclusionDepth),

            0x1001 => Some(OperationCode::VersionIsBefore),
            0x1002 => Some(OperationCode::VersionAncestors),
            0x1003 => Some(OperationCode::VersionDescendants),
            0x1004 => Some(OperationCode::VersionTracePosition),

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
            0x1C0A => Some(OperationCode::CrdtSyncText),

            0x1C08 => Some(OperationCode::CrdtAwarenessUpdate),
            0x1C09 => Some(OperationCode::CrdtAwarenessGet),

            0x1C0B => Some(OperationCode::CrdtRegisterAuthor),

            0x1E01 => Some(OperationCode::ResolveInlineTransclusions),
            0x1E02 => Some(OperationCode::MigrateCompoundToInline),
            0x1E03 => Some(OperationCode::ElementRemoveTransclusion),
            0x1E04 => Some(OperationCode::AttributionQueryResolved),

            0x0D01 => Some(OperationCode::AttributionQuery),
            0x0D02 => Some(OperationCode::AttributionVerify),
            0x0D03 => Some(OperationCode::AttributionLogStatus),
            0x0D0B => Some(OperationCode::AttestationReport),
            0x0D04 => Some(OperationCode::WorkTextRange),
            0x0D05 => Some(OperationCode::WorkOutline),
            0x0D06 => Some(OperationCode::WorkSearch),
            0x0D07 => Some(OperationCode::WorkGoto),

            0x0D08 => Some(OperationCode::HistoricalAuthorRegister),
            0x0D09 => Some(OperationCode::HistoricalAuthorGet),
            0x0D0A => Some(OperationCode::HistoricalAuthorSearch),
            0x0D0B => Some(OperationCode::HistoricalAuthorList),

            0x0D0C => Some(OperationCode::ImportSourceWork),
            0x0D0D => Some(OperationCode::ImportEpub),

            0x0D0D => Some(OperationCode::SourceDetect),
            0x0D0E => Some(OperationCode::SourcePatternList),
            0x0D0F => Some(OperationCode::WorkListByAuthor),
            0x0D10 => Some(OperationCode::ContentMatch),
            0x0D11 => Some(OperationCode::WorkApplySourceAttribution),
            0x0D12 => Some(OperationCode::WorkApplyTransclusionAttribution),

            0x0D13 => Some(OperationCode::WorkSummary),
            0x0D14 => Some(OperationCode::WorkVersionTimeline),
            0x0D15 => Some(OperationCode::PassageComposition),
            0x0D16 => Some(OperationCode::GlobalTextSearch),
            0x0D17 => Some(OperationCode::SeedDemoAttribution),

            #[cfg(feature = "serde")]
            0x0F01 => Some(OperationCode::ServerDirectoryList),
            #[cfg(feature = "serde")]
            0x0F02 => Some(OperationCode::ServerDirectoryAdd),
            #[cfg(feature = "serde")]
            0x0F03 => Some(OperationCode::ServerDirectoryRemove),
            #[cfg(feature = "serde")]
            0x0F04 => Some(OperationCode::ServerDirectorySetTrust),
            #[cfg(feature = "serde")]
            0x0F05 => Some(OperationCode::CrossServerResolve),
            #[cfg(feature = "serde")]
            0x0F06 => Some(OperationCode::CrossServerFetchWork),
            #[cfg(feature = "serde")]
            0x0F07 => Some(OperationCode::CrossServerListWorks),
            #[cfg(feature = "serde")]
            0x0F08 => Some(OperationCode::FederatedSearch),
            #[cfg(feature = "serde")]
            0x0F09 => Some(OperationCode::FetchIntroductions),
            #[cfg(feature = "serde")]
            0x0F0A => Some(OperationCode::AddDiscoveredServer),
            #[cfg(feature = "serde")]
            0x0F0B => Some(OperationCode::CrossServerLinkCreate),
            #[cfg(feature = "serde")]
            0x0F0C => Some(OperationCode::CrossServerLinkList),
            #[cfg(feature = "serde")]
            0x0F0D => Some(OperationCode::FetchRemoteIdentity),
            0x0F0E => Some(OperationCode::TumblerResolve),
            0x0F0F => Some(OperationCode::BloomFilterGet),
            0x0F10 => Some(OperationCode::BloomFilterCheck),
            0x0F11 => Some(OperationCode::NetworkSetEnabled),
            0x0F12 => Some(OperationCode::ExternalLinksSetEnabled),

            _ => None,
        }
    }

    pub fn to_u16(self) -> u16 {
        match self {
            OperationCode::SessionConnect => 0x0001,
            OperationCode::SessionDisconnect => 0x0002,
            OperationCode::SessionLogin => 0x0003,
            OperationCode::SessionLoginByName => 0x0004,
            OperationCode::SessionAuthenticate => 0x0005,
            OperationCode::SessionLoginPublic => 0x0006,
            OperationCode::SessionTicketIssue => 0x0007,
            OperationCode::SessionTicketRedeem => 0x0008,

            OperationCode::ServerGetById => 0x0101,
            OperationCode::ServerGetByBeId => 0x0102,

            OperationCode::ClubCreate => 0x0201,
            OperationCode::ClubCreateNamed => 0x0202,
            OperationCode::ClubGet => 0x0203,
            OperationCode::ClubByName => 0x0204,
            OperationCode::ClubIdByName => 0x0205,
            OperationCode::ClubNameById => 0x0206,
            OperationCode::ClubNames => 0x0207,

            OperationCode::WorkCreate => 0x0301,
            OperationCode::WorkGetEdition => 0x0302,
            OperationCode::WorkRevise => 0x0303,
            OperationCode::WorkGrab => 0x0304,
            OperationCode::WorkRelease => 0x0305,
            OperationCode::WorkIsGrabbed => 0x0306,
            OperationCode::WorkGrabber => 0x0307,
            OperationCode::WorkCanRead => 0x0308,
            OperationCode::WorkSaveAndRelease => 0x0333,
            OperationCode::WorkForceRelease => 0x0334,
            OperationCode::WorkRequestGrab => 0x0330,
            OperationCode::WorkCancelGrabRequest => 0x0331,
            OperationCode::WorkGrabWaiters => 0x0332,
            OperationCode::WorkCanRevise => 0x0309,
            OperationCode::WorkSetReadClub => 0x030A,
            OperationCode::WorkSetEditClub => 0x030B,
            OperationCode::WorkSetHistoryClub => 0x031F,
            OperationCode::WorkReadClub => 0x030C,
            OperationCode::WorkEditClub => 0x030D,
            OperationCode::WorkHistoryClub => 0x0320,
            OperationCode::WorkTransclusionChain => 0x0321,
            OperationCode::WorkRevisionCount => 0x030E,
            OperationCode::WorkFetchRevision => 0x030F,
            OperationCode::WorkSponsor => 0x0310,
            OperationCode::WorkUnsponsor => 0x0311,
            OperationCode::WorkSponsors => 0x0312,
            OperationCode::WorkStar => 0x0335,
            OperationCode::WorkSetSource => 0x0351,
            OperationCode::WebFetchSanitize => 0x0352,
            OperationCode::WorkUnstar => 0x0336,
            OperationCode::WorkIsStarred => 0x0337,
            OperationCode::WorkGraph => 0x0338,
            OperationCode::WorkKindGet => 0x0B01,
            OperationCode::WorkKindSet => 0x0B02,
            OperationCode::WorkLicenseGet => 0x0B05,
            OperationCode::WorkLicenseSet => 0x0B06,
            OperationCode::WorkListByKind => 0x0B03,
            OperationCode::WorkSetText => 0x0B04,
            OperationCode::WorkRevisionsList => 0x0C01,
            OperationCode::WorkBlobList => 0x0C07,
            OperationCode::WorkTextAtRevision => 0x0C02,
            OperationCode::WorkRevisionDescribe => 0x0C03,
            OperationCode::WorkRevisionMarkNotable => 0x0C04,
            OperationCode::WorkRevisionRollback => 0x0C05,
            OperationCode::TrailCreate => 0x0339,
            OperationCode::TrailDelete => 0x033a,
            OperationCode::TrailRename => 0x033b,
            OperationCode::TrailAddStop => 0x033c,
            OperationCode::TrailRemoveStop => 0x033d,
            OperationCode::TrailReorderStops => 0x033e,
            OperationCode::TrailList => 0x033f,
            OperationCode::TrailGet => 0x0340,
            OperationCode::TrailUpdate => 0x0344,
            OperationCode::TrailPublish => 0x0345,
            OperationCode::TrailUnpublish => 0x0346,
            OperationCode::TrailListPublished => 0x0347,
            OperationCode::TrailListCategories => 0x0348,
            OperationCode::TrailDerivedWork => 0x0349,
            OperationCode::ConnectionPinSet => 0x0349,
            OperationCode::ConnectionPinUnset => 0x034a,
            OperationCode::ConnectionPinsGet => 0x034b,
            OperationCode::CrossServerBacklinksGet => 0x034c,
            OperationCode::WorkOwner => 0x0313,
            OperationCode::WorkPublish => 0x0317,
            OperationCode::WorkUnpublish => 0x0318,
            OperationCode::WorkIrrevocablyUnpublish => 0x0319,
            OperationCode::WorkArchive => 0x031C,
            OperationCode::WorkUnarchive => 0x031D,
            OperationCode::WorkListArchived => 0x031E,
            OperationCode::WorkMerge => 0x0322,
            OperationCode::WorkGhost => 0x0323,
            OperationCode::WorkIsPublished => 0x031A,
            OperationCode::WorkFetchRevisionRange => 0x031B,

            OperationCode::ClubSetDefaultReadClub => 0x0208,
            OperationCode::ClubSetDefaultEditClub => 0x0209,
            OperationCode::ClubSetPassword => 0x020A,
            OperationCode::ClubClearCredential => 0x020B,
            OperationCode::ClubCreatePersonal => 0x020C,
            OperationCode::ClubWhoAmI => 0x020D,
            OperationCode::ClubAddMember => 0x020E,
            OperationCode::ClubRemoveMember => 0x020F,
            OperationCode::ClubMembers => 0x0210,
            OperationCode::ClubRoster => 0x0211,

            OperationCode::EditionStore => 0x0401,
            OperationCode::EditionGet => 0x0402,

            OperationCode::AdminAcceptConnections => 0x0501,
            OperationCode::AdminIsAcceptingConnections => 0x0502,
            OperationCode::AdminActiveSessions => 0x0503,
            OperationCode::AdminShutdown => 0x0504,
            OperationCode::AdminGrant => 0x0505,
            OperationCode::AdminRevokeGrant => 0x0506,
            OperationCode::AdminGrants => 0x0507,
            OperationCode::AdminServerInfo => 0x0508,

            OperationCode::WorkList => 0x0314,
            OperationCode::WorkListByOwner => 0x0315,
            OperationCode::WorkReviseDelta => 0x0316,
            OperationCode::WorkDiffNarration => 0x0341,
            OperationCode::WorkWritingFeedback => 0x0342,
            OperationCode::WorkSuggestTitle => 0x034e,
            OperationCode::WorkSetTitle => 0x034f,
            OperationCode::WorkAutoTag => 0x0350,
            OperationCode::WorkBacklinks => 0x0343,

            OperationCode::LinkCreate => 0x0701,
            OperationCode::LinkGet => 0x0702,
            OperationCode::LinkUpdate => 0x0703,
            OperationCode::LinkDelete => 0x0704,
            OperationCode::LinkListForWork => 0x0705,
            OperationCode::FindExcerptPositions => 0x0706,
            OperationCode::LinkAddEnd => 0x0707,
            OperationCode::LinkRemoveEnd => 0x0708,
            OperationCode::LinkSetTypes => 0x0709,
            OperationCode::LinkTypeRegister => 0x070A,
            OperationCode::LinkTypeList => 0x070B,
            OperationCode::LinkQuery => 0x070C,

            OperationCode::FindTranscluders => 0x0801,
            OperationCode::FindWorksForContent => 0x0802,
            OperationCode::FindTextTranscluders => 0x0803,
            OperationCode::FindSharedRegions => 0x0804,
            OperationCode::WorkDiffRegions => 0x0805,

            OperationCode::ServerStats => 0x0601,
            OperationCode::MetricsSnapshot => 0x0602,

            OperationCode::BlobUpload => 0x0901,
            OperationCode::BlobGet => 0x0902,
            OperationCode::BlobGetPreview => 0x0903,
            OperationCode::BlobExists => 0x0904,
            OperationCode::BlobInfo => 0x0905,
            OperationCode::BlobStats => 0x0906,

            OperationCode::OverlayApply => 0x0a01,
            OperationCode::OverlayGet => 0x0a02,

            OperationCode::LabelCreate => 0x0b01,
            OperationCode::LabelGetPositions => 0x0b02,
            OperationCode::EditionRelabel => 0x0b03,
            OperationCode::EditionRebind => 0x0b04,
            OperationCode::CanMakeIdentical => 0x0b05,
            OperationCode::MakeRangeIdentical => 0x0b06,
            OperationCode::IdentityUnify => 0x0b07,
            OperationCode::IdentityResolve => 0x0b08,

            OperationCode::EditionRetrieve => 0x0c01,
            OperationCode::EditionCost => 0x0c02,
            OperationCode::ElementInsert => 0x0c0B,
            OperationCode::TransclusionPlaceCrossServer => 0x0c0C,
            OperationCode::CrossServerSpanRefresh => 0x0c0D,
            OperationCode::ElementUpdate => 0x0c0C,
            OperationCode::RenderTransclusions => 0x0c0C,
            OperationCode::AnnotationCreate => 0x0c03,
            OperationCode::AnnotationDelete => 0x0c04,
            OperationCode::AnnotationAttachNode => 0x0c05,
            OperationCode::AnnotationAttachSpan => 0x0c06,
            OperationCode::AnnotationGet => 0x0c09,
            OperationCode::AnnotationList => 0x0c0A,

            OperationCode::ContentSharedRegion => 0x0e01,
            OperationCode::ContentMapSharedTo => 0x0e02,
            OperationCode::ContentMapSharedOnto => 0x0e03,
            OperationCode::PositionsOf => 0x0e04,

            OperationCode::RangeTranscluders => 0x0f01,
            OperationCode::RangeWorks => 0x0f02,
            OperationCode::OrderedBundles => 0x0f03,
            OperationCode::TransclusionDepth => 0x0f04,

            OperationCode::VersionIsBefore => 0x1001,
            OperationCode::VersionAncestors => 0x1002,
            OperationCode::VersionDescendants => 0x1003,
            OperationCode::VersionTracePosition => 0x1004,

            OperationCode::ProvenanceAncestry => 0x0805,

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
            OperationCode::CrdtSyncText => 0x1C0A,

            OperationCode::CrdtAwarenessUpdate => 0x1C08,
            OperationCode::CrdtAwarenessGet => 0x1C09,

            OperationCode::CrdtRegisterAuthor => 0x1C0B,

            OperationCode::ResolveInlineTransclusions => 0x1E01,
            OperationCode::MigrateCompoundToInline => 0x1E02,
            OperationCode::ElementRemoveTransclusion => 0x1E03,
            OperationCode::AttributionQueryResolved => 0x1E04,

            OperationCode::AttributionQuery => 0x0D01,
            OperationCode::AttributionVerify => 0x0D02,
            OperationCode::AttributionLogStatus => 0x0D03,
            OperationCode::AttestationReport => 0x0D0B,
            OperationCode::WorkTextRange => 0x0D04,
            OperationCode::WorkOutline => 0x0D05,
            OperationCode::WorkSearch => 0x0D06,
            OperationCode::WorkGoto => 0x0D07,

            OperationCode::HistoricalAuthorRegister => 0x0D08,
            OperationCode::HistoricalAuthorGet => 0x0D09,
            OperationCode::HistoricalAuthorSearch => 0x0D0A,
            OperationCode::HistoricalAuthorList => 0x0D0B,
            OperationCode::ImportSourceWork => 0x0D0C,
            OperationCode::ImportEpub => 0x0D0D,
            OperationCode::SourceDetect => 0x0D0D,
            OperationCode::SourcePatternList => 0x0D0E,
            OperationCode::WorkListByAuthor => 0x0D0F,
            OperationCode::ContentMatch => 0x0D10,
            OperationCode::WorkApplySourceAttribution => 0x0D11,
            OperationCode::WorkApplyTransclusionAttribution => 0x0D12,
            OperationCode::WorkSummary => 0x0D13,
            OperationCode::WorkVersionTimeline => 0x0D14,
            OperationCode::PassageComposition => 0x0D15,
            OperationCode::GlobalTextSearch => 0x0D16,
            OperationCode::SeedDemoAttribution => 0x0D17,

            #[cfg(feature = "serde")]
            OperationCode::ProvJsonExport => 0x0E01,
            #[cfg(feature = "serde")]
            OperationCode::ServerDirectoryList => 0x0F01,
            #[cfg(feature = "serde")]
            OperationCode::ServerDirectoryAdd => 0x0F02,
            #[cfg(feature = "serde")]
            OperationCode::ServerDirectoryRemove => 0x0F03,
            #[cfg(feature = "serde")]
            OperationCode::ServerDirectorySetTrust => 0x0F04,
            #[cfg(feature = "serde")]
            OperationCode::CrossServerResolve => 0x0F05,
            #[cfg(feature = "serde")]
            OperationCode::CrossServerFetchWork => 0x0F06,
            #[cfg(feature = "serde")]
            OperationCode::CrossServerListWorks => 0x0F07,
            #[cfg(feature = "serde")]
            OperationCode::FederatedSearch => 0x0F08,
            #[cfg(feature = "serde")]
            OperationCode::FetchIntroductions => 0x0F09,
            #[cfg(feature = "serde")]
            OperationCode::AddDiscoveredServer => 0x0F0A,
            #[cfg(feature = "serde")]
            OperationCode::CrossServerLinkCreate => 0x0F0B,
            #[cfg(feature = "serde")]
            OperationCode::CrossServerLinkList => 0x0F0C,
            #[cfg(feature = "serde")]
            OperationCode::FetchRemoteIdentity => 0x0F0D,
            OperationCode::TumblerResolve => 0x0F0E,
            OperationCode::BloomFilterGet => 0x0F0F,
            OperationCode::BloomFilterCheck => 0x0F10,
            OperationCode::NetworkSetEnabled => 0x0F11,
            OperationCode::ExternalLinksSetEnabled => 0x0F12,
            #[cfg(feature = "serde")]
            OperationCode::FederationAttestationCreate => 0x0E02,
            #[cfg(feature = "serde")]
            OperationCode::FederationAttestationVerify => 0x0E03,
            #[cfg(feature = "serde")]
            OperationCode::FederationBundleExport => 0x0E04,
            #[cfg(feature = "serde")]
            OperationCode::ClusterVerificationCreate => 0x0E05,
            #[cfg(feature = "serde")]
            OperationCode::CrossServerSignatureVerify => 0x0E06,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "serde", serde(tag = "type", rename_all = "snake_case"))]
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
#[cfg_attr(feature = "serde", serde(rename_all = "snake_case"))]
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
        credential: LockCredential,
    },
    SessionLoginPublic,
    SessionTicketIssue,
    SessionTicketRedeem {
        ticket: Vec<u8>,
    },

    ServerGetById {
        id: u64,
    },
    ServerGetByBeId {
        be_id: BeId,
    },

    ClubCreate {
        description: EditionPayload,
    },
    ClubCreateNamed {
        name: String,
        description: EditionPayload,
    },
    ClubGet {
        club_id: BeId,
    },
    ClubByName {
        name: String,
    },
    ClubIdByName {
        name: String,
    },
    ClubNameById {
        club_id: BeId,
    },
    ClubNames {
        #[cfg_attr(feature = "serde", serde(default))]
        offset: Option<u32>,
        #[cfg_attr(feature = "serde", serde(default))]
        limit: Option<u32>,
    },

    WorkCreate {
        edition: EditionPayload,
    },
    WorkGetEdition {
        work_id: BeId,
    },
    WorkRevise {
        work_id: BeId,
        edition: EditionPayload,
    },
    WorkGrab {
        work_id: BeId,
    },
    WorkRelease {
        work_id: BeId,
    },
    WorkSaveAndRelease {
        work_id: BeId,
        edition: EditionPayload,
    },
    WorkForceRelease {
        work_id: BeId,
    },
    WorkIsGrabbed {
        work_id: BeId,
    },
    WorkGrabber {
        work_id: BeId,
    },
    WorkRequestGrab {
        work_id: BeId,
    },
    WorkCancelGrabRequest {
        work_id: BeId,
    },
    WorkGrabWaiters {
        work_id: BeId,
    },
    WorkCanRead {
        work_id: BeId,
    },
    WorkCanRevise {
        work_id: BeId,
    },
    WorkStar {
        work_id: BeId,
    },
    WorkSetSource {
        work_id: BeId,
        is_source: bool,
    },
    /// Fetch a web page server-side, sanitize it with ammonia, and
    /// return clean text (+ sanitized excerpt). Optionally import as a
    /// frozen source work so the quotation keeps its provenance.
    WebFetchSanitize {
        url: String,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        max_chars: Option<u64>,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        import_as_source: Option<bool>,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        title: Option<String>,
    },
    WorkUnstar {
        work_id: BeId,
    },
    WorkIsStarred {
        work_id: BeId,
    },
    ConnectionPinSet {
        key: String,
    },
    ConnectionPinUnset {
        key: String,
    },
    ConnectionPinsGet,
    CrossServerBacklinksGet {
        work_id: BeId,
    },
    WorkGraph {
        #[cfg_attr(feature = "serde", serde(default))]
        center_work_id: Option<BeId>,
        #[cfg_attr(feature = "serde", serde(default))]
        max_nodes: u64,
    },

    WorkKindGet {
        work_id: BeId,
    },
    WorkKindSet {
        work_id: BeId,
        kind: crate::edition::WorkKind,
    },
    WorkLicenseGet {
        work_id: BeId,
    },
    WorkLicenseSet {
        work_id: BeId,
        license: crate::edition::License,
    },
    WorkListByKind {
        kind: crate::edition::WorkKind,
    },
    /// Set the text content of a work in one shot. Used for seeding concepts
    /// and other batch operations where CRDT ops would be too slow.
    WorkSetText {
        work_id: BeId,
        text: String,
    },

    /// FR-23: Revision wire ops
    WorkRevisionsList {
        work_id: BeId,
    },
    /// Query blob elements in an edition (image positions)
    WorkBlobList {
        work_id: BeId,
    },
    WorkTextAtRevision {
        work_id: BeId,
        revision_id: u64,
    },
    WorkRevisionDescribe {
        work_id: BeId,
        revision_id: u64,
        description: String,
    },
    WorkRevisionMarkNotable {
        work_id: BeId,
        revision_id: u64,
        notable: bool,
    },
    WorkRevisionRollback {
        work_id: BeId,
        target_revision_id: u64,
    },

    TrailCreate {
        name: String,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        introduction: Option<String>,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Vec::is_empty")
        )]
        categories: Vec<String>,
    },
    TrailDelete {
        trail_id: BeId,
    },
    TrailRename {
        trail_id: BeId,
        name: String,
    },
    TrailAddStop {
        trail_id: BeId,
        work_id: BeId,
        char_start: Option<u64>,
        char_end: Option<u64>,
        note: Option<String>,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        server_domain: Option<String>,
    },
    TrailRemoveStop {
        trail_id: BeId,
        stop_index: u64,
    },
    TrailReorderStops {
        trail_id: BeId,
        stop_order: Vec<u64>,
    },
    TrailList,
    TrailGet {
        trail_id: BeId,
    },
    TrailUpdate {
        trail_id: BeId,
        introduction: Option<String>,
        categories: Vec<String>,
    },
    TrailPublish {
        trail_id: BeId,
    },
    TrailUnpublish {
        trail_id: BeId,
    },
    TrailListPublished {
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        category: Option<String>,
    },
    TrailListCategories,
    /// FR-37 4d: ensure the trail's derived work exists and is in
    /// sync with its stops (generation-checked); returns the work id.
    TrailDerivedWork {
        trail_id: BeId,
    },

    WorkSetReadClub {
        work_id: BeId,
        club_id: Option<BeId>,
    },
    WorkSetEditClub {
        work_id: BeId,
        club_id: Option<BeId>,
    },
    WorkSetHistoryClub {
        work_id: BeId,
        club_id: Option<BeId>,
    },
    WorkReadClub {
        work_id: BeId,
    },
    WorkEditClub {
        work_id: BeId,
    },
    WorkHistoryClub {
        work_id: BeId,
    },
    WorkTransclusionChain {
        work_id: BeId,
        char_start: usize,
        char_end: usize,
    },
    WorkRevisionCount {
        work_id: BeId,
    },
    WorkFetchRevision {
        work_id: BeId,
        number: u64,
    },
    WorkFetchRevisionRange {
        work_id: BeId,
        from: u64,
        to: u64,
    },
    WorkSponsor {
        work_id: BeId,
        club_id: BeId,
    },
    WorkUnsponsor {
        work_id: BeId,
        club_id: BeId,
    },
    WorkSponsors {
        work_id: BeId,
    },
    WorkOwner {
        work_id: BeId,
    },
    WorkPublish {
        work_id: BeId,
    },
    WorkUnpublish {
        work_id: BeId,
    },
    WorkIrrevocablyUnpublish {
        work_id: BeId,
    },
    WorkArchive {
        work_id: BeId,
    },
    WorkUnarchive {
        work_id: BeId,
    },
    /// List archived (soft-deleted) works. Owner-scoped; admins see all.
    WorkListArchived,
    WorkIsPublished {
        work_id: BeId,
    },
    WorkMerge {
        base_work_id: BeId,
        a_work_id: BeId,
        b_work_id: BeId,
    },
    WorkGhost {
        work_id: BeId,
    },

    ClubSetDefaultReadClub {
        club_id: BeId,
        default_read_club: Option<BeId>,
    },
    ClubSetDefaultEditClub {
        club_id: BeId,
        default_edit_club: Option<BeId>,
    },

    ClubSetPassword {
        club_id: BeId,
        password: Vec<u8>,
    },
    ClubClearCredential {
        club_id: BeId,
    },
    ClubCreatePersonal {
        display_name: String,
        password: Option<Vec<u8>>,
    },
    ClubWhoAmI,
    ClubAddMember {
        club_id: BeId,
        member_id: BeId,
    },
    ClubRemoveMember {
        club_id: BeId,
        member_id: BeId,
    },
    ClubMembers {
        club_id: BeId,
    },
    ClubRoster {
        club_id: BeId,
    },

    EditionStore {
        edition: EditionPayload,
    },
    EditionGet {
        be_id: BeId,
    },

    AdminAcceptConnections {
        accept: bool,
    },
    AdminIsAcceptingConnections,
    AdminActiveSessions,
    AdminShutdown,
    AdminGrant {
        club_id: BeId,
        region_start: i64,
        region_end: i64,
    },
    AdminRevokeGrant {
        club_id: BeId,
    },
    AdminGrants,
    AdminServerInfo,

    WorkList {
        #[cfg_attr(feature = "serde", serde(default))]
        offset: Option<u32>,
        #[cfg_attr(feature = "serde", serde(default))]
        limit: Option<u32>,
    },
    WorkListByOwner {
        owner: BeId,
        #[cfg_attr(feature = "serde", serde(default))]
        offset: Option<u32>,
        #[cfg_attr(feature = "serde", serde(default))]
        limit: Option<u32>,
    },

    WorkReviseDelta {
        work_id: BeId,
        base_revision: u64,
        ops: Vec<TextDeltaOp>,
    },

    WorkDiffNarration {
        work_id: BeId,
    },

    WorkWritingFeedback {
        work_id: BeId,
    },
    WorkSuggestTitle {
        work_id: BeId,
    },
    WorkSetTitle {
        work_id: BeId,
        title: String,
    },
    WorkAutoTag {
        work_id: BeId,
    },

    WorkBacklinks {
        work_id: BeId,
    },

    LinkCreate {
        origin: BeId,
        destination: BeId,
        origin_ref: Option<HyperRefPayload>,
        destination_ref: Option<HyperRefPayload>,
        #[cfg_attr(feature = "serde", serde(default))]
        link_types: Vec<u64>,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        home_document: Option<BeId>,
    },
    LinkGet {
        link_id: BeId,
    },
    LinkUpdate {
        link_id: BeId,
        origin_ref: Option<HyperRefPayload>,
        destination_ref: Option<HyperRefPayload>,
    },
    LinkDelete {
        link_id: BeId,
    },
    LinkListForWork {
        work_id: BeId,
        #[cfg_attr(feature = "serde", serde(default))]
        offset: Option<u32>,
        #[cfg_attr(feature = "serde", serde(default))]
        limit: Option<u32>,
    },
    LinkAddEnd {
        link_id: BeId,
        end_name: String,
        end_ref: HyperRefPayload,
    },
    LinkRemoveEnd {
        link_id: BeId,
        end_name: String,
    },
    LinkSetTypes {
        link_id: BeId,
        link_types: Vec<u64>,
    },
    LinkTypeRegister {
        type_id: u64,
        name: String,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        definition_work: Option<BeId>,
    },
    LinkTypeList,
    /// Green's four-set link matching (FR-40 Story 4): find links
    /// where one end matches `from_spec`, another end matches
    /// `to_spec`, the types include `type_ids`, and the home document
    /// matches `home_spec`. Empty specs mean "any".
    LinkQuery {
        #[cfg_attr(feature = "serde", serde(default))]
        from_spec: LinkEndpointSpecPayload,
        #[cfg_attr(feature = "serde", serde(default))]
        to_spec: LinkEndpointSpecPayload,
        #[cfg_attr(feature = "serde", serde(default))]
        type_ids: Vec<u64>,
        #[cfg_attr(feature = "serde", serde(default))]
        home_spec: LinkEndpointSpecPayload,
    },
    FindExcerptPositions {
        work_id: BeId,
        excerpt: String,
    },

    FindTranscluders {
        content_be_id: BeId,
    },
    FindWorksForContent {
        content_be_id: BeId,
    },
    FindTextTranscluders {
        text: String,
    },
    FindSharedRegions {
        work_a: BeId,
        work_b: BeId,
        filter_text: Option<String>,
    },
    WorkDiffRegions {
        work_a: BeId,
        work_b: BeId,
    },

    ServerStats,
    MetricsSnapshot,

    BlobUpload {
        data: String,
        mime_type: String,
    },
    BlobGet {
        #[serde()]
        content_hash: String,
    },
    BlobGetPreview {
        #[serde()]
        content_hash: String,
    },
    BlobExists {
        #[serde()]
        content_hash: String,
    },
    BlobInfo {
        #[serde()]
        content_hash: String,
    },
    BlobStats,
    OverlayApply {
        #[serde()]
        base_hash: u64,
        ops: Vec<ImageOp>,
        mime_type: String,
    },
    OverlayGet {
        #[serde()]
        overlay_hash: u64,
    },

    LabelCreate,
    LabelGetPositions {
        work_id: BeId,
        label_id: u64,
    },
    EditionRelabel {
        work_id: BeId,
        label_id: u64,
    },
    EditionRebind {
        work_id: BeId,
        position: i64,
        new_edition: EditionPayload,
    },
    CanMakeIdentical {
        source_work_id: BeId,
        target_work_id: BeId,
        position: Option<i64>,
    },
    MakeRangeIdentical {
        source_work_id: BeId,
        target_work_id: BeId,
        region: Option<XnRegion>,
    },
    IdentityUnify {
        source_id: u64,
        target_id: u64,
    },
    IdentityResolve {
        id: u64,
    },

    EditionRetrieve {
        work_id: BeId,
        region: Option<XnRegion>,
        flags: Option<RetrieveFlagsPayload>,
    },
    EditionCost {
        work_id: BeId,
        method: Option<String>,
    },
    ElementInsert {
        work_id: BeId,
        position: i64,
        element: RangeElementPayload,
    },
    /// FR-41 S2: transclude a selected span of a remote work into a
    /// local document by reference (fetch span from origin, verify
    /// BLAKE3, freeze as source, place pinned virtual at cursor).
    TransclusionPlaceCrossServer {
        dest_work: BeId,
        #[cfg_attr(feature = "serde", serde(default))]
        cursor: usize,
        tumbler: String,
        span_start: usize,
        span_end: usize,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        title_hint: Option<String>,
    },
    /// FR-41 S3: check (or apply) an origin-side edit to a
    /// cross-server transclusion's frozen source.
    CrossServerSpanRefresh {
        source_work: BeId,
        #[cfg_attr(feature = "serde", serde(default))]
        update: bool,
    },
    ElementUpdate {
        work_id: BeId,
        char_position: usize,
        element: RangeElementPayload,
    },
    RenderTransclusions {
        work_id: BeId,
    },

    AnnotationCreate {
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
    },
    AnnotationDelete {
        work_id: BeId,
        annotation_id: u64,
    },
    AnnotationAttachNode {
        work_id: BeId,
        annotation_id: u64,
        node_id: u64,
    },
    AnnotationAttachSpan {
        work_id: BeId,
        annotation_id: u64,
        span_id: u64,
    },
    AnnotationGet {
        work_id: BeId,
        annotation_id: u64,
    },
    AnnotationList {
        work_id: BeId,
    },

    ContentSharedRegion {
        work_a: BeId,
        work_b: BeId,
    },
    ContentMapSharedTo {
        work_a: BeId,
        work_b: BeId,
    },
    ContentMapSharedOnto {
        work_a: BeId,
        work_b: BeId,
    },
    PositionsOf {
        work_id: BeId,
        element: RangeElement,
    },

    RangeTranscluders {
        work_id: BeId,
        region: Option<XnRegion>,
        direct_only: Option<bool>,
    },
    RangeWorks {
        work_id: BeId,
        region: Option<XnRegion>,
    },
    OrderedBundles {
        work_id: BeId,
        region: Option<XnRegion>,
    },
    TransclusionDepth {
        work_id: BeId,
        position: i64,
        max_depth: Option<usize>,
    },
    VersionIsBefore {
        work_a: BeId,
        work_b: BeId,
    },
    VersionAncestors {
        work_id: BeId,
    },
    VersionDescendants {
        work_id: BeId,
    },
    VersionTracePosition {
        work_id: BeId,
    },

    ProvenanceAncestry {
        work_id: BeId,
    },

    AdminRecorderCreate {
        kind: String,
        direct_only: Option<bool>,
        region: Option<XnRegion>,
    },
    AdminRecorderRecord {
        recorder_id: u64,
        element: RangeElement,
    },
    AdminRecorderList,
    AdminRecorderGet {
        recorder_id: u64,
    },
    AdminServerHealth,
    ResolveInlineTransclusions {
        work_id: BeId,
    },
    MigrateCompoundToInline {
        work_id: BeId,
    },
    ElementRemoveTransclusion {
        work_id: BeId,
        source_work_id: BeId,
        char_start: usize,
        char_end: usize,
    },
    AttributionQueryResolved {
        work_id: BeId,
    },
    CryptoGetPublicKey,
    CryptoSignData {
        data: Vec<u8>,
    },
    CryptoVerifySignature {
        data: Vec<u8>,
        signature: Vec<u8>,
    },
    CryptoKeyRotation,
    CryptoKeyHistory,
    WorkEndorse {
        work_id: BeId,
        endorsements: Vec<(u64, u64)>,
    },
    WorkRetract {
        work_id: BeId,
        endorsements: Vec<(u64, u64)>,
    },
    WorkEndorsements {
        work_id: BeId,
    },
    EditionEndorse {
        edition_id: BeId,
        endorsements: Vec<(u64, u64)>,
    },
    EditionRetract {
        edition_id: BeId,
        endorsements: Vec<(u64, u64)>,
    },
    EditionEndorsements {
        edition_id: BeId,
    },
    EditionVisibleEndorsements {
        edition_id: BeId,
    },
    EditionTotalEndorsements {
        edition_id: BeId,
    },

    FederationInfo,
    FederationPeers,
    FederatedTransclusionQuery {
        content_fingerprint_hex: String,
        direct_only: bool,
    },
    FederatedContentFetch {
        content_fingerprint_hex: String,
    },

    EndorsementSync {
        work_fingerprint: String,
    },
    EndorsementAdd {
        work_fingerprint: String,
        club_id: u64,
        token_id: u64,
    },
    EndorsementRetract {
        work_fingerprint: String,
        club_id: u64,
        token_id: u64,
    },
    EndorsementQuery {
        work_fingerprint: String,
    },
    StateSync {
        work_fingerprints: Vec<String>,
    },
    StateAlternatives {
        work_fingerprint: String,
    },

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

    CrdtSyncOpen {
        work_id: BeId,
    },
    CrdtSyncClose {
        work_id: BeId,
    },
    CrdtSyncUpdate {
        work_id: BeId,
        update: Vec<u8>,
    },
    CrdtSyncDiff {
        work_id: BeId,
        state_vector: Vec<u8>,
    },
    CrdtSyncFullState {
        work_id: BeId,
    },
    CrdtSyncMaterialize {
        work_id: BeId,
    },
    CrdtSyncSubscriberCount {
        work_id: BeId,
    },
    CrdtSyncText {
        work_id: BeId,
    },

    CrdtAwarenessUpdate {
        work_id: BeId,
        awareness: crate::server::crdt_manager::AwarenessState,
    },
    CrdtAwarenessGet {
        work_id: BeId,
    },

    CrdtRegisterAuthor {
        work_id: BeId,
        #[cfg_attr(feature = "serde", serde(skip))]
        public_key: [u8; 32],
        #[cfg_attr(feature = "serde", serde(skip))]
        display_name: String,
    },

    AttributionQuery {
        work_id: BeId,
        start: Option<i64>,
        end: Option<i64>,
    },
    AttributionVerify {
        author_public_key: Vec<u8>,
        signature: Vec<u8>,
        timestamp: u64,
        server_id: Vec<u8>,
        span_fingerprint_hex: String,
    },
    AttributionLogStatus,
    AttestationReport {
        work_id: BeId,
    },
    WorkTextRange {
        work_id: BeId,
        start_char: u64,
        end_char: u64,
    },
    WorkOutline {
        work_id: BeId,
    },
    WorkSearch {
        work_id: BeId,
        query: String,
        max_results: Option<u64>,
    },
    WorkGoto {
        work_id: BeId,
        line: Option<u64>,
        char: Option<u64>,
        context_lines: Option<u64>,
    },

    HistoricalAuthorRegister {
        name: String,
        display_name: String,
        birth_year: Option<i32>,
        death_year: Option<i32>,
        external_ids: std::collections::HashMap<String, String>,
        source_bibliography: String,
    },

    HistoricalAuthorGet {
        author_id: BeId,
    },

    HistoricalAuthorSearch {
        query: String,
    },

    HistoricalAuthorList,

    ImportSourceWork {
        author_id: BeId,
        title: String,
        text: String,
        edition_info: String,
        skip_prefix_lines: u64,
        skip_suffix_lines: u64,
    },

    /// FR-EPUB: Import an EPUB file. Extracts text + metadata server-side.
    ImportEpub {
        epub_data: Vec<u8>,
        #[cfg_attr(feature = "serde", serde(default))]
        title: Option<String>,
        #[cfg_attr(feature = "serde", serde(default))]
        author: Option<String>,
        #[cfg_attr(feature = "serde", serde(default))]
        skip_prefix_lines: u64,
        #[cfg_attr(feature = "serde", serde(default))]
        skip_suffix_lines: u64,
    },

    /// Phase 1 of EPUB import: extract text + metadata without creating a work.
    /// Client then feeds the text into the ImportWizard flow.
    ExtractEpub {
        epub_data: Vec<u8>,
    },

    SourceDetect {
        text: String,
    },

    SourcePatternList,

    WorkListByAuthor {
        author_id: BeId,
    },

    ContentMatch {
        text: String,
    },

    WorkApplySourceAttribution {
        work_id: BeId,
        historical_author_id: BeId,
        source_work_id: Option<BeId>,
        paste_start: Option<usize>,
        paste_end: Option<usize>,
    },

    WorkApplyTransclusionAttribution {
        link_id: BeId,
    },

    WorkSummary {
        work_id: BeId,
    },

    WorkVersionTimeline {
        work_id: BeId,
    },

    PassageComposition {
        work_id: BeId,
        start: u64,
        end: u64,
    },
    GlobalTextSearch {
        query: String,
        #[cfg_attr(feature = "serde", serde(default))]
        max_results: Option<u64>,
    },
    SeedDemoAttribution {
        work_id: BeId,
        #[cfg_attr(feature = "serde", serde(default))]
        author_count: Option<u32>,
    },

    #[cfg(feature = "serde")]
    ProvJsonExport {
        #[cfg_attr(feature = "serde", serde(default))]
        work_id: Option<u64>,
        include_federation: bool,
    },
    #[cfg(feature = "serde")]
    ServerDirectoryList,
    #[cfg(feature = "serde")]
    ServerDirectoryAdd {
        address: String,
        #[cfg_attr(feature = "serde", serde(default))]
        port: Option<u16>,
    },
    #[cfg(feature = "serde")]
    ServerDirectoryRemove {
        server_id: String,
    },
    #[cfg(feature = "serde")]
    ServerDirectorySetTrust {
        server_id: String,
        trusted: bool,
    },
    #[cfg(feature = "serde")]
    NetworkSetEnabled {
        enabled: bool,
    },
    #[cfg(feature = "serde")]
    ExternalLinksSetEnabled {
        enabled: bool,
    },
    #[cfg(feature = "serde")]
    CrossServerResolve {
        tumbler: String,
        content_hash_hex: String,
    },
    #[cfg(feature = "serde")]
    FederationAttestationCreate {
        attestation_type: String,
        subject_server_id: String,
    },
    #[cfg(feature = "serde")]
    FederationAttestationVerify {
        attestation_json: String,
    },
    #[cfg(feature = "serde")]
    FederationBundleExport {
        bundle_id: String,
    },
    #[cfg(feature = "serde")]
    ClusterVerificationCreate {
        activity_type: String,
        verifying_servers: Vec<String>,
        consensus_type: String,
        threshold_met: bool,
    },
    #[cfg(feature = "serde")]
    CrossServerSignatureVerify {
        server_id: String,
        signature: Vec<u8>,
        timestamp: u64,
    },
    #[cfg(feature = "serde")]
    CrossServerFetchWork {
        server_id: String,
        work_id: String,
    },
    #[cfg(feature = "serde")]
    CrossServerListWorks {
        server_id: String,
    },
    #[cfg(feature = "serde")]
    FederatedSearch {
        query: String,
    },
    #[cfg(feature = "serde")]
    FetchIntroductions {
        server_id: String,
    },
    #[cfg(feature = "serde")]
    AddDiscoveredServer {
        server_id: u64,
        address: String,
        name: String,
        verifying_key: String,
        introduced_by: u64,
    },
    #[cfg(feature = "serde")]
    CrossServerLinkCreate {
        local_work_id: u64,
        remote_tumbler: String,
        remote_title: String,
        remote_server_name: String,
        remote_server_id: u64,
        link_type: String,
    },
    #[cfg(feature = "serde")]
    CrossServerLinkList {
        work_id: u64,
    },
    #[cfg(feature = "serde")]
    FetchRemoteIdentity {
        server_id: String,
        club_name: String,
    },
    TumblerResolve {
        tumbler: String,
    },
    BloomFilterGet {
        server_id: String,
    },
    BloomFilterCheck {
        server_id: String,
        work_id: u64,
    },
}

impl WireRequest {
    pub fn is_readonly(&self) -> bool {
        matches!(
            self,
            Self::SessionConnect
                | Self::WorkGetEdition { .. }
                | Self::WorkIsGrabbed { .. }
                | Self::WorkGrabber { .. }
                | Self::WorkGrabWaiters { .. }
                | Self::WorkCanRead { .. }
                | Self::WorkCanRevise { .. }
                | Self::WorkIsStarred { .. }
                | Self::WorkReadClub { .. }
                | Self::WorkEditClub { .. }
                | Self::WorkHistoryClub { .. }
                | Self::WorkRevisionCount { .. }
                | Self::WorkSponsors { .. }
                | Self::WorkOwner { .. }
                | Self::WorkIsPublished { .. }
                | Self::WorkGhost { .. }
                | Self::RenderTransclusions { .. }
                | Self::WorkList { .. }
                | Self::WorkListByOwner { .. }
                | Self::WorkListArchived { .. }
                | Self::WorkBacklinks { .. }
                | Self::WorkEndorsements { .. }
                | Self::WorkSummary { .. }
                | Self::WorkVersionTimeline { .. }
                | Self::EditionGet { .. }
                | Self::EditionEndorsements { .. }
                | Self::EditionVisibleEndorsements { .. }
                | Self::EditionTotalEndorsements { .. }
                | Self::TrailList { .. }
                | Self::TrailGet { .. }
                | Self::TrailListPublished { .. }
                | Self::TrailListCategories
                | Self::ClubGet { .. }
                | Self::ClubNames { .. }
                | Self::ClubWhoAmI { .. }
                | Self::ClubMembers { .. }
                | Self::ClubRoster { .. }
                | Self::ServerStats
                | Self::MetricsSnapshot
                | Self::LinkGet { .. }
                | Self::LinkListForWork { .. }
                | Self::LinkTypeList
                | Self::LinkQuery { .. }
                | Self::BlobGet { .. }
                | Self::BlobGetPreview { .. }
                | Self::BlobExists { .. }
                | Self::BlobInfo { .. }
                | Self::BlobStats
                | Self::OverlayGet { .. }
                | Self::CrdtSyncDiff { .. }
                | Self::CrdtSyncFullState { .. }
                | Self::CrdtSyncSubscriberCount { .. }
                | Self::CrdtSyncText { .. }
                | Self::CrdtAwarenessGet { .. }
                | Self::AdminIsAcceptingConnections
                | Self::AdminActiveSessions
                | Self::AdminGrants
                | Self::AdminServerInfo { .. }
                | Self::AdminServerHealth { .. }
                | Self::AdminRecorderList { .. }
                | Self::AdminRecorderGet { .. }
                | Self::AttributionVerify { .. }
                | Self::AttributionLogStatus
                | Self::AnnotationGet { .. }
                | Self::HistoricalAuthorGet { .. }
                | Self::HistoricalAuthorSearch { .. }
                | Self::HistoricalAuthorList
                | Self::SourcePatternList
                | Self::CryptoGetPublicKey
                | Self::CryptoKeyHistory
                | Self::FederationInfo
                | Self::FederationPeers
                | Self::MembershipList { .. }
                | Self::MembershipVerify { .. }
                | Self::GovernanceLog { .. }
                | Self::GovernanceStatus { .. }
                | Self::GlobalTextSearch { .. }
        )
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "serde", serde(rename_all = "snake_case"))]
pub enum EditionPayload {
    Text(String),
    Entries(Vec<(i64, RangeElement)>),
    Empty,
}

#[allow(dead_code)]
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

    /// Trust-boundary conversion: deserialize the payload AND validate
    /// structural invariants before the edition may touch server
    /// state. Deserialization bypasses constructors (a reversed
    /// transclusion range survives the wire in raw form), so this —
    /// not construction — is the gate for untrusted input.
    pub fn to_edition_checked(&self, self_work_id: u64) -> Result<crate::edition::Edition, String> {
        let edition = self.to_edition();
        let report = crate::edition::document_invariants::validate_edition(&edition, self_work_id);
        if report.is_valid() {
            Ok(edition)
        } else {
            Err(format!(
                "malformed edition: {}",
                report
                    .violations
                    .iter()
                    .map(|v| v.code.to_string())
                    .collect::<Vec<_>>()
                    .join(", ")
            ))
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
        } else if entries.iter().all(|(_, e)| e.as_text().is_some()) {
            // Content-level payload: positions and segmentation are not
            // transported, so contiguity is not required (tree-native
            // edits produce gap-allocated positions).
            let s: String = entries
                .iter()
                .map(|(_, e)| e.as_text().unwrap_or(""))
                .collect();
            EditionPayload::Text(s)
        } else {
            EditionPayload::Entries(entries)
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(
    feature = "serde",
    serde(tag = "type", content = "value", rename_all = "snake_case")
)]
pub enum ResponseValue {
    Void,
    Id(BeId),
    Humber(u64),
    Boolean(bool),
    String(String),
    Ticket {
        clubs: Vec<BeId>,
        ticket: Vec<u8>,
    },
    Edition(EditionPayload),
    RangeElement(Option<RangeElement>),
    Region(XnRegion),
    Ids(Vec<BeId>),
    ClubNames(Vec<(String, BeId)>),
    SessionInfos(Vec<SessionInfoPayload>),
    ServerInfo(ServerInfoPayload),
    Grants(Vec<GrantPayload>),
    WorkList(Vec<WorkListEntry>),
    WorkGraphResult(GraphPayload),
    TrailResult(TrailPayload),
    TrailListResult(Vec<TrailPayload>),
    TrailCategories(Vec<String>),
    WorkBacklinksResult(Vec<BacklinkEntryPayload>),
    PaginatedWorkList {
        entries: Vec<WorkListEntry>,
        total_count: u64,
        has_more: bool,
    },
    PaginatedClubNames {
        entries: Vec<(String, BeId)>,
        total_count: u64,
        has_more: bool,
    },
    PaginatedLinkList {
        entries: Vec<LinkPayload>,
        total_count: u64,
        has_more: bool,
    },
    AnnotationResult(AnnotationPayload),
    AnnotationListResult(Vec<AnnotationPayload>),
    /// FR-23: Revision metadata list
    RevisionListResult(Vec<crate::persist::manifest::RevisionMeta>),
    /// Image blob positions in edition
    BlobListResult(Vec<crate::edition::edition::BlobEntry>),
    /// FR-23: Text at a specific revision
    TextResult(String),
    MetricsSnapshotResult(Vec<(String, u64, u64, u64, u64, u64, u64)>),
    LinkInfo(LinkPayload),
    CrossServerTransclusion(CrossServerTransclusionPayload),
    CrossServerSpanRefresh(CrossServerSpanRefreshPayload),
    LinkList(Vec<LinkPayload>),
    LinkTypes(Vec<LinkTypeInfoPayload>),
    ConnectionPins(Vec<String>),
    CrossServerBacklinksResult(Vec<CrossServerBacklinkPayload>),
    ExcerptPositions(Vec<ExcerptPositionPayload>),
    TransclusionResults(Vec<TransclusionResultPayload>),
    WorkIds(Vec<BeId>),
    TextTransclusionResults(Vec<TextTransclusionResultPayload>),
    RenderedTransclusions(Vec<RenderedElementPayload>),
    SharedRegions(Vec<SharedRegionPayload>),
    JsonValue(serde_json::Value),
    BlobMeta(BlobMetaPayload),
    BlobData(Vec<u8>),
    BlobStatsInfo(BlobStatsPayload),
    OverlayInfo(OverlayPayload),
    LabelInfo {
        label_id: u64,
    },
    LabelPositions {
        label_id: u64,
        positions: XnRegion,
    },
    CanMakeIdenticalResult {
        result: String,
    },
    MakeRangeIdenticalResult {
        outcome: String,
        failed_count: u64,
        failed: EditionPayload,
    },
    IdentityResolveResult {
        resolved_id: u64,
    },
    BundleResults {
        bundles: Vec<BundlePayload>,
    },
    StorageCostResult {
        total_bytes: u64,
        unique_bytes: u64,
        shared_bytes: u64,
        share_count: u64,
        billed_bytes: u64,
        method: String,
    },
    SharedRegionResult {
        region: XnRegion,
    },
    SharedMappingResult {
        pairs: Vec<(i64, i64)>,
    },
    PositionsOfResult {
        region: XnRegion,
    },
    RangeTranscludersResult {
        edition_ids: Vec<BeId>,
        work_ids: Vec<BeId>,
        region: XnRegion,
    },
    RangeWorksResult {
        work_ids: Vec<BeId>,
        region: XnRegion,
    },
    OrderedBundlesResult {
        bundles: Vec<BundlePayload>,
    },
    TransclusionDepthResult {
        depth: usize,
    },
    VersionIsBeforeResult {
        is_before: Option<bool>,
    },
    VersionAncestorsResult {
        ancestors: Vec<BeId>,
    },
    VersionDescendantsResult {
        descendants: Vec<BeId>,
    },
    VersionTracePositionResult {
        trace_position: Option<TracePositionPayload>,
    },
    ProvenanceAncestryResult {
        chain: Vec<ProvenanceHopPayload>,
    },
    TransclusionChainResult {
        chain: Vec<AgainHopPayload>,
    },
    ElementInsertResult {
        revision: u64,
    },
    ResolveInlineTransclusionsResult {
        text: String,
        span_ranges: Vec<SpanRangePayload>,
        source_titles: HashMap<BeId, String>,
    },
    MigrateCompoundToInlineResult {
        migrated_count: usize,
    },
    ElementRemoveTransclusionResult {
        removed: bool,
    },
    WorkMergeResult {
        work_id: BeId,
    },
    WorkGhostResult {
        ghost: Option<WorkGhostInfoPayload>,
    },
    RecorderCreateResult {
        recorder_id: u64,
    },
    RecorderRecordResult {
        recorded: bool,
    },
    RecorderListResult {
        recorders: Vec<RecorderInfoPayload>,
    },
    RecorderGetResult {
        recorder: Option<RecorderInfoPayload>,
    },
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
    EndorsementResult {
        endorsements: Vec<(u64, u64)>,
    },
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
    CrdtSyncTextResult {
        text: String,
    },

    CrdtAwarenessUpdateResult {
        relay_count: usize,
    },
    CrdtAwarenessGetResult {
        states: Vec<crate::server::crdt_manager::AwarenessState>,
    },

    CrdtRegisterAuthorResult {
        registered: bool,
    },

    AuthChallenge {
        challenge: Vec<u8>,
    },

    ClubWhoAmIResult {
        clubs: Vec<(BeId, String)>,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        verifying_key: Option<String>,
    },

    ClubSetPasswordResult {
        set: bool,
    },

    ClubClearCredentialResult {
        cleared: bool,
    },

    ClubMembersResult {
        members: Vec<BeId>,
    },

    ClubRosterResult {
        members: Vec<(BeId, String)>,
        total: u64,
        truncated: bool,
    },

    RevisionRangeResult {
        revisions: Vec<(u64, EditionPayload)>,
    },

    AttributionQueryResult {
        spans: Vec<AttributionSpanPayload>,
    },
    AttributionVerifyResult {
        valid: bool,
    },
    AttributionLogStatusResult {
        entry_count: u64,
        chain_valid: bool,
        last_sequence: u64,
        has_log: bool,
    },
    AttestationReportResult {
        report_json: String,
    },
    WorkTextRangeResult {
        text: String,
        total_chars: u64,
        start_char: u64,
        end_char: u64,
    },
    WorkOutlineResult {
        entries: Vec<OutlineEntryPayload>,
    },
    WorkSearchResult {
        matches: Vec<SearchMatchPayload>,
        total_matches: u64,
    },
    WorkGotoResult {
        line: u64,
        char_offset: u64,
        context: String,
        context_start_line: u64,
    },

    NarrationResult {
        narration: String,
        llm_model: String,
        updated_text: String,
    },
    WritingFeedbackResult {
        feedback: String,
        llm_model: String,
    },

    HistoricalAuthorResult {
        be_id: BeId,
        name: String,
        display_name: String,
        birth_year: Option<i32>,
        death_year: Option<i32>,
        external_ids: std::collections::HashMap<String, String>,
        source_bibliography: String,
    },

    HistoricalAuthorListResult {
        authors: Vec<HistoricalAuthorEntry>,
    },

    ImportSourceWorkResult {
        work_id: BeId,
        author_id: BeId,
        title: String,
        text_length: u64,
    },

    WebFetchSanitizeResult(WebFetchSanitizePayload),

    SourceDetectResult {
        source_type: String,
        detected: bool,
        content_start_line: u64,
        content_end_line: u64,
        total_lines: u64,
        metadata: std::collections::HashMap<String, String>,
    },

    SourcePatternListResult {
        patterns: Vec<SourcePatternEntry>,
    },

    ContentMatchResult {
        matched: bool,
        work_id: Option<BeId>,
        author_id: Option<BeId>,
        score: Option<f64>,
    },

    WorkSummaryResult {
        unique_sources: u64,
        unique_authors: u64,
        version_count: u64,
        char_count: u64,
        author_contributions: Vec<AuthorContributionEntry>,
        reused_in_count: u64,
        reused_in_docs: Vec<ReusedInDocEntry>,
    },

    WorkVersionTimelineResult {
        revisions: Vec<RevisionMetaEntry>,
    },

    PassageCompositionResult {
        layers: Vec<CompositionLayerEntry>,
    },

    GlobalSearchResults {
        results: Vec<GlobalSearchResultPayload>,
        total_works_matched: u64,
    },

    #[cfg(feature = "serde")]
    ProvJsonExportResult {
        prov_json: String,
    },
    #[cfg(feature = "serde")]
    ServerDirectoryListResult {
        servers: Vec<serde_json::Value>,
    },
    #[cfg(feature = "serde")]
    ServerDirectoryAddResult {
        server_id: String,
        name: String,
        address: String,
        trusted: bool,
    },
    #[cfg(feature = "serde")]
    ServerDirectoryRemoveResult {
        removed: bool,
    },
    #[cfg(feature = "serde")]
    ServerDirectorySetTrustResult {
        server_id: u64,
        trusted: bool,
    },
    #[cfg(feature = "serde")]
    CrossServerResolveResult {
        text: String,
        hash_verified: bool,
        cached: bool,
        origin_server_id: Option<u64>,
    },
    #[cfg(feature = "serde")]
    CrossServerFetchWorkResult {
        work_id: String,
        title: String,
        text: String,
        revision: u64,
        char_count: u64,
        content_hash: String,
        origin_server_id: u64,
        origin_server_name: String,
        license: String,
        tumbler: String,
        cached: bool,
    },
    #[cfg(feature = "serde")]
    CrossServerListWorksResult {
        works: Vec<serde_json::Value>,
        origin_server_name: String,
    },
    #[cfg(feature = "serde")]
    FederatedSearchResult {
        results: Vec<serde_json::Value>,
    },
    #[cfg(feature = "serde")]
    FetchIntroductionsResult {
        introductions: Vec<serde_json::Value>,
    },
    #[cfg(feature = "serde")]
    AddDiscoveredServerResult {
        added: bool,
    },
    #[cfg(feature = "serde")]
    CrossServerLinkCreateResult {
        created: bool,
        /// FR-40: did the receiving server acknowledge the backlink
        /// notification? None = no notification was attempted (e.g.
        /// remote server not in the directory).
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        remote_accepted: Option<bool>,
        /// Human-readable failure reason when remote_accepted is
        /// false (receiving-side rejection or sender-side reachability
        /// error).
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        notify_error: Option<String>,
    },
    #[cfg(feature = "serde")]
    CrossServerLinkListResult {
        links: Vec<serde_json::Value>,
    },
    #[cfg(feature = "serde")]
    FetchRemoteIdentityResult {
        display_name: String,
        verifying_key: String,
        home_server_name: String,
        home_server_address: String,
        verified_at: u64,
    },
    #[cfg(feature = "serde")]
    TumblerResolveResult {
        work_id: Option<String>,
        title: Option<String>,
        is_local: bool,
        server: String,
    },
    #[cfg(feature = "serde")]
    BloomFilterResult {
        bits: Vec<u8>,
        num_hashes: usize,
        num_bits: usize,
        item_count: usize,
        timestamp: u64,
    },
    #[cfg(feature = "serde")]
    BloomFilterCheckResult {
        present: bool,
    },
    #[cfg(feature = "serde")]
    FederationAttestationCreateResult {
        attestation: String,
    },
    #[cfg(feature = "serde")]
    FederationAttestationVerifyResult {
        verified: bool,
    },
    #[cfg(feature = "serde")]
    FederationBundleExportResult {
        bundle_json: String,
    },
    #[cfg(feature = "serde")]
    ClusterVerificationCreateResult {
        activity_id: String,
    },
    #[cfg(feature = "serde")]
    CrossServerSignatureVerifyResult {
        valid: bool,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SourcePatternEntry {
    pub source_type: String,
    pub display_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HistoricalAuthorEntry {
    pub be_id: BeId,
    pub name: String,
    pub display_name: String,
    pub birth_year: Option<i32>,
    pub death_year: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AttributionSpanPayload {
    pub start: i64,
    pub end: i64,
    pub author_public_key: Vec<u8>,
    pub author_display_name: Option<String>,
    pub author_club_id: Option<BeId>,
    pub signature_valid: bool,
    /// FR-140: WHY validity is what it is — "verified" (stored
    /// signature checks out), "author_maintained" (signature changed
    /// by the author's own later edits; re-verified against current
    /// element provenance by the same key), or "unsigned" (no
    /// verifiable authorship — the only alarming state).
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub verification_state: Option<String>,
    pub timestamp: u64,
    pub server_id: Vec<u8>,
    pub author_type: Option<String>,
    pub llm_model: Option<String>,
    pub historical_author_id: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub source_work_id: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub transcluded_by_name: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub transcluded_by_club_id: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub provenance_chain: Option<Vec<ProvenanceHopPayload>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KeyHistoryEntryPayload {
    pub key_id: u64,
    pub not_before: u64,
    pub not_after: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutlineEntryPayload {
    pub level: u32,
    pub text: String,
    pub line: u64,
    pub char_offset: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchMatchPayload {
    pub char_offset: u64,
    pub line: u64,
    pub context: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GlobalSearchResultPayload {
    pub work_id: BeId,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub title: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub owner: Option<BeId>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub revision_count: u64,
    pub matches: Vec<SearchMatchPayload>,
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
#[cfg_attr(feature = "serde", serde(tag = "type", rename_all = "snake_case"))]
pub enum BundlePayload {
    Element {
        region: XnRegion,
        element: RangeElement,
    },
    Array {
        region: XnRegion,
        elements: Vec<RangeElement>,
    },
    PlaceHolder {
        region: XnRegion,
    },
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
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "String::is_empty")
    )]
    pub title: String,
    #[cfg_attr(feature = "serde", serde(default))]
    pub read_club: Option<BeId>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub is_source: bool,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub content_start_line: Option<u64>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub content_end_line: Option<u64>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub source_author_id: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub source_edition_info: Option<String>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub is_starred: bool,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub updated_at: Option<u64>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub content_crum: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrossServerSpanRefreshPayload {
    pub source_work: BeId,
    pub changed: bool,
    pub current_text: String,
    pub new_revision: Option<u64>,
    pub origin_hash: String,
    pub tumbler: String,
    pub span: [usize; 2],
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrossServerTransclusionPayload {
    pub dest_work: BeId,
    pub source_work: BeId,
    pub revision: u64,
    pub span: [usize; 2],
    pub tumbler: String,
    pub content_hash: String,
    pub server_name: String,
    pub text_len: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LinkPayload {
    pub link_id: BeId,
    pub origin: BeId,
    pub destination: BeId,
    pub origin_ref: Option<HyperRefPayload>,
    pub destination_ref: Option<HyperRefPayload>,
    /// Ghost metadata for the origin endpoint (archived state + title + owner),
    /// so clients can render references into archived works distinctly.
    #[cfg_attr(feature = "serde", serde(default))]
    pub origin_archived: bool,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub origin_title: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub origin_owner: Option<BeId>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub destination_archived: bool,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub destination_title: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub destination_owner: Option<BeId>,
    /// All named ends on the link (including LeftEnd/RightEnd + any custom ends).
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Vec::is_empty")
    )]
    pub named_ends: Vec<(String, HyperRefPayload)>,
    /// Link type IDs (e.g., citation=1, response=2, commentary=3).
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Vec::is_empty")
    )]
    pub link_types: Vec<u64>,
    /// Derived type ends (FR-40 Story 2): for each type id with a
    /// registered definition work, the link effectively gains an end
    /// pointing at that work — Green's three-set, materialized on
    /// read rather than stored.
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Vec::is_empty")
    )]
    pub type_ends: Vec<(u64, BeId)>,
    /// Home document (FR-40 Story 3): the work this link lives in.
    /// Absent = server-global (the shipped default).
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub home_document: Option<BeId>,
    /// Ghost state of the home document: homed links with an archived
    /// home are hidden from listings (reversible via unarchive).
    #[cfg_attr(feature = "serde", serde(default))]
    pub home_archived: bool,
    /// Cross-server notify outcome for links whose destination is on
    /// another server: did the remote accept the backlink
    /// notification (FR-40 sender feedback)? None = no notify
    /// attempted (purely local link).
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub cross_server_notify_accepted: Option<bool>,
    /// Failure reason when the remote did not accept: either the
    /// receiving server rejected it (e.g. "work not found", rate
    /// limit) or the sender could not reach it (connect/DNS error).
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub cross_server_notify_error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LinkTypeInfoPayload {
    pub type_id: u64,
    pub name: String,
    /// The definition work for this type, if registered (FR-39): the
    /// work IS the type — its body carries the convention text.
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub definition_work: Option<BeId>,
}

/// One end-set of Green's four-set link matching (FR-40 Story 4).
/// An empty spec (no works, no author) matches ANY end; a spec with
/// `work_ids` matches ends anchored in those works; a spec with
/// `author` matches ends anchored in works owned by that club.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct LinkEndpointSpecPayload {
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Vec::is_empty")
    )]
    pub work_ids: Vec<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub author: Option<BeId>,
}

impl LinkEndpointSpecPayload {
    pub fn any() -> Self {
        Self::default()
    }

    pub fn is_any(&self) -> bool {
        self.work_ids.is_empty() && self.author.is_none()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrossServerBacklinkPayload {
    pub target_work_id: BeId,
    pub origin_server_address: String,
    pub origin_server_name: String,
    pub origin_work_id: String,
    pub origin_work_title: String,
    pub excerpt: String,
    pub link_type: String,
    pub received_at: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BacklinkEntryPayload {
    pub source_work_id: BeId,
    pub link_id: BeId,
    pub link_type: String,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub excerpt: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub title: Option<String>,
    /// Ghost/archived state of the SOURCE (origin) work — clients hide
    /// backlinks whose origin document is archived.
    #[cfg_attr(feature = "serde", serde(default))]
    pub source_archived: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphNodePayload {
    pub work_id: BeId,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "String::is_empty")
    )]
    pub title: String,
    #[cfg_attr(feature = "serde", serde(default))]
    pub is_starred: bool,
    #[cfg_attr(feature = "serde", serde(default))]
    pub is_source: bool,
    pub revision_count: u64,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub author_type: Option<String>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub kind: crate::edition::WorkKind,
    #[cfg_attr(feature = "serde", serde(default))]
    pub license: crate::edition::License,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphEdgePayload {
    pub source: BeId,
    pub target: BeId,
    pub edge_type: String,
    #[cfg_attr(feature = "serde", serde(default))]
    pub weight: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphPayload {
    pub nodes: Vec<GraphNodePayload>,
    pub edges: Vec<GraphEdgePayload>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrailStopPayload {
    pub work_id: BeId,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub char_start: Option<u64>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub char_end: Option<u64>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub note: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "String::is_empty")
    )]
    pub title: String,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub server_domain: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrailPayload {
    pub trail_id: BeId,
    pub name: String,
    /// FR-37 4c: the derived work presenting this trail as an
    /// addressable edition (None until first refresh).
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub derived_work_id: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub introduction: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Vec::is_empty")
    )]
    pub categories: Vec<String>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub published: bool,
    #[cfg_attr(feature = "serde", serde(default))]
    pub owner_club: BeId,
    pub stops: Vec<TrailStopPayload>,
    pub created_at: u64,
    pub updated_at: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnnotationPayload {
    pub annotation_id: u64,
    pub kind: String,
    pub payload: String,
    #[cfg_attr(feature = "serde", serde(default))]
    pub char_start: usize,
    #[cfg_attr(feature = "serde", serde(default))]
    pub char_end: usize,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub created_by: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub created_by_name: Option<String>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub created_at: u64,
    #[cfg_attr(feature = "serde", serde(default))]
    pub is_private: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HyperRefPayload {
    pub kind: String,
    pub work_context: Option<BeId>,
    pub original_context: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub path_context: Option<Vec<RangeElementPayload>>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub excerpt: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Vec::is_empty")
    )]
    pub provenance_chain: Vec<ProvenanceHopPayload>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub start_position: Option<i64>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub end_position: Option<i64>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub cross_server_ref: Option<CrossServerRefPayload>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrossServerRefPayload {
    pub tumbler: String,
    #[cfg_attr(feature = "serde", serde(default))]
    pub origin_server_id: u64,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub origin_server_address: Option<String>,
    pub content_hash: String,
    #[cfg_attr(feature = "serde", serde(default = "default_mime_type"))]
    pub mime_type: String,
    #[cfg_attr(feature = "serde", serde(default))]
    pub byte_size: u64,
    #[cfg_attr(feature = "serde", serde(default))]
    pub origin_author: String,
    pub origin_author_key: String,
    #[cfg_attr(feature = "serde", serde(default))]
    pub origin_server_sig: String,
    #[cfg_attr(feature = "serde", serde(default))]
    pub fetched_at: u64,
    #[cfg_attr(feature = "serde", serde(default))]
    pub excerpt: String,
}

fn default_mime_type() -> String {
    "text/plain".to_string()
}

impl CrossServerRefPayload {
    pub fn from_cross_server_ref(csr: &crate::edition::links::CrossServerRef) -> Self {
        CrossServerRefPayload {
            tumbler: csr.tumbler().to_string(),
            origin_server_id: csr.origin_server_id(),
            origin_server_address: csr.origin_server_address().map(|s| s.to_string()),
            content_hash: hex::encode(csr.content_hash()),
            mime_type: csr.mime_type().to_string(),
            byte_size: csr.byte_size(),
            origin_author: csr.origin_author().to_string(),
            origin_author_key: hex::encode(csr.origin_author_key()),
            origin_server_sig: hex::encode(csr.origin_server_sig()),
            fetched_at: csr.fetched_at(),
            excerpt: csr.excerpt().to_string(),
        }
    }

    pub fn to_cross_server_ref(&self) -> Option<crate::edition::links::CrossServerRef> {
        let content_hash = hex::decode(&self.content_hash).ok()?;
        if content_hash.len() != 32 {
            return None;
        }
        let mut hash_arr = [0u8; 32];
        hash_arr.copy_from_slice(&content_hash);

        let author_key = hex::decode(&self.origin_author_key).ok()?;
        if author_key.len() != 32 {
            return None;
        }
        let mut key_arr = [0u8; 32];
        key_arr.copy_from_slice(&author_key);

        let sig = if self.origin_server_sig.is_empty() {
            Vec::new()
        } else {
            hex::decode(&self.origin_server_sig).unwrap_or_default()
        };

        let mut csr = crate::edition::links::CrossServerRef::new(
            &self.tumbler,
            hash_arr,
            &self.origin_author,
            key_arr,
        );
        // The address normally travels inside a domain tumbler
        // (`"host:port".work.v.r`); when the tumbler is numeric, honor
        // an explicit origin_server_address on the payload so the
        // backlink notify can still reach the origin server (FR-40
        // sender feedback).
        if csr.origin_server_address().is_none() {
            if let Some(addr) = self
                .origin_server_address
                .as_ref()
                .filter(|a| !a.is_empty())
            {
                csr = csr.with_origin_server_address(addr.clone());
            }
        }
        csr = csr
            .with_mime_type(&self.mime_type)
            .with_byte_size(self.byte_size)
            .with_server_sig(sig)
            .with_fetched_at(self.fetched_at)
            .with_excerpt(&self.excerpt);
        Some(csr)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProvenanceHopPayload {
    pub source_work_id: BeId,
    pub link_id: BeId,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub source_work_title: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub source_author_name: Option<String>,
    /// The work this hop's content was transcluded *into* (the link's
    /// destination). Lets clients reconstruct the ancestry DAG instead of
    /// reading a flat link-id-sorted list as a linear chain.
    #[cfg_attr(feature = "serde", serde(default))]
    pub dest_work_id: BeId,
}

/// One hop in a transclusion `again()` chain (Gold's recursive transclusion walk).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgainHopPayload {
    pub work_id: BeId,
    pub work_title: String,
    pub element_text: String,
    pub author_name: String,
    pub author_type: String,
    pub is_original: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkLifecycleEventPayload {
    pub kind: String,
    pub actor_club: BeId,
    pub timestamp: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkGhostInfoPayload {
    pub work_id: BeId,
    pub title: String,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub owner: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub archived_by: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub archived_at: Option<u64>,
    pub lifecycle_history: Vec<WorkLifecycleEventPayload>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpanRangePayload {
    pub source_work_id: BeId,
    pub char_start: usize,
    pub char_end: usize,
    pub flat_start: usize,
    pub flat_end: usize,
    pub content_len: usize,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    pub otree_position: Option<usize>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    pub resolved_content: Option<String>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    pub placed_at: Option<u64>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    pub placed_by: Option<Option<u64>>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    pub source_changed: Option<bool>,
}

impl SpanRangePayload {
    pub fn from_span_range(sr: &crate::edition::compound::SpanRange) -> Self {
        SpanRangePayload {
            source_work_id: sr.source_work_id,
            char_start: sr.char_start,
            char_end: sr.char_end,
            flat_start: sr.flat_start,
            flat_end: sr.flat_end,
            content_len: sr.content_len,
            otree_position: Some(sr.otree_position),
            resolved_content: Some(sr.resolved_content.clone()),
            placed_at: Some(sr.placed_at),
            placed_by: Some(sr.placed_by),
            source_changed: Some(sr.source_changed),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RangeElementPayload {
    #[cfg_attr(feature = "serde", serde(rename = "type"))]
    pub elem_type: String,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub text: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub label_id: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub work_id: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub edition_id: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub id_holder: Option<u64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        alias = "content_hash"
    )]
    pub blob_hash: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none", alias = "mime_type")
    )]
    pub blob_mime: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none", alias = "byte_size")
    )]
    pub blob_size: Option<u64>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none", alias = "width")
    )]
    pub blob_width: Option<u32>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none", alias = "height")
    )]
    pub blob_height: Option<u32>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none", alias = "caption")
    )]
    pub blob_caption: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub transclusion_source: Option<u64>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub transclusion_start: Option<usize>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub transclusion_end: Option<usize>,
    // Virtual elements (FR-37 Phase 3): spec fields. `virtual_revision`
    // is REQUIRED — unpinned virtuals are invalid on the wire.
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub virtual_source: Option<u64>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub virtual_revision: Option<u64>,
}

impl RangeElementPayload {
    pub fn to_range_element(&self) -> Option<crate::edition::RangeElement> {
        match self.elem_type.as_str() {
            "text" => self
                .text
                .as_ref()
                .map(|t| crate::edition::RangeElement::text(t)),
            "label" => self.label_id.map(|id| {
                crate::edition::RangeElement::label(
                    id,
                    crate::edition::RangeElement::text(self.text.as_deref().unwrap_or("")),
                )
            }),
            "work" => self.work_id.map(crate::edition::RangeElement::work),
            "edition" => self.edition_id.map(crate::edition::RangeElement::edition),
            "id_holder" => self.id_holder.map(crate::edition::RangeElement::id_holder),
            "blob" => self.blob_hash.as_ref().and_then(|h| {
                let h_u64 = h.parse::<u64>().ok()?;
                let mime = self.blob_mime.clone().unwrap_or_default();
                let size = self.blob_size.unwrap_or(0);
                Some(crate::edition::RangeElement::blob_with_caption(
                    h_u64,
                    mime,
                    size,
                    self.blob_width,
                    self.blob_height,
                    self.blob_caption.clone(),
                ))
            }),
            "transclusion" => {
                if let (Some(src), Some(start), Some(end)) = (
                    self.transclusion_source,
                    self.transclusion_start,
                    self.transclusion_end,
                ) {
                    Some(crate::edition::RangeElement::transclusion(src, start, end))
                } else {
                    None
                }
            }
            "virtual" => {
                // FR-37 Phase 3: virtual elements cross the wire with
                // their PINNED spec. Revision is mandatory — unpinned
                // virtuals would break replica determinism.
                if let (Some(src), Some(start), Some(end), Some(rev)) = (
                    self.virtual_source,
                    self.transclusion_start,
                    self.transclusion_end,
                    self.virtual_revision,
                ) {
                    Some(crate::edition::RangeElement::virtual_element(
                        crate::edition::range_element::VirtualSpec {
                            source_work_id: src,
                            char_start: start,
                            char_end: end,
                            revision: rev,
                            placed_at: 0,
                            placed_by: None,
                        },
                    ))
                } else {
                    None
                }
            }
            _ => None,
        }
    }

    pub fn from_range_element(re: &crate::edition::RangeElement) -> Self {
        match re {
            crate::edition::RangeElement::Text { text } => RangeElementPayload {
                elem_type: "text".to_string(),
                text: Some(text.clone()),
                label_id: None,
                work_id: None,
                edition_id: None,
                id_holder: None,
                blob_hash: None,
                blob_mime: None,
                blob_size: None,
                blob_width: None,
                blob_height: None,
                blob_caption: None,
                transclusion_source: None,
                transclusion_start: None,
                transclusion_end: None,
                virtual_source: None,
                virtual_revision: None,
            },
            crate::edition::RangeElement::Label { label_id, inner } => RangeElementPayload {
                elem_type: "label".to_string(),
                text: inner.as_text().map(|s| s.to_string()),
                label_id: Some(label_id.0),
                work_id: None,
                edition_id: None,
                id_holder: None,
                blob_hash: None,
                blob_mime: None,
                blob_size: None,
                blob_width: None,
                blob_height: None,
                blob_caption: None,
                transclusion_source: None,
                transclusion_start: None,
                transclusion_end: None,
                virtual_source: None,
                virtual_revision: None,
            },
            crate::edition::RangeElement::Work { work_id } => RangeElementPayload {
                elem_type: "work".to_string(),
                text: None,
                label_id: None,
                work_id: Some(work_id.0),
                edition_id: None,
                id_holder: None,
                blob_hash: None,
                blob_mime: None,
                blob_size: None,
                blob_width: None,
                blob_height: None,
                blob_caption: None,
                transclusion_source: None,
                transclusion_start: None,
                transclusion_end: None,
                virtual_source: None,
                virtual_revision: None,
            },
            crate::edition::RangeElement::Edition { edition_id } => RangeElementPayload {
                elem_type: "edition".to_string(),
                text: None,
                label_id: None,
                work_id: None,
                edition_id: Some(edition_id.0),
                id_holder: None,
                blob_hash: None,
                blob_mime: None,
                blob_size: None,
                blob_width: None,
                blob_height: None,
                blob_caption: None,
                transclusion_source: None,
                transclusion_start: None,
                transclusion_end: None,
                virtual_source: None,
                virtual_revision: None,
            },
            crate::edition::RangeElement::IDHolder { id } => RangeElementPayload {
                elem_type: "id_holder".to_string(),
                text: None,
                label_id: None,
                work_id: None,
                edition_id: None,
                id_holder: Some(*id),
                blob_hash: None,
                blob_mime: None,
                blob_size: None,
                blob_width: None,
                blob_height: None,
                blob_caption: None,
                transclusion_source: None,
                transclusion_start: None,
                transclusion_end: None,
                virtual_source: None,
                virtual_revision: None,
            },
            crate::edition::RangeElement::Blob {
                content_hash,
                mime_type,
                byte_size,
                width,
                height,
                caption,
            } => RangeElementPayload {
                elem_type: "blob".to_string(),
                text: None,
                label_id: None,
                work_id: None,
                edition_id: None,
                id_holder: None,
                blob_hash: Some(content_hash.to_string()),
                blob_mime: Some(mime_type.clone()),
                blob_size: Some(*byte_size),
                blob_width: *width,
                blob_height: *height,
                blob_caption: caption.clone(),
                transclusion_source: None,
                transclusion_start: None,
                transclusion_end: None,
                virtual_source: None,
                virtual_revision: None,
            },
            crate::edition::RangeElement::Transclusion {
                source_work_id,
                char_start,
                char_end,
                ..
            } => RangeElementPayload {
                elem_type: "transclusion".to_string(),
                text: None,
                label_id: None,
                work_id: None,
                edition_id: None,
                id_holder: None,
                blob_hash: None,
                blob_mime: None,
                blob_size: None,
                blob_width: None,
                blob_height: None,
                blob_caption: None,
                transclusion_source: Some(*source_work_id),
                transclusion_start: Some(*char_start),
                transclusion_end: Some(*char_end),
                virtual_source: None,
                virtual_revision: None,
            },
            crate::edition::RangeElement::Virtual { spec, .. } => RangeElementPayload {
                elem_type: "virtual".to_string(),
                text: None,
                label_id: None,
                work_id: None,
                edition_id: None,
                id_holder: None,
                blob_hash: None,
                blob_mime: None,
                blob_size: None,
                blob_width: None,
                blob_height: None,
                blob_caption: None,
                transclusion_source: None,
                transclusion_start: Some(spec.char_start),
                transclusion_end: Some(spec.char_end),
                virtual_source: Some(spec.source_work_id),
                virtual_revision: Some(spec.revision),
            },
            _ => RangeElementPayload {
                elem_type: "other".to_string(),
                text: None,
                label_id: None,
                work_id: None,
                edition_id: None,
                id_holder: None,
                blob_hash: None,
                blob_mime: None,
                blob_size: None,
                blob_width: None,
                blob_height: None,
                blob_caption: None,
                transclusion_source: None,
                transclusion_start: None,
                transclusion_end: None,
                virtual_source: None,
                virtual_revision: None,
            },
        }
    }
}

impl HyperRefPayload {
    pub fn from_hyper_ref(hr: &crate::edition::links::HyperRef) -> Self {
        let path_context = hr.path_context().map(|p| {
            p.labels()
                .iter()
                .map(RangeElementPayload::from_range_element)
                .collect()
        });
        let excerpt = hr.excerpt().and_then(|ed| {
            let entries = ed.all_entries();
            let text: String = entries
                .iter()
                .filter_map(|(_, c)| c.element.as_text())
                .collect();
            if text.is_empty() {
                None
            } else {
                Some(text)
            }
        });
        let provenance_chain = hr
            .provenance_chain()
            .iter()
            .map(|hop| ProvenanceHopPayload {
                source_work_id: hop.source_work_id(),
                link_id: hop.link_id(),
                source_work_title: None,
                source_author_name: None,
                dest_work_id: 0,
            })
            .collect();
        HyperRefPayload {
            kind: if hr.is_single() {
                "single".to_string()
            } else {
                "multi".to_string()
            },
            work_context: hr.work_context(),
            original_context: hr.original_context(),
            path_context,
            excerpt,
            provenance_chain,
            start_position: hr.start_position(),
            end_position: hr.end_position(),
            cross_server_ref: hr
                .cross_server_ref()
                .map(CrossServerRefPayload::from_cross_server_ref),
        }
    }

    pub fn to_hyper_ref(&self, fallback_work_id: BeId) -> crate::edition::links::HyperRef {
        use crate::edition::links::{HyperRef, Path, ProvenanceHop};

        let excerpt = self
            .excerpt
            .as_deref()
            .map(crate::edition::Edition::from_text);
        let path_context = self.path_context.as_ref().and_then(|labels| {
            let elems: Vec<crate::edition::RangeElement> =
                labels.iter().filter_map(|l| l.to_range_element()).collect();
            if elems.is_empty() {
                None
            } else {
                Some(Path::new(elems))
            }
        });
        let provenance_chain: Vec<ProvenanceHop> = self
            .provenance_chain
            .iter()
            .map(|hop| ProvenanceHop::new(hop.source_work_id, hop.link_id))
            .collect();
        let work_context = self.work_context.or_else(|| Some(fallback_work_id));
        let mut hr = HyperRef::single(excerpt, work_context, self.original_context, path_context);
        hr = hr.with_span(self.start_position, self.end_position);
        if !provenance_chain.is_empty() {
            hr = hr.with_provenance_chain(provenance_chain);
        }
        if let Some(csr_payload) = &self.cross_server_ref {
            if let Some(csr) = csr_payload.to_cross_server_ref() {
                hr = hr.with_cross_server_ref(csr);
            }
        }
        hr
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExcerptPositionPayload {
    pub start: usize,
    pub end: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TracePositionPayload {
    pub branch_id: u64,
    pub position: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RenderedElementPayload {
    pub position: i64,
    pub text: String,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub source_work_id: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub source_author_name: Option<String>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub is_transcluded: bool,
    pub transclusion_sources: Vec<TransclusionSourcePayload>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransclusionSourcePayload {
    pub work_id: BeId,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub title: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub author_name: Option<String>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub is_direct: bool,
}

pub mod u64_hex {
    use serde::{de::Error, Deserializer, Serializer};
    pub fn serialize<S: Serializer>(v: &u64, s: S) -> Result<S::Ok, S::Error> {
        s.serialize_str(&format!("{:016x}", v))
    }
    pub fn deserialize<'de, D: Deserializer<'de>>(d: D) -> Result<u64, D::Error> {
        let s = <String as serde::Deserialize>::deserialize(d)?;
        u64::from_str_radix(&s, 16).map_err(D::Error::custom)
    }
}

pub mod u64_option_hex {
    use serde::{de::Error, Deserializer, Serializer};
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
    #[serde()]
    pub content_hash: String,
    pub byte_size: u64,
    pub mime_type: String,
    #[serde(
        serialize_with = "u64_option_hex::serialize",
        deserialize_with = "u64_option_hex::deserialize"
    )]
    pub preview_hash: Option<u64>,
    pub width: Option<u32>,
    pub height: Option<u32>,
}

impl BlobMetaPayload {
    pub fn from_blob_meta(meta: &crate::edition::BlobMeta) -> Self {
        BlobMetaPayload {
            content_hash: meta.hash_u64().to_string(),
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
    #[serde()]
    pub overlay_hash: u64,
    #[serde()]
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
    pub public_club_id: BeId,
    pub llm_enabled: bool,
    pub llm_usage: crate::server::ollama::LlmUsageSummary,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WebFetchSanitizePayload {
    /// Ammonia-cleaned HTML fragment (whitelisted tags only).
    pub sanitized_html: String,
    /// Plain-text extraction (readability-lite).
    pub text: String,
    pub final_url: String,
    pub content_type: String,
    /// Set when import_as_source created a frozen work.
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub imported_work_id: Option<BeId>,
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
#[cfg_attr(feature = "serde", serde(rename_all = "snake_case"))]
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
    #[cfg(feature = "serde")]
    ProvJsonExportFailed,
    #[cfg(feature = "serde")]
    ProvJsonImportFailed,
    #[cfg(feature = "serde")]
    FederationAttestationFailed,
    #[cfg(feature = "serde")]
    FederationVerificationFailed,
    #[cfg(feature = "serde")]
    CrossServerSignatureInvalid,
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
            crate::server::ServerError::NotAcceptingConnections => {
                ErrorCode::NotAcceptingConnections
            }
            crate::server::ServerError::ReadClubIrrevocablyRemoved(_) => {
                ErrorCode::IrrevocablyRemoved
            }
            crate::server::ServerError::NotOwner(_) => ErrorCode::NotAuthorized,
            #[cfg(feature = "serde")]
            crate::server::ServerError::ProvJsonExportFailed(_) => ErrorCode::ProvJsonExportFailed,
            #[cfg(feature = "serde")]
            crate::server::ServerError::ProvJsonImportFailed(_) => ErrorCode::ProvJsonImportFailed,
            #[cfg(feature = "serde")]
            crate::server::ServerError::FederationAttestationFailed(_) => {
                ErrorCode::FederationAttestationFailed
            }
            #[cfg(feature = "serde")]
            crate::server::ServerError::FederationVerificationFailed(_) => {
                ErrorCode::FederationVerificationFailed
            }
            #[cfg(feature = "serde")]
            crate::server::ServerError::CrossServerSignatureInvalid(_) => {
                ErrorCode::CrossServerSignatureInvalid
            }
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "serde", serde(rename_all = "snake_case"))]
pub enum DetectorType {
    Status,
    Revision,
    Fill,
    ContentTranscluders,
    ContentWorks,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "serde", serde(rename_all = "snake_case"))]
pub struct SubscribeRequest {
    pub detector_type: DetectorType,
    pub target_id: BeId,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(u8)]
pub enum EventCode {
    WorkGrabbed = 0x01,
    WorkReleased = 0x02,
    WorkRevised = 0x03,
    RangeFilled = 0x04,
    ElementFilled = 0x05,
    Done = 0x06,
    ContentMatch = 0x07,
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
            0x07 => Some(EventCode::ContentMatch),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "serde", serde(rename_all = "snake_case"))]
pub struct WireEvent {
    pub subscription_id: u16,
    pub event: EventPayload,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(
    feature = "serde",
    serde(tag = "type", content = "payload", rename_all = "snake_case")
)]
pub enum EventPayload {
    WorkGrabbed {
        work_be_id: BeId,
        session_id: u64,
    },
    WorkReleased {
        work_be_id: BeId,
        session_id: u64,
    },
    WorkRevised {
        work_be_id: BeId,
        revision: u64,
        session_id: u64,
    },
    RangeFilled {
        edition_be_id: BeId,
        region: XnRegion,
    },
    ElementFilled {
        element_be_id: BeId,
    },
    Done {
        operation_id: u64,
    },
    ContentMatch {
        fossil_id: u64,
        edition_be_id: BeId,
        is_direct: bool,
        work_be_id: Option<BeId>,
        title: Option<String>,
    },
    CrdtTextUpdate {
        work_id: BeId,
        text: String,
    },
    CrdtTextDelta {
        work_id: BeId,
        ops: Vec<TextDeltaOp>,
    },
    CrdtAwarenessUpdate {
        work_id: BeId,
        state: crate::server::crdt_manager::AwarenessState,
    },
    CrdtAwarenessRemove {
        work_id: BeId,
        session_id: u64,
    },
    CompoundSourceChanged {
        compound_work_id: BeId,
        source_work_id: BeId,
    },
}

impl EventPayload {
    pub fn from_event(event: &crate::server::Event) -> Self {
        match event {
            crate::server::Event::WorkGrabbed {
                work_be_id,
                session_id,
            } => EventPayload::WorkGrabbed {
                work_be_id: *work_be_id,
                session_id: session_id.as_u64(),
            },
            crate::server::Event::WorkReleased {
                work_be_id,
                session_id,
            } => EventPayload::WorkReleased {
                work_be_id: *work_be_id,
                session_id: session_id.as_u64(),
            },
            crate::server::Event::WorkRevised {
                work_be_id,
                revision,
                session_id,
            } => EventPayload::WorkRevised {
                work_be_id: *work_be_id,
                revision: *revision,
                session_id: session_id.as_u64(),
            },
            crate::server::Event::RangeFilled {
                edition_be_id,
                region,
            } => EventPayload::RangeFilled {
                edition_be_id: *edition_be_id,
                region: region.clone(),
            },
            crate::server::Event::ElementFilled { element_be_id } => EventPayload::ElementFilled {
                element_be_id: *element_be_id,
            },
            crate::server::Event::Done { operation_id } => EventPayload::Done {
                operation_id: *operation_id,
            },
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WireFrame {
    pub v: u8,
    #[cfg_attr(feature = "serde", serde(rename = "type"))]
    pub msg_type: String,
    pub id: u16,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    pub op: Option<String>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    pub payload: Option<serde_json::Value>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    pub value: Option<ResponseValue>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    pub code: Option<ErrorCode>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    pub message: Option<String>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    pub event: Option<EventPayload>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthorContributionEntry {
    pub club_id: BeId,
    pub display_name: String,
    pub char_count: u64,
    pub percentage: f64,
    #[cfg_attr(feature = "serde", serde(default))]
    pub author_type: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RevisionMetaEntry {
    pub revision: u64,
    pub char_count: u64,
    pub author_club_id: Option<BeId>,
    pub author_display_name: Option<String>,
    pub author_type: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub timestamp: Option<u64>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub content_crum: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReusedInDocEntry {
    pub work_id: BeId,
    pub title: String,
    pub shared_char_count: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompositionLayerEntry {
    pub revision: u64,
    pub author_club_id: Option<BeId>,
    pub author_display_name: Option<String>,
    pub text: String,
    pub operation: String,
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

#[cfg(test)]
mod fr37_wire_tests {
    use super::*;

    #[test]
    fn virtual_element_round_trip() {
        use crate::edition::range_element::{RangeElement, VirtualSpec};
        let spec = VirtualSpec {
            source_work_id: 0xABCD,
            char_start: 3,
            char_end: 20,
            revision: 12,
            placed_at: 1234,
            placed_by: Some(7),
        };
        let elem = RangeElement::virtual_element(spec);

        // Encode -> decode: spec survives; placed_at/by are placement
        // metadata and intentionally not transported (decode stamps
        // neutral values — same convention as other payload types).
        let payload = RangeElementPayload::from_range_element(&elem);
        assert_eq!(payload.elem_type, "virtual");
        assert_eq!(payload.virtual_source, Some(0xABCD));
        assert_eq!(payload.virtual_revision, Some(12));
        assert_eq!(payload.transclusion_start, Some(3));
        assert_eq!(payload.transclusion_end, Some(20));

        let decoded = payload.to_range_element().expect("virtual decodes");
        let got = decoded.virtual_spec().expect("virtual spec");
        assert_eq!(got.source_work_id, spec.source_work_id);
        assert_eq!(got.char_start, spec.char_start);
        assert_eq!(got.char_end, spec.char_end);
        assert_eq!(got.revision, spec.revision, "pin survives the wire");

        // Spec-fingerprint identical across the round trip (replica
        // determinism through the protocol).
        assert_eq!(decoded.content_fingerprint(), elem.content_fingerprint());
    }

    #[test]
    fn virtual_without_revision_rejected() {
        // Unpinned virtuals are invalid on the wire: without a pinned
        // revision, resolution would diverge across replicas.
        let payload = RangeElementPayload {
            elem_type: "virtual".to_string(),
            text: None,
            label_id: None,
            work_id: None,
            edition_id: None,
            id_holder: None,
            blob_hash: None,
            blob_mime: None,
            blob_size: None,
            blob_width: None,
            blob_height: None,
            blob_caption: None,
            transclusion_source: None,
            transclusion_start: Some(0),
            transclusion_end: Some(5),
            virtual_source: Some(42),
            virtual_revision: None,
        };
        assert!(payload.to_range_element().is_none());
    }

    #[test]
    fn virtual_survives_json_serialization() {
        use crate::edition::range_element::{RangeElement, VirtualSpec};
        let spec = VirtualSpec {
            source_work_id: 9,
            char_start: 0,
            char_end: 4,
            revision: 3,
            placed_at: 0,
            placed_by: None,
        };
        let elem = RangeElement::virtual_element(spec);
        let payload = RangeElementPayload::from_range_element(&elem);
        let json = serde_json::to_string(&payload).unwrap();
        let back: RangeElementPayload = serde_json::from_str(&json).unwrap();
        assert_eq!(
            back.to_range_element().unwrap().content_fingerprint(),
            elem.content_fingerprint()
        );
    }
}
