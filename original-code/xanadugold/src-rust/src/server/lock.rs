use std::collections::HashMap;

use crate::edition::BeId;

use super::error::ServerError;
use super::keymaster::KeyMaster;

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
#[cfg_attr(feature = "serde", serde(rename_all = "snake_case"))]
pub enum LockCredential {
    Boo,
    ChallengeResponse(Vec<u8>),
    Password(Vec<u8>),
    Named {
        name: String,
        credential: Box<LockCredential>,
    },
}

pub trait Lock: Send + Sync + std::fmt::Debug {
    fn try_open(&self, credential: &LockCredential) -> Result<KeyMaster, ServerError>;
    fn club_id(&self) -> Option<BeId>;
    fn clone_boxed(&self) -> Box<dyn Lock>;
    fn as_any(&self) -> &dyn std::any::Any;
}

impl Clone for Box<dyn Lock> {
    fn clone(&self) -> Self {
        self.clone_boxed()
    }
}

#[derive(Debug, Clone)]
pub struct BooLock {
    club_id: BeId,
}

impl BooLock {
    pub fn new(club_id: BeId) -> Self {
        BooLock { club_id }
    }
}

impl Lock for BooLock {
    fn try_open(&self, credential: &LockCredential) -> Result<KeyMaster, ServerError> {
        match credential {
            LockCredential::Boo => Ok(KeyMaster::make(self.club_id)),
            _ => Err(ServerError::LockFailed(
                "boo lock requires Boo credential".into(),
            )),
        }
    }

    fn club_id(&self) -> Option<BeId> {
        Some(self.club_id)
    }

    fn clone_boxed(&self) -> Box<dyn Lock> {
        Box::new(self.clone())
    }

    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
}

#[derive(Debug, Clone)]
pub struct WallLock;

impl WallLock {
    pub fn new() -> Self {
        WallLock
    }
}

impl Lock for WallLock {
    fn try_open(&self, _credential: &LockCredential) -> Result<KeyMaster, ServerError> {
        Err(ServerError::LockFailed("wall lock cannot be opened".into()))
    }

    fn club_id(&self) -> Option<BeId> {
        None
    }

    fn clone_boxed(&self) -> Box<dyn Lock> {
        Box::new(self.clone())
    }

    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
}

#[derive(Debug, Clone)]
pub struct ChallengeLock {
    club_id: BeId,
    challenge: Vec<u8>,
    verifying_key: [u8; 32],
}

impl ChallengeLock {
    pub fn new(club_id: BeId, challenge: Vec<u8>, verifying_key: [u8; 32]) -> Self {
        ChallengeLock {
            club_id,
            challenge,
            verifying_key,
        }
    }

    pub fn challenge(&self) -> &[u8] {
        &self.challenge
    }
}

impl Lock for ChallengeLock {
    fn try_open(&self, credential: &LockCredential) -> Result<KeyMaster, ServerError> {
        match credential {
            LockCredential::ChallengeResponse(signature_bytes) => {
                let verifying_key = ed25519_dalek::VerifyingKey::from_bytes(&self.verifying_key)
                    .map_err(|_| ServerError::LockFailed("invalid verifying key".into()))?;
                let signature: ed25519_dalek::Signature =
                    signature_bytes.as_slice().try_into().map_err(|_| {
                        ServerError::LockFailed(
                            "invalid signature length (expected 64 bytes)".into(),
                        )
                    })?;
                let mut message = Vec::with_capacity(8 + self.challenge.len());
                message.extend_from_slice(b"xudanu/v1/");
                message.extend_from_slice(&self.challenge);
                crate::crypto::sign::verify_signature(&verifying_key, &message, &signature)
                    .map(|_| KeyMaster::make(self.club_id))
                    .map_err(|_| {
                        ServerError::LockFailed("challenge signature verification failed".into())
                    })
            }
            _ => Err(ServerError::LockFailed(
                "challenge lock requires ChallengeResponse credential".into(),
            )),
        }
    }

    fn club_id(&self) -> Option<BeId> {
        Some(self.club_id)
    }

    fn clone_boxed(&self) -> Box<dyn Lock> {
        Box::new(self.clone())
    }

    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
}

#[derive(Debug, Clone)]
pub struct MatchLock {
    club_id: BeId,
    phc_hash: String,
}

impl MatchLock {
    pub fn new(club_id: BeId, phc_hash: String) -> Self {
        MatchLock { club_id, phc_hash }
    }
}

impl Lock for MatchLock {
    fn try_open(&self, credential: &LockCredential) -> Result<KeyMaster, ServerError> {
        match credential {
            LockCredential::Password(password) => {
                crate::crypto::password::verify_password(&self.phc_hash, password)
                    .map(|_| KeyMaster::make(self.club_id))
                    .map_err(|_| ServerError::LockFailed("password mismatch".into()))
            }
            _ => Err(ServerError::LockFailed(
                "match lock requires Password credential".into(),
            )),
        }
    }

    fn club_id(&self) -> Option<BeId> {
        Some(self.club_id)
    }

