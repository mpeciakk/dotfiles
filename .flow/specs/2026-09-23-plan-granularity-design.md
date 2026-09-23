# Plan granularity — middle variant (2026-09-23)

The dotfiles have no living `spec.md`, so this record carries the decisions as
well as the deliberation. Rollback point: `0d2c8b3` (the last commit with
full-code plans + Haiku implementer as the default).

## Problem

Plans had grown to 8–22k words (~1000 per task) because writing-plans required
complete implementation code in every step. Consequences observed:

- the red-team and the reviews took very long on large plans;
- the whole plan sat in the controller's context for the entire run, which is
  the context "the controller does not write code" was meant to protect;
- plan code was written without being run: roughly one task report in six
  mentions correcting plan code, both before and after the implementer moved to
  Haiku 4.5 (keyword count over `.flow/sdd` reports, mtime-dated — indicative
  only);
- Haiku looked as good as Sonnet precisely because implementation had become
  transcription, so that observation did not tell the models apart.

## D1 — What a plan fixes in full

**Chosen:** interfaces (exact signatures), full test code for every RED plus the
expected failure, exact values (names, constants, messages, formats, paths), and
verified external API shapes. Implementation code only where the implementation
is itself a decision — where a reviewer would reject a reasonable alternative
(algorithm, storage format, lock order, a specific error-handling contract).
Otherwise: the approach in 1–3 sentences plus the pattern to follow — an
existing `file:line` or symbol, or a symbol from an earlier task's Produces line.
When no pattern exists at all (greenfield, the first of its kind), that first
instance is itself a decision and gets full code. (Amended at the plan gate after
the red-team pass: without it, a literal planner falls back to full code exactly
where earlier tasks have not been built yet.)

**Rejected — full-code plans (status quo):** decisions all land before the gate
and cross-task names are pinned, but it costs the plan length above, puts code
into the controller's context, and freezes code written before earlier tasks
exist.

**Rejected — general plans (approach only, no code at all):** shortest plans,
but the tests — the one thing the reviewer can hold an implementation to —
would be written by the implementer, and cross-task consistency would rest on
prose.

**Rejected — tests as cases (input → expected) instead of test code:** shorter
still, but the quality of the RED moves to the implementer, and the test is the
contract.

## D2 — Implementer model

**Chosen:** the `implementer` definition moves to Sonnet 5 · high; the
controller overrides to `model: "haiku"` for small, surgical, or fully-specified
changes (spec sync, config, one value, a task whose brief already holds the
complete change). Haiku is the rule for those, not an exception — Sonnet only
where an implementation has to be built. The small lane defaults to Haiku.

**Rejected — a per-task `**Mode:** transcription | build` field in the plan:**
explicit and visible at the plan gate, but one more field to keep right and to
argue about with the red-team, for a case the middle variant makes rare. The
existing per-dispatch model override already covers it. Each dispatch's model
goes into the ledger note (`model=haiku|sonnet`), so fix rounds can be read per
model when the experiment is judged.

## D3 — Reviewing implementation the brief does not fix

The task-reviewer judges an implementation the brief leaves open on quality and
on fidelity to the named pattern; "not how I would have done it" is not a
finding. The contract is the brief's tests, interfaces and values.

## Out of scope

- red-team and branch-reviewer rules (they read less; their rules do not change);
- automated measurement.

## How this gets judged

After two comparable runs, against recent full-code runs: plan word count,
controller tokens per run (transcripts in `~/.claude/projects`), fix rounds per
task (`.flow/run/fix-rounds.json`), tasks needing a plan correction, wall-clock
from "go" to finish. More fix rounds with no clear drop in controller tokens →
revert to `0d2c8b3`'s model. Plans several times shorter at the same round count
→ keep.
