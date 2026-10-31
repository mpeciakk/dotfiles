# Prompt audit — slice A (CLAUDE.md, agents, workflow skills)

## Assumptions

- **Scope.** `/home/m/dotfiles/.claude/`. The git root is `/home/m/dotfiles`, and provenance comes from `git blame` there. Files in scope: `CLAUDE.md`, `agents/*.md` (4 files), and these skills: `development-workflow`, `subagent-driven-development` (SKILL.md, plus the scripts `task-brief`, `review-package` and `sdd-workspace`, read only to check commands and flags), `writing-plans` (SKILL.md, `grill-gate.md`), `requesting-code-review`, `receiving-code-review`, `finishing-a-development-branch`, `using-git-worktrees` and `handoff`. These files are symlinked into `~/.claude`, so **every proposed edit affects all projects.**
- **Skipped:** `settings*.json`, `.mcp.json` and `~/.claude.json` were not read. For `hooks/` I only checked that the files exist: `hooks/flow-state` exists, but its subcommands (`init/set/get/show/task/clear`) could not be verified. I did not read the other skills; the other auditors cover them. The claim at using-git-worktrees:42-44 about `worktree.baseRef: "head"` in settings.json is **unverified**. Commands that belong to installed tools (`gh api …/replies`, `EnterWorktree`/`ExitWorktree`, `ScheduleWakeup`, `ListAgents`) were not checked.
- **Target models.** The session files (`CLAUDE.md` and all skills) are audited against **Claude Opus 5.5**. Agents that pin a model are audited against that model: `implementer` (sonnet) → Claude Sonnet 5.5; `branch-reviewer` and `plan-red-team` (opus) → Claude Opus 5.5; `kt-cold-reader` (sonnet) → Claude Sonnet 5.5.
- **Provenance.** Every file in the slice dates from 2026-06-28 to 2026-10-28. The co-author trailers show Opus 5.5 in use from at least 2026-10-10 (commit e8a6200). Findings on text written in that period rest on the documented pattern alone, not on the text being "written for an older model". The three agent `effort` values are the exception: they predate the 5.5 models (see F-M10 and F-L2).

## Summary

The surface is mostly clean. Emphasis is rare: there are three uppercase "BEFORE"s, one "NOT", one "ONLY" and two "IS" across the whole slice. Prohibitions carry their reasons, and the deterministic steps already live in scripts. The highest-impact findings:

1. **Two review skills give opposite rules for one situation (High, flag).** The situation is a branch-reviewer finding that contradicts the plan. receiving-code-review:35-37 says it is always "the user's call". requesting-code-review:57-60 and subagent-driven-development:53-64 say a reversible, in-scope ruling is the controller's to make, logged under `## Rulings`. requesting-code-review tells the model to load receiving-code-review, so the two load together at exactly that moment.
2. **grill-gate.md still points at a stage that no longer exists (High).** It sequences itself against "propose approaches" in three places (lines 10, 25, 52). That stage belonged to the `brainstorming` skill, which commit e8a6200 deleted when it moved this file into writing-plans. writing-plans has no "approaches" step.
3. **The skill text stops at "re-test" on effort and review recall (Medium).** `plan-red-team` runs at `effort: xhigh`, a value set on 2026-08-18 for an earlier Opus. The Opus 5.5 guidance reserves `xhigh` for measured gains and notes that Opus 5.5 thinks more per turn at `xhigh` than Opus 5 did. Separately, branch-reviewer's precision-only framing ("No case, no issue … Never invent issues") has no coverage counterweight. Since Opus 4.7 the docs have said this kind of framing depresses measured review recall. A controller-side filter already exists (receiving-code-review), so per-finding confidence can be added safely.

The user asked about over-engineering. The Group 4 roster check and executor check are both **clean**: there are no redundant agents, and no LLM call does deterministic work. The audit does not rule on workflow design (per-task implementer, mandatory TDD, red-team, review gate); F-L10 explains why. The session-report plugin is installed. Use it to measure per-surface spend before changing the design.

**Counts per group**
- **Group 1 (dated prompt text): 11.** 6 Medium, 5 Low.
- **Group 2 (configuration files): 9.** 3 High (one of them a flag), 3 Medium, 3 Low.
- **Group 3 (tool and agent descriptions): 0.** The agent and skill `description` fields are routing text and are well-bounded.
- **Group 4 (configuration and architecture): 3.** 1 Medium, 2 Low. Request-building code: not applicable. Roster check: clean. Executor check: clean.

