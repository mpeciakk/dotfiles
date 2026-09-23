## Global Constraints

- Edit only under `.claude/` of the worktree you were given. Never through `~/.claude/…` paths: those are symlinks into the main checkout, not your worktree.
- Skill and agent prose is English; keep each file's existing voice, heading style and line wrapping (~80 columns).
- Surgical: change only the passages each task names. No rewording of neighbouring sections.
- Model names are exactly `Sonnet 5`, `Haiku 4.5`, `Opus 5.5`; agent frontmatter uses the aliases `sonnet`, `haiku`, `opus`.
- After every task, `bash .claude/hooks/flow-guard-test` still ends `124 passed, 0 failed`. It includes a wall-clock assertion: a latency-only failure gets one re-run before it counts.

---

### Task 1: `writing-plans` — the plan fixes the contract, not the implementation

This task is written the middle-variant way on purpose: the check and the required content are fixed, the prose is yours.

**Controller:** dispatch this task with `model: "sonnet"` — the agent definitions load from the main checkout, so this run still has the Haiku default and the old reviewer rules; the new ones take effect only after merge. Expect the task-reviewer to raise prose-preference findings here (D3 is not live yet) and weigh them yourself. Tasks 2 and 3 are fully specified: dispatch them with `model: "haiku"`.

**Files:**
- Modify: `.claude/skills/writing-plans/SKILL.md` — `## Overview` (line 10), a new section placed directly before `## Task Right-Sizing` (line 80), `## Task Structure` Step 3 (lines 162-167), `## No Placeholders` (lines 182-192)

**Interfaces:**
- Consumes: nothing.
- Produces: the section heading `## What the Plan Fixes, and What It Leaves to the Implementer` and the template step heading `- [ ] **Step 3: Implement**`. Task 2's wording in subagent-driven-development ("a task whose brief already holds the complete change") relies on the plan being able to carry full code only for some tasks.

- [ ] **Step 1: Write the failing check**

Save as `/tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task1.sh` (outside the repo — it must not be committed; create the directory if missing):

```bash
#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)"
f=.claude/skills/writing-plans/SKILL.md; fail=0
# Normalise whitespace: wrapped prose splits phrases across lines.
flat() { tr '\n' ' ' < "$f" | tr -s ' '; }
has()   { flat | grep -qF -- "$1" || { echo "MISSING: $1"; fail=1; }; }
hasnt() { ! flat | grep -qF -- "$1" || { echo "STILL PRESENT: $1"; fail=1; }; }
has   '## What the Plan Fixes, and What It Leaves to the Implementer'
has   'a reviewer would reject a reasonable alternative'
has   '- [ ] **Step 3: Implement**'
has   'an approach with no pattern to follow'
hasnt 'code blocks required for code steps'
hasnt 'which files to touch for each task, code, testing'
hasnt '- [ ] **Step 3: Write minimal implementation**'
# the new section sits before Task Right-Sizing
a=$(grep -n '^## What the Plan Fixes' "$f" | cut -d: -f1); b=$(grep -n '^## Task Right-Sizing' "$f" | cut -d: -f1)
[ -n "$a" ] && [ "$a" -lt "$b" ] || { echo "ORDER: new section must precede Task Right-Sizing"; fail=1; }
[ $fail = 0 ] && echo PASS || exit 1
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task1.sh`
Expected: exit 1, printing `MISSING: ## What the Plan Fixes…`, `MISSING: a reviewer would reject…`, `MISSING: - [ ] **Step 3: Implement**`, `MISSING: an approach with no pattern to follow`, `STILL PRESENT: code blocks required for code steps`, `STILL PRESENT: which files to touch for each task, code, testing`, `STILL PRESENT: - [ ] **Step 3: Write minimal implementation**`, `ORDER: …`.

- [ ] **Step 3: Implement**

Approach — four edits, each making the check's line for it pass:

1. **Overview** (line 10): the list "which files to touch for each task, code, testing, docs…" becomes one that names the contract — files, interfaces, the tests in full, exact values, the pattern to follow, how to test it. "Assuming … questionable taste" becomes: assume they do not know this codebase's patterns, so every approach names the one to follow. Keep the rest of the paragraph.
2. **New section** `## What the Plan Fixes, and What It Leaves to the Implementer`, before `## Task Right-Sizing`. Must carry, in this file's voice:
   - a two-column table — *always in full*: interface signatures (Produces/Consumes), full test code for every RED with its expected failure, exact values (names, constants, messages, formats, paths), verified external API shapes; *only when the implementation is itself a decision*: implementation code;
   - the criterion, containing the exact phrase `a reviewer would reject a reasonable alternative` — examples: algorithm, storage format, lock order, a specific error-handling contract;
   - otherwise: the approach in 1–3 sentences plus the pattern to follow — an existing `file:line` or symbol, or a symbol from an earlier task's Produces line; when no pattern exists at all, the first instance is itself a decision and gets full code;
   - why, briefly: full-code plans ran 8–22k words, which slowed red-team and review, sat in the controller's context for the whole run, and froze code written before earlier tasks existed and without ever being run; the test is the contract the reviewer holds the implementation to, which is why it stays in full;
   - a pointer to the design record `~/dotfiles/.flow/specs/2026-09-23-plan-granularity-design.md` for the rejected options (absolute — this skill is loaded in every repo).
3. **Task Structure template**: `- [ ] **Step 3: Write minimal implementation**` and its code block become `- [ ] **Step 3: Implement**` with an approach line and a `Follow:` line naming a pattern (e.g. `` `src/path/existing.py:40-62` (`parse_header`) ``), then a short note that a code block goes here only when the implementation is a decision per the new section. Steps 1, 2, 4, 5 stay as they are.
4. **No Placeholders**: replace the bullet "Steps that describe what to do without showing how (code blocks required for code steps)" with one saying test code is always shown, implementation code when it is a decision, and that an approach with no pattern to follow, or with nothing concrete in it, is a placeholder — it must contain the exact phrase `an approach with no pattern to follow`. Change "Similar to Task N" (repeat the code …) to say repeat the test code and values.

Leave `## Bite-Sized Task Granularity`, the header template, Self-Review, Red-Team Pass and Execution Handoff untouched. `red-team.md`'s skip rule for a pure-transcription plan also stays.

- [ ] **Step 4: Run the check and the regression suite**

Run: `bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task1.sh && bash .claude/hooks/flow-guard-test | tail -1`
Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/writing-plans/SKILL.md
git commit -m "writing-plans: plans fix the contract, implementation only when it is a decision"
```

---
