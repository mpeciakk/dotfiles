# Task 13 report: calculator + fuzzy match with highlight ranges

Commit: 8bea559 `quickshell: calculator and fuzzy matcher` (branch worktree-feat+wyspa-shell)

## Implemented
- `lib/calc.js`: `evaluate(expr) -> number|null`, `format(n) -> string`. Hand-written recursive descent (no eval/Function); every failure is an internal `throw` caught in `evaluate` -> null.
  - Grammar: sum (+ -) > prod (* / %) > unary (-) > power (`^` right-assoc, exponent is a `unary`, so `2^-1` = 0.5, `-2^2` = -4) > atom (number | const | func(...) | (...)).
  - Names resolved only via `Object.prototype.hasOwnProperty.call` on FUNCS/CONSTS, so `constructor`, `toString`, `__proto__`, `valueOf(1)` -> null. Identifiers are case-insensitive (`SQRT(4)`, `Pi`).
  - Decisions pinned in tests: `1e5` -> null (no exponent syntax; `e5` is an unknown identifier); `2pi`, `2 3`, `pi(2)`, `+3`, `1,,5`, `.`, `2,`, `1.` forms -> null; any non-finite intermediate (`1/0`, `7%0`, `sqrt(-1)`, `ln(0)`, `9^999`, `1/(1/0)`) -> null; nesting depth capped at 64 (parens, unary minus, `^`, function call) so 10000-deep input returns null deterministically instead of relying on stack overflow. A comma is always a decimal separator (`sqrt(2,25)` = 1,5), no argument lists.
  - `format`: `String(Number(n.toPrecision(10)))`, `e+` -> `e`, `.` -> `,`. Pinned: `-0` -> "0", `12345678901` -> "12345678900", `1e21` -> "1e21", `1.5e-7` -> "1,5e-7", `0.000001` -> "0,000001", `sin(pi)` -> "1,224646799e-16".
- `lib/fuzzy.js`: `match(query, text) -> {score, ranges} | null`. Tiers prefix 5000 > word start 4000 > contiguous substring 3000 > (2000 free for callers) > subsequence 1000, each minus a penalty capped at 999 (shorter/earlier/tighter wins). Contiguous occurrence is preferred over scattered letters for the highlight (`ab` in `a_xab` -> [[3,5]]); the word-start occurrence is preferred over an earlier mid-word one (`fi` in `Wifi Files` -> [[5,7]]). Subsequence is greedy-leftmost, ranges merged.
  - Unicode: `lower()` lowercases one UTF-16 unit at a time keeping only the first unit of the result, so indices always align with the original text (`İ`, `ß`, `ł` tested). No diacritic folding: `match("zol","Żółw")` -> null (pinned).
  - Word-start separators: space, tab and `-_./:,;()[]&+` (no regex/`\p` used, to stay V4-safe).
  - The "substring" tier is an addition between the brief's word-start and subsequence tiers (order prefix > word start > subsequence holds).
- `services/Apps.qml`: imports `../lib/fuzzy.js as F`; `query(search)` returns `[{entry, ranges}]` (ranges of `entry.name`; `[]` for empty query and keyword/comment hits). Name scored by `F.match`; hits only in genericName/comment/keywords get `extraScore: 2000` (between substring and subsequence, same relative order as the old 100 vs 40). The old `score()` and `subsequence()` helpers were orphaned by this and removed. `grep` shows nothing else in the tree calls `Apps.query`.

## TDD evidence
RED (stubs returning `undefined`, tests written first):
`node --test tests/calc.test.mjs tests/fuzzy.test.mjs` -> `ℹ tests 23 / pass 1 / fail 22` (the 1 pass is the "never reaches for eval" source-grep test against the stub). Failures were assertion failures, e.g. `actual: undefined, expected: 14`, `expected: '3'`, and `TypeError: Cannot read properties of undefined (reading 'score')` for fuzzy: expected, the stubs return nothing.
First GREEN attempt on calc caught three of my own test/regex mistakes (fixed, code not weakened to fit): `2,`/`1.` were accepted as numbers (regex tightened to require digits after the separator), `SQRT(4)+Pi` expectation was mis-computed (2+pi), and `sin(1,2)` is by the comma-decimal rule sin(1.2), moved out of "malformed" into an explicit test.
GREEN: `node --test tests/` -> `ℹ tests 63 / pass 63 / fail 0`, output clean (13 calc + 11 fuzzy + existing).

## Smoke
- `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/00-start.sh` -> exit 0, no warnings; `04-state.sh` -> exit 0, 17 ok, 0 FAIL. `qs list --all` after each: "No running instances."
- Temporary check (throwaway Timer in shell.qml, reverted before commit; `git status` showed no shell.qml change) after `Apps.list` was touched at startup and queried at 3 s, 42 desktop entries on `pc`:
  - `""` n=42 ranges []; `"fire"` n=2: File Roller [[0,2],[5,6],[9,10]], The Binding of Isaac: Rebirth ...; `"term"` n=2: kitty (keyword hit, ranges []) first, then a scattered subsequence on "The Witcher 3..." (confirms extras rank above subsequence); `"ffx"` n=1 Microsoft Teams for Linux [[7,8],[16,17],[24,25]]; `"browser"` n=4: Helium Browser [[7,14]] first; `"zzzzqq"` n=0; `"  Fi "` (trimmed) n=8: Files [[0,2]] first.
