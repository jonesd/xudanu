use crate::edition::BeId;

#[derive(Debug)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum ServerError {
    NotAuthorized,
    NotFound(String),
    AlreadyExists(String),
    NotGrabbed(BeId),
    AlreadyGrabbed {
        work: BeId,
        by: Option<super::session::SessionId>,
    },
    SessionRequired,
    InvalidArgument(String),
    TypeMismatch {
        expected: String,
        found: String,
    },
    LockFailed(String),
    SessionNotFound(super::session::SessionId),
    WorkNotFound(BeId),
    ClubNotFound(BeId),
    EditionNotFound(BeId),
    Internal(String),
    AdminRequired,
    Unauthorized(String),
    ServerShuttingDown,
    NotAcceptingConnections,
    ReadClubIrrevocablyRemoved(BeId),
    NotOwner(BeId),
    #[cfg(feature = "serde")]
    ProvJsonExportFailed(String),
    #[cfg(feature = "serde")]
    ProvJsonImportFailed(String),
    #[cfg(feature = "serde")]
    FederationAttestationFailed(String),
    #[cfg(feature = "serde")]
    FederationVerificationFailed(String),
    #[cfg(feature = "serde")]
    CrossServerSignatureInvalid(String),
}

impl std::fmt::Display for ServerError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ServerError::NotAuthorized => write!(f, "not authorized"),
            ServerError::NotFound(s) => write!(f, "not found: {}", s),
            ServerError::AlreadyExists(s) => write!(f, "already exists: {}", s),
            ServerError::NotGrabbed(id) => write!(f, "work {} not grabbed", id),
            ServerError::AlreadyGrabbed { work, by } => match by {
                Some(sid) => write!(f, "work {} is locked by session {} (use release first or wait for them to finish)", work, sid),
                None => write!(f, "work {} is locked by another session", work),
            }
            ServerError::SessionRequired => write!(f, "session required"),
            ServerError::InvalidArgument(s) => write!(f, "invalid argument: {}", s),
            ServerError::TypeMismatch { expected, found } => {
                write!(f, "type mismatch: expected {}, found {}", expected, found)
            }
            ServerError::LockFailed(s) => write!(f, "lock failed: {}", s),
            ServerError::SessionNotFound(id) => write!(f, "session not found: {:?}", id),
            ServerError::WorkNotFound(id) => write!(f, "work not found: {}", id),
            ServerError::ClubNotFound(id) => write!(f, "identity not found (id {}). Create an identity first with 'New Identity'", id),
            ServerError::EditionNotFound(id) => write!(f, "edition not found: {}", id),
            ServerError::Internal(s) => write!(f, "internal error: {}", s),
            ServerError::AdminRequired => write!(f, "admin authority required"),
            ServerError::Unauthorized(s) => write!(f, "unauthorized: {}", s),
            ServerError::ServerShuttingDown => write!(f, "server is shutting down"),
            ServerError::NotAcceptingConnections => write!(f, "server is not accepting connections"),
            ServerError::ReadClubIrrevocablyRemoved(id) => write!(f, "read club irrevocably removed for work {}", id),
            ServerError::NotOwner(id) => write!(f, "not owner of work {}", id),
            #[cfg(feature = "serde")]
            ServerError::ProvJsonExportFailed(s) => write!(f, "PROV-JSON export failed: {}", s),
            #[cfg(feature = "serde")]
            ServerError::ProvJsonImportFailed(s) => write!(f, "PROV-JSON import failed: {}", s),
            #[cfg(feature = "serde")]
            ServerError::FederationAttestationFailed(s) => write!(f, "federation attestation failed: {}", s),
            #[cfg(feature = "serde")]
            ServerError::FederationVerificationFailed(s) => write!(f, "federation verification failed: {}", s),
            #[cfg(feature = "serde")]
            ServerError::CrossServerSignatureInvalid(s) => write!(f, "cross-server signature invalid: {}", s),
        }
    }
}

#[cfg(feature = "serde")]
impl From<String> for ServerError {
    fn from(s: String) -> Self {
        ServerError::Internal(s)
    }
}

impl std::error::Error for ServerError {}
