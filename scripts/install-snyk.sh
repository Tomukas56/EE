#!/usr/bin/env bash
# Install Snyk CLI into ~/.local/bin (Intel macOS). Token stays out of git.
set -euo pipefail

BIN="${SNYK_BIN:-$HOME/.local/bin/snyk}"
URL="${SNYK_CLI_URL:-https://downloads.snyk.io/cli/stable/snyk-macos}"

mkdir -p "$(dirname "$BIN")"

if [[ -x "$BIN" ]] && "$BIN" --version >/dev/null 2>&1; then
  echo "snyk already at $BIN ($("$BIN" --version))"
  exit 0
fi

echo "Downloading Snyk CLI (darwin/amd64)..."
curl -fsSL -o "$BIN" "$URL"
chmod +x "$BIN"
xattr -dr com.apple.quarantine "$BIN" 2>/dev/null || true
"$BIN" --version
echo "Auth: export SNYK_TOKEN=... or add SNYK_TOKEN to backend/.env (gitignored)."
echo "Create a token: https://app.snyk.io/account"
