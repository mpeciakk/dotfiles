#!/usr/bin/env bash
# questions-test.sh — stream.py questions extracts the questions a session put to the user.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0
check() { if [ "$2" -eq 0 ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi; }
T=$(mktemp -d /tmp/kt-qtest.XXXXXX)
# stream-json result event (claude -p)
printf '%s\n' '{"type":"result","subtype":"success","result":"Inwentarz gotowy.\n1. Czy worker działa w tej samej jednostce co app.py?\n2. Kto nadaje dostęp SSH do sms1?\nZatwierdzasz?"}' > "$T/p.jsonl"
# interactive transcript: AskUserQuestion tool_use
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"AskUserQuestion","input":{"questions":[{"question":"Pakiet jest dla Ernesta?\n(imię odbiorcy)"},{"question":"Gdzie leży plik outbox.db?"}]}}]}}' > "$T/i.jsonl"
q=$(python3 -I "$EV/stream.py" questions "$T/p.jsonl" "$T/i.jsonl")
echo "$q" | sed 's/^/     /'
[ "$(echo "$q" | grep -c .)" -eq 5 ]; check "five questions (3 result lines with ?, 2 AskUserQuestion)" $?
echo "$q" | grep -qxF 'p.jsonl: 2. Kto nadaje dostęp SSH do sms1?'; check "result line kept whole, file prefix" $?
echo "$q" | grep -qxF 'i.jsonl: Pakiet jest dla Ernesta? (imię odbiorcy)'; check "AskUserQuestion newline folded" $?
echo "$q" | grep -q 'Inwentarz gotowy'; [ $? -ne 0 ]; check "line without ? is not a question" $?
python3 -I "$EV/stream.py" questions "$T/missing.jsonl" >/dev/null 2>&1; [ $? -ne 0 ]; check "missing file -> non-zero exit" $?
rm -rf "$T"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
