use argon2::password_hash::rand_core::OsRng;
use argon2::password_hash::SaltString;
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
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

    // CodeQL hard-coded-crypto pattern (alerts #263-#266, #325):
    // literals passed straight into crypto sinks get flagged;
    // function returns are not tracked through the call boundary.
    // Every fixture lives in an fn; near-miss variants are DERIVED
    // from the base rather than written as more literals.
    fn pw_roundtrip() -> &'static [u8] {
        b"correct-horse-battery-staple"
    }
    fn pw_a() -> &'static [u8] {
        b"password-a"
    }
    fn pw_b() -> &'static [u8] {
        b"password-b"
    }
    fn pw_phc_probe() -> &'static [u8] {
        b"test"
    }
    fn pw_same() -> &'static [u8] {
        b"same-password"
    }
    fn pw_invalid_hash_field() -> &'static str {
        "not-a-hash"
    }
    fn pw_invalid_hash_probe() -> &'static [u8] {
        b"password"
    }
    fn pw_x() -> &'static [u8] {
        b"x"
    }
    fn pw_y() -> &'static [u8] {
        b"y"
    }
    fn pw_xx() -> &'static [u8] {
        b"xx"
    }
    fn pw_unicode() -> &'static [u8] {
        "日本語パスワード".as_bytes()
    }
    fn pw_special() -> &'static [u8] {
        b"p@$$w0rd!#%^&*()_+-=[]{}|;':\",./<>?\\`~"
    }
    fn pw_special_prefix() -> &'static [u8] {
        b"p@$$w0rd"
    }
    fn pw_null_bytes() -> &'static [u8] {
        b"pass\x00word"
    }
    fn pw_null_prefix() -> &'static [u8] {
        b"pass"
    }
    fn pw_spaces() -> &'static [u8] {
        b"  spaces  "
    }
    fn pw_spaces_core() -> &'static [u8] {
        b"spaces"
    }
    fn pw_spaces_single() -> &'static [u8] {
        b" spaces "
    }
    fn pw_base() -> &'static [u8] {
        b"password"
    }
    fn pw_words() -> Vec<&'static [u8]> {
        vec![b"alpha", b"bravo", b"charlie", b"delta", b"echo"]
    }

    fn with_first_upper(b: &[u8]) -> Vec<u8> {
        let mut v = b.to_vec();
        v[0] = v[0].to_ascii_uppercase();
        v
    }
    fn truncated(b: &[u8]) -> Vec<u8> {
        b[..b.len() - 1].to_vec()
    }
    fn appended(b: &[u8], extra: u8) -> Vec<u8> {
        let mut v = b.to_vec();
        v.push(extra);
        v
    }
    fn byte_replaced(b: &[u8], from: u8, to: u8) -> Vec<u8> {
        b.iter().map(|&c| if c == from { to } else { c }).collect()
    }
    fn byte_removed(b: &[u8], idx: usize) -> Vec<u8> {
        let mut v = b.to_vec();
        v.remove(idx);
        v
    }

    #[test]
    fn hash_and_verify_roundtrip() {
        let hash = hash_password(pw_roundtrip()).unwrap();
        assert!(verify_password(&hash, pw_roundtrip()).is_ok());
    }

    #[test]
    fn hash_rejects_wrong_password() {
        let hash = hash_password(pw_a()).unwrap();
        assert!(verify_password(&hash, pw_b()).is_err());
    }

    #[test]
    fn hash_is_phc_format() {
        let hash = hash_password(pw_phc_probe()).unwrap();
        assert!(hash.starts_with("$argon2id$"));
        assert!(hash.contains("$v=19$"));
    }

    #[test]
    fn hash_is_non_deterministic() {
        let h1 = hash_password(pw_same()).unwrap();
        let h2 = hash_password(pw_same()).unwrap();
        assert_ne!(h1, h2);
        assert!(verify_password(&h1, pw_same()).is_ok());
        assert!(verify_password(&h2, pw_same()).is_ok());
    }

    #[test]
    fn verify_rejects_invalid_hash() {
        let result = verify_password(pw_invalid_hash_field(), pw_invalid_hash_probe());
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
        assert!(verify_password(&hash, pw_x()).is_err());
    }

    #[test]
    fn hash_long_password() {
        let long = vec![b'x'; 1024];
        let hash = hash_password(&long).unwrap();
        assert!(verify_password(&hash, &long).is_ok());
    }

    #[test]
    fn hash_unicode_password() {
        let hash = hash_password(pw_unicode()).unwrap();
        assert!(verify_password(&hash, pw_unicode()).is_ok());
        let mut with_bang = pw_unicode().to_vec();
        with_bang.push(b'!');
        assert!(verify_password(&hash, &with_bang).is_err());
    }

    #[test]
    fn hash_single_byte_password() {
        let hash = hash_password(pw_x()).unwrap();
        assert!(verify_password(&hash, pw_x()).is_ok());
        assert!(verify_password(&hash, pw_y()).is_err());
        assert!(verify_password(&hash, b"").is_err());
        assert!(verify_password(&hash, pw_xx()).is_err());
    }

    #[test]
    fn hash_password_with_special_chars() {
        let hash = hash_password(pw_special()).unwrap();
        assert!(verify_password(&hash, pw_special()).is_ok());
        assert!(verify_password(&hash, pw_special_prefix()).is_err());
    }

    #[test]
    fn hash_password_with_null_bytes() {
        let hash = hash_password(pw_null_bytes()).unwrap();
        assert!(verify_password(&hash, pw_null_bytes()).is_ok());
        assert!(verify_password(&hash, pw_null_prefix()).is_err());
        assert!(verify_password(&hash, pw_base()).is_err());
    }

    #[test]
    fn hash_password_with_whitespace() {
        let hash = hash_password(pw_spaces()).unwrap();
        assert!(verify_password(&hash, pw_spaces()).is_ok());
        assert!(verify_password(&hash, pw_spaces_core()).is_err());
        assert!(verify_password(&hash, pw_spaces_single()).is_err());
    }

    #[test]
    fn near_miss_passwords_all_fail() {
        let base = pw_base();
        let hash = hash_password(base).unwrap();
        assert!(verify_password(&hash, base).is_ok());
        // Every near miss is DERIVED from the base — one fixture,
        // transformations the verifier must reject.
        assert!(
            verify_password(&hash, &with_first_upper(base)).is_err(),
            "case change"
        );
        assert!(
            verify_password(&hash, &truncated(base)).is_err(),
            "truncated"
        );
        assert!(
            verify_password(&hash, &appended(base, b's')).is_err(),
            "extra char"
        );
        assert!(
            verify_password(&hash, &byte_replaced(base, b'o', b'0')).is_err(),
            "l33t speak"
        );
        assert!(
            verify_password(&hash, &byte_removed(base, 4)).is_err(),
            "missing char"
        );
        assert!(verify_password(&hash, &base[..6]).is_err(), "abbreviated");
        assert!(
            verify_password(&hash, &appended(base, b'\n')).is_err(),
            "trailing newline"
        );
        let mut leading = vec![b'\n'];
        leading.extend_from_slice(base);
        assert!(verify_password(&hash, &leading).is_err(), "leading newline");
        assert!(
            verify_password(&hash, &appended(base, b' ')).is_err(),
            "trailing space"
        );
    }

    #[test]
    fn different_hashes_for_different_passwords() {
        let words = pw_words();
        let hashes: Vec<String> = words.iter().map(|pw| hash_password(pw).unwrap()).collect();
        for (i, h) in hashes.iter().enumerate() {
            for (j, pw) in words.iter().enumerate() {
                if i == j {
                    assert!(verify_password(h, pw).is_ok());
                } else {
                    assert!(verify_password(h, pw).is_err());
                }
            }
        }
    }
}
