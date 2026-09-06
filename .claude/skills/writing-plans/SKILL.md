---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

A plan is complete when an implementer with no session history can execute each task from the task text alone. Complete, not comprehensive — nothing in it that a task does not need. Write it assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Three things the next stage depends on — do them, don't just read them:**
1. **Commit the plan file** before any worktree exists. The worktree branches
   from HEAD, so an uncommitted plan is absent from the branch the implementers
   build on and from its history.
2. **Record it absolute:** `flow-state set stage=plan plan="$(git rev-parse
   --show-toplevel)/.flow/plans/<file>.md"`. A relative path breaks from any
   subdirectory.
3. **Wait for the user's "go"** before execution. Details in Execution Handoff.

**Save plans to:** `.flow/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

Do this mapping with cbm before Grep/Read: `search_graph` to locate the code you'll touch, `trace_path` to see what calls it (impact / blast radius), and `get_code_snippet` to copy exact signatures verbatim into each task's Interfaces block.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## External Dependencies Get Verified Before They Get Built On

If a task's correctness depends on the real behavior of something outside this
codebase — a third-party API's response shape, a tool's actual flag semantics,
a service's real data — that assumption gets one task making one real,
low-cost check (a single request, reading the actual docs, a smoke call)
**before** any task that builds validation, parsing, or handling logic on top
of it. Put it early in the task order, not folded into the task that uses it.

This is not caution for its own sake: in a real run, four review rounds
confirmed a ClickUp integration matched its design spec, and none of them could
catch that the spec described a different ClickUp instance than the real one
— because nothing had made one real call yet to check. Internal review
verifies the code against the plan; it cannot verify the plan against reality.
One cheap empirical check up front is worth more than an arbitrarily thorough
review of code built on an unverified assumption.

## Keeping the Living Spec True

The decision this change made is already in the spec's decision table
(brainstorming put it there at the gate). What is *not* there yet is everything
the spec says about **state** — architecture, data model, API contracts,
behaviour it documents — because none of it existed when the design was approved.

**If this change alters any of that, the plan's last task updates those spec
sections**, listing them by heading, alongside the code that made them true. It
is a normal task: dispatched, diffed, reviewed with the change it describes. That
is the whole mechanism — a spec updated in the same branch, by the same review,
is a spec that stays true; a "remember to update the docs" note at the end is how
five of this user's seven specs went a month without a touch while their code
moved on.

Skip that task when the change genuinely alters nothing the spec states (a
bugfix restoring documented behaviour, an internal refactor). Say so in one line
in the plan rather than leaving it ambiguous.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Spec:** [absolute path to the project's living spec.md, and the decision
number this change added to it — e.g. `spec.md` D18. Omit only if the project
has no living spec.]

**Design record:** [path to `.flow/specs/<date>-<topic>-design.md`]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. If the spec has none, write `None.` and
keep the heading: `task-brief` prepends this section to every task's brief, and
the reviewer is handed it verbatim.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps. Then the reverse check: which sections of the *living* spec will this change make untrue? Each one is either named in the final spec-sync task or explicitly out of scope.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Red-Team Pass

After self-review, before offering execution, dispatch a fresh adversarial subagent to argue the plan is wrong — see [red-team.md](red-team.md) for when to run it, when to skip it, and the dispatch. Surface its ranked objections with your own honest take on each, and resolve the blocking ones — by amending the plan or an explicit user decision — before execution starts.

## Execution Handoff

Save the plan, record it, run the red-team pass, then present a short summary
(plan location, task count, red-team verdict) and **wait for the user's "go"**.
This is a gate — do not start execution on your own.

```bash
git add .flow/plans/<filename>.md && git commit -m "plan: <feature>"
~/.claude/hooks/flow-state set stage=plan plan="$(git rev-parse --show-toplevel)/.flow/plans/<filename>.md"
```

**Commit the plan before execution starts.** The worktree branches from HEAD, so
an uncommitted plan is absent from the workspace the implementers work in, and
the first `task-brief` call fails with "no such plan file". Record the path
absolute — a repo-relative one breaks the moment a command runs from a
subdirectory.

Note for the user in your summary: this commit and the spec commit land on the
branch they are on now (often `main`), before any worktree exists. That is
deliberate — the worktree branches from HEAD and needs them — but say it rather
than leaving them to discover two commits on main.

Announce: "Plan complete and saved to `.flow/plans/<filename>.md`. [Red-team verdict.] Say 'go' to execute."

**Once the user approves, unless they ask otherwise:**
- **REQUIRED SUB-SKILL (first):** using-git-worktrees — isolated workspace, recorded in the run state, clean test baseline, before any task runs.
- **THEN REQUIRED SUB-SKILL:** subagent-driven-development — a fresh implementer subagent per task, a per-task review (one reviewer, two verdicts: spec compliance + code quality), and a whole-branch review at the end. You coordinate; you do not write the code.

**Inline execution** — only when the user explicitly asks for it in this turn,
never as your own shortcut past dispatching. Record the decision so the
guards stand down and it stays visible: `~/.claude/hooks/flow-state set
stage=inline`. Then work each task's bite-sized steps in order, run the
verifications each step specifies, pause at natural checkpoints — still in a
worktree (using-git-worktrees), still finishing via
finishing-a-development-branch.
