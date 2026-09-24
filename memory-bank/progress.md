# Progress

## What works locally

### Code complete (2026-09-21)

### Backend
- PostgreSQL schema: `station`, `connector`, `charging_session`, crowd tables
- SyncWorker pulls Open Charge Map LT/LV/EE/PL on boot and daily 02:00 → ~2590 mappable
- `GET /api/stations` includes `connector_types` and `max_power_kw`
- `POST /api/sessions`, `GET /api/sessions?reporterId=`, `POST /api/sessions/:id/stop` (lab estimate)
- Helmet, CORS
- Stripe payment routes exist but are inert without a secret key
- `npm run dev` = `tsx watch src/index.ts`
- CVE lab gate: Snyk (`scripts/scan-cve.sh`) + OSV + npm audit; CycloneDX in `docs/sbom/`

### Mobile (map chrome approved by user — “vaizdas patrauklus ir aiškus”)
- Welcome (motto, Google + lab fallback, Skip = map-only guest)
- Home: Stations · Trip · **Payments** · Account
- Google Map: search suggestion list (diacritic-insensitive: `Raciu`/`Račių`); **right** rail = country / plug / kW + zoom/location
- Home tiles: equal title size (Owner review no longer shrinks)
- List + filters, detail with Start/Stop, Mark a new station, Owner review inbox
- Trip planner: route polyline map + Navigate (Google Maps, waypoint if stop)
- Charging / payment history from API; Payments shows wallet-not-linked banner
- Sign out closes the app; Skip Sign in returns to welcome
- **Offline mode** (§2.7, 2026-09-21):
  - SQLite cache (`offline_stations.db`) for regional data (LT/LV/EE/PL/ALL)
  - Account → Offline Maps: download/update/delete with size estimates
  - Manual force offline toggle with disclaimer dialog
  - Banner shows online/offline status, data age, 7-day warning
  - Auto-fallback to cache when network unavailable
  - "Go" button on station card → in-app route planner (not Google Maps)

## Completeness vs PRD (honest)

| Capability | Spec | Reality | Score |
|------------|------|---------|-------|
| Station list + detail | Required | Live API + UI | **Done** |
| Map with pins | Required | Google Maps + station pins | **Done** (lab UI approved) |
| Filters (type, kW, distance) | Required | Country, plug, min kW, € min–max, search | **Lab done** |
| Nearest station | Required | Map `nearest=1` | **Done** |
| **Offline mode** | **PRD §2.7** | **sqflite cache, Account → Offline Maps, banner** | **Code done 2026-09-16** |
| Auth (Google/Apple/email) | Required | Local device session; Firebase SHA-1 missing | **Lab only** |
| Vehicle profile | Mandatory | Saved on device | **Lab done** |
| Route planning | Core | Map + Directions or Nominatim + Navigate | **Lab done** |
| Session start/stop | Core | Lab DB estimate, not CPO | **Lab done** |
| Payments | Core | History = lab-estimate; wallet banner; no Stripe | **Partial** |
| Real CPO / OCPI | Planned | Via Lietuva open OCPI (LT live status/price); OCM LV/EE/PL | **Lab partial** |
| Online ingest (PRD §10) | Required for production | VL POLL on this Mac; no VPS/PostGIS | **Lab started** |
| Users table / JWT | Architecture | reporter_id string only | **Not started** |
| Tests | Engineering | `npm test` is a stub | **Not started** |
| Docker Compose | Dev env | Colima + `./scripts/db-up.sh`, API on :5433 | **Lab done** |

**Overall vs full PRD: ~48%** (offline mode +3%).  
**Vs Phase-1 backend MVP (stations API): ~90%.**  
Store, PCI, CRA, CPO start/stop, iOS are not.

## Implementation Roadmap

**Created**: 2026-09-24  
**Document**: `docs/IMPLEMENTATION_PLAN.md`  
**Timeline**: 17-21 weeks (~4-5 months)  
**Current Phase**: Pre-Phase 1 (Planning Complete)

### 11 Phases to Production:

1. **Backend Cloud Migration** 🔴 CRITICAL (2-3 weeks)
   - VPS setup, PostgreSQL/PostGIS, Nginx, CI/CD
2. **Authentication & Security** 🔴 CRITICAL (2 weeks)
   - JWT, 2FA, OAuth (Google/Apple), biometrics
3. **Real-Time OCPI Integration** 🔴 CRITICAL (3-4 weeks)
   - Via Lietuva, LV/EE/PL feeds, occupancy, tariffs
4. **Charging Session Management** 🔴 CRITICAL (2 weeks)
   - Start/stop sessions, real-time monitoring, history
5. **Stripe Payment Integration** 🔴 CRITICAL (2 weeks)
   - Apple Pay, Google Pay, invoices, webhook handling
6. **iOS Support** 🟡 HIGH (1-2 weeks)
   - Xcode, App Store submission
7. **Testing & QA** 🔴 CRITICAL (2 weeks)
   - Unit, integration, load, UAT (beta testers)
8. **Performance & Optimization** 🟢 MEDIUM (1 week)
   - Redis caching, indexing, monitoring
9. **Documentation & Compliance** 🔴 CRITICAL (1 week)
   - API docs, legal, GDPR, CRA finalization
10. **Launch Preparation** 🔴 CRITICAL (1 week)
    - App Store submissions, production checklist
11. **Post-Launch** 🟢 MEDIUM (Ongoing)
    - Support, feature enhancements, maintenance

See full plan with 200+ detailed tasks in `docs/IMPLEMENTATION_PLAN.md`.

## Left to build
Driver accents U1–U4 are covered in the implementation plan phases 3-4 (OCPI integration + session management).
Production requirements (§10 PRD) are addressed in Phase 1-3.
Full task tracking in `docs/IMPLEMENTATION_PLAN.md` (not on GitHub yet - will be tracked via GitHub Projects).
