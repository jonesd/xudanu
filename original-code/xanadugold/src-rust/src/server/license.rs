//! License posture registry (FR-156).
//!
//! Single source of truth for what THIS installation has opted into
//! — and what it declined. Three renderings read from this one
//! table: the admin endpoint (`admin_license_posture`), the startup
//! log line, and docs/dev/FR-156.
//!
//! MIRROR, NOT SWITCH: everything here is descriptive. Changing an
//! opt-in happens in Cargo features / operator config — the
//! deliberate act — never through this module or the admin surface
//! that renders it. A declined opt-in is listed on purpose: absence
//! of surprise is information too.

use serde::Serialize;

/// Where an opt-in is decided.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum OptInSource {
    /// Compile-time Cargo feature. The operator's build chose it;
    /// removing it takes a rebuild.
    BuildFeature,
    /// Runtime configuration, gated on an explicit license
    /// acknowledgment (reserved — translation engines, FR-155).
    RuntimeConfig,
}

/// Whether an opt-in is carried by THIS installation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum OptInState {
    /// Chosen: compiled into this binary.
    Enabled,
    /// Available but not chosen. Listed deliberately.
    Available,
}

#[derive(Debug, Serialize)]
pub struct LicenseEntry {
    /// Stable identifier. Never rename: admins and docs cite it.
    pub id: &'static str,
    /// Human name of the capability.
    pub name: &'static str,
    /// License of the carrying dependency (SPDX), with bindings
    /// noted where the Rust crate and the linked library differ.
    pub license: &'static str,
    /// Plain-language blast radius: what the opt-in does and which
    /// terms attach to the operator's binary.
    pub blast_radius: &'static str,
    /// Where the operator can read the terms.
    pub terms_url: &'static str,
    /// How the opt-in is decided.
    pub source: OptInSource,
    /// The Cargo feature name (build features only).
    pub feature: Option<&'static str>,
    /// Whether THIS binary carries it.
    pub state: OptInState,
}

/// The registry. `state` is computed by `cfg!` at compile time, so
/// each build reports its own posture.
///
/// NOTE for future entries: a new row lands here only when the
/// opt-in is real in the product (translation engines join when
/// FR-155 Stage 2 ships — not before).
static REGISTRY: [LicenseEntry; 1] = [LicenseEntry {
    id: "heif",
    name: "HEIF/HEIC image decode",
    license: "LGPL-3.0-or-later (libheif C library; the libheif-rs Rust bindings are MIT)",
    blast_radius: "Decodes .heif/.heic camera photos for image previews. \
Opting in links the LGPL-3.0-or-later libheif C library into this \
binary; the operator's distribution then carries LGPL terms for that \
code. Core xudanu stays Apache-2.0 / GPL-free either way.",
    terms_url: "https://www.gnu.org/licenses/lgpl-3.0.html",
    source: OptInSource::BuildFeature,
    feature: Some("heif"),
    // The `heif` feature turns on the optional libheif-rs dep, which
    // exposes the implicit "libheif-rs" feature blob_store gates on.
    // Mirror blob_store's dual cfg so the registry and the decoder
    // can never disagree.
    state: if cfg!(any(feature = "libheif-rs", feature = "heif-rs")) {
        OptInState::Enabled
    } else {
        OptInState::Available
    },
}];

/// The full posture: every known opt-in, both states, this build.
pub fn posture() -> &'static [LicenseEntry] {
    &REGISTRY
}

/// Admin-endpoint rendering: {"entries": [...]}.
pub fn posture_json() -> serde_json::Value {
    let entries: Vec<serde_json::Value> = REGISTRY
        .iter()
        .map(|e| serde_json::to_value(e).expect("LicenseEntry is plain data"))
        .collect();
    serde_json::json!({ "entries": entries })
}

/// Startup-log rendering: one line naming every opt-in and its
/// state in this build.
pub fn startup_line() -> String {
    let parts: Vec<String> = REGISTRY
        .iter()
        .map(|e| match e.state {
            OptInState::Enabled => format!("{}=enabled({})", e.id, e.license),
            OptInState::Available => format!("{}=available-not-chosen", e.id),
        })
        .collect();
    if parts.is_empty() {
        "no license opt-ins known to this build".to_string()
    } else {
        parts.join(", ")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn declined_opt_ins_are_listed_too() {
        // The panel's whole point: an admin confirming "we're clean"
        // must see the absences, not just the activations. On a
        // default build (no heif feature) the heif row IS that
        // absence, listed as Available.
        let heif = posture()
            .iter()
            .find(|e| e.id == "heif")
            .expect("heif entry");
        let heif_compiled = cfg!(any(feature = "libheif-rs", feature = "heif-rs"));
        assert_eq!(
            heif.state == OptInState::Enabled,
            heif_compiled,
            "registry state must match what blob_store actually gates on"
        );
        if !heif_compiled {
            assert_eq!(heif.state, OptInState::Available);
        }
    }

    #[test]
    fn ids_are_unique_and_fields_nonempty() {
        let mut ids: Vec<&str> = posture().iter().map(|e| e.id).collect();
        let n = ids.len();
        ids.sort_unstable();
        ids.dedup();
        assert_eq!(ids.len(), n, "duplicate registry ids");
        for e in posture() {
            assert!(!e.name.is_empty(), "{} name", e.id);
            assert!(!e.license.is_empty(), "{} license", e.id);
            assert!(!e.blast_radius.is_empty(), "{} blast_radius", e.id);
            assert!(
                e.terms_url.starts_with("https://"),
                "{} terms_url must be https",
                e.id
            );
        }
    }

    #[test]
    fn json_rendering_names_every_entry_and_state() {
        let v = posture_json();
        let entries = v
            .get("entries")
            .and_then(|e| e.as_array())
            .expect("entries array");
        assert_eq!(entries.len(), posture().len());
        for (val, e) in entries.iter().zip(posture()) {
            assert_eq!(val["id"], serde_json::json!(e.id));
            assert!(val["name"].is_string());
            assert!(val["license"].is_string());
            assert!(val["blast_radius"].is_string());
            assert!(val["terms_url"].is_string());
            let state = val["state"].as_str().expect("state string");
            assert!(
                state == "enabled" || state == "available",
                "state must be snake_case enum value"
            );
            let source = val["source"].as_str().expect("source string");
            assert!(
                source == "build_feature" || source == "runtime_config",
                "source must be snake_case enum value"
            );
        }
    }

    #[test]
    fn startup_line_names_every_entry() {
        let line = startup_line();
        for e in posture() {
            assert!(line.contains(e.id), "startup line omits {}", e.id);
        }
    }
}
