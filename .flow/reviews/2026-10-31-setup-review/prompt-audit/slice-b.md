# Prompt audit, slice B: process and writing skills

## Assumptions

- **Scope:** `/home/m/dotfiles/.claude/skills/{test-driven-development,systematic-debugging,writing-specs,writing-skills,polszczyzna}/`. That means every SKILL.md and every reference file. `/home/m/dotfiles/.claude/CLAUDE.md` was read only to check conflicts with these skills. Git root: `/home/m/dotfiles`. Provenance comes from `git blame` there. The files are deployed into `~/.claude` via symlinks and load in every project, so **every proposed edit affects all projects**.
- **Target model:** Claude Opus 5.5. No skill in this slice pins a model.
- **Not read (by instruction):** `settings*.json`, `.mcp.json`, `~/.claude.json`, and the contents of `hooks/`. Only the names in `hooks/` were listed, to confirm that `hooks/flow-guard` exists. CLAUDE.md's own findings and the pipeline skills belong to another auditor. A conflict with them is reported here only as `flag`.
- Nothing was edited. Every hunk was checked two ways. First, `git apply --check` against the repo. Second, all hunks were applied in sequence to a scratch copy (`/tmp/prompt-audit/work/tree`). Each hunk applies cleanly on its own and together with the others.

## Summary

The three findings with the most impact:

1. **`writing-skills/persuasion-principles.md` recommends the register that its own newer section disproves.** §1 Authority (`:15-17`) and "Why This Works" (`:138-139`) recommend `"YOU MUST"`, capitals and absolute language. Both date from 38a71e5, 2026-07-19. The counter-evidence section (`:179-214`, 914e604 2026-09-17 and ba56922 2026-10-11) measured the three most emphatic rules in this setup across 2030 transcripts and found them broken 110 times, 8 times in a row and in 39 tasks. On Opus 5.5 the same register also over-applies. This is the skill that teaches how to write every other skill, so the register spreads to every skill written from it (H1). The same file's Commitment example tells skills to require `you MUST announce: "I'm using [Skill Name]"`, against CLAUDE.md:106-107 (H2).
2. **`systematic-debugging/SKILL.md` is the one skill in the slice still in the vendored superpowers register.** 277 of its 330 lines are still from 38a71e5. It has 12 capitalised markers. The "≥3 fixes" rule appears in five places (`:226-231`, `:233-247`, `:261-262`, `:266`, `:290`), and the repo itself records that rule as broken in 39 tasks (persuasion-principles.md:189). The rule should be stated once, plainly, with its reason (M1). The overview line "Violating the letter of this process is violating the spirit" (M2) works against the judgment exits the skill grants itself. `test-driven-development` has already been cut to the repo's register (0 capitalised markers, 914e604) and shows what this skill should look like.
3. **`writing-skills` states facts the repo contradicts.** The Token Efficiency section (`SKILL.md:213-220`) claims that "getting-started and frequently-referenced skills load into EVERY conversation", sets word caps for a `getting-started` category that does not exist in `skills/`, and sets "<500 words" for other skills. The vendored Anthropic doc in the same directory says that only name and description are preloaded (`anthropic-best-practices.md:20`, `:1021-1024`) and sets the limit at <500 lines. Every SKILL.md in this slice has 869–3807 words (H3). The Discovery Workflow claims that agents "grep descriptions" (H4). The pointer to a "full test campaign" leads to a file that holds only predictions (H5).

**Counts per group:**

| Group | Findings |
|---|---|
| 1 (dated prompt text) | 10 (1 high, 5 medium, 4 low/flag) |
| 2 (brittle skill/config files) | 15 (5 high, 1 medium, 9 low/flag) |
| 3 (tool descriptions) | zero. Skill descriptions are routing text (keep-list 6); they were checked and none has findings |
| 4 (request config and architecture) | not applicable: there is no request-building or prompt-assembly code in the slice |

**Clean:** `writing-specs/SKILL.md`, `writing-specs/project-claude-md.md`, `test-driven-development/writing-good-tests.md`. `test-driven-development/SKILL.md` has only one conflict flag (F3). `polszczyzna` has only one low flag (F10). Its Polish norms and its named list of model mannerisms are data and a product requirement (keep-list 1). The migration guide says that Opus 5.5 "responds well to instructions that name specific patterns to avoid".

## Inventory

