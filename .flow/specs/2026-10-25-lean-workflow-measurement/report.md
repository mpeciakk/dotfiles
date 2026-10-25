# Lean workflow — two-week measurement (2026-10-25)

The check promised in `2026-10-10-lean-workflow-design.md` §Measuring it.
Rollback point: tag `workflow-v1`.

## Verdict

The two run metrics point the wrong way, but they are too small and too confounded
to justify a rollback. Post-lean runs get a post-merge fix twice as often (2 of 5 and
5 of 12, against 8 of 40). They take more active time per task (0.26 h against 0.12 h), most of it in the
branch-review phase that L6 and L11 made heavier on purpose.
User interventions did not drop (2 of 15 runs against 3 of 50). The population
changed with the workflow: lean sends small changes inline, so the runs that remain
are larger, and three of the seven fixed runs are MVP runs of new interactive
projects (canvas twice, ernest bridge v2), whose fixes came from live use. Confidence that lean
made runs worse: low. Two more weeks of runs, or a classification of the 24
post-lean run fixes into "a per-task review would have caught it" and "found only
live", would change this.

The rollback criterion ("worse quality with no gain in speed") is not met on the
evidence. It is not ruled out either.

## Method

- Windows: pre = runs started 2026-09-27 … 2026-10-11 00:49 UTC (merge `4e11030`),
  post = 2026-10-11 … 2026-10-25. Equal length. The pre window was not a stable
  baseline: plan-granularity, review-cost-cuts and setup-perf-audit all landed in it.
- A run = from the first `flow-state set stage=implement` to `stage=finish`, read
  from main-session transcripts (`runs.py`). Runs without a finish (ernest
  lora-bielik) and sessions made only of pulpit probes are excluded.
- Active time = run wall time minus (a) every gap that ends in a human turn or an
  interrupt (user wait) and (b) every gap over 2 h with no event (machine off;
  the pulpit run slept 11 h waiting on a background implementer). Only the run's
  own sessions count, not parallel sessions in the same repo.
- Fix commits (`fixes.py`): a landed change is a run (all commits whose author date
  falls in it) or a burst of inline commits less than 2 h apart. A fix is a commit
  whose subject starts with `fix`/`revert`/`hotfix` or says "napraw", outside the
  change, within 7 days after it, touching at least one of its code files (not
  `.md`, `docs/`, `.flow/`). Commits naming a review or red-team are left out:
  post-lean, inline review fixes land after the commit they fix. Each fix is
  attributed once, to the most recent change it touches. Every repo under
  `~/projects`, `~/work`, `~/dotfiles` with commits in the window; vault excluded;
  clones that share commits counted once.
- Censoring: a change landed after 2026-10-18 17:00 UTC has under 7 days of
  follow-up, so its fix rate is a lower bound. It is reported separately.
- Denominators differ: the fix metric counts 40 pre runs, not 50, because runs
  with no code-file commits (plan, docs or vault only) have nothing to fix.
  The implementation/review split counts only runs that had a branch review
  (41 pre, all 15 post).

## Result

| Metric | Pre (09-27…10-10) | Post |
|---|---|---|
| Runs finished | 50 | 15 |
| Active time per run, median (IQR) | 0.36 h (0.22–0.85) | 0.84 h (0.51–1.28) |
| Active time per plan task, median | 0.12 h | 0.26 h |
| Active time per 1000 changed lines, median | 0.33 h | 0.44 h |
| … go → first branch review, median active | 0.43 h | 0.54 h |
| … branch review → finish, median active | 0.11 h | 0.29 h |
| User wait per run, median | 0.03 h | 0.06 h |
| Subagents per run, median (task reviewers) | 10 (281 total) | 6 (0) |
| Runs with a post-merge fix in 7 days | 8 / 40 (20%) | 2 / 5 (40%), landed ≤10-18 · 5 / 12 (≥42%) after |
| Post-merge fixes per 1000 lines, runs | 0.21 | 0.80 · ≥0.35 |
| Inline bursts with a post-merge fix | 4 / 39 (10%) | 4 / 14 (29%) · 2 / 31 (≥6%) |
| Runs with a user correction mid-run | 3 / 50 | 2 / 15 |

Where the extra run time went: mostly into the branch-review phase (review, its
fix round, finish), which grew from 0.11 h to 0.29 h. Implementation grew only
from 0.43 h to 0.54 h, even though there is no per-task reviewer any more. That fits
what the design moved into the branch review on purpose: real verification in one
pass (L6) and a reviewer that judges spec silence and no longer splits the work
(L11). The agent definitions did not change model or effort between `workflow-v1`
and HEAD (checked with `git diff`).

Mid-run corrections are classified by hand from every human turn inside a run.
Gate answers, requested actions ("token wklejony") and answers to the agent's
questions are not counted.
- Pre: "ale po chuj na pc a nie tutaj" (work-client-d), "zatrzymaj się po tym
  kroku" (harmonia), a hand edit of `fix-rounds.json` to unblock a hook (harmonia).
- Post: smoke tests drawing on the user's screens during a game (wyspa review fixes,
  now memory `wyspa-smokes-disturb`), "coś co robi agent mocno hanguje mi kompa"
  (work-client-c).
- Post, also: two defects the user found during the live verification the plan asked
  for (ernest bridge v2: persona bot, a reply split in two). They are not counted
  above.

Post-lean run fixes by run: canvas MVP 6 and hands-3d 5 (gesture behaviour after
live use), ernest bridge-v2 3 (one daemon hang on a long code-fence line),
dkron 4, deploy-lxc 3, work-client-a audit 1, work-client-b audit 2.

## L10 and L11

- `explorer` (Haiku): 2 real dispatches in 75 post-lean sessions, both in one
  work-client-c session on 10-22. The other 3 calls were pulpit probes. The agent
  is effectively unused. In the same period, `general-purpose` was dispatched 218
  times, mostly for research, audits and KT write tests, not for code navigation.
- cbm graph (`cbm.py`, main sessions and subagents): no graph query after the
  merge. There are 0 `trace_path` and 0 `get_architecture` calls, against 15 plans
  written and 19 branch-reviewer dispatches. The only calls are 3
  `index_repository` at finish (ernest, work-client-c, harmonia). Pre: 35 calls,
  23 of them by the branch reviewer, against ~2450 grep/find searches; post: 3
  calls against ~1400. The L10 rule, `trace_path` for blast radius in planning
  and in the branch review, is not followed. The cause is not checked: one
  candidate is that cbm tools are deferred and need a ToolSearch load first.
- `## Rulings`: 12 of 19 post-lean plans have the section, 70 entries in total.
  Whether they were yours to make is your call. One pattern to check against L11
  ("spec decisions … stay with the user"): several rulings change a decision row
  of the plan without asking.
  - pulpit-mod: D9 gains a status `ended`, and D12 is redefined on `root()`.
  - harmonia selection-side-effects: D96 corrected on the branch.
  - work-client-b audit-db: deviates from D7 (CA delivery) and D8 (SQL regex).

## Not measured

- Mode A from `2026-10-15-error-analysis/report.md`: claims stated as fact without
  a proving check. None of the metrics above can see it. It needs the annotation
  pass rerun on a post-lean sample.
- Inline work has no "go" marker, so the speed metric covers runs only. Under lean,
  most changes are inline.
- Fix detection relies on commit subjects. A fix committed as `feat:` or folded
  into a later change is missed. A fix that touches a shared file is attributed to
  the most recent change, which may not be the one it fixes.
