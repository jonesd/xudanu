//! FR-60: OpenTimestamps anchoring of the attribution-log chain head.
//! Turns server-asserted timestamps into a trust-minimized existence
//! floor: the chain head hash is submitted to OTS calendars (aggregated
//! into shared Bitcoin transactions), and the returned receipt is
//! stored and upgraded. Only the 32-byte hash ever leaves the server.
//!
//! Wire format references: python-opentimestamps core (timestamp.py,
//! notary.py, op.py), verified live against alice.btc.calendar
//! (2026-09-07).

pub const DEFAULT_CALENDARS: [&str; 2] = [
    "https://alice.btc.calendar.opentimestamps.org",
    "https://bob.btc.calendar.opentimestamps.org",
];

/// `\0OpenTimestamps\0\0Proof\0` + 8 trailing bytes.
const HEADER_MAGIC: [u8; 31] = [
    0x00, 0x4f, 0x70, 0x65, 0x6e, 0x54, 0x69, 0x6d, 0x65, 0x73, 0x74, 0x61, 0x6d, 0x70, 0x73,
    0x00, 0x00, 0x50, 0x72, 0x6f, 0x6f, 0x66, 0x00, 0xbf, 0x89, 0xe2, 0xe8, 0x84, 0xe8, 0x92,
    0x94,
];
const SHA256_OP_TAG: u8 = 0x08;
const PENDING_TAG: [u8; 8] = [0x83, 0xdf, 0xe3, 0x0d, 0x2e, 0xf9, 0x0c, 0x8e];
const BITCOIN_TAG: [u8; 8] = [0x05, 0x88, 0x96, 0x0d, 0x73, 0xd7, 0x19, 0x01];
const MAX_DEPTH: usize = 64;

#[derive(Debug, Clone, PartialEq, serde::Serialize)]
pub struct ReceiptInfo {
    pub pending_calendars: Vec<String>,
    pub bitcoin_height: Option<u64>,
}

impl ReceiptInfo {
    pub fn confirmed(&self) -> bool {
        self.bitcoin_height.is_some()
    }
}

struct Stream<'a> {
    data: &'a [u8],
    pos: usize,
}

impl<'a> Stream<'a> {
    fn take(&mut self, n: usize) -> Result<&'a [u8], String> {
        if self.pos + n > self.data.len() {
            return Err(format!(
                "truncated stream: need {} bytes at {}, have {}",
                n,
                self.pos,
                self.data.len() - self.pos
            ));
        }
        let s = &self.data[self.pos..self.pos + n];
        self.pos += n;
        Ok(s)
    }
    fn peek(&self) -> Result<u8, String> {
        self.data
            .get(self.pos)
            .copied()
            .ok_or_else(|| "truncated stream: peek at eof".into())
    }
}

fn parse_attestation(s: &mut Stream, out: &mut ReceiptInfo) -> Result<(), String> {
    let tag: [u8; 8] = s
        .take(8)?
        .try_into()
        .map_err(|_| "attestation tag".to_string())?;
    let len = s.take(1)?[0] as usize;
    let payload = s.take(len)?;
    if tag == PENDING_TAG {
        out.pending_calendars
            .push(String::from_utf8_lossy(payload).into_owned());
    } else if tag == BITCOIN_TAG && payload.len() == 8 {
        let h = u64::from_le_bytes(payload.try_into().unwrap());
        out.bitcoin_height = Some(out.bitcoin_height.map_or(h, |prev: u64| prev.max(h)));
    }
    Ok(())
}

fn parse_timestamp(s: &mut Stream, out: &mut ReceiptInfo, depth: usize) -> Result<(), String> {
    if depth > MAX_DEPTH {
        return Err("stream nesting too deep".into());
    }
    loop {
        match s.peek()? {
            0xff => {
                s.take(1)?;
                if s.peek()? == 0x00 {
                    s.take(1)?;
                    parse_attestation(s, out)?;
                } else {
                    parse_op(s, out, depth)?;
                }
            }
            0x00 => {
                s.take(1)?;
                parse_attestation(s, out)?;
                return Ok(());
            }
            _ => {
                parse_op(s, out, depth)?;
                return Ok(());
            }
        }
    }
}

