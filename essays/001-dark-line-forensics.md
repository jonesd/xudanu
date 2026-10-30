# The test was green. It had never once done what it claimed.

A coverage percentage told us almost nothing. The dark lines told us
three things — including that one of our consensus tests had been
passing for the wrong reason since the day it was written.

The setting is a Rust server that runs PBFT-style governance over a
federated peer network — the kind of code where "it seems to work"
is not an acceptable test result, because the failure modes are
byzantine peers, view changes, and rounds that stall one vote short
of quorum. We keep a house rule from our bug catalog: **80% line
coverage is a floor, not a ceiling**, and we track per module rather
than trusting the project average. Last week that rule sent me
digging through the federation transport's numbers, and the digging
turned into a forensic exercise I now think more teams should run:
**bucket your uncovered lines by function and read the list like a
triage nurse, not a todo list.**

Here is what the dark lines found.

## 1. A test passing for the wrong reason

The unit test was named `governance_receive_pre_prepare_validates`,
and it looked thorough. It delivered a proposal, asserted acceptance,
then delivered mutations — wrong view, wrong sequence, non-leader
proposer — asserting `is_err()` on each:

```rust
assert!(gov.receive_pre_prepare(&proposal, &members).is_ok());

let mut bad = proposal.clone();
bad.view_number = 9;
assert!(gov.receive_pre_prepare(&bad, &members).is_err(),
    "wrong view rejected");

let mut bad = proposal.clone();
bad.proposer_id = "srv-b".to_string();
assert!(gov.receive_pre_prepare(&bad, &members).is_err(),
    "non-leader proposer rejected");
```

Green. Asserting exactly the right things. And here is the problem,
visible only in the coverage report: the first `is_ok()` call
**creates a pending round**. From that moment, every subsequent call
hits an earlier guard — `return Err("a round is already in
progress")` — and never reaches the view check or the leadership
check at all. The test's assertions were true. The code paths they
named were never executed. Coverage showed nine dark lines sitting
exactly on those two rejection arms, in a file otherwise lit green
by hundreds of tests.

The fix was to drive the rejections on a *fresh* replica with no
round in flight — and, more importantly, to make the oracle strong
enough that this class of mistake can't hide:

```rust
let err = gov.receive_pre_prepare(&mk(7, 1, "srv-a"), &members)
    .unwrap_err();
assert!(err.contains("does not match current view"), "{err}");
assert!(gov.pending_round().is_none(),
    "rejection creates no round");
```

`assert!(result.is_err())` accepts *any* failure reason. In a state
machine with a stack of guards, any earlier guard will satisfy it
forever. Assert the *reason*, and assert the state you expect to be
untouched. A test that can only fail for the right reason is the
only test that's testing anything.

(Yes, asserting on message substrings couples the test to the
wording. That coupling is the point: for a state machine whose
rejections are strings, the message is the contract. If your errors
are typed, assert the variant — either way, assert something only
the right failure can produce.)

## 2. Dead code carrying our invariant

The second finding was a private helper, `signed_prepare_voters()`,
reporting twelve dark lines. Twelve lines is nothing — except this
helper had **zero callers**, and its doc comment described one of the
most subtle invariants in the system: sealing a governance round
requires a quorum of *distinct signed* prepare votes, because a race
found by our fault suite once let a round seal while the leader's
signed prepare was still in flight.

The invariant was real. The function enforcing it was dead.
Meanwhile the exact computation it documented — collect voter ids,
deduplicate, count — was hand-rolled **inline, twice**, in the two
live seal paths. So the one place that explained the rule did
nothing, and the rule itself existed as two copies that could drift
apart independently. In consensus code, duplicated quorum arithmetic
is precisely where the next bug lives: someone fixes one copy during
a review, the other keeps the old semantics, and now two nodes
disagree about whether a certificate is complete.

The fix was not to write a test for the dead helper. It was to make
the dead code load-bearing: both call sites now call
`signed_prepare_voters()`, the helper became the single source of
truth, and every existing round test lights it up for free.

A dark function with a doc comment is a fork in the road. Either
delete it, or find out why it stopped being called. In this case
"why it stopped being called" was never asked because it was
probably never called at all — it was written as documentation and
merged as code.

## 3. A number that was true for a scope nobody stated

The third finding wasn't in the code at all. It was in the coverage
script.

Our coverage tooling ran `cargo llvm-cov --lib` — the unit suite
only. Fine for most of the codebase. But the federation *transport*
(the dialer, the encrypted handshake, the reconnect logic, the
message loop) is exercised by the **integration suite**: 340-odd
async tests that bind real server sockets and let servers dial each
other over loopback. On a lib-only pass, `federation_active.rs`
reported **33.2%** line coverage. Including the integration suite:
**79.8%**. Nobody lied, no number was wrong — but a scope decision
made in a shell script was silently defining what "covered" meant,
and the definition was hiding half the transport's real testing.

