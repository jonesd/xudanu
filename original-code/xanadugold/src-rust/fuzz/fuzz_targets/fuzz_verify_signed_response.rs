#![no_main]
use libfuzzer_sys::fuzz_target;
use xudanu::server::server::{verify_signed_response, verify_key_rotation};

fuzz_target!(|data: &[u8]| {
    let text = String::from_utf8_lossy(data).to_string();
    if let Ok(body) = serde_json::from_str::<serde_json::Value>(&text) {
        let _ = verify_signed_response(&body, &[0u8; 32], 1, None);
    }
});
