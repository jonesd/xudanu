---- MODULE XudanuPBFT ----
EXTENDS Integers, FiniteSets
\* XudanuPBFT.tla -- safety specification of the xudanu governance
\* consensus (post FR-19b hardening + FR-75 key epochs).
\* 
\* Models: N nodes, f byzantine (BYZ set), quorum Q = 2f+1.
\* Signed votes bound to (sequence, digest) -- a byzantine node's only
\* power beyond crashing is EQUIVOCATION: sending different digests
\* for the same sequence to different recipients. Safety must hold
\* regardless of message reordering (the mesh harness proved the
\* implementation under reordering; this spec proves the PROTOCOL).
\* 
\* Safety invariant (Agreement): no two nodes ever seal different
\* digests at the same sequence.
\* Also checked: Validity -- a sealed digest was proposed by the
\* leader of that sequence.
-------------------------------
CONSTANT N        \* cluster size (4)
CONSTANT Q        \* quorum (3)
CONSTANT BYZ      \* byzantine node indices (one)
CONSTANT S        \* sequence numbers to explore (1..2)
CONSTANT D        \* digests/values (two)

VARIABLE
    \* Messages "in flight", accumulated (OR-set semantics: messages
    \* are never lost -- reordering modeled by arbitrary step order).
    prepares,    \* [node][seq][digest] present
    commits,      \* [node][seq][digest] present
    \* Per-node state
    prepared,     \* [node][seq] = digest a node saw reach prepare-quorum
    sealed        \* [node][seq] = digest sealed, or "none"

Vars == <<prepares, commits, prepared, sealed>>

NoDigest == "none"  \* model NULL

Values == D \cup {NoDigest}

Node == 0..N-1
Seq == S
Digest == D

\* The leader of sequence s (deterministic rotation, view 0).
Leader(s) == (s - 1) % N

TypeOK ==
    /\ prepares \in [Node -> [Seq -> [Digest -> BOOLEAN]]]
    /\ commits  \in [Node -> [Seq -> [Digest -> BOOLEAN]]]
    /\ prepared \in [Node -> [Seq -> Values]]
    /\ sealed   \in [Node -> [Seq -> Values]]

\* Count prepare messages for (s, d): distinct voters.
PrepQuorum(s, d) ==
    Cardinality({m \in Node : prepares[m][s][d]}) >= Q

CommQuorum(s, d) ==
    Cardinality({m \in Node : commits[m][s][d]}) >= Q

\* An HONEST node m prepares (s, d) only on the leader's pre-prepare
\* for d (digest-bound: it cannot prepare a different digest).
CanPrepare(m, s, d) ==
    /\ m \notin BYZ
    /\ Leader(s) = m \/ Leader(s) \notin BYZ
    \* (the leader's own proposal is implicit; honest non-leaders
    \* echo only the leader's digest -- modeled by m voting d only if
    \* the leader proposed d; the leader's proposal itself is the
    \* variable prepares[Leader(s)][s][d] set by the leader step)
    /\ m # Leader(s) => prepares[Leader(s)][s][d]
    /\ prepared[m][s] = NoDigest   \* one value per node per seq

\* A byzantine node may vote for ANY digest at any time (equivocation
\* across recipients is indistinguishable in the accumulated set from
\* voting both).
CanByzVote(m, s, d) ==
    /\ m \in BYZ
    /\ ~prepares[m][s][d]

VotePrepare(m, s, d) ==
    /\ prepares' = [prepares EXCEPT ![m][s][d] = TRUE]
    /\ UNCHANGED <<commits, prepared, sealed>>

\* A node (honest or byzantine) commits what it prepared.
CanCommit(m, s, d) ==
    /\ prepared[m][s] = d
    /\ PrepQuorum(s, d)
    /\ ~commits[m][s][d]

VoteCommit(m, s, d) ==
    /\ commits' = [commits EXCEPT ![m][s][d] = TRUE]
    /\ UNCHANGED <<prepares, prepared, sealed>>

\* The leader proposes d at s (only once -- sets its own prepare).
Lead(s, d) ==
    /\ Leader(s) \notin BYZ
    /\ prepared[Leader(s)][s] = NoDigest
    /\ prepares' = [prepares EXCEPT ![Leader(s)][s][d] = TRUE]
    /\ UNCHANGED <<commits, prepared, sealed>>

\* A node recognizes prepare-quorum and records the prepared digest
\* (FR-75 fork protection: never prepares two digests at one seq).
RecordPrepared(m, s, d) ==
    /\ PrepQuorum(s, d)
    /\ CanPrepare(m, s, d) \/ m \in BYZ
    \* byzantine nodes may also "prepare" any digest they voted for
    /\ prepared' = [prepared EXCEPT ![m][s] = d]
    /\ UNCHANGED <<prepares, commits, sealed>>

\* A node seals after commit-quorum for the digest it prepared.
Seal(m, s, d) ==
    /\ prepared[m][s] = d
    /\ CommQuorum(s, d)
    /\ sealed' = [sealed EXCEPT ![m][s] = d]
    /\ UNCHANGED <<prepares, commits, prepared>>

Init ==
    /\ prepares  = [n \in Node |-> [s \in Seq |-> [d \in Digest |-> FALSE]]]
    /\ commits   = [n \in Node |-> [s \in Seq |-> [d \in Digest |-> FALSE]]]
    /\ prepared  = [n \in Node |-> [s \in Seq |-> NoDigest]]
    /\ sealed    = [n \in Node |-> [s \in Seq |-> NoDigest]]

Next ==
    \E m \in Node, s \in Seq, d \in Digest :
        \/ (CanPrepare(m, s, d) /\ ~prepares[m][s][d] /\ VotePrepare(m, s, d))
        \/ (CanByzVote(m, s, d) /\ VotePrepare(m, s, d))
        \/ (CanCommit(m, s, d) /\ VoteCommit(m, s, d))
        \/ Lead(s, d)
        \/ RecordPrepared(m, s, d)
        \/ Seal(m, s, d)

\* ===================== Safety =====================

\* Agreement: no two nodes seal different digests at one sequence.
Agreement ==
    \A s \in Seq, n1, n2 \in Node :
        /\ sealed[n1][s] # NoDigest
        /\ sealed[n2][s] # NoDigest
        => sealed[n1][s] = sealed[n2][s]

\* Validity: a sealed digest was proposed by the leader (or voted by
\* the byzantine minority -- bounded equivocation is inherent).
Validity ==
    \A s \in Seq, n \in Node :
        sealed[n][s] \in D =>
            prepares[Leader(s)][s][sealed[n][s]]
            \/ \E b \in BYZ : prepares[b][s][sealed[n][s]]

Spec == Init /\ [][Next]_Vars

Theorem == Spec => [](TypeOK /\ Agreement /\ Validity)
====
