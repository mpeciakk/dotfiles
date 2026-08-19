---
name: using-git-worktrees
description: Use when starting feature work that needs an isolated workspace (git worktree), or before executing an implementation plan
---

# Using Git Worktrees

Put the work in an isolated workspace and **write down where it is**. A
worktree nobody recorded is a worktree the next turn loses — and lost
workspaces are how commits end up on main.

**One mechanism:** the native `EnterWorktree` tool. It creates the worktree,
switches this session into it, and lets the harness manage cleanup. Reaching
for `git worktree add` while that tool exists creates a workspace the harness
cannot see — that is the mistake this skill exists to prevent. Invoking this
skill *is* the project instruction `EnterWorktree` asks for.

**Announce:** "Setting up an isolated workspace (using-git-worktrees)."

## Step 0 — already isolated?

```bash
git rev-parse --git-dir --git-common-dir --show-toplevel
git branch --show-current
git rev-parse --show-superproject-working-tree   # non-empty ⇒ submodule, not a worktree
```

Different git-dir and git-common-dir (and not a submodule) means you are
already in a linked worktree. Do not create another — record it (Step 2) and
go to Step 3.

Otherwise you are in a normal checkout. CLAUDE.md's standing rule — pipeline
implementation happens in a worktree — is the consent; do not stop to ask for it
again. Ask only if the user has said otherwise in this session, and if they
decline isolation, work in place: create a feature branch first if HEAD is on
main/master, then record it with Step 2's block anyway — `worktree` pointing at
this checkout. Skipping the record leaves the run without a workspace, which
disables the guards *and* blocks `stage=finish` later.

## Step 1 — create it

**Before creating it, make sure the spec and plan are committed.** The worktree
branches from your current local HEAD (`worktree.baseRef: "head"` in
settings.json — with the harness default `"fresh"` it would branch from
`origin/<default>` and contain neither). Uncommitted, they are absent from the
branch the implementers build on and from its history, and the spec is not there
for anyone reading the branch later.

Call `EnterWorktree` with a name derived from the work (`feat/json-export`). It
creates the worktree under `.claude/worktrees/`, switches this session into it,
and lets the harness handle cleanup.

Once it exists, confirm it is ignored **in the main checkout** — that is where
an unignored worktree directory shows up in `git status` and where `git add -A`
would stage it as an embedded repository:

```bash
MAIN=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
git -C "$MAIN" check-ignore -q .claude/worktrees || {
  echo '.claude/worktrees/' >> "$MAIN/.gitignore"
  git -C "$MAIN" add .gitignore && git -C "$MAIN" commit -m "chore: ignore worktrees"
}
```

Both the edit and the commit need `-C "$MAIN"`: run from inside the worktree they
land on the feature branch and leave the main checkout still dirty. Run the check
*after* creation — `check-ignore` calls a directory that does not exist yet
not-ignored even when the pattern covers it.

Fallback, only if `EnterWorktree` is unavailable: `git worktree add
.worktrees/<branch> -b <branch>` (same ignore check), and then
`EnterWorktree` with `path` pointing at it — that is what moves this session's
cwd into the worktree. Skip that and every subagent inherits the main
checkout's directory while the run believes it is isolated. If creation fails
on a sandbox permission error, say so and work in place.

## Step 2 — record the workspace

```bash
~/.claude/hooks/flow-state set \
  stage=isolate \
  worktree="$(git rev-parse --show-toplevel)" \
  branch="$(git branch --show-current)" \
  base="$(git rev-parse HEAD)"
```

If that prints "no run state", nobody opened the run: `flow-state init
<task-slug>` and re-run the block. An unrecorded workspace silently disables
every guard — the controller may then edit code freely with no message.

Recording is what turns the workspace from something remembered into something
the tooling can act on: from here on every subagent is told which tree and
branch it owns (a SubagentStart hook injects it), a second workspace is refused,
and the controller can no longer edit code itself. `base` is the branch's
starting commit, which the whole-branch review reads instead of guessing a merge
base.

On a detached HEAD, record the worktree and note that a branch has to be created
at finish time.

## Step 3 — setup and clean baseline

Install what the project needs (`package.json` → `npm install`, `Cargo.toml` →
`cargo build`, `pyproject.toml`/`requirements.txt` → poetry/pip, `go.mod` →
`go mod download`), then run the test suite.

Tests must be green *before* your changes exist — otherwise you cannot tell
your bugs from the ones you inherited. If they fail, report the failures and
ask whether to proceed or investigate.

Record that it happened, so a resumed run does not pay for the install and the
full suite twice — and so nothing infers "baseline done" from the workspace
being recorded, which happens one step earlier:

```bash
~/.claude/hooks/flow-state task 0 done "baseline green: <result>"
```

Report: worktree path, branch, test result, and what you are about to
implement.

## Never

- Create a worktree when Step 0 already found one — including any subagent
  creating its own. Subagents work in the tree they are given.
- Use `git worktree add` when `EnterWorktree` is available.
- Start implementation on main/master without explicit consent.
- Skip the baseline run, or proceed past failing baseline tests silently.
