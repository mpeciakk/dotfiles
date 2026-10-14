import { describe, expect, test } from 'claude-code/testing'

import { LINKED, MAIN, STATE, world } from './fixture'

const SURFACES = ['terminal', 'desktop'] as const
const START = { cwd: MAIN, surface: 'terminal', isInteractive: true } as const
const PANE_PROPS = {
  title: 'pulpit',
  isFocused: false,
  bodyColumns: 60,
  placement: 'dock',
  scroll: { offset: 0, bodyRows: 30 },
  view: {},
} as const
const BAND_PROPS = {
  hasSurvey: false,
  isWorking: false,
  maxRows: 6,
  bodyColumns: 100,
  scroll: { offset: 0, bodyRows: 5 },
  view: {},
} as const

const state = (fields: Record<string, unknown>) => JSON.stringify({ task: 'pulpit-mod', tasks: [], ...fields })

async function pane($: any, surface: (typeof SURFACES)[number]) {
  const ui = await $.ui.mount({ plugin: 'pulpit', surface, component: 'Pane', requestId: 'pulpit', props: PANE_PROPS })
  const shown = (await ui.findAll({ type: 'Text' })).map((text: { text: string }) => text.text).join('\n')
  await ui.unmount()
  return shown
}

async function band($: any, surface: (typeof SURFACES)[number]) {
  const ui = await $.ui.mount({ plugin: 'pulpit', surface, component: 'AbovePrompt', props: BAND_PROPS })
  const rows = await ui.findAll({ type: 'Text' })
  await ui.unmount()
  return rows.map((row: { text: string }) => row.text)
}

describe('Run panel', () => {
  test('a run at stage implement shows task, stage, ledger, worktree, branch and a short base', async ($, on) => {
    const w = world($, on, {
      file: state({
        stage: 'implement',
        worktree: LINKED,
        branch: 'feat/x',
        base: 'abcdef0123456789',
        tasks: [
          { n: '1', status: 'done' },
          { n: '2', status: 'started' },
          { n: '3', status: 'blocked', note: 'needs a decision' },
        ],
      }),
    })
    await $.session.start(START)
    for (const surface of SURFACES) {
      const shown = await pane($, surface)
      expect(shown).toContain('pulpit-mod')
      expect(shown).toContain('implement')
      expect(shown).toContain('task 1')
      expect(shown).toContain('done')
      expect(shown).toContain('task 2')
      expect(shown).toContain('started')
      expect(shown).toContain('task 3')
      expect(shown).toContain('blocked')
      expect(shown).toContain('needs a decision')
      expect(shown).toContain(LINKED)
      expect(shown).toContain('feat/x')
      expect(shown).toContain('abcdef0')
      expect(shown).not.toContain('abcdef01')
    }
    expect(w.calls.read).toBe(1)
  })

  test('a blocked entry is highlighted, a done one is not', async ($, on) => {
    world($, on, {
      file: state({ stage: 'implement', tasks: [{ n: '1', status: 'done' }, { n: '2', status: 'blocked' }] }),
    })
    await $.session.start(START)
    const ui = await $.ui.mount({ plugin: 'pulpit', surface: 'terminal', component: 'Pane', requestId: 'pulpit', props: PANE_PROPS })
    expect((await ui.find({ type: 'Text', text: 'task 2' }))?.props.color).toBe('error')
    expect((await ui.find({ type: 'Text', text: 'task 1' }))?.props.color).toBeUndefined()
    await ui.unmount()
  })

  test('every stage is shown as written', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'triage' }) })
    await $.session.start(START)
    for (const stage of ['triage', 'design', 'plan', 'isolate', 'implement', 'inline', 'finish']) {
      w.setFile(state({ stage }))
      await w.clock.advance(2000)
      expect(await pane($, 'terminal')).toContain(stage)
    }
  })

  test('stage plan with a plan shows the go gate', async ($, on) => {
    world($, on, { file: state({ stage: 'plan', plan: '/tmp/p.md' }) })
    await $.session.start(START)
    for (const surface of SURFACES) expect(await pane($, surface)).toContain('✋ go')
  })

  test('branch-review done shows the merge gate until the stage is finish', async ($, on) => {
    const w = world($, on, {
      file: state({ stage: 'implement', tasks: [{ n: 'branch-review', status: 'done' }] }),
    })
    await $.session.start(START)
    expect(await pane($, 'terminal')).toContain('✋ merge / PR / keep / discard')
    w.setFile(state({ stage: 'finish', tasks: [{ n: 'branch-review', status: 'done' }] }))
    await w.clock.advance(2000)
    expect(await pane($, 'terminal')).not.toContain('✋')
  })

  test('a gate that is answered disappears within one tick', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'plan', plan: '/tmp/p.md' }) })
    await $.session.start(START)
    expect(await pane($, 'terminal')).toContain('✋ go')
    w.setFile(state({ stage: 'isolate', plan: '/tmp/p.md' }))
    await w.clock.advance(2000)
    expect(await pane($, 'terminal')).not.toContain('✋')
  })

  test('a missing file draws no Run panel and no error', async ($, on) => {
    world($, on, { file: undefined })
    await $.session.start(START)
    for (const surface of SURFACES) {
      const shown = await pane($, surface)
      expect(shown).toContain('no active run')
      expect(shown).not.toContain('Run')
      expect(shown).not.toMatch(/error|fail|denied/i)
    }
  })

  test('a malformed file draws no Run panel and no error', async ($, on) => {
    world($, on, { file: '{ truncated' })
    await $.session.start(START)
    const shown = await pane($, 'terminal')
    expect(shown).toContain('no active run')
    expect(shown).not.toContain('Run')
    expect(shown).not.toMatch(/error|fail|denied/i)
  })

  test('the panel goes when the run is cleared', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'implement' }) })
    await $.session.start(START)
    expect(await pane($, 'terminal')).toContain('Run')
    w.setFile(undefined)
    await w.clock.advance(2000)
    expect(await pane($, 'terminal')).not.toContain('Run')
  })
})

