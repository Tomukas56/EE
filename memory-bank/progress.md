# Progress

## What works locally (verified 2026-09-01)

### Backend
- PostgreSQL schema: `station`, `connector`, `charging_session`, crowd tables
- SyncWorker pulls Open Charge Map LT/LV/EE/PL on boot and daily 02:00 → ~2590 mappable
- `GET /api/stations` includes `connector_types` and `max_power_kw`
- `POST /api/sessions`, `GET /api/sessions?reporterId=`, `POST /api/sessions/:id/stop` (lab estimate)
- Helmet, CORS
- Stripe payment routes exist but are inert without a secret key
- `npm run dev` = `tsx watch src/index.ts`
- CVE lab gate: Snyk (`scripts/scan-cve.sh`) + OSV + npm audit; CycloneDX in `docs/sbom/`

### Mobile
- Screens: welcome, vehicle (persisted), home, list + filters, detail with Start/Stop, Google Map, trip planner, charging/payment history from API
- Search, country, connector, min kW filters
- External navigation / call / website from detail
- Google Maps key is wired. Google Sign-In still needs SHA-1 in Firebase.

## Completeness vs PRD (honest)

| Capability | Spec | Reality | Score |
|------------|------|---------|-------|
| Station list + detail | Required | Live API + UI | **Done** |
| Map with pins | Required | Google Maps + station pins | **Done** |
| Filters (type, kW, distance) | Required | Country, plug, min kW, search; radius via zoom | **Lab done** |
| Nearest station | Required | Map `nearest=1` | **Done** |
| Auth (Google/Apple/email) | Required | Local device session; Firebase SHA-1 missing | **Lab only** |
| Vehicle profile | Mandatory | Saved on device | **Lab done** |
| Route planning | Core | Directions or Nominatim + one suggested stop | **Lab done** |
| Session start/stop | Core | Lab DB estimate, not CPO | **Lab done** |
| Payments | Core | History = lab-estimate; no Stripe | **Partial** |
| Real CPO / OCPI | Planned | OCM static POIs; occupancy UNKNOWN | **Partial** |
| Users table / JWT | Architecture | reporter_id string only | **Not started** |
| Tests | Engineering | `npm test` is a stub | **Not started** |
| Docker Compose | Dev env | Docker not on this Mac | **Blocked locally** |

**Overall vs full PRD: ~35–40%.**  
**Vs Phase-1 backend MVP (stations API): ~90%.**  
Lab sessions/history/filters/vehicle/trip are usable on the tablet. Store, PCI, CRA, OCPI, iOS are not.

Docs that say “85% / production-ready” overstate production readiness.

## Left to build
Tracked locally in `docs/specs/PROBLEMS.txt` (gitignored, not on GitHub).
