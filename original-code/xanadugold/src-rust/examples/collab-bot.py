#!/usr/bin/env python3
"""Automated collaborative editing bot for xudanu.

Connects to a running xudanu server, creates (or opens) a document,
and periodically appends text lines. Run alongside the web UI to
test real-time collaborative editing.

Usage:
    python3 collab-bot.py [--url WS_URL] [--doc WORK_ID] [--interval SECONDS]

Examples:
    # Start server in one terminal:
    cargo run --features server --bin xudanu-server -- run

    # Start bot in another terminal (creates a new doc):
    python3 collab-bot.py

    # Or attach to an existing doc:
    python3 collab-bot.py --doc 1

    # Then open http://localhost:8080 in your browser and edit the same doc.
"""

import asyncio
import json
import sys
import time
import argparse
try:
    import websockets
except ImportError:
    print("Install websockets: pip install websockets")
    sys.exit(1)

class XudanuClient:
    def __init__(self, url):
        self.url = url
        self.ws = None
        self.next_id = 1
        self.works = []
        self.session_id = None

    async def connect(self):
        self.ws = await websockets.connect(self.url)
        msg = await self.ws.recv()
        hs = json.loads(msg)
        assert hs.get("type") == "handshake", f"Expected handshake, got: {hs}"
        print(f"Connected to {self.url} (server: {hs.get('server_id', 'unknown')})")

    async def req(self, op, payload=None):
        frame = {"v": 2, "type": "request", "id": self.next_id, "op": op}
        if payload is not None:
            frame["payload"] = payload
        self.next_id += 1
        await self.ws.send(json.dumps(frame))
        while True:
            resp = json.loads(await self.ws.recv())
            if resp.get("type") == "response" and resp.get("id") == frame["id"] - 1:
                return resp
            if resp.get("type") == "error":
                return resp
            if resp.get("type") == "event":
                continue

    async def subscribe(self, det_type, target_id):
        frame = {
            "v": 2, "type": "subscribe", "id": self.next_id,
            "payload": {"detector_type": det_type, "target_id": target_id}
        }
        self.next_id += 1
        await self.ws.send(json.dumps(frame))
        while True:
            resp = json.loads(await self.ws.recv())
            if resp.get("type") == "response":
                return resp

    async def setup(self):
        resp = await self.req("session_connect")
        self.session_id = resp["value"]["value"]
        await self.req("session_login_public")
        print(f"Session: {self.session_id}")

    async def create_doc(self, text=""):
        resp = await self.req("work_create", {"edition": {"text": text}})
        work_id = resp["value"]["value"]
        print(f"Created document: {work_id}")
        return work_id

    async def list_works(self):
        resp = await self.req("work_list")
        self.works = resp["value"]["value"]
        return self.works

    async def get_edition(self, work_id):
        resp = await self.req("work_get_edition", {"work_id": work_id})
        ed = resp["value"]["value"]
        if ed.get("text") is not None:
            return ed["text"]
        if ed.get("entries"):
            return "".join(e[1].get("Text", {}).get("text", "") for e in ed["entries"])
        return ""

    async def grab(self, work_id):
        return await self.req("work_grab", {"work_id": work_id})

    async def release(self, work_id):
        return await self.req("work_release", {"work_id": work_id})

    async def revise(self, work_id, text):
        return await self.req("work_revise", {"work_id": work_id, "edition": {"text": text}})

    async def revise_delta(self, work_id, base_rev, old_text, new_text):
        ops = compute_delta(old_text, new_text)
        if not ops:
            return None
        return await self.req("work_revise_delta", {
            "work_id": work_id, "base_revision": base_rev, "ops": ops
        })


def compute_delta(old_text, new_text):
    ops = []
    oi, ni = 0, 0
    ol, nl = len(old_text), len(new_text)
    while oi < ol or ni < nl:
        common = 0
        max_c = min(ol - oi, nl - ni)
        while common < max_c and old_text[oi + common] == new_text[ni + common]:
            common += 1
        if common > 0:
            ops.append({"type": "retain", "count": common})
            oi += common
            ni += common
        delete_len = 0
        while oi + delete_len < ol and (ni >= nl or old_text[oi + delete_len] != new_text[ni]):
            delete_len += 1
        if delete_len > 0:
            ops.append({"type": "delete", "count": delete_len})
            oi += delete_len
        insert_len = 0
        while ni + insert_len < nl and (oi >= ol or old_text[oi] != new_text[ni + insert_len]):
            insert_len += 1
        if insert_len > 0:
            ops.append({"type": "insert", "text": new_text[ni:ni + insert_len]})
            ni += insert_len
    return ops


async def bot(url, doc_id, interval):
    client = XudanuClient(url)
    await client.connect()
    await client.setup()

    if doc_id is not None:
        work_id = doc_id
        works = await client.list_works()
        found = [w for w in works if w["work_id"] == work_id]
        if not found:
            print(f"Document {work_id} not found. Available: {[w['work_id'] for w in works]}")
            return
    else:
        work_id = await client.create_doc("Collaborative editing demo!\n\n")
        await client.subscribe("revision", work_id)
        await client.subscribe("status", work_id)

    current_text = await client.get_edition(work_id)
    rev = 1
    print(f"\nDocument {work_id} current text: {current_text!r}")
    print(f"\nOpen http://localhost:8080 in your browser and edit document {work_id}")
    print(f"Bot will append a line every {interval}s. Press Ctrl+C to stop.\n")

    line_num = 1
    try:
        while True:
            await asyncio.sleep(interval)
            await client.grab(work_id)
            try:
                fresh = await client.get_edition(work_id)
                if fresh != current_text:
                    print(f"  [bot] document changed by someone else, re-syncing")
                    current_text = fresh

                line = f"Bot line {line_num} at {time.strftime('%H:%M:%S')}\n"
                new_text = current_text + line

                resp = await client.revise_delta(work_id, rev, current_text, new_text)
                if resp and resp.get("value", {}).get("type") == "humber":
                    rev = resp["value"]["value"]
                    current_text = new_text
                    print(f"  [bot] appended line {line_num} (rev {rev})")
                elif resp and resp.get("value", {}).get("type") == "edition":
                    conflict_text = resp["value"]["value"].get("text", "")
                    print(f"  [bot] conflict! Server has: {conflict_text!r}")
                    current_text = conflict_text
                else:
                    print(f"  [bot] unexpected response: {resp}")
            finally:
                await client.release(work_id)
            line_num += 1
    except KeyboardInterrupt:
        print(f"\nBot stopped after {line_num - 1} edits.")


def main():
    parser = argparse.ArgumentParser(description="xudanu collaborative editing bot")
    parser.add_argument("--url", default="ws://127.0.0.1:8080/xudanu?format=json&version=2")
    parser.add_argument("--doc", type=int, default=None, help="Work ID to edit (creates new if omitted)")
    parser.add_argument("--interval", type=float, default=3.0, help="Seconds between edits")
    args = parser.parse_args()

    asyncio.run(bot(args.url, args.doc, args.interval))


if __name__ == "__main__":
    main()
