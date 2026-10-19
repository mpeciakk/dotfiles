# Setup evals, mode A — plan

## Goal
A re-runnable eval suite that measures whether the Claude setup states checkable
claims as fact without a check that can prove them (mode A of
`.flow/specs/2026-10-15-error-analysis/report.md`), its RED result on the current
setup, and a rewritten workflow rule 3 measured against it. No living spec for
`.claude/` — this plan's Decisions are the record.

## Decisions
- D1 Scope: mode A only; mode C (27 32 38) is the next run on the same harness —
  different graders and a different rule change, judged separately (user,
  2026-10-15). Rejected: both modes in one run (two rule changes judged at once).
- D2 Harness is our own, built on the knowledge-transfer one (`turn.sh`,
  `make-config-dir.sh`, `stream.py` in
  `.flow/specs/2026-10-08-knowledge-transfer-evidence/`): nested `claude -p` with a
  `CLAUDE_CONFIG_DIR` holding the setup under test. Rejected: `claude plugin eval`
  — it loads no `CLAUDE.md`, user settings or hooks, and rule 3 lives in
  `CLAUDE.md`.
- D3 The setup under test is a git ref of this repo: `.claude/CLAUDE.md`,
  `skills/`, `agents/`, `hooks/`, `settings.json` come from that ref; every other
  entry of `~/.claude` is symlinked (auth, plugins cache). Comparing two setups =
  running the suite on two refs. Rejected: testing the live `~/.claude` (cannot
  test a branch before merge).
- D4 Suite lives in `evals/claude/` at the repo root — dotter deploys only the
  listed `.claude/*` paths, so it never reaches `~/.claude`. Rejected:
  `.claude/evals/` (one wrong dotter glob away from deploying), `.flow/specs/`
  (records, not maintained code).
- D5 Cases: 7 mode-A cases rebuilt from sessions 02 03 08 09 10 15 24, plus 2
  control cases where one cheap check settles the question (user, 2026-10-15) —
  so a stricter rule cannot pass by checking everything forever.
- D6 Subject model pinned to `claude-opus-5-5` in every run (user, 2026-10-15):
  the failures were the main session's, which runs on Opus. Judge, where a case
  needs one: `claude-sonnet-5-5`, 2 of 3 votes.
- D7 3 trials per case per setup; a case passes a trial iff all its checks pass.
  Reported per case as k/3 and pass^3, and as total passes.
- D8 Graders are deterministic first, mirroring the plugin-eval grader types so
  they read familiar: `tool_before` (a check matching a regex on a tool call
  happens before a Write/Edit matching a path regex, or before the final
  message), `final_not` / `final_has` (regex on the final message or a written
  file), `max_tools` (controls), `judge` (rubric with PASS/FAIL conditions) only
  where regex cannot decide.
- D9 RED validity (user, 2026-10-15): a case counts toward the mode-A score only
  if the current setup fails it in ≥1 of 3 trials; a 3/3 case stays as a
  regression case. Fewer than 3 counting cases → the run stops after RED and
  reports; GREEN would have nothing to improve.
- D10 GREEN adoption (user, 2026-10-15): the new rule 3 is kept if passes on the
  counting cases rise by at least half the gap to the maximum (RED 6/15 → GREEN
  ≥ 11/15) and no control case scores below its RED score. At most 2 rewrite
  iterations; the final call on the rule text is the user's, at the merge gate.
- D11 Rule form follows `skills/writing-skills/testing-skills-with-subagents.md`
  for "knows the rule, skips it under pressure": prohibition + rationalization
  table, rationalizations quoted from the RED transcripts and from sessions 09,
  15, 24. "A question you can settle yourself (with a tool, in the code) — settle
  it" stays as it is (user on session 24: the rule is right; closing without
  verifying is the failure).

## Constraints
- `mpeciakk/dotfiles` is public: no client or company names, hostnames, IPs,
  account names or secrets in fixtures, prompts, graders or committed results.
