// Pure parts of pulpit: no `$`, no drawing. Reducers and formatters the hooks in register.tsx lean on.
import type { PulpitAgent, PulpitLedgerEntry, PulpitRun } from '../types'

export const PANE_ID = 'pulpit'

const optionalText = (value: unknown): string | undefined => (typeof value === 'string' && value !== '' ? value : undefined)

// Mirrors flow-state's load_at: a wrongly typed field means the file is not the contract, so no run.
export function parseRun(text: string): PulpitRun | undefined {
  let raw: unknown
  try {
    raw = JSON.parse(text)
  } catch {
    return undefined
  }
  if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) return undefined
  const state = raw as Record<string, unknown>
  for (const key of ['stage', 'worktree', 'branch', 'task']) {
    if (key in state && typeof state[key] !== 'string') return undefined
  }
  const ledger: PulpitLedgerEntry[] = []
  if (Array.isArray(state.tasks)) {
    for (const entry of state.tasks) {
      if (typeof entry !== 'object' || entry === null || Array.isArray(entry)) continue
      const { n, status, note } = entry as Record<string, unknown>
      const task: PulpitLedgerEntry = { n: String(n), status: String(status) }
      if (typeof note === 'string') task.note = note
      ledger.push(task)
    }
  }
  return {
    task: optionalText(state.task) ?? '',
    stage: optionalText(state.stage) ?? '',
    plan: optionalText(state.plan),
    worktree: optionalText(state.worktree),
    branch: optionalText(state.branch),
    base: optionalText(state.base),
    ledger,
  }
}

// The pending ✋ decision, as the words after the hand.
export function gateOf(run: PulpitRun): string | undefined {
  if (run.stage === 'plan' && run.plan) return 'go'
  const reviewed = run.ledger.some(entry => entry.n === 'branch-review' && entry.status === 'done')
  if (reviewed && run.stage !== 'finish') return 'merge / PR / keep / discard'
  return undefined
}

// flow-state's resolution: the first entry of `git worktree list --porcelain` is the main checkout.
export function mainCheckout(porcelain: string): string | undefined {
  const first = porcelain.split('\n')[0] ?? ''
  const path = first.startsWith('worktree ') ? first.slice('worktree '.length) : ''
  return path === '' ? undefined : path
}

export function stateFile(checkout: string): string {
  return `${checkout}/.flow/run/state.json`
}

export function shortSha(sha: string): string {
  return sha.slice(0, 7)
}

// The latest ledger entry `started` with a task number; a named gate entry (`branch-review`) is not a task.
export function startedTask(run: PulpitRun | null): string | undefined {
  return run?.ledger.filter(entry => entry.status === 'started' && /^\d+$/.test(entry.n)).at(-1)?.n
}

// The caller passes only a type that writes (see writerOf).
export function writerLine(writer: string | null, run: PulpitRun | null): string {
  if (writer === null) return 'writes: controller'
  if (writer !== 'implementer' || run === null) return `writes: ${writer}`
  const task = startedTask(run)
  const where = run.worktree?.split('/').filter(Boolean).at(-1)
  return ['writes: implementer', task && `task ${task}`, where].filter(Boolean).join(' · ')
}

// At most two rows: the gate, then the writer. Nothing without a run.
export function bandLines(run: PulpitRun | null, writer: string | null): string[] {
  if (run === null) return []
  const gate = gateOf(run)
  return [gate && `✋ ${gate}`, writerLine(writer, run)].filter((line): line is string => Boolean(line))
}

// hooks/flow-context READ_ONLY_AGENTS: every other type counts as a writer, the same default.
const READ_ONLY_AGENTS = new Set(['branch-reviewer', 'plan-red-team', 'explorer', 'Explore'])
// `ended` is ours: the engine drops a subagent from `$.agent.list()` when it ends (probed on 2.1.296 with `claude -p`: running, then
// absent, never `completed`), so a running row that leaves the list ended without us knowing how.
const FINISHED = new Set(['completed', 'failed', 'killed', 'ended'])
const KEPT_FINISHED = 6
// A spawn joins the list a moment later; a row younger than this is not yet missed from it.
const LISTING_GRACE_MS = 2000

export const isFinished = (row: PulpitAgent) => FINISHED.has(row.status)

export function addAgent(rows: PulpitAgent[], row: PulpitAgent): PulpitAgent[] {
  return [...rows.filter(existing => existing.id !== row.id), row]
}

// Returns `rows` itself when the step changes nothing, so the caller can skip the write.
export function stepAgent(rows: PulpitAgent[], id: string, model: string, effort: PulpitAgent['effort']): PulpitAgent[] {
  const row = rows.find(existing => existing.id === id)
  if (row === undefined || (row.model === model && row.effort === effort)) return rows
  const { effort: _before, ...rest } = row
  return rows.map(existing => (existing === row ? { ...rest, model, ...(effort === undefined ? {} : { effort }) } : existing))
}

// Takes each row's status from `$.agent.list()`, stamps when it finished or resumed, drops the oldest finished rows beyond the last 6.
// Returns `rows` itself when nothing changed. A running row the list stops naming has `ended`; a finished one stays as it was.
export function syncAgents(rows: PulpitAgent[], listed: readonly { id: string; status: string }[], now: number): PulpitAgent[] {
  const status = new Map(listed.map(entry => [entry.id, entry.status]))
  let isChanged = false
  const synced = rows.map(row => {
    const seen = status.get(row.id)
    if (seen === undefined && !isFinished(row) && now - row.startedAt >= LISTING_GRACE_MS) {
      isChanged = true
      return { ...row, status: 'ended', endedAt: now }
    }
    if (seen === undefined || seen === row.status) return row
    isChanged = true
    const updated = { ...row, status: seen }
    if (isFinished(updated) && !isFinished(row)) return { ...updated, endedAt: now }
    if (!isFinished(updated) && isFinished(row)) {
      const { endedAt: _ended, ...running } = updated
      return { ...running, startedAt: now }
    }
    return updated
  })
  const finished = synced.filter(isFinished).sort((a, b) => (a.endedAt ?? 0) - (b.endedAt ?? 0))
  const dropped = new Set(finished.slice(0, Math.max(0, finished.length - KEPT_FINISHED)))
  if (dropped.size > 0) return synced.filter(row => !dropped.has(row))
  return isChanged ? synced : rows
}

// The type of the latest spawned subagent in flight that may write; null leaves the controller the writer.
export function writerOf(rows: PulpitAgent[]): string | null {
  return rows.filter(row => row.status === 'running' && !READ_ONLY_AGENTS.has(row.type)).at(-1)?.type ?? null
}

export function formatDuration(ms: number): string {
  const seconds = Math.max(0, Math.floor(ms / 1000))
  const two = (n: number) => String(n).padStart(2, '0')
  if (seconds < 60) return `${seconds}s`
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m${two(seconds % 60)}s`
  return `${Math.floor(seconds / 3600)}h${two(Math.floor((seconds % 3600) / 60))}m`
}

// One Roles row: role · task · model · effort · description · clock, or what it ended as and how long it took.
export function agentLine(row: PulpitAgent, now: number): string {
  const label = { completed: 'done', failed: 'failed', killed: 'failed', ended: 'ended' }[row.status]
  const tail = label === undefined ? formatDuration(now - row.startedAt) : `${label} ${formatDuration((row.endedAt ?? now) - row.startedAt)}`
  return [row.type, row.task && `task ${row.task}`, row.model, row.effort, row.description, tail]
    .filter(part => part !== undefined && part !== '')
    .join(' · ')
}
