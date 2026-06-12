#!/usr/bin/env python3
"""Seed xudanu server with rich test data.

Populates:
  - 3 user accounts (alice, bob, carol)
  - Multiple works with multi-revision histories
  - Transclusion links between works
  - Endorsements
  - Source works with historical authors

Usage:
  # Start server first: ./scripts/single.sh 8080 ./data
  python3 scripts/seed.py
  python3 scripts/seed.py ws://localhost:9090/xudanu
"""

import json
import sys
import time
import urllib.request
import websocket  # pip install websocket-client

BASE_HOST = "127.0.0.1:8080"
if len(sys.argv) > 1:
    BASE_HOST = sys.argv[1].replace("ws://", "").replace("http://", "").replace("/xudanu", "").split("?")[0]

BASE_WS = f"ws://{BASE_HOST}/xudanu?format=json&version=2"


def make_ws():
    try:
        csrf_resp = urllib.request.urlopen(f"http://{BASE_HOST}/csrf-token")
        csrf_data = json.loads(csrf_resp.read())
        csrf = csrf_data.get("csrf_token", "")
        url = f"{BASE_WS}&csrf_token={csrf}"
    except Exception:
        url = BASE_WS
    return websocket.create_connection(url, timeout=10)


ws = make_ws()


class Client:
    def __init__(self, ws):
        self.ws = ws
        self.req_id = 1
        self.session_id = None

    def req(self, op, payload=None):
        fid = self.req_id
        self.req_id += 1
        frame = {"v": 2, "type": "request", "id": fid, "op": op}
        if payload is not None:
            frame["payload"] = payload
        self.ws.send(json.dumps(frame))
        while True:
            raw = json.loads(self.ws.recv())
            if raw.get("type") == "handshake":
                continue
            if raw.get("type") == "error" and raw.get("id") == 0:
                print(f"  (protocol error, retrying {op})")
                continue
            if raw.get("id") == fid:
                if raw.get("type") == "error":
                    raise Exception(f"{op}: {raw.get('message', raw.get('code', raw))}")
                return raw.get("value")
            if raw.get("type") == "event":
                continue

    def connect(self):
        v = self.req("session_connect")
        self.session_id = v["value"] if isinstance(v, dict) else v

    def login_public(self):
        self.req("session_login_public")

    def create_identity(self, name, password):
        pw_bytes = list(password.encode("utf-8"))
        try:
            v = self.req("club_create_personal", {
                "display_name": name,
                "password": pw_bytes,
            })
            club_id = v["value"] if isinstance(v, dict) else v
        except Exception:
            self.req("session_login_by_name", {"club_name": name})
            v = self.req("session_authenticate", {
                "credential": {"password": pw_bytes},
            })
            club_id = v["value"] if isinstance(v, dict) else v
            print(f"  (reusing existing identity: {name})")
            self._club_id = club_id
            return club_id
        self.req("session_login_by_name", {"club_name": name})
        self.req("session_authenticate", {
            "credential": {"password": pw_bytes},
        })
        return club_id

    def create_work(self, text):
        v = self.req("work_create", {"edition": {"text": text}})
        return v["value"] if isinstance(v, dict) else v

    def grab(self, work_id):
        self.req("work_grab", {"work_id": work_id})

    def revise(self, work_id, text):
        self.req("work_revise", {"work_id": work_id, "edition": {"text": text}})

    def release(self, work_id):
        self.req("work_release", {"work_id": work_id})

    def create_link(self, origin, dest, excerpt=None):
        payload = {"origin": origin, "destination": dest}
        if excerpt:
            payload["origin_ref"] = {
                "kind": "single",
                "work_context": origin,
                "original_context": None,
                "excerpt": excerpt,
            }
        v = self.req("link_create", payload)
        return v["value"] if isinstance(v, dict) else v

    def endorse(self, work_id):
        self.req("work_endorse", {
            "work_id": work_id,
            "endorsements": [[self._club_id, 1]],
        })

    def list_works(self):
        v = self.req("work_list")
        if isinstance(v, dict):
            if "entries" in v:
                return v["entries"]
            if "value" in v:
                return v["value"]
        if isinstance(v, list):
            return v
        return []

    def publish(self, work_id, public_club):
        self.req("work_set_read_club", {"work_id": work_id, "club_id": public_club})
        self.req("work_set_edit_club", {"work_id": work_id, "club_id": public_club})

    _club_id = 0


print(f"Connecting to {BASE_WS}...")
c = Client(ws)
c.connect()
print(f"  Session: {c.session_id}")