describe('reading the state file', () => {
  test('an unchanged mtime is not parsed again, a changed one is', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'implement' }) })
    await $.session.start(START)
    expect(w.calls.read).toBe(1)
    await w.clock.advance(2000)
    await w.clock.advance(2000)
    expect(w.calls.stat).toBeGreaterThan(2)
    expect(w.calls.read).toBe(1)
    w.setFile(state({ stage: 'finish' }))
    await w.clock.advance(2000)
    expect(w.calls.read).toBe(2)
  })

  test('a read that failed is tried again at the next tick although the mtime did not change', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'implement' }) })
    w.setReadable(false)
    await $.session.start(START)
    expect(await pane($, 'terminal')).toContain('no active run')
    w.setReadable(true)
    await w.clock.advance(2000)
    expect(await pane($, 'terminal')).toContain('implement')
  })

  test('from a linked worktree the main checkout holds the file', async ($, on) => {
    const w = world($, on, { root: LINKED, worktrees: [MAIN, LINKED], file: state({ stage: 'implement' }) })
    await $.session.start({ ...START, cwd: LINKED })
    expect(w.gitCwds[0]).toBe(LINKED)
    expect(w.statPaths[0]).toBe(STATE)
    expect(await pane($, 'terminal')).toContain('implement')
  })

  test('the checkout is resolved again when the root changes, and not before', async ($, on) => {
    const w = world($, on, { worktrees: [MAIN], file: state({ stage: 'implement' }) })
    await $.session.start(START)
    await w.clock.advance(2000)
    await w.clock.advance(2000)
    expect(w.calls.git).toBe(1)
    w.setRoot('/home/m/other')
    await w.clock.advance(2000)
    expect(w.calls.git).toBe(2)
    expect(w.gitCwds[1]).toBe('/home/m/other')
  })
})

describe('the pane', () => {
  test('opens at session start under the id pulpit', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    expect(w.calls.open).toBe(1)
  })

  test('/pulpit closes an open pane and opens a closed one', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    const origin = { kind: 'composer' } as const
    const presentation = { isFullscreen: true, columns: 200 } as const
    const closed = await $.command.run({ command: 'pulpit', args: '', origin, presentation })
    expect(w.calls.close).toBe(1)
    expect(closed.text).toContain('closed')
    const opened = await $.command.run({ command: 'pulpit', args: '', origin, presentation })
    expect(w.calls.open).toBe(2)
    expect(opened.text).toContain('opened')
  })

  test('/pulpit places a pane that waits undrawn on a narrow terminal', async ($, on) => {
    const w = world($, on)
    w.setPanes([{ id: 'pulpit', isPlaced: false }])
    await $.session.start(START)
    await $.command.run({
      command: 'pulpit',
      args: '',
      origin: { kind: 'composer' },
      presentation: { isFullscreen: true, columns: 100 },
    })
    expect(w.calls.close).toBe(0)
    expect(w.calls.open).toBe(1)
  })

  test('a pane the person closed is not reopened by a module reload', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    expect(w.calls.open).toBe(1)
    w.setPanes([]) // the person closed it
    await $.session.start(START) // a reload runs session.start again
    expect(w.calls.open).toBe(1)
  })

  test('a pane still open at a reload is left alone', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    await $.session.start(START)
    expect(w.calls.close).toBe(0)
  })
})

