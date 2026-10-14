import { describe, expect, test } from 'claude-code/testing'

import {
  addAgent,
  agentLine,
  bandLines,
  formatDuration,
  gateOf,
  mainCheckout,
  parseRun,
  shortSha,
  startedTask,
  stateFile,
  stepAgent,
  syncAgents,
  writerLine,
  writerOf,
} from '../hooks/core'
import type { PulpitAgent } from '../types'

// What `flow-state` writes (json.dump(sort_keys=True)), one run per stage.
const run = (fields: Record<string, unknown>) => JSON.stringify({ task: 'x', tasks: [], ...fields })

describe('parseRun', () => {
  test('reads task, stage, paths and the ledger as flow-state writes them', () => {
    const parsed = parseRun(
      run({
        stage: 'implement',
        plan: '/p/plan.md',
        worktree: '/w/x',
        branch: 'feat/x',
        base: 'abcdef0123456789',
        tasks: [
          { n: '1', status: 'done', note: 'base=abc' },
          { n: '2', status: 'started' },
        ],
      }),
    )
    expect(parsed).toEqual({
      task: 'x',
      stage: 'implement',
      plan: '/p/plan.md',
      worktree: '/w/x',
      branch: 'feat/x',
      base: 'abcdef0123456789',
      ledger: [
        { n: '1', status: 'done', note: 'base=abc' },
        { n: '2', status: 'started' },
      ],
    })
  })

  test('a run just after init has an empty ledger', () => {
    expect(parseRun(run({ stage: 'triage' }))?.ledger).toEqual([])
  })

  test('a numeric task number is kept as text', () => {
    expect(parseRun(run({ stage: 'implement', tasks: [{ n: 3, status: 'done' }] }))?.ledger).toEqual([
      { n: '3', status: 'done' },
    ])
  })

  test('malformed text is no run', () => {
    expect(parseRun('{ not json')).toBeUndefined()
    expect(parseRun('')).toBeUndefined()
    expect(parseRun('[]')).toBeUndefined()
    expect(parseRun('"x"')).toBeUndefined()
  })

  // flow-state's load_at treats a wrongly typed stage / worktree / branch / task as unusable.
  test('a field of the wrong type is no run', () => {
    expect(parseRun(JSON.stringify({ task: 'x', stage: 3 }))).toBeUndefined()
    expect(parseRun(JSON.stringify({ task: 'x', stage: 'plan', worktree: 7 }))).toBeUndefined()
    expect(parseRun(JSON.stringify({ task: ['x'], stage: 'plan' }))).toBeUndefined()
  })

  test('ledger entries that are not objects are skipped, a ledger that is not a list is empty', () => {
    expect(parseRun(run({ stage: 'plan', tasks: [null, 'x', { n: '1', status: 'done' }] }))?.ledger).toEqual([
      { n: '1', status: 'done' },
    ])
    expect(parseRun(run({ stage: 'plan', tasks: 'oops' }))?.ledger).toEqual([])
  })
})

describe('gateOf', () => {
  const at = (fields: Record<string, unknown>) => parseRun(run(fields))!

  test('stage plan with a recorded plan waits for go', () => {
    expect(gateOf(at({ stage: 'plan', plan: '/p.md' }))).toBe('go')
  })

  test('stage plan without a plan is not yet at the gate', () => {
    expect(gateOf(at({ stage: 'plan' }))).toBeUndefined()
  })

  test('branch-review done and stage not finish waits for merge / PR / keep / discard', () => {
    expect(
      gateOf(at({ stage: 'implement', tasks: [{ n: '1', status: 'done' }, { n: 'branch-review', status: 'done' }] })),
    ).toBe('merge / PR / keep / discard')
  })

  test('branch-review only started is not the gate', () => {
    expect(gateOf(at({ stage: 'implement', tasks: [{ n: 'branch-review', status: 'started' }] }))).toBeUndefined()
  })

  test('stage finish clears the merge gate', () => {
    expect(gateOf(at({ stage: 'finish', tasks: [{ n: 'branch-review', status: 'done' }] }))).toBeUndefined()
  })

  test('other stages have no gate', () => {
    for (const stage of ['triage', 'design', 'isolate', 'implement', 'inline']) {
      expect(gateOf(at({ stage, plan: '/p.md' }))).toBeUndefined()
    }
  })
})

