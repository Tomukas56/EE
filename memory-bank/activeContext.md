# Active Context

## Focus (2026-08-31)
Google account is required before any charging UI. After sign-in, home is a **root menu** (Stations, Trip, History, Account) whose tiles fill the window; each opens a **submenu**. Android Google Sign-In still needs SHA-1 in Firebase (`oauth_client` is empty). iOS needs a real OAuth client + matching bundle ID.

## Decisions this session
- Use **Postgres.app on 5434** instead of Docker (Docker is not installed; schema does not need PostGIS).
- Keep Stripe **optional** so the API boots without `STRIPE_SECRET_KEY`.
- Stay on **Flutter 3.32.8** (macOS 13). Do not `flutter upgrade` until the OS is 14+.
- Pin `google_fonts` to 6.2.1 and relax the Dart SDK constraint so `flutter pub get` works.
- Station static data comes from **Open Charge Map**; occupancy is stored as `UNKNOWN`.
- Stations keyed by `external_id` = `ocm:{id}`.
- Map: **Google Maps** (`google_maps_flutter`) with the Cloud Maps key in AndroidManifest, `web/google_maps_key.js`, iOS `AppDelegate`, and `AppConfig`. OSM/Carto remains the fallback if the key is cleared.
- Dark theme uses `#F5F5F7` / `#D1D1D6` on dark surfaces — never black or mid-gray text on black.
- Sign-in screen includes **Sutartis** (service rules) and **README** (what the app is / how to use it). Google is enabled only after the user ticks agreement.
- Chrome Google Maps JS key lives in `mobile/web/google_maps_key.js` (empty = keep OSM).

## What is running
- API: `npm start` in `backend/` on port 3000 (`0.0.0.0`)
- DB: `energy_db` on 127.0.0.1:5434
- Last OCM sync: **1914** Lithuanian stations (mock 7 rows removed)

## Next work (priority)
1. Persist users + vehicles (Firebase or backend JWT) — crowd APIs still have no user JWT
2. Geo / connector filters on `GET /api/stations`
3. Route planner (Directions API + energy model)
4. Stripe Payment Sheet + Apple Pay / Google Pay (see docs/PRD.md §7)
5. Close GDPR / TLS / MASVS gaps in docs/PRD.md §6 before any store release
6. Remove the nested OneDrive duplicate from the repo
7. Tests and a working `npm run dev`

Crowd stations: pending until owner PIN (`APP_OWNER_PIN`, lab default `2468`) confirms physical location. Arrival check-ins: working + free connectors (Yes/No/Dismiss).

Do not treat DEMO.md “85% complete / production-ready” as accurate — see `progress.md`.
