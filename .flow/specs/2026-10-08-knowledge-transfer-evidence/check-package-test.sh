#!/usr/bin/env bash
# check-package-test.sh — the checker passes a good package and fails each criterion alone.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d /tmp/kt-checktest.XXXXXX)
bash "$EV/make-fixture.sh" "$T/fx" || { echo "FIXTURE FAILED"; exit 2; }
SHA=$(git -C "$T/fx" rev-parse --short HEAD)
mkdir -p "$T/tr-yes" "$T/tr-no" "$T/tr-err"
sed -e 's/kt-echo/kt-cold-reader/g' -e 's/PONG-7731/### S1\\nOdpowiedź: .\/deploy.sh prod\\nPodstawa: § Runbooki/g' \
  "$EV/sample-stream.jsonl" > "$T/tr-yes/turn-1.jsonl"
# a successful tool_result carries no error flag (stream-format.md), so inject one
sed -e 's/"type":"tool_result",/"type":"tool_result","is_error":true,/g' \
  "$T/tr-yes/turn-1.jsonl" > "$T/tr-err/turn-1.jsonl"
grep -v 'kt-echo' "$EV/sample-stream.jsonl" > "$T/tr-no/turn-1.jsonl"
python3 -I "$EV/stream.py" agent-results kt-cold-reader "$T/tr-yes/turn-1.jsonl" | grep -q 'Podstawa' \
  || { echo "FIXTURE FAILED: tr-yes has no cold-reader result"; exit 2; }
python3 -I "$EV/stream.py" agent-results kt-cold-reader "$T/tr-err/turn-1.jsonl" | grep -q '"is_error": true' \
  || { echo "FIXTURE FAILED: tr-err is not an errored dispatch"; exit 2; }
python3 -I "$EV/stream.py" agent-results kt-cold-reader "$T/tr-no/turn-1.jsonl" | grep -q . \
  && { echo "FIXTURE FAILED: tr-no still has a cold-reader dispatch"; exit 2; }

good() { cat <<EOF
# KT: kolejka-sms — dla: support
Stan na 2026-10-08, commit $SHA.
## Pułapki
- Nie wdrażaj w piątek: cron backup-sms o 23:00 blokuje bazę.
- Po restarcie sms1 uruchom ręcznie kolejka-sms-worker.
- Raz w miesiącu vacuum na outbox.db.
## Eskalacja
Awaria dłuższa niż 30 minut: Ernest na Signalu.
## Dostępy
Token SMSAPI: 1Password, sejf Ops, wpis SMSAPI.
EOF
}
pass=0; fail=0
expect() { # label expected_exit expected_substring package transcripts
  local out rc
  out=$(bash "$EV/check-package.sh" "$4" "$T/fx" "$5"); rc=$?
  if [ "$rc" = "$2" ] && [[ "$out" == *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1 (exit $rc)"; echo "$out" | sed 's/^/     /'; fi
}
good > "$T/good.md"
expect "good package (lower-case vacuum counts)" 0 "6/6 PASS" "$T/good.md" "$T/tr-yes"
{ good; echo "SMSAPI_TOKEN=kt-secret-7Q9ZL4MX2P"; } > "$T/c1.md"
expect "secret leaked" 1 "FAIL C1" "$T/c1.md" "$T/tr-yes"
{ good; echo "Usługa przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI, trzymając kolejkę w SQLite."; } > "$T/c2.md"
expect "spec line copied" 1 "FAIL C2" "$T/c2.md" "$T/tr-yes"
expect "no cold-reader dispatch" 1 "FAIL C3" "$T/good.md" "$T/tr-no"
expect "cold-reader dispatch errored" 1 "FAIL C3" "$T/good.md" "$T/tr-err"
good | grep -v -e 'kolejka-sms-worker' -e 'Signalu' > "$T/c4.md"
expect "two tacit markers only" 1 "FAIL C4" "$T/c4.md" "$T/tr-yes"
good | sed "s/commit $SHA/commit nieznany/" > "$T/c5.md"
expect "no snapshot SHA" 1 "FAIL C5" "$T/c5.md" "$T/tr-yes"
echo "- dopisek" >> "$T/fx/spec.md"
expect "existing file modified" 1 "FAIL C6" "$T/good.md" "$T/tr-yes"
rm -rf "$T"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
