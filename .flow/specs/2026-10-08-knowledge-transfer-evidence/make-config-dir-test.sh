#!/usr/bin/env bash
# make-config-dir-test.sh — the throwaway config dir links everything but the skill and agent under test.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0
check() { if [ "$2" -eq 0 ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi; }
T=$(mktemp -d /tmp/kt-cfgtest.XXXXXX)
S=$T/src
mkdir -p "$S/skills/knowledge-transfer" "$S/skills/other" "$S/agents" "$S/projects"
echo secret > "$S/.credentials.json"; echo '{}' > "$S/settings.json"
echo old > "$S/skills/knowledge-transfer/SKILL.md"; echo x > "$S/skills/other/SKILL.md"
echo old > "$S/agents/kt-cold-reader.md"; echo x > "$S/agents/implementer.md"
D=$(bash "$EV/make-config-dir.sh" "$S" "$T/dst"); echo "     $D"
[ "$D" = "$T/dst" ]; check "prints the destination" $?
[ -L "$T/dst/.credentials.json" ] && [ "$(readlink "$T/dst/.credentials.json")" = "$S/.credentials.json" ]; check "credentials linked, not copied" $?
[ -L "$T/dst/settings.json" ] && [ -L "$T/dst/projects" ]; check "other top-level entries linked" $?
[ -d "$T/dst/skills" ] && [ ! -L "$T/dst/skills" ] && [ -d "$T/dst/agents" ] && [ ! -L "$T/dst/agents" ]; check "skills/ and agents/ are real dirs" $?
[ -L "$T/dst/skills/other" ] && [ -L "$T/dst/agents/implementer.md" ]; check "other skills and agents linked" $?
[ -d "$T/dst/skills" ] && [ ! -e "$T/dst/skills/knowledge-transfer" ] && [ ! -e "$T/dst/agents/kt-cold-reader.md" ]; check "skill and agent under test omitted" $?
bash "$EV/make-config-dir.sh" "$S" "$T/dst" >/dev/null 2>&1; [ $? -ne 0 ]; check "existing destination -> non-zero exit" $?
rm -rf "$T"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
