---
name: writing-skills
description: Use when creating a new skill, editing an existing skill, or checking that a skill works before it is deployed.
---

# Writing Skills

A skill is a reusable technique, pattern or reference that a future session
finds by its description and reads when the task matches. It is not the
story of how one problem was solved once.

Platform docs for structure and frontmatter fields:
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- https://code.claude.com/docs/en/skills (Claude Code fields such as
  `disable-model-invocation`, `argument-hint`)

Where they say a description holds "what the skill does and when to use it",
this setup overrides them: see Description.

## When a skill, when not

Write one for a technique that was not obvious, that you will reach for again
across projects. Not for: a one-off fix, a practice documented well
elsewhere, a project convention (it goes in that project's CLAUDE.md or
spec), or a rule a tool can check (see Hooks beat imperatives).

## Description

The description sits in the system prompt of every session and decides
whether the skill is read at all. It lists **only when to use the skill**:
"Use when…", then the triggers — the situations, symptoms, error messages and
phrases a user would type. It never says what the skill does or summarises
its steps.

Why: when a description summarised the process ("code review between
tasks"), the agent followed the description and skipped the body — one
review instead of the two the skill required. With triggers only, it read the
skill.

- Words a user would type stay, as triggers: "the user asks to merge, open a
  PR, keep or discard the branch".
- Describe the problem ("tests pass and fail inconsistently"), not one
  technology's symptom (`setTimeout`), unless the skill is about that
  technology.
- Third person. Name the exclusions ("Not for …") only where they keep two
  skills' triggers apart.

```yaml
# Wrong: summarises the process
description: Use when executing plans - dispatches subagent per task with code review between tasks
# Right: triggers only
description: Use when executing an approved plan task by task, or resuming a run ("go", "execute the plan", "next task", "kontynuuj", after /clear or compaction).
```

## Name and structure

- Name: letters, digits and hyphens; verb-first, by what you do
  (`condition-based-waiting`, not `async-test-helpers`).
- SKILL.md opens with the core idea in one or two sentences, then what to do.
  A table or short list for anything scanned rather than read. One good
  example in the most relevant language, not five mediocre ones.
- A separate file for content read only in a specific situation (a method
  for one kind of bug, a long reference) or for a reusable tool (script,
  template). Link it by relative path with a "read this when…" line; never
  `@`-link a file, which loads it into context immediately.
- Point to another skill by name ("per systematic-debugging"); do not copy
  its content.
- No flowchart for linear steps or reference; numbered steps or a table read
  better and cannot contradict the prose around them.

**Cost:** every description is paid in every session; the body on every use;
reference files only when read. Cut the description hardest.

## Match the form to the failure

Classify what goes wrong without the guidance before writing it. The form
that fixes one failure backfires on another.

| Failure without guidance | Right form | Wrong form |
|---|---|---|
| Knows the rule, skips it under pressure | Prohibition with its reason, plus the excuses actually seen | Soft "prefer…", "consider…" |
| Complies, but the output has the wrong shape | A recipe: what the output is, its parts, in order | A list of "don't…" |
| Omits a required element | A required slot in the template it fills in | A reminder near the template |
| Behaviour depends on a condition | A conditional on an observable predicate | A rule plus exemption clauses |

Measured in wording tests on dispatch-prompt guidance: the prohibition arm
produced more of the unwanted content than the recipe arm, with fully
separated distributions, and trended worse than no guidance at all. Adding
one nuance clause ("don't X unless it matters") to a winning recipe made it
noisy. An exemption clause ("this limit doesn't apply to code blocks") still
suppressed the exempted part.

## Hooks beat imperatives

Persuasion framing raised compliance from 33% to 72% in a lab, on single
requests (Meincke et al., 2025). Measured here, across 2030 session
transcripts, the three most emphatically worded rules were the ones broken
most:

| The rule, verbatim | Where it lived (at the time; history) | Times broken |
|---|---|---|
| "**Do NOT** schedule a short-interval wakeup to poll for background work you started" | the `ScheduleWakeup` tool description | 110 |
| "**Never** … skip the re-review after a fix" | subagent-driven-development (since replaced by executing-plans) | 8 in a row on one task |
| "If ≥ 3: **STOP** … **DON'T** attempt Fix #4" | systematic-debugging (since rewritten) | 39 tasks |

What held was `hooks/flow-guard`, a PreToolUse hook that denies the call and
gives the reason in the denial. Each of its rules was added after the prose
version had failed.

- **A rule a tool can check** — a call's arguments, a path, a counter, a
  sequence — gets a hook. The imperative goes in the denial message.
- **Prose is for what no hook can see:** judgement, ordering, when to stop and
  ask. State the reason beside the rule instead of raising its volume.
- **Rebuttal prose mostly buys nothing.** The skills written hardest in that
  style ran 54–371 lines, mostly answering objections a fresh session never
  raised. The one measured exception: upstream, deleting a short table of the
  excuses actually made under "just write it, tests after" dropped test-first
  from 8/10 to 5/10. Keep such a table only when it answers excuses you saw.

## Testing a discipline skill

A discipline skill holds a rule an agent under pressure is tempted to skip.
It ships only after a baseline vs treatment test. Other skills, and trivial
edits to any skill, follow CLAUDE.md "Code": a checkable goal and a real run.

1. **Scenarios first.** Write 3 pressure scenarios that tempt the failure, and
   for each the one behaviour that counts as a pass, before any run. Combine
   3+ pressures: time, sunk cost, authority, exhaustion, "being pragmatic".
   Make the agent act and choose: concrete options (A/B/C), real paths and
   times, no "I'd ask" exit.
2. **Isolate the text under test.** One read-only subagent per run, without
   the Skill tool and told not to invoke skills, with the skill text inlined
   in its prompt. Otherwise it loads the deployed copy, not your draft.
3. **Baseline:** run the scenarios with no skill. A scenario the baseline
   passes measures nothing; replace it or drop it. If none fails: for a new
   skill there is nothing to fix — stop; for a rewrite, the scenarios are too
   weak to catch a regression — harden them, or record that the test cannot
   discriminate and let the review be the check.
4. **Treatment:** run the scenarios that failed with the skill, 3+ runs each
   (single samples lie). Against an existing version, run old and new; the
   new one must pass at least as often.
5. **Read every answer.** Note the excuses verbatim. Converging answers mean
   the wording binds; five different readings in five runs mean it does not —
   change the form before adding words.
6. **Agent chose wrong with the skill present:** ask it how the skill could
   have made the right option unmistakable.
   - "It was clear, I ignored it" → if checkable, a hook; else the reason
     beside the rule.
   - "It should have said X" → add X.
   - "I didn't see section Y" → move Y earlier.
7. **Record** scenarios, pass behaviours and every verdict in the project's
   `.flow/probes/`.

Wording-only checks before full scenarios: one fresh-context sample per call,
system prompt = the full context the guidance will live in, always a
no-guidance control, 5+ samples per variant.

## Before deploying

- [ ] Description: "Use when…" and triggers only; no process summary.
- [ ] Guidance form matches the failure (table above).
- [ ] Every relative link resolves; no `@` links.
- [ ] Discipline skill: the baseline vs treatment record exists.
- [ ] Deployed with `dotter deploy`; `find ~/.claude/skills -xtype l` is
      empty.
