# Prompt audit — slice C (prompt-master, knowledge-transfer; enabled plugins + synced skills)

## Assumptions

- **Scope (Part 1, full audit + diff):** `/home/m/dotfiles/.claude/skills/prompt-master/` (SKILL.md, references/templates.md, references/patterns.md, UPSTREAM.md) and `/home/m/dotfiles/.claude/skills/knowledge-transfer/` (SKILL.md, references/authoring-checks.md, references/research-2026-10-09.md). `/home/m/dotfiles/.claude/CLAUDE.md` was read only to check for conflicts. Git repo root is `/home/m/dotfiles`, and provenance comes from `git blame`. These files are symlinked into `~/.claude` and load in every project, so **every Part 1 edit affects all projects**.
- **Scope (Part 2, report only):** the newest version directory of each enabled plugin: `openai-codex/codex/1.0.6`, `context7-marketplace/context7/1.0.2`, `cloudflare/cloudflare/1.0.2`, `earthtojake/text-to-cad/0.7.22`, `claude-plugins-official/session-report/f359d43b4060`, plus `~/.claude/skills/synced/*`. The user can't edit these files, so every Part 2 item is `flag`.
- **Target model:** Claude Opus 5.5 for everything. None of the audited skills pins a model. The codex-rescue and context7 docs-researcher agents pin `model: sonnet`, and that alias resolves to the current Sonnet.
- **Skipped:** prompt-master `README.md` and `LICENSE` (the model never loads them, and README may still name "Template M — Opus 4.7/4.8"). I did not read settings*.json, .mcp.json, plugin `mcp.json`, hooks/ contents or credentials. For hooks I only checked that `flow-guard` exists. I did not judge the non-Claude routing in prompt-master (GPT, Gemini, Qwen, MiniMax, Midjourney and others): the audit can only check claims against Claude's documented behaviour.

## Summary

The three findings with the most impact:

1. **prompt-master tells the model to add the patterns this audit removes when it writes prompts for Claude.** SKILL.md:444 makes "MUST over should. NEVER over avoid" a check that runs before every prompt is delivered. SKILL.md:425, SKILL.md:387 and templates.md:128 recommend chain of thought, a `<thinking>` section the model must output and "think carefully" wording for Claude. SKILL.md:27 forbids exactly that on current Claude. Opus 5.5, Fable 5.1 and Sonnet 5.5 always think, effort is the only depth control, and a request to reproduce reasoning can be refused (`reasoning_extraction`). Every Claude or Claude Code prompt this skill writes inherits the problem.
2. **prompt-master's Claude knowledge is a frozen roster of 4.x behaviours.** SKILL.md:72 and :176 name "Sonnet 5 / Haiku 4.5" as current, but `models.md` lists Sonnet 5.5 and Haiku 5.5. SKILL.md:74-90 and :177-180 carry Opus 4.6/4.7/4.8 behaviour claims. templates.md:399-452 calls Template M the brief for "Opus 4.7 or 4.8 (current default)", which contradicts SKILL.md:72 in the same skill.
3. **Part 2:** the codex plugin's `codex-rescue` agent is described as "Proactively use…" and "Do not wait for the user to explicitly ask for Codex", and it defaults to `--write`. That conflicts with the user's CLAUDE.md rule of one writer per tree with implementers dispatched by the run. On failure it "return[s] nothing", which contradicts the plugin's own `/codex:setup` guidance and the CLAUDE.md error rule.

knowledge-transfer is clean apart from one history paragraph (M5).

**Counts per group:**
- Part 1: Group 1 = 10 (H1, H2, H3, H4, H9, H10, M1, M2, M3, M4); Group 2 = 6 (H5, H6, H7, H8, M5, M6); Group 3 = 0; Group 4 = not applicable (no request-building code or sub-agent roster in scope). There are also 5 low-confidence `flag` items.
- Part 2 (all `flag`): Group 1 = 1; Group 2 = 7; Group 3 = 1.

## Inventory

| File | Lines | Loads |
|---|---|---|
| skills/prompt-master/SKILL.md | 460 | on trigger |
| skills/prompt-master/references/templates.md | 452 | on demand |
| skills/prompt-master/references/patterns.md | 82 | on demand |
| skills/prompt-master/UPSTREAM.md | 16 | maintainer note (records local edits) |
| skills/knowledge-transfer/SKILL.md | 386 | on trigger |
| skills/knowledge-transfer/references/authoring-checks.md | 163 | on demand |
| skills/knowledge-transfer/references/research-2026-10-09.md | 326 | only when the skill is revised (grepped for signals: clean) |

Provenance: prompt-master was vendored at 914e604 (2026-09-17) from upstream nidhinjs/prompt-master, and 0d2c8b3 (2026-09-23) added the "Opus 5.5 / Sonnet 5 …" lines on top of the 4.x notes. knowledge-transfer dates from 3856ad3 to d8c4986 (2026-10-08 to 2026-10-11). CLAUDE.md:113 ("Never choose silently") comes from 0fc330d (2026-10-13).

---

## Part 1 findings (ordered by confidence)

### High

**H1**
- **Location:** `.claude/skills/prompt-master/SKILL.md:444`
- **Evidence:** "3. Does every instruction use the strongest signal word? MUST over should. NEVER over avoid."
- **Pattern:** 1a pressure language, written as a rule the generator must apply to every prompt.
- **Why obsolete:** Current Claude models respond strongly to the system prompt, so inflated emphasis makes them over-trigger and act rigidly. Once every instruction is in caps, the caps no longer carry information. This check forces that register onto every prompt the skill writes, Claude and Claude Code targets included, and it contradicts the skill's own SKILL.md:78 ("Provide context and reasoning WHY").
- **Confidence:** High (documented in prompt-audit §1a).
- **Action:** `rewrite`. Plain requirement plus reason, with emphasis kept only for a constraint the target is known to underweight.

