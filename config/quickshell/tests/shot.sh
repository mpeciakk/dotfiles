#!/usr/bin/env bash
# Usage: tests/shot.sh <name> — crop around the island on the focused monitor.
# niri also copies the screenshot to the clipboard. Refuses while the user's
# session is locked (the old shell's lock target answers "true").
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$(qs ipc call lock isLocked 2>/dev/null || true)" == "true" ]; then echo "shot: session locked — ask the user to unlock"; exit 1; fi
mkdir -p /tmp/wyspa-shots
RAW="/tmp/wyspa-shots/$1-full.png"
W="$(qs ipc -p "$DIR" prop get island targetW 2>/dev/null || echo 800)"
H="$(qs ipc -p "$DIR" prop get island targetH 2>/dev/null || echo 500)"
[[ "$W" =~ ^[0-9]+$ ]] || W=800
[[ "$H" =~ ^[0-9]+$ ]] || H=500
SCALE="$(niri msg -j focused-output | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["logical"]["scale"])')"
niri msg action screenshot-screen --show-pointer false --path "$RAW" >/dev/null
sleep 0.5
python3 -I - "$RAW" "/tmp/wyspa-shots/$1.png" "$W" "$H" "$SCALE" <<'PY'
import sys
from PIL import Image
raw, out, w, h, scale = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), float(sys.argv[5])
im = Image.open(raw); iw, ih = im.size
cw = min(iw, int((w + 200) * scale)); ch = min(ih, int((h + 120) * scale))
im.crop(((iw - cw) // 2, 0, (iw + cw) // 2, ch)).save(out)
PY
echo "/tmp/wyspa-shots/$1.png"