---

## Findings — High

### F-H1 — receiving-code-review contradicts requesting-code-review and SDD on plan-contradicting findings
- **Location:** `.claude/skills/receiving-code-review/SKILL.md:33-37`, against `.claude/skills/requesting-code-review/SKILL.md:57-60` and `.claude/skills/subagent-driven-development/SKILL.md:53-64`.
- **Evidence:** receiving: "A finding that contradicts what the plan mandates is the user's call — show both, ask which governs (subagent-driven-development)." requesting: "**A finding that contradicts the plan:** as a plan conflict in subagent-driven-development — a reversible in-scope ruling is yours, logged under `## Rulings` in the plan's branch copy; scope, a spec decision or anything irreversible is the user's call."
- **Pattern:** Group 2, instruction files that contradict each other.
- **Why obsolete:** In both files the trigger is the branch-reviewer's findings, so this is a conflict, not an override. requesting-code-review:43 tells the model to evaluate those findings with receiving-code-review, so both load together. Example: a reviewer says the plan's name X is wrong and Y is right. Under requesting/SDD the controller rules and logs it. Under receiving the controller stops and asks the user. Blame puts receiving at 0d2c8b3 (2026-09-23) and requesting/SDD at ba56922 and e96c5de (2026-10-11), so receiving is the older text.
- **Confidence:** High (two in-repo files with opposite rules).
- **Action:** `flag`. The newer passage loosens an ask-the-user constraint, and the conflict row sends that case to flag. **The user decides:** may the controller rule on reversible, in-scope plan conflicts raised by the reviewer? If yes, rewrite receiving:35-37 to point at SDD's plan-conflict rule. If no, tighten requesting:57-60 and SDD:53-61 for reviewer-originated conflicts.

### F-H2 — the `**Announce:**` line conflicts with CLAUDE.md's ban on announcements
- **Location:** `.claude/skills/using-git-worktrees/SKILL.md:18`, against `.claude/CLAUDE.md:106-107`.
- **Evidence:** skill: `**Announce:** "Setting up an isolated workspace (using-git-worktrees)."` CLAUDE.md: "Don't open with … an announcement of what you're about to do."
- **Pattern:** Group 2, instruction files that contradict each other. The line is also a fixed English "Announce at start" idiom carried over from the upstream superpowers skills.
- **Why obsolete:** The skill line comes from 1eb2288 (2026-08-18); the CLAUDE.md rule comes from 0fc330d (2026-10-13), which is newer. The skill does not say it overrides the rule. It also hard-codes English, while CLAUDE.md:131 requires replies in the user's language (Polish here). CLAUDE.md:139 already covers progress reporting ("step N of M done").
- **Confidence:** High.
- **Action:** `remove` (proposed only). The edit brings the older text into line with the newer one. See D-H2.

### F-H3 — grill-gate.md is sequenced against a deleted "approaches" stage
- **Location:** `.claude/skills/writing-plans/grill-gate.md:10, 25, 52`.
- **Evidence:** "Before you propose approaches, scan…", "proceed straight to approaches", "Do not proceed to approaches until the scan is clean."
- **Pattern:** Group 2, volatile specifics (a stage name that no longer exists).
- **Why obsolete:** In e8a6200 (2026-10-10) the file was renamed from `skills/brainstorming/grill-gate.md` and the brainstorming skill was deleted in the same commit. writing-plans has sections "2. Questions and decisions" and "3. The plan", and no "propose approaches" step. Line 3 of the file was already updated ("before you write the plan's decisions"); lines 10, 25 and 52 were not. A model that follows the text literally either invents an approaches step or cannot tell when the grill must finish.
- **Confidence:** High (the repository contradicts it).
- **Action:** `rewrite` (proposed only). Replace "approaches" with the writing-plans stage. See D-H3.

---

## Findings — Medium

### F-M1 — CLAUDE.md opener rule built from a quoted list of phrases to avoid
- **Location:** `.claude/CLAUDE.md:106-107`.
- **Evidence:** `Don't open with "great question/idea", "you're absolutely right", agree-then-"but", hedging, or an announcement of what you're about to do.`
- **Pattern:** Group 1e, prohibition clusters (a list of stock phrases, with no reason given).
- **Why obsolete:** Quoting the exact phrases to avoid can steer the model toward them. The Opus 5.5 notes report "fewer stock phrases". This rule dates from 0fc330d (2026-10-13), a translation of the 2026-09-23 adaptation from i-have-adhd, so the finding rests on the pattern, not on age. The rewrite keeps every intent: substance first, no flattery, no hedge, no announcement. "agree-then-but" is already covered by line 108 ("Disagreement comes first"). The announcement clause stays, because it is the newer side of F-H2. F-L9 covers that clause separately.
- **Confidence:** Medium.
- **Action:** `rewrite`. See D-M1. The user may decline it as a deliberate reader-facing style rule.

