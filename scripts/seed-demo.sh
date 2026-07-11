#!/usr/bin/env bash
set -euo pipefail

# seed-demo.sh — Populate a fresh Xudanu server with demo content
# showing the full feature set: transclusions, typed links,
# provenance, compound documents.
#
# Usage: ./scripts/seed-demo.sh [server-url]
# Default: ws://127.0.0.1:8080/xudanu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/target/release/xudanu-cli"
SERVER="${1:-ws://127.0.0.1:8080/xudanu}"

echo "==> Seeding demo content on $SERVER..."

$CLI "$SERVER" login 2>/dev/null

echo "==> Creating source works..."

STATUTE=$($CLI "$SERVER" create-work "All persons shall have the right to privacy in their personal communications. This right shall not be infringed without due process of law. The protection of privacy extends to digital communications, including but not limited to electronic mail, messaging, and online transactions." 2>/dev/null | grep -o '0x[0-9a-f]*' | head -1 | cut -dx -f2)
echo "  Statute: 0x$STATUTE"

CASELAW=$($CLI "$SERVER" create-work "The court held that privacy extends to digital communications. In a landmark decision, the justices ruled that government surveillance of electronic communications requires a warrant. The decision established that citizens have a reasonable expectation of privacy in their digital data." 2>/dev/null | grep -o '0x[0-9a-f]*' | head -1 | cut -dx -f2)
echo "  Case Law: 0x$CASELAW"

DISSENT=$($CLI "$SERVER" create-work "Privacy is not absolute where national security is concerned. The fundamental tension between individual liberty and collective safety requires careful balancing. In times of crisis, limited and targeted surveillance may be justified." 2>/dev/null | grep -o '0x[0-9a-f]*' | head -1 | cut -dx -f2)
echo "  Dissent: 0x$DISSENT"

WELCOME=$($CLI "$SERVER" create-work "Welcome to Xudanu — a connected literature where every quotation maintains its bond to the original, where every reuse carries its full provenance.

This workspace demonstrates the key features of Xudanu, the modern implementation of Ted Nelson's Xanadu vision.

FEATURES TO EXPLORE:

1. COMPOUND DOCUMENTS — Open the 'Legal Brief' to see a document assembled from pieces of the Statute, Case Law, and Dissent. Each transclusion is colour-coded by source. Hover the coloured bars to see where each piece came from.

2. TRACE PROVENANCE (again chain) — Hover any transclusion marker and click 'Trace provenance'. You'll see the recursive chain: this document, then the source, then the original author. This is Gold's signature feature — the recursive transclusion walk.

3. TYPED LINKS — Five link types with distinct colours: Comment (blue), Reference (green), Disagreement (red), Quotation (purple), See Also (amber). Links are bidirectional — the target work automatically sees the incoming reference.

4. ATTRIBUTION — Click 'Show Prov' to see who wrote each section. Green = human, amber = historical/imported, red dashed = unsigned. Every edit is Ed25519-signed.

5. SPAN MIGRATION — Links and transclusions survive edits. If you edit text near a linked passage, the link marker follows the text, not the position.

6. CROSS-SERVER — This server can link to content on other Xudanu servers via tumblers (global addresses). See the Xanadu Network Guide for details.

7. COLLABORATIVE EDITING — Multiple users can edit the same document simultaneously. The O-tree CRDT merges changes without conflicts.

THE XANADU VISION:

Ted Nelson envisioned this in 1960: a docuverse where content is connected, not copied. Where every quotation traces back to its source. Where links are bidirectional and permanent.

Xudanu makes this vision real with modern technology: Rust backend, React frontend, BLAKE3 content addressing, Ed25519 signed attribution, and the O-tree CRDT for collaborative editing.

Explore. Edit. Create links. Build your own compound documents. Welcome to the docuverse." 2>/dev/null | grep -o '0x[0-9a-f]*' | head -1 | cut -dx -f2)
echo "  Welcome: 0x$WELCOME"

BRIEF=$($CLI "$SERVER" create-work "Legal Brief: Privacy Rights in Digital Communications

Introduction

This brief examines the tension between privacy rights and national security in the digital age. We argue that the right to privacy is fundamental and must be protected.

The Statutory Framework

All persons shall have the right to privacy in their personal communications.

This right is not absolute, however. Critics argue that privacy must be balanced against security concerns.

Judicial Interpretation

The court held that privacy extends to digital communications. This establishes a strong precedent for digital privacy rights.

However, the dissent raises valid concerns. Privacy is not absolute where national security is concerned.

Conclusion

We maintain that privacy is a human right that must be protected. The statutory framework, judicial interpretation, and practical considerations all support robust privacy protections in the digital age." 2>/dev/null | grep -o '0x[0-9a-f]*' | head -1 | cut -dx -f2)
echo "  Legal Brief: 0x$BRIEF"

echo "==> Creating typed links..."
echo "  Types: 1=Comment 2=Reference 3=Disagreement 4=Quotation 5=SeeAlso"

# Brief references the Statute (type 2 = Reference)
$CLI "$SERVER" create-link 0x$BRIEF 0x$STATUTE 2 2>/dev/null
echo "  Brief -Reference-> Statute"

# Brief disagrees with the Dissent (type 3 = Disagreement)
$CLI "$SERVER" create-link 0x$BRIEF 0x$DISSENT 3 2>/dev/null
echo "  Brief -Disagreement-> Dissent"

# Brief quotes the Case Law (type 4 = Quotation)
$CLI "$SERVER" create-link 0x$BRIEF 0x$CASELAW 4 2>/dev/null
echo "  Brief -Quotation-> Case Law"

# Statute is referenced by Case Law (type 2 = Reference)
$CLI "$SERVER" create-link 0x$STATUTE 0x$CASELAW 2 2>/dev/null
echo "  Statute -Reference-> Case Law"

# See Also link between Dissent and Case Law (type 5)
$CLI "$SERVER" create-link 0x$DISSENT 0x$CASELAW 5 2>/dev/null
echo "  Dissent -SeeAlso-> Case Law"

# Comment on the Dissent from the Brief (type 1)
$CLI "$SERVER" create-link 0x$BRIEF 0x$DISSENT 1 2>/dev/null
echo "  Brief -Comment-> Dissent"

echo ""
echo "==> Publishing all works..."
$CLI "$SERVER" publish 0x$STATUTE 2>/dev/null
$CLI "$SERVER" publish 0x$CASELAW 2>/dev/null
$CLI "$SERVER" publish 0x$DISSENT 2>/dev/null
$CLI "$SERVER" publish 0x$BRIEF 2>/dev/null
$CLI "$SERVER" publish 0x$WELCOME 2>/dev/null

echo ""
echo "==> Demo content created successfully!"
echo ""
echo "Works created:"
$CLI "$SERVER" list-works 2>/dev/null
echo ""
echo "==> Open http://localhost:8080 in your browser to explore."
echo "    Start with the 'Welcome to Xudanu' document."
echo ""
echo "==> To try cross-server features, start a second server:"
echo "    ./scripts/test-network.sh"
