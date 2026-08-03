# Xudanu Roadmap — Reliability, Multi-User, and Xanadu Integration

> **Created:** August 2026
> **Status:** Active planning document
> **Goal:** Production-ready multi-user hypertext system deployed on xudanu.com

## 1. Current State Assessment

### What Works
- Single-user document creation, editing, auto-save
- Transclusion (inline, with provenance, FR-26 hash verification)
- Typed links (Comment, Reference, Disagreement, Quotation, See Also, Trail)
- Reading vs authoring mode toggle
- Compound Builder (Phase 1: search, stats, images)
- Session tickets with 7-day rolling renewal
- CRDT collaborative editing (tested 2-3 users)
- Attribution with Ed25519 signatures
- Revision history
- Trails (curated document paths)
- XCP v1.0 endpoints (server identity, content retrieval, backlinks)

### Known Bugs (Priority Order)

| # | Bug | Severity | Root Cause |
|---|-----|----------|------------|
| 1 | Auth loss on refresh (intermittent) | HIGH | Fixed (issue_session_ticket), needs more testing |
| 2 | Document switching stalls under rapid clicks | HIGH | switchWork guard added, needs stress testing |
| 3 | Document surface disappears when window narrow | MEDIUM | CSS flex constraints |
| 4 | Visual artifacts in reading mode | MEDIUM | Canvas overlay / CSS interaction |
| 5 | Compound state occasionally wiped | MEDIUM | Fixed (epoch guards), needs testing |
| 6 | Revision history needs manual retry | LOW | Auth timing — loads before session authenticates |
| 7 | Pre-existing compound-panel test failure | LOW | Test fixture, not production code |

### Performance Concerns
- Work list fetches ALL works (up to 1000) on every connect
- Attribution query runs on every work switch + every text edit (1.5s debounce)
- Compound state polled every 30 seconds (even when nothing changed)
- No virtualization on work picker (renders all entries)

---

## 2. Reliability Plan (Weeks 1-2)

### 2.1 Auth Stability
- [x] Fix: `issue_session_ticket` uses current authority (not initial_login)
- [x] Fix: `session_login_public` doesn't overwrite ticket auth
- [x] Fix: Ticket nonce reuse for reconnects
- [ ] **Test**: 20 consecutive hard refreshes, verify david persists
- [ ] **Test**: Leave tab idle 30 minutes, verify still authenticated
- [ ] **Test**: Two tabs (same user), verify both stay authenticated
- [ ] **Test**: Server restart, verify ticket redemption works

### 2.2 Work Switching Stability
- [x] Fix: switchWork guard (no overlapping close/open)
- [x] Fix: Position calculation (no double-adjustment)
- [x] Fix: Server-side `\n` injection removed
- [ ] **Test**: Rapid click through 10 works, verify text loads correctly each time
- [ ] **Test**: Switch works while text delta is in flight, verify no corruption
- [ ] **Test**: Switch to same work twice rapidly, verify no blank screen

### 2.3 Data Integrity
- [x] Fix: Compound state epoch guards
- [x] Fix: Attribution epoch guards
- [x] Fix: Annotation epoch guards
- [ ] **Audit**: Review all `setState` calls in async callbacks for race conditions
- [ ] **Test**: Create work, type, switch, switch back — verify text preserved
- [ ] **Test**: Transclude, edit source, switch back — verify transclusion intact
- [ ] **Add**: Checksum verification on work switch (detect corruption early)

### 2.4 Performance
- [ ] **Optimize**: Work list — only fetch metadata (title, updated_at), not full entries
- [ ] **Optimize**: Attribution query — debounce to 3s (was 1.5s), skip if text unchanged
- [ ] **Optimize**: Compound poll — skip if no compound state (hasCompound false)
- [ ] **Optimize**: Virtualize work picker for >100 works
- [ ] **Optimize**: Lazy-load graph panel (already deferred, verify timing)

---

## 3. UX Polish (Weeks 2-3)

