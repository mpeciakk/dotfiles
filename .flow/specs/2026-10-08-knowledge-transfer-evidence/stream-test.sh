#!/usr/bin/env bash
# stream-test.sh — stream.py reads the real captured transcript correctly.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0
check() { # label condition-exit-code
  if [ "$2" -eq 0 ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi
}
out=$(python3 -I "$EV/stream.py" agent-results kt-echo "$EV/sample-stream.jsonl")
echo "$out" | sed 's/^/     /'
[ "$(echo "$out" | grep -c .)" -eq 1 ]; check "exactly one kt-echo result" $?
echo "$out" | grep -q '"is_error": false'; check "result is not an error" $?
echo "$out" | grep -q 'PONG-7731'; check "result carries the subagent text" $?
none=$(python3 -I "$EV/stream.py" agent-results kt-cold-reader "$EV/sample-stream.jsonl")
[ -z "$none" ]; check "other subagent_type: no output" $?
tools=$(python3 -I "$EV/stream.py" subagent-tools "$EV/sample-stream.jsonl")
[ -z "$tools" ]; check "kt-echo called no tools" $?
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
