# Pulpit — a Claude Code dashboard mod for the development-workflow — plan

## Goal
A function-hooks mod `pulpit` that shows, live beside the transcript, what this user's workflow is doing: the
run from `flow-state`, who may write the tree, the subagents as roles, permission checks, advisor consults, and
this session's run metrics (time since "go", user wait, interventions). Spec: none for `.claude/` — this plan's Decisions are the
record (design record lineage: `.flow/specs/2026-10-10-lean-workflow-design.md`, "Measuring it").

## Decisions
- D1 Own mod, built from scratch, inspired by scasella/claude-flightdeck (user's choice). Rejected: a small mod
  beside an installed flightdeck (user wants one dashboard); a flightdeck fork (maintaining a fork on an
  early-access API).
- D2 Panels, in this order: **Run**, **Writer**, **Roles**, **Gate**, **Advisor**, **Metrics**. A panel with
  nothing to show takes no room. No context / cost / rate-limit panels: the python statusline shows them.
  Rejected: turn receipt + event log (user did not pick them).
- D3 The statusline's `flow` line stays; the mod never calls `$.ui.status`. The band (D5) does not repeat what
  that line shows (task · stage · N/M · branch).
- D4 Pane `pulpit` (title `pulpit`) is opened at every `session.start` (user's choice: always, not only during a
  run); the engine places an unasked pane from 144 columns (110 once the user has opened it). `/pulpit` toggles
  it; `/pulpit` while closed opens it at any width. A pane the user closed stays closed for the session
  (`$.state` flag): `session.start` fires again on every module reload and must not reopen it.
- D5 Band above the prompt (`AbovePrompt`): drawn only while the pane is not placed (`$.ui.panes()`) and there
  is something to show; at most 2 rows: ✋ gate if one is pending, writer, running agents count, the latest
  denial (tool + first 60 chars of reason). Otherwise `next(e)`.
- D6 Pure observer: every hook calls `next(e)` with `e` as given and returns its result unchanged; no hook
  answers without `next`. `claude plugin validate` lists observed sites as gating by nature — its `gatingHooks`
  must be exactly the sites the mod observes ({`tool.check`, `prompt.submit`, `agent.spawn`,
  `classic.PermissionDenied`, `turn.step` if listed}), each with a `.catch` that replays `next(e)`. No network call, no model call.
- D7 **Run** source: `<main checkout>/.flow/run/state.json`, the main checkout resolved like `flow-state` does
  (`git worktree list --porcelain`, first entry) from `$.session.cwd()` — or `$.session.root()` if Task 1's
  probe shows `cwd()` follows a Bash `cd` — via `$.process.run`. Re-read on a 2 s
  `$.clock.every`, parsing only when `$.fs.stat` mtime changed; re-resolve the checkout when the cwd changes.
  Shows: task, stage, the pending gate (✋ `go` when `stage=plan` with a `plan`; ✋ `merge / PR / keep /
  discard` when the ledger has `branch-review` done and `stage` is not yet `finish`), each ledger entry with its status
  (`started`/`done`/`blocked`, blocked highlighted), worktree, branch, base (short SHA). Missing / unreadable /
  malformed file → no Run panel, no error line.
- D8 **Writer**: "writes: controller" unless a subagent of a writer type is in flight, then "writes: <type>"
  — for `implementer` "writes: implementer · task N · <worktree basename>" (N = the latest ledger entry with
  status `started`). In flight = `$.agent.list()` status `running` (covers an agent resumed by SendMessage). Read-only
  types are the set in `hooks/flow-context` `READ_ONLY_AGENTS` (`branch-reviewer`, `plan-red-team`,
  `explorer`, `Explore`); any other type counts as a writer, same default as flow-context. Display only.
- D9 **Roles**: one row per subagent spawned in this session: role (= `subagentType`), model · effort, task N
  for an implementer, description, running clock (1 s), done/failed with duration once finished. Spawn from
  `agent.spawn` (result `agentId`); status from `$.agent.list()` on the 1 s tick (running / completed / failed
  / killed). Model · effort: the latest `turn.step` input carrying that `agentId` (`model`, `effort` as
  actually sent); before its first step, `agent.spawn`'s result `model` and no effort. Finished rows beyond
  the last 6 are dropped.
- D10 **Gate** (user's choice: counters + denials, no per-check grid): session counters per verdict from
  `tool.check` results — allowed by rule (`rule` set), allowed by mode (no `rule`), asked, denied — and the last
  5 denials (time, tool, agent type when a subagent's, reason). A denial is a `tool.check` `deny` (settings hook
  denials carry `hook: 'PreToolUse'` and flow-guard's reason text) or a `classic.PermissionDenied` (an `ask`
  refused by the classifier or the user; deduplicated by `tool_use_id`). No `tool.call` hook and no
  error-text matching. The API cannot say who settled an `ask`; the panel never claims to.
- D11 **Advisor**: count this session and one line per consult: start time, duration, run stage at that
  moment. Source: `turn.step`'s result `serverToolUses` entries with `name === 'advisor'` (`startedAt`,
  `endedAt`; no `endedAt` → duration shown as `?`). Main loop only (`turn.step` without `agentId`); a
  subagent's consults are not counted. Shown once the step is whole — the API exposes no live start.
- D12 **Metrics** (user's choice: session-local panel; the lean-workflow before/after comparison is a separate
  transcript script, not this run): kept in `$.state` (session-scoped, survives reloads), no files. Counted
  only while the session's cwd is inside the run's recorded worktree and the stage is past `plan`. Shows:
  time since "go" when this session observed it (`stage` going `plan` → `isolate`|`implement`|`inline`),
  else time since the session joined the run; interventions = prompts with `origin.kind === 'composer'`;
  user wait = from the end of a main-loop turn to the next such prompt, counted only when no subagent was
  running (`$.agent.list()`) and no other turn started between. Panel hidden outside a run. Rejected: a
  cross-session JSONL record (no append/atomic create in `$.fs`, no pre-`workflow-v1` baseline — red-team
  S1/S2).
- D13 Home: `~/dotfiles/.claude/mods/pulpit/`, loaded in every session through `CLAUDE_CODE_PLUGIN_DIRS` in
  the `env` block of `.claude/settings.json` (value `~/dotfiles/.claude/mods/pulpit`, works on pc and laptop:
  both have `~/dotfiles`); watched, so edits hot-reload. Engine-written `.claude-plugin/types/` is git-ignored.
  Rejected: the session's `~/.claude/dev-mods/<uuid>/` (session-bound, outside the repo); a dotter mapping
  (per-file links, no gain over pointing at the repo).
- D14 Code split like flightdeck's: `hooks/core.ts` pure reducers and formatters (state transitions,
  verdict classification, metrics window), `hooks/register.tsx` hooks + `$` access + drawing. Tests target
  `core.ts` directly and the drawn tree through `$.ui.mount` on `terminal` and `desktop`.

