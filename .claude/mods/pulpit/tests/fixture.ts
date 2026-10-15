// A world beneath the plugin: fs, git, the session root and the pane list answered from memory,
// each call counted so a test can say what the mod did and did not ask for.
import { mock } from 'claude-code/testing'
import type { Engine, MockClock } from 'claude-code/testing'
import type { On } from 'claude-code'

export const MAIN = '/home/m/proj'
export const LINKED = '/home/m/proj/.claude/worktrees/feat'
export const STATE = `${MAIN}/.flow/run/state.json`

export const PORCELAIN = (...paths: string[]) =>
  paths.map(path => `worktree ${path}\nHEAD aaaaaaaa\nbranch refs/heads/x\n`).join('\n')

export type World = {
  clock: MockClock
  calls: { read: number; stat: number; git: number; open: number; close: number }
  gitCwds: string[]
  statPaths: string[]
  /** What the file holds from now on; undefined is a missing file. */
  setFile: (text: string | undefined) => void
  /** While false, fs.stat answers but fs.read refuses: a file caught mid-replace. */
  setReadable: (isReadable: boolean) => void
  setRoot: (root: string) => void
  /** Ids of the panes the engine lists, placed or not. */
  setPanes: (panes: { id: string; isPlaced: boolean }[]) => void
  /** The status `$.agent.list()` gives an agent from now on; the agent must have been spawned. */
  setAgentStatus: (id: string, status: string) => void
  /** What the engine's own `tool.check` decides from now on (the bottom of the chain). */
  setVerdict: (result: { decision: 'allow' | 'ask' | 'deny'; reason?: string; rule?: string; hook?: string }) => void
  /** The server tool calls the model's next responses carry. */
  setServerToolUses: (uses: { id: string; name: string; input: unknown; startedAt: number; endedAt?: number }[]) => void
  /** The engine drops an agent from `$.agent.list()` when it ends. */
  dropAgent: (id: string) => void
}

export function world($: Engine, on: On, init: { root?: string; file?: string; worktrees?: string[] } = {}): World {
  const clock = mock.clock(on, { now: 1_000_000 })
  let root = init.root ?? MAIN
  let file = init.file
  let mtimeMs = 1
  let isReadable = true
  let panes: { id: string; isPlaced: boolean }[] = []
  const calls = { read: 0, stat: 0, git: 0, open: 0, close: 0 }
  const gitCwds: string[] = []
  const statPaths: string[] = []
  const agents = new Map<string, { type: string; description: string; status: string }>()
  let spawned = 0
  let verdict: Parameters<World['setVerdict']>[0] = { decision: 'allow' }
  let serverToolUses: Parameters<World['setServerToolUses']>[0] = []

  on('session.start', (_$, e) => ({ cwd: e.cwd }))
  on('command.register', (_$, e) => ({ value: { command: e.name } }))
  // What the engine would draw itself where the plugin passes: nothing of ours.
  on('ui.render', () => ({ type: 'Box' as const, props: {}, children: [] }))
  on('session.root', () => ({ value: root }))
  on('session.cwd', () => ({ value: root }))
  on('process.run', (_$, e) => {
    calls.git += 1
    gitCwds.push(e.init?.cwd ?? '')
    const out = PORCELAIN(...(init.worktrees ?? [MAIN]))
    return { value: { exitCode: 0, stdout: out, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  on('fs.stat', (_$, e) => {
    calls.stat += 1
    statPaths.push(e.path)
    if (file === undefined) return { deny: 'ENOENT' }
    return { value: { kind: 'file' as const, size: file.length, mtimeMs, isLink: false } }
  })
  on('fs.read', (_$, e) => {
    calls.read += 1
    if (file === undefined || e.path !== STATE || !isReadable) return { deny: 'ENOENT' }
    return { value: file }
  })
  // Ids are agent-1, agent-2, ... in spawn order; a spawn joins the list as running, as the engine's does.
  on('agent.spawn', (_$, e) => {
    spawned += 1
    const agentId = `agent-${spawned}`
    agents.set(agentId, { type: e.subagentType, description: e.description, status: 'running' })
    return { model: e.model ?? 'claude-sonnet-5-5', agentId }
  })
  on('agent.list', () => ({ value: [...agents].map(([id, agent]) => ({ id, ...agent })) }))
  // A model request that answers at once; the hook under test sees the input on its way down.
  on('turn.step', async function* (_$, e) {
    return { turnId: e.turnId, index: e.index, answer: '', toolUses: [], serverToolUses, stopReason: 'end_turn' as const, usage: null }
  })
  on('prompt.submit', (_$, e) => ({ text: e.text, origin: e.origin }))
  on('turn.complete', () => ({ text: '' }))
  on('tool.check', () => verdict)
  on('classic.PermissionDenied', () => ({}))
  on('ui.open', (_$, e) => {
    calls.open += 1
    if (!panes.some(pane => pane.id === e.id)) panes = [...panes, { id: e.id, isPlaced: true }]
    return { value: { isPlaced: true as const } }
  })
  on('ui.close', (_$, e) => {
    calls.close += 1
    panes = panes.filter(pane => pane.id !== e.id)
    return { value: undefined }
  })
  on('ui.panes', () => ({
    value: panes.map(pane => ({ id: pane.id, title: pane.id, isShown: true, isFocused: false, isPlaced: pane.isPlaced })),
  }))

  return {
    clock,
    calls,
    gitCwds,
    statPaths,
    setFile: text => {
      if (text !== file) mtimeMs += 1
      file = text
    },
    setReadable: next => {
      isReadable = next
    },
    setRoot: next => {
      root = next
    },
    setPanes: next => {
      panes = next
    },
    setVerdict: next => {
      verdict = next
    },
    setServerToolUses: next => {
      serverToolUses = next
    },
    dropAgent: id => {
      agents.delete(id)
    },
    setAgentStatus: (id, status) => {
      const agent = agents.get(id)
      if (agent === undefined) throw new Error(`no agent ${id} was spawned`)
      agent.status = status
    },
  }
}