describe('mainCheckout', () => {
  test('is the first entry of git worktree list --porcelain, from a linked worktree too', () => {
    const out = [
      'worktree /home/m/dotfiles',
      'HEAD aaaaaaaa',
      'branch refs/heads/main',
      '',
      'worktree /home/m/dotfiles/.claude/worktrees/feat+pulpit',
      'HEAD bbbbbbbb',
      'branch refs/heads/worktree-feat+pulpit',
      '',
    ].join('\n')
    expect(mainCheckout(out)).toBe('/home/m/dotfiles')
  })

  test('keeps spaces in the path', () => {
    expect(mainCheckout('worktree /home/m/my project\nHEAD aa\n')).toBe('/home/m/my project')
  })

  test('is undefined for output that names no worktree', () => {
    expect(mainCheckout('')).toBeUndefined()
    expect(mainCheckout('fatal: not a git repository')).toBeUndefined()
  })
})

describe('stateFile', () => {
  test('is under .flow/run of the main checkout', () => {
    expect(stateFile('/home/m/dotfiles')).toBe('/home/m/dotfiles/.flow/run/state.json')
  })
})

describe('shortSha', () => {
  test('cuts to 7 characters', () => {
    expect(shortSha('abcdef0123456789')).toBe('abcdef0')
  })
  test('leaves a shorter value alone', () => {
    expect(shortSha('abc')).toBe('abc')
  })
})

describe('writerLine', () => {
  const run1 = parseRun(
    run({
      stage: 'implement',
      worktree: '/home/m/dotfiles/.claude/worktrees/feat+pulpit',
      tasks: [{ n: '1', status: 'done' }, { n: '2', status: 'started' }, { n: 'branch-review', status: 'started' }],
    }),
  )!

  test('is the controller when no writer subagent runs', () => {
    expect(writerLine(null, run1)).toBe('writes: controller')
    expect(writerLine(null, null)).toBe('writes: controller')
  })

  test('an implementer carries the latest started task number and the worktree name', () => {
    expect(writerLine('implementer', run1)).toBe('writes: implementer · task 2 · feat+pulpit')
  })

  test('an implementer without a run is named alone', () => {
    expect(writerLine('implementer', null)).toBe('writes: implementer')
  })

  test('another writer type is named alone', () => {
    expect(writerLine('general-purpose', run1)).toBe('writes: general-purpose')
  })
})

describe('bandLines', () => {
  const at = (fields: Record<string, unknown>) => parseRun(run(fields))!

  test('is empty without a run', () => {
    expect(bandLines(null, null)).toEqual([])
  })

  test('a run without a gate is the writer line alone', () => {
    expect(bandLines(at({ stage: 'implement' }), null)).toEqual(['writes: controller'])
  })

  test('a pending gate comes first, the writer second: two rows at most', () => {
    const lines = bandLines(at({ stage: 'plan', plan: '/p.md' }), 'implementer')
    expect(lines).toEqual(['✋ go', 'writes: implementer'])
  })
})

const agent = (fields: Partial<PulpitAgent> & { id: string }): PulpitAgent => ({
  type: 'implementer',
  description: 'do it',
  model: 'claude-sonnet-5-5',
  status: 'running',
  startedAt: 1000,
  ...fields,
})

describe('startedTask', () => {
  test('is the latest started ledger entry with a number, a named gate entry never counts', () => {
    const at = parseRun(run({ tasks: [{ n: '1', status: 'started' }, { n: '2', status: 'done' }, { n: 'branch-review', status: 'started' }] }))!
    expect(startedTask(at)).toBe('1')
    expect(startedTask(parseRun(run({}))!)).toBeUndefined()
    expect(startedTask(null)).toBeUndefined()
  })
})

