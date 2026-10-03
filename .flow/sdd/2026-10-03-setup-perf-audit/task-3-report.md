# Task 3 report: agent definitions

Commit: 7a43e12 "agents: no Artifact/Skill; reviewers build their own diff package (D9, D12, D18)"

## Implemented
- Frontmatter: implementer and fixer gained `disallowedTools: Artifact, Skill`; task-reviewer, branch-reviewer, plan-red-team now `Edit, Write, NotebookEdit, Artifact, Skill`. `skills: test-driven-development` untouched.
- implementer.md, fixer.md: the two "no Skill tool" sentences with the polszczyzna and systematic-debugging file pointers (as a short paragraph after the iteration/commit paragraph).
- task-reviewer.md and branch-reviewer.md: "What you are given" says BASE and HEAD; the diff section tells the reviewer to run `review-package <BASE> <HEAD>` and read the printed file once; an exit 4 is BLOCKED, never APPROVED / a verdict. The task-reviewer's "if the file is missing, fall back to git diff" sentence is removed.
- subagent-driven-development/SKILL.md: per-task step 5 (Review package) deleted, steps renumbered (reviewer = 5, fix loop = 6, record = 7); the BLOCKED-on-empty-range paragraph (`git log --all --oneline -5`) added under the reviewer step; re-review passes the same BASE and the new HEAD; DONE status line, prompt table (task-reviewer, branch-reviewer), Example line and the "Never" item reworded. Cross-references fixed: "(step 7)" in Never -> "(step 6)"; "requesting-code-review, step 4" (x2) -> "step 3". References to "step 3" (implementer dispatch) are unchanged and still valid (also in development-workflow/SKILL.md).
- requesting-code-review/SKILL.md: Package step deleted, renumbered (Dispatch = 2, Act = 3); prompt carries BASE and HEAD, no package path; re-review text "dispatch the re-review with BASE = the fix base and HEAD".

## TDD evidence
RED (new section appended to `=== agent definitions ===` in flow-guard-test before any edit to agents/skills):

    $ .claude/hooks/flow-guard-test | grep -E 'FAIL|passed'
    FAIL  implementer withholds Artifact and Skill
    FAIL  fixer withholds Artifact and Skill
    FAIL  task-reviewer withholds Artifact and Skill   disallowedTools: Edit, Write, NotebookEdit
    FAIL  branch-reviewer withholds Artifact and Skill disallowedTools: Edit, Write, NotebookEdit
    FAIL  plan-red-team withholds Artifact and Skill   disallowedTools: Edit, Write, NotebookEdit
    FAIL  SDD reviewer BLOCKED handling
    141 passed, 12 failed

12 failures = 5 frontmatter + 2 reviewer review-package + 2 writer skill pointers + 2 skill "controller builds package" + 1 BLOCKED handling, i.e. exactly the expected set (the pre-existing 141 stayed green). Expected because none of the agent/skill text existed yet.

GREEN (after the edits):

    $ .claude/hooks/flow-guard-test | tail -1
    153 passed, 0 failed
    $ .claude/hooks/prompt-context-test | tail -1
    17 passed, 0 failed

Output pristine (no FAIL lines, no stray noise).

## Files changed
.claude/agents/{implementer,fixer,task-reviewer,branch-reviewer,plan-red-team}.md; .claude/skills/subagent-driven-development/SKILL.md; .claude/skills/requesting-code-review/SKILL.md; .claude/hooks/flow-guard-test.

## Self-review
- No remaining `diff file`, `diff-package`, `PKG`, or `review-package` mentions in the two skills (grep). The `$SDD` variable in per-task step 1 is still used by `task-brief`, so it stays.
- Test greps are case-sensitive on `exit 4`; wording is "An exit 4 means ..." in both reviewers.

## Concerns
- implementer.md still says "the only downstream check is `review-package` refusing an empty commit range". Still true (now run by the reviewer); not in the brief, left alone.
- The new tests are string-presence checks on prose, not behaviour; that is what the brief specified.
