#!/usr/bin/env bash
R=$(cd "$(dirname "$0")/../../.." && pwd)/.claude; S=$R/skills; A=$R/agents
f=0; chk() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; f=1; fi; }
chk "SDD dispatches in background" "grep -q 'run_in_background: true' $S/subagent-driven-development/SKILL.md"
chk "review skill dispatches in background" "grep -q 'run_in_background: true' $S/requesting-code-review/SKILL.md"
chk "Opus triggers named" "grep -q 'auth' $S/subagent-driven-development/SKILL.md && grep -q '400 changed lines' $S/subagent-driven-development/SKILL.md"
chk "no vague non-trivial trigger" "! grep -q 'non-trivial, security- or concurrency-touching' $S/subagent-driven-development/SKILL.md"
chk "Explore row gone" "! grep -q 'Read-only exploration' $S/development-workflow/SKILL.md"
chk "model table says Sonnet 5.5" "grep -q 'Sonnet 5.5' $S/development-workflow/SKILL.md && ! grep -q 'Sonnet 5 ·' $S/development-workflow/SKILL.md"
chk "triage asks for /clear after a finished run" "grep -q '120K' $S/development-workflow/SKILL.md"
chk "finishing ends with /clear" "grep -q '/clear' $S/finishing-a-development-branch/SKILL.md"
chk "no second Global Constraints paste (SDD)" "! grep -q 'Global Constraints copied verbatim' $S/subagent-driven-development/SKILL.md"
chk "reviewer reads constraints from the brief" "grep -q 'brief already carries' $A/task-reviewer.md"
chk "red-team dispatched in background" "grep -q 'run_in_background: true' $S/writing-plans/red-team.md"
chk "model switches are session-only" "grep -q 'session only' $S/development-workflow/SKILL.md && ! grep -qE 'answers with .?/clear.?, .?/model sonnet.?, then' $S/development-workflow/SKILL.md"
chk "no stale 'runs Sonnet 5;'" "! grep -q 'runs Sonnet 5;' $S/subagent-driven-development/SKILL.md"
chk "statusline hints are session-only" "grep -q 'session only' $R/hooks/statusline"
exit $f
