# System Patterns

## Architecture
Hybrid aggregator (ADR-001):
- **Static data** (name, address, lat/lng, connectors) stored in PostgreSQL, synced periodically.
- **Dynamic data** (availability) should be fetched on demand — currently the mock sync writes status into the same tables.

```
Flutter app  --HTTP-->  Express API  -->  Prisma  -->  PostgreSQL
                              |
                         SyncWorker (cron 02:00 + on boot)
                              |
                         CPOService → Open Charge Map /v3/poi (country=LT)
```

## Backend
- Node.js 22+/23, TypeScript, Express 5, ESM (`"type": "module"`)
- Prisma 5.22, models `Station` and `Connector` only
- Helmet + CORS
- Payments isolated in `PaymentService` (Stripe). Stripe client is created only when a key exists so the API can boot without payments.

## Mobile
- Flutter, Riverpod, GoRouter
- API client: `ApiService` → `http://localhost:3000`
- Firebase Auth / Google Sign-In / Stripe packages are in `pubspec.yaml` but **not wired for local demo** (`Firebase.initializeApp` is commented out; auth stream returns `null`)
- Map screen is a placeholder list, not Google Maps

## Data rules
- No PostGIS in the live schema (lat/lng `Decimal`). Distance filters must be computed in app or SQL later.
- Sync upserts by station **name**, then deletes/recreates connectors (IDs change every sync).

## Known repo quirks
- Nested copy `OneDrive - teltonika.lt/Documents/ENERGY/` is a duplicate of the project and should not be treated as source.
- `npm run dev` points at `src/index.js` (wrong); use `npm run build && npm start`.
- Task Master is initialized but has **no tasks**.
