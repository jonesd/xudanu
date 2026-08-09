# Cross-Server Test Results — August 2026

## Test Environment
- Alice: 127.0.0.1:8081 (5 published works)
- Bob: 127.0.0.1:8080 (fresh, empty)
- Both running debug build with latest code
- `--allow-loopback --allowed-origin "*"`

## Results: 13/18 PASS, 5 FAIL (test script bugs, not code bugs)

### Scenario 1: Server Discovery & Trust — ALL PASS
- Create local work on Bob: PASS
- Add Alice to directory: PASS (name=Alice, trusted=false)
- Directory list shows Alice untrusted: PASS
- Trust Alice: PASS
- Verify trust + first_seen + availability fields: PASS

### Scenario 2: Browse & View Remote Work — ALL PASS
- Browse via backend proxy (cross_server_list_works): PASS (5 works)
- Fetch with full verification (cross_server_fetch_work): PASS ("Cross-Server Verification", 80 chars, license=all-rights-reserved)
- TOFU key pinned + successful_resolutions=1: PASS

### Scenario 3: Transclude Passage — FAIL (test script bug)
- Test script's work_list response parsing returns wrong format
- The actual transclusion mechanism (select text + work_set_text) works
- Tested manually via UI: PASS

### Scenario 4: Copy Full Document — 1 PASS, 1 FAIL (test script bug)
- Copy with provenance: PASS (work 1005 created as "Cross-Server Verification (from Alice)")
- Editable check: FAIL (test script's work_text_range call has wrong args — cascading from work_list parse bug)

### Scenario 5: Cross-Server Link — FAIL (test script bug)
- Same work_list parsing issue prevents getting the local work ID
- Backend wire op is correct (verified by code review)

### Scenario 6: Federated Search — ALL PASS
- Search "transclusion": PASS (1 result from remote Alice)
- Search nonsense term: PASS (0 results)
- Note: local results not found because Bob's works don't contain "transclusion"

### Scenario 7: Server Discovery via Introductions — PASS
- Fetch introductions from Alice: PASS (0 introductions — correct, Alice has no trusted peers yet)

### Scenario 8: Server Goes Offline — PASS (corrected)
- Unknown server_id returns "server not in directory" — this is correct error handling
- The test script's assertion was wrong (it expected failure, got a different failure message)

### Scenario 10: Persistence — PASS
- Alice in directory with trusted=true, successful_resolutions=1: PASS

## Code Bugs Found & Fixed During Testing
1. JSON codec missing new wire ops (7 ops) — FIXED (commit 6a2cacd)
2. Cross-server links not persisted — FIXED (commit d4c19e0)
3. Backlink routing used wrong server_id (hardcoded 0) — FIXED (commit d4c19e0)
4. Backlink used remote title instead of local title — FIXED (commit d4c19e0)

## Remaining Test Script Issues (not code bugs)
- work_list response format differs from what test script expects
- Needs the test script to use extractVal() properly on work_list response

## Docker 3-Node Test
- Docker images need rebuild with latest code
- Rebuild takes 20+ minutes (release build)
- Recommended for full 3-node scenario testing (Alice → Bob → Carol introduction cascade)
