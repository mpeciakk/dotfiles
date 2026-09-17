# Persuasion Principles for Skill Design

## Overview

LLMs respond to the same persuasion principles as humans. Understanding this psychology helps you design more effective skills - not to manipulate, but to ensure critical practices are followed even under pressure.

**Research foundation:** Meincke et al. (2025) tested 7 persuasion principles with N=28,000 AI conversations. Persuasion techniques more than doubled compliance rates (33% → 72%, p < .001).

## The Seven Principles

### 1. Authority
**What it is:** Deference to expertise, credentials, or official sources.

**How it works in skills:**
- Imperative language: "YOU MUST", "Never", "Always"
- Non-negotiable framing: "No exceptions"
- Eliminates decision fatigue and rationalization

**When to use:**
- Discipline-enforcing skills (TDD, verification requirements)
- Safety-critical practices
- Established best practices

**Example:**
```markdown
✅ Write code before test? Delete it. Start over. No exceptions.
❌ Consider writing tests first when feasible.
```

### 2. Commitment
**What it is:** Consistency with prior actions, statements, or public declarations.

**How it works in skills:**
- Require announcements: "Announce skill usage"
- Force explicit choices: "Choose A, B, or C"
- Use tracking: todos for checklists

**When to use:**
- Ensuring skills are actually followed
- Multi-step processes
- Accountability mechanisms

**Example:**
```markdown
✅ When you find a skill, you MUST announce: "I'm using [Skill Name]"
❌ Consider letting your partner know which skill you're using.
```

### 3. Scarcity
**What it is:** Urgency from time limits or limited availability.

**How it works in skills:**
- Time-bound requirements: "Before proceeding"
- Sequential dependencies: "Immediately after X"
- Prevents procrastination

**When to use:**
- Immediate verification requirements
- Time-sensitive workflows
- Preventing "I'll do it later"

**Example:**
```markdown
✅ After completing a task, IMMEDIATELY request code review before proceeding.
❌ You can review code when convenient.
```

### 4. Social Proof
**What it is:** Conformity to what others do or what's considered normal.

**How it works in skills:**
- Universal patterns: "Every time", "Always"
- Failure modes: "X without Y = failure"
- Establishes norms

**When to use:**
- Documenting universal practices
- Warning about common failures
- Reinforcing standards

**Example:**
```markdown
✅ Checklists without todo tracking = steps get skipped. Every time.
❌ Some people find a todo list helpful for checklists.
```

### 5. Unity
**What it is:** Shared identity, "we-ness", in-group belonging.

**How it works in skills:**
- Collaborative language: "our codebase", "we're colleagues"
- Shared goals: "we both want quality"

**When to use:**
- Collaborative workflows
- Establishing team culture
- Non-hierarchical practices

**Example:**
```markdown
✅ We're colleagues working together. I need your honest technical judgment.
❌ You should probably tell me if I'm wrong.
```

### 6. Reciprocity
**What it is:** Obligation to return benefits received.

**How it works:**
- Use sparingly - can feel manipulative
- Rarely needed in skills

**When to avoid:**
- Almost always (other principles more effective)

### 7. Liking
**What it is:** Preference for cooperating with those we like.

**How it works:**
- **DON'T USE for compliance**
- Conflicts with honest feedback culture
- Creates sycophancy

**When to avoid:**
- Always for discipline enforcement

## Principle Combinations by Skill Type

| Skill Type | Use | Avoid |
|------------|-----|-------|
| Discipline-enforcing | Authority + Commitment + Social Proof | Liking, Reciprocity |
| Guidance/technique | Moderate Authority + Unity | Heavy authority |
| Collaborative | Unity + Commitment | Authority, Liking |
| Reference | Clarity only | All persuasion |

## Why This Works: The Psychology

**Bright-line rules reduce rationalization:**
- "YOU MUST" removes decision fatigue
- Absolute language eliminates "is this an exception?" questions
- Explicit anti-rationalization counters close specific loopholes

**Implementation intentions create automatic behavior:**
- Clear triggers + required actions = automatic execution
- "When X, do Y" more effective than "generally do Y"
- Reduces cognitive load on compliance

**LLMs are parahuman:**
- Trained on human text containing these patterns
- Authority language precedes compliance in training data
- Commitment sequences (statement → action) frequently modeled
- Social proof patterns (everyone does X) establish norms

## Ethical Use

**Legitimate:**
- Ensuring critical practices are followed
- Creating effective documentation
- Preventing predictable failures

**Illegitimate:**
- Manipulating for personal gain
- Creating false urgency
- Guilt-based compliance

**The test:** Would this technique serve the user's genuine interests if they fully understood it?

## Research Citations

**Cialdini, R. B. (2021).** *Influence: The Psychology of Persuasion (New and Expanded).* Harper Business.
- Seven principles of persuasion
- Empirical foundation for influence research

**Meincke, L., Shapiro, D., Duckworth, A. L., Mollick, E., Mollick, L., & Cialdini, R. (2025).** Call Me A Jerk: Persuading AI to Comply with Objectionable Requests. University of Pennsylvania.
- Tested 7 principles with N=28,000 LLM conversations
- Compliance increased 33% → 72% with persuasion techniques
- Authority, commitment, scarcity most effective
- Validates parahuman model of LLM behavior

## Counter-evidence from this setup: a checkable rule needs a hook, not an imperative

The 33% → 72% figure above is compliance in a lab, on a single request. Measured
here, across 2030 session transcripts, the three most emphatically worded rules in
this whole setup were the ones broken most:

| The rule, verbatim | Where it lives | Times broken |
|---|---|---|
| "**Do NOT** schedule a short-interval wakeup to poll for background work you started" | the `ScheduleWakeup` tool description | 110 |
| "**Never** … skip the re-review after a fix" | subagent-driven-development | 8 in a row on one task |
| "If ≥ 3: **STOP** … **DON'T** attempt Fix #4" | systematic-debugging | 39 tasks |

Each of those is textbook authority framing — imperative, capitalised,
non-negotiable. None of them held. What holds, measured over the same
transcripts, is `hooks/flow-guard`: a PreToolUse hook that inspects the call and
denies it, with the reason in the denial message. Its own docstring opens
"Enforces things prose demonstrably failed to enforce," and each of its rules was
added *after* the prose version of that rule had already failed.

So, before reaching for authority framing:

**If the rule can be checked mechanically — a tool call's arguments, a file path,
a counter, a sequence — write the hook.** The imperative then belongs in the
denial message, where it arrives at the moment of the violation, aimed at the
specific call, and cannot be rationalised past.

Reserve persuasion for what no hook can see: judgement, ordering, when to stop
and ask. And watch the second cost — the three skills here written hardest in
this style (`test-driven-development`, `verification-before-completion`,
`using-superpowers`) ran 371, 139 and 54 lines, most of it rebutting objections a
fresh subagent has never raised. Two were cut by 80%; one was deleted for
contradicting the pipeline's own triage rule. The prose bought no compliance and
was paid for on every dispatch that preloaded it.

## Quick Reference

When designing a skill, ask:

1. **Can a hook check this?** If yes, write the hook; the prose is a fallback.
2. **What type is it?** (Discipline vs. guidance vs. reference)
3. **What behavior am I trying to change?**
4. **Which principle(s) apply?** (Usually authority + commitment for discipline)
5. **Am I combining too many?** (Don't use all seven)
6. **Is this ethical?** (Serves user's genuine interests?)