describe('the band', () => {
  test('is absent while the pane is placed', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'plan', plan: '/p.md' }) })
    await $.session.start(START)
    w.setPanes([{ id: 'pulpit', isPlaced: true }])
    for (const surface of SURFACES) expect(await band($, surface)).toEqual([])
  })

  test('shows the gate and the writer in two rows while the pane waits undrawn', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'plan', plan: '/p.md' }) })
    await $.session.start(START)
    w.setPanes([{ id: 'pulpit', isPlaced: false }])
    for (const surface of SURFACES) expect(await band($, surface)).toEqual(['✋ go', 'writes: controller'])
  })

  test('shows the writer alone when no gate is pending', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'implement' }) })
    await $.session.start(START)
    w.setPanes([])
    expect(await band($, 'terminal')).toEqual(['writes: controller'])
  })

  test('is absent when there is nothing to show', async ($, on) => {
    const w = world($, on, { file: undefined })
    await $.session.start(START)
    w.setPanes([])
    for (const surface of SURFACES) expect(await band($, surface)).toEqual([])
  })

  test('yields to a survey', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'plan', plan: '/p.md' }) })
    await $.session.start(START)
    w.setPanes([])
    const ui = await $.ui.mount({
      plugin: 'pulpit',
      surface: 'terminal',
      component: 'AbovePrompt',
      props: { ...BAND_PROPS, hasSurvey: true },
    })
    expect(await ui.findAll({ type: 'Text' })).toEqual([])
    await ui.unmount()
  })
})

const spawnInput = (subagentType: string, description: string, extra: Record<string, unknown> = {}) =>
  ({
    tool_use_id: 'toolu_1',
    prompt: 'do it',
    description,
    subagentType,
    provider: { plugin: 'engine', tier: 'core' },
    parentModel: 'claude-opus-5-5',
    background: true,
    fork: false,
    ...extra,
  }) as const

const stepInput = (agentId: string | undefined, model: string, effort?: 'low' | 'high') => ({
  turnId: 'turn-1',
  index: 0,
  model,
  messageCount: 3,
  ...(effort === undefined ? {} : { effort }),
  ...(agentId === undefined ? {} : { agentId }),
})

// A streaming call is read to its end, as the engine reads a model request.
async function step($: any, input: ReturnType<typeof stepInput>) {
  const stream = $.turn.step(input)
  while (!(await stream.next()).done);
}

const rolesOf = (shown: string) => shown.split('\n').filter(line => line.startsWith('implementer ·'))

