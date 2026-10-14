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
