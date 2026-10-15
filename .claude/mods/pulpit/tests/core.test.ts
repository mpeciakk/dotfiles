import { describe, expect, test } from 'claude-code/testing'

import {
  addAgent,
  addConsults,
  addDenial,
  addIntervention,
  agentLine,
  bandLines,
  consultLine,
  countVerdict,
  EMPTY_ADVISOR,
  EMPTY_GATE,
  EMPTY_METRICS,
  formatClock,
  formatDuration,
  gateCounts,
  gateOf,
  isInside,
  mainCheckout,
  metricsLines,
  parseRun,
  shortSha,
  startedTask,
  stateFile,
  stepAgent,
  syncAgents,
  userWait,
  watchRun,
  writerLine,
  writerOf,
} from '../hooks/core'
import type { PulpitAgent, PulpitDenial, PulpitMetrics, PulpitRun } from '../types'

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

  const denial = (fields: Partial<PulpitDenial> = {}): PulpitDenial => ({ id: 't1', at: 0, tool: 'Edit', reason: 'blocked by flow-guard', ...fields })

  test('the running agents count joins the writer row', () => {
    expect(bandLines(at({ stage: 'implement' }), null, 2)).toEqual(['writes: controller · 2 agents running'])
    expect(bandLines(at({ stage: 'implement' }), null, 1)).toEqual(['writes: controller · 1 agent running'])
  })

  test('the latest denial is a row of its own: tool and the first 60 characters of the reason', () => {
    const reason = 'x'.repeat(59) + 'yz-never-shown'
    expect(bandLines(at({ stage: 'implement' }), null, 0, denial({ reason }))).toEqual([
      'writes: controller',
      `denied: Edit — ${'x'.repeat(59)}y`,
    ])
  })

  test('a reason spanning lines is one row, and a missing reason leaves the tool alone', () => {
    expect(bandLines(at({ stage: 'implement' }), null, 0, denial({ reason: 'a\n  b' }))[1]).toBe('denied: Edit — a b')
    expect(bandLines(at({ stage: 'implement' }), null, 0, denial({ reason: '' }))[1]).toBe('denied: Edit')
  })

  test('gate, writer, count and denial fit two rows: the gate shares the writer row', () => {
    const lines = bandLines(at({ stage: 'plan', plan: '/p.md' }), null, 3, denial())
    expect(lines).toEqual(['✋ go · writes: controller · 3 agents running', 'denied: Edit — blocked by flow-guard'])
  })

  test('without a run the count and the denial still show, the writer only when one is in flight', () => {
    expect(bandLines(null, null, 1, denial())).toEqual(['1 agent running', 'denied: Edit — blocked by flow-guard'])
    expect(bandLines(null, null, 0, denial())).toEqual(['denied: Edit — blocked by flow-guard'])
    expect(bandLines(null, 'implementer', 1)).toEqual(['writes: implementer · 1 agent running'])
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

const entry = (fields: Partial<PulpitDenial> = {}): PulpitDenial => ({ id: 't1', at: 1000, tool: 'Bash', reason: 'no', ...fields })

describe('countVerdict', () => {
  test('an allow with a rule and an allow without one land in different counters', () => {
    let gate = countVerdict(EMPTY_GATE, { decision: 'allow', rule: 'Bash(git status:*)' })
    gate = countVerdict(gate, { decision: 'allow' })
    gate = countVerdict(gate, { decision: 'allow' })
    expect(gate).toMatchObject({ byRule: 1, byMode: 2, asked: 0, denied: 0 })
  })

  test('an ask counts as asked and changes nothing else', () => {
    expect(countVerdict(EMPTY_GATE, { decision: 'ask' })).toEqual({ ...EMPTY_GATE, asked: 1 })
  })

  test('a deny is not counted here: addDenial owns it, so a deny is never counted twice', () => {
    expect(countVerdict(EMPTY_GATE, { decision: 'deny', reason: 'x' })).toBe(EMPTY_GATE)
  })
})

describe('addDenial', () => {
  test('counts and keeps the denial with its reason', () => {
    const gate = addDenial(EMPTY_GATE, entry({ reason: 'flow-guard: state.json is the run record' }))
    expect(gate.denied).toBe(1)
    expect(gate.denials).toEqual([entry({ reason: 'flow-guard: state.json is the run record' })])
  })

  test('the same tool_use_id is one denial, whichever source came second', () => {
    const once = addDenial(EMPTY_GATE, entry({ id: 'toolu_9' }))
    const twice = addDenial(once, entry({ id: 'toolu_9', reason: 'classifier' }))
    expect(twice).toBe(once)
    expect(twice.denied).toBe(1)
  })

  test('the sixth denial evicts the oldest; the counter keeps counting', () => {
    let gate = EMPTY_GATE
    for (let i = 1; i <= 6; i++) gate = addDenial(gate, entry({ id: `t${i}`, tool: `T${i}` }))
    expect(gate.denied).toBe(6)
    expect(gate.denials.map(denial => denial.tool)).toEqual(['T2', 'T3', 'T4', 'T5', 'T6'])
  })

  test('a subagent type is kept with the denial', () => {
    const gate = addDenial(EMPTY_GATE, entry({ agentType: 'implementer' }))
    expect(gate.denials[0]?.agentType).toBe('implementer')
  })
})

describe('gateCounts', () => {
  test('one line: allowed by rule and by mode, asked, denied', () => {
    const gate = { ...EMPTY_GATE, byRule: 12, byMode: 3, asked: 1, denied: 2 }
    expect(gateCounts(gate)).toBe('allowed 12 by rule · 3 by mode · asked 1 · denied 2')
  })
})

describe('formatClock', () => {
  test('is the local time of day, zero-padded', () => {
    expect(formatClock(new Date(2026, 9, 15, 7, 5, 9).getTime())).toBe('07:05:09')
  })
})

describe('addConsults and consultLine', () => {
  const advisor = (startedAt: number, endedAt?: number) => ({
    id: 'srv_1',
    name: 'advisor',
    input: {},
    startedAt,
    ...(endedAt === undefined ? {} : { endedAt }),
  })
  const t0 = new Date(2026, 9, 15, 14, 0, 0).getTime()

  test('an advisor use adds a consult with duration and stage; another server tool adds nothing', () => {
    const got = addConsults(EMPTY_ADVISOR, [{ ...advisor(t0), id: 'a', name: 'web_search' }, advisor(t0, t0 + 12_000)], 'implement')
    expect(got.count).toBe(1)
    expect(consultLine(got.recent[0]!)).toBe('14:00:00 · 12s · implement')
  })

  test('no endedAt shows ? as the duration; no stage leaves the stage out', () => {
    const got = addConsults(EMPTY_ADVISOR, [advisor(t0)], '')
    expect(consultLine(got.recent[0]!)).toBe('14:00:00 · ?')
  })

  test('no uses returns the state itself', () => {
    expect(addConsults(EMPTY_ADVISOR, [], 'plan')).toBe(EMPTY_ADVISOR)
    expect(addConsults(EMPTY_ADVISOR, [{ ...advisor(t0), name: 'web_search' }], 'plan')).toBe(EMPTY_ADVISOR)
  })

  test('the count is the total, the lines are the latest five', () => {
    let got = EMPTY_ADVISOR
    for (let i = 0; i < 7; i++) got = addConsults(got, [advisor(t0 + i * 60_000, t0 + i * 60_000 + 1000)], 'plan')
    expect(got.count).toBe(7)
    expect(got.recent.map(consult => consultLine(consult).slice(0, 8))).toEqual(['14:02:00', '14:03:00', '14:04:00', '14:05:00', '14:06:00'])
  })
})

describe('isInside', () => {
  test('the worktree itself and anything beneath it; a sibling that shares the prefix is outside', () => {
    expect(isInside('/w/feat', '/w/feat')).toBe(true)
    expect(isInside('/w/feat/src/x', '/w/feat')).toBe(true)
    expect(isInside('/w/feat-two', '/w/feat')).toBe(false)
    expect(isInside('/home/m/proj', '/w/feat')).toBe(false)
  })

  test('a trailing slash on the worktree changes nothing', () => {
    expect(isInside('/w/feat/src', '/w/feat/')).toBe(true)
  })

  test('no worktree recorded: inside wherever the run was found; no root: outside', () => {
    expect(isInside('/home/m/proj', undefined)).toBe(true)
    expect(isInside(undefined, '/w/feat')).toBe(false)
    expect(isInside(undefined, undefined)).toBe(false)
  })
})

describe('watchRun', () => {
  const at = (stage: string, worktree?: string): PulpitRun => ({ task: 'x', stage, ledger: [], ...(worktree === undefined ? {} : { worktree }) })

  test('plan then isolate, implement or inline is a go, stamped when seen', () => {
    for (const stage of ['isolate', 'implement', 'inline']) {
      const planned = watchRun(EMPTY_METRICS, at('plan'), '/w', 100)
      expect(watchRun(planned, at(stage), '/w', 250).goAt).toBe(250)
    }
  })

  test('plan then design, and design then implement, are no go', () => {
    const planned = watchRun(EMPTY_METRICS, at('plan'), '/w', 100)
    const designed = watchRun(planned, at('design'), '/w', 200)
    expect(designed.goAt).toBeUndefined()
    expect(watchRun(designed, at('implement'), '/w', 300).goAt).toBeUndefined()
  })

  test('a run first seen past plan has no go and is joined when it is first counted', () => {
    const got = watchRun(EMPTY_METRICS, at('implement'), '/w', 100)
    expect(got).toMatchObject({ run: 'x', stage: 'implement', isCounting: true, joinedAt: 100 })
    expect(got.goAt).toBeUndefined()
  })

  test('counts from the stage after plan on, finish included; triage, design and plan do not', () => {
    for (const stage of ['isolate', 'implement', 'inline', 'finish']) expect(watchRun(EMPTY_METRICS, at(stage), '/w', 1).isCounting).toBe(true)
    for (const stage of ['triage', 'design', 'plan', '']) expect(watchRun(EMPTY_METRICS, at(stage), '/w', 1).isCounting).toBe(false)
  })

  test('outside the recorded worktree nothing counts and nobody has joined; coming in joins, later', () => {
    const outside = watchRun(EMPTY_METRICS, at('implement', '/w/feat'), '/home/m/proj', 100)
    expect(outside.isCounting).toBe(false)
    expect(outside.joinedAt).toBeUndefined()
    expect(watchRun(outside, at('implement', '/w/feat'), '/w/feat', 400)).toMatchObject({ isCounting: true, joinedAt: 400 })
  })

  test('a go seen before the worktree was entered survives the entering, and joinedAt stays the first join', () => {
    let m = watchRun(EMPTY_METRICS, at('plan'), '/home/m/proj', 100)
    m = watchRun(m, at('isolate', '/w/feat'), '/home/m/proj', 200)
    expect(m).toMatchObject({ goAt: 200, isCounting: false })
    m = watchRun(m, at('implement', '/w/feat'), '/w/feat', 300)
    expect(m).toMatchObject({ goAt: 200, joinedAt: 300, isCounting: true })
    expect(watchRun(m, at('implement', '/w/feat'), '/w/feat', 900).joinedAt).toBe(300)
  })

  test('a different run starts the figures again', () => {
    const first: PulpitMetrics = { ...watchRun(EMPTY_METRICS, at('implement'), '/w', 100), interventions: 4, waitMs: 9000 }
    const other = watchRun(first, { ...at('implement'), task: 'y' }, '/w', 500)
    expect(other).toMatchObject({ run: 'y', interventions: 0, waitMs: 0, joinedAt: 500 })
  })

  test('no run stops the counting and keeps the figures, so a read that failed once costs nothing', () => {
    const first: PulpitMetrics = { ...watchRun(EMPTY_METRICS, at('implement'), '/w', 100), interventions: 4, waitMs: 9000 }
    const gone = watchRun(first, null, '/w', 200)
    expect(gone).toMatchObject({ isCounting: false, interventions: 4, waitMs: 9000, joinedAt: 100 })
    expect(watchRun(gone, at('implement'), '/w', 300)).toMatchObject({ isCounting: true, interventions: 4, joinedAt: 100 })
  })

  test('a go is still seen across a read that failed in between', () => {
    const planned = watchRun(EMPTY_METRICS, at('plan'), '/w', 100)
    const gone = watchRun(planned, null, '/w', 150)
    expect(watchRun(gone, at('isolate'), '/w', 200).goAt).toBe(200)
  })
})

describe('addIntervention and userWait', () => {
  const counting: PulpitMetrics = { ...EMPTY_METRICS, run: 'x', isCounting: true }

  test('adds one intervention and the wait while counting', () => {
    const got = addIntervention(addIntervention(counting, 5000), 2000)
    expect(got).toMatchObject({ interventions: 2, waitMs: 7000 })
  })

  test('adds nothing while not counting', () => {
    expect(addIntervention(EMPTY_METRICS, 5000)).toBe(EMPTY_METRICS)
  })

  test('the wait is from the end of the turn to the prompt', () => {
    expect(userWait(1000, 91_000, false)).toBe(90_000)
  })

  test('no wait without a turn end on record, or while a subagent runs', () => {
    expect(userWait(null, 91_000, false)).toBe(0)
    expect(userWait(1000, 91_000, true)).toBe(0)
  })

  test('a clock that went back is no negative wait', () => {
    expect(userWait(5000, 1000, false)).toBe(0)
  })
})

describe('metricsLines', () => {
  const m: PulpitMetrics = { ...EMPTY_METRICS, run: 'x', isCounting: true, joinedAt: 1000, interventions: 3, waitMs: 125_000 }

  test('since go when a go was seen, with interventions and the user wait', () => {
    expect(metricsLines({ ...m, goAt: 500 }, 61_500)).toEqual(['since go 1m01s', 'interventions 3', 'user wait 2m05s'])
  })

  test('since joined when no go was seen', () => {
    expect(metricsLines(m, 61_000)[0]).toBe('since joined 1m00s')
  })

  test('nothing while not counting', () => {
    expect(metricsLines({ ...m, isCounting: false }, 61_000)).toEqual([])
  })
})
