# Branch-review fixes (fixbase 80481ab)

Workspace verified: toplevel /home/m/dotfiles/.claude/worktrees/feat-knowledge-transfer, branch worktree-feat-knowledge-transfer.

## IMPORTANT 1: tip commit trailer
`git commit --amend` with a message only. Tree before and after: f4314f809cd39542bfc71d4c024cf31cb82de861 (unchanged). SHA 80481ab -> 5df4ccc.
`git log -1 --format=%s` -> `docs: knowledge-transfer in README; D30 probe result in the design record`
`git log -1 --format='%(trailers)'` -> `Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>`

## IMPORTANT 2: design record line 35
Replaced with the reviewer's text. Checked against EV/probe.md GREEN: `subagent tools: (none)`, read result `NIE WIEM Z PAKIETU`, so "calls no tool, reads no file" matches the probe.

## MINOR 1, 2, 5: SKILL.md (133 -> 137 lines)
Hypothesis rule softened (ban on bare "anything else?" kept); one `temat` line after the matrix notes; `.env.example` clause. `diff` of lines 1-5 (frontmatter) and of the section matrix against the pre-edit file: identical (fm-same, matrix-same).

## MINOR 1 (green.md), MINOR 3
Interview count corrected: GREEN Q2-Q4 have "Zakładam", Q1 does not (it states a fact and asks); r1 Q1-Q3 yes, Q4-Q5 no. Honest note on the first GREEN package repeating Common-mistakes row 4 added. Evidence note added: runs used the pre-fix SKILL.md; post-fix edits are wording-only (hypothesis rule, temat line, .env.example clause).

## Tests
`bash EV/check-package-test.sh` -> `8 passed, 0 failed`
`bash EV/stream-test.sh` -> `6 passed, 0 failed`

## Commit
572fcbf docs: branch-review fixes — design record pointer, skill wording, green.md notes
`git diff --stat HEAD~1`: SKILL.md 10 (+7/-3), design.md 2 (+1/-1), green.md 18 (+15/-3); 3 files, 23 insertions, 7 deletions.

---

# Re-review fixes

## MINOR 1: green.md evidence note — post-fix edits are rule-scope clarifications

**Finding:** Lines 12-16 said post-fix SKILL.md edits are "wording-only". This was inaccurate for two edits:
(a) the interview hypothesis rule relaxed its scope — before, every question had to carry a hypothesis; now only where the repo or materials suggest one; (b) the `.env.example` clause is a new permission for a file type previously banned.

**Fix:** Replaced "wording-only" with "rule-scope clarifications (a softened hypothesis rule, a new `.env.example` permission); no gate, matrix or output-format change". Clarified that neither the softened rule nor the `.env.example` permission has a GREEN run behind it, so the note does not imply evidence covers the final text. The one-line `temat` rule remains wording-only.

**Test:** 
```
bash .flow/specs/2026-10-08-knowledge-transfer-evidence/check-package-test.sh | tail -1
8 passed, 0 failed

bash .flow/specs/2026-10-08-knowledge-transfer-evidence/stream-test.sh | tail -1
6 passed, 0 failed
```

## Commit
d39699f docs: green.md — post-fix edits are rule-scope clarifications, not wording-only
`git diff --stat HEAD~1`: green.md 5 (+5/-5); 1 file, 5 insertions, 5 deletions.
