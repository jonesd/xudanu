use serde_json::Value;

#[derive(Debug)]
pub enum MigrationError {
    NoStep(u32),
    Transform(String),
    Io(std::io::Error),
}

impl std::fmt::Display for MigrationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            MigrationError::NoStep(v) => {
                write!(f, "no migration step from version {}", v)
            }
            MigrationError::Transform(msg) => write!(f, "migration transform failed: {}", msg),
            MigrationError::Io(e) => write!(f, "migration io error: {}", e),
        }
    }
}

impl std::error::Error for MigrationError {}

impl From<std::io::Error> for MigrationError {
    fn from(e: std::io::Error) -> Self {
        MigrationError::Io(e)
    }
}

/// One format bump: a transform applied to the whole data directory.
/// Steps are plain data — author a custom one by registering it in
/// `MIGRATION_STEPS` (production chain) or passing your own slice to
/// `apply_steps_with` (embedders, tests).
#[derive(Debug, Clone, Copy)]
pub struct MigrationStep {
    pub from_format: u32,
    pub to_format: u32,
    pub description: &'static str,
    pub transform: fn(&std::path::Path) -> Result<(), MigrationError>,
}

/// The registered production chain. v1 is the baseline: the first
/// entry will be v1→v2 when format v2 exists. Entries must chain
/// contiguously; the walker fails closed on any gap.
pub static MIGRATION_STEPS: &[MigrationStep] = &[];

/// Apply every registered step needed to bring `dir` from
/// `from_version` to the current binary's format (FR-82).
pub fn apply_migration_steps(
    data_dir: &std::path::Path,
    from_version: u32,
) -> Result<usize, MigrationError> {
    apply_steps_with(
        data_dir,
        from_version,
        crate::persist::root_chunk::ROOT_CHUNK_FORMAT_VERSION,
        MIGRATION_STEPS,
    )
}

/// Walk an arbitrary step chain from `from_version` to
/// `target_version`, applying each transform in order. Fails closed:
/// a gap in the chain (`NoStep`), a from-version ahead of the target,
/// or a failing transform stops the walk with an error — the caller
/// (upgrade command) rolls back from its backup.
pub fn apply_steps_with(
    data_dir: &std::path::Path,
    from_version: u32,
    target_version: u32,
    steps: &[MigrationStep],
) -> Result<usize, MigrationError> {
    if from_version > target_version {
        // The caller guards this (data newer than binary); defense
        // in depth for library embedders.
        return Err(MigrationError::NoStep(from_version));
    }
    let mut version = from_version;
    let mut applied = 0;
    while version < target_version {
        let step = steps
            .iter()
            .find(|s| s.from_format == version)
            .ok_or(MigrationError::NoStep(version))?;
        tracing::info!(
            "[migrate] applying v{}→v{}: {}",
            step.from_format,
            step.to_format,
            step.description
        );
        (step.transform)(data_dir)?;
        version = step.to_format;
        applied += 1;
    }
    Ok(applied)
}

/// Recursively copy a directory (for upgrade backups).
pub fn copy_dir(src: &std::path::Path, dst: &std::path::Path) -> Result<(), MigrationError> {
    std::fs::create_dir_all(dst)?;
    for entry in std::fs::read_dir(src)? {
        let entry = entry?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());
        if src_path.is_dir() {
            copy_dir(&src_path, &dst_path)?;
        } else {
            std::fs::copy(&src_path, &dst_path)?;
        }
    }
    Ok(())
}

pub fn rename_field(raw: &mut Value, old: &str, new: &str) -> Result<(), MigrationError> {
    if let Some(obj) = raw.as_object_mut() {
        if let Some(value) = obj.remove(old) {
            obj.insert(new.to_string(), value);
        }
    }
    Ok(())
}

pub fn wrap_in_array(raw: &mut Value, old: &str, new: &str) -> Result<(), MigrationError> {
    if let Some(obj) = raw.as_object_mut() {
        if let Some(value) = obj.remove(old) {
            obj.insert(new.to_string(), Value::Array(vec![value]));
        }
    }
    Ok(())
}

