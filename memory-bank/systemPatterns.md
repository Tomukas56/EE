# System Patterns

## Architecture
Hybrid aggregator (ADR-001):
- **Static data** (name, address, lat/lng, connectors) stored in PostgreSQL, synced periodically from Open Charge Map.
- **Dynamic data** (availability) is specified as on-demand CPO fetch — currently occupancy is **UNKNOWN**.

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
- No PostGIS in the live schema (lat/lng `Decimal`). Distance filters computed in the app.
- Public `GET /api/stations` omits pending crowd pins until owner PIN confirm.

## Known repo quirks
- Task Master is initialized but has **no tasks**.
- `docs/DEMO.md` and older READMEs still describe 7 mock stations / History tile — treat `progress.md` as honest status.
