# Plan Granularity — Middle Variant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Plans fix the contract (interfaces, full test code, exact values) and leave implementation to a Sonnet implementer, with Haiku kept as the rule for small, surgical, fully-specified tasks.

**Architecture:** Prose changes to the flow's skills and agent definitions under `/home/m/dotfiles/.claude` (deployed to `~/.claude` as symlinks). `writing-plans` gets the new split and task template; the implementer definition moves to Sonnet; `subagent-driven-development`, `development-workflow` and the README carry the Haiku-override rule; implementer and task-reviewer learn how to treat implementation the brief leaves open. No hook or script changes — `task-brief` extracts tasks by heading, and headings keep their shape.

**Tech Stack:** Markdown skill files, YAML frontmatter in agent definitions, bash for checks.

**Spec:** none — the dotfiles have no living `spec.md` (writing one is its own job, `writing-specs`).

**Design record:** `/home/m/dotfiles/.flow/specs/2026-09-23-plan-granularity-design.md` (D1 plan split, D2 implementer model, D3 review of open implementation)

## Global Constraints

- Edit only under `.claude/` of the worktree you were given. Never through `~/.claude/…` paths: those are symlinks into the main checkout, not your worktree.
- Skill and agent prose is English; keep each file's existing voice, heading style and line wrapping (~80 columns).
- Surgical: change only the passages each task names. No rewording of neighbouring sections.
- Model names are exactly `Sonnet 5`, `Haiku 4.5`, `Opus 5.5`; agent frontmatter uses the aliases `sonnet`, `haiku`, `opus`.
- After every task, `bash .claude/hooks/flow-guard-test` still ends `124 passed, 0 failed`.

---

### Task 1: `writing-plans` — the plan fixes the contract, not the implementation

This task is written the middle-variant way on purpose: the check and the required content are fixed, the prose is yours.

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
has()   { grep -qF -- "$1" "$f" || { echo "MISSING: $1"; fail=1; }; }
hasnt() { ! grep -qF -- "$1" "$f" || { echo "STILL PRESENT: $1"; fail=1; }; }
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

1. **Overview** (line 10): the list "which files to touch for each task, code, testing, docs…" becomes one that names the contract — files, interfaces, the tests in full, exact values, the pattern to follow, how to test it. Keep the rest of the paragraph.
2. **New section** `## What the Plan Fixes, and What It Leaves to the Implementer`, before `## Task Right-Sizing`. Must carry, in this file's voice:
   - a two-column table — *always in full*: interface signatures (Produces/Consumes), full test code for every RED with its expected failure, exact values (names, constants, messages, formats, paths), verified external API shapes; *only when the implementation is itself a decision*: implementation code;
   - the criterion, containing the exact phrase `a reviewer would reject a reasonable alternative` — examples: algorithm, storage format, lock order, a specific error-handling contract;
   - otherwise: the approach in 1–3 sentences plus the existing pattern to follow as `file:line` or a symbol;
   - why, briefly: full-code plans ran 8–22k words, which slowed red-team and review, sat in the controller's context for the whole run, and froze code written before earlier tasks existed and without ever being run; the test is the contract the reviewer holds the implementation to, which is why it stays in full;
   - a pointer to the design record `.flow/specs/2026-09-23-plan-granularity-design.md` in the dotfiles repo for the rejected options.
3. **Task Structure template**: `- [ ] **Step 3: Write minimal implementation**` and its code block become `- [ ] **Step 3: Implement**` with an approach line and a `Follow:` line naming a pattern (e.g. `` `src/path/existing.py:40-62` (`parse_header`) ``), then a short note that a code block goes here only when the implementation is a decision per the new section. Steps 1, 2, 4, 5 stay as they are.
4. **No Placeholders**: replace the bullet "Steps that describe what to do without showing how (code blocks required for code steps)" with one saying test code is always shown, implementation code when it is a decision, and that an approach with no pattern to follow, or with nothing concrete in it, is a placeholder — it must contain the exact phrase `an approach with no pattern to follow`. Change "Similar to Task N" (repeat the code …) to say repeat the test code and values.

Leave `## Bite-Sized Task Granularity`, the header template, Self-Review, Red-Team Pass and Execution Handoff untouched. `red-team.md`'s skip rule for a pure-transcription plan also stays.

- [ ] **Step 4: Run the check and the regression suite**

