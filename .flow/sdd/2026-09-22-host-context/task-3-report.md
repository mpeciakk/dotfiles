# Task 3: Tell the reader there are two machines

## Summary

This task was a prose-only documentation update, no code changes. Inserted text describing the two-machine setup into `.claude/CLAUDE.md` and `README.md` as specified in the brief.

## What was implemented

**Step 1: Added section to `.claude/CLAUDE.md`**
- Inserted the "Dwie maszyny" block between the cross-session paragraph (line 42: "w repo, zgłosisz następnym razem.") and the "Dyscyplina kodu" section
- The new block is positioned at line 44-60
- Block covers:
  - Two machines: `pc` (desktop) and `laptop` (MacBook Air M2, Asahi)
  - Both report hostname `ciek`
  - Machine identity comes from `prompt-context` hook output
  - Synced directories and git history considerations
  - Unmarked turns don't imply machine identity
  - Importance of naming machines by label (`pc` or `laptop`)

**Step 2: Added paragraph to `README.md`**
- Inserted text in the "## Per-host hardware" section
- Positioned after the third bullet about `hosts/pc/herdr-mirror-hosts.toml` (line 106)
- Positioned before "To add a machine:" (line 108)
- Explains that `.dotter/local.toml` is read by `prompt-context` hook
- Notes that both hosts report hostname `ciek`
- Documents that missing file reports `[CTX] unknown (…)`

## Testing

**Step 3: Hook test suite**
Ran `./.claude/hooks/prompt-context-test` — all 18 tests passed:
```
18 passed, 0 failed
```

**Step 4: Grep verification**
First grep command: `grep -c 'prompt-context' .claude/CLAUDE.md README.md`
```
README.md:1
.claude/CLAUDE.md:1
```

Second grep command: `grep -n 'Dwie maszyny' .claude/CLAUDE.md`
```
44:Dwie maszyny — `pc` (desktop) i `laptop` (MacBook Air M2, Asahi):
```

The "Dwie maszyny" line is positioned before "Dyscyplina kodu" (which starts at line 61), exactly as required.

## TDD Evidence

Not applicable — this task is prose only and explicitly notes "No test for this task".

## Files Changed

- `.claude/CLAUDE.md` — Added 17-line documentation block about two-machine setup
- `README.md` — Added 4-line paragraph explaining `prompt-context` hook's role in machine identification

## Commit

```
d5e9437 docs: record that this configuration runs on two machines
```

## Self-Review

✓ Text inserted exactly as specified in the brief, verbatim
✓ Correct positioning in both files (between specified lines)
✓ No unintended edits to either file
✓ Hook test suite still passes (18/18)
✓ Grep verification confirms:
  - `prompt-context` appears once in each file
  - `Dwie maszyny` appears on line 44
  - Positioning is correct relative to `Dyscyplina kodu`
✓ Commit message follows the required format
✓ Both files have been committed successfully

## Concerns

None. All steps completed successfully.
