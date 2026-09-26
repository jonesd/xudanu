#!/bin/bash
# release-notes.sh — generate release notes for a tag range.
#
# Usage: ./scripts/release-notes.sh v1.14.3..v1.14.4
#   or:  ./scripts/release-notes.sh v1.14.0 v1.14.4
#
# Output: grouped changelog from git log + content-set manifest diff
# + the three guarantees header. Paste into the GitHub release body
# alongside the auto-generated notes.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

RANGE="${1:-}"
if [ -z "$RANGE" ]; then
  echo "Usage: $0 <vA..vB> (or <vA> <vB>)" >&2
  exit 1
fi
if [[ "$RANGE" != *..* ]] && [ -n "${2:-}" ]; then
  RANGE="${RANGE}..${2}"
fi

echo "## Release ${RANGE#*..}"
echo ""
echo "### The Three Guarantees"
echo ""
echo "1. **Engine releases never touch the docuverse** — your data directory is never modified"
echo "2. **Seeded content becomes yours** — upgrades never re-seed; newer examples via \`restore_examples\`"
echo "3. **Confirm-before-touch** — anything that can modify works asks first, defaults to skip-if-modified"
echo ""

echo "### Changes"
echo ""
# Group commits by conventional-commit type
git log --oneline --format="%s" "$RANGE" | while read -r subject; do
  type="${subject%%:*}"
  rest="${subject#*: }"
  case "$type" in
    feat)    echo "- **feat**: $rest" ;;
    fix)     echo "- **fix**: $rest" ;;
    docs)    echo "- **docs**: $rest" ;;
    chore)   echo "- chore: $rest" ;;
    style)   echo "- style: $rest" ;;
    test)    echo "- test: $rest" ;;
    *)       echo "- $subject" ;;
  esac
done

echo ""
echo "### Content-Set Diff"
echo ""
# Compare manifest.json at both tags
OLD_TAG="${RANGE%%..*}"
NEW_TAG="${RANGE#*..}"
OLD_MANIFEST=$(git show "$OLD_TAG:content/sets/manifest.json" 2>/dev/null || echo "{}")
NEW_MANIFEST=$(git show "$NEW_TAG:content/sets/manifest.json" 2>/dev/null || echo "{}")

CORE_OLD=$(echo "$OLD_MANIFEST" | python3 -c "import json,sys; print(json.load(sys.stdin).get('core',{}).get('version','—'))" 2>/dev/null || echo "—")
CORE_NEW=$(echo "$NEW_MANIFEST" | python3 -c "import json,sys; print(json.load(sys.stdin).get('core',{}).get('version','—'))" 2>/dev/null || echo "—")
if [ "$CORE_OLD" != "$CORE_NEW" ]; then
  echo "- Core set: v$CORE_OLD → v$CORE_NEW"
else
  echo "- Core set: v$CORE_NEW (unchanged)"
fi

python3 -c "
import json, sys
old = json.loads('''$OLD_MANIFEST''').get('sets', [])
new = json.loads('''$NEW_MANIFEST''').get('sets', [])
old_map = {s['name']: s['version'] for s in old}
new_map = {s['name']: s['version'] for s in new}
for name in sorted(set(old_map) | set(new_map)):
    ov, nv = old_map.get(name), new_map.get(name)
    if ov is None:
        print(f'- **+{name} v{nv}** (new)')
    elif nv is None:
        print(f'- **−{name}** (removed)')
    elif ov != nv:
        print(f'- **{name} v{ov}→v{nv}**')
" 2>/dev/null || echo "(no manifest diff available — content/sets/manifest.json may be new)"

echo ""
echo "### Verification"
echo ""
echo '```'
echo "curl -s https://your-server/health"
echo "curl -s https://your-server/api/public/tumbler/vectors"
echo '```'