Run: `bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task1.sh && bash .claude/hooks/flow-guard-test | tail -1`
Expected: `PASS`, then `124 passed, 0 failed`.

Then confirm `task-brief` still extracts a new-format task. Run:

```bash
d=$(mktemp -d); cat > "$d/p.md" <<'EOF'
# X Plan

## Global Constraints

- None.

---

### Task 1: One

- [ ] **Step 3: Implement**

Approach: do the thing.
Follow: `a.py:1` (`f`).

### Task 2: Two
EOF
~/.claude/skills/subagent-driven-development/scripts/task-brief "$d/p.md" 1 "$d/b.md" 2>/dev/null && cat "$d/b.md"; rm -r "$d"
```

Expected: the brief contains `## Global Constraints`, `### Task 1: One`, `Follow:`, and no `### Task 2`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/writing-plans/SKILL.md
git commit -m "writing-plans: plans fix the contract, implementation only when it is a decision"
```

---

### Task 2: Implementer on Sonnet 5, Haiku 4.5 as the rule for surgical tasks

**Files:**
- Modify: `.claude/agents/implementer.md:4` (frontmatter)
- Modify: `.claude/skills/subagent-driven-development/SKILL.md:98-99` (loop step 3) and `:187-188` (Dispatching)
- Modify: `.claude/skills/development-workflow/SKILL.md:93` (model table) and `:174-176` (Small Lane step 5)
- Modify: `.claude/README.md:36` (Model & effort)

**Interfaces:**
- Consumes: Task 1's premise that some briefs hold the complete change.
- Produces: nothing later tasks call.

- [ ] **Step 1: Write the failing check**

Save as `/tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task2.sh`:

```bash
#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)/.claude"; fail=0
has()   { grep -qF -- "$2" "$1" || { echo "MISSING in $1: $2"; fail=1; }; }
hasnt() { ! grep -qF -- "$2" "$1" || { echo "STILL PRESENT in $1: $2"; fail=1; }; }
has   agents/implementer.md 'model: sonnet'
has   agents/implementer.md 'effort: high'
hasnt agents/implementer.md 'model: haiku'
has   skills/subagent-driven-development/SKILL.md 'Haiku is the rule, not the exception'
has   skills/subagent-driven-development/SKILL.md '`haiku` for a small, surgical or fully-specified implementer task'
has   skills/development-workflow/SKILL.md '| `implementer` | agent definition | Sonnet 5 · high — override to Haiku 4.5 for every small, surgical or fully-specified task (subagent-driven-development, step 3) |'
has   skills/development-workflow/SKILL.md 'dispatched with `model: "haiku"`'
has   README.md 'overridden to **Haiku 4.5** for small, surgical or'
[ $fail = 0 ] && echo PASS || exit 1
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task2.sh`
Expected: exit 1 with eight lines — `MISSING in agents/implementer.md: model: sonnet`, `MISSING in agents/implementer.md: effort: high`, `STILL PRESENT in agents/implementer.md: model: haiku`, and one `MISSING` for each of the other five strings.

- [ ] **Step 3: Implement**

The wording here is the decision (the user asked for the Haiku rule to be explicit), so the text is given in full. Apply exactly:

`agents/implementer.md` frontmatter — replace the line `model: haiku` with two lines:

```
model: sonnet
effort: high
```

`skills/subagent-driven-development/SKILL.md`, loop step 3 — replace

```
3. **Dispatch the implementer** — `subagent_type: "implementer"`. See Dispatching
   below for what the prompt carries.
```

with

```
3. **Dispatch the implementer** — `subagent_type: "implementer"`. See Dispatching
   below for what the prompt carries. **Pick the model first.** The definition
   runs Sonnet 5; pass `model: "haiku"` for every task that is small, surgical
   or fully specified — a spec sync, a config or one-value change, a task whose
   brief already holds the complete change. Haiku is the rule, not the
   exception: Sonnet is for tasks where an implementation has to be built. In
   doubt, Haiku — a BLOCKED report is the escalation path (Implementer status).
