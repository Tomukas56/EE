# Progress

## What works locally (verified 2026-08-31)

### Backend
- PostgreSQL schema (`station`, `connector`) including `external_id` for OCM
- SyncWorker pulls **Open Charge Map** Lithuania POIs on boot and daily 02:00 → **1908 stations**
- `GET /` health
- `GET /api/stations` list with availability counts (OCM occupancy is `UNKNOWN`, so available counts stay 0)
- `GET /api/stations/:id` detail with connectors
- Helmet, CORS
- Stripe payment routes exist but are inert without a secret key

### Mobile (code compiles; `flutter analyze` = 0 errors, 1 warning, infos)
- Screens: welcome, vehicle form, home (root/submenu), list, detail, Google Map with station pins, route planner UI, charging history, payment history
- List/detail talk to the live API
- Search on the list (client-side)
- External navigation / call / website from detail
- Google Maps key is wired (Android / web / iOS). Google Sign-In still needs SHA-1 in Firebase.

## Completeness vs PRD (honest)

| Capability | Spec | Reality | Score |
|------------|------|---------|-------|
| Station list + detail | Required | Live API + UI | **Done** |
| Map with pins | Required | Google Maps + station pins | **Done** |
| Filters (type, kW, distance) | Required | Name/address search only | **Partial** |
| Nearest station | Required | “Coming soon” | **Not started** |
| Auth (Google/Apple/email) | Required | Packages present, Firebase disabled | **UI only** |
| Vehicle profile | Mandatory | Form exists, not persisted | **UI only** |
| Route planning | Core | Fake “1 stop” snackbar | **UI only** |
| Session start/stop | Core | No API, no UI action | **Not started** |
| Payments | Core | Stripe skeleton + mock history | **Partial backend** |
| Real CPO / OCPI | Planned | Open Charge Map static POIs (LT); no OCPI occupancy | **Partial** |
| Users / sessions tables | Architecture | Not in Prisma | **Not started** |
| Tests | Engineering | `npm test` is a stub | **Not started** |
| Docker Compose | Dev env | File exists; Docker not on this Mac | **Blocked locally** |

**Overall vs full PRD: ~30–35%.**  
**Vs Phase-1 backend MVP (stations API): ~90%.**  
**Vs Flutter shell / demo screens: ~70% UI, ~25% real data.**

Docs that say “85% / production-ready” describe a Windows demo snapshot and overstate production readiness (no auth, no sessions, no tests, mock payments, no real CPOs).

## Left to build
See the action plan in `activeContext.md` and the session reply. Highest leverage after local bring-up: map + geo API, real auth/vehicle persistence, then sessions/payments, then OCPI.
