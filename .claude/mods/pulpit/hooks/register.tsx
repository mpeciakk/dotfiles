import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, Timer } from 'claude-code'

import type { PulpitAgent, PulpitRun } from '../types'
import {
  PANE_ID,
  addAgent,
  agentLine,
  bandLines,
  gateOf,
  isFinished,
  mainCheckout,
  parseRun,
  shortSha,
  startedTask,
  stateFile,
  stepAgent,
  syncAgents,
  writerLine,
  writerOf,
} from './core'

const run = atom({ plugin: 'pulpit', key: 'run' } as const, null)
const writer = atom({ plugin: 'pulpit', key: 'writer' } as const, null)
const hasOpened = atom({ plugin: 'pulpit', key: 'hasOpened' } as const, false)
const agents = atom({ plugin: 'pulpit', key: 'agents' } as const, [])
const now = atom({ plugin: 'pulpit', key: 'now' } as const, 0)

const POLL_MS = 2000
const CLOCK_MS = 1000

// What the poll remembers between ticks: which root the state file was resolved for, and the mtime it was last parsed at.
type Poll = { root?: string; path?: string; mtimeMs?: number }

async function stateFileOf($: EngineInterface, root: string): Promise<string | undefined> {
  const listing = await $.process.run(['git', 'worktree', 'list', '--porcelain'], { cwd: root })
  const checkout = listing.exitCode === 0 ? mainCheckout(listing.stdout) : undefined
  return checkout && stateFile(checkout)
}

// Any failure (git missing, no file, malformed JSON) hides the Run panel: never an error line.
async function refresh($: EngineInterface, poll: Poll) {
  let found: PulpitRun | null = null
  try {
    const root = await $.session.root()
    if (root !== poll.root) {
      poll.path = await stateFileOf($, root)
      poll.root = root
      poll.mtimeMs = undefined
    }
    if (poll.path !== undefined) {
      const { mtimeMs } = await $.fs.stat(poll.path)
      if (mtimeMs === poll.mtimeMs) return
      poll.mtimeMs = mtimeMs
      found = parseRun(await $.fs.read(poll.path)) ?? null
    }
  } catch {
    poll.mtimeMs = undefined
  }
  const current = await read($, run)
  if (JSON.stringify(current) !== JSON.stringify(found)) await update($, run, () => found)
}

// The writer the agent rows imply; its own atom because the panel and the band read it without the rows.
async function publishWriter($: EngineInterface) {
  const who = writerOf(await read($, agents))
  if ((await read($, writer)) !== who) await update($, writer, () => who)
}

// Statuses come from `$.agent.list()`; the clock atom moves while an agent is in flight so open drawings redraw.
async function syncAgentRows($: EngineInterface) {
  try {
    const listed = await $.agent.list()
    const at = await $.clock.now()
    const rows = await read($, agents)
    if (syncAgents(rows, listed, at) !== rows) await update($, agents, current => syncAgents(current, listed, at))
    if ((await read($, agents)).some(row => !isFinished(row))) await update($, now, () => at)
    await publishWriter($)
  } catch {
    // an agent list that fails leaves the rows as they were, never an error line
  }
}

type Spawned = Pick<PulpitAgent, 'id' | 'type' | 'description' | 'model'>

// The run is re-read first: the ledger may have changed within the poll interval before the dispatch.
async function trackSpawn($: EngineInterface, poll: Poll, spawned: Spawned) {
  await refresh($, poll)
  const at = await $.clock.now()
  const task = spawned.type === 'implementer' ? startedTask(await read($, run)) : undefined
  const row: PulpitAgent = { ...spawned, status: 'running', startedAt: at, ...(task === undefined ? {} : { task }) }
  await update($, agents, rows => addAgent(rows, row))
  await update($, now, () => at)
  await publishWriter($)
}

async function trackStep($: EngineInterface, agentId: string, model: string, effort: PulpitAgent['effort']) {
  const rows = await read($, agents)
  if (stepAgent(rows, agentId, model, effort) !== rows) await update($, agents, current => stepAgent(current, agentId, model, effort))
}

// The pane waits undrawn on a narrow terminal and is still listed, so listed means open.
async function openUnlessClosed($: EngineInterface) {
  const isListed = (await $.ui.panes()).some(pane => pane.id === PANE_ID)
  // session.start runs again on every module reload: a pane opened before and gone now was closed by the person.
  if (isListed || !(await read($, hasOpened))) {
    await update($, hasOpened, () => true)
    if (!isListed) void $.ui.open({ id: PANE_ID, title: PANE_ID })
  }
}

