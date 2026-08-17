---
name: requesting-code-review
description: Use when you want a fresh reviewer on completed work — "review my changes", "code review this", "review the branch", before merging to main, or for the whole-branch review at the end of subagent-driven-development. Per-task review inside a plan run uses subagent-driven-development's own reviewer template.
---

# Requesting Code Review

Dispatch a reviewer subagent to catch issues before they cascade. It gets
precisely crafted context — never your session history — so it judges the work
product rather than your thought process, and your own context stays free for
the work.

This template is for the **whole-branch review** at the end of
subagent-driven-development, and for ad-hoc reviews. Per-*task* review has its
own template (`../subagent-driven-development/task-reviewer-prompt.md`).

Request one after a major feature, before merging to main, and when a fresh
perspective would help: stuck on something, about to refactor, just fixed a
subtle bug.

## How

**1. Bound the diff.** BASE is where the work under review began — the branch
fork point, or the commit you recorded before starting. Never `HEAD~1`: it
silently drops all but the last commit of multi-commit work.

```bash
BASE_SHA=$(~/.claude/hooks/flow-state get base)          # the run records it
[ -n "$BASE_SHA" ] || BASE_SHA=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
HEAD_SHA=$(git rev-parse HEAD)
```

If both fall through — a repo whose default branch is `trunk` or `develop` —
ask the user which branch this work forked from rather than packaging an empty
or oversized range.

**2. Package the diff as a file**, so it never enters your context and the
reviewer reads it in one call:

```bash
PKG=$(~/.claude/skills/subagent-driven-development/scripts/review-package "$BASE_SHA" "$HEAD_SHA")
```

**3. Dispatch** a `general-purpose` subagent with [code-reviewer.md](code-reviewer.md),
filling `[DESCRIPTION]` (what you built), `[PLAN_OR_REQUIREMENTS]` (what it
should do), `[MINOR_FINDINGS]` (the run's deferred findings, in their own block —
not mixed into the requirements), `[BASE_SHA]`, `[HEAD_SHA]`, and `[DIFF_FILE]`.
Model per development-workflow's table — the final review earns Opus 5.

**4. Act on it.** Critical and Important findings go to ONE fix subagent with
the complete list; Minor findings get recorded, not silently dropped. If the
reviewer is wrong, push back with the code or test that proves it — but never
pre-empt a finding by telling the reviewer what not to flag.
