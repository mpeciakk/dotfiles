// What pulpit keeps in `$.state`, and the shapes it reads from `flow-state`'s state.json.

export type PulpitLedgerEntry = {
  /** `n` of `flow-state task N STATUS`: a task number, or a named gate such as `branch-review`. */
  n: string
  /** `started`, `done` or `blocked` (anything else is shown as written). */
  status: string
  note?: string
}

export type PulpitRun = {
  task: string
  stage: string
  plan?: string
  worktree?: string
  branch?: string
  /** The SHA the run's worktree branched from. */
  base?: string
  ledger: PulpitLedgerEntry[]
}

export type PulpitAgent = {
  /** The id `agent.spawn` answers and `$.agent.list()` lists it by. */
  id: string
  /** `subagentType`: the role. */
  type: string
  description: string
  /** The model of the agent's latest step; before its first step, what `agent.spawn` resolved. */
  model: string
  /** The effort of the agent's latest step; absent before its first step or for a model without effort. */
  effort?: string | number
  /** The ledger entry the run had `started` when an implementer was spawned. */
  task?: string
  /** `$.agent.list()`'s status as last seen. */
  status: string
  /** When it was spawned, or last resumed (ms, `$.clock.now()`). */
  startedAt: number
  /** When it was first seen finished; absent while it is not. */
  endedAt?: number
}

export type PulpitDenial = {
  /** The `tool_use_id` of the refused call: the key that makes one denial of a `tool.check` deny and a `classic.PermissionDenied`. */
  id: string
  /** `$.clock.now()` when it was seen (ms). */
  at: number
  tool: string
  /** The `agent_type` of the subagent whose call it was; absent for the main loop. */
  agentType?: string
  reason: string
}

export type PulpitGate = {
  /** `tool.check` allowed by a settings rule (the result carries `rule`). */
  byRule: number
  /** `tool.check` allowed by the mode (no `rule`). */
  byMode: number
  /** `tool.check` said ask; who settled it is not known. */
  asked: number
  /** Every denial seen, one per `tool_use_id`. */
  denied: number
  /** The last 5 denials, oldest first. */
  denials: PulpitDenial[]
}

export type PulpitConsult = {
  startedAt: number
  /** Absent when the response ended before the advisor's result. */
  durationMs?: number
  /** The run's stage when the step came back; empty without a run. */
  stage: string
}

export type PulpitAdvisor = {
  /** Main-loop consults this session. */
  count: number
  /** The latest 5, oldest first. */
  recent: PulpitConsult[]
}

export type PulpitMetrics = {
  /** The run these figures belong to (its `task`); empty before a run was seen. A different task starts them again. */
  run: string
  /** The run's stage at the last look: a go is a plan that is no longer plan. */
  stage: string
  /** `$.clock.now()` when this session saw the stage go from `plan` to `isolate`, `implement` or `inline`. */
  goAt?: number
  /** When this session first found itself inside the run's worktree past `plan`. */
  joinedAt?: number
  /** The session is inside the run's worktree and the stage is past `plan`: only then are figures kept and shown. */
  isCounting: boolean
  /** Prompts of the person's own (`origin.kind === 'composer'`) while counting. */
  interventions: number
  /** Milliseconds the session sat idle, from a main-loop turn's end to the person's next prompt, with no subagent running. */
  waitMs: number
}

declare module 'claude-code' {
  interface PluginState {
    pulpit: {
      /** The run in `<main checkout>/.flow/run/state.json`; null when there is none or it is unusable. */
      run: PulpitRun | null
      /** The `agent_type` of a writer subagent in flight; null while the controller writes. */
      writer: string | null
      /** The subagents spawned this session, in spawn order; finished ones beyond the last 6 are dropped. */
      agents: PulpitAgent[]
      /** `$.clock.now()` as the 1 s tick last saw it while a subagent is in flight; the Roles clocks read it, so a write redraws them. */
      now: number
      /** What `tool.check` and `classic.PermissionDenied` showed this session. */
      gate: PulpitGate
      /** The main loop's advisor consults this session. */
      advisor: PulpitAdvisor
      /** This session's figures for the open run. */
      metrics: PulpitMetrics
      /** `$.clock.now()` at the end of the latest main-loop turn, while no turn has started since; null otherwise. */
      idleSince: number | null
      /** True once the pane has been opened this session; a missing pane after that was closed by the person. */
      hasOpened: boolean
    }
  }
}
