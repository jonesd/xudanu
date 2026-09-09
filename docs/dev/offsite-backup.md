# Off-Machine Backup — design, failure model, security

Nelson's rule (17): content must never exist as only one copy. This
document is the design authority for how Xudanu data leaves the
machine it lives on. Implementation: `scripts/backup-offsite.sh`
(hardened 2026-09-08), `scripts/restore-offsite.sh`, `/health`
`backup` section.

## 1. Direction policy (decided 2026-09-08)

| Flow | Verdict | Why |
|---|---|---|
| **xudanu.com → Hetzner Storage Box** | **THE backup** | push-only; target has no public services; snapshots give point-in-time recovery; ~€4/mo; zero patching |
| Mac dev dirs → anywhere | low priority | dev/demo data is recreatable from seed scripts; local dirs are small anyway |
| xudanu.com → Mac (pull) | **never** | requires inbound reachability to a home machine (tailscale exposure), depends on laptop being on, and the laptop lacks free disk |
| Mac → xudanu.com | skip for now | low value; makes production a receiver of push data (disk-fill risk, however small) |

Same-provider caveat: box and VPS are both Hetzner — a provider-level
outage touches both. Accepted for now; snapshots still cover the
common failure classes (disk, deletion, compromise of primary).
Diversify when client data with an SLA is involved.

## 2. What gets backed up (and the bug this fixed)

Pre-2026-09-08 the script's `--include="manifest*.json*"` pattern
**missed `root_manifest.json`** — the bootstrap file that names the
root chunk. A restore from an old backup could not boot. Current
order and rationale:

1. `root_manifest.json` + `manifest*.json*` — bootstrap + history
2. `chunks/` — content-addressed content; dedups naturally per file
3. `blobs/` — images/imported media
4. `attribution/` — the provenance ledger (its chain head is
   Bitcoin-anchored; the log must survive with the content it
   attests to, or the anchors attest to nothing retrievable)
5. `anchoring/` — OTS receipts (the proofs themselves)
6. `security.log.*` — tamper-evident audit trail
7. `wal.log`, `archive/`, `ticket_nonces.json`
8. `server.key` — LAST and separately; passphrase-encrypted at rest
   and it stays that way in the backup

Explicitly NOT in any backup: the key passphrase, the admin
passphrase, the OTS calendar URLs' identity (public anyway). Those
live in the password manager and the deploy compose file only.

## 3. Failure scenarios and what happens

| Scenario | Behavior |
|---|---|
| Network down mid-run | rsync `--partial` resumes next run; status=`fail`; ping switch `/fail` if configured |
| One dest fails, others succeed | all dests attempted; per-dest results in status; overall `fail` |
| Destination full | rsync errors → status `fail` with step detail |
| Two backups overlap (slow link + cron fire) | lockfile; second run exits code 3 without touching the sync |
| Cron dies silently | dead-man switch stops receiving pings → the switch service alerts; `/health` backup staleness also grows |
| Source corrupted before backup | mitigation: pre-flight `xudanu-server verify <dir>` recommended in the cron wrapper (not forced — cost on big dirs); snapshots mean a bad backup doesn't overwrite good history |
| Primary compromised + attacker deletes | snapshots on the box are outside the primary's credentials; attribution chain + anchors make silent history tamper evident even where deletion isn't preventable |
| Backup restored, then... does it work? | the QUARTERLY RESTORE DRILL (below) answers this before it matters |

## 4. Error surfacing (three layers)

1. **`<data_dir>/backup-status.json`** — written every run, success
   or failure, with per-destination results; exposed by the server
   as `/health` → `backup` (`last_run`, `status`, `age_secs`), so
   any uptime monitor watches staleness exactly like anchoring.
2. **stderr + exit codes** — cron mail, systemd OnFailure, or any
   wrapper sees them (1 = backup failed, 3 = lock contention).
3. **Optional dead-man switch** — `XUDANU_BACKUP_PING_URL` env; a
   healthchecks.io-style URL pinged on success and `/fail` on
   failure. Catches the failure cron itself.

Alerting guidance: `status != ok` → investigate now; `age_secs >
48h` → the cron is dead or the link is; both are visible externally.

## 5. Security model

- **Transit**: rsync over SSH only. No plaintext protocols.
- **Destination account**: dedicated user on the box, SSH key
  restricted to rsync server mode via `authorized_keys` forced
  command (`command="rsync --server -az . /backups/xudanu"`,
  `restrict`, no-pty). The key cannot open a shell, cannot read
  other paths, cannot delete outside the rsync semantics the command
  permits. Passphraseless key is acceptable BECAUSE the command is
  forced and the account is backup-only.
- **server.key**: encrypted at rest (Argon2 + ChaCha20) before it
  ever leaves; the backup does not weaken this.
- **Ransomware/deletion on primary**: snapshots are governed by the
  box, not by anything the primary's compromise would control.
- **Ransomware on the backup target**: the target holds a copy of
  `server.key` — passphrase-encrypted; the threat is deletion, which
  snapshots mitigate; the anchored attribution chain makes any
  tampered restore detectable (`xudanu-server verify` + chain head
  vs the Bitcoin receipt).
- **Restore is trusted-input**: restores go into a FRESH directory,
  verified (`xudanu-server verify`), then swapped in — never rsynced
  over a live data dir.

## 6. Deployment on xudanu.com (runbook)

```sh
# 1. Storage Box: create backup user + snapshot schedule (Hetzner console)
# 2. On the server: dedicated key
ssh-keygen -t ed25519 -f /root/.ssh/backup_key -N ""
# 3. Storage Box authorized_keys (in its console):
#    restrict,no-pty,command="rsync --server -vlogDtpre.iLsfxCIe . /backups/xudanu" ssh-ed25519 AAAA... backup
# 4. Cron (root): nightly 03:15, retry wrapper, pre-flight verify weekly
crontab -e
#    15 3 * * * /opt/xudanu/repo/scripts/backup-offsite.sh /data uXXXXXX@uXXXXXX.your-storagebox.de:/backups/xudanu >> /var/log/xudanu-backup.log 2>&1
#    (optional) export XUDANU_BACKUP_PING_URL in a wrapper script
# 5. Watch: https://xudanu.com/health → backup.status / age_secs
```

## 7. The quarterly restore drill (the only real test)

A backup that has never been restored is a hypothesis.

1. Spin up a throwaway VPS (or docker volume), install the release
   binary.
2. rsync the backup down to a fresh `/data`.
3. `xudanu-server verify /data` — chunk integrity.
4. Start the server against it; confirm works count, links, the
   attribution chain (`verify-security-log`), and that the anchoring
   head matches the last anchored receipt.
5. Tear it down. Record the drill date in this file.

Last drill: — (none yet; first drill due after the first production
backup runs)
