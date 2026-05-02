use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use argon2::password_hash::SaltString;
use argon2::password_hash::rand_core::OsRng;
use subtle::ConstantTimeEq;

const ARGON2ID_M_COST: u32 = 19456;
const ARGON2ID_T_COST: u32 = 2;
const ARGON2ID_PARALLELISM: u32 = 1;

#[derive(Debug)]
pub enum PasswordHashError {
    HashFailed,
    InvalidHashFormat,
    VerificationFailed,
}

impl std::fmt::Display for PasswordHashError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            PasswordHashError::HashFailed => write!(f, "password hashing failed"),
            PasswordHashError::InvalidHashFormat => write!(f, "invalid PHC hash format"),
            PasswordHashError::VerificationFailed => write!(f, "password verification failed"),
        }
    }
}

impl std::error::Error for PasswordHashError {}

pub fn hash_password(password: &[u8]) -> Result<String, PasswordHashError> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::new(
        argon2::Algorithm::Argon2id,
        argon2::Version::V0x13,
        argon2::Params::new(ARGON2ID_M_COST, ARGON2ID_T_COST, ARGON2ID_PARALLELISM, None)
            .map_err(|_| PasswordHashError::HashFailed)?,
    );
    let hash = argon2
        .hash_password(password, &salt)
        .map_err(|_| PasswordHashError::HashFailed)?;
    Ok(hash.to_string())
}

pub fn verify_password(phc_hash: &str, password: &[u8]) -> Result<(), PasswordHashError> {
    let parsed = PasswordHash::new(phc_hash).map_err(|_| PasswordHashError::InvalidHashFormat)?;
    let argon2 = Argon2::new(
        argon2::Algorithm::Argon2id,
        argon2::Version::V0x13,
        argon2::Params::new(ARGON2ID_M_COST, ARGON2ID_T_COST, ARGON2ID_PARALLELISM, None)
            .map_err(|_| PasswordHashError::VerificationFailed)?,
    );
    argon2
        .verify_password(password, &parsed)
        .map_err(|_| PasswordHashError::VerificationFailed)
}

pub fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    a.ct_eq(b).into()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hash_and_verify_roundtrip() {
        let hash = hash_password(b"correct-horse-battery-staple").unwrap();
        assert!(verify_password(&hash, b"correct-horse-battery-staple").is_ok());
    }

    #[test]
    fn hash_rejects_wrong_password() {
        let hash = hash_password(b"password-a").unwrap();
        assert!(verify_password(&hash, b"password-b").is_err());
    }

    #[test]
    fn hash_is_phc_format() {
        let hash = hash_password(b"test").unwrap();
        assert!(hash.starts_with("$argon2id$"));
        assert!(hash.contains("$v=19$"));
    }

    #[test]
    fn hash_is_non_deterministic() {
        let h1 = hash_password(b"same-password").unwrap();
        let h2 = hash_password(b"same-password").unwrap();
        assert_ne!(h1, h2);
        assert!(verify_password(&h1, b"same-password").is_ok());
        assert!(verify_password(&h2, b"same-password").is_ok());
    }

    #[test]
    fn verify_rejects_invalid_hash() {
        let result = verify_password("not-a-hash", b"password");
        assert!(result.is_err());
    }

    #[test]
    fn constant_time_eq_same() {
        assert!(constant_time_eq(b"abc", b"abc"));
    }

    #[test]
    fn constant_time_eq_different() {
        assert!(!constant_time_eq(b"abc", b"abd"));
    }

    #[test]
    fn constant_time_eq_different_lengths() {
        assert!(!constant_time_eq(b"abc", b"abcd"));
    }

    #[test]
    fn hash_empty_password() {
        let hash = hash_password(b"").unwrap();
        assert!(verify_password(&hash, b"").is_ok());
        assert!(verify_password(&hash, b"x").is_err());
    }

    #[test]
    fn hash_long_password() {
        let long = vec![b'x'; 1024];
        let hash = hash_password(&long).unwrap();
        assert!(verify_password(&hash, &long).is_ok());
    }

    #[test]
    fn hash_unicode_password() {
        let hash = hash_password("日本語パスワード".as_bytes()).unwrap();
        assert!(verify_password(&hash, "日本語パスワード".as_bytes()).is_ok());
        assert!(verify_password(&hash, "日本語パスワード!".as_bytes()).is_err());
    }
}
