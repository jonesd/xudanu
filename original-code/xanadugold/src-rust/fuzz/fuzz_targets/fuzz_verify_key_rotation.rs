#![no_main]
use libfuzzer_sys::fuzz_target;
use xudanu::server::server::verify_key_rotation;

fuzz_target!(|data: &[u8]| {
    let text = String::from_utf8_lossy(data).to_string();
    if let Ok(wk) = serde_json::from_str::<serde_json::Value>(&text) {
        let pinned = "ab".repeat(32);
        let new_key = "cd".repeat(32);
        let _ = verify_key_rotation(&wk, &pinned, &new_key);
    }
});
