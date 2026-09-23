## Global Constraints

- Edit only under `.claude/` of the worktree you were given. Never through `~/.claude/…` paths: those are symlinks into the main checkout, not your worktree.
- Skill and agent prose is English; keep each file's existing voice, heading style and line wrapping (~80 columns).
- Surgical: change only the passages each task names. No rewording of neighbouring sections.
- Model names are exactly `Sonnet 5`, `Haiku 4.5`, `Opus 5.5`; agent frontmatter uses the aliases `sonnet`, `haiku`, `opus`.
- After every task, `bash .claude/hooks/flow-guard-test` still ends `124 passed, 0 failed`. It includes a wall-clock assertion: a latency-only failure gets one re-run before it counts.

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
flat() { tr '\n' ' ' < "$1" | tr -s ' '; }
has() { flat "$1" | grep -qF -- "$2" || { echo "MISSING in $1: $2"; fail=1; }; }
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
