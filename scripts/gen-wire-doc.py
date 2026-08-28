#!/usr/bin/env python3
"""Generate wire.md from real server traffic.

The 1.5 approach: instead of hand-writing protocol docs and testing them
against the server, we START a server, SEND documented operations, CAPTURE
the actual responses, and GENERATE the documentation from reality. The docs
are born true because they come from the code, not from intention.

Usage:
    python3 gen-wire-doc.py [--server ws://host:port] [--output wire.md]
"""

import argparse
import asyncio
import json
import sys
import os

sys.path.insert(0, os.environ.get("FEBE_PATH", "/tmp/green-probe/febe"))

# We'll use the WebSocket client directly (no external deps)
try:
    import websockets
except ImportError:
    print("ERROR: pip3 install websockets", file=sys.stderr)
    sys.exit(1)

# ── Operations to document, with their payloads and setup requirements ─────

OPS = [
    {
        "op": "session_connect",
        "payload": None,
        "setup": [],
        "description": "Open a session. Returns the session ID.",
        "auth": "none",
    },
    {
        "op": "session_login_public",
        "payload": None,
        "setup": ["session_connect"],
        "description": "Login as anonymous public user.",
        "auth": "none",
    },
    {
        "op": "whoami",
        "payload": None,
        "setup": ["session_connect", "session_login_public"],
        "description": "Check current identity.",
        "auth": "public",
    },
    {
        "op": "work_create",
        "payload": {"edition": {"text": "Hello from the wire doc generator."}},
        "setup": ["session_connect", "session_login_public"],
        "description": "Create a new work with text content.",
        "auth": "logged_in",
    },
    {
        "op": "work_list",
        "payload": {"limit": 10},
        "setup": ["session_connect"],
        "description": "List works visible to the session.",
        "auth": "none",
    },
    {
        "op": "work_get_edition",
        "payload": None,
        "depends_on": "work_create",
        "setup": ["session_connect", "session_login_public", "work_create"],
        "description": "Fetch the current edition text of a work.",
        "auth": "read",
    },
    {
        "op": "work_star",
        "payload": None,
        "depends_on": "work_create",
        "setup": ["session_connect", "session_login_public", "work_create"],
        "description": "Star a work.",
        "auth": "owner",
    },
    {
        "op": "work_publish",
        "payload": None,
        "depends_on": "work_create",
        "setup": ["session_connect", "session_login_public", "work_create"],
        "description": "Make a work publicly readable.",
        "auth": "owner",
    },
    {
        "op": "server_stats",
        "payload": None,
        "setup": ["session_connect"],
        "description": "Get server statistics.",
        "auth": "none",
    },
    {
        "op": "blob_stats",
        "payload": None,
        "setup": ["session_connect"],
        "description": "Get blob store statistics.",
        "auth": "none",
    },
    {
        "op": "club_names",
        "payload": None,
        "setup": ["session_connect"],
        "description": "List known club names.",
        "auth": "none",
    },
    {
        "op": "club_who_am_i",
        "payload": None,
        "setup": ["session_connect", "session_login_public"],
        "description": "Check current club identity.",
        "auth": "public",
    },
    {
        "op": "trail_list",
        "payload": None,
        "setup": ["session_connect"],
        "description": "List trails (curated reading paths).",
        "auth": "none",
    },
    {
        "op": "connection_pins_get",
        "payload": None,
        "setup": ["session_connect"],
        "description": "Get persistent connection pins.",
        "auth": "logged_in",
    },
    {
        "op": "federation_info",
        "payload": None,
        "setup": ["session_connect"],
        "description": "Get federation status.",
        "auth": "none",
    },
    {
        "op": "attribution_log_status",
        "payload": None,
        "setup": ["session_connect"],
        "description": "Get attribution log status.",
        "auth": "none",
    },
    {
        "op": "crypto_get_public_key",
        "payload": None,
        "setup": ["session_connect"],
        "description": "Get the server's public key.",
        "auth": "none",
    },
    {
        "op": "search",
        "payload": None,
        "setup": ["session_connect"],
        "description": "Search public content.",
        "auth": "none",
    },
    {
        "op": "metrics_snapshot",
        "payload": None,
        "setup": ["session_connect"],
        "description": "Get operation metrics (admin).",
        "auth": "admin",
    },
    {
        "op": "admin_active_sessions",
        "payload": None,
        "setup": ["session_connect"],
        "description": "List active sessions (admin).",
        "auth": "admin",
    },
]


