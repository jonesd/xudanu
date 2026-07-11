#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/target/release/xudanu-cli"
SERVER="${1:-127.0.0.1:8080}"

echo "==> Seeding demo content on $SERVER..."

$CLI "$SERVER" login 2>/dev/null
CLUB=$($CLI "$SERVER" club-create "Demo User" 2>/dev/null)
$CLI "$SERVER" login 2>/dev/null

echo "==> Creating source works..."

STATUTE=$($CLI "$SERVER" create-work "All persons shall have the right to privacy in their personal communications. This right shall not be infringed without due process of law. The protection of privacy extends to digital communications, including but not limited to electronic mail, messaging, and online transactions. Any surveillance of private communications must be authorized by a warrant, supported by probable cause, and narrowly tailored to achieve a legitimate government interest." 2>/dev/null | head -1)
echo "  Statute: $STATUTE"

CASELAW=$($CLI "$SERVER" create-work "The court held that privacy extends to digital communications. In a landmark decision, the justices ruled that government surveillance of electronic communications requires a warrant. The decision established that citizens have a reasonable expectation of privacy in their digital data. This expectation covers not only the content of communications but also metadata, location data, and browsing history." 2>/dev/null | head -1)
echo "  Case Law: $CASELAW"

DISSENT=$($CLI "$SERVER" create-work "Privacy is not absolute where national security is concerned. The fundamental tension between individual liberty and collective safety requires careful balancing. In times of crisis, limited and targeted surveillance may be justified. The key question is not whether surveillance should exist, but what safeguards and oversight mechanisms should accompany it." 2>/dev/null | head -1)
echo "  Dissent: $DISSENT"

BRIEF=$($CLI "$SERVER" create-work "Legal Brief: Privacy Rights in Digital Communications

Introduction

This brief examines the tension between privacy rights and national security in the digital age. We argue that the right to privacy is fundamental.

The Statutory Framework

The statute establishes that all persons shall have the right to privacy in their personal communications. However, this right is not absolute.

Judicial Interpretation

The court held that privacy extends to digital communications, establishing a strong precedent. However, the dissent raises concerns about national security.

Conclusion

We maintain that privacy is a human right that must be protected against any backdoor." 2>/dev/null | head -1)
echo "  Legal Brief: $BRIEF"

WELCOME=$($CLI "$SERVER" create-work "Welcome to Xudanu

A connected literature where every quotation maintains its bond to the original.

This document contains live examples you can interact with right now. Try hovering the coloured underlines below, then try the features described.

LINKS YOU CAN HOVER NOW

The five lines below each have a different typed link. Hover each one to see the tooltip:

Line 1 has a Comment link (blue dashed).
Line 2 has a Reference link (green solid).
Line 3 has a Disagreement link (red long dash).
Line 4 has a Quotation link (purple dotted).
Line 5 has a See Also link (amber dash-dot).

Each link connects this passage to one of the source documents in the library. Click a link to navigate. Double-click to see connections.

TRACE PROVENANCE

If you open the Legal Brief document, you will see coloured transclusion markers (bars on the left margin). Hover any marker and click Trace provenance to see the recursive chain back to the original author. This is Gold's signature feature.

ATTRIBUTION

Click Show Prov in the top toolbar. You will see colour-coded backgrounds showing who wrote each section. Green means human-authored. This is court-grade attribution with Ed25519 signatures.

GETTING STARTED

1. Click Browse Library to see all documents
2. Open any document to explore
3. Toggle Write in the top bar to start editing
4. Select text and click Link to create your own connections
5. Select text and click Transclude to quote from another document

Xudanu implements Ted Nelson's 1960 vision: a docuverse where content is connected, not copied. Where every quotation traces back to its source. Where links are bidirectional and permanent." 2>/dev/null | head -1)
echo "  Welcome: $WELCOME"

echo ""
echo "==> Creating typed links..."

# Links FROM the Welcome document so markers show up in it
# Comment link on welcome (type 1)
$CLI "$SERVER" create-link "$WELCOME" "$STATUTE" 1 2>/dev/null
echo "  Welcome -Comment-> Statute"

# Reference link (type 2)
$CLI "$SERVER" create-link "$WELCOME" "$CASELAW" 2 2>/dev/null
echo "  Welcome -Reference-> Case Law"

# Disagreement link (type 3)
$CLI "$SERVER" create-link "$WELCOME" "$DISSENT" 3 2>/dev/null
echo "  Welcome -Disagreement-> Dissent"

# Quotation link (type 4)
$CLI "$SERVER" create-link "$WELCOME" "$BRIEF" 4 2>/dev/null
echo "  Welcome -Quotation-> Brief"

# See Also link (type 5)
$CLI "$SERVER" create-link "$WELCOME" "$STATUTE" 5 2>/dev/null
echo "  Welcome -SeeAlso-> Statute"

# Links between source documents
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
echo "==> Demo content created!"
echo "    Open http://localhost:8080"
echo "    Start with 'Welcome to Xudanu' — it has live link markers you can hover."
