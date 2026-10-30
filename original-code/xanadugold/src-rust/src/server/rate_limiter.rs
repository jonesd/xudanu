use std::collections::HashMap;
use std::net::IpAddr;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::Mutex;
use std::time::{Duration, Instant};

const RATE_WINDOW: Duration = Duration::from_secs(60);
/// Default public-read budget per client IP per window. Sized for a
/// human browsing at up to ~2 page loads/sec — the capacity probe
/// (scripts/fr155-load.mjs) measured the read path at ~2,800 req/s
/// aggregate, so this per-reader cap is the binding constraint by
/// design, not a throughput bottleneck.
pub const DEFAULT_GET_LIMIT: u32 = 120;
/// Admin floor for the public-read limit: a value below this locks
/// out legitimate readers (a single page load fetches several
/// resources). The admin op rejects values outside
/// MIN_GET_LIMIT..=MAX_GET_LIMIT.
pub const MIN_GET_LIMIT: u32 = 10;
/// Admin ceiling: anything beyond this is a configuration mistake
/// (the point is abuse resistance, not an open pipe). ~16k reads/s
/// per IP is far past the measured whole-server ceiling.
pub const MAX_GET_LIMIT: u32 = 1_000_000;
/// FR-79 Stage 2: overlay marks queries per minute, per IP. Each
/// query carries the page's text spine (up to 2 MB) and runs
/// excerpt resolution server-side — browsing generates one per page
/// load; scrapes generate hundreds.
const OVERLAY_LIMIT: u32 = 60;
const NOTIFY_LIMIT: u32 = 30;
const NOTIFY_WINDOW: Duration = Duration::from_secs(3600);
/// FR-41 S1: federated search fan-outs per minute, per session.
/// Each fan-out costs every trusted peer a search — interactive
/// search needs a handful; scripts need to be told to slow down.
pub const FEDERATED_SEARCH_LIMIT: u32 = 10;
const FEDERATED_SEARCH_WINDOW: Duration = Duration::from_secs(60);

struct RateEntry {
    count: u32,
    window_start: Instant,
}

struct NotifyEntry {
    count: u32,
    window_start: Instant,
}

pub struct RateLimiter {
    get_entries: Mutex<HashMap<IpAddr, RateEntry>>,
    overlay_by_ip: Mutex<HashMap<IpAddr, RateEntry>>,
    notify_by_ip: Mutex<HashMap<IpAddr, NotifyEntry>>,
    notify_by_server: Mutex<HashMap<String, NotifyEntry>>,
    federated_search_by_session: Mutex<HashMap<u64, RateEntry>>,
    /// Public-read budget per IP per window. Admin-adjustable at
    /// runtime (AdminRateLimitSet) and boot-settable via
    /// XUDANU_RATE_GET_LIMIT; Relaxed ordering is sufficient — the
    /// limit is advisory counting, not synchronization.
    get_limit: AtomicU32,
}

impl RateLimiter {
    pub fn new() -> Self {
        RateLimiter {
            get_entries: Mutex::new(HashMap::new()),
            overlay_by_ip: Mutex::new(HashMap::new()),
            notify_by_ip: Mutex::new(HashMap::new()),
            notify_by_server: Mutex::new(HashMap::new()),
            federated_search_by_session: Mutex::new(HashMap::new()),
            get_limit: AtomicU32::new(DEFAULT_GET_LIMIT),
        }
    }

    /// Boot-time operator override: XUDANU_RATE_GET_LIMIT. Invalid or
    /// out-of-bounds values keep the default (with a warning) rather
    /// than refusing to start.
    pub fn from_env() -> Self {
        let limiter = RateLimiter::new();
        if let Ok(raw) = std::env::var("XUDANU_RATE_GET_LIMIT") {
            match raw.trim().parse::<u32>() {
                Ok(n) if (MIN_GET_LIMIT..=MAX_GET_LIMIT).contains(&n) => {
                    limiter.get_limit.store(n, Ordering::Relaxed);
                }
                _ => {
                    tracing::warn!(
                        value = %raw,
                        min = MIN_GET_LIMIT,
                        max = MAX_GET_LIMIT,
                        "XUDANU_RATE_GET_LIMIT invalid; keeping default {}",
                        DEFAULT_GET_LIMIT
                    );
                }
            }
        }
        limiter
    }

    pub fn get_limit(&self) -> u32 {
        self.get_limit.load(Ordering::Relaxed)
    }

    /// Set the public-read budget. The only hard invariant here is
    /// "never zero" — a zero limit blocks every read forever (counts
    /// only increment). Explicit bounds (MIN..=MAX) are enforced by
    /// the admin op and the env parser, which reject out-of-range
    /// values with an error instead of silently clamping.
    pub fn set_get_limit(&self, limit: u32) {
        let floored = limit.max(1);
        self.get_limit.store(floored, Ordering::Relaxed);
    }

