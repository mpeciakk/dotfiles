# Task 3 Report: plan-red-team — the most severe objection decides

## Implementation

Updated the red-team agent and skill documentation to clarify verdict rules: any blocking or serious objection rules out PROCEED; with only minor objections, the verdict is PROCEED and those minor items are applied directly by the plan writer without requiring a gate/debate.

## Test-Driven Development Evidence

### RED (Failing Test)

**Command:**
```bash
bash /tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-task3.sh
```

**Output:**
```
Exit code 1
MISSING in agents/plan-red-team.md: Any blocking or serious objection rules out PROCEED
MISSING in agents/plan-red-team.md: with minor objections only, the verdict is PROCEED
MISSING in skills/writing-plans/red-team.md: Branch on the most severe objection in the report, not on its label
MISSING in skills/writing-plans/red-team.md: apply the minor list to the plan yourself
MISSING in skills/writing-plans/red-team.md: needs a decision from the user
MISSING in skills/writing-plans/red-team.md: name what changed in one line at the plan gate
STILL PRESENT in skills/writing-plans/red-team.md: If the verdict is PROCEED with no blocking objections, say so in one line and
```

**Why expected to fail:** The required text was not yet present in either file. The test checks for six required phrases and the absence of one obsolete phrase.

### GREEN (Passing Test)

**Command after implementation:**
```bash
bash /tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-task3.sh
```

**Output:**
```
PASS
```

**Verification command:**
```bash
bash .claude/hooks/flow-guard-test | tail -1
```

**Output:**
```
124 passed, 0 failed
```

## Changes Made

### File 1: `.claude/agents/plan-red-team.md`

Modified item 3 of the Output section from:
```
3. One-line verdict: PROCEED / PROCEED WITH CHANGES / RETHINK
```

To:
```
3. One-line verdict: PROCEED / PROCEED WITH CHANGES / RETHINK. Any blocking or
   serious objection rules out PROCEED; with minor objections only, the verdict
   is PROCEED and the minor ones are listed under it as edits to apply.
```

### File 2: `.claude/skills/writing-plans/red-team.md`

In the `## After the pass` section:

1. **Inserted new paragraph** at the beginning (before "Surface the ranked objections…"):
```
Branch on the most severe objection in the report, not on its label — a
PROCEED carrying a serious objection, or a report with no verdict line, is
decided by the same rule. Any blocking or serious objection: surface as below.
```

2. **Replaced last paragraph** ("If the verdict is PROCEED with no blocking objections…") with:
```
Minor objections only: apply the minor list to the plan yourself — no gate, no
debate — commit the amended plan, and name what changed in one line at the plan
gate. Skip an item you disagree with and say which and why in that line; an item
that needs a decision from the user goes to the plan gate as a question instead.
```

## Commit

Commit SHA: `5c187e1`
Message: "red-team: the most severe objection decides; minor-only gives PROCEED, applied without a gate"

## Self-Review

- **Completeness:** All requirements met. The exact text blocks from the brief were inserted as specified, without modification.
- **Surgical changes:** Only the two specified files were modified. The changes are precisely targeted to the sections named.
- **Style consistency:** The new text matches the existing voice, heading style, and line wrapping (~80 columns) of the files.
- **Testing:** Both the check script and flow-guard-test pass. The implementation is correct.

## Concerns

None. The task is complete and verified.