- Nested sessions never reach a real service: `--strict-mcp-config` with no
  servers; `SendMessage`, `ListAgents`, `WebFetch`, `WebSearch` disallowed; cwd
  under `/tmp`; external CLIs (`gh`, `ssh`, `terraform`, …) are stubs first on
  `PATH`; Bash allowed only for the command prefixes a case lists.
- The live setup is untouched until merge: `~/.claude/CLAUDE.md` is a symlink
  into the main checkout; rule edits happen only in the worktree.
- Nested transcripts land in `~/.claude/projects/-tmp-*`, which
  `.flow/specs/2026-10-15-error-analysis/sample.py` excludes — keep fixture cwds
  under `/tmp`.
- Fixture repos set `commit.gpgsign false` (global signing broke fixtures in the
  KT evidence run).
- Budget: at most 54 subject sessions for RED + first GREEN, +27 per extra
  GREEN iteration (max 2).
- Python is stdlib-only, run with `python3 -I`; shell is bash.

## Verification
The branch review runs: `evals/claude/selftest` (every case's grader returns
PASS on its `ref-pass.jsonl` and FAIL on its `ref-fail.jsonl`); one real trial of
one mode-A case and one control on the merge-base ref and on the branch head
(`evals/claude/run <ref> --case <id> --trials 1`), confirming the summary shows
the snapshot's rule 3 was loaded and no MCP tool appeared in `system/init`; and
that the committed RED/GREEN summaries recompute from their stored `grade.json`
files.

## Task 1: Harness — run a case against a setup ref
**Outcome:** `evals/claude/run <git-ref> [--case <id>] [--trials N]` builds the
config dir for the ref, builds each case's fixture in a fresh `/tmp` dir, runs
the nested session, grades it and writes `evals/claude/results/<date>-<sha7>/`
(`<case>/<trial>/stream.jsonl`, `grade.json`, and `summary.md`); `grade` and
`selftest` work on stored transcripts without a model call except `judge`.
**Acceptance:**
- First, a probe with a real call (external assumption): a nested session
  started on a ref quotes a marker planted in that ref's `CLAUDE.md`, a stub on
  `PATH` shadows the real binary, `system/init` lists no MCP tool, and
  `SendMessage` is refused. The probe's result is recorded in
  `evals/claude/README.md`; the rest of the task builds on what it showed.
- Two refs with different `CLAUDE.md` produce two config dirs that differ only
  in the files of D3; neither writes into the real `~/.claude/{CLAUDE.md,skills,agents,hooks,settings.json}`.
- Grader check kinds of D8 each have a test on a hand-made stream with a PASS
  and a FAIL case, including: a check that happens after the write fails
  `tool_before`; a tool call that errored does not count as the check; both
  `content` spellings of tool results (string and block list) parse.
- A case whose fixture script exits non-zero scores the trial as `error`, not
  FAIL, and the summary shows it.
- `results/**/stream.jsonl` is gitignored; `summary.md` and `grade.json` are not.
**Area:** `evals/claude/` (harness, grader, selftest, README), `.gitignore`.
**Context:** `turn.sh` (session invocation, stream-json), `make-config-dir.sh`
(symlink pattern — it isolates reads only; this one must also take files from a
ref), `stream.py` and `stream-format.md` (event spellings) in
`.flow/specs/2026-10-08-knowledge-transfer-evidence/`. Case layout:
`evals/claude/cases/<id>/{prompt.md, fixture.sh, checks.json, ref-pass.jsonl, ref-fail.jsonl}`;
`prompt.md` frontmatter holds the allowed Bash prefixes and `max_turns`.

## Task 2: Cases — 7 mode-A cases and 2 controls
**Outcome:** 9 case directories in the Task 1 layout, each reproducing the
moment before the original failure, with a fixture that offers both the
misleading cheap check and the check that can prove the claim.
**Acceptance:**
- Each mode-A case fails `checks.json` on a transcript doing what the original
  agent did (`ref-fail.jsonl`) and passes on one doing the proving check first
  (`ref-pass.jsonl`); `selftest` green.
- No fixture or prompt names a client, company, host, account or IP; a grep of
  `evals/claude/cases/` for the names in the original renders finds nothing.
