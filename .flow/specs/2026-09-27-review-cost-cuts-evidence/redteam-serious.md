I read the full plan (2,696 lines), the real `score.py`/`state.py`/`source.py`/`store.py`/`config.py`/`catalog/client.py`/`session/run.py`, and the real test files, and hand-traced each of the six items.

---

# Pre-mortem — round 6

## SERIOUS

### S1. The `round()` → `int()` switch was applied to the implementation snippet but **not to the Interfaces contract**, and no test can tell the two apart

`/home/m/projects/harmonia/.flow/plans/2026-09-13-discovery.md:832` (Task 6 **Interfaces**, the normative line an implementer reads first) still says:

> buduje finalną listę `cfg.shortlist`-elementową egzekwując: co najwyżej **`round(expand_share * cfg.shortlist)`** pozycji pochodzenia `source in DISCOVERY_SOURCES`

while line 1052 implements `max_discovery = int(expand_share * cfg.shortlist)` with a four-line comment explaining why `int()`. Line 887's test comment also still reads `# round(0.5*4)=2`.

Why it bites: the **only** test that asserts a discovery count is `test_shortlist_caps_discovery_share_after_scoring`, which uses `shortlist=4, expand_share=0.5` → `2.0`. `int` and `round` both give 2. I enumerated every plausible `(shortlist, expand_share)` pair — the two functions diverge in 49 of them (e.g. `shortlist=3, 0.5` → 1 vs 2; `shortlist=8, 0.2` → 1 vs 2) — but **no test and no call site in the plan sits on a divergent value**. So an implementer who follows the Interfaces line ships `round()`, the whole suite goes green, and the plan's own stated semantics ("monotonic at-most-X share") are silently violated. This is the same failure shape the last five rounds kept finding: prose and code disagreeing where the tests can't arbitrate.

Fix (three edits, all in the plan):
1. Line 832: `round(...)` → `int(...)`.
2. Line 887: fix the comment.
3. Make the test discriminate — change `cfg = SelectorConfig(shortlist=4)` to `shortlist=3`, keep `expand_share=0.5` and the 6+6 population, and assert `sum(1 for s in top if s.candidate.source == "lastfm") == 1  # int(1.5)=1, NIE round(1.5)=2`. (Traced: all 12 land in band 2 with identical scores, digit ids sort before `"B…"`, so capped = 1 discovery + 2 library. Fails for the right reason under `round()`.)

---

## MINOR

### M1. The round-5 `_lb_used_this_session` fix has no test at all
`test_lb_recommendations_consumed_once_then_absent` (plan:2012-2049) stubs `run_discovery` with a lambda that never raises, so it only exercises the happy path. Moving `self._lb_used_this_session = True` back above the `run_discovery(...)` call — the exact bug round 5 found — would still pass. Add a third scenario: stub that raises on call 1 and records on call 2, then assert call 2 still receives `(lb, ["mbid1", "mbid2"])`.

### M2. The justification comment for the `range(1, N)` id-collision fix is factually wrong
Plan:2233-2235 and 2377-2378 say starting at `i=0` means *"pool_upsert nadpisałby wiersz ZIARNA (source "saved"→"lastfm")"*. It would not. `pool_upsert`'s `ON CONFLICT` clause (`/home/m/projects/harmonia/src/harmonia/store.py:104-106`) updates `title, artists_json, album, release_year, popularity, duration_ms, explicit, added_at, synced_at` — **not `source`** — and `/home/m/projects/harmonia/tests/test_store.py:75-83` asserts exactly that (`got.source == "saved"` after an upsert with `"playlist:PL"`). The real harm of `i=0` is (a) 19 discovery rows instead of 20 and (b) `store.put` overwriting the seed's analysis (`emb(0.0)`+`MOOD_HI` → `emb(0.9)`+`mood={}`). The fix is right; only the reason is wrong — but a fresh implementer who verifies the claim and finds it false may revert to `range(20)`. Correct the comment.

### M3. Floor semantics silently yield a zero cap for plausible user configs
`expand_share: 0.1` with the default `selector.shortlist: 8` gives `int(0.8) == 0`; so do `0.05/8`, `0.2/4`, `0.125/4`. Discovery then fetches, maps, inserts and analyses rows that can never enter a shortlist, with nothing in the log saying why. `config.load()`'s `_range` accepts any `0 ≤ expand_share ≤ 1`. Worth one sentence in Task 13 §11 documenting the floor, or an explicit decision from Maciej on `max(1, …)`. (Note the plan already relies on the zero-cap case being reachable — it's the premise of the new relaxation test — so this is a documentation gap, not a contradiction.)

### M4. Task 10's `next()` snippet omits the lines Task 9 puts in the same gap
Plan:2097-2128 shows `cur = …` → dispatch `if` → `attempts = 0`, with no sign of the `suppressed`/`taste`/`w_taste` block Task 9 inserts at exactly that point. Task 9 flags the overlap (plan:1853); Task 10 does not. An implementer copying Task 10's block verbatim could drop Task 9's three lines. `test_next_passes_suppressed_ids_to_select` would catch it, so this is low-risk — one cross-reference line in Task 10 closes it.

