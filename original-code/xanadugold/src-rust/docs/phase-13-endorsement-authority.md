# Phase 13: Endorsement Authority + Wire Operations

## Overview

Phase 13 wires the endorsement system into the server API with proper authority validation, matching the C++ `validateEndorsement`/`validateSignature` pattern. Endorsements are publicly readable but can only be modified by sessions with signature authority for the clubs referenced in the endorsement.

## What Was Built

### 1. Edition Endorsement Field

Added `endorsements: EndorsementSet` field to `Edition` (previously only `Work` had endorsements). Methods:
- `endorsements()` — get current endorsements
- `endorse(&mut self, additional)` — union additional endorsements
- `retract(&mut self, removed)` — difference removed endorsements
- `with_endorsements(self, endorsements)` — builder pattern

All Edition constructors and transformation methods (with, without, replace, copy, transformed_by, etc.) preserve endorsements.

### 2. Authority Validation (`validate_endorsement`)

Port of C++ `FeRangeElement::validateEndorsement` + `validateSignature`:

```rust
fn validate_endorsement(&self, session_id, endorsements) -> Result<()> {
    let km = session.key_master()?;
    for club_id in endorsements.club_ids() {
        if !km.has_signature_authority(club_id, &self.clubs) {
            return Err(ServerError::Unauthorized(...));
        }
    }
    Ok(())
}
```

Checks `has_signature_authority(club_id, all_clubs)` for every club_id in the endorsement set. This follows the C++ pattern exactly: extract club IDs from endorsements, verify the KeyMaster has signature authority for each.

### 3. Server Methods

| Method | Auth | Description |
|--------|------|-------------|
| `work_endorse(session, work_id, endorsements)` | Signature authority | Union endorsements onto a Work |
| `work_retract(session, work_id, endorsements)` | Signature authority | Remove endorsements from a Work |
| `work_endorsements(work_id)` | None | Query Work endorsements |
| `edition_endorse(session, edition_id, endorsements)` | Signature authority | Union endorsements onto an Edition |
| `edition_retract(session, edition_id, endorsements)` | Signature authority | Remove endorsements from an Edition |
| `edition_endorsements(edition_id)` | None | Query Edition endorsements |
| `edition_visible_endorsements(session, edition_id)` | None | Edition + readable Works' endorsements |
| `edition_total_endorsements(edition_id)` | None | Edition + all Works' endorsements |

### 4. Wire Protocol (opcodes 0x1301–0x1308)

| Operation | Opcode | Payload |
|-----------|--------|---------|
| `work_endorse` | 0x1301 | work_id, endorsements: [[club_id, token_id], ...] |
| `work_retract` | 0x1302 | work_id, endorsements: [[club_id, token_id], ...] |
| `work_endorsements` | 0x1303 | work_id |
| `edition_endorse` | 0x1304 | edition_id, endorsements: [[club_id, token_id], ...] |
| `edition_retract` | 0x1305 | edition_id, endorsements: [[club_id, token_id], ...] |
| `edition_endorsements` | 0x1306 | edition_id |
| `edition_visible_endorsements` | 0x1307 | edition_id |
| `edition_total_endorsements` | 0x1308 | edition_id |

All endorse/retract operations validate authority. Query operations are public.

### 5. New Error Type

`ServerError::Unauthorized(String)` — returned when a session lacks signature authority for a club in the endorsement set.

## How to Use

### Endorsing a Work

```json
→ {"id": 1, "op": "work_endorse", "v": 2,
   "work_id": 1004,
   "endorsements": [[3, 10], [3, 20]]}
← {"id": 1, "type": "response", "value": null, "v": 2}
```

### Querying Endorsements

```json
→ {"id": 2, "op": "work_endorsements", "v": 2, "work_id": 1004}
← {"id": 2, "type": "response", "value": {"endorsements": [[3, 10], [3, 20]]}, "v": 2}
```

### Retracting an Endorsement

```json
→ {"id": 3, "op": "work_retract", "v": 2,
   "work_id": 1004,
   "endorsements": [[3, 10]]}
← {"id": 3, "type": "response", "value": null, "v": 2}
```

### Endorsing an Edition

```json
→ {"id": 1, "op": "edition_endorse", "v": 2,
   "edition_id": 5001,
   "endorsements": [[3, 5]]}
← {"id": 1, "type": "response", "value": null, "v": 2}
```

### Authority Check Failure

If a session lacks signature authority for any club in the endorsement:

```json
← {"id": 2, "type": "error", "code": "unauthorized",
   "message": "unauthorized: no signature authority for club 99"}
```

## Tests

- **5 integration tests**: `work_endorse_and_query`, `work_endorse_retract`, `edition_endorse_and_query`, `endorsement_requires_authority`, `work_endorse_idempotent`
- **Total: 1322 tests passing** (1202 unit + 120 integration)

## C++ Equivalence

| C++ Method | Rust Equivalent |
|-----------|-----------------|
| `FeRangeElement::validateEndorsement()` | `Server::validate_endorsement()` |
| `FeRangeElement::validateSignature()` | `KeyMaster::has_signature_authority()` (already existed) |
| `FeWork::endorse()` | `Server::work_endorse()` |
| `FeWork::retract()` | `Server::work_retract()` |
| `FeWork::endorsements()` | `Server::work_endorsements()` |
| `FeEdition::endorse()` | `Server::edition_endorse()` |
| `FeEdition::retract()` | `Server::edition_retract()` |
| `FeEdition::endorsements()` | `Server::edition_endorsements()` |
| `FeEdition::visibleEndorsements()` | `Server::edition_visible_endorsements()` |
| `BeEdition::totalEndorsements()` | `Server::edition_total_endorsements()` |

## Not Yet Implemented

- **Endorsement persistence in snapshots**: Endorsements on Works and Editions are not yet serialized in `WorkSnapshot`/`EditionSnapshot`. Only sponsors are persisted.
- **Endorsement propagation via Canopy/BertProp**: The `BertProp.endorsements` field and `endorsements_filter` in `BackfollowFinder` exist in the library but are not yet connected to the server endorsement operations.
- **Club filtering by endorsement**: The C++ `FeClub::sponsoredWorks(filter)` can filter by endorsement match. Not yet wired.
