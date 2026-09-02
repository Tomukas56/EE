# Progress

## What works locally (verified 2026-09-02 on SM-T585)

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

## Completeness vs PRD (honest)

| Capability | Spec | Reality | Score |
|------------|------|---------|-------|
| Station list + detail | Required | Live API + UI | **Done** |
| Map with pins | Required | Google Maps + station pins | **Done** (lab UI approved) |
| Filters (type, kW, distance) | Required | Country, plug, min kW, search; radius via zoom | **Lab done** |
| Nearest station | Required | Map `nearest=1` | **Done** |
| Auth (Google/Apple/email) | Required | Local device session; Firebase SHA-1 missing | **Lab only** |
| Vehicle profile | Mandatory | Saved on device | **Lab done** |
| Route planning | Core | Map + Directions or Nominatim + Navigate | **Lab done** |
| Session start/stop | Core | Lab DB estimate, not CPO | **Lab done** |
| Payments | Core | History = lab-estimate; wallet banner; no Stripe | **Partial** |
| Real CPO / OCPI | Planned | OCM static POIs; occupancy UNKNOWN | **Partial** |
| Users table / JWT | Architecture | reporter_id string only | **Not started** |
| Tests | Engineering | `npm test` is a stub | **Not started** |
| Docker Compose | Dev env | Colima + `./scripts/db-up.sh`, API on :5433 | **Lab done** |

**Overall vs full PRD: ~35–40%.**  
**Vs Phase-1 backend MVP (stations API): ~90%.**  
Store, PCI, CRA, OCPI, iOS are not.

Docs that say “85% / production-ready” overstate production readiness.

## Left to build
Tracked locally in `docs/specs/PROBLEMS.txt` (gitignored, not on GitHub).