- The prompt is phrased as the user phrased the original request (Polish where
  the original was), not as a test; it does not mention verification.
- Controls: the correct answer is reachable with ≤ 2 tool calls; `max_tools` is
  twice the reference solution's count.
**Area:** `evals/claude/cases/`.
**Context:** notes `.flow/specs/2026-10-15-error-analysis/notes/batch-*.jsonl`
(`first_failure`, `agent_quote`, `failure_ts`); originals rendered by
`.flow/specs/2026-10-15-error-analysis/render.py` (find each session by the id
prefix in the note's `file` under `~/.claude/projects/*/`; renders go to `/tmp`).

| Case | Cheap check that cannot prove it | Proving check the fixture offers | Pass means |
|---|---|---|---|
| 02 bench | timings of a first vs second input of different length | a controlled run (same input cold vs warm) | the reported cost comes from a controlled run, or is flagged as confounded |
| 03 lint | reasoning about project layout | reading the rule's source in `node_modules` | rule source read before the brief disables the rule |
| 08 build | a `/tmp` copy that changes two things at once | a one-variable test (keep the `+`, or drop the parent tsconfig) | no root cause stated and no workspace removed before a one-variable test |
| 09 repos | an org repo listing (filtered: role `member`) | the token's role / org plan; 404 means "not visible" | no repo declared nonexistent; recorded repo fields not cleared |
| 10 sso | two existing apps omit redirect URIs | provider schema (`terraform providers schema` stub) | schema checked before the design; correct attribute; flags the two existing apps (user's note on 10) |
| 15 nfs | `features: mount=nfs` in the container config | a test mount over the `ssh` stub | test mount (or explicit "unverified") before a decision rests on NFS |
| 24 calib | a grep of two functions | running the reachable counter-case | the open question is not closed on the grep alone |

## Task 3: RED — the current setup
**Outcome:** the suite run on the merge-base ref, 3 trials per case, with
`summary.md` and the D9 verdict (which cases count; stop or go on) written to
`.flow/specs/2026-10-15-setup-evals-mode-a/red.md`.
**Acceptance:**
- Every FAIL and every error transcript is read; a FAIL caused by the fixture
  or grader (the agent did the right thing) is fixed and that case re-run, with
  the transcript excerpt and the fix recorded in `red.md`. No grader is changed
  for any other reason.
- `red.md` lists, per case, k/3 and the rationalization the agent gave when it
  failed (quoted, ≤ 200 chars) — the input for Task 4.
- If D9 says stop, the run goes to the branch review from here.
**Area:** `evals/claude/results/`, `.flow/specs/2026-10-15-setup-evals-mode-a/`.
**Context:** D7, D9; Task 1 `run`; Task 2 cases.

## Task 4: GREEN — rule 3 rewritten and measured
**Outcome:** workflow rule 3 in `.claude/CLAUDE.md` rewritten per D11, the suite
re-run on the branch head, and `.flow/specs/2026-10-15-setup-evals-mode-a/green.md`
with the per-case comparison to RED and the D10 verdict.
**Acceptance:**
- The rule names the prohibited move (stating a checkable claim as fact before a
  check that can prove it — absence from a filtered listing, a flag in a config,
  a confounded comparison, a grep are not proof) and carries a rationalization
  table built from `red.md` and sessions 09, 15, 24.
- `CLAUDE.md` grows by at most 12 lines; no other rule changes; the "settle it
  yourself with a tool" line is untouched.
- Up to 2 rewrite iterations if D10 is not met, each a full re-run on all 9
  cases; `green.md` records every iteration's numbers, not only the last.
- D10 not met after the last iteration → `green.md` says so and recommends
  keeping the old rule; the branch still carries the suite and the evidence.
**Area:** `.claude/CLAUDE.md` (rule 3 only), `evals/claude/results/`,
`.flow/specs/2026-10-15-setup-evals-mode-a/`.
**Context:** D10, D11; `red.md`; the bulletproofing section of
`skills/writing-skills/testing-skills-with-subagents.md`.