    fn clone_boxed(&self) -> Box<dyn Lock> {
        Box::new(self.clone())
    }

    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
}

#[derive(Debug, Clone)]
pub struct MultiLock {
    club_id: Option<BeId>,
    sub_locks: HashMap<String, Box<dyn Lock>>,
}

impl MultiLock {
    pub fn new(club_id: Option<BeId>) -> Self {
        MultiLock {
            club_id,
            sub_locks: HashMap::new(),
        }
    }

    pub fn with_sub_lock(mut self, name: String, lock: Box<dyn Lock>) -> Self {
        self.sub_locks.insert(name, lock);
        self
    }

    pub fn lock_names(&self) -> Vec<&str> {
        self.sub_locks.keys().map(|s| s.as_str()).collect()
    }

    pub fn get_sub_lock(&self, name: &str) -> Option<&dyn Lock> {
        self.sub_locks.get(name).map(|b| b.as_ref())
    }
}

impl Lock for MultiLock {
    fn try_open(&self, credential: &LockCredential) -> Result<KeyMaster, ServerError> {
        match credential {
            LockCredential::Named { name, credential } => {
                let sub_lock = self.sub_locks.get(name).ok_or_else(|| {
                    ServerError::LockFailed(format!("no sub-lock named '{}'", name))
                })?;
                sub_lock.try_open(credential)
            }
            _ => Err(ServerError::LockFailed(
                "multi lock requires Named credential".into(),
            )),
        }
    }

    fn club_id(&self) -> Option<BeId> {
        self.club_id
    }

    fn clone_boxed(&self) -> Box<dyn Lock> {
        let mut cloned_sub = HashMap::new();
        for (name, lock) in &self.sub_locks {
            cloned_sub.insert(name.clone(), lock.clone_boxed());
        }
        Box::new(MultiLock {
            club_id: self.club_id,
            sub_locks: cloned_sub,
        })
    }

    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
}

pub trait LockSmith: Send + Sync + std::fmt::Debug {
    fn create_lock(&self, club_id: Option<BeId>) -> Box<dyn Lock>;
    fn clone_boxed(&self) -> Box<dyn LockSmith>;
}

#[derive(Debug, Clone)]
pub struct BooLockSmith;

impl BooLockSmith {
    pub fn new() -> Self {
        BooLockSmith
    }
}

impl LockSmith for BooLockSmith {
    fn create_lock(&self, club_id: Option<BeId>) -> Box<dyn Lock> {
        match club_id {
            Some(id) => Box::new(BooLock::new(id)),
            None => Box::new(WallLock::new()),
        }
    }

    fn clone_boxed(&self) -> Box<dyn LockSmith> {
        Box::new(self.clone())
    }
}

#[derive(Debug, Clone)]
pub struct WallLockSmith;

impl WallLockSmith {
    pub fn new() -> Self {
        WallLockSmith
    }
}

impl LockSmith for WallLockSmith {
    fn create_lock(&self, _club_id: Option<BeId>) -> Box<dyn Lock> {
        Box::new(WallLock::new())
    }

    fn clone_boxed(&self) -> Box<dyn LockSmith> {
        Box::new(self.clone())
    }
}

#[derive(Debug, Clone)]
pub struct ChallengeLockSmith {
    pub verifying_key: [u8; 32],
}

impl ChallengeLockSmith {
    pub fn new(verifying_key: [u8; 32]) -> Self {
        ChallengeLockSmith { verifying_key }
    }
}

impl LockSmith for ChallengeLockSmith {
    fn create_lock(&self, club_id: Option<BeId>) -> Box<dyn Lock> {
        let id = club_id.unwrap_or(0);
        let mut challenge = vec![0u8; 32];
        rand::RngCore::fill_bytes(&mut rand::rngs::OsRng, &mut challenge);
        Box::new(ChallengeLock::new(id, challenge, self.verifying_key))
    }

    fn clone_boxed(&self) -> Box<dyn LockSmith> {
        Box::new(self.clone())
    }
}

#[derive(Debug, Clone)]
pub struct MatchLockSmith {
    pub phc_hash: String,
    pub scrambler_name: String,
}

impl MatchLockSmith {
    pub fn from_password(password: &[u8]) -> Result<Self, ServerError> {
        let phc_hash = crate::crypto::password::hash_password(password)
            .map_err(|e| ServerError::Internal(format!("password hash failed: {}", e)))?;
        Ok(MatchLockSmith {
            phc_hash,
            scrambler_name: "argon2id".to_string(),
        })
    }

    pub fn from_phc_hash(phc_hash: String) -> Self {
        MatchLockSmith {
            phc_hash,
            scrambler_name: "argon2id".to_string(),
        }
    }
}

impl LockSmith for MatchLockSmith {
    fn create_lock(&self, club_id: Option<BeId>) -> Box<dyn Lock> {
        let id = club_id.unwrap_or(0);
        Box::new(MatchLock::new(id, self.phc_hash.clone()))
    }

