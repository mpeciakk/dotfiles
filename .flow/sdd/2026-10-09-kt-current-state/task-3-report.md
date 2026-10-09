# Task 3 report: D32 GREEN on the colleague scenario

Status: DONE_WITH_CONCERNS. Commit `5e492df test: knowledge-transfer D32 GREEN on the colleague scenario`.
Full evidence: `.flow/specs/2026-10-08-knowledge-transfer-evidence/d32.md` (committed). This file is the summary.

## What happened
- RED (committed `team-package.md`): `check-d32.sh` 1/4 (FAIL D1, D2, D3). Real-world edge-vibecoding package: 0/4 (FAIL D1, D2, D3, D4 on line 276 `Na pc jest herdr 0.9.3`). Read-only, nothing touched in that repo.
- Sanity turn: auth OK, `Base directory for this skill: /tmp/kt-d32.WKgR0m/fx/.claude/skills/knowledge-transfer`.
- GREEN run 1 (SKILL `cfd6029`): check-package 6/6, check-d32 4/4, gate before first Write OK, 0 forbidden questions (3 turns). But by reading it FAILED:
  1. section 2 gives the spec's flow as present-tense steps ("Proces zapisuje zlecenie w tabeli `outbox`") with only `wg speca`; the skeleton statement is in section 3, not section 2;
  2. section 6 has untraceable conditions: "Gdy worker znów się zatrzyma, nie powtarzaj startu w pętli. Zajrzyj w logi i zgłoś awarię.", "zapisz nowy w 1Password", "Stosuj, gdy masz dostęp do panelu", "Zgłoś problem, gdy zlecenia przepadają po 429";
  3. (observation) the session patched the package 7 times after the cold read and skipped the re-dispatch: "nie puszczałem cold readu drugi raz".
- Refactor 1 (SKILL.md, 19 lines changed): section-2 counter (say next to the flow that code does not implement it, point to Luki), section-6 counter (conditions trace to repo/user/Luki, else listed unknown), three Common-mistakes rows, "four runs" sentence.
- r1 (fresh fixture, new SKILL): check-package 6/6, check-d32 4/4, base dir OK, gate OK, 0 forbidden (borderline note), section 2 passes ("Kod tego nie robi ... patrz sekcja 9"), section 6 every condition traced, no post-cold-read patch (cold read 8/8). GREEN holds.

## TDD evidence
RED command: `bash EV/check-d32.sh EV/team-package.md` -> `1/4 PASS`, exit 1, FAIL D1/D2/D3 (verbatim in d32.md). GREEN: same checker on `d32-package-r1.md` -> `4/4 PASS`, exit 0; `check-package.sh` 6/6 (verbatim in d32.md). Run 1 is the second RED of the loop (checkers green, reading red).

## Files
Created: `EV/d32.md`, `EV/d32-package.md`, `EV/d32-package-r1.md`, `EV/d32-transcripts/turn-1..3.jsonl`, `EV/d32-transcripts-r1/turn-1..3.jsonl`. Modified: `.claude/skills/knowledge-transfer/SKILL.md`.

## Concerns
1. Borderline classification: the interview question "is the real implementation elsewhere / is the repo a skeleton" (run 1 Q1, r1 b). I labelled it allowed (as RED Q4 in `team.md`). SKILL.md's run-history bullet says "A spec-code contradiction goes to Luki without a question"; read broadly it is forbidden and would fail GREEN on both runs. Reviewer's call; SKILL.md not changed for it.
2. Run-1 answer-log errors by me, disclosed in d32.md: Q1 got F1 although only F4 matches; Q3 missed F1 and F7. No effect on package facts visible, but the log is not exact. r1 matching was done word by word (incl. "uruchamia" -> F9 by lemma).
3. The refactor round was driven by my reading of the brief's section-2 three-part test; a reviewer who reads `wg speca` as sufficient would call run 1 GREEN and the refactor unneeded (the counters are general and harmless).
4. r1 soft spots (not failing): Luki says "Nie ma zastępcy dla Ernesta" as fact (user only left it unanswered); section 3 "w journalctl są tylko wpisy systemd" is an inference; scenarios say "Kolega ..." in third person.
5. The "How it works on real code" and machine-agnostic cases are not exercised by the fixture (left to the after-merge edge-vibecoding run, noted in d32.md).
6. Nested sessions with the throwaway config dir printed "Claude configuration file not found ... .claude.json" and wrote a backup via the `backups` symlink into `~/.claude/backups`; credentials stayed a symlink (checked before cleanup). Cleanup done (fixtures, config dir, sanity transcripts removed).


