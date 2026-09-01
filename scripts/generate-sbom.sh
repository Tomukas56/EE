#!/usr/bin/env bash
# Generate CycloneDX 1.6 SBOMs for the Energy Eniwhere API and Flutter app.
# Requires Node/npx. Regenerates docs/sbom/*.cdx.json from lockfiles.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/sbom"
mkdir -p "$OUT"

# v13 wants Node 24+; Node 23 still generates a valid 1.6 BOM (engine warning only).
CDXGEN=(npx --yes @cdxgen/cdxgen@13.0.1)

echo "Generating backend SBOM from package-lock.json..."
"${CDXGEN[@]}" \
  -t npm \
  --spec-version 1.6 \
  -o "$OUT/ee-backend.cdx.json" \
  "$ROOT/backend"

echo "Generating mobile SBOM from pubspec.lock..."
"${CDXGEN[@]}" \
  -t pub \
  --spec-version 1.6 \
  -o "$OUT/ee-mobile.cdx.json" \
  "$ROOT/mobile"

python3 - "$OUT" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

out = Path(sys.argv[1])

def stamp(path: Path, *, name: str, version: str, purl: str, description: str) -> None:
    data = json.loads(path.read_text())
    meta = data.setdefault("metadata", {})
    meta["timestamp"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    meta["supplier"] = {
        "name": "Energy Eniwhere",
        "url": ["https://github.com/Tomukas56/EE"],
        "contact": [{"name": "Energy Eniwhere", "email": "security@eniwhere.invalid"}],
    }
    meta["authors"] = [{"name": "Energy Eniwhere"}]
    meta["properties"] = [
        {"name": "ee:regime", "value": "lab"},
        {
            "name": "ee:note",
            "value": "Inventory only. Not a CVE gate, CE declaration, or store-release SBOM.",
        },
    ]
    component = meta.setdefault("component", {})
    component["type"] = "application"
    component["name"] = name
    component["version"] = version
    component["group"] = "com.eniwhere.energy"
    component["purl"] = purl
    component["description"] = description
    component["manufacturer"] = {"name": "Energy Eniwhere"}
    path.write_text(json.dumps(data, indent=2) + "\n")
    comps = data.get("components") or []
    print(f"{path.name}: spec {data.get('specVersion')} · {len(comps)} components")

stamp(
    out / "ee-backend.cdx.json",
    name="energy-eniwhere-api",
    version="1.0.0",
    purl="pkg:generic/com.eniwhere.energy/api@1.0.0",
    description="Energy Eniwhere Node.js API (remote data processing for the mobile app).",
)
stamp(
    out / "ee-mobile.cdx.json",
    name="energy-eniwhere-app",
    version="1.0.0+1",
    purl="pkg:generic/com.eniwhere.energy/app@1.0.0+1",
    description="Energy Eniwhere Flutter app (com.eniwhere.energy).",
)
PY

echo "Wrote $OUT/ee-backend.cdx.json and $OUT/ee-mobile.cdx.json"