### F-M2 — more quoted phrase bans in CLAUDE.md Response shape
- **Location:** `.claude/CLAUDE.md:141` and `.claude/CLAUDE.md:151-152`.
- **Evidence:** `No "oops", no "it looks like".` and `No recap of what's already visible, no "let me know", no "hope this helps".`
- **Pattern:** Group 1e (same pattern as F-M1).
- **Why obsolete:** Same reasoning as F-M1. The positive rule next to each ban ("location, cause, fix"; "one concrete next action") already defines the shape. The quoted phrases add only the anchoring risk.
- **Confidence:** Medium.
- **Action:** `rewrite`. See D-M2a and D-M2b.

### F-M3 — numeric list cap in CLAUDE.md
- **Location:** `.claude/CLAUDE.md:146-148`.
- **Evidence:** "Lists: at most 5 items per group, most important first, the rest on request. The cap is presentation only — never cut analysis…"
- **Pattern:** Group 1f, numeric output ceiling ("at most five bullets" is the documented example).
- **Why obsolete:** The documented fix is to express the goal as audience framing without the number. The line's own guard ("presentation only — never cut analysis, a list of findings or the steps of a procedure") is why rewriting it is safe: it already says the goal is readability, not truncation. The user's attention-friendly response shape is a legitimate reason to decline.
- **Confidence:** Medium.
- **Action:** `rewrite`. See D-M3.

### F-M4 — implementer reply clamp
- **Location:** `.claude/agents/implementer.md:114` (target model: Sonnet 5.5).
- **Evidence:** "Then reply with ONLY (under 15 lines — detail lives in the report file):"
- **Pattern:** Group 1f (a numeric ceiling) and 1a (uppercase emphasis).
- **Why obsolete:** The field list that follows already fixes the reply's shape, and the reason ("detail lives in the report file") already explains why it is short. The line count and "ONLY" date from 846382a (2026-08-18) and add nothing for a model that follows a field list closely.
- **Confidence:** Medium.
- **Action:** `rewrite`. See D-M4.

### F-M5 — "relentlessly" and "When in doubt … ask" in grill-gate.md
- **Location:** `.claude/skills/writing-plans/grill-gate.md:37` and `:69`.
- **Evidence:** "Interview relentlessly until every open decision point is closed." and "When in doubt, it's a decision — ask."
- **Pattern:** Group 1a, pressure language ("If in doubt, use X" is a documented over-trigger pattern).
- **Why obsolete:** Both lines come from 38a71e5 (2026-07-19, a pre-5.5 model). They push the model to ask more, and they contradict the file's own guards: line 61-62 ("both branches lead to materially the same implementation is not open") and line 66-67 ("Don't manufacture questions"). Current Opus models act on emphasis like this literally, so they ask more often. The design intent at line 32-33 ("err toward surfacing a decision") is kept.
- **Confidence:** Medium.
- **Action:** `rewrite`. See D-M5a and D-M5b.

### F-M6 — incident story in finishing-a-development-branch
- **Location:** `.claude/skills/finishing-a-development-branch/SKILL.md:78-81`.
- **Evidence:** `A real run hit this directly: Bash from inside that session is confined to the worktree, and a git operation aimed at the shared main checkout was refused until the session left ("the isolation guard blocks git operations on the shared checkout from inside the worktree — correctly").`
- **Pattern:** Group 2, history narratives (past tense, a quoted incident).
- **Why obsolete:** What gives the rule its authority is the current fact: git operations on the main checkout are refused from inside an `EnterWorktree` session. The story around it (9b4da4e, 2026-09-06) is archaeology. The rewrite keeps the fact.
- **Confidence:** Medium.
- **Action:** `rewrite`. See D-M6.