pub fn migrate_manifest_to_latest(
    mut raw: Value,
    from_version: u32,
) -> Result<Value, MigrationError> {
    // v4 is baseline. No migration steps exist yet.
    // When adding the first migration (v4->v5), replace this check with a loop:
    //   let mut version = from_version;
    //   while version < CURRENT_MANIFEST_VERSION {
    //       raw = match version {
    //           4 => migrate_v4_to_v5(raw)?,
    //           _ => return Err(MigrationError::NoStep(version)),
    //       };
    //       version += 1;
    //   }
    if from_version < crate::persist::manifest::CURRENT_MANIFEST_VERSION {
        return Err(MigrationError::NoStep(from_version));
    }

    raw["format_version"] = Value::Number(serde_json::Number::from(
        crate::persist::manifest::CURRENT_MANIFEST_VERSION,
    ));
    raw["checksum"] = Value::String(String::new());
    Ok(raw)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn rename_field_simple() {
        let mut raw = json!({"old_name": 42, "other": "keep"});
        rename_field(&mut raw, "old_name", "new_name").unwrap();
        assert_eq!(raw["new_name"], 42);
        assert!(raw.get("old_name").is_none());
        assert_eq!(raw["other"], "keep");
    }

    #[test]
    fn rename_field_missing_is_noop() {
        let mut raw = json!({"foo": 1});
        rename_field(&mut raw, "nonexistent", "bar").unwrap();
        assert_eq!(raw, json!({"foo": 1}));
    }

    #[test]
    fn rename_field_on_non_object_is_noop() {
        let mut raw = json!(42);
        rename_field(&mut raw, "a", "b").unwrap();
        assert_eq!(raw, json!(42));
    }

    #[test]
    fn wrap_in_array_simple() {
        let mut raw = json!({"owner": 99});
        wrap_in_array(&mut raw, "owner", "owners").unwrap();
        assert_eq!(raw["owners"], json!([99]));
        assert!(raw.get("owner").is_none());
    }

    #[test]
    fn migrate_skips_when_already_current() {
        let raw = json!({"format_version": 4, "works": []});
        let result = migrate_manifest_to_latest(raw, 4).unwrap();
        assert_eq!(
            result["format_version"],
            crate::persist::manifest::CURRENT_MANIFEST_VERSION
        );
    }

    #[test]
    fn migrate_errors_on_unknown_step() {
        let raw = json!({"format_version": 2});
        let result = migrate_manifest_to_latest(raw, 2);
        assert!(matches!(result, Err(MigrationError::NoStep(2))));
    }

    #[test]
    fn apply_steps_from_baseline_applies_none() {
        // v1 is the baseline: upgrading v1 data is a no-op today.
        assert_eq!(
            apply_migration_steps(std::path::Path::new("."), 1).unwrap(),
            0
        );
    }

    #[test]
    fn apply_steps_from_unknown_version_fails_closed() {
        // Format 0 (stampless, no manifest) and any unregistered
        // version must error, never guess.
        assert!(matches!(
            apply_migration_steps(std::path::Path::new("."), 0),
            Err(MigrationError::NoStep(0))
        ));
        assert!(matches!(
            apply_migration_steps(std::path::Path::new("."), 99),
            Err(MigrationError::NoStep(99))
        ));
    }

    // ── Step-chain walker (custom steps, multi-revision) ───────────

    fn test_dir(tag: &str) -> std::path::PathBuf {
        let dir = std::env::temp_dir().join(format!(
            "xudanu_migrate_chain_{}_{}_{}",
            tag,
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        dir
    }

    /// A step transform that appends one line to migration-log —
    /// proves visit ORDER across a chain. Function pointers can't
    /// capture, so one arm per marker; the pattern documents how
    /// authors write plain fns.
    fn log_step(marker: &'static str) -> fn(&std::path::Path) -> Result<(), MigrationError> {
        fn append(dir: &std::path::Path, line: &str) -> Result<(), MigrationError> {
            use std::io::Write;
            let mut f = std::fs::OpenOptions::new()
                .create(true)
                .append(true)
                .open(dir.join("migration-log"))
                .map_err(MigrationError::Io)?;
            writeln!(f, "{}", line).map_err(MigrationError::Io)?;
            Ok(())
        }
        match marker {
            "s1" => |dir| append(dir, "s1"),
            "s2" => |dir| append(dir, "s2"),
            "s3" => |dir| append(dir, "s3"),
            _ => unreachable!("unknown marker"),
        }
    }

    fn chain(steps: &[(&'static str, u32, u32)]) -> Vec<MigrationStep> {
        steps
            .iter()
            .map(|(marker, from, to)| MigrationStep {
                from_format: *from,
                to_format: *to,
                description: marker,
                transform: log_step(marker),
            })
            .collect()
    }

    #[test]
    fn chain_applies_steps_in_order_across_revisions() {
        let dir = test_dir("order");
        let steps = chain(&[("s1", 1, 2), ("s2", 2, 3), ("s3", 3, 4)]);

        let applied = apply_steps_with(&dir, 1, 4, &steps).unwrap();
        assert_eq!(applied, 3);
        assert_eq!(
            std::fs::read_to_string(dir.join("migration-log")).unwrap(),
            "s1\ns2\ns3\n",
            "steps must run in format order"
        );
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn chain_from_middle_revision_skips_earlier_steps() {
        let dir = test_dir("middle");
        let steps = chain(&[("s1", 1, 2), ("s2", 2, 3), ("s3", 3, 4)]);

        let applied = apply_steps_with(&dir, 2, 4, &steps).unwrap();
        assert_eq!(applied, 2);
        assert_eq!(
            std::fs::read_to_string(dir.join("migration-log")).unwrap(),
            "s2\ns3\n",
            "data already at v2 must not re-run v1→v2"
        );
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn chain_fails_closed_on_gap() {
        let dir = test_dir("gap");
        // v2→v3 is missing: v1→v2 applies, then the walk must stop.
        let steps = chain(&[("s1", 1, 2), ("s3", 3, 4)]);

        let err = apply_steps_with(&dir, 1, 4, &steps).unwrap_err();
        assert!(matches!(err, MigrationError::NoStep(2)));
        // The step before the gap ran; nothing after it did.
        assert_eq!(
            std::fs::read_to_string(dir.join("migration-log")).unwrap(),
            "s1\n"
        );
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn chain_step_failure_stops_the_walk() {
        let dir = test_dir("fail");
        let steps = vec![
            MigrationStep {
                from_format: 1,
                to_format: 2,
                description: "ok step",
                transform: |dir| {
                    std::fs::write(dir.join("before-failure"), "").map_err(MigrationError::Io)
                },
            },
            MigrationStep {
                from_format: 2,
                to_format: 3,
                description: "failing step",
                transform: |_| Err(MigrationError::Transform("deliberate failure".into())),
            },
            MigrationStep {
                from_format: 3,
                to_format: 4,
                description: "must never run",
                transform: |dir| std::fs::write(dir.join("never"), "").map_err(MigrationError::Io),
            },
        ];

        let err = apply_steps_with(&dir, 1, 4, &steps).unwrap_err();
        assert!(matches!(err, MigrationError::Transform(_)));
        assert!(dir.join("before-failure").exists());
        assert!(
            !dir.join("never").exists(),
            "steps after a failure never run"
        );
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn chain_refuses_version_ahead_of_target() {
        let dir = test_dir("ahead");
        let steps = chain(&[("s1", 1, 2)]);
        assert!(matches!(
            apply_steps_with(&dir, 5, 4, &steps),
            Err(MigrationError::NoStep(5))
        ));
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn custom_steps_can_transform_real_sidecar_json() {
        // The authoring pattern: a custom step is a plain fn over
        // the data dir. Here, rename a field in a JSON sidecar.
        let dir = test_dir("json");
        std::fs::write(
            dir.join("settings.json"),
            r#"{"old_field": 7, "keep": true}"#,
        )
        .unwrap();
        let steps = vec![MigrationStep {
            from_format: 1,
            to_format: 2,
            description: "rename old_field → new_field",
            transform: |dir| {
                let raw: Value =
                    serde_json::from_str(&std::fs::read_to_string(dir.join("settings.json"))?)
                        .map_err(|e| MigrationError::Transform(e.to_string()))?;
                let mut raw = raw;
                rename_field(&mut raw, "old_field", "new_field")?;
                std::fs::write(
                    dir.join("settings.json"),
                    serde_json::to_string_pretty(&raw)
                        .map_err(|e| MigrationError::Transform(e.to_string()))?,
                )
                .map_err(MigrationError::Io)
            },
        }];

        apply_steps_with(&dir, 1, 2, &steps).unwrap();
        let migrated: Value =
            serde_json::from_str(&std::fs::read_to_string(dir.join("settings.json")).unwrap())
                .unwrap();
        assert_eq!(migrated["new_field"], json!(7));
        assert_eq!(migrated["keep"], json!(true));
        assert!(migrated.get("old_field").is_none());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn copy_dir_roundtrip() {
        let base = std::env::temp_dir().join(format!(
            "xudanu_migrate_copy_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let src = base.join("src");
        let dst = base.join("dst");
        std::fs::create_dir_all(src.join("nested")).unwrap();
        std::fs::write(src.join("a.txt"), "alpha").unwrap();
        std::fs::write(src.join("nested/b.txt"), "beta").unwrap();

        copy_dir(&src, &dst).unwrap();
        assert_eq!(std::fs::read_to_string(dst.join("a.txt")).unwrap(), "alpha");
        assert_eq!(
            std::fs::read_to_string(dst.join("nested/b.txt")).unwrap(),
            "beta"
        );
        let _ = std::fs::remove_dir_all(&base);
    }
}