| File | Lines | Last commit |
|---|---|---|
| `test-driven-development/SKILL.md` | 175 | ba56922 2026-10-11 |
| `test-driven-development/writing-good-tests.md` | 203 | c525c8a 2026-10-28 |
| `systematic-debugging/SKILL.md` | 330 | 918fefd 2026-10-25 (277 lines still 38a71e5) |
| `systematic-debugging/root-cause-tracing.md` | 169 | ba56922 |
| `systematic-debugging/defense-in-depth.md` | 136 | 0fc330d |
| `systematic-debugging/condition-based-waiting.md` | 115 | 38a71e5 |
| `systematic-debugging/condition-based-waiting-example.ts` | 158 | code example |
| `systematic-debugging/find-polluter.sh` | 72 | script, read but not run |
| `writing-specs/SKILL.md` | 234 | 918fefd |
| `writing-specs/project-claude-md.md` | 57 | df9f7cd |
| `writing-skills/SKILL.md` | 689 | 6ee8535 / 38a71e5 2026-07-19, all of it |
| `writing-skills/anthropic-best-practices.md` | 1150 | 38a71e5, vendored copy of Anthropic docs |
| `writing-skills/testing-skills-with-subagents.md` | 384 | 6ee8535 / 38a71e5 |
| `writing-skills/persuasion-principles.md` | 225 | ba56922 (`:179-225` local, 914e604 + ba56922) |
| `writing-skills/examples/CLAUDE_MD_TESTING.md` | 189 | 38a71e5 |
| `writing-skills/graphviz-conventions.dot`, `render-graphs.js` | 171 / 168 | style data and a script, skimmed |
| `polszczyzna/SKILL.md` | 160 | c34bc56 2026-09-21, vendored |
| `polszczyzna/references/norma.md` | 128 | c34bc56 |
| `/home/m/dotfiles/.claude/CLAUDE.md` | 160 | 0fc330d 2026-10-13 / 918fefd 2026-10-25, read for conflicts only |

**Provenance:** most of `writing-skills/` and `systematic-debugging/` is the upstream superpowers import (38a71e5, 2026-07-19). The user's later passes are: 914e604 "prune the skill layer and correct what contradicted it" (2026-09-17), ba56922 "upstream picks" (2026-10-11), and 0fc330d, which rewrote CLAUDE.md in English (2026-10-13). Where a 38a71e5 line contradicts a later local line, the later line is the current rule.

---

## Findings: high confidence

### H1. Authority framing recommended against the file's own newer measurement
- **Location:** `.claude/skills/writing-skills/persuasion-principles.md:15-17`, `:138-139`
- **Evidence:** `- Imperative language: "YOU MUST", "Never", "Always"` / `- Eliminates decision fatigue and rationalization` / `- "YOU MUST" removes decision fatigue`
- **Pattern:** 1a pressure language. Also Group 2, a contradiction inside one file that blame can order.
- **Why obsolete:** Current models respond strongly to the system prompt, so capitalised imperatives get over-applied. They make the model rigid in gray areas and do not make it more compliant. The same file's newer section (`:179-209`, 914e604) records "the three most emphatically worded rules in this whole setup were the ones broken most … None of them held". Because this is guidance for writing skills, the register spreads into every new skill.
- **Confidence:** High. The pattern is documented, and the repo itself contradicts the text.
- **Action:** `rewrite`. Keep the non-negotiable content and drop the capitals (hunks H1).

### H2. "You MUST announce skill usage" vs CLAUDE.md's ban on announcements
- **Location:** `.claude/skills/writing-skills/persuasion-principles.md:34`, `:45-46` (38a71e5, 2026-07-19) vs `.claude/CLAUDE.md:106-107` (0fc330d, 2026-10-13)
- **Evidence:** `✅ When you find a skill, you MUST announce: "I'm using [Skill Name]"` vs `Don't open with "great question/idea", … or an announcement of what you're about to do.`
- **Pattern:** Group 2, instruction files that contradict each other.
- **Why obsolete:** A skill author who follows the example writes an announcement rule into a new skill. The session then opens its replies with "I'm using X", which CLAUDE.md forbids. persuasion-principles.md:206-211 also records that `using-superpowers`, the skill that demanded announcements, was deleted. CLAUDE.md is newer, so the older example gets rewritten. The replacement Commitment example is quoted from `systematic-debugging/SKILL.md:92-93`.
- **Confidence:** High.
- **Action:** `rewrite` (hunks H2).

### H3. Token Efficiency section: stale cost model and nonexistent skill category
- **Location:** `.claude/skills/writing-skills/SKILL.md:213-220`, `:263-265`
- **Evidence:** `**Problem:** getting-started and frequently-referenced skills load into EVERY conversation.` / `- getting-started workflows: <150 words each` / `- Other skills: <500 words (still be concise)`
- **Pattern:** Group 2, volatile specifics (a claim the repo contradicts). Also 1d, an unenforced instruction.
- **Why obsolete:** `anthropic-best-practices.md:20` and `:1021-1024` in the same directory say that only name and description are preloaded and that the body loads on use. `skills/` has no getting-started skill. The vendored doc's limit is "under 500 lines" (`:1097-1099`), not 500 words. Every SKILL.md in the slice breaks the word cap: TDD 869, systematic-debugging 2012, writing-specs 2135, polszczyzna 2164, writing-skills 3807 words. Concrete case: an author cuts load-bearing context out of a skill body to reach a 500-word target based on a cost model that is false.
- **Confidence:** High. The repo contradicts the claim. Under the Volatile-specifics row, this edit is proposed only.
- **Action:** `rewrite` to the cost model and limit in the vendored doc (hunks H3).