### F-M7 — a one-project fix hard-coded into a skill that loads everywhere
- **Location:** `.claude/skills/using-git-worktrees/SKILL.md:98-103`.
- **Evidence:** "Install what the project needs (`package.json` → `npm install`, `Cargo.toml` → `cargo build`, …), then run the test suite and the build. Tests alone can pass on a tree that does not build: Astro under `.claude/worktrees/` resolves the `tsconfig.json` `extends` from the main checkout, so `astro build` fails without `node_modules` there too while Vitest stays green."
- **Pattern:** Group 2, the recency trap. The line also falls under the "verbose SKILL.md explaining what the model knows" row.
- **Why obsolete:** The Astro/Vitest sentence was added in c525c8a (2026-10-28) after one project's failure, but it loads in every project. The manifest-to-command list is general knowledge. The lessons that generalize are "run the build, not only the tests" and "a config that resolves from the main checkout needs the main checkout's dependencies too". The rewrite keeps both.
- **Confidence:** Medium.
- **Action:** `rewrite` (proposed only). See D-M7.

### F-M8 — `branch-reviewer` reports only what passes its precision filter, with no coverage counterweight
- **Location:** `.claude/agents/branch-reviewer.md:89-94` and `:107` (target model: Opus 5.5).
- **Evidence:** "Never invent issues to look thorough; a clean axis gets one line." and "No case, no issue: no "consider", no taste."
- **Pattern:** Group 1. This is the code-review re-baselining item in the migration guide: the TUNE checklists for Opus 4.7, Opus 4.8, Opus 5 and Sonnet 5 all say current models follow "be conservative" or "don't nitpick" instructions literally, which depresses measured recall. Opus 5.5 inherits the Opus 5 guidance as its starting point. Keep-list item 11 applies: the fix adds text.
- **Why obsolete:** The reviewer is the only independent check (line 10-11). A bug it suspects but cannot fully confirm gets dropped silently. A downstream filter already exists, because the controller verifies every finding (receiving-code-review), so the documented fix (report with confidence, filter later) costs nothing here. The concrete-case requirement is **kept**: it is duplicated in CLAUDE.md:119-121, and deleting it would create a new conflict.
- **Confidence:** Medium.
- **Action:** `add`. See D-M8a and D-M8b.

### F-M9 — model versions and effort hard-coded in the development-workflow table
- **Location:** `.claude/skills/development-workflow/SKILL.md:64-73`.
- **Evidence:** "| `implementer` | Sonnet 5.5 · high (agent definition) |", "| `branch-reviewer` | Opus 5.5 · high |", "| `plan-red-team` | Opus 5.5 · xhigh |"
- **Pattern:** Group 2, history narratives (pinned model names) and time-sensitive content (the same fact kept in two places).
- **Why obsolete:** The agent frontmatter holds the real values, as the aliases `sonnet`/`opus` plus `effort`. This table copies them with version numbers. Git history shows the table already needed manual edits at each model change (5c68fef, 72c3626, e8a6200), and it goes stale at the next release or effort change, including the one F-M10 proposes. The controller only needs the model family (SDD:52 escalates to "Opus") and the principle on line 73.
- **Confidence:** Medium.
- **Action:** `rewrite`. Point to the frontmatter and keep the families and the principle. See D-M9.
- **Completeness:** the same pins appear in `.claude/README.md:40-41` ("implementer **Sonnet 5.5 · high**, branch-reviewer **Opus 5.5 · high**, plan-red-team **Opus 5.5 · xhigh**"). That file is outside this slice, so no hunk is written for it; route it to whoever owns README.md, or update it with D-M9. There are no other pins of this table in `.claude/**/*.md`. The prompt-master skill pins model names, but on an unrelated topic owned by another slice.

### F-M10 — `plan-red-team` runs at `effort: xhigh`, a value carried over from an earlier Opus (Group 4)
- **Location:** `.claude/agents/plan-red-team.md:5` (target model: Opus 5.5).
- **Evidence:** `effort: xhigh`
- **Pattern:** Group 4, thinking or effort configuration sized for the wrong model. Source: model-migration → Migrating to Claude Opus 5.5 → Choosing an effort level.
- **Why obsolete:** The value was set in 846382a (2026-08-18), before Opus 5.5. The guide says: "reserve `xhigh` and `max` for work where you have measured a quality gain", "At a given level, Claude Opus 5.5 tends to think more per turn than Claude Opus 5, especially at `xhigh`", and "re-run the sweep rather than carrying the Claude Opus 5 setting over". This finding is Medium and F-L2 is only Low because the guidance names `xhigh` specifically, while the other agents' `high` is within the documented range.
- **Confidence:** Medium.
- **Action:** `rewrite` to `effort: high`. See D-M10. **Completeness:** if D-M9 is declined, development-workflow/SKILL.md:71 must also change from "Opus 5.5 · xhigh" to "Opus 5.5 · high". `.claude/README.md:41` (outside this slice) also says "plan-red-team **Opus 5.5 · xhigh**" and needs the same change.

