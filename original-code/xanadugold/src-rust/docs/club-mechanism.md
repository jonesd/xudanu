# Club Mechanism

## Overview

Clubs are the identity, access control, and organizational unit in Xanadu Gold.
Every user, group, and system role is a club. Permissions flow through club
membership and ownership chains.

## Core Concepts

### Club

A club is a first-class entity with:

- **BeId** — unique numeric identifier
- **Work** — an editable description (edition content)
- **Owner** — a BeId (another club or `None`)
- **Signature club** — the club authorized to sign on this club's behalf
- **Credential** — password (argon2id) or public key (ed25519)
- **Members** — set of BeIds that belong to this club
- **Read club / Edit club** — which clubs can read/edit the club's description
- **Personal flag** — marks user-account clubs (max 10,000 per server)

### System Clubs

Four clubs are created at server startup:

| Club | Purpose |
|------|---------|
| `public` | All public sessions authenticate here. Read access to published works. |
| `admin` | Server administration authority. |
| `access` | Access control authority (owned by admin). |
| `empty` | No members, no owner. Used as "nobody" for access control. |

### Session

A session is a connection to the server. Each session has a `KeyMaster` that
tracks which clubs the session has authority over.

### KeyMaster

Tracks two sets of BeIds:

- **Login authority** — clubs the session explicitly authenticated as
- **Actual authority** — login authority + all transitive super-clubs

Authority is transitive: if club A is a member of club B, then A's actual
authority includes B (and anything B is a member of).

## Authentication

### Authentication Flow

```
Client                          Server
  |                               |
  |--- SessionConnect ----------->|  create session
  |                               |
  |--- SessionLogin { club_id } ->|  creates a Lock
  |<-- AuthChallenge { nonce } ---|  (ChallengeLock: random 32-byte nonce)
  |                               |  (MatchLock: no challenge, proceed)
  |                               |
  |--- SessionAuthenticate ------>|  client proves identity
  |    { credential }             |
  |<-- [club_id, ...] -----------|  returns resolved authority
```

### Lock Types

| Lock | When Used | Credential | Verification |
|------|-----------|------------|--------------|
| **MatchLock** | Club has password | `Password(bytes)` | argon2id hash comparison |
| **ChallengeLock** | Club has ed25519 public key | `ChallengeResponse(64-byte signature)` | ed25519 signature over `"xudanu/v1/" + nonce` |
| **BooLock** | Public club only | `Boo` | None (public access) |
| **WallLock** | Club has no credential and isn't public | N/A | Always rejects |

**Strict rule**: BooLock is ONLY used for the system public club. All other
clubs require a real credential. Clubs without credentials are inaccessible
via `SessionLogin` until a credential is set.

### Password Authentication (MatchLock)

1. Club stores a PHC-format argon2id hash
2. Client sends raw password bytes
3. Server verifies with constant-time argon2id comparison
4. Rate limited: 10 attempts per club per 5-minute window

### Public Key Authentication (ChallengeLock)

1. Club stores an ed25519 verifying key (32 bytes)
2. Server generates a random 32-byte nonce
3. Client signs `"xudanu/v1/" + nonce` with their ed25519 signing key
4. Server verifies the 64-byte ed25519 signature against the stored verifying key
5. No rate limit (cryptographic verification)

### Setting Credentials

