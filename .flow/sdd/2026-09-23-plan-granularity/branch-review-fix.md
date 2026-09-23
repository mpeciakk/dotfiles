# Branch-review fixes (plan-granularity)

Two findings from the whole-branch review; the user decided finding 1 (narrow
the Haiku rule: decision code stays on Sonnet). Apply the text below exactly,
in the worktree's `.claude/` files.

## Check (save outside the repo, run: RED before, PASS after)

```bash
#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)/.claude"; fail=0
flat() { tr '\n' ' ' < "$1" | tr -s ' '; }
has()   { flat "$1" | grep -qF -- "$2" || { echo "MISSING in $1: $2"; fail=1; }; }
hasnt() { ! flat "$1" | grep -qF -- "$2" || { echo "STILL PRESENT in $1: $2"; fail=1; }; }
S=skills/subagent-driven-development/SKILL.md; W=skills/development-workflow/SKILL.md
has   $S 'flow-state task N started "base=$BASE model=<haiku|sonnet>"'
has   $S 'a second `task N` call replaces the first and drops `base=`'
has   $S 'transcribing that is where a wrong plan gets caught'
hasnt $S 'Record the model in the ledger note'
hasnt $S 'fully-specified'
hasnt $S 'fully specified'
has   $W 'decision code in a brief stays on Sonnet'
hasnt $W 'fully-specified'
has   README.md 'paste-ready tasks (decision code stays on Sonnet)'
hasnt README.md 'fully-specified'
[ $fail = 0 ] && echo PASS || exit 1
```

Then `bash .claude/hooks/flow-guard-test | tail -1` → `124 passed, 0 failed`.

## Finding 1 — Haiku rule narrowed (user decision)

`skills/subagent-driven-development/SKILL.md`, loop step 3 — replace

```
   below for what the prompt carries. **Pick the model first.** The definition
   runs Sonnet 5; pass `model: "haiku"` for every task that is small, surgical
   or fully specified — a spec sync, a config or one-value change, a task whose
   brief already holds the complete change. Haiku is the rule, not the
   exception: Sonnet is for tasks where an implementation has to be built.
   Record the model in the ledger note (`flow-state task N started
   "base=… model=haiku"`), so fix rounds can be read per model later.
```

with

```
   below for what the prompt carries. The definition runs Sonnet 5; pass
   `model: "haiku"` for every task that is small, surgical or paste-ready — a
   spec sync, a config or one-value change, a brief whose complete change is
   text to insert as given. Haiku is the rule for those, not the exception.
   Sonnet takes tasks where an implementation has to be built, and tasks whose
   brief carries decision code (an algorithm, a format, a lock order, the first
   instance of a pattern): transcribing that is where a wrong plan gets caught.
```

`skills/subagent-driven-development/SKILL.md`, Dispatching — replace

```
surgical or fully-specified implementer task (step 3), `opus` for a
```

with

```
surgical or paste-ready implementer task (step 3), `opus` for a
```

`skills/development-workflow/SKILL.md`, model table — in the `implementer` row
replace `for every small, surgical or fully-specified task` with
`for every small, surgical or paste-ready task — decision code in a brief stays on Sonnet`.

`README.md`, Model & effort — replace

```
small, surgical or fully-specified tasks; fixer and task-reviewer **Sonnet 5 · high**
```

with

```
small, surgical or paste-ready tasks (decision code stays on Sonnet); fixer and
task-reviewer **Sonnet 5 · high**
```

## Finding 2 — model recorded with the base, in one ledger call

`flow-state task N …` replaces the whole entry for task N, so a separate
`model=` call would erase `base=`. `skills/subagent-driven-development/SKILL.md`,
loop step 2 — replace

```
2. **Record the base** before dispatching, in the ledger — a compaction between
   dispatch and review would otherwise lose it, and `HEAD~1` silently drops all
   but the last commit of a multi-commit task:

   ```bash
   BASE=$(git rev-parse HEAD)
   ~/.claude/hooks/flow-state task N started "base=$BASE"
   ```
```

with

```
2. **Record the base and the model** before dispatching, in the ledger — a
   compaction between dispatch and review would otherwise lose the base, and
   `HEAD~1` silently drops all but the last commit of a multi-commit task. Pick
   the model first (step 3's rule) and record it every time, `sonnet` included,
   so fix rounds can be read per model. One `started` entry per task: a second
   `task N` call replaces the first and drops `base=`.

   ```bash
   BASE=$(git rev-parse HEAD)
   ~/.claude/hooks/flow-state task N started "base=$BASE model=<haiku|sonnet>"
   ```
```

Commit message: `sdd: decision code stays on Sonnet; model recorded with the base`