**H2**
- **Location:** `SKILL.md:425-426`
- **Evidence:** "**Chain of Thought** — for logic, math, and debugging on standard reasoning models ONLY (Claude, GPT-5.x, Gemini, Qwen2.5, Llama)" and "Think through this step by step before answering."
- **Pattern:** 1b scaffold replaced by an API feature, plus a Group 2 internal contradiction with SKILL.md:27.
- **Why obsolete:** Opus 5.5 always thinks, and effort is the only depth control. "Think step by step" is redundant at best, and SKILL.md:27 already forbids it for current Claude. With both lines loaded, the model has to guess which one is in force.
- **Confidence:** High.
- **Action:** `rewrite`. Remove Claude from the eligible list and point to the hard rule.

**H3**
- **Location:** `SKILL.md:387-388`
- **Evidence:** "Logic or analysis task with no step-by-step → add \"Think through this carefully before answering\"" and "CoT added to o3/o4-mini/R1/Qwen3-thinking → REMOVE IT"
- **Pattern:** 1b, prose that steers thinking depth.
- **Why obsolete:** The diagnostic adds depth-steering prose to any logic prompt, Claude included. The removal line leaves out Claude.
- **Confidence:** High.
- **Action:** `rewrite`. Make the first line conditional on a model without built-in reasoning, and add current Claude to the removal line.

**H4**
- **Location:** `references/templates.md:128` (Template E, with the `<thinking>`…`</thinking>` + `<answer>` scaffold at 133-141)
- **Evidence:** "Only use CoT for standard reasoning models (Claude, GPT-4o, Gemini). Do NOT add CoT instructions to o1, o3, or Claude extended thinking"
- **Pattern:** 1b, "show your thinking" and `<thinking>` tag instructions.
- **Why obsolete:** On Opus 5.5, Fable 5.1 and Sonnet 5.5, telling the model to reproduce its reasoning in the output can trigger a `refusal` (reasoning extraction), and thinking can't be turned off, so "Claude extended thinking" is no longer a separate case.
- **Confidence:** High (documented in prompt-audit 1b and models.md).
- **Action:** `rewrite`. Exclude current Claude from Template E. The template stays for non-reasoning models.

**H5**
- **Location:** `SKILL.md:70-90`, with its maintainer note at `UPSTREAM.md:11-16`
- **Evidence:** "Current models: **Opus 5.5**, **Sonnet 5**, **Fable 5.1**, **Haiku 4.5**." / "*Durable across Claude 4.x (4.6 / 4.7 / 4.8):*" / "Claude Opus 4.x over-engineers by default — add …" / "To influence depth: \"Think carefully before responding\" (more) or \"Prioritize responding quickly\" (less)." / "*Opus 4.8 (previous generation)*" / "*Opus 4.7 (older)*"
- **Pattern:** Group 2 volatile specifics and pinned model names, 1d model-version workarounds, and 1b depth-steering prose (line 81).
- **Why obsolete:** `models.md` lists Sonnet 5.5 and Haiku 5.5 as current, so the roster is wrong today. The 4.x behaviour notes describe models that are not current. The "over-engineers → add X" line is a workaround tied to a model version, and the Opus 5.5 guide says to re-test such scope lines rather than carry them over. Prose depth steering doesn't work where effort is the only control. The scope line is kept and re-labelled as "when the user wants a minimal change".
- **Confidence:** High for the roster and line 81; medium for removing the 4.x notes.
- **Action:** `rewrite`. Remove the roster and the per-version notes, and state behaviour for current Claude. UPSTREAM.md must be updated in the same change (hunk H5-upstream) because its "Local changes" list describes the old text.

**H6**
- **Location:** `SKILL.md:176-180` (Claude Code routing)
- **Evidence:** "Current models are Opus 5.5 / Sonnet 5 / Fable 5.1 / Haiku 4.5…" / "Opus 4.7 and 4.8 are more literal than 4.6" / "Opus 4.7+ uses fewer tool calls by default" / "Opus 4.7+ spawns fewer subagents by default" / "Claude Opus 4.x over-engineers"
- **Pattern:** Group 2 stale roster, 1d model-version workarounds.
- **Why obsolete:** The roster is the same stale one as in H5. The 4.7+ tool-call and subagent claims are tied to retired-generation behaviour, and line 72 tells the model to apply them to current models anyway.
- **Confidence:** High for the roster; medium for the rest.
- **Action:** `rewrite`. Keep the purpose of each line as a condition ("when a specific investigation matters, name it"; "when the user wants a minimal change, say so").

**H7**
- **Location:** `references/templates.md:21`, `:399-401`, `:452`
- **Evidence:** "## Template M — Opus 4.7 / 4.8 Task Brief" / "on Claude Opus 4.7 or 4.8 (current default)" / "**When to use:** Opus 4.7 or 4.8 on any surface"
- **Pattern:** Group 2, instruction files that contradict each other, and pinned model names.
- **Why obsolete:** templates.md says Opus 4.7/4.8 is the "current default", while SKILL.md:72 (0d2c8b3, newer) says Opus 5.5 is current. SKILL.md:82 and :184 send every Claude task to this template.
- **Confidence:** High (the repository contradicts itself).
- **Action:** `rewrite`. Rename it "Claude Task Brief" (title, TOC anchor and "when to use"). The newer file's statement wins.

**H8**
- **Location:** `SKILL.md:460` vs `references/patterns.md:3`
- **Evidence:** "the complete 35-pattern reference" vs "37 patterns" (37 rows)
- **Pattern:** Group 2 volatile specifics.
- **Why obsolete:** The repository contradicts it.
- **Confidence:** High.
- **Action:** `rewrite` to 37.

