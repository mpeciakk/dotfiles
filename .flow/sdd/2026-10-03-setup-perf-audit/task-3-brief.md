## Global Constraints

- Do not touch `config/`, `hosts/`, or `config/mimeapps.list` — unrelated user changes live there.
- Hooks and scripts stay python3/bash with the standard library only; keep each file's existing style and comment density.
- `.claude/settings.json`: valid JSON, 2-space indentation, existing key order kept where a key survives.
- `CLAUDE.md` stays Polish; skills, agents and README stay English.
- The hook test suites must end green: `/home/m/dotfiles/.claude/hooks/flow-guard-test` and `/home/m/dotfiles/.claude/hooks/prompt-context-test` (run them from the worktree path — they test the files beside them).
- Cite code in docs by path and symbol, never by line number.
- The repo is PUBLIC and run reports under `.flow/sdd/` get committed: never copy the contents of any `settings.local.json`, `.credentials*`, `~/.claude.json` or env values into a report, test, script or commit — key names only (`python3 -c 'import json,sys; print(sorted(json.load(open(sys.argv[1]))))' FILE`).
- Run commands with literal paths (no `$(…)`, no `VAR=$(…) cmd $VAR`): the harness's worktree guard refuses computed commands. Throwaway check scripts live in `.flow/sdd/2026-10-03-setup-perf-audit/` and resolve their root from their own path.
- Live config is the main checkout (`~/.claude/*` symlinks into `/home/m/dotfiles`), so nothing in the worktree takes effect until merge + `dotter deploy`; verify settings with `claude --settings <file>`.

---

### Task 3: agent definitions — Artifact and Skill off, reviewers build their own diff package

**Files:**
- Modify: `.claude/agents/implementer.md`, `.claude/agents/fixer.md`, `.claude/agents/task-reviewer.md`, `.claude/agents/branch-reviewer.md`, `.claude/agents/plan-red-team.md`
- Modify: `.claude/skills/subagent-driven-development/SKILL.md` (per-task loop step 5 and the "Your prompt supplies" table), `.claude/skills/requesting-code-review/SKILL.md` (How, step 2 and step 3)
- Test: `.claude/hooks/flow-guard-test` (new section)

**Interfaces:**
- Consumes: `review-package BASE HEAD` (existing; exit 4 = empty range).
- Produces: reviewers' prompts now carry BASE and HEAD instead of a diff-package path.

- [ ] **Step 1: Write the failing tests** — append to the end of the existing `=== agent definitions ===` section of `flow-guard-test` (no second header):

```bash
AG=$(cd "$HERE/../agents" && pwd)
fm() { awk '/^---$/{n++; next} n==1' "$AG/$1.md"; }
for a in implementer fixer task-reviewer branch-reviewer plan-red-team; do
  d=$(fm "$a" | grep '^disallowedTools:')
  case "$d" in *Artifact*Skill*|*Skill*Artifact*) report ok "$a withholds Artifact and Skill";;
    *) report no "$a withholds Artifact and Skill" "$d";; esac
done
for a in task-reviewer branch-reviewer; do
  grep -q 'scripts/review-package' "$AG/$a.md" && grep -q 'exit 4' "$AG/$a.md" && grep -q 'BLOCKED' "$AG/$a.md" \
    && report ok "$a builds its own diff package; exit 4 is BLOCKED" || report no "$a review-package step"
done
for a in implementer fixer; do
  grep -q 'polszczyzna/SKILL.md' "$AG/$a.md" && grep -q 'systematic-debugging/SKILL.md' "$AG/$a.md" \
    && report ok "$a knows the skill files it can no longer invoke" || report no "$a skill pointers"
done
SK=$(cd "$HERE/../skills" && pwd)
for f in subagent-driven-development/SKILL.md requesting-code-review/SKILL.md; do
  grep -qE 'PKG=|generate the review package|without a diff file|\[review-package|Package it with' "$SK/$f" \
    && report no "$f still has the controller build the review package" || report ok "$f: reviewer builds the package"
done
grep -q 'BLOCKED' "$SK/subagent-driven-development/SKILL.md" && grep -q 'git log --all --oneline -5' "$SK/subagent-driven-development/SKILL.md" \
  && report ok "SDD says what a reviewer BLOCKED on an empty range means" || report no "SDD reviewer BLOCKED handling"
```

- [ ] **Step 2: Run to verify it fails**

Run: `.claude/hooks/flow-guard-test | grep -E 'Artifact and Skill|diff package|skill pointers|knows the skill|review package|builds the package|BLOCKED'`
Expected: FAIL for all five agents, both reviewers, both writers' pointers, both skills, and the BLOCKED check.

- [ ] **Step 3: Implement**
- Frontmatter: implementer and fixer get `disallowedTools: Artifact, Skill` (they have none today); task-reviewer, branch-reviewer, plan-red-team become `disallowedTools: Edit, Write, NotebookEdit, Artifact, Skill`. `skills: test-driven-development` stays — preloading does not need the Skill tool.
- implementer.md and fixer.md: two sentences — "You have no Skill tool. Text in Polish meant for people (docs, spec.md, Polish commit messages): read `~/.claude/skills/polszczyzna/SKILL.md` first. A bug or unexpected test result: read `~/.claude/skills/systematic-debugging/SKILL.md` and follow it."
- task-reviewer.md, section "The diff is your view of the change": first instruction becomes "Your prompt gives BASE and HEAD. Run `~/.claude/skills/subagent-driven-development/scripts/review-package <BASE> <HEAD>` (literal SHAs) and read the file it prints, once. Exit 4 means the range has no commits: report BLOCKED with its message — never APPROVED." Replace "If the file is missing, fall back to…" accordingly. Same for branch-reviewer.md ("What you are given" says BASE and HEAD instead of "a diff file").
- SDD per-task loop: delete step 5 (Review package) and renumber; step 6 (now 5) says the reviewer gets BASE and HEAD and builds the package itself; on a re-review pass the same `BASE` and the new HEAD. In the "Your prompt supplies" table, task-reviewer: "brief path, implementer report path, BASE and HEAD…" (drop "diff-package path"); branch-reviewer: "…BASE and HEAD…" (drop the package path).
- SDD, the other places that still have the controller package the diff: "Implementer status — **DONE** → generate the review package and review" becomes "→ dispatch the task reviewer with BASE and HEAD"; the Example line `[review-package … → dispatch task reviewer]` becomes `[dispatch task reviewer with BASE..HEAD]`; the "Never" item "Dispatch a reviewer without a diff file" becomes "Dispatch a reviewer without BASE and HEAD".
- SDD, after the reviewer step: "A reviewer BLOCKED on 'no commits in BASE..HEAD' means the implementer's commits are not in this tree: find them (`git log --all --oneline -5`) before anything else — never re-dispatch the reviewer unchanged." This replaces the empty-range guidance that lived in the deleted step 5.
- requesting-code-review: delete step 2 (Package the diff) and renumber; step 3 (now 2) prompt carries BASE and HEAD, no package path; step 4's "Package it with `review-package <fixbase> HEAD`" becomes "dispatch the re-review with BASE = the fix base and HEAD".

- [ ] **Step 4: Run to verify it passes**

Run: `.claude/hooks/flow-guard-test | tail -1`
Expected: `N passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/agents .claude/skills/subagent-driven-development/SKILL.md .claude/skills/requesting-code-review/SKILL.md .claude/hooks/flow-guard-test
git commit -m "agents: no Artifact/Skill; reviewers build their own diff package (D9, D12, D18)"
```

---