---

## Findings — Low (flag only, no hunk)

- **F-L1 (G2).** `.claude/skills/finishing-a-development-branch/SKILL.md:48-57`: a fixed English menu ("Implementation complete. What would you like to do? … Which option?") against CLAUDE.md:131 ("Reply in the language of my message"). A model that follows the menu literally could print English to a Polish user. The options themselves pin the format and should stay. A fix would add "in the user's language" to the line-41 heading.
- **F-L2 (G4).** `implementer.md:5` `effort: high` (5c68fef, 2026-09-23, set for Sonnet 5) and `branch-reviewer.md:5` `effort: high` (846382a, 2026-08-18, set for an earlier Opus) are carried over. Sonnet 5.5's levels are recalibrated, with `medium` as the starting point for agentic coding. Opus 5.5 defaults to `medium` and at `medium` beats Opus 5 at `high`. The docs prescribe a re-run sweep, not a specific value, and `high` is within both models' range, so no hunk is proposed. Measure (see F-L10) before lowering. At `low`, Sonnet 5.5 skips verification more often.
- **F-L3 (G1d, possible patch accretion).** `kt-cold-reader.md:58-73`: a block of narrow conditionals (automation promises, "Luki" cross-checks, "intervene during automatic work", approval rules against secret restrictions). They arrived in one commit (d8c4986) together with a research reference, not one incident at a time, so accretion is not shown. If cold-reader output wobbles between cases, generalize the block to "cite both sections for any contradiction or missing precondition".
- **F-L4 (G1f).** `writing-plans/SKILL.md:40`: "Target 100–250 lines. Past ~300, look at why". This is a size target for a written plan. It gives its reason and was written for the current model era (2026-10-10). A qualitative version is possible ("If the plan runs long, look at why…") but not needed.
- **F-L5 (G1c, generic advice).** `implementer.md:93`: "**Clean?** Names say what things do; code you would want to maintain." This restates a trained default. The other three self-review items are specific to the task, so the line is harmless.
- **F-L6 (G1a).** `CLAUDE.md:16, 28, 117`: three uppercase "BEFORE"s marking order. Emphasis density is low and each one marks a real ordering, so the observation is noted without a requested change.
- **F-L7 (G2).** `using-git-worktrees/SKILL.md:32-33`: "CLAUDE.md's standing rule — pipeline implementation happens in a worktree". CLAUDE.md no longer uses the word "pipeline"; the rule is now workflow rule 5 ("Implement a run in a worktree"). The meaning still carries over. A fix would replace the wording with "workflow rule 5 — a run is implemented in a worktree".
- **F-L8 (G2).** `implementer.md:42-43` says "append to the existing report", while `requesting-code-review/SKILL.md:46-47` gives the report path `.flow/sdd/<plan basename>/branch-review-report.md (created if absent)`. On the first findings dispatch no such file exists, and an implementer reading literally may look for the task report or return NEEDS_CONTEXT. A fix would make it "append to the report file named in the dispatch, creating it if absent".
- **F-L9 (G1d, update suppressor).** `CLAUDE.md:107`, the "announcement of what you're about to do" clause. Opus 5.5 guidance treats a one-line statement of intent before the first tool call as helpful in work with a human in the loop. The ban is the user's explicit preference and anchors F-H2, so it is kept. If long tool runs feel silent, this clause is the one to re-test.
- **F-L10 (G4, design: not ruled on).** The Opus 5 behavioural notes (inherited as the Opus 5.5 starting point) say instructions to verify via a subagent cause over-verification and that delegation multiplies cost. Two things touch this: the `branch-reviewer` gate on inline cross-module changes (CLAUDE.md:7-10) and the per-task `implementer` dispatch (SDD). Both are gates the user designed with stated reasons ("judges the work, not your reasoning about it"; "your context stays small"). Neither is the model spontaneously verifying itself, so the audit does not count them as cruft. **Token accounting:** the `session-report` plugin is installed. Use it to compare per-surface spend (implementer runs, red-team, branch review) before deciding whether these gates pay for themselves.