fn parse_op(s: &mut Stream, out: &mut ReceiptInfo, depth: usize) -> Result<(), String> {
    let tag = s.take(1)?[0];
    match tag {
        0xf0 | 0xf1 => {
            let len = s.take(1)?[0] as usize;
            s.take(len)?;
        }
        0x02 | 0x03 | 0x08 | 0x67 | 0xf2 | 0xf3 => {}
        other => return Err(format!("unknown op tag {:#04x} at {}", other, s.pos - 1)),
    }
    parse_timestamp(s, out, depth + 1)
}

/// Parse a calendar timestamp stream (the POST /digest or GET
/// /timestamp response body).
pub fn parse_stream(data: &[u8]) -> Result<ReceiptInfo, String> {
    let mut s = Stream { data, pos: 0 };
    let mut info = ReceiptInfo {
        pending_calendars: Vec::new(),
        bitcoin_height: None,
    };
    parse_timestamp(&mut s, &mut info, 0)?;
    if s.pos != data.len() {
        return Err(format!("trailing garbage: {} of {}", s.pos, data.len()));
    }
    Ok(info)
}

/// Frame a full `.ots` detached file: magic + version + sha256 tag +
/// digest + calendar stream.
pub fn frame_ots_file(digest: &[u8; 32], stream: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(stream.len() + 64);
    out.extend_from_slice(&HEADER_MAGIC);
    out.push(0x01);
    out.push(SHA256_OP_TAG);
    out.extend_from_slice(digest);
    out.extend_from_slice(stream);
    out
}

/// Transport abstraction so the anchor round is testable offline.
pub trait OtsTransport {
    fn post_digest(&self, calendar: &str, digest: &[u8; 32]) -> Result<Vec<u8>, String>;
    fn get_timestamp(&self, calendar: &str, digest: &[u8; 32]) -> Result<Vec<u8>, String>;
}

pub struct HttpOtsTransport {
    client: reqwest::blocking::Client,
}

impl HttpOtsTransport {
    pub fn new() -> Self {
        Self {
            client: reqwest::blocking::Client::builder()
                .timeout(std::time::Duration::from_secs(10))
                .user_agent("xudanu-fr60-anchor")
                .build()
                .unwrap_or_default(),
        }
    }
}

impl Default for HttpOtsTransport {
    fn default() -> Self {
        Self::new()
    }
}

fn hex32(digest: &[u8; 32]) -> String {
    digest.iter().map(|b| format!("{:02x}", b)).collect()
}

impl OtsTransport for HttpOtsTransport {
    fn post_digest(&self, calendar: &str, digest: &[u8; 32]) -> Result<Vec<u8>, String> {
        let url = format!("{}/digest", calendar);
        let resp = self
            .client
            .post(&url)
            .header("Content-Type", "application/octet-stream")
            .body(digest.to_vec())
            .send()
            .map_err(|e| format!("submit {}: {}", url, e))?;
        if !resp.status().is_success() {
            return Err(format!("submit {}: HTTP {}", url, resp.status()));
        }
        resp.bytes().map(|b| b.to_vec()).map_err(|e| e.to_string())
    }
    fn get_timestamp(&self, calendar: &str, digest: &[u8; 32]) -> Result<Vec<u8>, String> {
        let url = format!("{}/timestamp/{}", calendar, hex32(digest));
        let resp = self
            .client
            .get(&url)
            .send()
            .map_err(|e| format!("fetch {}: {}", url, e))?;
        if !resp.status().is_success() {
            return Err(format!("fetch {}: HTTP {}", url, resp.status()));
        }
        resp.bytes().map(|b| b.to_vec()).map_err(|e| e.to_string())
    }
}

/// One anchor round outcome — persisted and surfaced to the admin.
#[derive(Debug, Clone, serde::Serialize)]
pub struct AnchorRound {
    pub digest_hex: String,
    pub status: &'static str,
    pub bitcoin_height: Option<u64>,
    pub calendars: Vec<String>,
}

