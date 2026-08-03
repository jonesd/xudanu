/// Pluggable email transport. The default [`DevProvider`] logs the link.
pub trait EmailProvider: Send + Sync {
    /// Deliver a verification link to `to_email`. The URL is absolute and
    /// ready to click.
    fn send_verification(&self, to_email: &str, verification_url: &str);
}

/// Development provider: writes the verification link to the server log so the
/// flow is fully testable with no email infrastructure.
pub struct DevProvider;

impl EmailProvider for DevProvider {
    fn send_verification(&self, to_email: &str, verification_url: &str) {
        tracing::info!(
            target: "xudanu::verification",
            to = %to_email,
            url = %verification_url,
            "DEV verification email (no SMTP configured); click the link to verify"
        );
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn dev_provider_send_does_not_panic() {
        let provider = DevProvider;
        provider.send_verification("user@example.com", "https://example.com/verify?token=abc");
    }

    #[test]
    fn dev_provider_send_empty_inputs_does_not_panic() {
        let provider = DevProvider;
        provider.send_verification("", "");
    }
}