# --- Create accounts ---
print("\nCreating accounts...")
c.login_public()
v = c.req("server_stats")
public_club = v.get("value", {}).get("public_club_id", 0) if isinstance(v, dict) else 0

# Alice
alice = Client(make_ws())
alice.connect()
alice.login_public()
alice_id = alice.create_identity("alice", "password123")
alice._club_id = alice_id
print(f"  alice: club {alice_id}")

# Bob
bob = Client(make_ws())
bob.connect()
bob.login_public()
bob_id = bob.create_identity("bob", "password456")
bob._club_id = bob_id
print(f"  bob: club {bob_id}")

# Carol
carol = Client(make_ws())
carol.connect()
carol.login_public()
carol_id = carol.create_identity("carol", "password789")
carol._club_id = carol_id
print(f"  carol: club {carol_id}")

# --- Alice creates original essay with multiple revisions ---
print("\n--- Alice: Original Essay ---")
essay = alice.create_work(
    "Introduction to Xanadu\n\n"
    "The Xanadu project was conceived by Ted Nelson in 1960.\n"
    "It represents one of the oldest hypertext systems.\n\n"
    "Core Concepts\n\n"
    "Transclusion is the practice of including content from one document "
    "into another by reference, not by copy.\n"
    "This preserves provenance and attribution.\n"
)
print(f"  Created essay: {essay:#x}")
alice.publish(essay, public_club)

alice.grab(essay)
alice.revise(
    essay,
    "Introduction to Xanadu\n\n"
    "The Xanadu project was conceived by Ted Nelson in 1960.\n"
    "It represents one of the oldest and most ambitious hypertext systems.\n\n"
    "Core Concepts\n\n"
    "Transclusion is the practice of including content from one document "
    "into another by reference, not by copy.\n"
    "This preserves provenance, attribution, and authorship.\n\n"
    "Versioning\n\n"
    "Every edit creates a new version. The version DAG tracks ancestry "
    "so you can see where content came from.\n"
)
alice.release(essay)
print(f"  Revised essay (v2): added versioning section")

time.sleep(0.3)
alice.grab(essay)
alice.revise(
    essay,
    "Introduction to Xanadu\n\n"
    "The Xanadu project was conceived by Ted Nelson in 1960.\n"
    "It represents one of the oldest and most ambitious hypertext systems ever proposed.\n\n"
    "Core Concepts\n\n"
    "Transclusion is the practice of including content from one document "
    "into another by reference, not by copy.\n"
    "This preserves provenance, attribution, and authorship across all derivative works.\n\n"
    "Versioning\n\n"
    "Every edit creates a new version tracked in a DAG (directed acyclic graph).\n"
    "The version DAG records full ancestry so you can trace where any content originated.\n\n"
    "Endorsement\n\n"
    "Works can be endorsed by readers, signaling quality or agreement.\n"
    "Endorsements accumulate as flags in the transclusion canopy.\n"
)
alice.release(essay)
print(f"  Revised essay (v3): expanded versioning, added endorsement section")

# --- Bob creates a derivative work with transclusions ---
print("\n--- Bob: Derivative Analysis ---")
analysis = bob.create_work(
    "Analysis of Transclusion Systems\n\n"
    "Transclusion is the practice of including content from one document "
    "into another by reference, not by copy.\n\n"
    "This essay examines how transclusion preserves authorship.\n"
    "The Xanadu project was conceived by Ted Nelson in 1960.\n\n"
    "Comparative Notes\n\n"
    "Modern systems like web links copy content implicitly.\n"
    "True transclusion maintains the link to the original.\n"
)
print(f"  Created analysis: {analysis:#x}")
bob.publish(analysis, public_club)

bob.grab(analysis)
bob.revise(
    analysis,
    "Analysis of Transclusion Systems\n\n"
    "Transclusion is the practice of including content from one document "
    "into another by reference, not by copy.\n"
    "This preserves provenance, attribution, and authorship across all derivative works.\n\n"
    "This essay examines how transclusion preserves authorship "
    "in collaborative environments.\n"
    "The Xanadu project was conceived by Ted Nelson in 1960.\n"
    "It represents the oldest and most ambitious hypertext system ever proposed.\n\n"
    "Comparative Notes\n\n"
    "Modern systems like web links copy content implicitly.\n"
    "True transclusion maintains the link to the original source.\n"
    "Every edit creates a new version tracked in a DAG.\n"
)
bob.release(analysis)
print(f"  Revised analysis (v2): more transcluded content from essay")

