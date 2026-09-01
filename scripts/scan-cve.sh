#!/usr/bin/env bash
# Lab CVE gate: Snyk (primary) + OSV (Dart lockfile / second opinion) + npm audit.
# Exit 1 if Snyk high/critical, OSV, or npm high/critical findings.
# Override: EE_CVE_ALLOW=1 ./scripts/scan-cve.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/sbom"
mkdir -p "$OUT"

export PATH="$HOME/.local/bin:$PATH"

snyk_whoami() {
  # Ignore a stale SNYK_TOKEN in the environment — `snyk auth` OAuth is preferred.
  env -u SNYK_TOKEN snyk whoami 2>/dev/null | head -n 1 | tr -d '\r'
}

load_snyk_token() {
  local who
  who="$(snyk_whoami || true)"
  if [[ -n "$who" && "$who" != *"ERROR"* && "$who" != *"Authentication"* ]]; then
    unset SNYK_TOKEN
    echo "Snyk CLI login: $who (OAuth; SNYK_TOKEN not applied)"
    return 0
  fi
  if [[ -n "${SNYK_TOKEN:-}" ]]; then
    echo "Using SNYK_TOKEN from the environment"
    return 0
  fi
  local f val
  for f in "$ROOT/backend/.env" "$ROOT/.env"; do
    [[ -f "$f" ]] || continue
    val="$(grep -E '^[[:space:]]*SNYK_TOKEN=' "$f" 2>/dev/null | tail -n 1 | sed 's/^[[:space:]]*SNYK_TOKEN=//' | sed 's/^["'\'']//;s/["'\'']$//' || true)"
    if [[ -n "$val" ]]; then
      export SNYK_TOKEN="$val"
      echo "Using SNYK_TOKEN from $(basename "$(dirname "$f")")/$(basename "$f")"
      return 0
    fi
  done
}

summarize_snyk_json() {
  python3 - "$1" <<'PY'
import json, sys
from pathlib import Path

path = Path(sys.argv[1])
label = path.name
if not path.exists() or path.stat().st_size == 0:
    print(f"{label}: missing")
    sys.exit(0)

raw = path.read_text().strip()
if not raw:
    print(f"{label}: empty")
    sys.exit(0)

data = json.loads(raw)
if isinstance(data, list):
    blobs = data
else:
    blobs = [data]

high = 0
for blob in blobs:
    if not isinstance(blob, dict):
        continue
    vulns = blob.get("vulnerabilities") or blob.get("issues") or []
    if isinstance(vulns, dict):
        vulns = list(vulns.values()) if vulns else []
    counted = False
    for v in vulns:
        if not isinstance(v, dict):
            continue
        counted = True
        sev = str(v.get("severity") or v.get("effectiveSeverity") or "").lower()
        if sev in ("high", "critical"):
            high += 1
    # --severity-threshold already filtered; uniqueCount is a fallback if the list is absent
    if not counted and blob.get("ok") is False:
        high += int(blob.get("uniqueCount") or 0)

print(f"{label}: high+critical findings={high}")
sys.exit(1 if high else 0)
PY
}

echo "=== Snyk (primary; high+critical) ==="
load_snyk_token
"$ROOT/scripts/install-snyk.sh"

snyk_backend_rc=0
snyk_mobile_rc=0

if ! command -v snyk >/dev/null 2>&1; then
  echo "snyk CLI not on PATH after install-snyk.sh"
  snyk_backend_rc=2
else
  (
    cd "$ROOT/backend"
    snyk test \
      --severity-threshold=high \
      --file=package-lock.json \
      --policy-path="$ROOT/.snyk" \
      --json-file-output="$OUT/cve-snyk-backend.json"
  ) || snyk_backend_rc=$?

  if [[ "$snyk_backend_rc" -eq 2 || "$snyk_backend_rc" -eq 3 ]]; then
    echo "Snyk backend scan error (exit $snyk_backend_rc)."
    echo "Create a token at https://app.snyk.io/account and put SNYK_TOKEN=... in backend/.env (gitignored)."
    cat > "$OUT/cve-snyk.md" <<EOF
# Snyk

Scan did not authenticate (CLI exit $snyk_backend_rc).

