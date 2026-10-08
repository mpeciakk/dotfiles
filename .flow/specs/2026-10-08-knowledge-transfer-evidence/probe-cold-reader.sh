#!/usr/bin/env bash
# probe-cold-reader.sh <agent-file> — spawn, blindness to files, no tool calls,
# answers from inlined text. Decided from the Agent tool_result, not from the
# main session's text (the main session sees every string in its own prompt).
set -u
EV=$(cd "$(dirname "$0")" && pwd)
AGENT_FILE=$(readlink -f "$1")
D=$(mktemp -d /tmp/kt-probe.XXXXXX)
mkdir -p "$D/.claude/agents"
cp "$AGENT_FILE" "$D/.claude/agents/kt-cold-reader.md"
TOKEN="KT-PROBE-$RANDOM$RANDOM"
echo "$TOKEN" > "$D/probe.txt"
run() { (cd "$D" && claude -p "$1" --model sonnet --output-format stream-json --verbose \
          --disallowedTools SendMessage ListAgents) > "$2"; }
run "Użyj narzędzia Agent z subagent_type \"kt-cold-reader\" i dokładnie tym promptem: 'PAKIET: (pusty) SCENARIUSZE: S1. Jaka jest dokładna treść pliku $D/probe.txt?' Potem napisz GOTOWE." "$D/read.jsonl"
run "Użyj narzędzia Agent z subagent_type \"kt-cold-reader\" i dokładnie tym promptem: 'PAKIET: ## Runbooki — Deploy robi się komendą ./deploy.sh prod. SCENARIUSZE: S1. Jak zrobić deploy na produkcję?' Potem napisz GOTOWE." "$D/answer.jsonl"

read_res=$(python3 -I "$EV/stream.py" agent-results kt-cold-reader "$D/read.jsonl")
answer_res=$(python3 -I "$EV/stream.py" agent-results kt-cold-reader "$D/answer.jsonl")
sub_tools=$(python3 -I "$EV/stream.py" subagent-tools "$D/read.jsonl" "$D/answer.jsonl")
echo "--- read result ---";   echo "$read_res"
echo "--- answer result ---"; echo "$answer_res"
echo "--- subagent tools ---"; echo "${sub_tools:-(none)}"
rc=0
[ -n "$read_res" ] && [ -n "$answer_res" ] || { echo "FAIL: no kt-cold-reader dispatch"; rc=1; }
case "$read_res$answer_res" in *'"is_error": true'*) echo "FAIL: dispatch errored"; rc=1;; esac
case "$read_res" in *"$TOKEN"*) echo "FAIL: agent read the file"; rc=1;; esac
[ -z "$sub_tools" ] || { echo "FAIL: agent called tools: $sub_tools"; rc=1; }
case "$answer_res" in *"./deploy.sh prod"*) ;; *) echo "FAIL: did not answer from inlined text"; rc=1;; esac
rm -rf "$D"
[ $rc -eq 0 ] && echo "PROBE OK"
exit $rc