## Constraints
- Claude Code 2.1.296 on pc; the API is early access — the d.ts written at load (`.claude-plugin/types/`) is
  the authority, not memory.
- A hook that throws is skipped by the engine; the mod must not rely on that — data-source failures (git
  missing, unreadable file, malformed JSON) degrade to "panel hidden", never a transcript error line.
- No new dependencies; no `import()`; files are ES modules with the extensions the engine loads.
- `claude plugin test` has no real fs or process: fixture tests answer `fs.stat`, `fs.read`, `fs.write`,
  `process.run` by hooking those events beneath the plugin.
- One writer per tree; the run's worktree only.

## Verification
1. `claude plugin validate <worktree>/.claude/mods/pulpit`: loads, no refusals, `gatingHooks` exactly the
   observed sites of D6, each with its `.catch`.
2. `claude plugin test <mod folder>`: all tests green, including a mount on `terminal` and `desktop`.
3. Real session (the user's, at the finish gate — the reviewer cannot drive the TUI; the controller writes
   the commands out): in a scratch git repo under `/tmp`, `flow-state init x; set stage=plan plan=/tmp/p.md`,
   then `claude --plugin-dir <worktree>/.claude/mods/pulpit` there, ≥144 columns. Check: the pane opens, Run
   shows `✋ go`; `flow-state set stage=isolate worktree=.` → within 2 s the gate is gone; ask the session to
   dispatch one `explorer` agent → a Roles row with clock, then done; ask it to `Edit` `.flow/run/state.json`
   → flow-guard denies, Gate shows the reason and the band does when the terminal is narrowed below 110
   columns; an advisor call, if one happens, appears in Advisor. End with `flow-state clear` and `rm -rf` of
   the scratch repo.
4. `claude -p --plugin-dir <mod> --debug "say ok"`: debug log has no `pulpit:` load or hook failure line.

