// Pure parts of pulpit: no `$`, no drawing. Reducers and formatters the hooks in register.tsx lean on.
import type {
  PulpitAdvisor,
  PulpitAgent,
  PulpitConsult,
  PulpitDenial,
  PulpitGate,
  PulpitLedgerEntry,
  PulpitMetrics,
  PulpitRun,
} from '../types'

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

const BAND_REASON_CHARS = 60

const agentsRunning = (count: number) => `${count} ${count === 1 ? 'agent' : 'agents'} running`

// At most two rows: the gate, the writer and the running count, then the latest denial. With all of them the gate shares the
// writer's row. The writer is named when there is a run or a writer in flight: "controller" alone is no news without a run.
export function bandLines(run: PulpitRun | null, writer: string | null, running = 0, denial: PulpitDenial | null = null): string[] {
  const gate = run === null ? undefined : gateOf(run)
  const who = run === null && writer === null ? undefined : writerLine(writer, run)
  const state = [who, running > 0 ? agentsRunning(running) : undefined].filter(Boolean).join(' · ')
  const reason = denial?.reason.replace(/\s+/g, ' ').trim().slice(0, BAND_REASON_CHARS)
  const denied = denial && ['denied:', denial.tool, reason && `— ${reason}`].filter(Boolean).join(' ')
  const lines = [gate && `✋ ${gate}`, state, denied].filter((line): line is string => Boolean(line))
  return lines.length > 2 ? [`${lines[0]} · ${lines[1]}`, ...lines.slice(2)] : lines
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

export const EMPTY_GATE: PulpitGate = { byRule: 0, byMode: 0, asked: 0, denied: 0, denials: [] }
export const EMPTY_ADVISOR: PulpitAdvisor = { count: 0, recent: [] }
const KEPT_DENIALS = 5
const KEPT_CONSULTS = 5

// Allow and ask only: a deny is addDenial's, because the same refusal may come again as a classic.PermissionDenied.
export function countVerdict(gate: PulpitGate, result: { decision: string; rule?: string }): PulpitGate {
  if (result.decision === 'ask') return { ...gate, asked: gate.asked + 1 }
  if (result.decision !== 'allow') return gate
  return result.rule === undefined ? { ...gate, byMode: gate.byMode + 1 } : { ...gate, byRule: gate.byRule + 1 }
}

// shortcut: dedup knows only the last 5 ids; a duplicate arriving after five newer denials counts again, never in practice.
export function addDenial(gate: PulpitGate, denial: PulpitDenial): PulpitGate {
  if (gate.denials.some(seen => seen.id === denial.id)) return gate
  return { ...gate, denied: gate.denied + 1, denials: [...gate.denials, denial].slice(-KEPT_DENIALS) }
}

export const gateCounts = (gate: PulpitGate) =>
  `allowed ${gate.byRule} by rule · ${gate.byMode} by mode · asked ${gate.asked} · denied ${gate.denied}`

export function formatClock(ms: number): string {
  const at = new Date(ms)
  return [at.getHours(), at.getMinutes(), at.getSeconds()].map(n => String(n).padStart(2, '0')).join(':')
}

export const denialLine = (denial: PulpitDenial) =>
  [formatClock(denial.at), denial.tool, denial.agentType, denial.reason].filter(part => part !== undefined && part !== '').join(' · ')

// Only the advisor's: a step lists every tool the API ran itself.
export function addConsults(
  advisor: PulpitAdvisor,
  uses: readonly { name: string; startedAt: number; endedAt?: number }[],
  stage: string,
): PulpitAdvisor {
  const consults = uses
    .filter(use => use.name === 'advisor')
    .map((use): PulpitConsult => ({
      startedAt: use.startedAt,
      stage,
      ...(use.endedAt === undefined ? {} : { durationMs: use.endedAt - use.startedAt }),
    }))
  if (consults.length === 0) return advisor
  return { count: advisor.count + consults.length, recent: [...advisor.recent, ...consults].slice(-KEPT_CONSULTS) }
}

export const consultLine = (consult: PulpitConsult) =>
  [formatClock(consult.startedAt), consult.durationMs === undefined ? '?' : formatDuration(consult.durationMs), consult.stage]
    .filter(part => part !== '')
    .join(' · ')

export const EMPTY_METRICS: PulpitMetrics = { run: '', stage: '', isCounting: false, interventions: 0, waitMs: 0 }
const PAST_PLAN = new Set(['isolate', 'implement', 'inline', 'finish'])
const GO_STAGES = new Set(['isolate', 'implement', 'inline'])

// Paths are compared as written: no realpath. A run with no worktree recorded (inline) was found from this session's own repo, so the
// session is inside it.
export function isInside(root: string | undefined, worktree: string | undefined): boolean {
  if (root === undefined) return false
  if (worktree === undefined) return true
  const base = worktree.replace(/\/+$/, '')
  return root === base || root.startsWith(`${base}/`)
}

// What one look at the run (and where the session is) does to the figures. No run keeps them: the read may have failed for a tick, and
// a go seen at that moment must not be lost; only a different task starts them again.
export function watchRun(metrics: PulpitMetrics, run: PulpitRun | null, root: string | undefined, at: number): PulpitMetrics {
  if (run === null) return metrics.isCounting ? { ...metrics, isCounting: false } : metrics
  const own = metrics.run === run.task ? metrics : { ...EMPTY_METRICS, run: run.task }
  const isCounting = PAST_PLAN.has(run.stage) && isInside(root, run.worktree)
  return {
    ...own,
    stage: run.stage,
    isCounting,
    ...(own.stage === 'plan' && GO_STAGES.has(run.stage) ? { goAt: at } : {}),
    ...(isCounting && own.joinedAt === undefined ? { joinedAt: at } : {}),
  }
}

export function addIntervention(metrics: PulpitMetrics, waitMs: number): PulpitMetrics {
  if (!metrics.isCounting) return metrics
  return { ...metrics, interventions: metrics.interventions + 1, waitMs: metrics.waitMs + waitMs }
}

// The wait a prompt ends: nothing without a turn end on record, and nothing while a subagent works (the person is not what is waited on).
export const userWait = (idleSince: number | null, at: number, hasRunning: boolean) =>
  idleSince === null || hasRunning ? 0 : Math.max(0, at - idleSince)

export function metricsLines(metrics: PulpitMetrics, now: number): string[] {
  if (!metrics.isCounting) return []
  const [label, since] = metrics.goAt === undefined ? ['since joined', metrics.joinedAt] : ['since go', metrics.goAt]
  return [
    `${label} ${formatDuration(now - (since ?? now))}`,
    `interventions ${metrics.interventions}`,
    `user wait ${formatDuration(metrics.waitMs)}`,
  ]
}