### H4. Discovery Workflow says agents grep for skills
- **Location:** `.claude/skills/writing-skills/SKILL.md:673`
- **Evidence:** `2. **Searches skills** (greps descriptions, browses categories)`
- **Pattern:** Group 2, volatile specifics.
- **Why obsolete:** `anthropic-best-practices.md:1021` says "At startup, the name and description from all Skills' YAML frontmatter are loaded into the system prompt". The Skill tool works this way, so the step describes a discovery mechanism that is no longer used.
- **Confidence:** High.
- **Action:** `rewrite` (hunk H4).

### H5. Pointer to a "full test campaign" that contains no results
- **Location:** `.claude/skills/writing-skills/testing-skills-with-subagents.md:15`
- **Evidence:** `**Complete worked example:** See examples/CLAUDE_MD_TESTING.md for a full test campaign testing CLAUDE.md documentation variants.`
- **Pattern:** Group 2, volatile specifics.
- **Why obsolete:** `examples/CLAUDE_MD_TESTING.md:170-189` ends with "Expected Results" (predictions such as "Variant C: Strong compliance but might feel too rigid") and "Next Steps: 1. Create subagent test harness". Nothing in it was run. A reader who trusts the pointer treats the predictions as measured.
- **Confidence:** High.
- **Action:** `rewrite` the pointer (hunk H5). The example file itself is F7.

### H6. "Read the reference COMPLETELY" vs CLAUDE.md's read-by-range rule
- **Location:** `.claude/skills/systematic-debugging/SKILL.md:165-166`, `:288` (38a71e5) vs `.claude/CLAUDE.md:17-18` (0fc330d 2026-10-13 / 918fefd 2026-10-25)
- **Evidence:** `- If implementing pattern, read reference implementation COMPLETELY` / `- Don't skim - read every line` / `Read it completely.` vs `a file you are not editing is read by range, not whole.`
- **Pattern:** Group 2 conflict. Also 1a: capitals with no reason given.
- **Why obsolete:** Take a 1,500-line reference module the session is not editing. The skill says to read all of it and CLAUDE.md says to read a range. Both load in the same session. CLAUDE.md is newer. The older line is a directive, not a prohibition, so it can be rewritten. The rewrite keeps the skill's real intent: no skimming within the relevant range.
- **Confidence:** High.
- **Action:** `rewrite` (hunks H6).

## Findings: medium confidence

