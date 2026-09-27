# Review and spec cost cuts (2026-09-27)

The dotfiles have no living `spec.md`, so this record carries the decisions as
well as the deliberation.

## Problem (transcript analysis, pc, 2026-09-20 → 09-27)

- 65% of weighted usage is cache reads, so context size drives cost.
  `harmonia/spec.md` is 302 KB (§14 Decisions 72 KB, §16 open points 54 KB,
  411 `file:line` citations). Spec-sync tasks ran implementers at 330–342K
  context, cost 3–5× a code task, and made up ~19% of all usage since the weekly
  reset.
- About 30% of first task reviews return Needs fixes, yet there are 0.73 fixer
  dispatches per implementer. Of 147 fixers: 62 after Needs fixes, 34 after
  branch review, 15 after an **Approved** review.
- First-review Important findings (153, regex-classified, medium confidence):
  about 31% TDD evidence, 26% spec/docs/citation drift, 8% report claims, 29%
  code defects.
- plan-red-team verdicts: 62 PROCEED WITH CHANGES, 25 RETHINK, 2 PROCEED, 18
  unparsed out of 107. A sampled report's findings were real. The problem is
  that any finding at all yields WITH CHANGES.

## D1 — Spec size limit and split

**Chosen:** 40 KB per file (spec.md or any docs/ file). Above that, spec.md
becomes an index (Cel, Zakres, one line per topic file). Each
`docs/<topic>.md` holds its own sections, decisions and open points. §/D
numbering stays global. No line numbers anywhere in a spec: cite path + symbol.
Size is checked by the skills that grow the spec (brainstorming, writing-plans),
not only by writing-specs.

**Rejected:**
- Keeping the decision table in spec.md. Harmonia would stay at ~130 KB.
- One `docs/decisions.md`. Every design gate would read 72 KB.
- 25 KB / 80 KB thresholds. 40 KB matches writing-specs' existing 350-line band.
- A hook measuring size on `flow-state set spec=`. More code for one number,
  and the rule still has to say what to do about it.
- Splitting as a side effect of a change. It stays a separate writing-specs job.

## D2 — Reviewer rubric

**Chosen:** missing RED output for a test that exists, targets the new behaviour
and passes → Minor. A test that could not have been RED stays Important. Citation
drift and docs drift → Minor, unless the doc states wrong behaviour or the task's
deliverable is the spec sync.

**Rejected:** dropping the TDD evidence check entirely. The could-not-fail test
is a real defect and the check is what finds it.

## D3 — Fix loops

**Chosen:**
- No fixer after an Approved task review.
- After branch review, Critical/Important plus any Minor the controller keeps go
  to one fixer, and the re-review covers only the fix range.
- Minor-only → one fixer with full-suite evidence, no re-review.

**Rejected:** skipping the re-review for Important fixes after branch review.
That is behaviour change landing unreviewed.

## D4 — Red-team verdict

**Chosen:** PROCEED WITH CHANGES requires at least one blocking or serious
objection. Minor-only → PROCEED plus a list. The controller applies the list to
the plan without a gate and names it in one line at the plan gate.

## D4a — RETHINK vs PROCEED WITH CHANGES

**Chosen:** RETHINK when fixing a blocking objection means a different approach,
not edits to this plan; otherwise PROCEED WITH CHANGES. Added after the
Verification replay: with D4 in place a serious-only report could not be given
either verdict, because plan-red-team never defined RETHINK.

**Rejected:** leaving it for a separate lane. D4 is what exposed the gap, and
closing it costs one sentence.

**Out of scope:**
- red-team effort xhigh → high (no evidence high suffices);
- `tools:` on agents and the duplicate Cloudflare skills (separate small lane);
- splitting harmonia's spec (separate session using the new writing-specs mode);
- the plan-granularity experiment (unchanged: fix rate is driven by the rubric,
  not by plan detail).