**H9**
- **Location:** `SKILL.md:27`
- **Evidence:** "reasoning-native models (Claude Opus 5.5 / Sonnet 5 / Fable 5.1 with extended thinking or an effort level, …)"
- **Pattern:** 1b and Group 2 stale roster.
- **Why obsolete:** The qualifier "with extended thinking or an effort level" implies these models can run without thinking. Opus 5.5 and Fable 5.1 can't, and Sonnet 5 is no longer the current Sonnet.
- **Confidence:** High.
- **Action:** `rewrite` to "current Claude models", adding the refusal risk for visible-reasoning requests.

**H10**
- **Location:** `references/templates.md:437-440`
- **Evidence:** "Hard multi-step task: `\"Think carefully and step-by-step before starting.\"`" / "Simple targeted change: `\"Prioritize responding quickly…\"`"
- **Pattern:** 1b, prose that steers thinking depth.
- **Why obsolete:** On Opus 5.5 effort is the only thinking control, and on Sonnet 5.5 a request to think less has almost no effect from medium effort up.
- **Confidence:** High.
- **Action:** `rewrite` to one line: depth is set by effort or the harness and stays out of the prompt.

### Medium

**M1**
- **Location:** `SKILL.md:18`
- **Evidence:** "**Hard rules — NEVER violate these**"
- **Pattern:** 1a.
- **Why obsolete:** This is emphasis on the heading. The rules below it already carry their own reasons, and the anxious register carries over into the output.
- **Confidence:** Medium.
- **Action:** `rewrite` to "**Hard rules**".

**M2**
- **Location:** `references/patterns.md:64`
- **Evidence:** "#26 No CoT for logic task … \"Think through both approaches step by step before recommending\""
- **Pattern:** 1b.
- **Why obsolete:** Same issue as H2/H3 in the fix-a-prompt reference. Applied to a pasted Claude prompt, it adds CoT.
- **Confidence:** Medium.
- **Action:** `rewrite`. Scope it to models without built-in reasoning and cross-reference #27.

**M3**
- **Location:** `references/patterns.md:81`
- **Evidence:** "#36 Vague first turn on Opus 4.7 / 4.8 … they no longer fill implicit context like 4.6 did"
- **Pattern:** 1d fossils (pinned model, phrasing relative to an earlier migration: "no longer").
- **Why obsolete:** The text is written as a diff against 4.6, a model the reader never saw.
- **Confidence:** Medium.
- **Action:** `rewrite` so it doesn't name a model.

**M4**
- **Location:** `references/templates.md:433-434` (Template M)
- **Evidence:** "## Progress / After each completed step: ✅ [what was done] — [file(s) affected]"
- **Pattern:** 1b/1f, progress choreography on a fixed cadence.
- **Why obsolete:** Current models report progress at a sensible rate without being told, and a per-step format rule written for older models over-constrains Claude Code runs.
- **Confidence:** Medium.
- **Action:** `rewrite` into a final report (files changed, and how each acceptance criterion was checked). Scope note: `SKILL.md:394` ("Silent agent → add 'After each step output: ✅ …'") and `patterns.md` #22/#33 still prescribe that line for every agentic prompt (kept as L3 because they also serve non-Claude tools). On a Claude Code prompt the Diagnostic Checklist would add the line back. Take M4 together with a scoping edit to :394 ("on a tool without its own progress reporting"), or skip it.

**M5**
- **Location:** `.claude/skills/knowledge-transfer/SKILL.md:361-365`
- **Evidence:** "The quoted rows come from three runs: the skill-less baseline run (`.flow/specs/2026-10-08-knowledge-transfer-evidence/baseline.md`), the first real KT run (edge-vibecoding, D31) and the second real KT run (edge-vibecoding, D32)…"
- **Pattern:** Group 2 history narratives (incident IDs, run archaeology).
- **Why obsolete:** The paragraph prescribes no behaviour. The `.flow/…` paths resolve only from `/home/m/dotfiles`, not in the company repo where KT runs, so they point at nothing for the model running the skill. Provenance is already in git (340ceb8/cfd6029) and in `.flow/specs/…`. The table rows stay: they follow the rationalization-table form that writing-skills prescribes.
- **Confidence:** Medium.
- **Action:** `remove`.

**M6**
- **Location:** `prompt-master/SKILL.md:361` vs `.claude/CLAUDE.md:113`
- **Evidence:** "Fix silently — flag only if the fix changes the user's intent." vs "Never choose silently: name assumptions, show the interpretations when there are several…"
- **Pattern:** Group 2, instruction files that contradict each other.
- **Why obsolete:** Case: the user pastes "write a summary"; the checklist (:377) adds an explicit length and derived success criteria without saying so, and those are assumptions the user never sees named. Per git blame, CLAUDE.md:113 (0fc330d, 2026-10-13) is newer than SKILL.md:361 (914e604, 2026-09-17), and the two always load together. I don't treat the skill line as a task-scoped override: the 💡 line (:37) states what was optimized, not which assumptions were added.
- **Confidence:** Medium.
- **Action:** `rewrite` the older line. Name added assumptions in the existing 💡 line, so the output format doesn't change.

### Low / flag (report only, not in the diff)

