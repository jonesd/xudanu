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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::server::SessionId;

    #[test]
    fn display_simple_variants() {
        assert_eq!(ServerError::NotAuthorized.to_string(), "not authorized");
        assert_eq!(ServerError::SessionRequired.to_string(), "session required");
        assert_eq!(
            ServerError::AdminRequired.to_string(),
            "admin authority required"
        );
        assert_eq!(
            ServerError::ServerShuttingDown.to_string(),
            "server is shutting down"
        );
        assert_eq!(
            ServerError::NotAcceptingConnections.to_string(),
            "server is not accepting connections"
        );
    }

    #[test]
    fn display_string_field_variants() {
        assert_eq!(
            ServerError::NotFound("work-7".into()).to_string(),
            "not found: work-7"
        );
        assert_eq!(
            ServerError::AlreadyExists("foo".into()).to_string(),
            "already exists: foo"
        );
        assert_eq!(
            ServerError::InvalidArgument("bad".into()).to_string(),
            "invalid argument: bad"
        );
        assert_eq!(
            ServerError::LockFailed("busy".into()).to_string(),
            "lock failed: busy"
        );
        assert_eq!(
            ServerError::Internal("boom".into()).to_string(),
            "internal error: boom"
        );
        assert_eq!(
            ServerError::Unauthorized("nope".into()).to_string(),
            "unauthorized: nope"
        );
    }

    #[test]
    fn display_not_grabbed() {
        assert_eq!(
            ServerError::NotGrabbed(42).to_string(),
            "work 42 not grabbed"
        );
    }

    #[test]
    fn display_already_grabbed_with_session() {
        let err = ServerError::AlreadyGrabbed {
            work: 7,
            by: Some(SessionId::new(3)),
        };
        assert_eq!(
            err.to_string(),
            "work 7 is locked by session session:3 (use release first or wait for them to finish)"
        );
    }

    #[test]
    fn display_already_grabbed_without_session() {
        let err = ServerError::AlreadyGrabbed { work: 7, by: None };
        assert_eq!(err.to_string(), "work 7 is locked by another session");
    }

    #[test]
    fn display_type_mismatch() {
        let err = ServerError::TypeMismatch {
            expected: "Text".into(),
            found: "Link".into(),
        };
        assert_eq!(err.to_string(), "type mismatch: expected Text, found Link");
    }

    #[test]
    fn display_be_id_variants() {
        assert_eq!(
            ServerError::WorkNotFound(5).to_string(),
            "work not found: 5"
        );
        assert_eq!(
            ServerError::EditionNotFound(9).to_string(),
            "edition not found: 9"
        );
        assert_eq!(
            ServerError::ReadClubIrrevocablyRemoved(3).to_string(),
            "read club irrevocably removed for work 3"
        );
        assert_eq!(ServerError::NotOwner(8).to_string(), "not owner of work 8");
        assert_eq!(
            ServerError::ClubNotFound(11).to_string(),
            "identity not found (id 11). Create an identity first with 'New Identity'"
        );
    }

    #[test]
    fn display_session_not_found() {
        let err = ServerError::SessionNotFound(SessionId::new(42));
        assert_eq!(err.to_string(), "session not found: SessionId(42)");
    }

    #[cfg(feature = "serde")]
    #[test]
    fn display_serde_only_variants() {
        assert_eq!(
            ServerError::ProvJsonExportFailed("x".into()).to_string(),
            "PROV-JSON export failed: x"
        );
        assert_eq!(
            ServerError::ProvJsonImportFailed("y".into()).to_string(),
            "PROV-JSON import failed: y"
        );
        assert_eq!(
            ServerError::FederationAttestationFailed("z".into()).to_string(),
            "federation attestation failed: z"
        );
        assert_eq!(
            ServerError::FederationVerificationFailed("w".into()).to_string(),
            "federation verification failed: w"
        );
        assert_eq!(
            ServerError::CrossServerSignatureInvalid("k".into()).to_string(),
            "cross-server signature invalid: k"
        );
    }

    #[cfg(feature = "serde")]
    #[test]
    fn from_string_converts_to_internal() {
        let err: ServerError = "something broke".to_string().into();
        match err {
            ServerError::Internal(s) => assert_eq!(s, "something broke"),
            other => panic!("expected Internal, got {:?}", other),
        }
    }
}
