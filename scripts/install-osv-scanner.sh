#!/usr/bin/env bash
# Install Google OSV-Scanner into ~/.local/bin (Intel macOS). Not committed to git.
set -euo pipefail

VERSION="${OSV_SCANNER_VERSION:-v2.5.0}"
BIN="${OSV_SCANNER_BIN:-$HOME/.local/bin/osv-scanner}"
URL="https://github.com/google/osv-scanner/releases/download/${VERSION}/osv-scanner_darwin_amd64"

mkdir -p "$(dirname "$BIN")"

if [[ -x "$BIN" ]] && "$BIN" --version 2>/dev/null | grep -q "${VERSION#v}"; then
  echo "osv-scanner already ${VERSION} at $BIN"
  exit 0
fi

echo "Downloading OSV-Scanner ${VERSION} (darwin/amd64)..."
curl -fsSL -o "$BIN" "$URL"
chmod +x "$BIN"
xattr -dr com.apple.quarantine "$BIN" 2>/dev/null || true
"$BIN" --version
echo "Ensure PATH includes ~/.local/bin (already in ~/.zshrc for this lab Mac)."
