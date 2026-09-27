# Pre-mortem

## BLOCKING

None.

## SERIOUS

None.

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
