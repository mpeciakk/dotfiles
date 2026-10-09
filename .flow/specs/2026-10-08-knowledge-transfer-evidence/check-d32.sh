#!/usr/bin/env bash
# check-d32.sh <package.md> — criteria D1-D4 for a D32-shaped knowledge-transfer
# package. Exit 0 iff 4/4 PASS.
set -u
PKG=$1
[ -f "$PKG" ] || { echo "check-d32.sh: no such file: $PKG" >&2; exit 2; }
pass=0
ok()  { pass=$((pass+1)); echo "PASS $1 $2"; }
bad() { echo "FAIL $1 $2: $3"; }

# D1 — no dates in prose. Link targets and backtick spans containing "/" are
# paths, not prose, so they are blanked before matching (line numbers kept).
months='stycznia|lutego|marca|kwietnia|maja|czerwca|lipca|sierpnia|września|października|listopada|grudnia'
dates="\b[0-9]{4}-[0-9]{2}-[0-9]{2}\b|\b[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{4}\b|\b[0-9]{1,2} ($months) [0-9]{4}\b"
dated=$(sed -E 's/\]\([^)]*\)/]()/g; s/`[^`]*\/[^`]*`//g' "$PKG" | grep -nE "$dates" | cut -d: -f1)
if [ -z "$dated" ]; then ok D1 daty
else
  bad D1 daty "dates in prose"
  for n in $dated; do printf '     %s: %s\n' "$n" "$(sed -n "${n}p" "$PKG")"; done
fi

# D2 — exactly eleven "## " headings, the i-th starting with the i-th expected one
want=('## 0. Jak czytać' '## 1. Cel i granice' '## 2. Jak to działa' '## 3. Stan projektu'
      '## 4. Środowisko i dostępy' '## 5. Typowe zadanie krok po kroku' '## 6. Awarie i obejścia'
      '## 7. Rozwój' '## 8. Kto co wie' '## 9. Luki' '## 10. Sprawdź się')
mapfile -t have < <(grep '^## ' "$PKG")
d2=""
[ "${#have[@]}" -eq "${#want[@]}" ] || d2="found ${#have[@]} headings, need ${#want[@]}"
if [ -z "$d2" ]; then
  for i in "${!want[@]}"; do
    case "${have[$i]}" in "${want[$i]}"*) ;; *) d2="heading $i is '${have[$i]}', expected '${want[$i]}'"; break;; esac
  done
fi
if [ -z "$d2" ]; then ok D2 sekcje; else bad D2 sekcje "$d2"; fi

# D3 — section 9 exists and every item in it has "Skutek:" and "Do czasu ustalenia:"
d3=$(python3 -I - "$PKG" <<'PY'
import re, sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
start = next((i for i, l in enumerate(lines) if l.startswith("## 9. Luki")), None)
if start is None:
    print("no '## 9. Luki' section"); sys.exit(1)
body = []
for l in lines[start + 1:]:
    if l.startswith("## "):
        break
    body.append(l.replace("**", ""))
if not any(l.strip() for l in body):
    sys.exit(0)
items = []
for l in body:
    if re.match(r"(- |\d+\. )", l):
        items.append(l)
    elif items and l[:1].isspace() and l.strip():
        items[-1] += "\n" + l
if not items:
    print("section 9 has text but no items"); sys.exit(1)
problems = []
for it in items:
    miss = [k for k in ("Skutek:", "Do czasu ustalenia:") if k not in it]
    if miss:
        problems.append("item '%s' lacks %s" % (it.split("\n")[0][:40], ", ".join(miss)))
if problems:
    print("; ".join(problems)); sys.exit(1)
PY
)
if [ $? -eq 0 ]; then ok D3 luki; else bad D3 luki "$d3"; fi

# D4 — no machine-specific setup in the package
paths=$(grep -nE '/home/|/tmp/|~/\.claude|/Users/|\bpc\b|\blaptop\b' "$PKG" | cut -d: -f1 | tr '\n' ' ')
if [ -z "$paths" ]; then ok D4 setup; else bad D4 setup "machine-specific text on lines: ${paths% }"; fi

echo "$pass/4 PASS"
[ "$pass" -eq 4 ]
