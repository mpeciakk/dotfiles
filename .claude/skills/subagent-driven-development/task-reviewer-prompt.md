# Task Reviewer Prompt Template

One reviewer reads one task's diff and returns two verdicts: spec compliance
and code quality. This is a task-scoped gate — the broad review happens once,
after all tasks.

## Filling this template

- `[MODEL]` — required. Per development-workflow's table; keep the reviewer at
  least as strong as the implementer, so anything beyond a small mechanical
  diff goes to Opus 5.
- `[BRIEF_FILE]` — the same brief the implementer worked from
  (`~/.claude/skills/subagent-driven-development/scripts/task-brief PLAN N`).
- `[REPORT_FILE]` — where the implementer wrote its detailed report.
- `[BASE_SHA]` / `[HEAD_SHA]` — the base recorded in task N's ledger note
  (`flow-state show`), and the current head.
- `[DIFF_FILE]` — required. The path printed by
  `~/.claude/skills/subagent-driven-development/scripts/review-package BASE HEAD`.
- `[GLOBAL_CONSTRAINTS]` — the binding requirements copied **verbatim** from the
  plan's Global Constraints or the spec: exact values, exact formats, and stated
  relationships between components ("same layout as X", "matches Y"). This block
  is the reviewer's attention lens, so it carries what THIS project demands —
  the process rules are already in the template below.

Two things not to add: open-ended directives ("check all uses", "run race tests
if useful") without a concrete task-specific reason, and any instruction to
re-run tests the implementer already ran on this code.

```
Subagent (general-purpose):
  description: "Review Task N (spec + quality)"
  model: [MODEL]
  prompt: |
    You are reviewing one task's implementation: whether it matches its
    requirements, and whether it is well built. This is a task-scoped gate,
    not a merge review — a whole-branch review happens separately later.

    ## What was requested

    Read the task brief: [BRIEF_FILE]

    Global constraints that bind this task:
    [GLOBAL_CONSTRAINTS]

    ## What the implementer claims they built

    Read the implementer's report: [REPORT_FILE]

    Treat it as unverified claims and check them against the diff. Design
    rationales are claims too: "left it per YAGNI" or "kept it simple
    deliberately" is the implementer grading their own work. Judge the code on
    its merits — a stated rationale never downgrades a finding.

    ## The diff

    **Base:** [BASE_SHA]  **Head:** [HEAD_SHA]  **File:** [DIFF_FILE]

    Read the diff file once: it holds the commit list, the stat summary, and
    the full diff with surrounding context, and it is your view of the change.
    Its context lines ARE the changed files — do not Read a changed file
    separately unless a hunk you must judge is cut off mid-function, and say so
    if you do. Do not re-run git commands. If the file is missing, fall back to
    `git diff --stat [BASE_SHA]..[HEAD_SHA]` and `git diff [BASE_SHA]..[HEAD_SHA]`.

    Do not crawl the wider codebase. Look outside the diff only for a concrete
    risk you can name — one focused check per named risk, naming both the risk
    and what you checked. Cross-cutting changes are legitimate named risks: if
    the diff changes lock ordering, an API contract, or shared mutable state,
    checking the call sites is the right method — use codebase-memory
    (`trace_path`, `get_code_snippet`) rather than grepping the tree.

    Your review is read-only on this checkout: do not touch the working tree,
    the index, HEAD, or branch state.

    ## Tests

    The implementer ran the tests and reported results with TDD evidence for
    exactly this code. Do not re-run the suite to confirm it. Run a test only
    when reading the code raises a specific doubt no existing run answers —
    then a focused test, never a package-wide suite, race detector, or
    repeated high-count loop. If heavy validation seems warranted, recommend it
    instead of running it. Warnings or noise in the reported output are
    findings: test output should be pristine.

    Check the evidence exists before trusting it. For every new behavior in this
    diff the report must show a RED command whose output fails for the stated
    reason, then a GREEN one. Missing RED output, or a RED that would have failed
    for an unrelated reason (import error, syntax), is an **Important** finding —
    "TDD evidence missing/unsound", with the test's file:line. Report it; do not
    substitute a run of your own.

    ## Part 1: Spec compliance

    Compare the diff against what was requested:
    - **Missing:** requirements skipped, or claimed but not implemented
    - **Extra:** anything not requested — over-engineering, "nice to haves"
    - **Misunderstood:** right feature built wrong, or wrong problem solved

    If a requirement cannot be verified from this diff alone (it lives in
    unchanged code or spans tasks), report it as ⚠️ rather than widening your
    search.

    If this task's job was to bring the project's living spec back in line with
    the code (its brief names spec sections), that IS the deliverable: check each
    named section against what the branch actually built, and treat a section
    left describing the old behaviour as a missed requirement, not a nitpick. A
    spec that lies is worse than one that is merely thin.

    ## Part 2: Code quality

    - Separation of concerns; error handling; DRY without premature
      abstraction; edge cases
    - Tests that verify real behavior rather than mocks, covering this task's
      edge cases
    - Structure: one clear responsibility per file, units understandable and
      testable independently, the plan's file structure followed. Flag files
      this change made large or grew significantly — not pre-existing size.

    Point at evidence: file:line for every finding, and for any check you would
    otherwise answer with a bare "yes".

    ## Calibration

    Not everything is Critical. **Important** means the task cannot be trusted
    until it is fixed: incorrect or fragile behavior, a missed requirement, or
    maintainability damage worth blocking a merge over — verbatim duplication of
    a logic block, swallowed errors, tests that assert nothing. "Coverage could
    be broader" and polish are **Minor**.

    If the brief or plan explicitly mandates something this rubric calls a
    defect, that IS a finding — report it as Important, labeled plan-mandated.
    The plan does not get to grade its own work; the human decides.

    Lead with problems. Mention a strength only when it is load-bearing (a
    correct decision worth preserving), never as a cushion. Do not invent
    issues to look thorough: if an axis is clean, say so in one line.

    ## Output format

    Your final message IS the report. Begin with the spec verdict; every line is
    a verdict, a finding with file:line, a check you ran, or a finding's
    confidence and what would change it — no preamble, no process narration, no
    closing summary.

    ### Spec Compliance
    - ✅ Spec compliant | ❌ Issues found: [what, with file:line]
    - ⚠️ Cannot verify from diff: [what, and what the controller should check]

    ### Issues
    #### Critical (Must Fix)
    #### Important (Should Fix)
    #### Minor (Nice to Have)
    For each: file:line, what is wrong, why it matters, how to fix if not obvious.

    ### Strengths (only if load-bearing)

    ### Assessment
    **Task quality:** [Approved | Needs fixes]
    **Reasoning:** [1-2 sentences]
```

A single fix dispatch can address spec gaps and quality findings together; the
re-review covers both verdicts again.
