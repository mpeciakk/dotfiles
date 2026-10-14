# Error analysis of the Claude setup (2026-10-15)

Step 1 of the eval-driven proposal: find out what actually fails before writing
evals. Method after Husain / Anthropic "Demystifying evals": read sessions, note
the first failure in each, group, count.

## Method

- Population: 183 main sessions with human turns, first human turn on or after
  2026-09-01, vault and `/tmp` projects excluded (`sample.py`, seed 20261015).
- Sample: 38 — 15 with a correction signal in a human turn, 15 without, all 8
  sessions started after the lean merge (2026-10-11 00:49 UTC).
  The sample list (`sample.tsv`: paths and first user messages) stays local in
  `/tmp/error-analysis/` — this repo is public; client project names in the
  notes are replaced with `work-client-*`.
- `render.py` → readable sessions in `/tmp/error-analysis/renders/` (outside the
  repo: tool output may hold secrets). Four Opus subagents annotated them per
  `brief.md`; notes in `notes/batch-*.jsonl`.
- `anchor: user` = a later human turn reacts to the failure; `anchor: model` =
  the annotator's judgement alone. `still_applies` = would the current setup
  most likely do the same.

## Result

19 of 38 sessions have a first failure (signal 12/15, quiet 4/15, lean 3/8).
Only 2 are `anchor: user` (32, 34); 17 rest on model judgement. Verification
of model-anchored notes: 38 checked against the transcript by the main session
(the request did not ask for English); 06, 09, 10, 24, 27 labelled by the user
on 2026-10-15 — all five failures, 6 of 6 confirmed. The user moved 27 from D
to C (see below) and rejected the reading that a current rule causes 24.

| Mode | Sessions | Still applies | Caught by |
|---|---|---|---|
| A. A checkable claim stated as fact after no check, a confounded check, or a check that cannot prove it (filtered listing, mtimes, config flag) | 02 03 05 08 09 10 15 24 | 7 yes, 1 no (05) | per-task reviewer 02 24 · implementer 03 15 · red-team 10 · self 05 08 · vault session 09 |
| B. Work closed or merged with a known open step or gap left unsaid | 06 25 29 34 | 2 yes, 1 ?, 1 no (25) | user 34 · implementer 29 · nobody 06 25 |
| C. Acted on a direction, choice or scope widening the user had not agreed, trade-off named only later | 27 32 38 | 3 yes | user 32 · nobody 27 38 |
| D. A rule skipped in a side action no gate sees (vault message with task status) | 11 | yes | self |
| E. A pipe masked a failed command (push → deploy shipped old main) | 07 | yes | self |
| Old process only | 04 14 | no | — |

## Reading

1. Mode A is the dominant failure: 8 of 19, 7 still apply. Workflow rule 3
   ("check it, don't state it from memory") is in force and was broken anyway;
   in 09 and 15 the agent did run a check, just one that could not prove the
   claim. In 24 the user holds that "settle it yourself with a tool" is right
   and the failure is closing on one grep instead of verifying the claim.
   In 10 the user expects more: the agent should have flagged that the two
   apps it copied the pattern from carry the same defect — and that check
   belonged to the session that set up the first app.
2. The user rarely sees mode A: none of the 8 has a human reaction. The
   2026-10-25 outcome metrics (fix commits, user interventions) will mostly
   miss it.
3. Two of the eight (02, 24) were caught by the per-task review that L6
   removed. Inline work, now the default, has no reviewer unless it crosses
   modules. Lean-stratum data (8 sessions) is too small to tell whether the
   branch review replaces it.
4. By the threshold set before the analysis ("fewer than 5 recurring modes
   with still_applies → no full suite"), a broad eval suite is not justified:
   A (7), C (3) and B (2 yes + 1 ?) recur. Targeted suites for A, then C, are.
5. Mode C as the user put it for 27: "should not have implemented it right
   away without agreeing the direction with me". 27 and 38 are both edits to
   the setup itself, made before the user agreed what to change.

## Lessons from the previous setup (still_applies: no)

- A rule broken in almost every session is a wrong rule, not a discipline
  problem: "cbm before Grep/Read" was broken in every navigating session
  (annotators left it out as noise) and L10 removed it; in 04 the agent
  bypassed the full pipeline for a small change, which L1 then made the
  default.
- Ordering bugs go away with one gate: in 14 the spec row was written before
  the red-team changed the plan; L3 writes decisions into the spec after it.
- Static environment facts in CLAUDE.md work where behavioural rules do not:
  05 (guessing the sync mechanism) has no counterpart since the Two machines
  section; rule 3, a behavioural rule, kept failing.
- Plan scope must not freeze a known spec lie (25); fixed by rule 6.

## Next: a mode-A suite

- Cases: the 8 mode-A sessions are the RED baseline; each note names the check
  the agent skipped (eslint rule source in 03, a test mount in 15, `terraform
  providers schema` in 10).
- Graders: `tool_used` on that check plus `tool_order` (check before the
  Write/Edit of the brief, spec row or design), and `regex` on the produced
  file for the false claim.
- Harness: mode A breaks CLAUDE.md rule 3 and Candor, and `claude plugin eval`
  does not load CLAUDE.md, so it runs on `turn.sh` / `make-config-dir.sh`
  (`.flow/specs/2026-10-08-knowledge-transfer-evidence/`).
- Fix form: `skills/writing-skills/testing-skills-with-subagents.md` puts
  "knows the rule, skips it under pressure" under prohibition + rationalization
  table; rule 3 is soft guidance. Rationalizations from 09, 15 and 24 feed it.

## Limits

- 17 of 19 failures rest on model judgement; only 38 was checked by hand here.
- The correction-signal regex is crude: in signal sessions the human
  corrections mostly concerned something other than the first failure.
- Annotators skipped the removed cbm rule on purpose (would have masked the
  real first failures).
