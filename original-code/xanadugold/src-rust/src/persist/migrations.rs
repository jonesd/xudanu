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
}
