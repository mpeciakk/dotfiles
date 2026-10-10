#!/usr/bin/env bash
# Validates the repo's niri config with the pc host's niri-output.kdl as output.kdl.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$REPO"/config/niri/*.kdl "$TMP"/
cp "$REPO/hosts/pc/niri-output.kdl" "$TMP/output.kdl"
niri validate -c "$TMP/config.kdl"