## Task 1: skeleton, data sources, pane and band
**Outcome:** the mod loads from `.claude/mods/pulpit/`; the pane opens at `session.start` and `/pulpit`
toggles it; the band draws when the pane is not placed; the Run and Writer panels show live data from
`state.json` and agent spawns (Writer may show "controller" only until Task 2 tracks agents — its read of
writer state lands here as an atom Task 2 fills). `settings.json` `env.CLAUDE_CODE_PLUGIN_DIRS` set,
`.gitignore` covers `.claude/mods/*/.claude-plugin/types/`.
**Acceptance:** tests show: Run panel from a fixture state (each stage, ✋ go, ✋ merge, blocked entry); no
panel for a missing / malformed file; mtime unchanged → no re-parse; checkout resolved from a linked worktree
cwd to the main checkout; band absent while the pane is placed, present (≤2 rows) when not; `/pulpit` opens
and closes; a pane closed by the user is not reopened by a module reload. First, a real probe in a `claude -p
--plugin-dir` session (results reported before building on them): `$.fs.read` of an absolute path outside the
mod; `$.process.run` of `git`; whether `$.session.cwd()` changes after a Bash `cd` (D7); whether
`classic.PermissionDenied` fires on an auto-mode classifier denial (D10) — if it does not, report it, the Gate
counts only `tool.check` denials.
**Area:** `.claude/mods/pulpit/{.claude-plugin/plugin.json,hooks/hooks.json,hooks/register.tsx,hooks/core.ts,
types/index.d.ts,*.test.ts}`, `.claude/settings.json` (env only), `.gitignore`.
**Context:** plugin-authoring skill (examples `pane.tsx`, `band.tsx`, `pane-state.d.ts`); `hooks/flow-state`
(`load`, ledger shape, worktree resolution); D4–D8, D13, D14.

## Task 2: Roles and Writer from subagents
**Outcome:** Roles panel lists subagents with model · effort, task N, live clock, finish state; Writer
switches to the in-flight implementer and back.
**Acceptance:** tests show: spawn → row with clock ticking on the mocked clock; `$.agent.list()` status
completed → done + duration, failed/killed → failed; model · effort taken from that agent's `turn.step`
input, model only before its first step; read-only type in flight → Writer stays "controller"; other
non-implementer writer type → "writes: <type>"; agent back to running (resumed) → Writer names it again;
two implementers → both rows, Writer names the latest `started` task; >6 finished → oldest dropped.
**Area:** `hooks/core.ts`, `hooks/register.tsx`, `types/index.d.ts`, tests.
**Context:** D8, D9; Task 1's atoms and panel layout.

## Task 3: Gate and Advisor
**Outcome:** Gate counters and last 5 denials; Advisor consult list with stage.
**Acceptance:** tests show: each `tool.check` verdict lands in its counter (rule vs no rule); a PreToolUse
hook deny shows its reason; a `classic.PermissionDenied` counts as one denial even if a `tool.check` deny
with the same `tool_use_id` was seen; 6th denial evicts the oldest; a subagent's denial carries its type; a
main-loop `turn.step` result with an `advisor` server tool use adds a line with duration (`?` without
`endedAt`) and the stage at that time; a subagent's advisor use adds nothing; no advisor → no panel.
Band shows the latest denial.
**Area:** `hooks/core.ts`, `hooks/register.tsx`, `types/index.d.ts`, tests.
**Context:** D10, D11; d.ts `ToolCheckResult`, `PermissionDeniedHookInput`, `TurnStepResult.serverToolUses`.

## Task 4: Metrics panel
**Outcome:** the Metrics panel shows this session's figures for the open run (D12).
**Acceptance:** tests show: `plan` → `isolate` observed → "since go" clock; joining a run already past
`plan` → "since joined"; `plan` → `design` starts nothing; a composer prompt after an idle main-loop gap adds
wait and an intervention; a notification-origin turn adds neither; a prompt while a subagent runs adds an
intervention but no wait; cwd outside the worktree → nothing counted, panel hidden; figures survive a module
reload (`$.state`); run cleared → panel gone.
**Area:** `hooks/core.ts`, `hooks/register.tsx`, `types/index.d.ts`, tests.
**Context:** D12; `.flow/specs/2026-10-10-lean-workflow-design.md` "Measuring it" (definitions only).

## Rulings
- Task 2: D9 gains a fifth row status `ended` (a running agent gone from `$.agent.list()` ≥2 s after spawn), dimmed with its duration — a real `claude -p` probe on 2.1.296 showed finished agents drop off the list instead of reading `completed`; `done`/`failed` stay for when the engine reports them — cost if wrong: a row says `ended` where `done` was knowable.
- Task 2: the band's running-agents count (D5) moves to Task 3, beside the latest denial — Task 1 deferred it and Task 2's acceptance did not list it — cost if wrong: none, one owner.
- Task 3: D6's gating set includes `classic.PermissionDenied` (D10 hooks it; validate lists it) — cost if wrong: none, wording.
- Task 3: the Advisor panel shows the latest 5 consults under `Advisor (N)` instead of every consult — keeps the panel bounded in a long session — cost if wrong: one constant.
