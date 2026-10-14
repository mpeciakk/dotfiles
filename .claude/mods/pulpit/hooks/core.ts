// Pure parts of pulpit: no `$`, no drawing. Reducers and formatters the hooks in register.tsx lean on.
import type { PulpitLedgerEntry, PulpitRun } from '../types'

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

// Read-only types are flow-context's READ_ONLY_AGENTS; every other type counts as a writer, so the
// caller passes only a type that does (Task 2 decides which).
export function writerLine(writer: string | null, run: PulpitRun | null): string {
  if (writer === null) return 'writes: controller'
  if (writer !== 'implementer' || run === null) return `writes: ${writer}`
  const started = run.ledger.filter(entry => entry.status === 'started' && /^\d+$/.test(entry.n)).at(-1)
  const where = run.worktree?.split('/').filter(Boolean).at(-1)
  return ['writes: implementer', started && `task ${started.n}`, where].filter(Boolean).join(' · ')
}

// At most two rows: the gate, then the writer. Nothing without a run.
export function bandLines(run: PulpitRun | null, writer: string | null): string[] {
  if (run === null) return []
  const gate = gateOf(run)
  return [gate && `✋ ${gate}`, writerLine(writer, run)].filter((line): line is string => Boolean(line))
}
