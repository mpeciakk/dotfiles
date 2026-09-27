# Evidence fixtures — review-cost-cuts (2026-09-27, pc)

Extracted from subagent transcripts in `~/.claude/projects/` (final reports),
used by the plan's `## Verification` replays. Verdict lines were stripped so a
replay cannot copy them.

- `review-a.md` — harmonia, "Review Task 10 diff": only Important = no RED transcript for passing tests. Expected under D2: Minor.
- `review-b.md` — forensic-watermarking, "Review Task 8 attack.sh": RED claimed, not shown. Expected: Minor.
- `review-c.md` — harmonia, "Review Task 2: guard octave_ratio": RED taken on the baseline where the test already passed. Expected: Important.
- `redteam-serious.md` — harmonia discovery plan, round 6: one SERIOUS plus minors. Expected: PROCEED WITH CHANGES.
- `redteam-minor-only.md` — the same report with BLOCKING/SERIOUS emptied (no real minor-only report exists in history). Expected: PROCEED plus the M-list.
- harmonia spec for the dry split: `git -C ~/projects/harmonia show 056c1d3:spec.md` (302 339 B).