async def connect_and_capture(server_url: str) -> dict:
    """Connect to a server, run all ops, capture real request/response pairs."""
    results = {}

    # Get CSRF token first
    import urllib.request
    base_http = server_url.replace("ws://", "http://").replace("wss://", "https://")
    req = urllib.request.Request(f"{base_http}/csrf-token")
    with urllib.request.urlopen(req) as resp:
        csrf = json.loads(resp.read()).get("csrf_token")

    async with websockets.connect(
        f"{server_url}/xudanu?format=json&version=2&csrf_token={csrf}",
        additional_headers={"Origin": "http://localhost:5173"}
    ) as ws:
        # Handshake
        handshake = await ws.recv()

        # Run each op
        work_id = None
        msg_id = 0

        for spec in OPS:
            op = spec["op"]
            payload = spec.get("payload")

            # Fill in dependent values
            if spec.get("depends_on") == "work_create" and work_id:
                if payload is None:
                    payload = {}
                payload["work_id"] = work_id

            if payload is None and op != "session_connect":
                payload = {}

            msg_id += 1
            frame = {
                "v": 2,
                "type": "request",
                "id": msg_id,
                "op": op,
            }
            if payload:
                frame["payload"] = payload

            request = json.dumps(frame, indent=2)
            await ws.send(request)

            try:
                response = await asyncio.wait_for(ws.recv(), timeout=5.0)
                resp = json.loads(response)
                # Normalize volatile fields
                resp = normalize(resp)
                resp, warns = sanitize(resp)
                for w in warns:
                    print(f'  SANITIZED: {w}')
            except asyncio.TimeoutError:
                resp = {"error": "TIMEOUT"}
            except Exception as e:
                resp = {"error": str(e)}

            results[op] = {"request": frame, "response": resp}

            # Capture work_id for dependent ops
            if op == "work_create":
                val = resp.get("value", {})
                if isinstance(val, dict) and "value" in val:
                    work_id = val["value"]
                elif isinstance(val, (int, float)):
                    work_id = val

    return results


def normalize(resp: dict) -> dict:
    """Mask volatile fields so examples are deterministic."""
    import copy
    r = copy.deepcopy(resp)

    def walk(obj):
        if isinstance(obj, dict):
            for key in list(obj.keys()):
                if key in ("session_id", "server_id", "started_at", "current_text",
                          "char_count", "revision", "attribution", "char_count",
                          "content_hash_blake3", "tumbler", "work_id", "value"):
                    if key in ("value",) and isinstance(obj[key], (int, float)):
                        obj[key] = "<id>"
                    elif key in ("session_id",):
                        obj[key] = "<session_id>"
                    elif key in ("current_text",):
                        obj[key] = "<text>"
                    elif key in ("content_hash_blake3",):
                        obj[key] = "<hash>"
                    elif key in ("tumbler",):
                        obj[key] = "<tumbler>"
                elif isinstance(obj[key], (dict, list)):
                    walk(obj[key])
        elif isinstance(obj, list):
            for item in obj:
                walk(item)

    walk(r)
    return r


def compact_resp(resp: dict, max_len: int = 300) -> str:
    """Compact response: strip envelope, show only value."""
    if resp.get("type") == "response":
        val = resp.get("value", {})
        s = json.dumps(val, indent=2)
        return s if len(s) <= max_len else s[:max_len] + "\n..."
    return json.dumps(resp, indent=2)


def compact_req(req: dict) -> str:
    """Compact request: show only op + payload (envelope documented once)."""
    payload = req.get("payload", {})
    if not payload:
        return "()  // no payload"
    return json.dumps(payload, indent=2)




