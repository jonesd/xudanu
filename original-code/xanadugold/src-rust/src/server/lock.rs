use std::collections::HashMap;

use crate::edition::BeId;

use super::error::ServerError;
use super::keymaster::KeyMaster;

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
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
}

#[derive(Debug, Clone)]
pub struct ChallengeLock {
    club_id: BeId,
    challenge: Vec<u8>,
    expected_response: Vec<u8>,
}

impl ChallengeLock {
    pub fn new(club_id: BeId, challenge: Vec<u8>, expected_response: Vec<u8>) -> Self {
        ChallengeLock {
            club_id,
            challenge,
            expected_response,
        }
    }

    pub fn challenge(&self) -> &[u8] {
        &self.challenge
    }
}

impl Lock for ChallengeLock {
    fn try_open(&self, credential: &LockCredential) -> Result<KeyMaster, ServerError> {
        match credential {
            LockCredential::ChallengeResponse(response) => {
                if response == &self.expected_response {
                    Ok(KeyMaster::make(self.club_id))
                } else {
                    Err(ServerError::LockFailed("challenge response mismatch".into()))
                }
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
                let sub_lock = self
                    .sub_locks
                    .get(name)
                    .ok_or_else(|| ServerError::LockFailed(format!("no sub-lock named '{}'", name)))?;
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
    pub public_key: Vec<u8>,
    pub encrypter_name: String,
}

impl ChallengeLockSmith {
    pub fn new(public_key: Vec<u8>, encrypter_name: String) -> Self {
        ChallengeLockSmith {
            public_key,
            encrypter_name,
        }
    }

    pub fn create_challenge(&self, challenge_data: &[u8]) -> Result<Vec<u8>, ServerError> {
        if self.public_key.len() != 32 {
            return Err(ServerError::Internal("invalid public key length for challenge".into()));
        }
        let peer_pub_bytes: [u8; 32] = self.public_key.clone().try_into()
            .map_err(|_| ServerError::Internal("public key must be 32 bytes".into()))?;
        let peer_pub = x25519_dalek::PublicKey::from(peer_pub_bytes);
        let eph_secret = x25519_dalek::EphemeralSecret::random_from_rng(rand::rngs::OsRng);
        let eph_public = x25519_dalek::PublicKey::from(&eph_secret);
        let shared = eph_secret.diffie_hellman(&peer_pub);
        let key = crate::crypto::kdf::derive_key(shared.as_bytes(), None, crate::crypto::kdf::DomainLabel::CHALLENGE_KEY, b"challenge-aead");
        let sealed = crate::crypto::aead::seal_standalone(&key, challenge_data, b"xudanu-challenge", 0)
            .map_err(|e| ServerError::Internal(format!("challenge encryption failed: {}", e)))?;
        let mut result = Vec::with_capacity(32 + sealed.ciphertext.len());
        result.extend_from_slice(eph_public.as_bytes());
        result.extend(sealed.ciphertext);
        Ok(result)
    }
}

impl LockSmith for ChallengeLockSmith {
    fn create_lock(&self, club_id: Option<BeId>) -> Box<dyn Lock> {
        let id = club_id.unwrap_or(0);
        let challenge = self.public_key.clone();
        let expected = vec![0u8; 32];
        Box::new(ChallengeLock::new(id, challenge, expected))
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
    fn challenge_lock_opens_with_correct_response() {
        let lock = ChallengeLock::new(10, vec![1, 2, 3], vec![4, 5, 6]);
        let km = lock
            .try_open(&LockCredential::ChallengeResponse(vec![4, 5, 6]))
            .unwrap();
        assert!(km.has_authority(10));
    }

    #[test]
    fn challenge_lock_rejects_wrong_response() {
        let lock = ChallengeLock::new(10, vec![1, 2, 3], vec![4, 5, 6]);
        let result = lock.try_open(&LockCredential::ChallengeResponse(vec![7, 8, 9]));
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
                MatchLockSmith::from_password(b"pw").unwrap().create_lock(Some(99)),
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