    fn clone_boxed(&self) -> Box<dyn LockSmith> {
        Box::new(self.clone())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn boo_lock_opens() {
        let lock = BooLock::new(42);
        let km = lock.try_open(&LockCredential::Boo).unwrap();
        assert!(km.has_authority(42));
    }

    #[test]
    fn boo_lock_rejects_wrong_credential() {
        let lock = BooLock::new(42);
        let result = lock.try_open(&LockCredential::Password(vec![]));
        assert!(result.is_err());
    }

    #[test]
    fn wall_lock_never_opens() {
        let lock = WallLock::new();
        assert!(lock.try_open(&LockCredential::Boo).is_err());
        assert!(lock
            .try_open(&LockCredential::Password(vec![1, 2, 3]))
            .is_err());
    }

    #[test]
    fn challenge_lock_opens_with_correct_signature() {
        let signing_key = crate::crypto::sign::generate_signing_key();
        let verifying_key = signing_key.verifying_key().to_bytes();
        let challenge = vec![1, 2, 3, 4, 5, 6, 7, 8];
        let lock = ChallengeLock::new(10, challenge.clone(), verifying_key);
        let mut message = Vec::with_capacity(8 + challenge.len());
        message.extend_from_slice(b"xudanu/v1/");
        message.extend_from_slice(&challenge);
        let sig = crate::crypto::sign::sign_bytes(&signing_key, &message);
        let km = lock
            .try_open(&LockCredential::ChallengeResponse(sig.to_bytes().to_vec()))
            .unwrap();
        assert!(km.has_authority(10));
    }

    #[test]
    fn challenge_lock_rejects_wrong_signature() {
        let signing_key = crate::crypto::sign::generate_signing_key();
        let wrong_key = crate::crypto::sign::generate_signing_key();
        let verifying_key = signing_key.verifying_key().to_bytes();
        let challenge = vec![1, 2, 3, 4, 5, 6, 7, 8];
        let lock = ChallengeLock::new(10, challenge.clone(), verifying_key);
        let mut message = Vec::with_capacity(8 + challenge.len());
        message.extend_from_slice(b"xudanu/v1/");
        message.extend_from_slice(&challenge);
        let sig = crate::crypto::sign::sign_bytes(&wrong_key, &message);
        let result = lock.try_open(&LockCredential::ChallengeResponse(sig.to_bytes().to_vec()));
        assert!(result.is_err());
    }

    #[test]
    fn match_lock_opens_with_correct_password() {
        let smith = MatchLockSmith::from_password(b"secret").unwrap();
        let lock = smith.create_lock(Some(5));
        let km = lock
            .try_open(&LockCredential::Password(b"secret".to_vec()))
            .unwrap();
        assert!(km.has_authority(5));
    }

    #[test]
    fn match_lock_rejects_wrong_password() {
        let smith = MatchLockSmith::from_password(b"secret").unwrap();
        let lock = smith.create_lock(Some(5));
        let result = lock.try_open(&LockCredential::Password(b"wrong".to_vec()));
        assert!(result.is_err());
    }

    #[test]
    fn multi_lock_delegates_to_sub() {
        let ml = MultiLock::new(Some(1))
            .with_sub_lock("boo".to_string(), Box::new(BooLock::new(42)))
            .with_sub_lock(
                "match".to_string(),
                MatchLockSmith::from_password(b"pw")
                    .unwrap()
                    .create_lock(Some(99)),
            );
        let km = ml
            .try_open(&LockCredential::Named {
                name: "boo".to_string(),
                credential: Box::new(LockCredential::Boo),
            })
            .unwrap();
        assert!(km.has_authority(42));
        let km2 = ml
            .try_open(&LockCredential::Named {
                name: "match".to_string(),
                credential: Box::new(LockCredential::Password(b"pw".to_vec())),
            })
            .unwrap();
        assert!(km2.has_authority(99));
    }

    #[test]
    fn multi_lock_rejects_unknown_name() {
        let ml = MultiLock::new(None);
        let result = ml.try_open(&LockCredential::Named {
            name: "nonexistent".to_string(),
            credential: Box::new(LockCredential::Boo),
        });
        assert!(result.is_err());
    }

    #[test]
    fn multi_lock_lists_names() {
        let ml = MultiLock::new(None)
            .with_sub_lock("a".to_string(), Box::new(BooLock::new(1)))
            .with_sub_lock("b".to_string(), Box::new(WallLock::new()));
        let mut names = ml.lock_names();
        names.sort();
        assert_eq!(names, vec!["a", "b"]);
    }

    #[test]
    fn boo_lock_smith_creates_boo_or_wall() {
        let smith = BooLockSmith::new();
        let boo = smith.create_lock(Some(10));
        assert!(boo.try_open(&LockCredential::Boo).is_ok());
        let wall = smith.create_lock(None);
        assert!(wall.try_open(&LockCredential::Boo).is_err());
    }

    #[test]
    fn lock_cloned_boxed() {
        let lock: Box<dyn Lock> = Box::new(BooLock::new(42));
        let cloned = lock.clone_boxed();
        let km = cloned.try_open(&LockCredential::Boo).unwrap();
        assert!(km.has_authority(42));
    }
}
