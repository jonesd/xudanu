#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/target/release/xudanu-cli"
SERVER="${1:-127.0.0.1:8080}"

echo "==> Seeding demo content on $SERVER..."

$CLI "$SERVER" login 2>/dev/null

echo "==> Creating source works..."

STATUTE=$($CLI "$SERVER" create-work "All persons shall have the right to privacy in their personal communications. This right shall not be infringed without due process of law. The protection of privacy extends to digital communications, including but not limited to electronic mail, messaging, and online transactions." 2>/dev/null | head -1)
echo "  Statute: $STATUTE (0x$(printf '%04x' "$STATUTE"))"

CASELAW=$($CLI "$SERVER" create-work "The court held that privacy extends to digital communications. In a landmark decision, the justices ruled that government surveillance of electronic communications requires a warrant. The decision established that citizens have a reasonable expectation of privacy in their digital data." 2>/dev/null | head -1)
echo "  Case Law: $CASELAW (0x$(printf '%04x' "$CASELAW"))"

DISSENT=$($CLI "$SERVER" create-work "Privacy is not absolute where national security is concerned. The fundamental tension between individual liberty and collective safety requires careful balancing. In times of crisis, limited and targeted surveillance may be justified." 2>/dev/null | head -1)
echo "  Dissent: $DISSENT (0x$(printf '%04x' "$DISSENT"))"

WELCOME=$($CLI "$SERVER" create-work "Welcome to Xudanu

A connected literature where every quotation maintains its bond to the original, where every reuse carries its full provenance.

This workspace demonstrates the key features of Xudanu.

FEATURES TO EXPLORE:

1. TYPED LINKS - Five link types with distinct colours: Comment (blue), Reference (green), Disagreement (red), Quotation (purple), See Also (amber). Open the Legal Brief to see links to the source documents. Hover the coloured underlines to see what they connect to.

2. TRACE PROVENANCE - Hover any link marker and click 'Trace provenance'. You will see the recursive chain back to the original author.

3. ATTRIBUTION - Click 'Show Prov' in the toolbar to see who wrote each section. Green = human, amber = historical. Every edit is Ed25519-signed.

4. SPAN MIGRATION - Links survive edits. Edit text near a linked passage and the marker follows the text.

5. CROSS-SERVER - This server can link to content on other Xudanu servers via tumblers.

6. COLLABORATIVE EDITING - Multiple users can edit simultaneously. The O-tree CRDT merges without conflicts.

Explore. Edit. Create links. Welcome to the docuverse." 2>/dev/null | head -1)
echo "  Welcome: $WELCOME (0x$(printf '%04x' "$WELCOME"))"

BRIEF=$($CLI "$SERVER" create-work "Legal Brief: Privacy Rights in Digital Communications

Introduction

This brief examines the tension between privacy rights and national security in the digital age. We argue that the right to privacy is fundamental.

The Statutory Framework

All persons shall have the right to privacy in their personal communications.

This right is not absolute, however. Critics argue that privacy must be balanced against security concerns.

Judicial Interpretation

The court held that privacy extends to digital communications. This establishes a strong precedent for digital privacy rights.

However, the dissent raises valid concerns. Privacy is not absolute where national security is concerned.

Conclusion

We maintain that privacy is a human right that must be protected." 2>/dev/null | head -1)
echo "  Legal Brief: $BRIEF (0x$(printf '%04x' "$BRIEF"))"

echo ""
echo "==> Creating typed links..."
echo "  Types: 1=Comment 2=Reference 3=Disagreement 4=Quotation 5=SeeAlso"

$CLI "$SERVER" create-link "$STATUTE" "$CASELAW" 2 2>/dev/null
echo "  Statute -Reference-> Case Law"

$CLI "$SERVER" create-link "$BRIEF" "$STATUTE" 2 2>/dev/null
echo "  Brief -Reference-> Statute"

$CLI "$SERVER" create-link "$BRIEF" "$DISSENT" 3 2>/dev/null
echo "  Brief -Disagreement-> Dissent"

$CLI "$SERVER" create-link "$BRIEF" "$CASELAW" 4 2>/dev/null
echo "  Brief -Quotation-> Case Law"

$CLI "$SERVER" create-link "$DISSENT" "$CASELAW" 5 2>/dev/null
echo "  Dissent -SeeAlso-> Case Law"

echo ""
echo "==> Publishing all works..."
for id in "$STATUTE" "$CASELAW" "$DISSENT" "$BRIEF" "$WELCOME"; do
  $CLI "$SERVER" publish "$id" 2>/dev/null
done

echo ""
echo "==> Demo content created successfully!"
echo ""
echo "Works:"
$CLI "$SERVER" list-works 2>/dev/null
echo ""
echo "==> Open http://localhost:8080 in your browser to explore."
echo "    Start with the 'Welcome to Xudanu' document."
