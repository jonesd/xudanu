// Build script: writer fingerprint for persistence safety.
//
// Every manifest records who wrote it (git hash + dirty flag + build
// profile). restore refuses to open data written by a different
// build unless XUDANU_ALLOW_FOREIGN_WRITER=1 — the guard against
// WIP-binary/main-binary skew silently dropping state at the next
// checkpoint. Release builds get a clean hash; a dirty working tree
// gets a "-dirty" suffix and is only ever opened by itself.

use std::process::Command;

fn main() {
    println!("cargo:rerun-if-changed=../../.git/HEAD");
    println!("cargo:rerun-if-changed=../../.git/index");

    let hash = Command::new("git")
        .args(["rev-parse", "--short", "HEAD"])
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|| "no-vcs".to_string());

    let dirty = Command::new("git")
        .args(["status", "--porcelain"])
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| !o.stdout.is_empty())
        .unwrap_or(false);

    let profile = if cfg!(debug_assertions) {
        "debug"
    } else {
        "release"
    };
    let tag = format!("{}-{}{}", hash, profile, if dirty { "-dirty" } else { "" });

    println!("cargo:rustc-env=XUDANU_WRITER_TAG={}", tag);
}
