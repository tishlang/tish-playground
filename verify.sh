#!/usr/bin/env bash
# Verify that the local tish compiler handles raw JSX text (e.g. "Web preview works!").
# Run after: npm run install-tish && npm run build
set -euo pipefail

export PATH="${HOME}/.cargo/bin:${PATH:-}"
PLAYGROUND_ROOT="$(cd "$(dirname "$0")" && pwd)"

if ! command -v tish &>/dev/null; then
  echo "Error: tish CLI not found. Run: npm run install-tish"
  exit 1
fi

echo "Verifying JSX text: <h1>Web preview works!</h1>"
outfile="$PLAYGROUND_ROOT/public/dist/.verify-out.js"
mkdir -p "$(dirname "$outfile")"
tish compile "$PLAYGROUND_ROOT/verify-jsx-text.tish" -o "$outfile" --target js --jsx lattish 2>&1

if grep -q '"Web preview works!' "$outfile" && grep -q '😔' "$outfile"; then
  echo "OK: Raw JSX text compiles correctly"
  rm -f "$outfile"
  exit 0
else
  echo "FAIL: Expected output to contain \"Web preview works!\" and emoji"
  cat "$outfile"
  exit 1
fi
