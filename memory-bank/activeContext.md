# Active Context

## Focus (2026-09-02)
Tablet QA on SM-T585: map chrome approved — compact country / plug / kW icons on the **right**, same column as `+` `−`, nearest, my location. Google Maps loads. Search lists name/address matches.

Do **not** claim done: live Stripe/PCI, OCPI occupancy, iOS, CRA/CE, production HTTPS, Maps key restriction, User JWT.

## Decisions this session
- Map filters stay on the **right** with zoom/location (not the left). Do not wrap `GoogleMap` in `Listener` / `GestureDetector` — that blanks the Android platform view.
- Google Maps fallback to OSM must **not** start at `initState`; arm it only after the map widget is on screen, and wait ~20s (GPS + Maps SDK on SM-T585 is slow).
- Lab charging is local DB only: energy = elapsed hours × max connector kW (min 1 minute), €0.32/kWh, `payment_method: lab-estimate`.
- Vehicle profile stays on-device (SharedPreferences), not a User table.
- Root menu: Stations · Trip · **Payments** (subtitle Sessions · History) · Account. History tile renamed.
- Payments screen shows device wallet binding (Android Google Wallet/Pay, iOS Apple Wallet/Pay). Lab = not linked.
- Owner review is the **owner PIN inbox** for crowd-marked stations; unpublished until confirm.
- Signed-in **Sign out** ends the session and `SystemNavigator.pop()` (closes the app). Skip **Sign in** only returns to welcome.
- Trip planner shows a route map + **Navigate** (Google Maps directions; waypoint if a charging stop exists).
- Flutter **3.32.8 / Dart 3.8.1**. Do not `flutter upgrade` on this Mac.

## What is running
- API: `node dist/index.js` in `backend/` on port 3000 (`0.0.0.0`)
- DB: Compose `energy_eniwhere_db` on **127.0.0.1:5433** (`./scripts/db-up.sh`).
- Last OCM sync: **~2590** mappable (LT ~1909, LV ~93, EE ~170, PL ~418)
- Tablet: Samsung SM-T585 — `adb reverse tcp:3000 tcp:3000`; `flutter run -d 330039b62585a5df`
- Debug session often logs `Lost connection to device` when the tablet is backgrounded; the APK stays installed.

## Next work (priority)
1. Continue tablet QA: Trip Navigate, Start/Stop, Payments, Sign out
2. Firebase SHA-1 + real Google Sign-In (then remove local bypass for store)
3. Stripe Payment Sheet only after HTTPS + test key
4. CRA Art. 14 playbook before any store listing
5. Tests; DEMO.md still overstates readiness

Crowd stations: pending until owner PIN (`APP_OWNER_PIN`, lab default `2468`) confirms physical location.

Do not treat DEMO.md “85% complete / production-ready” as accurate — see `progress.md`.