describe('Roles panel', () => {
  test('a spawn adds a row whose clock follows the mocked clock, and the spawn result is passed on unchanged', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    const result = await $.agent.spawn(spawnInput('explorer', 'find the hooks'))
    expect(result).toEqual({ model: 'claude-sonnet-5-5', agentId: 'agent-1' })
    for (const surface of SURFACES) {
      expect(await pane($, surface)).toContain('explorer · claude-sonnet-5-5 · find the hooks · 0s')
    }
    await w.clock.advance(3000)
    expect(await pane($, 'terminal')).toContain('explorer · claude-sonnet-5-5 · find the hooks · 3s')
    await w.clock.advance(60_000)
    expect(await pane($, 'terminal')).toContain('find the hooks · 1m03s')
  })

  test('bookkeeping that fails leaves the spawn result as it was and adds no row', async ($, on) => {
    world($, on)
    on('state.set', { plugin: 'pulpit', key: 'agents' }, () => ({ deny: 'store refused' }))
    await $.session.start(START)
    const result = await $.agent.spawn(spawnInput('explorer', 'find the hooks'))
    expect(result).toEqual({ model: 'claude-sonnet-5-5', agentId: 'agent-1' })
    expect(await pane($, 'terminal')).not.toContain('find the hooks')
  })

  test('an open pane redraws as the clock moves', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    await $.agent.spawn(spawnInput('explorer', 'find the hooks'))
    const ui = await $.ui.mount({ plugin: 'pulpit', surface: 'terminal', component: 'Pane', requestId: 'pulpit', props: PANE_PROPS })
    expect(await ui.find({ type: 'Text', text: 'find the hooks · 0s' })).toBeDefined()
    await w.clock.advance(5000)
    expect(await ui.find({ type: 'Text', text: 'find the hooks · 5s' })).toBeDefined()
    await ui.unmount()
  })

  test('no agent, no Roles panel', async ($, on) => {
    world($, on, { file: state({ stage: 'implement' }) })
    await $.session.start(START)
    expect(await pane($, 'terminal')).not.toContain('Roles')
  })

  test('completed shows done and the duration, the clock stops', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    await $.agent.spawn(spawnInput('explorer', 'find the hooks'))
    await w.clock.advance(4000)
    w.setAgentStatus('agent-1', 'completed')
    await w.clock.advance(1000)
    await w.clock.advance(30_000)
    expect(await pane($, 'terminal')).toContain('find the hooks · done 5s')
  })

  test('an agent that leaves the list while running shows ended and its duration, not a clock that never stops', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    await $.agent.spawn(spawnInput('implementer', 'long job'))
    await w.clock.advance(10_000)
    w.dropAgent('agent-1')
    await w.clock.advance(1000)
    await w.clock.advance(30_000)
    expect(await pane($, 'terminal')).toContain('long job · ended 11s')
  })

  test('an ended row is dimmed like a done one, not marked as an error', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    await $.agent.spawn(spawnInput('implementer', 'long job'))
    await w.clock.advance(3000)
    w.dropAgent('agent-1')
    await w.clock.advance(1000)
    const ui = await $.ui.mount({ plugin: 'pulpit', surface: 'terminal', component: 'Pane', requestId: 'pulpit', props: PANE_PROPS })
    const row = await ui.find({ type: 'Text', text: 'long job · ended' })
    expect(row?.props.dimColor).toBe(true)
    expect(row?.props.color).toBeUndefined()
    await ui.unmount()
  })

  test('an agent not on the list yet at the first tick is not taken for ended', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    await $.agent.spawn(spawnInput('implementer', 'slow to list'))
    w.dropAgent('agent-1')
    await w.clock.advance(1000)
    expect(await pane($, 'terminal')).toContain('slow to list · 1s')
  })

  test('failed and killed both show failed with the duration', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    await $.agent.spawn(spawnInput('explorer', 'one'))
    await $.agent.spawn(spawnInput('explorer', 'two'))
    await w.clock.advance(2000)
    w.setAgentStatus('agent-1', 'failed')
    w.setAgentStatus('agent-2', 'killed')
    await w.clock.advance(1000)
    const shown = await pane($, 'terminal')
    expect(shown).toContain('one · failed 3s')
    expect(shown).toContain('two · failed 3s')
  })

  test('a failed row is highlighted, a done one dimmed', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    await $.agent.spawn(spawnInput('explorer', 'one'))
    await $.agent.spawn(spawnInput('explorer', 'two'))
    w.setAgentStatus('agent-1', 'failed')
    w.setAgentStatus('agent-2', 'completed')
    await w.clock.advance(1000)
    const ui = await $.ui.mount({ plugin: 'pulpit', surface: 'terminal', component: 'Pane', requestId: 'pulpit', props: PANE_PROPS })
    expect((await ui.find({ type: 'Text', text: 'one · failed' }))?.props.color).toBe('error')
    expect((await ui.find({ type: 'Text', text: 'two · done' }))?.props.dimColor).toBe(true)
    await ui.unmount()
  })

  test('model and effort come from the latest step of that agent, the spawn model alone before its first step', async ($, on) => {
    world($, on)
    await $.session.start(START)
    await $.agent.spawn(spawnInput('implementer', 'a', { model: 'sonnet' }))
    await $.agent.spawn(spawnInput('explorer', 'b'))
    expect(await pane($, 'terminal')).toContain('implementer · sonnet · a')
    await step($, stepInput('agent-1', 'claude-opus-5-5', 'high'))
    let shown = await pane($, 'terminal')
    expect(shown).toContain('implementer · claude-opus-5-5 · high · a')
    expect(shown).toContain('explorer · claude-sonnet-5-5 · b')
    await step($, stepInput('agent-1', 'claude-haiku-5'))
    shown = await pane($, 'terminal')
    expect(shown).toContain('implementer · claude-haiku-5 · a')
    expect(shown).not.toContain('high')
  })

  test('a step of the main loop changes no row', async ($, on) => {
    world($, on)
    await $.session.start(START)
    await $.agent.spawn(spawnInput('explorer', 'b'))
    await step($, stepInput(undefined, 'claude-opus-5-5', 'high'))
    expect(await pane($, 'terminal')).toContain('explorer · claude-sonnet-5-5 · b')
  })

  test('an implementer carries the task the run has started when it is spawned, even within one poll interval', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'implement', tasks: [{ n: '1', status: 'started' }] }) })
    await $.session.start(START)
    w.setFile(state({ stage: 'implement', tasks: [{ n: '1', status: 'done' }, { n: '2', status: 'started' }] }))
    await $.agent.spawn(spawnInput('implementer', 'roles'))
    expect(await pane($, 'terminal')).toContain('implementer · task 2 · claude-sonnet-5-5 · roles')
  })

  test('two implementers: both rows, each with its own task', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'implement', tasks: [{ n: '1', status: 'started' }] }) })
    await $.session.start(START)
    await $.agent.spawn(spawnInput('implementer', 'first'))
    w.setFile(state({ stage: 'implement', tasks: [{ n: '1', status: 'started' }, { n: '2', status: 'started' }] }))
    await $.agent.spawn(spawnInput('implementer', 'second'))
    const rows = rolesOf(await pane($, 'terminal'))
    expect(rows).toEqual([
      'implementer · task 1 · claude-sonnet-5-5 · first · 0s',
      'implementer · task 2 · claude-sonnet-5-5 · second · 0s',
    ])
  })

  test('only the last 6 finished rows stay, the oldest are dropped', async ($, on) => {
    const w = world($, on)
    await $.session.start(START)
    for (let i = 1; i <= 8; i += 1) {
      await $.agent.spawn(spawnInput('explorer', `n${i}`))
      w.setAgentStatus(`agent-${i}`, 'completed')
      await w.clock.advance(1000)
    }
    const shown = await pane($, 'terminal')
    expect(shown).not.toMatch(/\bn1 ·|\bn2 ·/)
    for (const kept of ['n3', 'n4', 'n5', 'n6', 'n7', 'n8']) expect(shown).toContain(`${kept} · done`)
  })
})