### 3.1 Document Surface
- [ ] Fix: Narrow window — document surface must never disappear
- [ ] Fix: Reading mode visual artifacts (canvas overlay bleed)
- [ ] Add: Responsive layout (tablet: collapsible panels, mobile: single panel)
- [ ] Add: Empty state for new users ("Create your first document")

### 3.2 Navigation
- [ ] Fix: Recent list must update immediately on work creation
- [ ] Fix: Star toggle must work across club boundaries
- [ ] Add: Keyboard shortcut to cycle through Recent works (Cmd+Shift+[ / ])
- [ ] Add: Breadcrumb trail showing navigation history (back button)

### 3.3 Transclusion UX
- [x] Fix: Inline placement (no forced line break)
- [ ] Fix: Click transclusion text to navigate to source (currently broken)
- [ ] Add: Hover tooltip on transclusion span (source title, license, changed status)
- [ ] Add: "Where else is this used?" counter on transclusion spans
- [ ] Add: Reading mode renders transclusion seamlessly (no markers)

### 3.4 Editor
- [x] Fix: Escape cancels pending transclusion
- [ ] Fix: Undo support (Cmd+Z in editor doesn't undo transclusion placement)
- [ ] Add: Block formatting markers (# heading, - list, > quote)
- [ ] Add: Paste handling for rich text (strip formatting, keep plain text)
- [ ] Add: Auto-save indicator (saved/saving/error states)

---

## 4. Multi-User Features (Weeks 3-5)

### 4.1 User Discovery
- [ ] Add: "People" panel showing all users on this server
  - Server: `club_names` endpoint exists (`WireRequest::ClubNames`)
  - Client: `fetchClubNames()` method exists
  - UI: New panel in left rail or right sidebar
  - Show: display name, work count, last active
- [ ] Add: User profiles (click a user → see their public works)
- [ ] Add: Online indicator (awareness already tracks sessions)

### 4.2 Work Sharing
- [ ] Add: "Invite to edit" button on work header
  - Show user picker (from People panel)
  - Call `work_set_edit_club` to add user's club
  - Notify invited user (store in manifest or session)
- [ ] Add: "Shared with me" section in Library
  - Works where my club is in edit_club or read_club
  - Work list query already returns read_club/edit_club
- [ ] Add: Notification when someone shares a work with you
  - Server: store pending invitations in SocialSection
  - Client: poll on connect, show badge in header
- [ ] Add: Revoke edit access (remove club from edit_club)

### 4.3 Collaborative Awareness
- [x] Cursor positions and selections (awareness system)
- [ ] **Add: Awareness bar** — restore the presence bar showing online
  colleagues with their current work, cursor position, and quick
  interaction (click to join their work, send cursor reaction)
  - Server: awareness data already pushed via `crdt_awareness_update`
  - Client: `awareness` state already in `useCrdtSync`
  - UI: Needs a dedicated bar (was removed during UI consolidation)
  - Show: avatar, name, current work title, typing indicator
  - Interact: click user → navigate to their work, hover → see cursor
- [ ] Add: "X is editing" indicator when another user has the work open
- [ ] Add: Conflict notification (when CRDT merge changes your text)
- [ ] Add: Presence list in right panel (who's viewing this work)

### 4.4 Permissions Model
- [x] read_club / edit_club per work
- [x] ensure_can_read / ensure_can_edit server-side checks
- [ ] Add: Owner-only operations (delete, change license, archive)
- [ ] Add: Admin panel for server-wide user management
- [ ] Add: Rate limiting per user (not just per IP)

---

## 5. Xanadu Organization Engagement

### 5.1 Short-term (passive)
- [x] Deploy on xudanu.com
- [x] Send screenshots + documentation links to Roger Gregory
- [x] XCP spec published (v1.0 deployed, v1.1 drafted)
- [x] Open source on GitHub (Apache 2.0)
- [ ] Contact Andrew Pam (more active than Roger)
- [ ] Write HN launch post (when ready)

### 5.2 Medium-term (active)
- [ ] Implement XCP search endpoint (enables cross-server discovery)
- [ ] Implement XCP webhook subscriptions (live transclusion updates)
- [ ] Build Gold XCP adapter (thin HTTP wrapper over Gold API)
  - This lets Gold servers join the network without rewriting Gold
  - Demonstrates XCP's implementation-agnostic design
  - Gives the Xanadu team a concrete reason to engage
- [ ] Write "Xudanu for Xanadu Users" guide
  - Map Gold concepts to Xudanu equivalents
  - Show working transclusion, links, provenance
  - Explain what's different and why

### 5.3 Long-term (partnership)
- [ ] Host Xanadu community documents on xudanu.com
  - Import Project Xanadu papers, Nelson's writings (with permission)
  - Create trails through the documentation
  - Demonstrate the docuverse vision with real content
- [ ] Offer xudanu.com as a hosted Xanadu service
  - Free tier for individuals
  - Xanadu team gets admin access to their own namespace
- [ ] Collaborate on spanfilade (if they're interested)
  - We have the ent/ module with crum/HTree machinery
  - Their expertise on I-stream positioning is irreplaceable
  - Joint implementation could benefit both projects

### 5.4 Positioning
- **For the Xanadu team**: "A working, modern implementation of the
  docuverse vision. Open source, deployable today. We want your
  expertise, not your permission."
- **For general users**: "Hypertext the way Ted Nelson imagined it:
  unbreakable links, transclusion, provenance. Built in Rust, runs
  in your browser."
- **For developers**: "Self-hosted document store with CRDT
  collaboration, typed links, content-addressed transclusion, and
  cryptographic attribution. XCP for cross-server references."

---

## 6. Deployment Checklist (xudanu.com)

- [ ] Choose hosting (VPS: DigitalOcean/Hetzner $5-10/mo, or self-hosted)
- [ ] Configure DNS (xudanu.com → server IP)
- [ ] Obtain TLS certificates (Let's Encrypt via certbot)
- [ ] Build release binary (`cargo build --release --features server`)
- [ ] Build frontend (`npm run build` → dist/)
- [ ] Configure systemd service (auto-restart, log rotation)
- [ ] Set up backups (daily: manifest + chunks + blobs)
- [ ] Configure firewall (ports 80/443 only)
- [ ] Set up monitoring (health endpoint check, disk space alerts)
- [ ] Create admin account
- [ ] Seed with demo content (Xanadu essay, transclusion demo)
- [ ] Write welcome page for new users
- [ ] Set up email (for signup verification, if enabled)
- [ ] Configure CSRF protection (--csrf-token flag)
- [ ] Test: create account, create work, type, transclude, switch, refresh

---

## 7. Prioritized Task List

### Phase 1: Stability (This Week)
1. Fix narrow window document surface
2. Stress test auth (20 refreshes, idle, restart)
3. Stress test work switching (rapid clicks)
4. Fix reading mode visual artifacts
5. Clean up all debug console.logs
6. Run full test suite, fix any failures

### Phase 2: UX Polish (Next Week)
7. Fix Recent list update on work creation
8. Fix click-to-navigate on transclusion spans
9. Add auto-save indicator
10. Add empty state for new users
11. Add responsive layout (tablet)

### Phase 3: Multi-User (Weeks 3-4)
12. Add People panel (user discovery)
13. Add invite-to-edit functionality
14. Add "Shared with me" section
15. Add presence indicators
16. Add notifications for shares

### Phase 4: Deployment (Week 4-5)
17. Build release binary
18. Deploy to xudanu.com with TLS
19. Seed demo content
20. Send invitation to Andrew Pam
21. Write HN launch post

### Phase 5: XCP Enhancement (Week 6+)
22. Implement search endpoint
23. Implement webhook subscriptions
24. Build Gold XCP adapter
25. Contact Xanadu team with working demos

---

## Success Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Hard refresh preserves auth | 20/20 consecutive | Untested |
| Work switch reliability | 50 rapid switches, 0 blank screens | Untested |
| Page load to text visible | < 2 seconds | ~1 second (IPv4 fix) |
| Concurrent users | 10 without degradation | Untested |
| Backend tests passing | 2465+ | 2465 ✅ |
| Frontend tests passing | 504+ | 504 ✅ |
| Pre-push checks | 8/8 | 8/8 ✅ |
