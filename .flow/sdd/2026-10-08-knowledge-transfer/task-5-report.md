# Task 5 report

Status: DONE_WITH_CONCERNS. Commits: `1480ee1` fix: stream reader survives events whose message is a string;
`3856ad3` skills: knowledge-transfer — recipient-specific handover packages verified by a cold read (D29).

## Implemented
- `.claude/skills/knowledge-transfer/SKILL.md` (133 lines): frontmatter and matrix verbatim from the brief, sections
  in the brief's order (Boundary, Intake, Process, Section matrix, Cold read, Hard rules, Common mistakes). Common
  mistakes has 6 rows, all quoted from `EV/baseline.md` (no interview before Write, work handed back to the user,
  unsupported claims, spec restated, no pinned state, self-verification by grep of its own file). No rows from the
  "skipping verification"/"secret handling" groups beyond what the baseline showed.
- Evidence in `EV/` (= `.flow/specs/2026-10-08-knowledge-transfer-evidence`): `green.md`, `green-package.md`,
  `green-package-r1.md`, `green-transcripts/`, `green-transcripts-r1/`.

## TDD evidence
- RED for the skill = the baseline at `1573f10` (4/6; C5 snapshot missing, C3 by construction). Not re-run.
- GREEN: `bash EV/check-package.sh EV/green-package.md /tmp/kt-green.RnL0vc/fx EV/green-transcripts` -> 6/6 PASS.
  Refactor 1: `... green-package-r1.md /tmp/kt-green.2ZG3tx/fx EV/green-transcripts-r1` -> 6/6 PASS.
- Harness bug (RED/GREEN for `stream.py`): on the first real nested transcript `stream.py agent-results` crashed with
  `AttributeError: 'str' object has no attribute 'get'` (`system/permission_denied` has `"message"` as a string).
  RED: added to `stream-test.sh` a real-shaped line, `bash EV/stream-test.sh` -> `FAIL string-valued message event
  does not crash the reader`, `6 passed, 1 failed`. GREEN: `blocks()` checks `isinstance(message, dict)`;
  `6 passed, 0 failed`.

## Observations
- Both runs: stopped at the inventory gate before any Write; interview questions mostly carried "Zakładam, że ..."
  hypotheses; cold-reader dispatched foreground, haiku, from the nested session; commit = package file only; token
  value in no transcript or package; spec untouched; spec-vs-repo stub contradiction reported in "Luki".
- Skipped gate in the GREEN run: after patching section 6 the session did not re-run the cold read ("tej poprawki
  nie sprawdziłem ponownie ... pełny powtórny przebieg kosztowałby tyle samo czasu"; it had tried the disallowed
  SendMessage). Counter added in "Cold read" (a re-run is a fresh dispatch; an unchecked patch is not a patch).
  Refactor 1 (fresh fixture): re-ran twice, 6/6. Refactor budget used 1 of 2.
- User simulation strict per `user-facts.md`; F5/F6/F7 not volunteered in GREEN. `green.md` says the C4
  comparison with the baseline is not apples to apples.
- DENIED lines: only `Bash` (compound for-loops, a `sed -i`); no Skill/Agent/Write/Edit.

## Files changed
`.claude/skills/knowledge-transfer/SKILL.md`; EV: `green.md`, `green-package.md`, `green-package-r1.md`,
`green-transcripts/`, `green-transcripts-r1/`, `stream.py`, `stream-test.sh`.

## Concerns
1. The refactor-1 pass is one run on one fixture; whether the re-run counter holds elsewhere is untested.
2. Ambiguity in `user-facts.md`: matching keywords per question vs. per message and inflections ("kontaktuje",
   "haseł", "kopia" meaning a token copy) leaves room; borderline reads are listed in `green.md`.
3. In both runs the session asked for a deputy for Ernest (the user is "Ernest"/unreachable); fixture-specific, not a
   skill issue.
4. The fix to `stream.py` is outside the brief's file list (Task 1/3 artifact); it was needed to score C3.
5. SKILL.md "re-run" counter was added to the Cold read section, not to the Common mistakes table, because the
   brief restricts that table to baseline failures.