describe('Writer', () => {
  const writerIn = async ($: any) => (await pane($, 'terminal')).split('\n').find(line => line.startsWith('writes:'))

  test('stays the controller while only a read-only type is in flight', async ($, on) => {
    world($, on, { file: state({ stage: 'implement' }) })
    await $.session.start(START)
    for (const type of ['branch-reviewer', 'plan-red-team', 'explorer', 'Explore']) {
      await $.agent.spawn(spawnInput(type, type))
    }
    expect(await writerIn($)).toBe('writes: controller')
  })

  test('another type is named by its type', async ($, on) => {
    world($, on, { file: state({ stage: 'implement' }) })
    await $.session.start(START)
    await $.agent.spawn(spawnInput('general-purpose', 'x'))
    expect(await writerIn($)).toBe('writes: general-purpose')
  })

  test('an implementer is named with the latest started task and the worktree name', async ($, on) => {
    world($, on, {
      file: state({ stage: 'implement', worktree: LINKED, tasks: [{ n: '1', status: 'done' }, { n: '2', status: 'started' }] }),
    })
    await $.session.start(START)
    await $.agent.spawn(spawnInput('implementer', 'x'))
    expect(await writerIn($)).toBe('writes: implementer · task 2 · feat')
  })

  test('goes back to the controller when the agent finishes and names it again when it is resumed', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'implement' }) })
    await $.session.start(START)
    await $.agent.spawn(spawnInput('general-purpose', 'x'))
    w.setAgentStatus('agent-1', 'completed')
    await w.clock.advance(1000)
    expect(await writerIn($)).toBe('writes: controller')
    w.setAgentStatus('agent-1', 'running') // SendMessage resumed it
    await w.clock.advance(1000)
    expect(await writerIn($)).toBe('writes: general-purpose')
  })

  test('two implementers in flight: the latest started task is named', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'implement', worktree: LINKED, tasks: [{ n: '1', status: 'started' }] }) })
    await $.session.start(START)
    await $.agent.spawn(spawnInput('implementer', 'first'))
    w.setFile(state({ stage: 'implement', worktree: LINKED, tasks: [{ n: '1', status: 'started' }, { n: '2', status: 'started' }] }))
    await $.agent.spawn(spawnInput('implementer', 'second'))
    await w.clock.advance(2000)
    expect(await writerIn($)).toBe('writes: implementer · task 2 · feat')
  })

  test('the band shows the writer while the pane waits undrawn', async ($, on) => {
    const w = world($, on, { file: state({ stage: 'implement' }) })
    await $.session.start(START)
    await $.agent.spawn(spawnInput('general-purpose', 'x'))
    w.setPanes([])
    expect(await band($, 'terminal')).toEqual(['writes: general-purpose'])
  })
})
