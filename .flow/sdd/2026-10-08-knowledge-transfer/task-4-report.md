# Task 4 report: baseline (RED), resumed after a crashed implementer

Status: DONE_WITH_CONCERNS. Commit: `1573f10 test: knowledge-transfer baseline without the skill`
(branch `worktree-feat-knowledge-transfer`, worktree verified before the edit and before the commit).

## What I did (steps 3-5 only; steps 1-2 were already done)

- Verified `EV/scenario.md` matches the brief's fenced block (diff clean) and that
  `EV/baseline-package.md` is byte-identical to `git show HEAD:PRZEKAZANIE.md` in the
  fixture `/tmp/kt-baseline.WiOr2S/fx` (diff clean). Did not re-run any nested `claude`
  and did not re-run make-fixture.
- Step 3: ran the checker. Output (verbatim, also in `EV/baseline.md`):

```
PASS C1 sekret
PASS C2 bez kopii speca
FAIL C3 cold-reader: no successful kt-cold-reader result containing 'Podstawa:'
PASS C4 wiedza ukryta
FAIL C5 snapshot: no short SHA from the fixture history
PASS C6 bez zmian w istniejących plikach
4/6 PASS        (exit 1)
```

  Stop rule not triggered: C5 fails, so C1/C2/C4/C5/C6 do not all pass.
- Step 4: wrote `EV/baseline.md` (checker output, reconstructed answer log, whether the
  session asked before writing, spec restatement, verbatim quotes, DENIED lines).
- Step 5: committed exactly the brief's files (scenario.md, baseline.md,
  baseline-package.md, baseline-transcripts/), message as in the brief plus the
  attribution trailer. `.flow/sdd/` stays untracked.

## TDD evidence

This task is a measurement, not production code: the RED is the failing checker on a
session without the skill (`bash EV/check-package.sh EV/baseline-package.md
/tmp/kt-baseline.WiOr2S/fx EV/baseline-transcripts` -> 4/6, exit 1; C3 fails by
construction, C5 genuinely). The GREEN comes in Task 5 with the skill and must be 6/6.
I also verified that all 17 "verbatim" quotes in the quotes section of `baseline.md`
are substrings of the corresponding `result` text (script run, two initially off by
markdown bold / quote glyphs, fixed, re-run clean in the committed state).

## Findings that matter for Task 5

1. Genuine measurable gap on the checker: only C5 (no snapshot pin). The package has no
   snapshot SHA and no "state as of" marker (it has calendar dates, none pinning the repo state). C3 is a gap by construction.
2. Baseline is strong; I did not inflate it. It already has a dated token expiry (30 Oct,
   computed with `date`), an open-items section, and states the spec/code mismatch.
3. C4 overstates: the session asked nothing before its first Write (tool order in
   turn-1: reads only, one Skill call to `polszczyzna`, then Write). All seven facts
   arrived because the simulated user volunteered them in turn 2 in reply to the
   session's "do uzupełnienia" list, not because of an interview.
4. C2 passes on a technicality: package sections 2, 3, 8 are near-verbatim restatements
   of spec.md, differing only enough to dodge line-level matching.
5. Unsupported claims in the package (not in facts or repo): "300 na minutę" as a limit,
   "powtarzaj w każdy poniedziałek", the token-renewal steps and "środa 28 października",
   `.env` on the server. Two inferences are honestly flagged by the session.
6. The session refused to commit on "Akceptuję" in turns 2-5 (waited for "commituj"),
   committed in turn 6.

## DENIED

Two `DENIED Bash` in turn 1 (compound command / variable in command), none in turns 2-6.
No DENIED Skill/Agent/Write/Edit, so no harness failure.

## Answer log and deviations from user-facts.md

Prompts recovered verbatim from the nested session's own history
(`~/.claude/projects/-tmp-kt-baseline-WiOr2S-fx/fc0e81ee-....jsonl`); all five are in
`baseline.md`. The simulator's decisions were not logged by the crashed run, so the
log lines and the keyword hits are reconstructed by me (mechanical stem matching, my
stem list). Deviations: turn 2 volunteered F1-F7 although the preceding result had no
question (the one that matters); turn 3 gave F3/F5/F7 (the only literal question matches
F7); turn 5 omitted F2 although "token"/"SMSAPI" appeared; turn 6 answered "Akceptuję."
without "nie wiem" for the keyword-less "Kim jest Ernest?". No fact was invented or
contradicted. The score is unchanged by these (turn 2 already carried all facts).

## Concerns

- The simulation volunteered facts nobody asked for (turn 2). If Task 5 runs the same
  simulation strictly by the rule, the skill session will be held to a tighter standard
  than the baseline was; for a fair comparison, apply the same simulation policy or
  accept that the baseline C4 pass is generous.
- The baseline ran with the user's global CLAUDE.md and the `polszczyzna` skill
  loaded (not skill-free apart from knowledge-transfer). Recorded in `baseline.md`.
- `baseline.md` is in English with Polish quotes; no Polish prose was written, so the
  `polszczyzna` skill was not needed for it.

Files: `.flow/specs/2026-10-08-knowledge-transfer-evidence/{scenario.md, baseline.md,
baseline-package.md, baseline-transcripts/turn-1..6.jsonl}` (committed in 1573f10).
