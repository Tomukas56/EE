# Active Context

## Focus (2026-09-02) — snapshot locked in
Tablet QA on SM-T585 accepted this lab chrome:

- Map: Google Maps; search match list; country / plug / kW icons on the **right** with `+` `−`, nearest, my location.
- Search is **diacritic-insensitive** (LT/LV/EE/PL): `Raciu` = `Račių`, `c` = `č`.
- Root: Stations · Trip · **Payments** · Account. Menu titles stay the same size (Owner review subtitle no longer shrinks the tile).
- Trip: route map + Navigate. Sign out closes the app.

Do **not** claim done: live Stripe/PCI, OCPI occupancy, iOS, CRA/CE, production HTTPS, Maps key restriction, User JWT, **§11 2FA** (specified only — do not implement during lab QA).

## Decisions this session
- Map filters stay on the **right** with zoom/location. Do not wrap `GoogleMap` in `Listener` / `GestureDetector`.
- Google Maps OSM fallback: arm only after the map is on screen (~20s), not at `initState`.
- **Map of stations** can zoom out to the LT/LV/EE/PL region (min zoom 5). **Nearest column** stays street-scale (~2.4 km, min zoom 14). Pins stay capped at 40 for SM-T585 RAM.
- Search folds Baltic/Polish letters in `foldSearchText` (`mobile/lib/utils/geo.dart`); used by map suggestions and the station list.
- Menu cards: do not wrap the whole tile in one `FittedBox` — long subtitles must not scale down the title.
- Lab charging: elapsed hours × max kW, €0.32/kWh, `payment_method: lab-estimate`.
- Flutter **3.32.8 / Dart 3.8.1**. Do not `flutter upgrade`.
- **Offline mode (2026-09-16)**: PRD §2.7. Manual download with confirmation. No auto-refresh. Data expiry warning after 7 days (not auto-deleted). SQLite unencrypted (only public catalogue).

## What is running
- API: `node dist/index.js` in `backend/` on port 3000
- DB: Compose on **127.0.0.1:5433** (`./scripts/db-up.sh`)
- Tablet: SM-T585 — `adb reverse tcp:3000 tcp:3000`

## User accents (2026-09-05) — above other product work
1. **Prices on the map** (pin, not only detail)
2. Filter by **power** and **max €/kWh**
3. **Occupancy** on the chosen station
4. **Start in this app** and live **progress** (kWh / time / cost)

These need PRD §10 (tariff + last-known) then OCPI session. Do **not** implement §11 2FA during lab QA.

## Via Lietuva (2026-09-05)
Lab backend POLLs official `ev.vialietuva.lt/ocpi/2.3.0` (locations + tariffs, CC BY 4.0). App still talks only to our API. LT OCM rows are dropped when VL sync succeeds. Refresh every 5 minutes.

## Next work (priority)
1. ✅ Offline Mode (§2.7) — **COMPLETE (2026-09-21)**
2. ✅ Security Scanning & CVE Management — **COMPLETE (2026-09-24)**:
   - Snyk authentication configured
   - GitHub Actions weekly automated scans
   - 0 high/critical vulnerabilities
   - SBOM updated, CRA compliance documentation
3. ✅ **Implementation Plan Created (2026-09-24)** — See `docs/IMPLEMENTATION_PLAN.md`
   - 11-phase roadmap (17-21 weeks, ~4-5 months)
   - Detailed tasks, priorities, dependencies
   - Resource requirements, cost estimates
   - Risk assessment

## Immediate Next Steps (Phase 1: Backend Cloud)
1. 🔴 **VPS Server Setup** (OVH/Hetzner: 2 vCPU, 4 GB RAM)
2. 🔴 **PostgreSQL/PostGIS Production** (Docker, backups, monitoring)
3. 🔴 **Nginx + HTTPS** (Let's Encrypt, reverse proxy)
4. 🔴 **Backend Deployment** (PM2/systemd, environment variables)
5. 🔴 **Data Migration** (local → production)
6. 🔴 **CI/CD Setup** (GitHub Actions deployment workflow)

See `docs/IMPLEMENTATION_PLAN.md` for full 11-phase plan.