- **L1**, `SKILL.md:7, 44, 438, 402, 443`: "PRIMACY ZONE / MIDDLE ZONE / RECENCY ZONE"; "Place it in the first 30% of the prompt so it survives attention decay"; "most critical constraints in the first 30%". This looks like an idiom from the lost-in-the-middle era. I found no documented Opus 5.5 basis for it either way. `flag`, low.
- **L2**, `SKILL.md:183`, `patterns.md:82`: "/compact at ~50% context, not 90%". This is session-management advice with no source, and the threshold is volatile. `flag`, low.
- **L3**, `SKILL.md:394`, `templates.md:250-252` (Template H): "After each step output: ✅ [what was completed]". This is the same cadence pattern as M4, but these lines serve several tools (Devin, Cline and others), so the Claude-only reason doesn't fully apply. `flag`, low.
- **L4**, `SKILL.md:377`, `patterns.md:15, 38`: "Implicit length → add word or sentence count", "exactly 3 sentences", "each under 20 words". This is 1f numeric caps, but on a summary prompt the count is a format spec. `flag`, low.
- **L5**, the non-Claude routing in prompt-master (GPT-5.x, o3, Gemini 2.x/3, Qwen, MiniMax, Midjourney `--v 6`, SD and others): version-pinned third-party claims I can't check against Claude docs. Not audited.

knowledge-transfer otherwise: clean. Its prohibitions ("Never ask" lists, secrets, cold-read rounds) encode real constraints with reasons. The section list pins a format. `model: "sonnet"` is an alias, so it isn't stale. authoring-checks.md and research-2026-10-09.md had no signal hits.

---

## Part 2 findings: plugins and synced skills (all `flag`; the user can't edit these)

Paths are relative to `~/.claude/plugins/cache/` unless stated otherwise.

**P1**
- **Location:** `openai-codex/codex/1.0.6/agents/codex-rescue.md:3, 17, 34`; `skills/codex-cli-runtime/SKILL.md:24, 39`
- **Evidence:** "Proactively use when Claude Code is stuck…"; "Do not wait for the user to explicitly ask for Codex. Use this subagent proactively…"; "Default to a write-capable Codex run by adding `--write`"
- **Pattern:** Conflict with the user's CLAUDE.md (Group 2), plus a trigger booster that controls behaviour (1a).
- **Why it matters:** Case: during inline debugging or an open run, the main thread hands a "substantial debugging task" to codex-rescue without being asked, and Codex edits the working tree with `--write`. That breaks CLAUDE.md rule 5 ("Implementers write task code; you edit only when no implementer is working — one writer per tree") and skips the TDD/systematic-debugging process skills and the branch-review gate. The agent is in the Agent roster of every session.
- **Confidence:** Medium-high.
- **Action:** `flag`. The user decides. Options: add a CLAUDE.md line limiting codex-rescue to explicit `/codex:rescue` requests, or disable the plugin's agent.

**P2**
- **Location:** `openai-codex/codex/1.0.6/agents/codex-rescue.md:42`, `skills/codex-cli-runtime/SKILL.md:43` vs `commands/rescue.md:48`, `skills/codex-result-handling/SKILL.md:21`
- **Evidence:** "If the Bash call fails or Codex cannot be invoked, return nothing." vs "If the helper reports that Codex is missing or unauthenticated, stop and tell the user to run `/codex:setup`."
- **Pattern:** Group 2 contradiction inside the plugin, and a conflict with the CLAUDE.md error rule ("Error: location, cause, fix").
- **Why it matters:** Case: Codex is not logged in. The subagent returns an empty result, so the caller can't tell "no output" from "auth failure", and the setup hint is never shown.
- **Confidence:** Medium.
- **Action:** `flag`.

**P3**
- **Location:** `openai-codex/codex/1.0.6/skills/codex-result-handling/SKILL.md:19`
- **Evidence:** "CRITICAL: After presenting review findings, STOP. … You MUST explicitly ask … strictly forbidden, even if the fix is obvious."
- **Pattern:** 1a pressure language.
- **Why it matters:** The constraint itself is legitimate and agrees with CLAUDE.md. Only the register is dated: it could be one plain sentence with its reason.
- **Confidence:** Medium.
- **Action:** `flag`.