describe('addAgent', () => {
  test('appends a row, and a replayed spawn replaces the row of that id instead of doubling it', () => {
    const once = addAgent([], agent({ id: 'a' }))
    expect(once.map(row => row.id)).toEqual(['a'])
    const twice = addAgent(once, agent({ id: 'a', description: 'replayed' }))
    expect(twice).toHaveLength(1)
    expect(twice[0]?.description).toBe('replayed')
  })
})

describe('stepAgent', () => {
  test('sets the model and effort a step was sent with, on the row of that agent only', () => {
    const rows = [agent({ id: 'a' }), agent({ id: 'b' })]
    const out = stepAgent(rows, 'a', 'claude-opus-5-5', 'high')
    expect(out[0]).toMatchObject({ model: 'claude-opus-5-5', effort: 'high' })
    expect(out[1]).toEqual(rows[1])
  })

  test('a step without effort drops an effort an earlier step carried', () => {
    const out = stepAgent([agent({ id: 'a', effort: 'high' })], 'a', 'claude-haiku-5', undefined)
    expect(out[0]?.effort).toBeUndefined()
  })

  test('returns the same array when nothing changes or the agent is unknown', () => {
    const rows = [agent({ id: 'a', effort: 'high' })]
    expect(stepAgent(rows, 'a', 'claude-sonnet-5-5', 'high')).toBe(rows)
    expect(stepAgent(rows, 'zzz', 'x', 'low')).toBe(rows)
  })
})

describe('syncAgents', () => {
  test('completed stamps the end time once, and failed or killed likewise', () => {
    const rows = [agent({ id: 'a' }), agent({ id: 'b' }), agent({ id: 'c' })]
    const done = syncAgents(
      rows,
      [{ id: 'a', status: 'completed' }, { id: 'b', status: 'failed' }, { id: 'c', status: 'killed' }],
      5000,
    )
    expect(done.map(row => [row.status, row.endedAt])).toEqual([['completed', 5000], ['failed', 5000], ['killed', 5000]])
    const later = syncAgents(done, [{ id: 'a', status: 'completed' }], 9000)
    expect(later.find(row => row.id === 'a')?.endedAt).toBe(5000)
  })

  test('a finished agent that runs again (resumed) restarts its clock and loses its end time', () => {
    const rows = [agent({ id: 'a', status: 'completed', startedAt: 1000, endedAt: 5000 })]
    const out = syncAgents(rows, [{ id: 'a', status: 'running' }], 8000)
    expect(out[0]).toMatchObject({ status: 'running', startedAt: 8000 })
    expect(out[0]?.endedAt).toBeUndefined()
  })

  test('returns the same array when no status changed', () => {
    const rows = [agent({ id: 'a' })]
    expect(syncAgents(rows, [{ id: 'a', status: 'running' }], 2000)).toBe(rows)
  })

  test('a running agent the list does not name yet keeps its row for the first 2 seconds', () => {
    const rows = [agent({ id: 'a', startedAt: 1000 })]
    expect(syncAgents(rows, [], 2999)).toBe(rows)
  })

  // The engine drops a subagent from the list when it ends (probed: running, then absent, never completed).
  test('a running agent that stays off the list has ended: neither done nor failed, stamped when noticed', () => {
    const rows = [agent({ id: 'a', startedAt: 1000 })]
    const out = syncAgents(rows, [], 3000)
    expect(out[0]).toMatchObject({ status: 'ended', endedAt: 3000 })
  })

  test('an ended agent that is listed again is running again, its clock restarted', () => {
    const rows = [agent({ id: 'a', status: 'ended', startedAt: 1000, endedAt: 3000 })]
    const out = syncAgents(rows, [{ id: 'a', status: 'running' }], 9000)
    expect(out[0]).toMatchObject({ status: 'running', startedAt: 9000 })
    expect(out[0]?.endedAt).toBeUndefined()
  })

  test('a finished agent the list does not name keeps its row as it was', () => {
    const rows = [agent({ id: 'a', status: 'completed', endedAt: 2000 })]
    expect(syncAgents(rows, [], 99_000)).toBe(rows)
  })

  test('only the last 6 finished rows stay, the oldest by end time go, running ones always stay', () => {
    const rows = Array.from({ length: 8 }, (_, i) => agent({ id: `d${i}`, status: 'completed', startedAt: 0, endedAt: 100 + i }))
    rows.push(agent({ id: 'live' }))
    const out = syncAgents(rows, [{ id: 'live', status: 'running' }, { id: 'd7', status: 'failed' }], 9000)
    expect(out.map(row => row.id)).toEqual(['d2', 'd3', 'd4', 'd5', 'd6', 'd7', 'live'])
  })
})