1. Open https://app.snyk.io/account
2. Create an API token
3. Add \`SNYK_TOKEN=<token>\` to \`backend/.env\` (gitignored — never commit it)
4. Re-run \`./scripts/scan-cve.sh\`

OSV + npm audit still ran as a second opinion.
EOF
    snyk_mobile_rc="$snyk_backend_rc"
  elif [[ -f "$ROOT/docs/sbom/ee-mobile.cdx.json" ]]; then
    # Flutter/Dart: Snyk does not scan pubspec.lock via `snyk test`. Use the CycloneDX SBOM.
    snyk sbom test \
      --experimental \
      --file="$ROOT/docs/sbom/ee-mobile.cdx.json" \
      --severity-threshold=high \
      --json-file-output="$OUT/cve-snyk-mobile.json" \
      || snyk_mobile_rc=$?
  else
    echo "No docs/sbom/ee-mobile.cdx.json — run ./scripts/generate-sbom.sh first."
    snyk_mobile_rc=2
  fi
fi

snyk_sum_rc=0
summarize_snyk_json "$OUT/cve-snyk-backend.json" || snyk_sum_rc=1
if [[ -f "$OUT/cve-snyk-mobile.json" ]]; then
  summarize_snyk_json "$OUT/cve-snyk-mobile.json" || snyk_sum_rc=1
fi

echo "=== OSV-Scanner (second opinion: package-lock.json + pubspec.lock) ==="
"$ROOT/scripts/install-osv-scanner.sh"
osv_rc=0
osv-scanner scan source \
  --config "$ROOT/osv-scanner.toml" \
  -L "$ROOT/backend/package-lock.json" \
  -L "$ROOT/mobile/pubspec.lock" \
  --format json \
  --output-file "$OUT/cve-osv.json" \
  || osv_rc=$?

osv-scanner scan source \
  --config "$ROOT/osv-scanner.toml" \
  -L "$ROOT/backend/package-lock.json" \
  -L "$ROOT/mobile/pubspec.lock" \
  --format markdown \
  --output-file "$OUT/cve-osv.md" \
  || true

echo "=== npm audit (backend) ==="
npm_rc=0
(
  cd "$ROOT/backend"
  npm audit --json > "$OUT/cve-npm-audit.json" || true
)
python3 - "$OUT/cve-npm-audit.json" <<'PY'
import json, sys
from pathlib import Path
meta = json.loads(Path(sys.argv[1]).read_text()).get("metadata", {}).get("vulnerabilities", {})
high = int(meta.get("high") or 0) + int(meta.get("critical") or 0)
print(f"npm audit: {meta.get('total', 0)} total, high+critical={high}")
sys.exit(1 if high else 0)
PY
npm_rc=$?

python3 - "$OUT" "$osv_rc" "$npm_rc" "$snyk_backend_rc" "$snyk_mobile_rc" <<'PY'
import json
import sys
from pathlib import Path

out = Path(sys.argv[1])
osv_rc = int(sys.argv[2])
npm_rc = int(sys.argv[3])
snyk_backend_rc = int(sys.argv[4])
snyk_mobile_rc = int(sys.argv[5])
osv_path = out / "cve-osv.json"
count = 0
if osv_path.exists():
    data = json.loads(osv_path.read_text() or "{}")
    results = data.get("results") or []
    for result in results:
        for pkg in result.get("packages") or []:
            count += len(pkg.get("vulnerabilities") or [])
    if count == 0:
        vulns = data.get("vulnerabilities") or []
        count = len(vulns)
print(
    f"OSV findings (approx): {count}; osv-scanner exit={osv_rc}; npm audit exit={npm_rc}; "
    f"snyk backend exit={snyk_backend_rc}; snyk mobile SBOM exit={snyk_mobile_rc}"
)
PY

if [[ "${EE_CVE_ALLOW:-}" == "1" ]]; then
  echo "EE_CVE_ALLOW=1 — reports written, not failing the gate."
  exit 0
fi

fail=0
if [[ "$snyk_backend_rc" -ne 0 || "$snyk_mobile_rc" -ne 0 || "$snyk_sum_rc" -ne 0 ]]; then
  fail=1
fi
if [[ "$osv_rc" -ne 0 || "$npm_rc" -ne 0 ]]; then
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "CVE gate failed. Reports: $OUT/cve-snyk-backend.json $OUT/cve-snyk-mobile.json $OUT/cve-osv.md $OUT/cve-npm-audit.json"
  echo "Snyk ignores: .snyk  |  OSV ignores: osv-scanner.toml  |  token: SNYK_TOKEN in backend/.env"
  exit 1
fi

echo "CVE gate passed (Snyk high+critical clean; OSV/npm high+ clean)."
