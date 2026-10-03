//! FR-141 live-server transport: MCP tools against a RUNNING xudanu
//! server over the v2 JSON WebSocket protocol (the same wire the web
//! frontend and xudanu-cli speak), instead of opening a data dir
//! directly. The server owns durability; no local checkpointing.

use serde_json::{json, Value};

use futures_util::{SinkExt, StreamExt};
use tokio_tungstenite::tungstenite::Message;
type WsStream =
    tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>;

pub struct WsDocuverse {
    rt: tokio::runtime::Runtime,
    sender: futures_util::stream::SplitSink<WsStream, Message>,
    receiver: futures_util::stream::SplitStream<WsStream>,
    next_id: u64,
}

impl WsDocuverse {
    pub fn connect(url: &str) -> Result<Self, String> {
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .map_err(|e| format!("runtime init failed: {}", e))?;
        let (sender, receiver) = rt.block_on(async_connect(url))?;
        Ok(WsDocuverse {
            rt,
            sender,
            receiver,
            next_id: 1,
        })
    }

    pub fn login_public(&mut self) -> Result<(), String> {
        let resp = self.request("session_connect", None)?;
        let _session = extract_value(&resp)
            .as_u64()
            .or_else(|| extract_value(&resp).get("value").and_then(|v| v.as_u64()))
            .ok_or("session_connect returned no session id")?;
        let resp = self.request("session_login_public", None)?;
        if resp.get("type").and_then(|t| t.as_str()) == Some("error") {
            return Err(resp
                .get("message")
                .and_then(|m| m.as_str())
                .unwrap_or("login failed")
                .to_string());
        }
        Ok(())
    }

    pub fn set_author_type(&mut self, model: &str) -> Result<(), String> {
        self.request(
            "session_set_author_type",
            Some(json!({"author_type": "llm", "llm_model": model})),
        )
        .map(|_| ())
    }

    pub fn request(&mut self, op: &str, payload: Option<Value>) -> Result<Value, String> {
        let id = self.next_id;
        self.next_id += 1;
        let mut frame = json!({"v": 2, "type": "request", "id": id, "op": op});
        if let Some(p) = payload {
            frame["payload"] = p;
        }
        let text = serde_json::to_string(&frame).map_err(|e| e.to_string())?;
        let response: Value =
            self.rt
                .block_on(async {
                    self.sender
                        .send(Message::Text(text.into()))
                        .await
                        .map_err(|e| format!("send failed: {}", e))?;
                    loop {
                        let v: Value = match self.receiver.next().await {
                            Some(Ok(Message::Text(t))) => {
                                serde_json::from_str(&t).map_err(|e| format!("bad frame: {}", e))?
                            }
                            Some(Ok(Message::Binary(b))) => serde_json::from_slice(&b)
                                .map_err(|e| format!("bad frame: {}", e))?,
                            other => return Err(format!("unexpected frame: {:?}", other)),
                        };
                        // The server interleaves subscription events and
                        // may reorder responses; wait for OUR id.
                        let is_event = v.get("type").and_then(|t| t.as_str()) == Some("event");
                        let matches = v.get("id").and_then(|i| i.as_u64()) == Some(id);
                        if !is_event && matches {
                            return Ok(v);
                        }
                    }
                })
                .map_err(|e: String| e)?;
        if response.get("type").and_then(|t| t.as_str()) == Some("error") {
            return Err(format!(
                "{} failed: {}",
                op,
                response
                    .get("message")
                    .and_then(|m| m.as_str())
                    .unwrap_or("unknown error")
            ));
        }
        Ok(response)
    }
}

async fn async_connect(
    url: &str,
) -> Result<
    (
        futures_util::stream::SplitSink<WsStream, Message>,
        futures_util::stream::SplitStream<WsStream>,
    ),
    String,