/// The pure anchor round: given the current chain-head digest and the
/// best previously stored stream, produce the next stream + status.
/// Submit when the head is new; fetch upgrades when it is not.
pub fn anchor_round<T: OtsTransport>(
    transport: &T,
    calendars: &[&str],
    head: [u8; 32],
    prev_stream: Option<&[u8]>,
) -> Result<(Vec<u8>, AnchorRound), String> {
    let digest_hex = hex32(&head);
    let stream: Vec<u8> = match prev_stream {
        Some(prev) if parse_stream(prev).map(|i| i.confirmed()).unwrap_or(false) => {
            return Ok((
                prev.to_vec(),
                AnchorRound {
                    digest_hex,
                    status: "confirmed",
                    bitcoin_height: parse_stream(prev).ok().and_then(|i| i.bitcoin_height),
                    calendars: Vec::new(),
                },
            ))
        }
        prev => {
            // New head, or an unconfirmed prior submission: fetch any
            // upgrade first; if that fails (or is new), submit.
            let mut fetched: Option<Vec<u8>> = None;
            let mut errors: Vec<String> = Vec::new();
            if prev.is_some() {
                for cal in calendars {
                    match transport.get_timestamp(cal, &head) {
                        Ok(s) => {
                            fetched = Some(s);
                            break;
                        }
                        Err(e) => errors.push(e),
                    }
                }
            }
            match fetched {
                Some(s) if parse_stream(&s).map(|i| i.confirmed()).unwrap_or(false) => s,
                _ => {
                    let mut submitted = None;
                    for cal in calendars {
                        match transport.post_digest(cal, &head) {
                            Ok(s) => {
                                submitted = Some(s);
                                break;
                            }
                            Err(e) => errors.push(e),
                        }
                    }
                    submitted.ok_or_else(|| format!("all calendars failed: {:?}", errors))?
                }
            }
        }
    };
    let info = parse_stream(&stream)?;
    let status = if info.confirmed() { "confirmed" } else { "pending" };
    Ok((
        stream,
        AnchorRound {
            digest_hex,
            status,
            bitcoin_height: info.bitcoin_height,
            calendars: info.pending_calendars,
        },
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The live 172-byte pending stream from alice.btc.calendar,
    /// 2026-09-07 (digest = sha256("xudanu-fr60-protocol-probe")).
    const LIVE_PENDING: &[u8] = &[
        0xf0, 0x08, 0x8b, 0x58, 0x44, 0x6d, 0xb2, 0x4b, 0x7a, 0xf0, 0x08, 0xf1,
        0x20, 0xf3, 0x3e, 0xed, 0x62, 0x0a, 0xe8, 0x81, 0xa1, 0xc3, 0x2f, 0xd5,
        0xd9, 0x90, 0x9c, 0x6a, 0x1f, 0x55, 0x48, 0x90, 0xa3, 0x0c, 0x20, 0x54,
        0xeb, 0x4a, 0xa9, 0x68, 0x93, 0xb5, 0xec, 0xe2, 0xf3, 0x08, 0xf0, 0x10,
        0xdd, 0xae, 0xee, 0x80, 0x93, 0x19, 0x33, 0xf4, 0x05, 0x6c, 0xff, 0xff,
        0xc5, 0x07, 0xb1, 0x14, 0x08, 0xf1, 0x20, 0x23, 0x30, 0x6e, 0x51, 0xeb,
        0xcd, 0x1d, 0xf4, 0xdd, 0xd1, 0x4b, 0x75, 0x7f, 0x74, 0x62, 0x37, 0xbd,
        0xa3, 0x16, 0x80, 0x5d, 0x9e, 0xb1, 0xcc, 0x7a, 0xdf, 0xef, 0x6f, 0x75,
        0x05, 0xda, 0xa3, 0x08, 0xf1, 0x04, 0x6a, 0x9e, 0xd7, 0xa6, 0xf0, 0x08,
        0xba, 0xb7, 0xc1, 0x12, 0xc1, 0x55, 0xe5, 0x0c, 0x00, 0x83, 0xdf, 0xe3,
        0x0d, 0x2e, 0xf9, 0x0c, 0x8e, 0x2e, 0x2d, 0x68, 0x74, 0x74, 0x70, 0x73,
        0x3a, 0x2f, 0x2f, 0x61, 0x6c, 0x69, 0x63, 0x65, 0x2e, 0x62, 0x74, 0x63,
        0x2e, 0x63, 0x61, 0x6c, 0x65, 0x6e, 0x64, 0x61, 0x72, 0x2e, 0x6f, 0x70,
        0x65, 0x6e, 0x74, 0x69, 0x6d, 0x65, 0x73, 0x74, 0x61, 0x6d, 0x70, 0x73,
        0x2e, 0x6f, 0x72, 0x67,
    ];

    #[test]
    fn parses_live_pending_receipt() {
        let info = parse_stream(&LIVE_PENDING).unwrap();
        assert!(!info.confirmed());
        assert_eq!(info.pending_calendars.len(), 1);
        assert!(info.pending_calendars[0].contains("alice.btc.calendar"));
    }

    #[test]
    fn parses_bitcoin_attestation() {
        // op chain ending in a Bitcoin block-height attestation.
        let mut s = vec![0x08, 0x00];
        s.extend_from_slice(&BITCOIN_TAG);
        s.push(8);
        s.extend_from_slice(&900_000u64.to_le_bytes());
        let info = parse_stream(&s).unwrap();
        assert_eq!(info.bitcoin_height, Some(900_000));
        assert!(info.confirmed());
    }

    #[test]
    fn rejects_truncated_and_garbage() {
        assert!(parse_stream(&LIVE_PENDING[..50]).is_err());
        assert!(parse_stream(&[0x99, 0x99]).is_err());
    }

    #[test]
    fn frames_ots_file_with_reference_header() {
        let digest = [7u8; 32];
        let framed = frame_ots_file(&digest, LIVE_PENDING);
        assert_eq!(&framed[..31], &HEADER_MAGIC[..]);
        assert_eq!(framed[31], 0x01);
        assert_eq!(framed[32], 0x08);
        assert_eq!(&framed[33..65], &digest[..]);
        assert_eq!(&framed[65..], LIVE_PENDING);
    }

    struct StubTransport {
        pending: Vec<u8>,
        upgraded: Vec<u8>,
    }
    impl OtsTransport for StubTransport {
        fn post_digest(&self, _c: &str, _d: &[u8; 32]) -> Result<Vec<u8>, String> {
            Ok(self.pending.to_vec())
        }
        fn get_timestamp(&self, _c: &str, _d: &[u8; 32]) -> Result<Vec<u8>, String> {
            Ok(self.upgraded.to_vec())
        }
    }

    fn confirmed_stream(height: u64) -> Vec<u8> {
        let mut s = vec![0x08, 0x00];
        s.extend_from_slice(&BITCOIN_TAG);
        s.push(8);
        s.extend_from_slice(&height.to_le_bytes());
        s
    }

    #[test]
    fn round_submits_new_head_then_upgrades() {
        let head = [9u8; 32];
        let t = StubTransport {
            pending: LIVE_PENDING.to_vec(),
            upgraded: confirmed_stream(900_123),
        };
        // New head: submit.
        let (stream, round) = anchor_round(&t, &DEFAULT_CALENDARS, head, None).unwrap();
        assert_eq!(round.status, "pending");
        assert!(round.calendars.len() == 1);
        // Same head next round: fetch upgrade → confirmed.
        let (stream2, round2) = anchor_round(&t, &DEFAULT_CALENDARS, head, Some(&stream)).unwrap();
        assert_eq!(round2.status, "confirmed");
        assert_eq!(round2.bitcoin_height, Some(900_123));
        // Confirmed stays stable (no further network dependence).
        let (_, round3) = anchor_round(&t, &DEFAULT_CALENDARS, head, Some(&stream2)).unwrap();
        assert_eq!(round3.status, "confirmed");
    }
}