## Group 4 checks (explicit)
- **Request config, API fossils, history editing, cache ordering, budget countdowns:** not applicable. The slice contains no request-building code.
- **Roster check:** 4 agents with separate tasks and tool sets. `implementer` writes code. `branch-reviewer` reads code and runs tests. `plan-red-team` reads the plan and does not run tests. `kt-cold-reader` has no tools. None is near-duplicate → **clean**.
- **Executor check:** there are four model-call sites. Per run: the session (controller), `plan-red-team` once for plans with 2+ tasks, `implementer` once per task (plus one findings dispatch), and `branch-reviewer` once (plus a fix-range re-review after Critical findings). The 4th site, `kt-cold-reader`, belongs to the knowledge-transfer skill, outside this run. The deterministic steps are already code: `task-brief` (brief extraction), `review-package` (the diff bundle), `sdd-workspace` and `flow-state` (run state). Each remaining call is adaptive, and per task the one adaptive call is the implementer → **clean**.
- **Token accounting:** available (session-report). See F-L10.

## Verified facts (no finding)
- `review-package`'s exit codes 3 and 4 and its `--worktree` flag match branch-reviewer:26-30.
- `task-brief N` (plan taken from `flow-state get plan`) and its default output path match SDD:32-39. The preamble prepending matches writing-plans:72-73.
- Paths that exist: `.claude/hooks/flow-state`, `.claude/skills/polszczyzna/SKILL.md`, `.claude/skills/systematic-debugging/SKILL.md`, `.claude/skills/writing-specs/`, `.claude/skills/test-driven-development/`.
- Agreeing copies, left alone under keep-list item 8: "one writer per tree" (CLAUDE.md:25, development-workflow:56, SDD:16/89, implementer:27), the "concrete case" rule (CLAUDE.md:119, branch-reviewer:91), and "state sections after the last task" (CLAUDE.md:29, SDD:71, writing-plans:101, finishing:18).
- `handoff/SKILL.md`: clean.

---

# Proposed diff

Each hunk is computed against the **current** file, independently of the others, so hunks can be taken one at a time. Line offsets shift when several hunks are taken in one file; use `git apply --recount` or `patch -F3`. D-M2b and D-M3 have adjacent context lines in CLAUDE.md; apply one after the other. Paths are relative to `/home/m/dotfiles`. **Every hunk affects all projects.** Hunks marked "proposed only" fall under Group 2 rows that need explicit confirmation.

### D-H2 — F-H2 (proposed only; affects all projects)
```diff
--- a/.claude/skills/using-git-worktrees/SKILL.md
+++ b/.claude/skills/using-git-worktrees/SKILL.md
@@ -15,8 +15,6 @@
 cannot see — that is the mistake this skill exists to prevent. Invoking this
 skill *is* the project instruction `EnterWorktree` asks for.
 
-**Announce:** "Setting up an isolated workspace (using-git-worktrees)."
-
 ## Step 0 — already isolated?
 
 ```bash
```

### D-H3 — F-H3 (proposed only; affects all projects)
```diff
--- a/.claude/skills/writing-plans/grill-gate.md
+++ b/.claude/skills/writing-plans/grill-gate.md
@@ -8,5 +8,5 @@
 ## The rule
 
-Before you propose approaches, scan your current understanding for **open
+Before you write the plan's decisions, scan your current understanding for **open
 decision points**. An open decision point is any one of:
 
@@ -22,7 +22,7 @@
 Then branch:
 
 - **Zero open decision points → skip the grill entirely.** Ask nothing, proceed
