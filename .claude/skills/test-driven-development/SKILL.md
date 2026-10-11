---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

# Test-Driven Development (TDD)

Write the test first. Watch it fail. Write minimal code to pass.

**If you did not watch the test fail, you do not know that it tests the right
thing.**

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Wrote the code before the test? Delete it and implement fresh from the test —
not "kept as a reference", not adapted while the test is written. Tests-after
answer *what does this do*; tests-first answer *what should this do*, and only
the second can fail for the right reason.

Applies to features, bugfixes, refactors and behavior changes. Throwaway
prototypes, generated code and config files are the exceptions — ask before
treating anything else as one.

## The cycle

### RED — one failing test

One behavior, a name that states it, real code rather than mocks.

<Good>
```typescript
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```
Clear name, tests real behavior, one thing
</Good>

<Bad>
```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
```
Vague name, tests the mock rather than the code
</Bad>

### Verify RED — mandatory

Run it. It must **fail**, not error, and fail because the feature is missing
rather than because of a typo.

- Passes already → you are testing existing behavior; fix the test.
- Errors → fix the error and re-run until it fails correctly.

### GREEN — the simplest code that passes

<Good>
```typescript
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i === 2) throw e;
    }
  }
  throw new Error('unreachable');
}
```
Just enough to pass
</Good>

<Bad>
```typescript
async function retryOperation<T>(
  fn: () => Promise<T>,
  options?: {
    maxRetries?: number;
    backoff?: 'linear' | 'exponential';
    onRetry?: (attempt: number) => void;
  }
): Promise<T> {
  // YAGNI
}
```
Over-engineered
</Bad>

No extra features, no refactoring of neighbouring code, no improvements the
test did not ask for.

### Verify GREEN — mandatory

The test passes, the other tests still pass, and the output is pristine — no
stray errors or warnings. Test still failing → fix the code, never the test.
Something else broke → fix it now.

Green means the project's test command (bare `pytest`, `npm test`, whatever
the repo uses), not the one file you touched — a narrow scope bounds the
change, not the verification. Name every failure that run shows, including
one you did not cause; a red test left unmentioned is a false "green".

### REFACTOR — only on green

Remove duplication, improve names, extract helpers. No new behavior, tests stay
green. Then the next failing test.

## Good tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | one thing; an "and" in the name means split it | `test('validates email and domain and whitespace')` |
| **Clear** | the name describes the behavior | `test('test1')` |
| **Shows intent** | demonstrates the API you want | obscures what the code should do |

## When stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test it | write the wished-for API, assertion first; ask if still stuck |
| Test too complicated | the design is too complicated — simplify the interface |
| Must mock everything | the code is too coupled — inject dependencies |
| Test setup huge | extract helpers; still complex means simplify the design |

## Bugs

Reproduce with a failing test first. The test proves the fix and prevents the
regression. Never fix a bug without one.

## Writing the tests

Before writing or changing tests, adding a mock or a test helper, read
[writing-good-tests.md](writing-good-tests.md): every test names the break it
catches, expected values are derived without the code under test, mocks stay
at the slow or external level.

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. The test takes 30 seconds. |
| "I'll test after" | A test written after passes at once and proves nothing — you never saw it catch the bug. |
| "Already tested it manually" | No record, no re-run, cases forgotten under pressure. |
| "Deleting hours of work is wasteful" | Sunk cost. Keeping code you cannot trust is the waste. |
| "Keep it as reference" | You will adapt it — that is testing after. Delete means delete. |
| "Need to explore first" | Fine: explore, throw it away, start with a test. |
| "Hard to test" | Hard to test is hard to use. Listen to the test. |
| "This case is different" | That is the rationalization. Write the test. |

## Final rule

```
Production code → a test exists and failed first
Otherwise → not TDD
```
