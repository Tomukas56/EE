# System Patterns

## Architecture
**Production (PRD §10):** app never calls CPO APIs. Connectors → Sync → Normalizer → Duplicate Resolver → PostgreSQL/PostGIS → our REST API → Flutter. Last-known occupancy + `last_updated`. DFD: `docs/specs/DFD.md`. Target host: OVH VPS, FastAPI, Nginx, Docker.

**Lab (today):**
Hybrid aggregator (ADR-001, occupancy path updated 2026-09-03):
- **Static data** from Open Charge Map into PostgreSQL.
- **Dynamic data** specified as last-known in EE DB — currently occupancy is **UNKNOWN** (no CPO PUSH/POLL yet).

```
Flutter app  --HTTP-->  Express API  -->  Prisma  -->  PostgreSQL
                              |
                         SyncWorker (cron 02:00 + on boot)
                              |
                         CPOService → Open Charge Map /v3/poi (LT, LV, EE, PL)
```

## Backend
- Node.js 22+/23, TypeScript, Express 5, ESM (`"type": "module"`)
- Prisma: `Station`, `Connector`, charging sessions, crowd submissions / check-ins
- Helmet + CORS
- Payments isolated in `PaymentService`. Stripe client is created only when a key exists.

## Mobile
- Flutter 3.32.8, Riverpod, GoRouter, `google_maps_flutter` + `flutter_map` OSM fallback
- Physical Android uses `AppConfig.lanApi` (`http://192.168.1.228:3000`) or `adb reverse tcp:3000`
- Map: do **not** wrap `GoogleMap` in pointer interceptors. Filters + zoom live in one **right** `Positioned` column.
- Search: `foldSearchText` in `geo.dart` (LT/LV/EE/PL diacritics). Menu tiles: do not wrap the whole card in one `FittedBox`.
- Session: SharedPreferences; Google Sign-In attempted, lab-device fallback on ApiException 10
- Firebase Auth is not a store-ready OIDC flow until SHA-1 is in Firebase

## Data rules
- No PostGIS in the **lab** schema (lat/lng `Decimal`). Production requires PostGIS (PRD §10).
- Public `GET /api/stations` omits pending crowd pins until owner PIN confirm.

## Known repo quirks
- Task Master is initialized but has **no tasks**.
- Treat `progress.md` as honest status (not old “85% / 7 mock stations” claims).