> {
    use tokio_tungstenite::tungstenite::client::IntoClientRequest;

    let http_base = url
        .trim_start_matches("ws://")
        .trim_start_matches("wss://")
        .split('/')
        .next()
        .unwrap_or("127.0.0.1:8080");

    // Normalize: a bare host means the /xudanu endpoint.
    let url = if url
        .trim_start_matches("ws://")
        .trim_start_matches("wss://")
        .contains('/')
    {
        url.to_string()
    } else {
        format!("{}/xudanu", url.trim_end_matches('/'))
    };

    let mut final_url = if url.contains("format=") {
        url.to_string()
    } else {
        let sep = if url.contains('?') { '&' } else { '?' };
        format!("{}{}format=json&version=2", url, sep)
    };
    if let Ok(resp) = reqwest::get(format!("http://{}/csrf-token", http_base)).await {
        if resp.status().is_success() {
            #[derive(serde::Deserialize)]
            struct CsrfResp {
                csrf_token: Option<String>,
            }
            if let Ok(data) = resp.json::<CsrfResp>().await {
                if let Some(token) = data.csrf_token {
                    let sep = if final_url.contains('?') { '&' } else { '?' };
                    final_url = format!("{}{}csrf_token={}", final_url, sep, token);
                }
            }
        }
    }

    let mut request = final_url
        .into_client_request()
        .map_err(|e| format!("bad url: {}", e))?;
    request
        .headers_mut()
        .insert("Origin", "http://localhost:5173".parse().unwrap());
    let (stream, _) = tokio_tungstenite::connect_async(request)
        .await
        .map_err(|e| format!("connect failed: {}", e))?;
    let (sender, mut receiver) = stream.split();

    let hs = receiver.next().await;
    match hs {
        Some(Ok(Message::Text(t))) => {
            let v: Value = serde_json::from_str(&t).map_err(|e| e.to_string())?;
            let _ = v;
        }
        Some(Ok(Message::Binary(b))) => {
            let v: Value = serde_json::from_slice(&b).map_err(|e| e.to_string())?;
            let _ = v;
        }
        other => return Err(format!("unexpected handshake: {:?}", other)),
    }
    Ok((sender, receiver))
}

const LINK_TYPE_IDS: &[(&str, u64)] = &[
    ("comment", 1),
    ("reference", 2),
    ("disagreement", 3),
    ("quotation", 4),
    ("see_also", 5),
    ("web", 6),
    ("trail", 7),
];

fn work_arg(args: &Value) -> Result<u64, String> {
    args.get("work")
        .and_then(|v| v.as_u64())
        .ok_or_else(|| "missing work id".to_string())
}

/// Responses wrap the payload twice: the frame carries
/// {"value": ResponseValue}, and ResponseValue is internally tagged
/// as {"type": "...", "value": ...}. Unwrap to the inner value; fall
/// back to the outer for flat variants (numbers, strings, arrays).
pub fn extract_value(resp: &Value) -> Value {
    let outer = resp.get("value").cloned().unwrap_or(Value::Null);
    match &outer {
        Value::Object(map) => {
            if let Some(inner) = map.get("value") {
                inner.clone()
            } else {
                outer
            }
        }
        _ => outer,
    }
}

