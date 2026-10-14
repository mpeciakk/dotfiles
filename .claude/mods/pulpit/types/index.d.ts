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

declare module 'claude-code' {
  interface PluginState {
    pulpit: {
      /** The run in `<main checkout>/.flow/run/state.json`; null when there is none or it is unusable. */
      run: PulpitRun | null
      /** The `agent_type` of a writer subagent in flight; null while the controller writes. Filled by the agent tracking. */
      writer: string | null
      /** True once the pane has been opened this session; a missing pane after that was closed by the person. */
      hasOpened: boolean
    }
  }
}
