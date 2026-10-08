#!/usr/bin/env bash
# turn.sh <fixture-dir> <transcripts-dir> <message> [session-id] — one nested
# session turn. Writes <transcripts-dir>/turn-<N>.jsonl (N = next free from 1);
# prints SESSION <id>, DENIED <tool> per permission denial, then the result text.
set -u
FX=$(readlink -f "$1")
TR=$(readlink -f "$2")
MSG=$3
SID=${4:-}
n=1
while [ -e "$TR/turn-$n.jsonl" ]; do n=$((n+1)); done
OUT="$TR/turn-$n.jsonl"
resume=()
[ -n "$SID" ] && resume=(--resume "$SID")
cd "$FX" && claude -p "$MSG" "${resume[@]}" --model sonnet --output-format stream-json --verbose \
  --permission-mode acceptEdits \
  --allowedTools Read Grep Glob Write Edit Agent Skill "Bash(git *)" "Bash(ls *)" "Bash(wc *)" "Bash(cat *)" "Bash(head *)" "Bash(date *)" "Bash(mkdir *)" \
  --disallowedTools SendMessage ListAgents > "$OUT"
python3 -I -c '
import json, sys
last = None
for line in open(sys.argv[1], encoding="utf-8"):
    try:
        ev = json.loads(line)
    except ValueError:
        continue
    if ev.get("type") == "result":
        last = ev
if last is None:
    sys.exit("no result event in " + sys.argv[1])
print("SESSION", last.get("session_id"))
for d in last.get("permission_denials") or []:
    print("DENIED", d.get("tool_name"))
print(last.get("result", ""))
' "$OUT"
