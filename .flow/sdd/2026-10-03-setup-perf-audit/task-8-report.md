# Task 8 Report: `bin/claude-baseline` — the before/after measurement

## What was implemented

Extended `bin/claude-baseline` docstring with analysis rules documenting:
- Output token under-reporting in transcripts for subagents since v2.1.280 (~3× under-reported)
- Requirement to use `~/.claude.json` `lastModelUsage` / cost state for accurate output measurements
- Timestamp-based windowing (never file mtime)
- Machine detection from [CTX] line, fallback to version
- Account separation when multiple appear
- Added comment above LAP/PC version sets noting they require updates when machines upgrade

## Test results (TDD evidence)

### RED — failing test before implementation
```bash
$ grep -q 'lastModelUsage' bin/claude-baseline
$ echo "Exit code: $?"
Exit code: 1
```
✓ Correctly failed (string not present in file)

### GREEN — implementation passes
```bash
$ grep -q 'lastModelUsage' bin/claude-baseline
$ echo "Exit code: $?"
Exit code: 0
```
✓ Correctly passed (string now in file)

### Verification — script execution
```bash
$ python3 bin/claude-baseline 2026-09-27 2026-10-03
Okno 2026-09-27..2026-10-03
Pierwsze żądanie (tokeny): rodzaj/maszyna  n  p10  mediana  p90
  main  laptop     49   39738    49016   60962
  main  pc         33   43299    51350   75462
  sub   laptop    240   12102    35617   39930
  sub   pc        167   34005    40583   47021
  wf    laptop    198   42643    52761   53766
  wf    pc          2   42945    47722   52500
Tokeny wejścia: 2039M; cache read 96.9%; list $ (bez korekty F7): 746
Kompakcje: 23; preTokens: [166920, 167439, 167467] ... [483640, 541764, 623480]
```
✓ Script executes successfully
✓ Output matches expected format and values (laptop main ~49K, pc main ~51K as noted in brief)
✓ Exit code 0

## Files changed

- `bin/claude-baseline` — extended docstring with analysis rules (5 insertions, 1 deletion)

## Commits

```
ca41e99 bin: claude-baseline analysis rules (D28)
```

## Self-review findings

✓ Docstring extends existing Polish style with complete analysis rules
✓ All required elements included: `lastModelUsage`, timestamp windowing, account separation, machine detection
✓ Comment added above LAP/PC version sets with update note
✓ Script remains functional with no behavioral changes
✓ No references to session content or `~/.claude.json` values (only key names)
✓ Formatted for readability and clarity in Polish

## Concerns

None. Task complete, all steps passed, script functional.