**P4**
- **Location:** cloudflare plugin MCP servers `cloudflare-bindings`, `cloudflare-builds`, `cloudflare-observability` (from the server instructions in this session; I did not read the plugin's mcp.json)
- **Evidence:** "DEPRECATED: This Workers Bindings MCP server is deprecated. Use the Cloudflare API MCP server…" (the same notice appears for builds and observability)
- **Pattern:** Group 3, overlapping near-duplicate tools and tools that are invalid in the current configuration.
- **Why it matters:** `workers_list`, `workers_get_worker`, `workers_get_worker_code`, `search_cloudflare_documentation` and `migrate_pages_to_workers_guide` each appear in 2-3 servers, alongside `cloudflare-api`, which replaces all three deprecated servers. Case: "list my Workers" has three equivalent tools, two of them from servers marked deprecated.
- **Confidence:** Medium-high.
- **Action:** `flag`. The user can disable the three deprecated servers.

**P5**
- **Location:** `cloudflare/cloudflare/1.0.2/skills/turnstile-spin/SKILL.md:131`
- **Evidence:** "**Persist skill.** Ask: \"Save the Spin skill to `.claude/skills/turnstile-spin/SKILL.md`…\" Default yes."
- **Pattern:** Group 2, duplicates that drift.
- **Why it matters:** Case: the user accepts the default. The project gets a frozen copy of a plugin skill that loads next to `cloudflare:turnstile-spin` and never updates with the plugin. It also writes agent configuration as a side effect of a feature task, which goes against the user's "Setup changes: agree direction first" memory and CLAUDE.md's "no 'for later' code".
- **Confidence:** Medium.
- **Action:** `flag`. Answer "no" at that step.

**P6**
- **Location:** `earthtojake/text-to-cad/0.7.22/skills/*/SKILL.md` (18 references, for example `cad/SKILL.md:29, 100`, `dfm/SKILL.md:28, 45, 89`, `sendcutsend/SKILL.md:19, 35`); `step-parts/SKILL.md:3`
- **Evidence:** "use `$dxf`", "search `$step-parts`", "use $cad if available"; description: "Use when Codex needs to search the hosted step.parts catalog…"
- **Pattern:** Group 2 volatile specifics: names that don't resolve in this harness.
- **Why it matters:** In Claude Code these skills are `text-to-cad:cad`, `text-to-cad:dxf` and so on. Case: dfm says "use $cad if available", Claude finds no `$cad` and may conclude the skill isn't available. The step-parts routing text addresses Codex rather than the reader.
- **Confidence:** Medium.
- **Action:** `flag`.

**P7**
- **Location:** `~/.claude/skills/synced/…_f0133014…/docs/SKILL.md:3` (newest bucket; loaded this session as `anthropic-skills:docs`) vs `…_0ba13e53…/docs/SKILL.md:3`
- **Evidence:** "the default for any document, named as a doc or not: … handbook, guide, how-to, cheat sheet, SOP or other writing to keep … create the doc (headings only, no body) before any search, file read or plan" vs the older bucket's "use only when the user asks for one … Documenting code means docstrings or repo docs, not a doc."
- **Pattern:** Group 2, two copies of one skill that disagree, and a conflict with the user's workflow.
- **Why it matters:** Case: "napisz dokument przekazania" matches both knowledge-transfer and docs. The docs trigger demands creating a doc before any file read, which pre-empts KT's scan and its "nothing is written before the yes" gate, and also CLAUDE.md rule 6 (read the spec first). The listing here showed this skill without a description, so the routing risk may be lower in Claude Code than on claude.ai.
- **Confidence:** Medium.
- **Action:** `flag`.

**P8**
- **Location:** `~/.claude/skills/synced/…_f0133014…/{wrangler, cloudflare, workers-best-practices, cloudflare-one, cloudflare-email-service}/SKILL.md`
- **Evidence:** The manifest has the same names with `updatedAt 2026-07-21`. Synced wrangler is 922 lines vs 71 in plugin 1.0.2; cloudflare is 248 vs 149; workers-best-practices is 127 vs 60.
- **Pattern:** Group 2, duplicates that drift (older, larger copies with the same names).
- **Why it matters:** Where both copies load, two versions of the same guidance compete. They did not appear in this session's skill list, so they are on disk but not loaded here.
- **Confidence:** Medium.
- **Action:** `flag`. Remove them from the claude.ai skill set if the plugin is the intended source.

**P9**
- **Location:** `~/.claude/skills/synced/…_f0133014…/the-humanizer/SKILL.md:16-27`, `:3-4`
- **Evidence:** "## Changelog … This section must be maintained on every edit." (12 dated version rows in the body); description: "Review any written content (… emails, Slack messages) … improve the voice or tone of any written content … \"email review\""
- **Pattern:** Group 2 history narratives, plus a trigger overlap.
- **Why it matters:** The changelog is archaeology loaded on every invocation. The word lists only cover English, and the triggers overlap the user's `polszczyzna` skill (Polish emails and texts). Case: "popraw ton tego maila" (a Polish email) could route to English-calibrated rewrite rules. Not loaded in this session.
- **Confidence:** Medium.
- **Action:** `flag`.

Clean or not flagged in Part 2:
- context7: its Step 1-4 is the tools' required call order (keep-list 3).
- session-report.
- The bodies of the cloudflare plugin skills: turnstile's "must NOT" list holds security contracts with reasons, and the CRITICAL markers in the smart-placement references sit on reference facts (low at most).
- The "never" rules in synced pptx/pdf: they are file-corruption contracts (keep-list 4).
- import-memory: it only runs where memory tools exist.

---

## Proposed diff (Part 1 only; every hunk affects all projects)

Paths are relative to `/home/m/dotfiles`. There is one finding per hunk; H5 includes its required `UPSTREAM.md` companion hunk, and H7 has three hunks. Each hunk was generated against HEAD. I checked on a scratch copy that every hunk applies on its own and that all of them apply together with `git apply`. Nothing was applied to the repo.

```diff
# H1 — affects all projects
--- a/.claude/skills/prompt-master/SKILL.md
+++ b/.claude/skills/prompt-master/SKILL.md
@@ -441,7 +441,7 @@
 
 1. Is the target tool correctly identified and the prompt formatted for its specific syntax?
 2. Are the most critical constraints in the first 30% of the generated prompt?
-3. Does every instruction use the strongest signal word? MUST over should. NEVER over avoid.
+3. Is every requirement stated plainly as a requirement ("Include X", not "try to include X"), with its reason where it isn't obvious? Reserve caps emphasis (MUST, NEVER) for a constraint the target model is known to underweight — on current Claude models it causes over-triggering.
 4. Has every fabricated technique been removed?
 5. Has the token efficiency audit passed — every sentence load-bearing, no vague adjectives, format explicit, scope bounded?
 6. Would this prompt produce the right output on the first attempt?

# H2 — affects all projects
--- a/.claude/skills/prompt-master/SKILL.md
+++ b/.claude/skills/prompt-master/SKILL.md
@@ -422,7 +422,7 @@
 **Grounding anchors** — for any factual or citation task:
 "Use only information you are highly confident is accurate. If uncertain, write [uncertain] next to the claim. Do not fabricate citations or statistics."
 
-**Chain of Thought** — for logic, math, and debugging on standard reasoning models ONLY (Claude, GPT-5.x, Gemini, Qwen2.5, Llama). Never on o3/o4-mini/R1/Qwen3-thinking.
+**Chain of Thought** — for logic, math, and debugging on standard models ONLY (GPT-5.x, Gemini, Qwen2.5, Llama). Never on current Claude models or o3/o4-mini/R1/Qwen3-thinking — they reason internally (see Hard rules).
 "Think through this step by step before answering."
 
 ---

# H3 — affects all projects
--- a/.claude/skills/prompt-master/SKILL.md
+++ b/.claude/skills/prompt-master/SKILL.md
@@ -384,8 +384,8 @@
 - Entire codebase pasted as context → scope to the relevant file and function only
 
 **Reasoning failures**
-- Logic or analysis task with no step-by-step → add "Think through this carefully before answering"
-- CoT added to o3/o4-mini/R1/Qwen3-thinking → REMOVE IT
+- Logic or analysis task with no step-by-step, on a model without built-in reasoning → add "Think through this carefully before answering"
+- CoT or thinking-depth wording added to a reasoning-native model (current Claude, o3/o4-mini/R1/Qwen3-thinking) → remove it
 - New prompt contradicts prior session decisions → flag, resolve, include memory block
 
 **Agentic failures**

# H4 — affects all projects
--- a/.claude/skills/prompt-master/references/templates.md
+++ b/.claude/skills/prompt-master/references/templates.md
@@ -126,5 +126,5 @@
 *Use for logic-heavy tasks, math, debugging, and multi-factor analysis where the AI needs to reason carefully before committing to an answer.*
 
-**Important:** Only use CoT for standard reasoning models (Claude, GPT-4o, Gemini). Do NOT add CoT instructions to o1, o3, or Claude extended thinking — they reason internally and CoT instructions degrade their output.
+Only use CoT for standard models (GPT-4o, Gemini). Do not use it for current Claude models, o1 or o3 — they reason internally and CoT instructions degrade their output; on current Claude the `<thinking>` section below also asks the model to reproduce its reasoning, which can be refused.
 
 ```

# H5 — affects all projects
--- a/.claude/skills/prompt-master/SKILL.md
+++ b/.claude/skills/prompt-master/SKILL.md
@@ -67,27 +67,17 @@
 
 ---
 
-**Claude (claude.ai, Claude API, Claude 5.x / 4.x)**
-
-Current models: **Opus 5.5**, **Sonnet 5**, **Fable 5.1**, **Haiku 4.5**. The version notes below were written for the 4.x generation; the durable ones still apply, but assume a current model unless the user names an older version.
-
-*Durable across Claude 4.x (4.6 / 4.7 / 4.8):*
-- Be explicit and specific — Claude 4.x follows instructions literally. It does exactly what you say, nothing more. Missing context = narrow literal output, not a smart guess.
-- Claude Opus 4.x over-engineers by default — add "Only make changes directly requested. Do not add features or refactor beyond what was asked."
+**Claude (claude.ai, Claude API)**
+
+Current Claude models think internally: depth is set by the API's `effort` parameter or by the harness, not by prompt wording.
+- Be explicit and specific — Claude follows instructions literally. It does exactly what you say, nothing more. Missing context = narrow literal output, not a smart guess.
+- When the user wants a minimal change, say so: "Only make changes directly requested. Do not add features or refactor beyond what was asked."
 - XML tags help for complex multi-section prompts: `<context>`, `<task>`, `<constraints>`, `<output_format>`
 - Provide context and reasoning WHY, not just WHAT — Claude generalizes better from explanations
 - Always specify output format and length explicitly
 - For complex or multi-step tasks: front-load everything in one turn — intent, constraints, acceptance criteria, relevant files. Every extra back-and-forth turn adds reasoning overhead and token cost.
-- Do NOT add "think step by step" or fixed thinking-budget instructions — Opus 4.x uses adaptive thinking and calibrates depth automatically. To influence depth: "Think carefully before responding" (more) or "Prioritize responding quickly" (less).
+- Do not add "think step by step", thinking-depth wording ("think carefully", "prioritize responding quickly") or a visible reasoning section (`<thinking>` tags, a `reasoning` field) — redundant on current Claude, and a request to reproduce reasoning can be refused.
 - Use Template M for agentic or multi-step tasks.
-
-*Opus 4.8 (previous generation):*
-- Shares 4.7's literalism and adaptive thinking — the same front-loading discipline applies. Treat the first turn as the only turn for complex work: intent, scope, constraints, acceptance criteria up front.
-- 1M-token context window — large multi-file context can go in a single prompt, but keep it relevant; padding still dilutes attention.
-- Effort/thinking depth is calibrated automatically — do not specify an effort level or thinking budget.
-
-*Opus 4.7 (older):*
-- More literal than 4.6 — vague first turns produce narrower results. Front-load intent, file scope, constraints, and acceptance criteria.
 
 ---
 

# H5-upstream — affects all projects
--- a/.claude/skills/prompt-master/UPSTREAM.md
+++ b/.claude/skills/prompt-master/UPSTREAM.md
@@ -8,9 +8,12 @@
 `diff -r` against this directory, and port what you want.
 
 Local changes since that commit:
-- SKILL.md, hard rules: the reasoning-native model list names Claude Opus 5.5 / Fable 5.1 /
-  Sonnet 5 (extended thinking or an effort level) alongside o3, o4-mini,
-  DeepSeek-R1 and Qwen3.
-- SKILL.md, Claude routing and Claude Code sections: the current model line names
-  Opus 5.5 / Sonnet 5 / Fable 5.1 / Haiku 4.5 instead of "Opus 4.8 (current
-  default)"; the 4.x notes stay, labeled as the previous generation.
+- SKILL.md, hard rules and CoT guidance (hard rules, diagnostic checklist, Safe
+  Techniques; templates.md Template E; patterns.md #26): current Claude models are
+  reasoning-native — no CoT, thinking-depth wording or visible reasoning sections.
+- SKILL.md, Claude routing and Claude Code sections: no model roster and no 4.x
+  version notes; behaviour stated for current Claude models.
+- templates.md Template M is the "Claude Task Brief" (was "Opus 4.7 / 4.8"); no
+  thinking-depth lines; a final report instead of per-step progress lines.
+- patterns.md #36 is model-neutral; SKILL.md names the 37-pattern reference.
+- SKILL.md: plain-emphasis verification item; assumptions named in the 💡 line.

# H6 — affects all projects
--- a/.claude/skills/prompt-master/SKILL.md
+++ b/.claude/skills/prompt-master/SKILL.md
@@ -173,11 +173,10 @@
 - Agentic — runs tools, edits files, executes commands autonomously
 - Starting state + target state + allowed actions + forbidden actions + stop conditions + checkpoints
 - Stop conditions are MANDATORY — runaway loops are the biggest credit killer
-- Current models are Opus 5.5 / Sonnet 5 / Fable 5.1 / Haiku 4.5. Effort and thinking depth are managed by the Claude Code harness on current models — do NOT hardcode an effort level or thinking budget in prompts.
-- Opus 4.7 and 4.8 are more literal than 4.6 — vague first turns produce narrower results. Front-load everything: intent, file scope, constraints, acceptance criteria, session strategy.
-- Opus 4.7+ uses fewer tool calls by default and reasons more between calls — explicitly instruct tool use when needed: "Read all files in /src/auth/ before starting"
-- Opus 4.7+ spawns fewer subagents by default — explicitly request when needed: "Use a subagent to investigate X so it stays out of main context"
-- Claude Opus 4.x over-engineers — add "Only make changes directly requested. Do not add extra files, abstractions, or features."
+- Effort and thinking depth are set by the Claude Code harness — leave effort levels, thinking budgets and thinking-depth wording out of the prompt.
+- Claude reads prompts literally — vague first turns produce narrower results. Front-load everything: intent, file scope, constraints, acceptance criteria, session strategy.
+- When a specific investigation matters, name it: "Read all files in /src/auth/ before starting", "Use a subagent to investigate X so it stays out of main context"
+- When the user wants a minimal change, say so: "Only make changes directly requested. Do not add extra files, abstractions, or features."
 - Always scope to specific files and directories — never give a global instruction without a path anchor
 - Human review triggers required: "Stop and ask before deleting any file, adding any dependency, or affecting the database schema"
 - Session hygiene matters: new task = new session. Use /rewind instead of correcting mid-conversation. /compact at ~50% context, not 90%.

# H7a — affects all projects
--- a/.claude/skills/prompt-master/references/templates.md
+++ b/.claude/skills/prompt-master/references/templates.md
@@ -19,5 +19,5 @@
 | [K — ComfyUI](#template-k--comfyui) | ComfyUI node-based image workflows |
 | [L — Prompt Decompiler](#template-l--prompt-decompiler) | Breaking down, adapting, or splitting existing prompts |
-| [M — Opus 4.7 / 4.8 Task Brief](#template-m--opus-4.7--4.8-task-brief) | Complex, multi-step, or agentic task on Claude Opus 4.7 or 4.8 |
+| [M — Claude Task Brief](#template-m--claude-task-brief) | Complex, multi-step, or agentic task on Claude |
 
 ---

# H7b — affects all projects
--- a/.claude/skills/prompt-master/references/templates.md
+++ b/.claude/skills/prompt-master/references/templates.md
@@ -397,7 +397,7 @@
 ---
 
-## Template M — Opus 4.7 / 4.8 Task Brief
-
-*Use for any complex, multi-step, or agentic task on Claude Opus 4.7 or 4.8 (current default) — claude.ai, API, or Claude Code. Both read prompts literally and produce narrow output when context is missing. This template front-loads everything so the first turn is the only turn.*
+## Template M — Claude Task Brief
+
+*Use for any complex, multi-step, or agentic task on Claude — claude.ai, API, or Claude Code. Claude reads prompts literally and produces narrow output when context is missing. This template front-loads everything so the first turn is the only turn.*
 
 ```

# H7c — affects all projects
--- a/.claude/skills/prompt-master/references/templates.md
+++ b/.claude/skills/prompt-master/references/templates.md
@@ -450,3 +450,3 @@
 ```
 
-**When to use:** Opus 4.7 or 4.8 on any surface — claude.ai, API, Claude Code — when the task is complex, multi-file, ambiguous, or agentic. Not needed for simple one-shot tasks.
+**When to use:** Claude on any surface — claude.ai, API, Claude Code — when the task is complex, multi-file, ambiguous, or agentic. Not needed for simple one-shot tasks.

# H8 — affects all projects
--- a/.claude/skills/prompt-master/SKILL.md
+++ b/.claude/skills/prompt-master/SKILL.md
@@ -457,4 +457,4 @@
 | File | Read When |
 |------|-----------|
 | [references/templates.md](references/templates.md) | You need the full template structure for any tool category |
-| [references/patterns.md](references/patterns.md) | User pastes a bad prompt to fix, or you need the complete 35-pattern reference |
+| [references/patterns.md](references/patterns.md) | User pastes a bad prompt to fix, or you need the complete 37-pattern reference |

# H9 — affects all projects
--- a/.claude/skills/prompt-master/SKILL.md
+++ b/.claude/skills/prompt-master/SKILL.md
@@ -24,7 +24,7 @@
   - **Graph of Thought** -- requires an external graph engine not present in most tools
   - **Universal Self-Consistency** -- requires independent sampling passes
   - **Prompt chaining as a layered technique** -- compounds fabrication risk across longer chains
-- Do not add Chain of Thought to reasoning-native models (Claude Opus 5.5 / Sonnet 5 / Fable 5.1 with extended thinking or an effort level, o3, o4-mini, DeepSeek-R1, Qwen3 thinking mode) — they think internally, CoT degrades output
+- Do not add Chain of Thought to reasoning-native models (current Claude models, o3, o4-mini, DeepSeek-R1, Qwen3 thinking mode) — they think internally, CoT degrades output; on current Claude a request to show the reasoning can also be refused
 - Do not ask more than 3 clarifying questions before producing a prompt
 - Do not pad output with explanations the user did not request
 

# H10 — affects all projects
--- a/.claude/skills/prompt-master/references/templates.md
+++ b/.claude/skills/prompt-master/references/templates.md
@@ -435,8 +435,5 @@
 ```
 
-**Thinking depth** — add only when needed, delete otherwise:
-- Hard multi-step task: `"Think carefully and step-by-step before starting."`
-- Simple targeted change: `"Prioritize responding quickly. This is a scoped change."`
-- Default: say nothing — adaptive thinking calibrates itself.
+**Thinking depth** — leave it out of the prompt: current Claude sets it from `effort` (API) or the harness (Claude Code).
 
 **Claude Code only — add Session Strategy block when relevant:**

# M1 — affects all projects
--- a/.claude/skills/prompt-master/SKILL.md
+++ b/.claude/skills/prompt-master/SKILL.md
@@ -15,7 +15,7 @@
 
 ---
 
-**Hard rules — NEVER violate these**
+**Hard rules**
 
 - Do not output a prompt without first confirming the target tool — ask if ambiguous
 - Prefer simpler techniques (role assignment, few-shot, grounding anchors, chain of thought) over complex meta-reasoning frameworks in single-prompt contexts. The following techniques carry higher fabrication risk when used in a single prompt and should only be applied when the user explicitly requests them and the target tool supports them:

# M2 — affects all projects
--- a/.claude/skills/prompt-master/references/patterns.md
+++ b/.claude/skills/prompt-master/references/patterns.md
@@ -61,7 +61,7 @@
 
 | # | Pattern | Bad Example | Fixed |
 |---|---------|------------|-------|
-| 26 | **No CoT for logic task** | "which approach is better?" | "Think through both approaches step by step before recommending" |
+| 26 | **No CoT for logic task (model without built-in reasoning)** | "which approach is better?" | "Think through both approaches step by step before recommending" — not for current Claude or other reasoning models (#27) |
 | 27 | **Adding CoT to reasoning models** | "think step by step" sent to o1/o3 | Remove it — reasoning models think internally, CoT instructions degrade output |
 | 28 | **Expecting inter-session memory** | "you already know my project" | Always re-provide the Memory Block in every new session |
 | 29 | **Contradicting prior work** | New prompt ignores earlier architecture | Include Memory Block with all established decisions |

# M3 — affects all projects
--- a/.claude/skills/prompt-master/references/patterns.md
+++ b/.claude/skills/prompt-master/references/patterns.md
@@ -78,5 +78,5 @@
 | 33 | **Silent agent** | No progress output | "After each step output: ✅ [what was completed]" |
 | 34 | **Unlocked filesystem** | No file restrictions | "Only edit files inside `src/`. Do not touch `package.json`, `.env`, or any config file." |
 | 35 | **No human review trigger** | Agent decides everything autonomously | "Stop and ask before: deleting any file, adding any dependency, or changing the database schema" |
-| 36 | **Vague first turn on Opus 4.7 / 4.8** | "fix the auth bug" with no scope, no files, no criteria | Opus 4.7 and 4.8 read prompts literally — they no longer fill implicit context like 4.6 did. Use Template M. Front-load intent, file scope, constraints, and acceptance criteria. |
+| 36 | **Vague first turn on Claude** | "fix the auth bug" with no scope, no files, no criteria | Claude reads prompts literally and does not fill implicit context. Use Template M. Front-load intent, file scope, constraints, and acceptance criteria. |
 | 37 | **Context rot on long sessions** | Keeps correcting in the same session for 60+ turns | New task = new session. Use /rewind instead of correcting. /compact at ~50% context. Subagents for file-heavy investigation. |

# M4 — affects all projects
--- a/.claude/skills/prompt-master/references/templates.md
+++ b/.claude/skills/prompt-master/references/templates.md
@@ -431,6 +431,6 @@
 - Touching anything outside Scope
 
-## Progress
-After each completed step: ✅ [what was done] — [file(s) affected]
+## Final Report
+When done: every file changed, and how each acceptance criterion was checked.
 ```
 

# M5 — affects all projects
--- a/.claude/skills/knowledge-transfer/SKILL.md
+++ b/.claude/skills/knowledge-transfer/SKILL.md
@@ -358,12 +358,6 @@
 
 ## Common mistakes
 
-The quoted rows come from three runs: the skill-less baseline run
-(`.flow/specs/2026-10-08-knowledge-transfer-evidence/baseline.md`), the first
-real KT run (edge-vibecoding, D31) and the second real KT run (edge-vibecoding,
-D32). The unquoted generic rows describe failures seen in the D32 fixture runs
-(`.flow/specs/2026-10-08-knowledge-transfer-evidence/d32.md`).
-
 | Mistake | Counter |
 |---|---|
 | Wrote the whole package first, asked nothing: "przed wyjazdem sam musisz uzupełnić jego sekcję 7 (sześć punktów, które trzeba wpisać)" | The inventory gate and the interview come before the first Write. A gap is yours to ask about, with a hypothesis; the user's closing task list is not a deliverable. |

# M6 — affects all projects
--- a/.claude/skills/prompt-master/SKILL.md
+++ b/.claude/skills/prompt-master/SKILL.md
@@ -358,7 +358,7 @@
 
 ### Diagnostic Checklist
 
-Scan every user-provided prompt or rough idea for these failure patterns. Fix silently — flag only if the fix changes the user's intent.
+Scan every user-provided prompt or rough idea for these failure patterns and fix them in the prompt. Name in the 💡 line any assumption a fix introduced (derived success criteria, format, length, scope) so the user can correct it.
 
 **Task failures**
 - Vague task verb → replace with a precise operation
```

Not verified: no behavioural probe (Step 7) was run. The H1-H10 removals are hypotheses until a Claude-target prompt generated by the edited skill has been compared against one from the current skill.