    /// FR-79 Stage 2: rate-limit overlay marks queries per IP.
    pub fn check_overlay(&self, ip: IpAddr) -> bool {
        let mut entries = self.overlay_by_ip.lock().unwrap();
        let now = Instant::now();
        let entry = entries.entry(ip).or_insert(RateEntry {
            count: 0,
            window_start: now,
        });
        if now.duration_since(entry.window_start) > RATE_WINDOW {
            entry.count = 0;
            entry.window_start = now;
        }
        entry.count += 1;
        entry.count <= OVERLAY_LIMIT
    }

    /// FR-41 S1: rate-limit federated-search fan-outs per session.
    pub fn check_federated_search(&self, session_id: u64) -> bool {
        let mut entries = self.federated_search_by_session.lock().unwrap();
        let now = Instant::now();
        let entry = entries.entry(session_id).or_insert(RateEntry {
            count: 0,
            window_start: now,
        });
        if now.duration_since(entry.window_start) > FEDERATED_SEARCH_WINDOW {
            entry.count = 0;
            entry.window_start = now;
        }
        entry.count += 1;
        entry.count <= FEDERATED_SEARCH_LIMIT
    }

    pub fn check_get(&self, ip: IpAddr) -> bool {
        let mut entries = self.get_entries.lock().unwrap();
        let now = Instant::now();
        let entry = entries.entry(ip).or_insert(RateEntry {
            count: 0,
            window_start: now,
        });
        if now.duration_since(entry.window_start) > RATE_WINDOW {
            entry.count = 0;
            entry.window_start = now;
        }
        entry.count += 1;
        entry.count <= self.get_limit()
    }

    pub fn check_notify(&self, ip: IpAddr, server_id: &str) -> (bool, bool) {
        let now = Instant::now();

        let mut by_ip = self.notify_by_ip.lock().unwrap();
        let ip_entry = by_ip.entry(ip).or_insert(NotifyEntry {
            count: 0,
            window_start: now,
        });
        if now.duration_since(ip_entry.window_start) > NOTIFY_WINDOW {
            ip_entry.count = 0;
            ip_entry.window_start = now;
        }
        ip_entry.count += 1;
        let ip_ok = ip_entry.count <= NOTIFY_LIMIT;
        drop(by_ip);

        let mut by_server = self.notify_by_server.lock().unwrap();
        let srv_entry = by_server
            .entry(server_id.to_string())
            .or_insert(NotifyEntry {
                count: 0,
                window_start: now,
            });
        if now.duration_since(srv_entry.window_start) > NOTIFY_WINDOW {
            srv_entry.count = 0;
            srv_entry.window_start = now;
        }
        srv_entry.count += 1;
        let srv_ok = srv_entry.count <= NOTIFY_LIMIT;

        (ip_ok, srv_ok)
    }

    pub fn cleanup(&self) {
        let now = Instant::now();
        {
            let mut entries = self.get_entries.lock().unwrap();
            entries.retain(|_, e| now.duration_since(e.window_start) < RATE_WINDOW * 2);
        }
        {
            let mut by_ip = self.notify_by_ip.lock().unwrap();
            by_ip.retain(|_, e| now.duration_since(e.window_start) < NOTIFY_WINDOW * 2);
        }
        {
            let mut by_server = self.notify_by_server.lock().unwrap();
            by_server.retain(|_, e| now.duration_since(e.window_start) < NOTIFY_WINDOW * 2);
        }
    }

    pub fn get_stats(&self) -> RateLimitStats {
        let get_count = self.get_entries.lock().unwrap().len();
        let notify_ip_count = self.notify_by_ip.lock().unwrap().len();
        let notify_srv_count = self.notify_by_server.lock().unwrap().len();
        RateLimitStats {
            tracked_ips: get_count,
            notify_ips: notify_ip_count,
            notify_servers: notify_srv_count,
            get_limit: self.get_limit(),
            notify_limit: NOTIFY_LIMIT,
            get_window_secs: RATE_WINDOW.as_secs(),
            notify_window_secs: NOTIFY_WINDOW.as_secs(),
        }
    }
}

#[derive(Debug, serde::Serialize)]
pub struct RateLimitStats {
    pub tracked_ips: usize,
    pub notify_ips: usize,
    pub notify_servers: usize,
    pub get_limit: u32,
    pub notify_limit: u32,
    pub get_window_secs: u64,
    pub notify_window_secs: u64,
}

pub fn validate_work_id_hex(id: &str) -> bool {
    !id.is_empty() && id.len() <= 8 && id.chars().all(|c| c.is_ascii_hexdigit())
}

pub fn validate_content_hash(hex: &str) -> bool {
    hex.len() == 64 && hex.chars().all(|c| c.is_ascii_hexdigit())
}