describe('writerOf', () => {
  test('is null with nothing in flight, and finished agents do not count', () => {
    expect(writerOf([])).toBeNull()
    expect(writerOf([agent({ id: 'a', status: 'completed', endedAt: 5 })])).toBeNull()
  })

  test('a read-only type in flight leaves the controller the writer', () => {
    for (const type of ['branch-reviewer', 'plan-red-team', 'explorer', 'Explore']) {
      expect(writerOf([agent({ id: 'a', type })])).toBeNull()
    }
  })

  test('any other type in flight is a writer, the latest spawned one wins', () => {
    expect(writerOf([agent({ id: 'a', type: 'general-purpose' })])).toBe('general-purpose')
    const rows = [agent({ id: 'a', type: 'implementer' }), agent({ id: 'b', type: 'explorer' }), agent({ id: 'c', type: 'claude' })]
    expect(writerOf(rows)).toBe('claude')
  })

  test('only a running agent counts, a pending or idle one does not', () => {
    expect(writerOf([agent({ id: 'a', status: 'idle' })])).toBeNull()
  })
})

describe('formatDuration', () => {
  test('seconds below a minute, minutes and seconds below an hour, then hours and minutes', () => {
    expect(formatDuration(0)).toBe('0s')
    expect(formatDuration(59_999)).toBe('59s')
    expect(formatDuration(62_000)).toBe('1m02s')
    expect(formatDuration(3_600_000)).toBe('1h00m')
    expect(formatDuration(3_725_000)).toBe('1h02m')
  })

  test('a clock that ran backwards shows 0s', () => {
    expect(formatDuration(-5000)).toBe('0s')
  })
})

describe('agentLine', () => {
  test('a running implementer: role, task, model and effort, description, a live clock', () => {
    const row = agent({ id: 'a', task: '2', effort: 'high', description: 'Roles panel' })
    expect(agentLine(row, 13_000)).toBe('implementer · task 2 · claude-sonnet-5-5 · high · Roles panel · 12s')
  })

  test('without effort only the model is shown', () => {
    expect(agentLine(agent({ id: 'a', type: 'explorer' }), 2000)).toBe('explorer · claude-sonnet-5-5 · do it · 1s')
  })

  test('a numeric effort is shown as written', () => {
    expect(agentLine(agent({ id: 'a', type: 'x', effort: 8000 }), 1000)).toBe('x · claude-sonnet-5-5 · 8000 · do it · 0s')
  })

  test('a completed row shows done and its duration, not a clock', () => {
    const row = agent({ id: 'a', type: 'x', status: 'completed', startedAt: 1000, endedAt: 63_000 })
    expect(agentLine(row, 999_999)).toBe('x · claude-sonnet-5-5 · do it · done 1m02s')
  })

  test('an ended row (it left the list) shows ended and its duration', () => {
    const row = agent({ id: 'a', type: 'x', status: 'ended', startedAt: 1000, endedAt: 15_000 })
    expect(agentLine(row, 999_999)).toBe('x · claude-sonnet-5-5 · do it · ended 14s')
  })

  test('failed and killed both show failed', () => {
    for (const status of ['failed', 'killed']) {
      const row = agent({ id: 'a', type: 'x', status, startedAt: 0, endedAt: 3000 })
      expect(agentLine(row, 9999)).toBe('x · claude-sonnet-5-5 · do it · failed 3s')
    }
  })
})
