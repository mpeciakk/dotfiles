#!/usr/bin/env bash
# check-d32-test.sh — check-d32.sh passes a D32-shaped package and fails each criterion alone.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0
check() { if [ "$2" -eq 0 ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi; }
T=$(mktemp -d /tmp/kt-d32test.XXXXXX)
cat > "$T/good.md" <<'EOF'
# Przekazanie projektu kolejka-sms

## 0. Jak czytać
Opisuje commit abc1234. Wersja 0.9.1, serwer 10.100.100.205.

## 1. Cel i granice
Usługa kolejkuje SMS-y i wysyła je przez bramkę.

## 2. Jak to działa
Worker czyta outbox.db i wysyła zlecenia.

## 3. Stan projektu
Działa produkcyjnie. Wg speca ponawianie 429 jest niesprawdzone na produkcji.

## 4. Środowisko i dostępy
Infrastruktura firmowa: docs.internal.animativ.dev.

## 5. Typowe zadanie krok po kroku
1. Na serwerze: `systemctl status kolejka-sms-worker`.

## 6. Awarie i obejścia
- Worker nie wstaje po restarcie serwera.

## 7. Rozwój
Testy: `pytest`.
Decyzje: [rekord](../../.flow/specs/2026-10-08-x-design.md), poprzednie KT: `docs/kt/2026-10-08.md`.

## 8. Kto co wie
Projekt zna tylko autor.

## 9. Luki
- **Kontakt do SMSAPI.** **Skutek:** brak eskalacji u dostawcy.
  Do czasu ustalenia: zgłoszenia przez panel SMSAPI.

## 10. Sprawdź się
1. Worker nie działa po restarcie. Co robisz?
EOF
run() { bash "$EV/check-d32.sh" "$1" > "$T/out" 2>&1; echo $?; }
r=$(run "$T/good.md"); sed 's/^/     /' "$T/out"
[ "$r" -eq 0 ] && grep -qx '4/4 PASS' "$T/out"; check "good package -> 4/4, exit 0" $?
variant() { # variant <name> <the one criterion expected to fail> <sed script>
  sed -e "$3" "$T/good.md" > "$T/$1.md"
  r=$(run "$T/$1.md")
  [ "$r" -ne 0 ] && grep -q "^FAIL $2 " "$T/out" && [ "$(grep -c '^FAIL ' "$T/out")" -eq 1 ]
  check "$1 -> only $2 fails" $?
}
variant iso-date         D1 's/^Działa produkcyjnie\./Działa produkcyjnie. Token odnowiono 2026-08-01./'
variant dot-date         D1 's/^Działa produkcyjnie\./Działa produkcyjnie od 1.08.2026./'
variant worded-date      D1 's/^Działa produkcyjnie\./Działa produkcyjnie od 1 sierpnia 2026./'
variant order            D2 's/^## 2\. Jak to działa/## 2. Stan projektu/; s/^## 3\. Stan projektu/## 3. Jak to działa/'
variant missing-heading  D2 '/^## 7\. Rozwój/d'
variant gap-no-meanwhile D3 's/Do czasu ustalenia: /Potem: /'
variant gap-no-impact    D3 's/Skutek:/Wpływ:/'
variant gap-numbered     D3 's/^- \*\*Kontakt/1. **Kontakt/; s/Skutek:/Wpływ:/'
variant gap-prose        D3 '/^  Do czasu/d; /^- \*\*Kontakt/c\Brak kontaktu do SMSAPI.'
variant home-path        D4 's/^Testy: `pytest`\./Testy: `pytest` w \/home\/m\/kolejka./'
variant tmp-path         D4 's/^Testy: `pytest`\./Testy: `pytest` w \/tmp\/kt-team.x\/fx./'
variant machine-name     D4 's/^Testy: `pytest`\./Testy: `pytest`, na pc herdr 0.9.3./'
r=$(run "$EV/team-package.md"); sed 's/^/     /' "$T/out"
[ "$r" -ne 0 ] && grep -q '^FAIL D1 ' "$T/out" && grep -q '^FAIL D2 ' "$T/out" && grep -qF 'Ostatnio odnowiono go 2026-08-01' "$T/out"
check "pre-D32 package (team-package.md) fails D1 and D2, D1 lists every dated line" $?
r=$(run "$T/missing.md"); [ "$r" -ne 0 ]; check "missing file -> non-zero exit" $?
rm -rf "$T"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
