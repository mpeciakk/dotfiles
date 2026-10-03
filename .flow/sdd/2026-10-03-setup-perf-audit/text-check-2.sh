#!/usr/bin/env bash
R=$(cd "$(dirname "$0")/../../.." && pwd)/.claude; M=/home/m/.claude/projects/-home-m-dotfiles/memory
f=0; chk() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; f=1; fi; }
chk "grill rule inline in brainstorming checklist" "grep -qE '^3\. \*\*Grill gate\*\*.*recommended default and why' $R/skills/brainstorming/SKILL.md"
chk "minor-objection rule inline in writing-plans" "awk '/^## Red-Team Pass/,/^## Execution/' $R/skills/writing-plans/SKILL.md | grep -q 'verdict PROCEED'"
chk "rule 2 names grep/find via Bash" "grep -q 'grep/find' $R/CLAUDE.md && ! grep -q 'Grep/Glob/Read tylko' $R/CLAUDE.md"
chk "rule 2 names the cbm project convention" "grep -q 'home-m-projects-' $R/CLAUDE.md"
chk "rule 5 marked main-thread" "grep -q 'dotyczy głównego wątku' $R/CLAUDE.md"
chk "README: no Sonnet 5 xhigh default" "! grep -q 'Sonnet 5 · xhigh' $R/README.md"
chk "README: no Grep/Glob augmenter" "! grep -q 'PreToolUse augmenter' $R/README.md"
chk "experiment note closed" "! grep -q 'Still open' $M/plan-granularity-experiment.md && grep -q 'Haiku' $M/plan-granularity-experiment.md"
chk "writing-plans execute line says model switch is session only" "grep -q 'To execute: /clear, /model sonnet.*session only' $R/skills/writing-plans/SKILL.md"
exit $f