The blended project TOTAL made this worse, not better, because
TOTALs from different target sets aren't comparable — a run that
includes 340 integration tests and a run that doesn't will produce
averages that look like they belong on the same chart. The only
numbers that survive a scope change are the **per-file rows**. We
made two changes: the script now includes `--test integration` in
its engine pass, and it prints the count of tests each pass actually
*executed* next to the coverage — a suite that runs zero tests
while test files exist is a hard failure, because that exact
artifact once reported a tested crate at 0% while looking like a
tooling bug.

A coverage percentage is a function of your scope flags. If the
scope isn't printed next to the number, the number is noise.

## The shape the three share

Looking back, the findings have the same skeleton. In each one, a
summary stood in for the thing it summarized — and the summary kept
passing:

- `is_err()` is a summary of a `Result`: one bit where you needed
  the reason.
- A zero-caller count is a summary of a function's relevance — and
  it said "unimportant" about the one function documenting our
  sealing invariant.
- A blended TOTAL is a summary of a matrix: one number standing in
  for per-file truth across a scope nobody had stated.

We had met this shape before, in the running cluster. A returning
node's health check counted log entries — "nine of ten present" —
and looked healthy while carrying a hole where the tenth should
have been. **Counters cannot see holes; only full digest-list
comparison exposes them.** The coverage exercise was the same
lesson wearing a different coat. Wherever a count, a bit, or an
average tells you something is fine, ask what the full comparison
would say.

## The method, so you can run it

The whole technique is about thirty lines of plumbing over
`llvm-cov`. The report already prints every dark line — thousands of
them, unranked. The information isn't hidden; it just isn't sorted
into a question. The bucketing is the reading:

```bash
# 1. Run coverage over the suites you believe test your code.
cargo llvm-cov --features server --lib --test integration

# 2. Extract the uncovered lines, per file.
cargo llvm-cov report --show-missing-lines \
  | grep -o 'src/server/federation.rs: .*' \
  | tr ',' '\n' | grep -E '^[ 0-9]+$'
```

Then bucket each missing line number by its enclosing function —
nearest preceding `fn` declaration — and **exclude the test module**
(a pile of dark lines inside `mod tests` usually means skipped or
async-lazy test code, not untested production code). What comes out
is a ranked list:

```
federation.rs — 293 dark lines outside tests
  30  get_governance_activities
  30  deserialize<D>
  29  create_cross_server_signature
  ...
   0  receive_pre_prepare      ← was 9, before the fix
   0  receive_commit           ← was 7
   0  signed_prepare_voters    ← was 12, and dead
```

Read it like triage. Thirty dark lines in a serde helper is noise.
Nine dark lines on the wrong-view rejection arm of a consensus state
machine is a siren. The ranking is not a worklist to zero out —
it's a question machine: *why is this exact function dark?* Every
finding in this essay came from asking that question three times.

If you know mutation testing, this will sound familiar — it's the
heavyweight cousin. Mutation testing perturbs your code and checks
whether any test notices, which finds hollow tests mechanically, at
the cost of a toolchain and a run measured in hours. Dark-line
triage is what you can do this afternoon with coverage data your CI
already produces: it doesn't prove your tests are strong, it ranks
where your beliefs about them have never once been executed. That
ranking, read curiously, is most of the value.

## None of this was a production bug

I want to be honest about severity, because the temptation with a
piece like this is to imply saved disasters. Nothing above was
broken in production. The rejection logic was correct; only its
test was hollow. The quorum math was correct in both copies; it was
the *third* copy that was dead. The coverage numbers were accurate;
their scope was just quietly narrower than anyone remembered.

What the dark lines caught was **rot risk**: a test that would keep
passing while the arms it named silently broke; an invariant kept
alive by duplication instead of by code; a measurement that would
have told us the transport regressed with a straight face. None of
those files an incident today. All of them shorten the distance to
one tomorrow.

After the fixes, the consensus state machine — propose, pre-prepare,
prepare, commit, seal, verify, view change, equivocation handling —
has zero dark lines, and two new integration tests cover the paths
that were hardest to reach from unit tests: a configured peer that
is down must back off without taking the server with it, and a
governance round opened before a peer connects must replay to that
peer on connect, with the replica voting back. That last one is the
scenario our whole reconnect story depends on, and before this
exercise it had never once executed in CI.

The 80% floor didn't find any of this. The floor is a blunt
instrument; it can't tell you *which* fifth is dark. You have to go
read the lines — because the count will always say nine out of ten.

---

*The code lives in [xudanu](https://github.com/jonesd/xudanu), a
federated publishing server — the PBFT governance layer is what the
network uses to admit, expel, and rotate member keys when operators
disagree about which direction to take.*