export const register: Register = on => {
  const poll: Poll = {}
  let tick: Timer | undefined
  let clockTick: Timer | undefined

  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'pulpit', description: 'Toggle the pulpit dashboard pane' })
    await refresh($, poll)
    tick?.cancel()
    tick = $.clock.every(POLL_MS, () => refresh($, poll))
    clockTick?.cancel()
    clockTick = $.clock.every(CLOCK_MS, () => syncAgentRows($))
    await openUnlessClosed($)

    return next(e)
  })

  // Observers: the result of `next` is passed on unchanged; the `.catch` replays it if the bookkeeping throws.
  on('agent.spawn', async ($, e, next) => {
    const result = await next(e)
    if (result.deny === undefined && result.agentId !== undefined) {
      await trackSpawn($, poll, { id: result.agentId, type: e.subagentType, description: e.description, model: result.model })
    }

    return result
  }).catch(($, e, next) => next(e))

  on('turn.step', async function* ($, e, next) {
    if (e.agentId !== undefined) await trackStep($, e.agentId, e.model, e.effort)

    return yield* next(e)
  }).catch(async function* ($, e, next) {
    return yield* next(e)
  })

  on('command.run', { command: 'pulpit' }, async $ => {
    const isPlaced = (await $.ui.panes()).some(pane => pane.id === PANE_ID && pane.isPlaced)
    if (isPlaced) {
      await $.ui.close({ id: PANE_ID })
      // the band reads isPlaced while drawing; nothing else redraws it after a close
      $.ui.invalidate('ui.render')

      return { text: 'pulpit closed.' }
    }
    await $.ui.open({ id: PANE_ID, title: PANE_ID })
    $.ui.invalidate('ui.render')

    return { text: 'pulpit opened.' }
  })

  on('ui.render', { component: 'Pane', requestId: PANE_ID }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const current = await read($, run)
    const who = await read($, writer)
    const rows = await read($, agents)
    const clock = await read($, now)
    const gate = current === null ? undefined : gateOf(current)

    return (
      <Box flexDirection="column">
        {current === null && who === null && rows.length === 0 && <Text dimColor>no active run</Text>}
        {current !== null && (
          <Box flexDirection="column" marginBottom={1}>
            <Text bold>Run</Text>
            <Text>
              {current.task} · {current.stage}
            </Text>
            {gate !== undefined && (
              <Text bold color="warning">
                ✋ {gate}
              </Text>
            )}
            {current.ledger.map(entry => (
              <Text
                {...(entry.status === 'blocked' ? { color: 'error' } : {})}
                {...(entry.status === 'done' ? { dimColor: true } : {})}
              >
                {/^\d+$/.test(entry.n) ? `task ${entry.n}` : entry.n} · {entry.status}
                {entry.note ? ` — ${entry.note}` : ''}
              </Text>
            ))}
            {current.worktree && <Text dimColor>worktree {current.worktree}</Text>}
            {current.branch && <Text dimColor>branch {current.branch}</Text>}
            {current.base && <Text dimColor>base {shortSha(current.base)}</Text>}
          </Box>
        )}
        {(current !== null || who !== null) && (
          <Box flexDirection="column">
            <Text bold>Writer</Text>
            <Text>{writerLine(who, current)}</Text>
          </Box>
        )}
        {rows.length > 0 && (
          <Box flexDirection="column" marginTop={1}>
            <Text bold>Roles</Text>
            {rows.map(row => (
              <Text
                {...(row.status === 'failed' || row.status === 'killed' ? { color: 'error' } : {})}
                {...(row.status === 'completed' || row.status === 'ended' ? { dimColor: true } : {})}
              >
                {agentLine(row, clock)}
              </Text>
            ))}
          </Box>
        )}
      </Box>
    )
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const isPlaced = (await $.ui.panes()).some(pane => pane.id === PANE_ID && pane.isPlaced)
    if (e.props.hasSurvey || isPlaced) return next(e)
    const lines = bandLines(await read($, run), await read($, writer))
    if (lines.length === 0) return next(e)
    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box flexDirection="column">
        {lines.map(line => (
          <Text>{line}</Text>
        ))}
      </Box>
    )
  })
}