-  straight to approaches, and don't announce the skip — silence is the correct
+  straight to the plan's decisions, and don't announce the skip — silence is the correct
   output when everything is clear. Skip only when the request pins down purpose,
   solution shape, success criteria, and obvious edge-case behavior, such that any
   competent implementer would build materially the same thing ("rename this env
@@ -49,7 +49,7 @@
 - **Re-scan after each answer.** An answer can open new points or close several
   at once. Continue until the scan returns zero.
 
-Do not proceed to approaches until the scan is clean.
+Do not write the plan's decisions until the scan is clean.
 
 ## Recording decisions
 
```

### D-M1 — F-M1 (affects all projects)
```diff
--- a/.claude/CLAUDE.md
+++ b/.claude/CLAUDE.md
@@ -103,8 +103,9 @@
 
 ## Candor
 
-- Don't open with "great question/idea", "you're absolutely right",
-  agree-then-"but", hedging, or an announcement of what you're about to do.
+- Open with substance: the first sentence is the answer, the objection or the
+  result — not praise of my message, a hedge, or an announcement of what you're
+  about to do.
 - Disagreement comes first: the most important objection up front, the rest by
   weight. When challenging, quote my words or code.
 - Add to an assessment your confidence and what concretely would change your
```

### D-M2a — F-M2 (affects all projects)
```diff
--- a/.claude/CLAUDE.md
+++ b/.claude/CLAUDE.md
@@ -138,7 +138,7 @@
   trade-off, recommendation first.
 - Multi-step work: state in every turn — "step 3 of 5 done: X. Next: Y."
 - Show finished work concretely: what works now and how to check it.
-- Error: location, cause, fix. No "oops", no "it looks like".
+- Error: location, cause, fix.
 - Tangents: finish the main thing first; a side issue is one sentence at the
   end, as a separate question. A question you can settle yourself (with a
   tool, in the code) — settle it and fold the answer in.
```

### D-M2b — F-M2 (affects all projects)
```diff
--- a/.claude/CLAUDE.md
+++ b/.claude/CLAUDE.md
@@ -146,10 +146,9 @@
 - Lists: at most 5 items per group, most important first, the rest on request.
   The cap is presentation only — never cut analysis, a list of findings or
   the steps of a procedure; group them instead.
 - Ending: one line on what you didn't do or didn't check and the risk from it
   (skip when none); then one concrete next action (at a run gate — the ✋
-  decision). No recap of what's already visible, no "let me know", no "hope
-  this helps".
+  decision). End there: no recap of what's already visible, no sign-off.
 - Exceptions: "explain"/"walk me through" → full explanation with headers;
   destructive operation → confirm first; third "still broken" turn → stop,
   name the assumption that may be wrong, ask one diagnostic question; real
```

### D-M3 — F-M3 (affects all projects)
```diff
--- a/.claude/CLAUDE.md
+++ b/.claude/CLAUDE.md
@@ -143,9 +143,9 @@
   end, as a separate question. A question you can settle yourself (with a
   tool, in the code) — settle it and fold the answer in.
 - Time estimates only with a basis — in minutes or hours, not "some work".
-- Lists: at most 5 items per group, most important first, the rest on request.
-  The cap is presentation only — never cut analysis, a list of findings or
-  the steps of a procedure; group them instead.
+- Lists: short groups I can take in at a glance, most important first, the
+  rest on request. Grouping is presentation only — never cut analysis, a list
+  of findings or the steps of a procedure.
 - Ending: one line on what you didn't do or didn't check and the risk from it
   (skip when none); then one concrete next action (at a run gate — the ✋
   decision). No recap of what's already visible, no "let me know", no "hope
```

### D-M4 — F-M4 (affects all projects)
```diff
--- a/.claude/agents/implementer.md
+++ b/.claude/agents/implementer.md
@@ -111,7 +111,7 @@
 - Self-review findings
 - Concerns
 