```

`skills/subagent-driven-development/SKILL.md`, Dispatching — replace

```
Pass `model:` only to override a definition's default — e.g. `opus` for a
task-reviewer on a hard diff, or for one genuinely hard implementer task.
```

with

```
Pass `model:` only to override a definition's default — `haiku` for a small,
surgical or fully-specified implementer task (step 3), `opus` for a
task-reviewer on a hard diff or for one genuinely hard implementer task.
```

`skills/development-workflow/SKILL.md`, model table — replace the row

```
| `implementer` | agent definition | Haiku 4.5, no effort setting (override to Sonnet 5 for a genuinely hard task) |
```

with

```
| `implementer` | agent definition | Sonnet 5 · high — override to Haiku 4.5 for every small, surgical or fully-specified task (subagent-driven-development, step 3) |
```

`skills/development-workflow/SKILL.md`, Small Lane step 5 — replace

```
5. **One implementer, one review** (subagent-driven-development, single task).
   Skip the whole-branch review: with one task, the task review already saw the
   whole branch.
```

with

```
5. **One implementer, one review** (subagent-driven-development, single task),
   the implementer dispatched with `model: "haiku"` — a one-decision change is
   the surgical case. Skip the whole-branch review: with one task, the task
   review already saw the whole branch.
```

`README.md`, Model & effort — replace

```
`agents/`: implementer **Haiku 4.5**, fixer and task-reviewer **Sonnet 5 · high**
```

with

```
`agents/`: implementer **Sonnet 5 · high**, overridden to **Haiku 4.5** for
small, surgical or fully-specified tasks; fixer and task-reviewer **Sonnet 5 · high**
```

and append to the end of that same paragraph (after "Full table in `development-workflow`."):

```
Plans fix the contract — interfaces, full tests, exact values — and carry
implementation code only where it is a decision; this is an experiment against
the full-code plans of `0d2c8b3`, see
`.flow/specs/2026-09-23-plan-granularity-design.md`.
```

- [ ] **Step 4: Run the check and the regression suite**

Run: `bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task2.sh && bash .claude/hooks/flow-guard-test | tail -1`
Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/agents/implementer.md .claude/skills/subagent-driven-development/SKILL.md .claude/skills/development-workflow/SKILL.md .claude/README.md
git commit -m "implementer: Sonnet 5 by default, Haiku 4.5 as the rule for surgical tasks"
```

---

### Task 3: Implementation the brief leaves open — implementer and task-reviewer

**Files:**
- Modify: `.claude/agents/implementer.md` — `## Requirements come from the brief`, first paragraph (lines 32-35)
- Modify: `.claude/agents/task-reviewer.md` — `## Part 1: Spec compliance`, after the `**Misunderstood:**` bullet (line 77)

**Interfaces:**
- Consumes: Task 1's step shape (`Step 3: Implement` with an approach and a `Follow:` pattern).
- Produces: nothing later tasks call.

- [ ] **Step 1: Write the failing check**

Save as `/tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task3.sh`:

```bash
#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)/.claude"; fail=0
has() { grep -qF -- "$2" "$1" || { echo "MISSING in $1: $2"; fail=1; }; }
has agents/implementer.md 'Where the brief gives an approach instead of code, the implementation is yours'
has agents/task-reviewer.md '"not how I would have done it" is not a finding'
[ $fail = 0 ] && echo PASS || exit 1
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task3.sh`
Expected: exit 1 with both `MISSING` lines.

- [ ] **Step 3: Implement**

Given in full — the wording is the D3 decision. In `agents/implementer.md`, directly after the paragraph ending `if the brief is wrong, report NEEDS_CONTEXT quoting the line.`, insert a blank line and:

```
Where the brief gives an approach instead of code, the implementation is yours:
follow the pattern it names, and keep its tests, interfaces and values verbatim
— those are the contract the review holds you to. Code the brief does give is
there because the implementation is itself a decision; use it as written.
```

In `agents/task-reviewer.md`, directly after the bullet `- **Misunderstood:** right feature built wrong, or wrong problem solved`, insert a blank line and:

```
Where the brief gives an approach rather than code, the contract is its tests,
interfaces and values. Judge the implementation on quality and on fidelity to
the pattern the brief names; "not how I would have done it" is not a finding.
Code the brief does give is a requirement like any other.
```

- [ ] **Step 4: Run the check and the regression suite**

Run: `bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task3.sh && bash .claude/hooks/flow-guard-test | tail -1`
Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/agents/implementer.md .claude/agents/task-reviewer.md
git commit -m "agents: implementation the brief leaves open is the implementer's, judged on quality"
```

---

No spec-sync task: the dotfiles have no living spec; the README's state paragraph is updated in Task 2.
