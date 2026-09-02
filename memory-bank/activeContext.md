# Active Context

## Focus (2026-09-02) — snapshot locked in
Tablet QA on SM-T585 accepted this lab chrome:

- Map: Google Maps; search match list; country / plug / kW icons on the **right** with `+` `−`, nearest, my location.
- Search is **diacritic-insensitive** (LT/LV/EE/PL): `Raciu` = `Račių`, `c` = `č`.
- Root: Stations · Trip · **Payments** · Account. Menu titles stay the same size (Owner review subtitle no longer shrinks the tile).
- Trip: route map + Navigate. Sign out closes the app.

Do **not** claim done: live Stripe/PCI, OCPI occupancy, iOS, CRA/CE, production HTTPS, Maps key restriction, User JWT.

## Decisions this session
- Map filters stay on the **right** with zoom/location. Do not wrap `GoogleMap` in `Listener` / `GestureDetector`.
- Google Maps OSM fallback: arm only after the map is on screen (~20s), not at `initState`.
- Search folds Baltic/Polish letters in `foldSearchText` (`mobile/lib/utils/geo.dart`); used by map suggestions and the station list.
- Menu cards: do not wrap the whole tile in one `FittedBox` — long subtitles must not scale down the title.
- Lab charging: elapsed hours × max kW, €0.32/kWh, `payment_method: lab-estimate`.
- Flutter **3.32.8 / Dart 3.8.1**. Do not `flutter upgrade`.

## What is running
- API: `node dist/index.js` in `backend/` on port 3000
- DB: Compose on **127.0.0.1:5433** (`./scripts/db-up.sh`)
- Tablet: SM-T585 — `adb reverse tcp:3000 tcp:3000`

## Next work (priority)
1. Continue tablet QA: Trip Navigate, Start/Stop, Payments
2. Firebase SHA-1 + real Google Sign-In
3. Stripe Payment Sheet only after HTTPS + test key
4. CRA Art. 14 playbook before any store listing
5. Tests; DEMO.md still overstates readiness