---

# Fix round 1 (reviewer finding: fixture facts in SKILL.md; r1 GREEN possibly leaked)

Status: DONE (r2 GREEN). Full evidence: `.flow/specs/2026-10-08-knowledge-transfer-evidence/d32.md`, section "Refactor round 2".

## Finding and fix
- `SKILL.md` Common-mistakes rows added by refactor 1 quoted the kolejka-sms fixture run („Proces zapisuje zlecenie w tabeli `outbox`”, „Gdy worker znów się zatrzyma …”, „zapisz nowy w 1Password”, the cold-read patch quote), and the intro listed the fixture run as a fourth source.
- Changed (commit `be751f8`): the three rows are generic descriptions with the same counters (no fixture strings, files, tables or Polish quotes); the intro is back to three runs (baseline, first and second real KT run). The section-2 and section-6 bullets contain no fixture facts and are untouched.
- Task 2 check (`bash /tmp/kt-task2-check.sh`): `fails=0`; `wc -l` = 214 (< 230). `grep -nE 'outbox|1Password|kolejka|worker|SMSAPI'` on SKILL.md still hits lines 54, 143, 180, 200 (older text: the interview example, the SMSAPI example in the token rule, the vault bullet, and the baseline "Restated the spec" row). Not touched: not on the list, see Concerns.
- `bash EV/check-d32.sh EV/d32-package-r1.md` -> 4/4 PASS.

## r2 (fresh fixture `/tmp/kt-d32.c84fIq/fx`, tip `1519789`, skill text `be751f8`, session `fb6d66c6-4b4f-4b1f-a350-06b122a6e379`, 3 turns)
- `bash EV/check-package.sh EV/d32-package-r2.md <fixture> EV/d32-transcripts-r2` -> 6/6 PASS, exit 0.
- `bash EV/check-d32.sh EV/d32-package-r2.md` -> 4/4 PASS, exit 0.
- Base directory line: `Base directory for this skill: /tmp/kt-d32.c84fIq/fx/.claude/skills/knowledge-transfer`.
- Gate: turn 1 tools `Skill`, `Bash`, `Read`; first `Write` in turn 2 after the answers. Cold read once (8/8), no edit after it.
- Forbidden questions: 0 (same borderline item as run 1 and r1: "is the real implementation elsewhere?", see Concerns).
- Section 2 passes: own-words flow, spec link, „**Kod tego przepływu nie realizuje.** … Szczegóły w [Lukach](#9-luki)”.
- Section 6 passes: no invented condition; one dangling pointer (row 1 says the stop condition is unknown and points to Luki, but no Luki item lists it).
- Agnostic / token: pass; no date anywhere but the commit pin; token = „wygasa co 90 dni” + panel. Soft spot: „według użytkownika” in section 2.
- Answers: strictly by `user-facts-team.md`, word-by-word (log in d32.md). `$C/.credentials.json` was a symlink (`-> /home/m/.claude/.credentials.json`) before cleanup. Fixture and config dir removed.

## Commits
- `be751f8` skills: knowledge-transfer — genericise the new Common-mistakes rows, drop fixture run from the source list
- (evidence commit, see the final reply)

## Concerns
1. Borderline question again: "is the real implementation in another repo or branch?" (r2 Q1). SKILL.md's run-history bullet says a spec-code contradiction goes to Luki without a question. Read broadly this is forbidden in all three runs; I labelled it allowed (as `team.md` RED Q4). Reviewer's call; the skill is not changed.
2. Dangling Luki pointer in r2 section 6 row 1 (no gap item for the worker manual-start stop condition): the skill's "write that it is unknown and list the gap" is followed in the first half only. Not a fabrication; recorded, not tuned.
3. SKILL.md lines 54, 143, 200 still contain SMS/worker/SMSAPI wording from older tasks (not from the fixture run's failures; line 200 quotes the baseline run). Not on the list, left as is.
4. On turn 3 I answered the deputy request with „nie wiem” by reading the request sentence only; the surrounding report prose would match F2, F3, F4 by keyword. Logged in d32.md.
5. Correction to concern 3: line 143 („token wygasa co 90 dni; datę wygaśnięcia pokazuje panel SMSAPI”) is Task 2's rule example for the D1 date rule and happens to coincide with the fixture's F2 fact (90-day token, SMSAPI panel). It is in the plan's Task 2 text, not added by the refactor; I left it. The reviewer may want to judge whether r2's D1 pass (no date, token as a rule) is independent of that example.