/// Remote implementation of the FR-141 tool set over wire ops.
/// Mirrors the JSON shapes produced by the local implementation in
/// mcp.rs so MCP clients see identical results either way.
pub fn call_tool_remote(ws: &mut WsDocuverse, name: &str, args: &Value) -> Result<Value, String> {
    match name {
        "search_works" => {
            let query = args
                .get("query")
                .and_then(|v| v.as_str())
                .ok_or_else(|| "missing query".to_string())?;
            let payload = json!({
                "query": query,
                "max_results": args.get("max_results").and_then(|v| v.as_u64()).unwrap_or(20).min(100)
            });
            let resp = extract_value(&ws.request("global_text_search", Some(payload))?);
            let results = resp
                .get("results")
                .and_then(|v| v.as_array())
                .cloned()
                .unwrap_or_default();
            let entries: Vec<Value> = results
                .iter()
                .map(|r| {
                    json!({
                        "work_id": r.get("work_id"),
                        "title": r.get("title"),
                        "revision_count": r.get("revision_count"),
                        "uri": format!("xudanu://work/{}", r.get("work_id").and_then(|v| v.as_u64()).unwrap_or(0)),
                        "matches": r.get("matches").cloned().unwrap_or(json!([]))
                    })
                })
                .collect();
            Ok(json!({ "results": entries, "total": entries.len() }))
        }
        "read_work" => {
            let work = work_arg(args)?;
            let resp = extract_value(&ws.request(
                "resolve_inline_transclusions",
                Some(json!({"work_id": work})),
            )?);
            let text = resp
                .get("text")
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string();
            let total_chars = text.chars().count();
            Ok(json!({
                "work_id": work,
                "uri": format!("xudanu://work/{}", work),
                "total_chars": total_chars,
                "truncated": total_chars > 100_000,
                "text": text.chars().take(100_000).collect::<String>(),
                "span_ranges": resp.get("span_ranges").cloned().unwrap_or(json!([])),
                "span_range_count": resp.get("span_ranges").and_then(|v| v.as_array()).map(|a| a.len()).unwrap_or(0)
            }))
        }
        "read_span" => {
            let work = work_arg(args)?;
            let start = args
                .get("start")
                .and_then(|v| v.as_u64())
                .ok_or("missing start")? as usize;
            let end = args
                .get("end")
                .and_then(|v| v.as_u64())
                .ok_or("missing end")? as usize;
            if start >= end {
                return Err(format!("invalid span [{}, {})", start, end));
            }
            let revision = args.get("revision").and_then(|v| v.as_u64());
            let text = match revision {
                Some(rev) => {
                    let resp = extract_value(&ws.request(
                        "work_fetch_revision",
                        Some(json!({"work_id": work, "number": rev})),
                    )?);
                    extract_edition_text(&resp)?
                }
                None => {
                    let resp = extract_value(
                        &ws.request("work_get_edition", Some(json!({"work_id": work})))?,
                    );
                    extract_edition_text(&resp)?
                }
            };
            let total = text.chars().count();
            if end > total {
                return Err(format!(
                    "span [{}, {}) out of bounds: work has {} chars",
                    start, end, total
                ));
            }
            let slice: String = text.chars().skip(start).take(end - start).collect();
            let content_hash = blake3::hash(slice.as_bytes()).to_hex().to_string();
            let uri = match revision {
                Some(rev) => format!("xudanu://work/{}?rev={}#span={},{}", work, rev, start, end),
                None => format!("xudanu://work/{}#span={},{}", work, start, end),
            };
            Ok(json!({
                "work_id": work,
                "revision": revision,
                "start": start,
                "end": end,
                "content_hash": content_hash,
                "uri": uri,
                "text": slice
            }))
        }
        "find_backlinks" => {
            let work = work_arg(args)?;
            let resp =
                extract_value(&ws.request("work_backlinks", Some(json!({"work_id": work})))?);
            let backlinks = resp.as_array().cloned().unwrap_or_default();
            Ok(json!({ "backlinks": backlinks, "total": backlinks.len() }))
        }
        "who_transcluded" => {
            let work = work_arg(args)?;
            let resp = extract_value(
                &ws.request("find_transcluders", Some(json!({"content_be_id": work})))?,
            );
            let reusers = resp.as_array().cloned().unwrap_or_default();
            Ok(json!({ "reusers": reusers, "total": reusers.len() }))
        }
        "get_prov" => {
            let work = work_arg(args)?;
            let resp = extract_value(&ws.request(
                "prov_json_export",
                Some(json!({"work_id": work, "include_federation": false})),
            )?);
            let prov_str = resp.as_str().unwrap_or_default().to_string();
            let doc: Value = serde_json::from_str(&prov_str).unwrap_or(Value::String(prov_str));
            Ok(json!({
                "work_id": work,
                "uri": format!("xudanu://work/{}", work),
                "prov": doc
            }))
        }
        "get_version_info" => {
            let work = work_arg(args)?;
            let resp = extract_value(&ws.request("work_summary", Some(json!({"work_id": work})))?);
            Ok(json!({
                "work_id": work,
                "title": resp.get("title"),
                "revision_count": resp.get("revision_count"),
                "uri": format!("xudanu://work/{}", work)
            }))
        }
        "create_work" => {
            let text = args
                .get("text")
                .and_then(|v| v.as_str())
                .ok_or_else(|| "missing text".to_string())?;
            let resp = extract_value(
                &ws.request("work_create", Some(json!({"edition": {"text": text}})))?,
            );
            let work = resp
                .as_u64()
                .or_else(|| resp.get("value").and_then(|v| v.as_u64()))
                .ok_or("no work id in response")?;
            Ok(json!({
                "work_id": work,
                "uri": format!("xudanu://work/{}", work),
                "revision": 0
            }))
        }
        "transclude" => {
            let source = args
                .get("source_work")
                .and_then(|v| v.as_u64())
                .ok_or("missing source_work")?;
            let start = args
                .get("start")
                .and_then(|v| v.as_u64())
                .ok_or("missing start")? as usize;
            let end = args
                .get("end")
                .and_then(|v| v.as_u64())
                .ok_or("missing end")? as usize;
            let element = json!({
                "type": "transclusion",
                "work_id": source,
                "char_start": start,
                "char_end": end
            });
            let (work, created) = match args.get("into_work").and_then(|v| v.as_u64()) {
                Some(existing) => (existing, false),
                None => {
                    let resp = extract_value(
                        &ws.request("work_create", Some(json!({"edition": "empty"})))?,
                    );
                    let work = resp
                        .as_u64()
                        .or_else(|| resp.get("value").and_then(|v| v.as_u64()))
                        .ok_or("no work id")?;
                    (work, true)
                }
            };
            let at = args.get("at").and_then(|v| v.as_i64()).unwrap_or(0);
            let resp = extract_value(&ws.request(
                "element_insert",
                Some(json!({
                    "work_id": work, "position": at, "element": element
                })),
            )?);
            Ok(json!({
                "work_id": work,
                "created_new_work": created,
                "revision": resp.as_u64().unwrap_or(0),
                "source_work": source,
                "source_span": {"start": start, "end": end},
                "uri": format!("xudanu://work/{}", work)
            }))
        }
        "create_link" => {
            let origin = args
                .get("origin")
                .and_then(|v| v.as_u64())
                .ok_or("missing origin")?;
            let destination = args
                .get("destination")
                .and_then(|v| v.as_u64())
                .ok_or("missing destination")?;
            let type_name = args.get("link_type").and_then(|v| v.as_str());
            let payload = match type_name {
                None => json!({"origin": origin, "destination": destination}),
                Some(name) => {
                    let type_id = LINK_TYPE_IDS
                        .iter()
                        .find(|(n, _)| *n == name)
                        .map(|(_, id)| *id)
                        .ok_or_else(|| format!("unknown link_type: {}", name))?;
                    json!({"origin": origin, "destination": destination, "link_types": [type_id]})
                }
            };
            let resp = extract_value(&ws.request("link_create", Some(payload))?);
            Ok(json!({
                "link_id": resp.as_u64().unwrap_or(0),
                "origin": origin,
                "destination": destination,
                "link_type": type_name,
                "origin_uri": format!("xudanu://work/{}", origin),
                "destination_uri": format!("xudanu://work/{}", destination)
            }))
        }
        "revise" => {
            let work = work_arg(args)?;
            let text = args
                .get("text")
                .and_then(|v| v.as_str())
                .ok_or("missing text")?;
            ws.request("work_grab", Some(json!({"work_id": work})))
                .map_err(|e| format!("grab failed: {}", e))?;
            let outcome = ws.request(
                "work_revise",
                Some(json!({"work_id": work, "edition": {"text": text}})),
            );
            let release = ws.request("work_release", Some(json!({"work_id": work})));
            let resp = outcome.map_err(|e| format!("revise failed: {}", e))?;
            release.map_err(|e| format!("release failed: {}", e))?;
            Ok(json!({
                "work_id": work,
                "revision": extract_value(&resp).as_u64().unwrap_or(0),
                "uri": format!("xudanu://work/{}", work)
            }))
        }
        "compare_versions" => {
            let work = work_arg(args)?;
            let from_rev = args
                .get("from_rev")
                .and_then(|v| v.as_u64())
                .ok_or("missing from_rev")?;
            let to_rev = args
                .get("to_rev")
                .and_then(|v| v.as_u64())
                .ok_or("missing to_rev")?;
            let resp = extract_value(&ws.request(
                "revision_compare",
                Some(json!({
                    "work_id": work, "rev_a": from_rev, "rev_b": to_rev
                })),
            )?);
            Ok(json!({
                "work_id": work,
                "from_rev": from_rev,
                "to_rev": to_rev,
                "inserted": resp.get("inserted").cloned().unwrap_or(json!([])),
                "deleted": resp.get("deleted").cloned().unwrap_or(json!([])),
                "unchanged_ratio": resp.get("unchanged_ratio").cloned().unwrap_or(json!(null)),
                "source": resp.get("source").cloned().unwrap_or(json!(null))
            }))
        }
        "watch_work" => {
            let work = work_arg(args)?;
            let kind = args
                .get("kind")
                .and_then(|v| v.as_str())
                .ok_or("missing kind")?;
            let mut m = json!({
                "link_types": [],
                "from_clubs": []
            });
            if let Some(type_name) = args.get("link_type").and_then(|v| v.as_str()) {
                let type_id = LINK_TYPE_IDS
                    .iter()
                    .find(|(n, _)| *n == type_name)
                    .map(|(_, id)| *id)
                    .ok_or_else(|| format!("unknown link_type: {}", type_name))?;
                m["link_types"] = json!([type_id]);
            }
            if let Some(dir) = args.get("direction").and_then(|v| v.as_str()) {
                m["direction"] = json!(dir);
            }
            let resp = extract_value(&ws.request(
                "detector_create",
                Some(json!({
                    "work_id": work, "kind": kind, "match": m
                })),
            )?);
            Ok(json!({
                "detector_id": resp.get("detector_id"),
                "work_id": work,
                "kind": kind,
                "unread": resp.get("unread")
            }))
        }
        "detector_events" => {
            let resp = extract_value(&ws.request("detector_list", None)?);
            let detectors = resp
                .get("detectors")
                .and_then(|v| v.as_array())
                .or_else(|| resp.as_array())
                .cloned()
                .unwrap_or_default();
            let filter = args.get("detector_id").and_then(|v| v.as_u64());
            let entries: Vec<Value> = detectors
                .into_iter()
                .filter(|d| {
                    filter.is_none_or(|f| d.get("detector_id").and_then(|v| v.as_u64()) == Some(f))
                })
                .collect();
            Ok(json!({ "detectors": entries, "total": entries.len() }))
        }
        "detector_ack" => {
            let detector_id = args
                .get("detector_id")
                .and_then(|v| v.as_u64())
                .ok_or("missing detector_id")?;
            let resp = extract_value(
                &ws.request("detector_ack", Some(json!({"detector_id": detector_id})))?,
            );
            Ok(json!({"detector_id": detector_id, "acked": resp.as_u64().unwrap_or(0)}))
        }
        "unwatch_work" => {
            let detector_id = args
                .get("detector_id")
                .and_then(|v| v.as_u64())
                .ok_or("missing detector_id")?;
            let resp = extract_value(
                &ws.request("detector_delete", Some(json!({"detector_id": detector_id})))?,
            );
            Ok(json!({"detector_id": detector_id, "deleted": resp.as_bool().unwrap_or(false)}))
        }
        other => Err(format!("unknown tool: {}", other)),
    }
}

fn extract_edition_text(edition_value: &Value) -> Result<String, String> {
    if let Some(text) = edition_value.get("text").and_then(|v| v.as_str()) {
        return Ok(text.to_string());
    }
    if let Some(entries) = edition_value.get("entries").and_then(|v| v.as_array()) {
        let mut text = String::new();
        for entry in entries {
            if let Some(elem) = entry.as_array().and_then(|a| a.get(1)) {
                if let Some(t) = elem.get("text").and_then(|v| v.as_str()) {
                    text.push_str(t);
                }
            }
        }
        return Ok(text);
    }
    if edition_value.is_null() || edition_value.get("empty").is_some() {
        return Ok(String::new());
    }
    Ok(String::new())
}
