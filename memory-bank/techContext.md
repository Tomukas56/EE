# Tech Context

## Local machine (2026-09-02)
| Tool | Status |
|------|--------|
| macOS | 13.7.8 Ventura (darwin-x64) |
| Node | v23.11.0 |
| Flutter | **3.32.8 / Dart 3.8.1** — do **not** `flutter upgrade` (3.47 needs macOS 14+) |
| Docker | **Colima v0.10.3**. Start: `colima start --vm-type vz` or `./scripts/db-up.sh`. Socket: `unix://$HOME/.colima/default/docker.sock` |
| PostgreSQL | **Live API:** Compose `postgres:18-alpine` on **127.0.0.1:5433**. Postgres.app is not used. Volume: `/var/lib/postgresql` (PG18). |
| Android | Samsung SM-T585 (Android 8.1, serial `330039b62585a5df`) |
| Xcode | Incomplete — no iOS builds |

## Runtime configuration (gitignored)
- Root `.env`: Docker Compose `DB_USER` / `DB_PASSWORD` / `DB_NAME`
- `backend/.env`: `DATABASE_URL` → `127.0.0.1:5433/energy_db`
- `STRIPE_SECRET_KEY` empty — payment routes return 500 until a test key is added
- Maps key is in `AppConfig` / AndroidManifest (must be restricted before store)

## How to run
```bash
# API (Compose Postgres on 5433)
./scripts/db-up.sh
cd backend && npm start          # http://0.0.0.0:3000

# Tablet
adb reverse tcp:3000 tcp:3000
cd mobile && flutter run -d 330039b62585a5df
```

Lab path: Welcome (Agreement + Google / Skip) → Menu → Stations → Map of stations.
