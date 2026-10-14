import { describe, expect, test } from 'claude-code/testing'

import { bandLines, gateOf, mainCheckout, parseRun, shortSha, stateFile, writerLine } from '../hooks/core'

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
