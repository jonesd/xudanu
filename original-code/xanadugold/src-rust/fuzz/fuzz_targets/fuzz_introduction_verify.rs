#![no_main]
use libfuzzer_sys::fuzz_target;
use xudanu::server::server::SignedIntroduction;

fuzz_target!(|data: &[u8]| {
    let text = String::from_utf8_lossy(data).to_string();
    if let Ok(intro) = serde_json::from_str::<SignedIntroduction>(&text) {
        let _ = intro.verify(&intro.introduced_by_key);
    }
});
