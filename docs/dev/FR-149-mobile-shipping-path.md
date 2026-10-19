# FR-149: Mobile Shipping Path — iPhone & Android

- **ID:** FR-149
- **Status:** Proposed (2026-10-19). Companion to FR-148 (mobile
  enfilade): FR-148 builds the engine; this FR ships it to stores.
- **Depends on:** FR-88 (engine extraction), FR-148a/b (wasm build,
  viewer)
- **Commercial frame:** App Store/Play are the primary revenue
  channel. Free reader + Pro subscription (IAP). The server never
  handles money — Apple/Google take payment, the shell gates
  capability. Branding: **Xudanu** (with the existing Project Xanadu
  non-affiliation disclaimer carried into store listings).

## 1. Architecture (one codebase, three targets)

```
        Rust engine (enfilade, crums, chunk store, verify)
           │            │                │
      wasm32 ──────► native ──────► native
           │            │                │
   TS shell (React)  Tauri (mac/     (server — not shipped)
           │          win/linux)
   Capacitor wrapper
     ├─ iOS app (App Store)
     └─ Android app (Play Store)
```

- The TS shell is identical on all targets — desktop browser, PWA,
  iOS, Android.
- Mac/desktop: browser first; optional Tauri shell compiles the
  engine NATIVELY (no wasm) later — optimization, not a fork.
- Mobile: Capacitor wraps the same web build; the engine runs as
  wasm inside the webview. One wrapper, two stores.

## 2. Why Capacitor (decision record)

| Option | Verdict |
|---|---|
| Capacitor | ✅ chosen — mature iOS/Android, huge plugin ecosystem (IAP, filesystem, share), webview-first matches the wasm plan |
| Tauri v2 | strong on desktop; mobile still maturing — revisit for the Mac-native shell |
| React Native/Expo | ✗ abandons the TS web app and duplicates UI |
| Swift + Kotlin native | ✗ two rewrites, loses the engine |

## 3. Phases

### Phase 0 — prerequisites (can start today, $0)
- Apple ID + Xcode; free provisioning runs on your own iPhone
  (7-day re-sign) — develop BEFORE paying
- Android Studio + emulator (free)
- At TestFlight: Apple Developer Program ($99/yr); at Play upload:
  Play Console ($25 one-time)
- iPhone test device on a recent iOS; one Android device/emulator

### Phase 1 — engine to wasm (FR-148a + harness)
- `cargo build --target wasm32-unknown-unknown`; the compiler's
  error list IS the FR-88 worklist (fs/time/rand boundaries)
- wasm-bindgen surface (~20 exports); known-value tests must pass
  bit-identically to native
- Battery/bandwidth harness on recorded traces (FR-148f) — no UI
  without a budget

### Phase 2 — the shell (one app, all platforms)
- Extend `web/app`: engine package + reader UI; PWA manifest +
  service worker (installed PWAs are exempt from Safari's 7-day
  storage eviction — our chunk cache survives)
- Mac/desktop ships from the same build (today's app + engine)

### Phase 3 — Capacitor wrapper
- `npx cap add ios android`; one config, one entitlements story
- IAP via RevenueCat (or StoreKit2/Billing directly later):
  entitlement flag → shell gates Pro features
- Free web build OMITS Pro code entirely (no paywall server-side)

### Phase 4 — store readiness
- StoreKit products: Xudanu Pro (monthly/yearly); Play equivalents
- Screenshots/privacy labels: the honest ones — account-free
  reading, no tracking, storage = downloaded documents only
- App Review notes: reader app + IAP; external links policy
  (readers may browse xan:// content — document it plainly)
- TestFlight internal → external; Play internal testing track

### Phase 5 — launch
- Phased rollout (Store: 1→7→100%); crash + battery telemetry
  minimal and disclosed; price experiments later, polish first

## 4. Risks (honest)

- wasm-in-webview perf on old Androids — the 148f harness gates this
- Apple review variability for a "reader of the web" app — first
  submission may need iteration; start early, submit small
- Engine extraction scope creep — FR-88 stays minimal: move code,
  don't redesign it

## 5. Milestone money map

| Milestone | Invest | Return surface |
|---|---|---|
| Phases 0–2 | $0 | free readers everywhere (audience) |
| Phase 3 | $124 (both dev accounts) | TestFlight/Play beta |
| Phase 4–5 | RevenueCat free tier | Pro subscriptions live |