### M5. `discovery_cfg` is wired unconditionally, including under `--no-discovery`
Task 11 (plan:2622-2626) passes `discovery_cfg=cfg.discovery` and `expand_share=cfg.pool.expand_share` regardless of the `discovery` flag; only the three clients go `None`. So a `--no-discovery` session still updates the taste centroid, marks `discovery_log` outcomes, queries suppression every `next()`, and caps pre-existing discovery rows. That's defensible (old rows still deserve suppression), but it isn't stated anywhere, and the new §13 criterion only covers "no new discovery-origin pool rows". One sentence in Task 11's Interfaces.

### M6. Cosmetic: `import time as time_mod` is unused in `test_taste_update_persists_and_decays` (plan:205). No lint gate in `pyproject.toml`, so harmless.

---

## What I verified and found genuinely correct

- **(a) `shortlist()` band relaxation.** Traced arithmetic matches the comments: discovery `emb(0.9)` vs `emb(0.0)` → `cos_dist ≈ 0.3784`, mood identical → drift `≈ 0.1892`, inside band 0 `(0.15, 0.45)`; library drift `0.0`, outside band 0, inside band 1. `max_discovery = int(0.0 × 1) = 0` empties band 0 → `continue` → band 1. In band 1 the library candidate also wins on score (2.583 vs 2.205, driven by the `genre` part), so `top[0].candidate.source == "saved"` is sound, and `level == 1` is the assertion that genuinely fails on the unfixed code (which returned `([], 0)`). No infinite loop (bounded `for`), and no behavioural change in any previously-returning band: with `expand_share=1.0`, `max_discovery == size`, and since `n_discovery ≤ len(result) < size` at the top of every iteration, `_cap_discovery_share` provably never skips — it is identical to `inside[: cfg.shortlist]`. All four pre-existing `shortlist` tests, including `_shortlist(cur, []) == ([], 2)`, still hold.
- **(b) `int()` vs `round()`.** No plan test or call site lands on a divergent value, and there are no floating-point truncation surprises (`0.3*10`, `0.7*10` etc. all land on or above the integer) — the only defect is the stale prose, S1 above.
- **(c) Strong-skip assertion.** Traced through Task 2's `taste_update`: empty table → `old_total = 0.0` → `total = -0.5` → `total > 0` is False → `vec = old_vec` (zeros) → row INSERTed → `taste_get()` returns zeros. The corrected assertion is right and consistent with `test_taste_update_negative_weight_first_does_not_invert_direction`. Critically, `seed_pool` gives `ids[0]` a **non-zero** embedding (`emb(0.0) = [1.0, 0.0, 0…]`, `/home/m/projects/harmonia/tests/test_selector_source.py:32-37`), so the `if emb.any()` guard does not short-circuit and both taste tests actually reach `taste_update` — this was the one way these two tests could have passed/failed vacuously. No other new test asserts a centroid outcome.
- **(d) `tests/test_selector_score.py:67`.** The real line is byte-identical to the plan's quote. Grepping the whole repo for `parts` usage: `source.py:154` iterates `.items()`, `session/run.py:114-119` indexes by name, `tests/test_llm_client.py:32` builds its own partial dict, and no test asserts the `shortlist` log record's key set. Line 67 is genuinely the only enumerating assertion.
- **(e) `_lb_used_this_session` retry.** On a first-run `run_discovery` exception, `self._lb_recommendations` stays cached (not cleared) and the flag stays `False`, so run 2 takes the `not self._lb_used_this_session` branch, sets `lb_for_run = self.listenbrainz` and passes the real cached list. The retry works and is not redundant — the cache being non-`None` only suppresses the *re-fetch*, not the *hand-off*. Verified against positional indices `a[3]`/`a[5]` used by the test.
- **(f) Id collisions.** Complete. Grepped every generator in the plan: the only `seed_pool(1)` + `f"{i:022d}"` pairs are the two already fixed (`range(1,21)`, `range(1,11)`); every other discovery-id generator uses `f"D{i}"*11` or `f"B{i}"*11`, which cannot collide with `"0"*22`, and the `f"{i:022d}"` uses in Task 6 and in `test_discovery_log_recent_*` have no seed row at all.
- Also spot-verified and clean: Task 8's twelve `run_discovery` tests (query strings, `assert_called_once_with` limits, dedup/`seen_ids`/`existing is not None` ordering); Task 4's throttle test (`_last_call = 0.0` vs a large `time.monotonic()` → first call never sleeps); httpx `base_url` + `get("")` path merging for both new clients; `pool_pending`'s new `ORDER BY` against `tests/test_store.py:86-100` (all-`"saved"` fixtures → expression is 0 for every row → existing order preserved); `_FakeClient.messages.parse_kwargs` for Task 7's tags test; `test_three_fetch_failures_raise_instead_of_burning_the_pool` under the `total_attempts` split (all `seed_pool` rows are `"saved"`, so `attempts` still fires at 3); `_cfg()`/`replace()` in `test_session_run.py` against the three new `Config` fields; and no import cycle from `selector.source → discovery.discover`.

---

## Simpler alternative worth one line

Not for the plan as a whole — the post-scoring cap is the right shape and the code is now small. But **S1's root cause has a structural fix**: `max_discovery` is computed inline in `shortlist()`, so nothing can unit-test the formula independently of a full scoring run. Extracting it to a two-line module function (`def _discovery_cap(expand_share, size) -> int: return int(expand_share * size)`) and testing it directly on a divergent pair makes the `int` vs `round` contract testable in one assertion instead of needing a carefully-tuned 12-candidate population. Optional; the S1 test change alone is sufficient.