- calc.js/fuzzy.js were also executed in Quickshell's V4 engine via a throwaway config in /tmp (sticky regex, `repeat`, etc.): `2+3*4`=14, `1,5*2`=3, `sqrt(16)`=4, `constructor`=null, 10000-deep parens=null, `format(1/3)`="0,3333333333", `format(1e21)`="1e21", `1e5`=null; fuzzy ranges and the `İstanbul` index test identical to node. No instance left (`qs list --all` empty); /tmp files only.

## Files changed
`lib/calc.js`, `lib/fuzzy.js`, `tests/calc.test.mjs`, `tests/fuzzy.test.mjs` (new); `services/Apps.qml` (modified). All under `config/quickshell/`.

## Concerns
1. Apps is a lazy singleton and `DesktopEntries` loads asynchronously: the first access at 3 s returned 0 entries until `Apps.list` had been touched earlier at startup. Task 15 (launcher state) should reference `Apps.list` at startup (like `IslandState.current`/`Niri.focusedId` in shell.qml) or the first open of the launcher may show an empty list. Not changed here (out of scope).
2. Long names match short queries as a scattered subsequence (e.g. "term" matches "The Witcher 3: Wild Hunt — Remastered"), which is inherent to the brief's subsequence tier; it ranks last among name matches and below keyword hits.
3. `Apps.query` still keeps the old behaviour of exact-substring-only matching on genericName/comment/keywords (case-insensitive `includes`), without highlight ranges.

---

## Fix round 1 (review of Task 13)

### IMPORTANT 1 - extras skipped when the name subsequence-matches
- Change: new pure `rank(query, name, extras) -> {score, ranges} | null` in `lib/fuzzy.js` (new constant `EXTRA = 2000`). Name match with score > EXTRA (substring or better) is returned unchanged; otherwise, if `extras.join(" ").toLowerCase()` contains the query, result is `{score: EXTRA, ranges: <name subsequence ranges or []>}`; else the name match. Empty query returns `match()` unchanged. `services/Apps.qml` now calls `F.rank(q, name, [genericName, comment, keywords.join(" ")])`; the `extraScore` property and the `continue` branch are gone.
- Tests (`tests/fuzzy.test.mjs`, 5 new `rank()` tests): full tier order exact > prefix > word start > substring > extras > subsequence; "The Witcher 3: Wild Hunt - Remastered" (name subsequence-matches "term") with keyword "terminal" scores 2000 and keeps its name ranges, above the same name without the keyword; extras-only hit -> `{2000, []}`, case-insensitive, no hit -> null; name prefix not changed by extras; empty query -> `{0, []}`.
- RED: `node --test tests/fuzzy.test.mjs tests/calc.test.mjs` -> `tests 30 / pass 24 / fail 6` (5 x `TypeError: F.rank is not a function` + the calc test below). One of my fixtures was wrong on first GREEN (the shortened name "The Witcher 3: Wild Hunt" has no "m", so it did not subsequence-match "term"; the test's own precondition assertion caught it); fixed the fixture to "...Wild Hunt - Remastered", not the code.
- Live (throwaway Timer in shell.qml touching `Apps.list` at startup, query at 3 s, removed afterwards; `git status` shows no shell.qml change), 42 desktop entries on `pc`:
  - `"this"` n=6, all six are in the 2000 tier (alphabetical): Big Walk, Factorio, No Man's Sky, The Binding of Isaac: Rebirth `[[0,2],[5,6],[16,17]]`, The Witcher 3 ... `[[0,2],[5,6],[31,32]]`, Warframe. Isaac and Witcher subsequence-match by name (old name-only score 983 / 968, i.e. they were in the 1000 tier and `continue`d past the extras check); now they take the extras tier with their name ranges kept.
  - `"term"` n=2: kitty (comment hit, `[]`) first, Witcher (name subsequence only, 970, its comment has no "term") second - unchanged.
  - `"ste"` n=15: Steam `[[0,3]]` (4995) first, Witcher `[[31,34]]` (substring, 2932) second, then extras hits.
  - The live data has no entry that matches "term" both ways, so the "term" case from the finding is pinned by the node test; "this" is the live evidence of the same mechanism.

### MINOR 1 - numeric literal overflow -> Infinity
- Change: `lib/calc.js` `tokenize`: a number token whose `parseFloat` is not finite makes the tokenizer return null (-> `evaluate` null). All literal positions go through tokenize, so `big`, `-big`, `(big)`, `2^-big`, `1/big` are covered; no change to `sum()`/`evaluate()`.
- Test: "numeric literals that overflow to Infinity are null, not Infinity" (`1`+400 zeros in 6 shapes), RED before the fix (see counts above), green after.

### Verification
- `node --test 'tests/*.test.mjs'` -> `tests 69 / pass 69 / fail 0`, output clean.
- `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/00-start.sh` -> exit 0; `04-state.sh` -> exit 0, all ok, no FAIL. `qs list --all` after each (and after both live runs): "No running instances."
- Not touched: the other Minor items, per instruction.