pub fn validate_tumbler(tumbler: &str) -> bool {
    if tumbler.is_empty() || tumbler.len() > 256 {
        return false;
    }
    if tumbler.starts_with('"') {
        if let Some(end) = tumbler[1..].find('"') {
            let inner = &tumbler[1..1 + end];
            if inner.is_empty() {
                return false;
            }
            if !inner
                .chars()
                .all(|c| c.is_alphanumeric() || c == '.' || c == '-' || c == '_')
            {
                return false;
            }
            let rest = &tumbler[2 + end..];
            return rest.starts_with('.')
                && rest[1..].chars().all(|c| c.is_ascii_digit() || c == '.');
        }
        return false;
    }
    tumbler.chars().all(|c| c.is_ascii_digit() || c == '.')
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::net::Ipv4Addr;

    #[test]
    fn rate_limiter_allows_under_limit() {
        let limiter = RateLimiter::new();
        let ip = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));
        for _ in 0..120 {
            assert!(limiter.check_get(ip), "should allow up to limit");
        }
    }

    #[test]
    fn rate_limiter_blocks_over_limit() {
        let limiter = RateLimiter::new();
        let ip = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));
        for _ in 0..120 {
            limiter.check_get(ip);
        }
        assert!(!limiter.check_get(ip), "should block over limit");
    }

    #[test]
    fn rate_limiter_separate_ips() {
        let limiter = RateLimiter::new();
        let ip1 = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));
        let ip2 = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 2));
        for _ in 0..120 {
            limiter.check_get(ip1);
        }
        assert!(limiter.check_get(ip2), "different IP should not be blocked");
    }

    #[test]
    fn rate_limiter_get_limit_admin_adjustable() {
        let limiter = RateLimiter::new();
        assert_eq!(limiter.get_limit(), DEFAULT_GET_LIMIT);
        limiter.set_get_limit(2);
        let ip = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));
        assert!(limiter.check_get(ip));
        assert!(limiter.check_get(ip));
        assert!(!limiter.check_get(ip), "admin-set limit is enforced");
        assert_eq!(
            limiter.get_stats().get_limit,
            2,
            "stats reflect the set limit"
        );
    }

    #[test]
    fn rate_limiter_get_limit_rejects_lockout_values() {
        let limiter = RateLimiter::new();
        limiter.set_get_limit(0);
        assert_eq!(
            limiter.get_limit(),
            1,
            "zero would block every read forever; setter floors it at 1"
        );
        assert!(
            limiter.check_get(IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1))),
            "first read still allowed at floor"
        );
    }

    #[test]
    fn rate_limiter_get_limit_changes_apply_immediately() {
        let limiter = RateLimiter::new();
        let ip = IpAddr::V4(Ipv4Addr::new(10, 0, 0, 1));
        limiter.set_get_limit(3);
        for _ in 0..3 {
            assert!(limiter.check_get(ip));
        }
        limiter.set_get_limit(5);
        assert!(
            limiter.check_get(ip),
            "raising admits more within the same window"
        );
        assert!(limiter.check_get(ip));
        assert!(!limiter.check_get(ip), "new cap enforced once reached");
    }

    #[test]
    fn rate_limiter_notify_limits() {
        let limiter = RateLimiter::new();
        let ip = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));
        for _ in 0..30 {
            let (ip_ok, srv_ok) = limiter.check_notify(ip, "server-1");
            assert!(ip_ok && srv_ok);
        }
        let (ip_ok, _) = limiter.check_notify(ip, "server-2");
        assert!(!ip_ok, "IP should be over limit");
    }

    #[test]
    fn federated_search_limit_per_session() {
        let limiter = RateLimiter::new();
        for _ in 0..FEDERATED_SEARCH_LIMIT {
            assert!(limiter.check_federated_search(42), "under limit allowed");
        }
        assert!(
            !limiter.check_federated_search(42),
            "over limit blocked (amplifier guard)"
        );
    }

    #[test]
    fn federated_search_sessions_independent() {
        let limiter = RateLimiter::new();
        for _ in 0..FEDERATED_SEARCH_LIMIT {
            limiter.check_federated_search(1);
        }
        assert!(
            limiter.check_federated_search(2),
            "different session unaffected"
        );
    }

    #[test]
    fn validate_work_id_valid() {
        assert!(validate_work_id_hex("0424"));
        assert!(validate_work_id_hex("deadbeef"));
    }

    #[test]
    fn validate_work_id_invalid() {
        assert!(!validate_work_id_hex(""));
        assert!(!validate_work_id_hex("gggg"));
        assert!(!validate_work_id_hex("123456789"));
    }

    #[test]
    fn validate_content_hash_valid() {
        assert!(validate_content_hash(
            "a1b2c3d4e5f67890a1b2c3d4e5f67890a1b2c3d4e5f67890a1b2c3d4e5f67890"
        ));
    }

    #[test]
    fn validate_content_hash_invalid() {
        assert!(!validate_content_hash("short"));
        assert!(!validate_content_hash(&"gg".repeat(32)));
    }

    #[test]
    fn validate_tumbler_domain() {
        assert!(validate_tumbler("\"alice.example.com\".5.3.10.7"));
    }

    #[test]
    fn validate_tumbler_numeric() {
        assert!(validate_tumbler("1.5.3.10.7"));
    }

    #[test]
    fn validate_tumbler_invalid() {
        assert!(!validate_tumbler(""));
        assert!(!validate_tumbler("'; DROP TABLE"));
    }
}