`club_set_password` requires either:
- Direct authority over the club (session has the club in its actual_authority), OR
- Signature authority (session has authority over the club's `signature_club`)

This allows the creator of a club to set its first password without having
previously authenticated as that club, because `create_club` sets
`signature_club` to the creator's login club.

## Access Control

### Read Permission

A session can read a work if ANY of:

1. The session has grabbed the work
2. The work's `read_club` is the public club
3. The session has authority over the work's `read_club`
4. The session has edit permission (falls through)

### Edit Permission

A session can edit a work if:

1. The work's `edit_club` is the public club, OR
2. The session has authority over the work's `edit_club`

### Ownership

The owner of a work can:
- Publish, unpublish, irrevocably unpublish
- Set read/edit clubs

Ownership is checked via `ensure_owner`, which verifies the session has
authority over the work's owner club.

### Signature Authority

`has_signature_authority(club_id)` checks whether the session has authority
over a club's `signature_club`. This is used for:
- Setting passwords on newly created clubs
- Adding/removing club members
- Making endorsements

### Default Clubs

Clubs can have default read/edit clubs that are applied to works created by
members. Set via `club_set_default_read_club` / `club_set_default_edit_club`.

## Authority Resolution

### At Login Time

When a session authenticates, `KeyMaster::update_authority` resolves all
transitive super-clubs from the login club's membership chain:

```
login_as(club_A)
  → club_A.transitive_super_club_ids()
  → {club_A, club_B, club_C}  (if A ∈ B.members and B ∈ C.members)
```

### On Membership Changes

When `club_add_member` or `club_remove_member` is called:

1. The membership change is applied
2. `refresh_all_session_authority()` is called
3. Every active session's `KeyMaster` re-resolves transitive authority

This means:
- A user added to a club **immediately** gains access to that club's resources
- A user removed from a club **immediately** loses access

## Wire Protocol Operations

### Session Operations (0x00xx)

| Opcode | Name | Auth Required | Description |
|--------|------|---------------|-------------|
| 0x0003 | SessionLogin | No | Start login to a club (returns challenge or void) |
| 0x0004 | SessionLoginByName | No | Login by club name |
| 0x0005 | SessionAuthenticate | Pending lock | Complete login with credential |
| 0x0006 | SessionLoginPublic | No | Authenticate as public club |

### Club Operations (0x02xx)

| Opcode | Name | Auth Required | Description |
|--------|------|---------------|-------------|
| 0x0201 | ClubCreate | Logged in | Create a new club |
| 0x0202 | ClubCreateNamed | Logged in | Create a named club |
| 0x0203 | ClubGet | Session | Verify club exists |
| 0x0204 | ClubByName | Session | Look up club by name |
| 0x0205 | ClubIdByName | Session | Resolve name to ID |
| 0x0206 | ClubNameById | Session | Resolve ID to name |
| 0x0207 | ClubNames | Session | List all club names |
| 0x0208 | ClubSetDefaultReadClub | Authority over club | Set default read club |
| 0x0209 | ClubSetDefaultEditClub | Authority over club | Set default edit club |
| 0x020A | ClubSetPassword | Signature authority | Set password credential |
| 0x020B | ClubClearCredential | Signature authority | Remove credential |
| 0x020C | ClubCreatePersonal | Logged in | Create user account |
| 0x020D | ClubWhoAmI | Logged in | List personal clubs |
| 0x020E | ClubAddMember | Signature authority | Add member to club |
| 0x020F | ClubRemoveMember | Signature authority | Remove member from club |
| 0x0210 | ClubMembers | Authority or read access | List club members |

### Work Operations (0x01xx)

| Opcode | Name | Auth Required | Description |
|--------|------|---------------|-------------|
| 0x0101 | WorkCreate | Logged in | Create a new work |
| 0x0102 | WorkGetEdition | Can read | Get current edition |
| 0x0104 | WorkGrab | Can edit | Grab for exclusive editing |
| 0x0105 | WorkRelease | Grabber | Release grab |
| 0x0106 | WorkForceRelease | Can edit | Force-release any grab |
| 0x0107 | WorkRevise | Grabber + can edit | Submit new edition |
| 0x0108 | WorkSetReadClub | Can edit | Set read access club |
| 0x0109 | WorkSetEditClub | Can edit | Set edit access club |
| 0x010B | WorkPublish | Owner | Make publicly readable |
| 0x010C | WorkUnpublish | Owner | Restrict to owner |
| 0x010D | WorkIrrevocablyUnpublish | Owner | Permanently remove public access |
| 0x010E | WorkSponsor | Can edit | Add sponsoring club |
| 0x010F | WorkUnsponsor | Can edit | Remove sponsoring club |
| 0x0110 | WorkSetOwner | Can edit | Transfer ownership |

## Security Model

### Principles

1. **No implicit access** — every operation requires explicit authorization
2. **Transitive authority is live** — membership changes take effect immediately
3. **Credentials are required** — only the public club accepts passwordless auth
4. **Signatures are cryptographic** — ed25519 for challenge-response, argon2id for passwords
5. **Rate limiting** — 10 login attempts per club per 5-minute window

### Threat Model

| Threat | Mitigation |
|--------|------------|
| Brute-force password | argon2id (19456 KiB, 2 iterations) + rate limiting |
| Credential replay | Challenge-response uses random server nonce per login |
| Session hijacking | Session IDs are random 64-bit, per-connection |
| Privilege escalation | Authority checked on every mutation, not cached across operations |
| Information disclosure | Club names, IDs, endorsements require active session |
| Grab hijacking | Force-release requires edit permission on the work |
| TOCTOU on authority | Authority re-resolved from login_authority on every check |

### Signing Keys

Personal clubs have ed25519 signing keys:

- Generated on password setup, encrypted with argon2id-derived key
- Stored as `EncryptedSigningKey` in the manifest (verifying key + AES-256-GCM envelope)
- Decrypted on successful password login, held in session memory
- Used for endorsements and federation signatures

## Personal Clubs (User Accounts)

Personal clubs are user accounts. They:

- Are limited to 10,000 per server
- Must have unique display names
- Require a password on creation
- Generate an ed25519 signing key encrypted with the password
- Can only have one per session

Creation flow:
1. `ClubCreatePersonal { display_name, password }`
2. Server creates club with `is_personal = true`
3. Generates ed25519 keypair, encrypts signing key with password
4. Session gains authority over the new personal club

## Persistence

### Dirty Tracking

Clubs use `dirty_clubs: HashSet<BeId>` for dirty tracking:

- Club mutations add the club's BeId to `dirty_clubs`
- Checkpoint only re-serializes clubs in `dirty_clubs`
- After checkpoint, `dirty_clubs` is cleared
- Clean clubs reuse their stored `ClubChunkRef`

### What's Persisted

Each club serializes as `ClubChunkRef`:

```
ClubChunkRef {
    be_id, name, signature_club,
    work_root: WorkChunkRef,     // description work, chunked
    default_read_club, default_edit_club,
    is_personal, display_name,
    credential,                   // PHC hash or verifying key
    encrypted_signing_key,        // AES-256-GCM envelope
    members: Vec<BeId>,
    sponsored_works: Vec<BeId>,
}
```

### Restore

On server restart:
1. Manifest is read and checksum-verified
2. Each `ClubChunkRef` is deserialized into a `Club`
3. Only current editions are loaded (lazy revision loading)
4. Club refs are stored for dirty-checkpoint optimization
5. Authority is NOT stored — sessions must re-authenticate after restart

## Example: Multi-User Workflow

```
# Server starts, admin sets password
Server: init_data_dir("/data")
Server: club_set_password(admin_session, admin_club, b"admin-secret")

# Alice creates account
Client: SessionConnect
Client: SessionLoginPublic                          # auth as public
Client: ClubCreatePersonal { "alice", "alice-pass" }
Server: creates personal club, generates signing key

# Alice logs in
Client: SessionConnect
Client: SessionLogin { alice_club_id }
Server: returns void (MatchLock, no challenge needed)
Client: SessionAuthenticate { Password(b"alice-pass") }
Server: verifies argon2id, returns [alice_club_id, ...]

# Alice creates a private work
Client: WorkCreate { edition: "My private document" }
Server: work created with read_club=alice, edit_club=alice

# Alice creates a group
Client: ClubCreateNamed { "editors", ... }
Client: ClubSetPassword { editors_club, b"editors-pass" }
Client: ClubAddMember { editors_club, alice_club }
Server: alice immediately has authority over editors_club

# Bob creates account and is added to editors
Client: (Bob connects and creates personal club "bob")
Client: (Alice) ClubAddMember { editors_club, bob_club }
Server: bob immediately has authority over editors_club

# Alice shares work with editors group
Client: WorkSetEditClub { work_id, editors_club }
# Now both Alice and Bob can edit, nobody else can
```