# Patterns that should never appear in committed docs.
import re as _re
SENSITIVE_PATTERNS = [
    (_re.compile(r'[\w.+-]+@(?!example\.com)[\w.-]+\.[a-z]{2,}'), '<email>'),
    (_re.compile(r'greetingsforalltime|admin12345|xudanu-demo-admin'), '<sanitized>'),
    (_re.compile(r'[0-9a-f]{64,}'), '<hash>'),
    (_re.compile(r'root@\d+\.\d+\.\d+\.\d+'), '<server>'),
]

def sanitize(obj):
    """Recursively scrub sensitive values. Returns (obj, warnings)."""
    warnings = []
    def walk(o):
        if isinstance(o, str):
            for pat, replacement in SENSITIVE_PATTERNS:
                if pat.search(o):
                    warnings.append(o[:40])
                    return replacement
            return o
        elif isinstance(o, dict):
            return {k: walk(v) for k, v in o.items()}
        elif isinstance(o, list):
            return [walk(i) for i in o]
        return o
    return walk(obj), warnings


def generate_markdown(results: dict) -> str:
    """Generate compact wire.md: envelope once, unique fields per op."""
    lines = [
        "# Xudanu Wire Protocol",
        "",
        "> Generated from real server traffic.",
        "> Regenerate: `python3 scripts/gen-wire-doc.py`",
        "",
        "## Envelope (all requests)",
        "",
        "```json",
        '{"v": 2, "type": "request", "id": <n>, "op": "<name>", "payload": {...}}',
        "```",
        "",
        "## Envelope (all responses)",
        "",
        "```json",
        '{"v": 2, "type": "response", "id": <same>, "value": {...}}',
        '{"v": 2, "type": "error", "id": 0, "code": "...", "message": "..."}',
        "```",
        "",
        "## Auth sequence",
        "",
        "```",
        "session_connect → session_login_public  (anonymous)",
        "session_connect → club_id_by_name → session_login → session_authenticate  (identity)",
        "session_connect → club_id_by_name → session_login → session_authenticate  (admin)",
        "```",
        "",
        "---",
        "",
    ]

    # Simple ops: table format
    simple_ops = []
    complex_ops = []

    for spec in OPS:
        op = spec["op"]
        if op not in results:
            continue
        data = results[op]
        resp_str = compact_resp(data["response"])
        if len(resp_str) < 200:
            simple_ops.append((spec, data))
        else:
            complex_ops.append((spec, data))

    # Table for simple ops
    if simple_ops:
        lines.append("## Simple operations")
        lines.append("")
        lines.append("| Op | Auth | Payload | Response value |")
        lines.append("|---|---|---|---|")
        for spec, data in simple_ops:
            op = spec["op"]
            req_payload = data["request"].get("payload", {})
            payload_str = json.dumps(req_payload, separators=(",", ":")) if req_payload else "—"
            resp_val = data["response"].get("value", {})
            resp_str = json.dumps(resp_val, separators=(",", ":"))
            if len(resp_str) > 120:
                resp_str = resp_str[:100] + "…"
            lines.append(f"| `{op}` | {spec.get('auth','none')} | `{payload_str}` | `{resp_str}` |")
        lines.append("")

    # Full examples for complex ops
    if complex_ops:
        lines.append("## Complex operations")
        lines.append("")
        for spec, data in complex_ops:
            op = spec["op"]
            lines.append(f"### `{op}`")
            lines.append("")
            lines.append(spec.get("description", ""))
            lines.append("")
            lines.append(f"**Payload:**")
            lines.append("```json")
            lines.append(compact_req(data["request"]))
            lines.append("```")
            lines.append("")
            lines.append(f"**Response value:**")
            lines.append("```json")
            lines.append(compact_resp(data["response"]))
            lines.append("```")
            lines.append("")

    return "\n".join(lines)


async def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--server", default="ws://127.0.0.1:8080")
    ap.add_argument("--output", default="docs/wire.md")
    args = ap.parse_args()

    print(f"Connecting to {args.server}...")
    results = await connect_and_capture(args.server)

    md = generate_markdown(results)

    with open(args.output, "w") as f:
        f.write(md)
    print(f"Generated {args.output} with {len(results)} operations")
    print(f"Operations: {', '.join(results.keys())}")


if __name__ == "__main__":
    asyncio.run(main())
