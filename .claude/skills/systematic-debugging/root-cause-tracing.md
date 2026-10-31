# Root-Cause Tracing

**Read this when** an error shows up deep in a call chain and it is unclear
where the bad value came from.

The error appears where the bad value is used, not where it was made. Trace
it back to where it originates and fix it there. A fix where the error
appears leaves every other path to that point open.

## Tracing back

1. **Symptom:** `Error: git init failed in ~/project/packages/core`.
2. **Immediate cause:** the code that fails —
   `execFileAsync('git', ['init'], { cwd: projectDir })`.
3. **Who called it, with what:** grep the callers, one level at a time —
   `createSessionWorktree(projectDir)` ← `Session.initializeWorkspace()` ←
   `Session.create()` ← a test calling `Project.create()`. At each level,
   note the value: here `projectDir = ''`, and an empty `cwd` resolves to
   `process.cwd()`, the source tree.
4. **Origin:** keep going until you reach the code that produced the value —
   here a test read `context.tempDir` at the top level, before `beforeEach`
   had set it.
5. **Fix at the origin:** `tempDir` became a getter that throws when read
   before `beforeEach`.

## When you cannot trace by reading

Instrument the dangerous operation, just before it runs:

```typescript
async function gitInit(directory: string) {
  console.error('[DEBUG-a4f2] git init', {
    directory,
    cwd: process.cwd(),
    stack: new Error().stack,
  });
  await execFileAsync('git', ['init'], { cwd: directory });
}
```

Run it and filter: `npm test 2>&1 | grep DEBUG-a4f2`. In tests, use
`console.error`, not the app logger — the logger may be silenced. Read the
stacks for the test file and line that trigger it, and for a pattern (same
test, same parameter).

**Something appears during tests and you don't know which test makes it:**
bisect with `find-polluter.sh` in this directory, from the project root —
`bash ~/.claude/skills/systematic-debugging/find-polluter.sh '.git' 'src/**/*.test.ts'`.
It runs the tests one by one and stops at the first that leaves the path
behind.

## Dead end

The trace stops: the value comes from code or data you cannot see (another
service, a queue payload, a closed library).

1. Instrument one level up — log the input and a stack trace where the bad
   value enters your code — and run once more, or wait for the next
   occurrence.
2. Still no origin: guard the symptom site with validation that fails loudly,
   with a clear error. Never a silent default, which turns a crash into wrong
   data. State in your report that the origin is unknown and where the
   instrumentation sits.

## Guards after the fix

Once the origin is fixed, add a check on every *other path* that can reach
the bad state — not on every layer the value passes through.

For each candidate check, ask: can something reach this point without passing
the check above it — another caller, a mock, another platform, a refactor
that inlines the entry point? If yes, the check earns its place. If the layer
above guarantees the value, the check handles an impossible case (CLAUDE.md
"Code") and only misleads the next reader.

Test each guard you keep: bypass the layer above and confirm this one
catches it. A guard you cannot write a bypass test for was not reachable —
drop it.

In the `projectDir` case, four guards were each reached by a path the others
missed:
- `Project.create()` validates that the directory exists and is writable.
- `WorkspaceManager` rejects an empty `projectDir`.
- In tests, `git init` is refused outside the temp directory.
- The stack-trace log stays in place before `git init`.
