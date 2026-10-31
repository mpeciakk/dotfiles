# Skills cleanup — plan

## Goal
Cut the skill set to what is used and current. Rewrite `writing-skills` and
`systematic-debugging` short. Fold `receiving-code-review` into
`requesting-code-review`. Delete `handoff` and the `test-driven-development`
skill. Make every skill description trigger-only. Brief:
`.flow/specs/2026-10-31-skills-cleanup-brief.md` (approved 2026-10-31, pc). No
living spec in this repo, so this Decisions section is the record.

## Decisions
- D1 A skill description lists only when to use the skill: "Use when…" plus
  triggers and symptoms. It never says what the skill does or the steps of
  its process (user, 2026-10-31, F1). Why: an agent follows a description
  that summarises the process instead of reading the skill. Rejected: "what +
  when" (Anthropic doc; the repo followed it until now), and triggers plus a
  short scope phrase.
- D2 D1 covers every skill in `.claude/skills` except the vendored
  `prompt-master`. Agent descriptions stay as they are: they choose a
  subagent at dispatch, not when a skill triggers (user, 2026-10-31).
  Rejected: only the skills this run touches (the rule would contradict the
  repo on day one); including prompt-master (it would drift from upstream).
- D3 Root-cause tracing at a dead end: add instrumentation one level up (a
  log with a stack trace) and try once more. Still a dead end: guard the
  symptom site with validation and a clear error, and state in the report
  that the origin is unknown (user, 2026-10-31, F4). Rejected: "never fix at
  the symptom" (blocks the work); "fix at the symptom" (masks the bug and
  leaves no trace). systematic-debugging's "No root cause" section follows
  the same rule. A retry or a timeout is allowed only for a cause proven
  environmental or external, and it is logged (red-team #4).
- D4 writing-skills drops its Iron Law ("no skill without a failing test
  first"). Only discipline skills (rules an agent under pressure is tempted
  to skip) need a baseline vs treatment test before they ship. Other skills
  and trivial edits follow CLAUDE.md "Code" (F2). Why: the brief approved
  this; the Iron Law was not followed in any recent setup change.
- D5 writing-skills keeps no reference files. `anthropic-best-practices.md`
  is replaced by links to two live pages (F6):
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
  - https://code.claude.com/docs/en/skills

  Together they cover structure and the frontmatter fields, including
  `disable-model-invocation` and `argument-hint`. D1 overrides the first
  page's "what + when" rule for descriptions. The essential steps
  of `testing-skills-with-subagents.md` go into SKILL.md.
  `persuasion-principles.md` (including the F5 per-task-review example) and
  `examples/CLAUDE_MD_TESTING.md` (F7) are deleted, along with
  `render-graphs.js` and `graphviz-conventions.dot`. The measured
  counter-evidence table moves into SKILL.md as a short section. Its stale
  sentence about TDD's eight-row table gets corrected. The "where it lived"
  column is marked as history, since those rules and skills are gone.
  Rejected: trimming every file (each one costs a read and goes stale on
  its own).
- D6 systematic-debugging references:
  - `root-cause-tracing.md`: kept and trimmed, with one dead-end rule (D3).
    `defense-in-depth.md` folds into it as a short section; the file is
    deleted.
  - `condition-based-waiting.md`: kept and trimmed. Its examples match the
    `waitFor` signature (F12).
  - `condition-based-waiting-example.ts`: deleted (F13).
  - `find-polluter.sh`: kept unchanged.

  The trimmed files turn their `digraph` blocks into prose or numbered
  steps: render-graphs.js goes (D5), and a dead-end rule in a diagram is
  how F4 arose.
- D7 systematic-debugging keeps one list of warning signs. The Red Flags,
  Redirections and Common Rationalizations lists merge into it (F8). The
  pressure coaching and the unsourced "95%" line are removed (F9). The "≥3
  fixes" rule stays as one plain line, pointing to the CLAUDE.md advisor
  rule (same error after 2 fix attempts).
- D8 The systematic-debugging rewrite ships after a staged baseline vs
  treatment eval (user, 2026-10-31, after red-team #1).
  - Setup: each subagent is read-only, gets no Skill tool and is told not
    to invoke skills. The skill text under test is inlined in its prompt,
    so the deployed old copy cannot leak in. Before the first dispatch,
    `.flow/probes/2026-10-31-debugging-eval.md` holds 3 pressure scenarios,
    each naming the one behaviour that counts as a pass (e.g. names a root
    cause before proposing a fix; stops after the third failed fix).
  - Stage 1: the 3 scenarios with no skill (3 runs). If every scenario
    passes, the file records "eval cannot discriminate" and the branch
    review is the check.
  - Stage 2: for each scenario stage 1 failed, old (main) and new, 3 runs
    each. New must pass at least as often as old.
  - New worse: at most 2 wording iterations. Then the task falls back to
    the old SKILL.md with only its links fixed. Verification 3 and 4 then
    hold for the rest of the skill, and the gap goes to the user.
  Why: D4 requires this for a discipline skill; one run per cell, with the
  Skill tool available, could not tell the versions apart. Rejected: 27 runs
  always (cost even when nothing can be measured); no eval (breaks D4).
- D9 `writing-good-tests.md` moves to
  `skills/executing-plans/writing-good-tests.md`. The test-driven-development
  lines that CLAUDE.md does not already hold go to the top of that file:
  - test-first stays the default for a bug fix and for behaviour that is
    easy to state as a test. Wiring, UI, exploration and refactors are
    code-first (W3, lean-workflow-v2). This line also goes into CLAUDE.md
    "Before writing", not only the file;
  - what gets no test;
  - use a fake clock, never the wall clock;
  - see the test fail for the reason you expect;
  - run the full suite and name every failure in it.

  The good/bad test table goes there too. CLAUDE.md "Before writing" gets
  one line pointing to the file. Rejected: keeping a directory with no
  SKILL.md (a non-skill under `skills/`).
- D10 The parts of receiving-code-review that requesting-code-review §3 lacks
  move into §3:
  - verify each finding against the code before acting;
  - an unclear item blocks the rest: ask about it first;
  - external and human (PR) reviewers;
  - GitHub inline replies;
  - the order of work: blockers first, then simple fixes, then complex
    ones, and one suite run after the whole list (red-team #3);
  - scope is not the reviewer's to grant: grep the callers, and propose
    removing unused code instead of finishing it;
  - when to push back, and the reply forms ("Fixed — …", "Checked X — it
    does Y. Fixing.").

  Rejected: dropping these as covered by Candor. Nothing else in `.claude`
  holds them (red-team checked with grep).

  The requesting-code-review description gains the trigger "acting on
  review feedback".

## Constraints
- `hooks/flow-guard-test` and `hooks/prompt-context-test` pass.
- `find ~/.claude/skills -xtype l` is empty after `dotter deploy`. Emptied
  directories: `rmdir` them first, or answer `y` to dotter's prompt.
- `CLAUDE.md` stays under 200 lines (171 now).
- Text in the repo is in English; the `polszczyzna` description stays in
  Polish.

## Verification
On the branch:
1. Both hook test suites pass.
2. `grep -rnIE 'receiving-code-review|test-driven-development|skills/handoff|persuasion-principles|anthropic-best-practices|testing-skills-with-subagents|CLAUDE_MD_TESTING|render-graphs|graphviz-conventions|defense-in-depth\.md|condition-based-waiting-example' .claude --exclude-dir=projects`
   finds nothing. It searches for file and skill names, not concepts.
3. Every relative link in a changed skill resolves.
4. `wc -l`: writing-skills SKILL.md ≤ 180, systematic-debugging SKILL.md
   ≤ 150, CLAUDE.md < 200.
5. The D8 eval file holds the scenarios and pass behaviours, written
   before any run. It also holds the stage 1 results, plus either "cannot
   discriminate" or the stage 2 counts, or the fallback D8 describes.

Before task 1: tag the base `skills-cleanup-pre`. README's rollback line
names it next to `workflow-v2-pre`.

After the merge, on pc:
1. `dotter deploy`, then `find ~/.claude/skills -xtype l` is empty.
2. In a fresh session, the skill list has no `handoff`,
   `receiving-code-review` or `test-driven-development`.

On laptop, before its next session: `dotter deploy` and the same
`-xtype l` check. Until then, the CLAUDE.md pointer there leads to a file
that is not deployed.

## Task 1: review feedback lives in requesting-code-review; handoff gone
**Outcome:** receiving-code-review and handoff no longer exist. Everything
that pointed to receiving-code-review points to requesting-code-review §3.
**Acceptance:**
- §3 holds the four D10 items. Its description triggers on acting on review
  feedback.
- `skills/receiving-code-review/` and `skills/handoff/` are deleted.
- CLAUDE.md (workflow intro), development-workflow "Always on", README "Always-on
  discipline", `agents/branch-reviewer.md` (the verification line) name
  requesting-code-review instead.
- knowledge-transfer: the `handoff` table row and "(handoff)" in its
  description are gone.
**Area:** `skills/requesting-code-review/`, `skills/receiving-code-review/`,
`skills/handoff/`, `CLAUDE.md`, `skills/development-workflow/SKILL.md`,
`README.md`, `agents/branch-reviewer.md`, `skills/knowledge-transfer/SKILL.md`.
**Context:** the brief's item 3 and 4; receiving-code-review sections "By
source", "Unclear items", "GitHub".

## Task 2: test guidance without the test-driven-development skill
**Outcome:** the TDD skill is gone. Its live content is in
`skills/executing-plans/writing-good-tests.md` (D9).
**Acceptance:**
- The moved file opens with the D9 lines and the good/bad table. Its
  existing principles are unchanged.
- Each of W3's five bullets (`.flow/plans/2026-10-31-lean-workflow-v2.md`)
  can be found in CLAUDE.md or in the moved file. The test-first default is
  in CLAUDE.md.
- `skills/test-driven-development/` is deleted.
- CLAUDE.md: line 11 drops test-driven-development. Rule 1 drops "TDD".
  "Before writing" gains the pointer line.
- executing-plans step 3, development-workflow "Always on" and README point
  to the new file or to CLAUDE.md instead of the skill.
**Area:** `skills/test-driven-development/`, `skills/executing-plans/`,
`CLAUDE.md`, `skills/development-workflow/SKILL.md`, `README.md`.
**Context:** the TDD SKILL.md sections "What gets a test", "When the test
comes first" and "Verified means run", compared line by line with CLAUDE.md
"Before writing".

## Task 3: writing-skills rewritten
**Outcome:** a SKILL.md of about 150 lines and no reference files (D5).
**Acceptance:**
- Frontmatter rules match D1: a name, and a trigger-only description.
- Structure and file organisation are covered.
- The baseline vs treatment procedure applies to discipline skills only
  (D4).
- The counter-evidence section holds the measured table and the "write the
  hook" rule.
- None of F1, F2, F5, F6, F7, F11 can still be found in the skill.
- README "Testing" points to the new section.
- `unsettled-flags.md` marks F1, F2, F5, F6, F7 and F11 as settled, naming
  the D numbers.
**Area:** `skills/writing-skills/`, `README.md`,
`.flow/reviews/2026-10-31-setup-review/unsettled-flags.md`.
**Context:** the audit, `.flow/reviews/2026-10-31-setup-review/prompt-audit/slice-b.md`
(H1–H5, M3–M5, F1, F2, F5–F7, F11). The cut of TDD in git history is the
pattern to follow.

## Task 4: systematic-debugging rewritten and evaluated
**Outcome:** a SKILL.md of about 120 lines and references per D6, passing
the D8 eval.
**Acceptance:**
- The four phases stay.
- One list of warning signs (D7). No pressure coaching, no "95%".
- The dead-end rule matches D3 in SKILL.md and in root-cause-tracing.md.
- condition-based-waiting.md has no call that breaks the `waitFor`
  signature. It calls no helper defined only in the deleted `.ts` file
  (`waitForEvent` and its siblings).
- The "No root cause" section matches D3: a retry only for a proven
  environmental cause.
- Test guidance points to writing-good-tests.md (task 2).
- The eval file follows D8's stages, with every run's verdict recorded.
- `unsettled-flags.md` marks F4, F8, F9, F12 and F13 as settled.
**Area:** `skills/systematic-debugging/`, `.flow/probes/`,
`.flow/reviews/2026-10-31-setup-review/unsettled-flags.md`.
**Context:** the audit (H6, M1, M2, M6, F4, F8, F9, F12, F13); the task 3
skill for the eval procedure.

## Task 5: trigger-only descriptions
**Outcome:** every description in `.claude/skills` except prompt-master
follows D1.
**Acceptance:**
- No description summarises what the skill does or its process steps.
  Candidates today: executing-plans, writing-plans, writing-specs,
  polszczyzna, knowledge-transfer, finishing-a-development-branch.
- Words a user would type stay, rewritten as trigger phrases ("the user
  asks to merge, open a PR, keep or discard the branch"). Only the summary
  of the process goes.
- Each one keeps all its triggers, quoted phrases included.
- The "Not for…" exclusions stay where they keep triggers apart.
**Area:** the frontmatter of `skills/*/SKILL.md`.
**Context:** D1 and D2; the description section written in task 3.

## Rulings
- Task 2: two framing sentences in writing-good-tests.md ("Strict TDD produces both naturally", "The TDD cycle … is what 'complete' means") reworded to match W3 — they made test-first mandatory, which W3 dropped — cost if wrong: two sentences to revert.