-Then reply with ONLY (under 15 lines — detail lives in the report file):
+Then reply with only these fields — the detail lives in the report file:
 
 - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
 - Commits (short SHA + subject — from `git log`, not recalled; a misremembered
```

### D-M5a — F-M5 (affects all projects)
```diff
--- a/.claude/skills/writing-plans/grill-gate.md
+++ b/.claude/skills/writing-plans/grill-gate.md
@@ -34,7 +34,7 @@
 
 ## The grill loop (only when triggered)
 
-Interview relentlessly until every open decision point is closed. Walk down each
+Ask until every open decision point is closed. Walk down each
 branch of the decision tree, resolving dependencies **first** (a decision that
 gates other decisions comes before them).
 
```

### D-M5b — F-M5 (affects all projects)
```diff
--- a/.claude/skills/writing-plans/grill-gate.md
+++ b/.claude/skills/writing-plans/grill-gate.md
@@ -66,4 +66,4 @@
 - **Grilling to look thorough.** If the scan is genuinely empty, asking anyway is
   noise. Don't manufacture questions.
 - **Silent assumption.** The failure this gate exists to prevent: picking a side
-  on a real fork without telling the user. When in doubt, it's a decision — ask.
+  on a real fork without telling the user.
```

### D-M6 — F-M6 (affects all projects)
```diff
--- a/.claude/skills/finishing-a-development-branch/SKILL.md
+++ b/.claude/skills/finishing-a-development-branch/SKILL.md
@@ -75,12 +75,10 @@
 `EnterWorktree` created (Step 2's second row) → exit it before touching the
 main checkout: `ExitWorktree` with `action: "keep"`, not `"remove"` — the
 merge has not happened yet, and removing the branch now would make it
-unrecoverable. A real run hit this directly: Bash from inside that session is
-confined to the worktree, and a git operation aimed at the shared main
-checkout was refused until the session left ("the isolation guard blocks git
-operations on the shared checkout from inside the worktree — correctly"). A
+unrecoverable. From inside that session, git operations on the shared main
+checkout are refused until the session exits the worktree. A
 worktree the session only `cd`'d into (Step 2's third row) carries no such
 confinement — skip this if that's what you're in.
 
 ```bash
 MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
```

### D-M7 — F-M7 (proposed only; affects all projects)
```diff
--- a/.claude/skills/using-git-worktrees/SKILL.md
+++ b/.claude/skills/using-git-worktrees/SKILL.md
@@ -95,12 +95,10 @@
 
 ## Step 3 — setup and clean baseline
 
-Install what the project needs (`package.json` → `npm install`, `Cargo.toml` →
-`cargo build`, `pyproject.toml`/`requirements.txt` → poetry/pip, `go.mod` →
-`go mod download`), then run the test suite and the build. Tests alone can pass
-on a tree that does not build: Astro under `.claude/worktrees/` resolves the
-`tsconfig.json` `extends` from the main checkout, so `astro build` fails
-without `node_modules` there too while Vitest stays green.
+Install what the project needs with its own package manager, then run the test
+suite and the build. Tests alone can pass on a tree that does not build: a
+config that resolves from the main checkout (a `tsconfig.json` `extends`) needs
+the main checkout's dependencies installed too.
 
 Tests must be green *before* your changes exist — otherwise you cannot tell
 your bugs from the ones you inherited. If they fail, report the failures and
```

### D-M8a — F-M8 (affects all projects)
```diff
--- a/.claude/agents/branch-reviewer.md
+++ b/.claude/agents/branch-reviewer.md
@@ -92,6 +92,9 @@
 leads to this wrong result, or this line costs this. Re-read the lines first —
 the caller exists, the value can really be empty, the code really is unused.
 No case, no issue: no "consider", no taste.
+An issue with a concrete case that you could not fully confirm still goes in,
+marked with its confidence — the controller verifies every finding
+(receiving-code-review) and drops what does not hold.
 
 ## Output
 
```

### D-M8b — F-M8 (affects all projects)
```diff
--- a/.claude/agents/branch-reviewer.md
+++ b/.claude/agents/branch-reviewer.md
@@ -104,7 +104,7 @@
     #### Critical
     #### Important
     #### Minor
-    For each: file:line, what is wrong, the concrete case, how to fix if not obvious — the smallest fix, preferring one that deletes code.
+    For each: file:line, what is wrong, the concrete case, your confidence (high / medium / low), how to fix if not obvious — the smallest fix, preferring one that deletes code.
 
     ### Implementer concerns, triaged
     [each: valid / not, with a reason]
```

### D-M9 — F-M9 (affects all projects)
```diff
--- a/.claude/skills/development-workflow/SKILL.md
+++ b/.claude/skills/development-workflow/SKILL.md
@@ -61,13 +61,9 @@
   decision row at the plan gate, the state sections after the last task,
   before the branch review.
 
 ## Models
 
-| Role | Default |
-|---|---|
-| Session (plan, controller, debugging) | session model |
-| `implementer` | Sonnet 5.5 · high (agent definition) |
-| `branch-reviewer` | Opus 5.5 · high |
-| `plan-red-team` | Opus 5.5 · xhigh |
-
-A reviewer is at least as strong as what it reviews.
+The session model plans, coordinates and debugs. Each agent's model and effort
+live in its definition's frontmatter: `implementer` runs on Sonnet,
+`branch-reviewer` and `plan-red-team` on Opus. A reviewer is at least as strong
+as what it reviews.
```

### D-M10 — F-M10 (affects all projects; if D-M9 is declined, also change development-workflow/SKILL.md:71 to `Opus 5.5 · high`)
```diff
--- a/.claude/agents/plan-red-team.md
+++ b/.claude/agents/plan-red-team.md
@@ -2,7 +2,7 @@
 name: plan-red-team
 description: Adversarial pre-mortem on an implementation plan before it executes — argues the strongest case that the plan is wrong. Dispatched once per plan at the plan gate by writing-plans. Not for reviewing code that already exists.
 model: opus
-effort: xhigh
+effort: high
 disallowedTools: Edit, Write, NotebookEdit, Artifact, Skill
 color: red
 ---
```
