## Global Constraints

- Edit only under `.claude/` of the worktree you were given. Never through `~/.claude/…` paths: those are symlinks into the main checkout, not your worktree.
- Skill and agent prose is English; keep each file's existing voice, heading style and line wrapping (~80 columns).
- Surgical: change only the passages each task names. No rewording of neighbouring sections.
- Model names are exactly `Sonnet 5`, `Haiku 4.5`, `Opus 5.5`; agent frontmatter uses the aliases `sonnet`, `haiku`, `opus`.
- After every task, `bash .claude/hooks/flow-guard-test` still ends `124 passed, 0 failed`. It includes a wall-clock assertion: a latency-only failure gets one re-run before it counts.

---

### Task 2: Implementer on Sonnet 5, Haiku 4.5 as the rule for surgical tasks

**Files:**
- Modify: `.claude/agents/implementer.md:4` (frontmatter)
- Modify: `.claude/skills/subagent-driven-development/SKILL.md:98-99` (loop step 3) and `:187-188` (Dispatching)
- Modify: `.claude/skills/development-workflow/SKILL.md:87-88` (dispatch-override sentence), `:93` (model table) and `:174-176` (Small Lane step 5)
- Modify: `.claude/README.md:36` (Model & effort)

**Interfaces:**
- Consumes: Task 1's premise that some briefs hold the complete change.
- Produces: nothing later tasks call.

- [ ] **Step 1: Write the failing check**

Save as `/tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task2.sh`:

```bash
#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)/.claude"; fail=0
# Normalise whitespace: wrapped prose splits phrases across lines.
flat() { tr '\n' ' ' < "$1" | tr -s ' '; }
has()   { flat "$1" | grep -qF -- "$2" || { echo "MISSING in $1: $2"; fail=1; }; }
hasnt() { ! flat "$1" | grep -qF -- "$2" || { echo "STILL PRESENT in $1: $2"; fail=1; }; }
has   agents/implementer.md 'model: sonnet'
has   agents/implementer.md 'effort: high'
hasnt agents/implementer.md 'model: haiku'
has   skills/subagent-driven-development/SKILL.md 'Haiku is the rule, not the exception'
has   skills/subagent-driven-development/SKILL.md '`haiku` for a small, surgical or fully-specified implementer task'
has   skills/development-workflow/SKILL.md '| `implementer` | agent definition | Sonnet 5 · high — override to Haiku 4.5 for every small, surgical or fully-specified task (subagent-driven-development, step 3) |'
has   skills/development-workflow/SKILL.md 'dispatched with `model: "haiku"`'
hasnt skills/development-workflow/SKILL.md 'only to override the definition for one case'
has   skills/subagent-driven-development/SKILL.md 'model=haiku'

has   README.md 'overridden to **Haiku 4.5** for small, surgical or'
[ $fail = 0 ] && echo PASS || exit 1
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task2.sh`
Expected: exit 1 with ten lines — `MISSING in agents/implementer.md: model: sonnet`, `MISSING in agents/implementer.md: effort: high`, `STILL PRESENT in agents/implementer.md: model: haiku`, `STILL PRESENT in skills/development-workflow/SKILL.md: only to override the definition for one case`, and one `MISSING` for each of the other six strings.

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
   exception: Sonnet is for tasks where an implementation has to be built.
   Record the model in the ledger note (`flow-state task N started
   "base=… model=haiku"`), so fix rounds can be read per model later.
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

`skills/development-workflow/SKILL.md`, Model & effort — replace

```
Agent tool call itself takes `model` but no effort. Pass `model:` on a dispatch
only to override the definition for one case.
```

with

```
Agent tool call itself takes `model` but no effort. Pass `model:` on a dispatch
to override the definition — routinely `haiku` for surgical implementer tasks.
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

and add, as a new paragraph directly after that one:

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
