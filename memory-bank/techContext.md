# Tech Context

## Local machine (2026-08-31)
| Tool | Status |
|------|--------|
| macOS | 13.7.8 Ventura (darwin-x64) |
| Node | v23.11.0 |
| Flutter | **3.32.8 / Dart 3.8.1** — latest Flutter (3.47) requires macOS 14+ |
| Docker | **Colima v0.10.3** (not Docker Desktop). CLI in `~/.local/bin`. Engine: Ubuntu 24.04 VM via macOS Virtualization. Start: `colima start --vm-type vz`. Socket: `unix://$HOME/.colima/default/docker.sock` |
| PostgreSQL | Postgres.app **18.3 on port 5434** (Homebrew `@14` is installed but not running) |
| Android Studio / SDK | Present (android-36) |
| Chrome | Present — web target available |
| Xcode | Incomplete — no iOS builds |
| Homebrew | Broken (needs Ruby 4.0) — do not rely on `brew services` |

## Runtime configuration (gitignored)
- Root `.env`: Docker Compose DB vars (optional; live API uses Postgres.app on 5434, not Compose)
- `backend/.env`: `DATABASE_URL` → `127.0.0.1:5434/energy_db`, user `energy_admin_secure`
- `STRIPE_SECRET_KEY` empty — payment routes return 500 until a test key is added
- `SNYK_TOKEN` in `backend/.env` for `./scripts/scan-cve.sh` (never commit; https://app.snyk.io/account)

## Flutter constraint
`pubspec.yaml` originally required Dart `^3.10.3`. On this Mac it is relaxed to `>=3.8.0 <4.0.0` and `google_fonts` is pinned to `6.2.1`.

## How to run
```bash
# API (already applied migrations once)
cd backend && npm start          # http://localhost:3000

# App
cd mobile && flutter run -d chrome
# or an Android emulator / device (use 10.0.2.2 instead of localhost)
```

Demo path in the app: Welcome → **Setup Vehicle Profile** (skips Google Sign-In) → Home → Charging Stations.
