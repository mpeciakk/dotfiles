# Branch review fixes (one round)

Worktree `/home/m/dotfiles/.claude/worktrees/feat+kt-company-scope`, branch `worktree-feat+kt-company-scope`.
All changes are text (skill rules and evidence notes), no behaviour code; the safety net is `/tmp/kt2-check.sh` plus the
three evidence test scripts. No RED/GREEN agent run was repeated, as instructed.

## IMPORTANT 1, SKILL.md Cold read (pass rule)
Changed the fail rule: "... or the answer contradicts the key — except a scenario whose key says the package does not know:
it passes on `NIE WIEM Z PAKIETU` and still fails on `ZGADUJĘ` or a confident answer."

## IMPORTANT 2, SKILL.md accounts boundary
Never-ask list: "accounts" -> "the company's accounts". Still-asked bullet: "the project's own external dependencies
(who owns the account at one is allowed)". Other words unchanged (only re-wrapped lines).

## MINOR
- SKILL.md step 3: "what the recipient needs" -> "what the reader needs". `kt-cold-reader.md` untouched.
- `team-green-void-package.md`: one-line VOIDED banner at the top pointing to `team.md` "Harness deviation". Transcripts untouched.
- `user-facts-team.md` F8: `1Password` removed from the keyword list.
- `stream-format.md`: new section "Which skill or agent loads in a nested run" (personal-level copy wins; throwaway
  `CLAUDE_CONFIG_DIR`; proof = `Base directory for this skill:` line).
- `team.md`: evidence note after "No refactor round", listing the three SKILL.md edits; cold-read pass rule and accounts
  boundary labelled rule-scope clarifications, "reader" word labelled wording-only; states no GREEN run covers them.

## Verification (cwd = worktree)
```
$ bash /tmp/kt2-check.sh
fails=0
$ bash .flow/specs/2026-10-08-knowledge-transfer-evidence/questions-test.sh | tail -1
5 passed, 0 failed
$ bash .flow/specs/2026-10-08-knowledge-transfer-evidence/stream-test.sh | tail -1
6 passed, 0 failed
$ bash .flow/specs/2026-10-08-knowledge-transfer-evidence/check-package-test.sh | tail -1
8 passed, 0 failed
```
Not fixed / declined: none. Concerns: none.
