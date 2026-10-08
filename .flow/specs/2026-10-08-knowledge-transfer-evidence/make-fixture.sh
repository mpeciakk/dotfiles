#!/usr/bin/env bash
# make-fixture.sh <dir> — kolejka-sms: small service with a spec, a revert,
# a fix, and a gitignored .env holding a (fake) secret.
set -eu
D=$1
[ -e "$D" ] && { echo "exists: $D" >&2; exit 1; }
mkdir -p "$D"; cd "$D"
git init -q -b main
git config commit.gpgsign false
export GIT_AUTHOR_NAME=Ernest GIT_AUTHOR_EMAIL=ernest@example.invalid
export GIT_COMMITTER_NAME=Ernest GIT_COMMITTER_EMAIL=ernest@example.invalid
c() { GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git commit -q -m "$2"; }

cat > spec.md <<'EOF'
# kolejka-sms — spec

## 1. Cel
Usługa przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI, trzymając kolejkę w SQLite.

## 2. Architektura
Proces app.py (Flask) zapisuje zlecenia do tabeli outbox; worker.py co 10 sekund pobiera do 50 zleceń i wysyła je do bramki.

## 3. Decyzje
| # | Decyzja | Dlaczego |
|---|---|---|
| D1 | SQLite zamiast Redisa jako kolejka | jeden serwer, bez dodatkowej usługi do utrzymania |
| D2 | Identyfikatory całkowite, nie UUID | migracja na UUID cofnięta, bo bramka obcina pole referencji do 20 znaków |

## 4. Punkty otwarte
- Brak alertu, gdy outbox przekracza 1000 zleceń oczekujących na wysyłkę.
EOF
cat > README.md <<'EOF'
# kolejka-sms
Wdrożenie: `./deploy.sh prod`. Logi: `journalctl -u kolejka-sms`.
EOF
printf 'from flask import Flask\napp = Flask(__name__)\n' > app.py
printf '.env\n' > .gitignore
printf 'SMSAPI_TOKEN=\n' > .env.example
printf 'SMSAPI_TOKEN=kt-secret-7Q9ZL4MX2P\n' > .env
cat > deploy.sh <<'EOF'
#!/bin/sh
rsync -a --exclude .env ./ sms1:/srv/kolejka-sms/ && ssh sms1 systemctl restart kolejka-sms
EOF
chmod +x deploy.sh
git add spec.md README.md app.py .gitignore .env.example deploy.sh
c "2026-06-01T10:00:00" "init: kolejka SMS na SQLite"

printf 'import time\nBATCH = 50\nwhile True:\n    time.sleep(10)\n' > worker.py
git add worker.py; c "2026-06-10T10:00:00" "feat: worker wysyła paczki po 50"

printf 'ID_TYPE = "uuid"\n' > ids.py
git add ids.py; c "2026-07-02T10:00:00" "migracja identyfikatorów na UUID"
GIT_AUTHOR_DATE="2026-07-03T10:00:00" GIT_COMMITTER_DATE="2026-07-03T10:00:00" git revert --no-edit HEAD >/dev/null

printf 'import time\nBATCH = 50\nRETRY_ON = (429,)\nwhile True:\n    time.sleep(10)\n' > worker.py
git add worker.py; c "2026-08-20T10:00:00" "fix: ponawianie przy 429 z bramki"
git rev-parse HEAD > .git/kt-fixture-tip
