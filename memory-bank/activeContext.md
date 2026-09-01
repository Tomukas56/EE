# Active Context

## Focus (2026-09-01)
Laboratory functions that can run without Stripe / Firebase SHA-1 / Docker / OCPI: vehicle persist, connector/kW filters, lab charging sessions, history from API, trip planner, `npm run dev`.

Do **not** claim done: live Stripe/PCI, OCPI occupancy, iOS, CRA/CE, production HTTPS, Maps key restriction, User JWT, Docker.

## Decisions this session
- Lab charging is local DB only: energy = elapsed hours × max connector kW (min 1 minute), €0.32/kWh, `payment_method: lab-estimate`.
- Vehicle profile stays on-device (SharedPreferences), not a User table.
- Trip planner uses Google Directions when the existing Maps key allows it; otherwise Nominatim + 1.3× straight-line.
- Filters: country + connector type + min kW. Operator is the existing search field.
- `npm run dev` is `tsx watch src/index.ts`. Production-style lab still uses `npm start` after `tsc`.

## What is running
- API: `node dist/index.js` in `backend/` on port 3000 (`0.0.0.0`)
- DB: `energy_db` on 127.0.0.1:5434
- Last OCM sync: **2590** mappable (LT ~1909, LV ~93, EE ~170, PL ~418); public list ~2543
- Tablet: Samsung SM-T585 — `adb reverse tcp:3000 tcp:3000`

## Next work (priority)
1. Put `SNYK_TOKEN` in `backend/.env` and run `./scripts/scan-cve.sh` (Snyk is the primary CVE gate)
2. Laboratory QA on the tablet: Start/Stop, history, filters, vehicle, Vilnius→Riga trip
3. Firebase SHA-1 + real Google Sign-In (then remove local bypass for store)
4. Stripe Payment Sheet only after HTTPS + test key
5. CRA Art. 14 playbook before any store listing
6. Tests; DEMO.md still overstates readiness

Crowd stations: pending until owner PIN (`APP_OWNER_PIN`, lab default `2468`) confirms physical location.

Do not treat DEMO.md “85% complete / production-ready” as accurate — see `progress.md`.
