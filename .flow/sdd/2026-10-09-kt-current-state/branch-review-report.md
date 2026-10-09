# Branch-review minors — fix report

Worktree /home/m/dotfiles/.claude/worktrees/feat+kt-current-state, branch worktree-feat+kt-current-state (base HEAD ccd7468).
Findings 1, 2, 4, 5 fixed. Finding 3 (scope of "without a question") deliberately untouched, per dispatch.
All four are text/comment changes with no behaviour; the existing Task 2 check and the harness tests are the safety net.

## 1. SKILL.md source line (Common mistakes)
"The rows come from three runs" -> "The quoted rows come from three runs", plus a sentence: "The unquoted generic rows describe
failures seen in the D32 fixture runs (`.flow/specs/2026-10-08-knowledge-transfer-evidence/d32.md`)." No quotes or fixture
strings added; no other row touched. File is 215 lines (< 230).

## 2. d32.md independence note
Added item 4 under "What this fixture does not exercise": the r2 "90-day token as a rule" check ran with the example in the skill
text (plan line 268, almost word for word the F2 answer) so it is not independent, the after-merge edge-vibecoding run is; and the
baseline-quote rows quote the baseline run on the same kolejka-sms fixture, so r2 D1/D2 are not fully independent either.
SKILL.md not changed for this.

## 4. SKILL.md lines 69-70
"When" -> "when" after `**Run history:**`. Re-wrap: the phrase `how it was run in the past` must stay on one line (grep -F in the
Task 2 check), and it cannot fit on line 69 (would exceed 80 columns), so the existing break before it is the only valid wrap;
line 70 onward was already filled to the margin. The visible change is the lowercase.

## 5. make-config-dir.sh
Three header comment lines: isolates reads only, not writes; every top-level entry is a symlink, so nested sessions write
`projects/` transcripts and `backups/` into the real `~/.claude`. No code change.

## Verification (run from the worktree root, one command each)
- `bash /tmp/kt-task2-check.sh` -> `fails=0`
- `bash .flow/specs/2026-10-08-knowledge-transfer-evidence/check-d32.sh <pkg>` on d32-package.md, d32-package-r1.md, d32-package-r2.md -> `4/4 PASS` each (D1 daty, D2 sekcje, D3 luki, D4 setup)
- check-d32-test.sh -> `15 passed, 0 failed`
- make-config-dir-test.sh -> `7 passed, 0 failed`
- check-package-test.sh -> `8 passed, 0 failed`
- stream-test.sh -> `6 passed, 0 failed`
- questions-test.sh -> `5 passed, 0 failed`

No other test suite exists for this branch (skill text and evidence files only).
