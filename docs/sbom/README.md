# Energy Eniwhere — Software Bill of Materials

**Format:** CycloneDX 1.6 JSON  
**CRA control:** C-02 (Annex I Part II — identify and document components)  
**Regime:** Laboratory snapshot. Regenerated SBOM + local CVE gate (`./scripts/scan-cve.sh`). Not a CE file or store-release attestation.

Regenerate **for the build you ship**. A store listing needs an SBOM that matches that version’s lockfiles.

## Files

| File | Source | Components (this snapshot) |
|------|--------|----------------------------|
| [ee-backend.cdx.json](ee-backend.cdx.json) | `backend/package-lock.json` | 181 |
| [ee-mobile.cdx.json](ee-mobile.cdx.json) | `mobile/pubspec.lock` | 136 |

Not in these files: `.env`, `mobile/android/build/`, Colima VM image, Open Charge Map station rows.

## Regenerate

Needs Node/`npx` (this Mac: Node 23). From the repo root:

```bash
./scripts/generate-sbom.sh
```

Uses `@cdxgen/cdxgen@13.0.1` with `--spec-version 1.6`. On Node 23 you may see `EBADENGINE` warnings; the BOM still validates.

## Third-party services (not lockfile packages)

CRA due diligence also covers remote processing and runtimes. These are **not** CycloneDX `library` rows:

| Component | Role | Notes |
|-----------|------|--------|
| Node.js v23.11.0 | API runtime | Lab host; production runtime TBD |
| Flutter 3.32.8 / Dart 3.8.1 | App SDK | Pinned for macOS 13; do not `flutter upgrade` here |
| PostgreSQL (Postgres.app 18.3, port 5434) | Station/session data | Lab; Compose/Colima not the live API DB |
| Open Charge Map | Station POI sync | Static catalogue; occupancy not live |
| Google Maps Platform | Map tiles / Directions | API key in the client — restrict before store |
| Firebase Auth / Google Sign-In | Account | Android `oauth_client` empty until SHA-1 in console |
| Stripe | Payments (skeleton) | `STRIPE_SECRET_KEY` empty; no live charges |
| Nominatim (OSM) | Trip geocode fallback | Used if Directions is denied |

`security@eniwhere.invalid` in BOM metadata is a **placeholder**, not a CVD mailbox.

## CVE scan (lab gate)

**Primary:** [Snyk CLI](https://docs.snyk.io/developer-tools/snyk-cli) (`snyk test` on `backend/package-lock.json`; `snyk sbom test` on the Flutter CycloneDX file).  
**Second opinion:** Google OSV-Scanner on both lockfiles + `npm audit` high/critical.

```bash
./scripts/install-snyk.sh          # once per machine (Intel Mac → ~/.local/bin/snyk)
snyk auth                          # browser login (preferred)
# Optional CI: SNYK_TOKEN in backend/.env only if `snyk whoami` works with that token
./scripts/scan-cve.sh              # fails on Snyk high/critical, OSV, or npm high/critical
```

Backend shortcut: `cd backend && npm run snyk` (needs `snyk` on PATH and `SNYK_TOKEN`). Also `npm run audit`.

Reports (regenerated each scan):

| File | Contents |
|------|----------|
| [cve-snyk.md](cve-snyk.md) | Human note (auth / last Snyk run) |
| [cve-snyk-backend.json](cve-snyk-backend.json) | Snyk npm test JSON |
| [cve-snyk-mobile.json](cve-snyk-mobile.json) | Snyk SBOM test of Flutter CycloneDX (experimental) |
| [cve-osv.md](cve-osv.md) | OSV human table |
| [cve-osv.json](cve-osv.json) | Full OSV JSON |
| [cve-npm-audit.json](cve-npm-audit.json) | npm audit JSON |

Snyk ignores: [`.snyk`](../../.snyk) with a written CRA reason. OSV ignores: [`osv-scanner.toml`](../../osv-scanner.toml).

`EE_CVE_ALLOW=1 ./scripts/scan-cve.sh` writes reports without failing (lab override, not for store).

This Mac has no `dart pub audit` (Dart 3.8). Snyk does not scan `pubspec.lock` with `snyk test`; Dart is covered by the mobile SBOM test plus OSV on `pubspec.lock`.

## What this does not satisfy

- Coordinated vulnerability disclosure (public security@)
- CRA Article 14 24h/72h reporting
- CE marking / EU declaration of conformity (from 11 Dec 2027)

Register: [SECURITY_COMPLIANCE.md](../specs/SECURITY_COMPLIANCE.md).