### M1. The "≥3 fixes" rule is shouted five times and measured as broken
- **Location:** `.claude/skills/systematic-debugging/SKILL.md:226-231`, `:240`, `:264-266`, `:290`. `:233-247` and `:261-262` stay as the single statement and the single red-flag cue.
- **Evidence:** `- STOP` / `- **If ≥ 3: STOP and question the architecture (step 5 below)**` / `- DON'T attempt Fix #4 without architectural discussion` / `**ALL of these mean: STOP. Return to Phase 1.**` / `**If 3+ fixes failed:** Question the architecture (see Phase 4.5)` / table row `"One more fix attempt" (after 2+ failures)`
- **Pattern:** 1a pressure language, 1c repetition as reinforcement, 1d unenforced instruction.
- **Why obsolete:** `persuasion-principles.md:189` records this exact wording as broken in 39 tasks, so the volume and the repetition bought no compliance. On Opus 5.5 the repetition only makes the model reconcile five wordings of one rule. The rewrite states the rule once, in step 4, and gives its reason, which the old text left out. The reason is the local measured case at `:324-330`. Enforcing the rule mechanically (the repo's "write the hook" conclusion) is the user's decision. hooks/ is out of scope, so no hook is proposed.
- **Completeness:** `persuasion-principles.md:185-189` quotes the old wording as measured evidence. Keep that quote: it records what was measured. If you take this hunk, its column "Where it lives" becomes "where it lived".
- **Confidence:** Medium.
- **Action:** `rewrite` and `remove` the duplicates (hunks M1).

### M2. Overview pressure lines in systematic-debugging
- **Location:** `.claude/skills/systematic-debugging/SKILL.md:12-14`
- **Evidence:** `**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.` / `**Violating the letter of this process is violating the spirit of debugging.**`
- **Pattern:** 1a. Capitals and an absolute with no reason. The second line is the superpowers persuasion device from writing-skills (see M3).
- **Why obsolete:** Opus 5.5 follows instructions literally. Read that way, "letter = spirit" forbids the judgment exits the skill grants itself: "When Process Reveals 'No Root Cause'" (`:301-308`) and "Cannot build one → say so … and ask" (`:93-94`). The Iron Law at `:16-20` already states the rule.
- **Confidence:** Medium.
- **Action:** `rewrite` line 12 with its reason and `remove` line 14 (hunk M2).

### M3. writing-skills teaches authors to add "letter = spirit"
- **Location:** `.claude/skills/writing-skills/SKILL.md:506-515`, `testing-skills-with-subagents.md:255-256`, `:282-307`
- **Evidence:** `Add foundational principle early: … **Violating the letter of the rules is violating the spirit of the rules.**` / `- Need stronger foundational principle` / `- Add "Violating letter is violating spirit"` / the example "Iteration 2 - Add Foundational Principle … **Bulletproof achieved.**"
- **Pattern:** 1a, guidance that produces pressure language. Group 2: contradicted by persuasion-principles.md:191-211, which is newer.
- **Why obsolete:** This is the source of M2. The newer local evidence says authority framing did not hold. Its fix order is: a hook if the rule can be checked mechanically, otherwise the reason stated next to the rule. `:206-211` also says the TDD skill that the "Bulletproof achieved" example describes was later cut by 80%. "Most of that prose bought no compliance." Removing the example removes the last reference to the advice.
- **Confidence:** Medium.
- **Action:** `remove` the section and the example. `rewrite` the meta-testing step (hunks M3).

### M4. STOP / MANDATORY / IMPORTANT around the deployment checklist
- **Location:** `.claude/skills/writing-skills/SKILL.md:614-630`
- **Evidence:** `**After writing ANY skill, you MUST STOP and complete the deployment process.**` / `**The deployment checklist below is MANDATORY for EACH skill.**` / `It's a violation of quality standards.` / `**IMPORTANT: Create a todo for EACH checklist item below.**`
- **Pattern:** 1a pressure language. 1c choreography: the todo-per-item instruction tells the model how to track progress, which it already does.
- **Why obsolete:** Four capitalised markers in 17 lines carry one requirement: test each skill before starting the next. The rewrite keeps that requirement and gives the reason (batches hide which skill failed).
- **Confidence:** Medium.
- **Action:** `rewrite` (hunk M4).

### M5. "You MUST understand" in cross-reference markers
- **Location:** `.claude/skills/writing-skills/SKILL.md:18`, `:284`; `testing-skills-with-subagents.md:13`
- **Evidence:** `**REQUIRED BACKGROUND:** You MUST understand test-driven-development before using this skill.`
- **Pattern:** 1a.
- **Why obsolete:** The `**REQUIRED BACKGROUND:**` marker already carries the requirement. `:284` presents the capitalised form as the convention to copy. The repo's newer usage, `writing-specs/SKILL.md:101`, uses the plain form.
- **Confidence:** Medium.
- **Action:** `rewrite` (hunks M5).

### M6. Dated upstream "Real-World Impact" narratives
- **Location:** `.claude/skills/systematic-debugging/root-cause-tracing.md:163-169`, `condition-based-waiting.md:109-115`, `writing-skills/testing-skills-with-subagents.md:377-384`
- **Evidence:** `From debugging session (2025-10-03):` … `1847 tests passed, zero pollution` / `Pass rate: 60% → 100%` / `Final VERIFY GREEN: 100% compliance under maximum pressure`
- **Pattern:** Group 2, history narratives.
- **Why obsolete:** The setup's own rule, `writing-skills/SKILL.md:595-597`, classifies `"In session 2025-10-03, we found empty projectDir caused..."` as an anti-pattern ("Too specific, not reusable"). These files break that rule. The "100% compliance" claim is also contradicted by persuasion-principles.md:206-211. The worked examples (the Empty projectDir trace and the defense-in-depth layers) stay, because the text refers to them. Kept on purpose: `systematic-debugging/SKILL.md:324-330` and `persuasion-principles.md:179-214`. Those are this setup's own measured reasons, and M1 cites `:324-330`.
- **Confidence:** Medium.
- **Action:** `remove` (hunks M6).

## Findings: low confidence / flag (report only, no diff)

- **F1. Description scope: two files in one skill disagree** (Group 2, `flag`). `writing-skills/SKILL.md:99`, `:102`, `:150-158`, `:180` say: "describes ONLY when to use (NOT what it does)", "**NEVER summarize the skill's process or workflow**". `anthropic-best-practices.md:187`, `:197`, `:1108` say: "should include both what the Skill does and when to use it". Both come from commit 38a71e5, so history cannot order them. Repo practice follows the Anthropic doc: the descriptions of `writing-specs`, `polszczyzna` and `subagent-driven-development` (pipeline, other auditor) all say what the skill does. You need to decide which rule is current. Then remove the other rule, or name it as overridden.
- **F2. The writing-skills Iron Law covers trivial edits; CLAUDE.md exempts them** (Group 2, `flag`, because the older passage is a prohibition). `writing-skills/SKILL.md:380-391` ("This applies to NEW skills AND EDITS … Not for "documentation updates" … Delete means delete", 2026-07-19) vs `CLAUDE.md:60` ("For a trivial change (typo, one line) common sense is enough", 2026-10-13). Concrete case: a one-word typo fix in a SKILL.md. writing-skills requires a baseline pressure scenario first, or else deletion. CLAUDE.md requires nothing. The register of the "No exceptions" list (`:385-391`) can be brought to normal volume once you have decided the scope.
- **F3. TDD covers refactors; CLAUDE.md checks refactors with "green before and after"** (Group 2, `flag`, prohibition). `test-driven-development/SKILL.md:16`, `:24-26` ("NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST" … "Applies to features, bugfixes, refactors"; "ask before treating anything else as one") vs `CLAUDE.md:60`, `:65` ("refactor" → "tests green before and after"; trivial change → common sense). Concrete case: "refactor module X" with passing tests. TDD asks for a failing test first, which a refactor that preserves behaviour cannot honestly produce. CLAUDE.md asks for green before and after. CLAUDE.md is newer, but the rewrite would loosen a prohibition, so this is your decision.
- **F4. root-cause-tracing.md disagrees with itself at a dead end** (Group 2, `flag`). `:21` gives `"Can trace backwards?" -> "Fix at symptom point" [label="no - dead end"]`. `:141`, `:145` and `:154` give `"Can trace one level up?" -> "NEVER fix just the symptom" [label="no"]` and "**NEVER fix just where the error appears.**" Concrete case: the trace dead-ends. One diagram says to fix at the symptom, the other forbids it. The first matches `systematic-debugging/SKILL.md:301-308`. Both diagrams come from one commit, and one side is a prohibition, so you decide.
- **F5. The Scarcity example models per-task review** (Group 2, `flag`, conflicts with the pipeline). `persuasion-principles.md:64` says: `✅ After completing a task, IMMEDIATELY request code review before proceeding.` The lean workflow (e8a6200 "no per-task review"; CLAUDE.md:7-10 review "before it lands on main"; subagent-driven-development "then one whole-branch review") is newer. An author who copies the example puts per-task review back. The other auditor owns the pipeline side.
- **F6. The vendored Anthropic doc has no copy date** (Group 2 volatile, low). `anthropic-best-practices.md` has not changed since 38a71e5 and carries no source date. Examples: `:798` advises "using stronger language like "MUST filter"" (against 1a for current models), `:132-142` gives per-tier testing advice, and `:1008-1009` makes platform claims ("Anthropic API: Has no network access"). Refresh it from the live page, or date the copy. It cannot be checked against the repo.
- **F7. `examples/CLAUDE_MD_TESTING.md` tests a discovery mechanism that no longer exists** (Group 2, low). Its scenarios and variants test `ls`/`grep` of `~/.claude/skills/<category>/` and `skills/using-skills`. Skills now reach the model through preloaded descriptions and the Skill tool. The paths are scenario placeholders, so their absence is not a finding on its own. Deleting the file once H5 is decided is a candidate.
- **F8. Three overlapping lists in systematic-debugging** (1c, low). Red Flags (`:249-266`), Redirections (`:268-277`) and Common Rationalizations (`:279-290`) cover the same failure. persuasion-principles.md:206-214 found that rebuttal prose mostly bought no compliance. The exception was TDD's measured table. This table has no measurement. Removing it needs an eval, so it is flagged only.
- **F9. Pressure coaching and an unsourced statistic** (1a/1c, low). `systematic-debugging/SKILL.md:34-44` ("Use this ESPECIALLY when … Manager wants it fixed NOW") repeats the trigger after the skill has already loaded. `:310` "95% of "no root cause" cases are incomplete investigation" gives no source.
- **F10. polszczyzna's cutting pass** (1f, low). `polszczyzna/SKILL.md:72` says "Jeśli nie da się wyciąć nic, prawdopodobnie czytasz za pobieżnie" ("if you can't cut anything, you're probably reading too quickly"), and `:150` asks "O ile się skrócił?" ("how much shorter did it get?"). The "15–20%" target is the cited plain-language standard (data, keep). The "you're reading too fast" line pushes for a cut on every text. Concrete case: polishing a Polish `spec.md` (the description lists spec.md), where `writing-specs/SKILL.md:133-137` says "Overshoot and say why". The line already says "bez straty treści" ("without losing content"), so the risk is small.
- **F11. Minor writing-skills items** (low). `:12` "**Personal skills live in your runtime's skills directory** " is a sentence that says nothing specific and ends in trailing whitespace. `:103` "Keep under 500 characters if possible" puts a hedge on a target. `:288` claims "consuming 200k+ context" with no source. `:444-457` ends the rationalization table with "Untested skills have issues. Always." and "No exceptions." (1a).
- **F12. Copied example breaks its own signature** (no documented pattern, low). `condition-based-waiting.md:367-371` declares `waitFor(condition, description, timeoutMs = 5000)` with `description` required. `:348` and `:357-361` call `waitFor(() => …)` without it. Code copied from the Quick Patterns table fails to type-check in TypeScript.
- **F13. Upstream provenance header** (Group 2, low). `condition-based-waiting-example.ts:2-3` reads `// From: Lace test infrastructure improvements (2025-10-03)`. It is a code comment and harmless. Remove it together with M6 if you want consistency.

---

## Proposed diff

Paths are relative to `/home/m/dotfiles`. Each hunk carries its finding ID, and every hunk **affects all projects**. The hunks use one line of context, so each finding can be applied on its own or in any combination. All 12 patch files, applied in sequence (H1–H6, then M1–M6), apply cleanly to a scratch copy. Standalone patch files: `/tmp/prompt-audit/work/<ID>.patch`.

#### H1 - .claude/skills/writing-skills/persuasion-principles.md (affects all projects)
~~~diff
--- a/.claude/skills/writing-skills/persuasion-principles.md
+++ b/.claude/skills/writing-skills/persuasion-principles.md
@@ -14,5 +14,5 @@
 **How it works in skills:**
-- Imperative language: "YOU MUST", "Never", "Always"
-- Non-negotiable framing: "No exceptions"
-- Eliminates decision fatigue and rationalization
+- A bright-line rule stated once, at normal volume, with its reason beside it
+- Non-negotiable content: "No exceptions" where there genuinely are none
+- Capitals and stacked imperatives add no compliance here (see the counter-evidence section below) and make current models over-apply the rule
 
@@ -137,4 +137,3 @@
 **Bright-line rules reduce rationalization:**
-- "YOU MUST" removes decision fatigue
-- Absolute language eliminates "is this an exception?" questions
+- A rule with no exceptions removes "is this an exception?" questions; the absoluteness lives in the content, not in capitals
 - Explicit anti-rationalization counters close specific loopholes
~~~

#### H2 - .claude/skills/writing-skills/persuasion-principles.md (affects all projects)
~~~diff
--- a/.claude/skills/writing-skills/persuasion-principles.md
+++ b/.claude/skills/writing-skills/persuasion-principles.md
@@ -33,3 +33,3 @@
 **How it works in skills:**
-- Require announcements: "Announce skill usage"
+- Require a stated checkpoint: "name the command that goes red before fixing"
 - Force explicit choices: "Choose A, B, or C"
@@ -44,4 +44,4 @@
 ```markdown
-✅ When you find a skill, you MUST announce: "I'm using [Skill Name]"
-❌ Consider letting your partner know which skill you're using.
+✅ Phase 1 is not done until you can name one command you have already run that goes red on this bug.
+❌ Try to reproduce the bug first if you can.
 ```
~~~

#### H3 - .claude/skills/writing-skills/SKILL.md (affects all projects)
~~~diff
--- a/.claude/skills/writing-skills/SKILL.md
+++ b/.claude/skills/writing-skills/SKILL.md
@@ -212,10 +212,9 @@
 
-### 4. Token Efficiency (Critical)
-
-**Problem:** getting-started and frequently-referenced skills load into EVERY conversation. Every token counts.
-
-**Target word counts:**
-- getting-started workflows: <150 words each
-- Frequently-loaded skills: <200 words total
-- Other skills: <500 words (still be concise)
+### 4. Token Efficiency
+
+**Cost model:** every skill's `name` and `description` sit in the system prompt of every session; the SKILL.md body loads only when the skill is used, and reference files only when read. Description words are paid in every session, body words on every use.
+
+**Targets:**
+- Description: the triggering conditions, in as few words as do the job
+- SKILL.md body: under 500 lines (anthropic-best-practices.md); heavy reference goes to separate files
 
@@ -262,5 +261,4 @@
 ```bash
-wc -w skills/path/SKILL.md
-# getting-started workflows: aim for <150 each
-# Other frequently-loaded: aim for <200 total
+wc -l skills/path/SKILL.md
+# body: under 500 lines
 ```
~~~

#### H4 - .claude/skills/writing-skills/SKILL.md (affects all projects)
~~~diff
--- a/.claude/skills/writing-skills/SKILL.md
+++ b/.claude/skills/writing-skills/SKILL.md
@@ -672,3 +672,3 @@
 1. **Encounters problem** ("tests are flaky")
-2. **Searches skills** (greps descriptions, browses categories)
+2. **Matches the task against skill descriptions** (all of them are in the system prompt from session start)
 3. **Finds SKILL** (description matches)
~~~

#### H5 - .claude/skills/writing-skills/testing-skills-with-subagents.md (affects all projects)
~~~diff
--- a/.claude/skills/writing-skills/testing-skills-with-subagents.md
+++ b/.claude/skills/writing-skills/testing-skills-with-subagents.md
@@ -14,3 +14,3 @@
 
-**Complete worked example:** See examples/CLAUDE_MD_TESTING.md for a full test campaign testing CLAUDE.md documentation variants.
+**Campaign sketch:** examples/CLAUDE_MD_TESTING.md lays out scenarios and documentation variants for testing CLAUDE.md wording; it records predictions, not results.
 
~~~

#### H6 - .claude/skills/systematic-debugging/SKILL.md (affects all projects)
~~~diff
--- a/.claude/skills/systematic-debugging/SKILL.md
+++ b/.claude/skills/systematic-debugging/SKILL.md
@@ -164,4 +164,3 @@
 2. **Compare Against References**
-   - If implementing pattern, read reference implementation COMPLETELY
-   - Don't skim - read every line
+   - If implementing a pattern, read the reference implementation's relevant range in full - every line of it, not a skim
    - Understand the pattern fully before applying
@@ -287,3 +286,3 @@
 | "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
-| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
+| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read the relevant range in full. |
 | "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
~~~

#### M1 - .claude/skills/systematic-debugging/SKILL.md (affects all projects)
~~~diff
--- a/.claude/skills/systematic-debugging/SKILL.md
+++ b/.claude/skills/systematic-debugging/SKILL.md
@@ -226,7 +226,5 @@
 4. **If Fix Doesn't Work**
-   - STOP
-   - Count: How many fixes have you tried?
-   - If < 3: Return to Phase 1, re-analyze with new information
-   - **If ≥ 3: STOP and question the architecture (step 5 below)**
-   - DON'T attempt Fix #4 without architectural discussion
+   - Count the fixes tried so far.
+   - Fewer than 3: return to Phase 1 and re-analyze with the new information.
+   - 3 or more: go to step 5 instead of a fourth fix. Three failed fixes point at the design, and each further patch tends to surface the next variant of the same defect (see Real-World Impact).
 
@@ -239,3 +237,3 @@
 
-   **STOP and question fundamentals:**
+   **Question fundamentals:**
    - Is this pattern fundamentally sound?
@@ -263,5 +261,3 @@
 
-**ALL of these mean: STOP. Return to Phase 1.**
-
-**If 3+ fixes failed:** Question the architecture (see Phase 4.5)
+**All of these mean: return to Phase 1.**
 
@@ -289,3 +285,2 @@
 | "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
-| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |
 
~~~

#### M2 - .claude/skills/systematic-debugging/SKILL.md (affects all projects)
~~~diff
--- a/.claude/skills/systematic-debugging/SKILL.md
+++ b/.claude/skills/systematic-debugging/SKILL.md
@@ -11,5 +11,3 @@
 
-**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.
-
-**Violating the letter of this process is violating the spirit of debugging.**
+**Core principle:** find the root cause before attempting fixes; a symptom fix leaves the cause to resurface somewhere else.
 
~~~

#### M3 - .claude/skills/writing-skills/SKILL.md (affects all projects)
~~~diff
--- a/.claude/skills/writing-skills/SKILL.md
+++ b/.claude/skills/writing-skills/SKILL.md
@@ -504,12 +504,2 @@
 </Good>
-
-### Address "Spirit vs Letter" Arguments
-
-Add foundational principle early:
-
-```markdown
-**Violating the letter of the rules is violating the spirit of the rules.**
-```
-
-This cuts off entire class of "I'm following the spirit" rationalizations.
 
~~~

#### M3 - .claude/skills/writing-skills/testing-skills-with-subagents.md (affects all projects)
~~~diff
--- a/.claude/skills/writing-skills/testing-skills-with-subagents.md
+++ b/.claude/skills/writing-skills/testing-skills-with-subagents.md
@@ -254,4 +254,4 @@
    - Not documentation problem
-   - Need stronger foundational principle
-   - Add "Violating letter is violating spirit"
+   - Mechanically checkable rule: enforce it with a hook (persuasion-principles.md, counter-evidence section)
+   - Otherwise: state the rule's reason beside it, so the trade-off is visible
 
@@ -280,28 +280,2 @@
 - Agent asks permission but argues strongly for violation
-
-## Example: TDD Skill Bulletproofing
-
-### Initial Test (Failed)
-```markdown
-Scenario: 200 lines done, forgot TDD, exhausted, dinner plans
-Agent chose: C (write tests after)
-Rationalization: "Tests after achieve same goals"
-```
-
-### Iteration 1 - Add Counter
-```markdown
-Added section: "Why Order Matters"
-Re-tested: Agent STILL chose C
-New rationalization: "Spirit not letter"
-```
-
-### Iteration 2 - Add Foundational Principle
-```markdown
-Added: "Violating letter is violating spirit"
-Re-tested: Agent chose A (delete it)
-Cited: New principle directly
-Meta-test: "Skill was clear, I should follow it"
-```
-
-**Bulletproof achieved.**
 
~~~

#### M4 - .claude/skills/writing-skills/SKILL.md (affects all projects)
~~~diff
--- a/.claude/skills/writing-skills/SKILL.md
+++ b/.claude/skills/writing-skills/SKILL.md
@@ -613,18 +613,7 @@
 
-## STOP: Before Moving to Next Skill
-
-**After writing ANY skill, you MUST STOP and complete the deployment process.**
-
-**Do NOT:**
-- Create multiple skills in batch without testing each
-- Move to next skill before current one is verified
-- Skip testing because "batching is more efficient"
-
-**The deployment checklist below is MANDATORY for EACH skill.**
-
-Deploying untested skills = deploying untested code. It's a violation of quality standards.
+## One Skill at a Time
+
+Finish the checklist below for each skill before starting the next. Batched untested skills hide which one caused a failure, and deploying an untested skill is deploying untested code.
 
 ## Skill Creation Checklist (TDD Adapted)
-
-**IMPORTANT: Create a todo for EACH checklist item below.**
 
~~~

#### M5 - .claude/skills/writing-skills/SKILL.md (affects all projects)
~~~diff
--- a/.claude/skills/writing-skills/SKILL.md
+++ b/.claude/skills/writing-skills/SKILL.md
@@ -17,3 +17,3 @@
 
-**REQUIRED BACKGROUND:** You MUST understand test-driven-development before using this skill. That skill defines the fundamental RED-GREEN-REFACTOR cycle. This skill adapts TDD to documentation.
+**REQUIRED BACKGROUND:** test-driven-development - it defines the RED-GREEN-REFACTOR cycle this skill adapts to documentation.
 
@@ -283,3 +283,3 @@
 - ✅ Good: `**REQUIRED SUB-SKILL:** Use test-driven-development`
-- ✅ Good: `**REQUIRED BACKGROUND:** You MUST understand systematic-debugging`
+- ✅ Good: `**REQUIRED BACKGROUND:** systematic-debugging`
 - ❌ Bad: `See skills/testing/test-driven-development` (unclear if required)
~~~

#### M5 - .claude/skills/writing-skills/testing-skills-with-subagents.md (affects all projects)
~~~diff
--- a/.claude/skills/writing-skills/testing-skills-with-subagents.md
+++ b/.claude/skills/writing-skills/testing-skills-with-subagents.md
@@ -12,3 +12,3 @@
 
-**REQUIRED BACKGROUND:** You MUST understand test-driven-development before using this skill. That skill defines the fundamental RED-GREEN-REFACTOR cycle. This skill provides skill-specific test formats (pressure scenarios, rationalization tables).
+**REQUIRED BACKGROUND:** test-driven-development - it defines the RED-GREEN-REFACTOR cycle; this file adds skill-specific test formats (pressure scenarios, rationalization tables).
 
~~~

#### M6 - .claude/skills/systematic-debugging/root-cause-tracing.md (affects all projects)
~~~diff
--- a/.claude/skills/systematic-debugging/root-cause-tracing.md
+++ b/.claude/skills/systematic-debugging/root-cause-tracing.md
@@ -161,9 +161 @@
 **Capture stack:** `new Error().stack` shows complete call chain
-
-## Real-World Impact
-
-From debugging session (2025-10-03):
-- Found root cause through 5-level trace
-- Fixed at source (getter validation)
-- Added 4 layers of defense
-- 1847 tests passed, zero pollution
~~~

#### M6 - .claude/skills/systematic-debugging/condition-based-waiting.md (affects all projects)
~~~diff
--- a/.claude/skills/systematic-debugging/condition-based-waiting.md
+++ b/.claude/skills/systematic-debugging/condition-based-waiting.md
@@ -107,9 +107 @@
 3. Comment explaining WHY
-
-## Real-World Impact
-
-From debugging session (2025-10-03):
-- Fixed 15 flaky tests across 3 files
-- Pass rate: 60% → 100%
-- Execution time: 40% faster
-- No more race conditions
~~~

#### M6 - .claude/skills/writing-skills/testing-skills-with-subagents.md (affects all projects)
~~~diff
--- a/.claude/skills/writing-skills/testing-skills-with-subagents.md
+++ b/.claude/skills/writing-skills/testing-skills-with-subagents.md
@@ -375,10 +375 @@
 RED-GREEN-REFACTOR for documentation works exactly like RED-GREEN-REFACTOR for code.
-
-## Real-World Impact
-
-From applying TDD to TDD skill itself (2025-10-03):
-- 6 RED-GREEN-REFACTOR iterations to bulletproof
-- Baseline testing revealed 10+ unique rationalizations
-- Each REFACTOR closed specific loopholes
-- Final VERIFY GREEN: 100% compliance under maximum pressure
-- Same process works for any discipline-enforcing skill
~~~