# --- Create transclusion links ---
print("\nCreating transclusion links...")
excerpt = "Transclusion is the practice of including content from one document into another by reference, not by copy."
link1 = bob.create_link(analysis, essay, excerpt)
print(f"  Link analysis -> essay: {link1:#x}")

excerpt2 = "The Xanadu project was conceived by Ted Nelson in 1960."
link2 = bob.create_link(analysis, essay, excerpt2)
print(f"  Link analysis -> essay: {link2:#x}")

# --- Carol creates a review ---
print("\n--- Carol: Review ---")
review = carol.create_work(
    "Review: Transclusion in Practice\n\n"
    "The Xanadu project was conceived by Ted Nelson in 1960.\n"
    "It represents the oldest and most ambitious hypertext system ever proposed.\n\n"
    "Assessment\n\n"
    "The concept of transclusion is powerful but under-adopted.\n"
    "Modern web platforms prefer copying over referencing.\n\n"
    "Rating: 4/5 stars. Loses one star for lack of implementation.\n"
)
print(f"  Created review: {review:#x}")
carol.publish(review, public_club)

carol.grab(review)
carol.revise(
    review,
    "Review: Transclusion in Practice (Updated)\n\n"
    "The Xanadu project was conceived by Ted Nelson in 1960.\n"
    "It represents the oldest and most ambitious hypertext system ever proposed.\n\n"
    "Assessment\n\n"
    "The concept of transclusion is powerful but historically under-adopted.\n"
    "Modern platforms prefer copying over referencing.\n"
    "New implementations like Xudanu are changing this.\n\n"
    "Rating: 5/5 stars. The DAG-based version tracking is excellent.\n"
)
carol.release(review)
print(f"  Revised review (v2): updated rating")

link3 = carol.create_link(review, essay, "The Xanadu project was conceived by Ted Nelson in 1960.")
link4 = carol.create_link(review, analysis, "Transclusion is the practice of including content")
print(f"  Links review -> essay, review -> analysis")

# --- Endorsements ---
print("\nAdding endorsements...")
for user, targets in [(alice, [analysis, review]), (bob, [essay, review]), (carol, [essay, analysis])]:
    for t in targets:
        try:
            user.endorse(t)
        except Exception as e:
            print(f"  (endorsement skipped: {e})")
print("  Endorsements done (some may have been skipped)")

# --- Alice creates a private draft ---
print("\n--- Alice: Private Draft ---")
draft = alice.create_work(
    "Draft: Future of Hypertext\n\n"
    "This is a work in progress about next-generation hypertext.\n"
    "Content includes speculative ideas about quantum linking.\n"
)
print(f"  Created private draft: {draft:#x}")
alice.grab(draft)
alice.revise(
    draft,
    "Draft: Future of Hypertext\n\n"
    "This is a work in progress about next-generation hypertext.\n"
    "Quantum entanglement could theoretically enable instant content synchronization.\n"
    "Blockchain-like structures might provide tamper-proof provenance.\n"
)
alice.release(draft)
print(f"  Revised draft (v2): added quantum and blockchain ideas")

# --- Carol creates a source work (for historical author simulation) ---
print("\n--- Carol: Notes on Hypertext History ---")
notes = carol.create_work(
    "Lecture Notes: History of Hypertext\n\n"
    "Vannevar Bush proposed the memex in 1945.\n"
    "Ted Nelson coined hypertext in 1963.\n"
    "Tim Berners-Lee created the World Wide Web in 1989.\n\n"
    "Key insight: linking by reference (transclusion) preserves "
    "the relationship between original and derivative works.\n"
)
print(f"  Created notes: {notes:#x}")
carol.publish(notes, public_club)
try:
    carol.endorse(notes)
except Exception:
    print("  (notes endorsement skipped)")

link5 = carol.create_link(notes, essay, "Ted Nelson")
print(f"  Link notes -> essay")

# --- Summary ---
print("\n" + "=" * 50)
print("Seed data created successfully!")
print("=" * 50)
print(f"""
Works created:
  1. Essay (alice, public, 3 revisions)     #{essay:#06x}
  2. Analysis (bob, public, 2 revisions)     #{analysis:#06x}
  3. Review (carol, public, 2 revisions)     #{review:#06x}
  4. Draft (alice, private, 2 revisions)     #{draft:#06x}
  5. Notes (carol, public, 1 revision)       #{notes:#06x}

Transclusion links: 5
Endorsements: 6 (2-3 per public work)

Try:
  - Open any work and click More -> Work Summary
  - Compare Essay vs Analysis (shared transcluded content)
  - Check attribution on the Analysis (bob's work)
  - Watch for transclusions on the Essay
""")

ws.close()
