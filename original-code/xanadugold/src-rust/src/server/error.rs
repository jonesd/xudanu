use crate::edition::BeId;

#[derive(Debug)]
pub enum ServerError {
    NotAuthorized,
    NotFound(String),
    AlreadyExists(String),
    NotGrabbed(BeId),
    AlreadyGrabbed { work: BeId, by: Option<super::session::SessionId> },
    SessionRequired,
    InvalidArgument(String),
    TypeMismatch { expected: &'static str, found: &'static str },
    LockFailed(String),
    SessionNotFound(super::session::SessionId),
    WorkNotFound(BeId),
    ClubNotFound(BeId),
    EditionNotFound(BeId),
    Internal(String),
}

impl std::fmt::Display for ServerError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ServerError::NotAuthorized => write!(f, "not authorized"),
            ServerError::NotFound(s) => write!(f, "not found: {}", s),
            ServerError::AlreadyExists(s) => write!(f, "already exists: {}", s),
            ServerError::NotGrabbed(id) => write!(f, "work {} not grabbed", id),
            ServerError::AlreadyGrabbed { work, by } => {
                write!(f, "work {} already grabbed by {:?}", work, by)
            }
            ServerError::SessionRequired => write!(f, "session required"),
            ServerError::InvalidArgument(s) => write!(f, "invalid argument: {}", s),
            ServerError::TypeMismatch { expected, found } => {
                write!(f, "type mismatch: expected {}, found {}", expected, found)
            }
            ServerError::LockFailed(s) => write!(f, "lock failed: {}", s),
            ServerError::SessionNotFound(id) => write!(f, "session not found: {:?}", id),
            ServerError::WorkNotFound(id) => write!(f, "work not found: {}", id),
            ServerError::ClubNotFound(id) => write!(f, "club not found: {}", id),
            ServerError::EditionNotFound(id) => write!(f, "edition not found: {}", id),
            ServerError::Internal(s) => write!(f, "internal error: {}", s),
        }
    }
}

impl std::error::Error for ServerError {}
