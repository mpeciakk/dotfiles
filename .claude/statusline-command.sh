#!/bin/sh
# Statusline: model name + 20-char context-usage bar.
# Uses python3 only (no jq/bc dependency). Reads Claude Code's JSON on stdin.
exec python3 -c '
import sys, json

try:
    d = json.load(sys.stdin)
except Exception:
    d = {}

model = (d.get("model") or {}).get("display_name") or "Unknown Model"
used = (d.get("context_window") or {}).get("used_percentage")

try:
    pct = max(0.0, min(100.0, float(used)))
except (TypeError, ValueError):
    pct = None

WIDTH = 20
if pct is None:
    print(f"{model}  [{chr(0x2591) * WIDTH}] -%", end="")
else:
    filled = round(pct * WIDTH / 100)
    bar = chr(0x2588) * filled + chr(0x2591) * (WIDTH - filled)
    print(f"{model}  [{bar}] {pct:.0f}%", end="")
'
