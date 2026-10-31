---
name: test-driven-development
description: Use when implementing a feature or a bug fix — decides which behaviours get a test, when the test comes first, and what counts as verified.
---

# Tests for behaviour

Tests exist to catch a behaviour breaking. Write the ones that do; skip the
ones that only restate the code.

## What gets a test

- **Each acceptance line** in the plan, or each behaviour the user stated:
  one focused test.
- **Each bug that escaped into a commit:** a regression test that fails
  without the fix.
- **Not:** impossible cases, private helpers already covered through the
  behaviour that uses them, a second test for what a first one already pins.

A timing-dependent test uses a fake clock, never the wall clock: a test that
sleeps and races is a flaky test.

## When the test comes first

Test-first is the default for a **bug fix** and for behaviour that is **easy
to state as a test** (an input and its expected output, an error for a bad
value). Write the test, run it, and see it fail for the reason you expect —
not an error, not a typo. A test you never saw fail may not test what you
think. Then the simplest code that passes.

A bug fix always starts there: the failing test proves the bug, then proves
the fix.

Elsewhere — wiring, UI layout, exploratory code, a refactor — write the code
first and add the tests its behaviour needs. A refactor keeps the suite green
before and after; it needs no new failing test.

## Verified means run

- The project's full test command (`pytest`, `npm test`, whatever the repo
  uses), not the one file you touched. Name every failure it shows, including
  one you did not cause.
- Then the real thing: run the command, open the page, call the API — the
  plan's Verification, or whatever shows the change working. A green suite
  says the tests pass, not that the feature works.

## Good tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | one behaviour; an "and" in the name means split it | `test('validates email and domain and whitespace')` |
| **Clear** | the name states the behaviour | `test('test1')` |
| **Real** | exercises the code, not a mock of it | asserts a mock was called 3 times |

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
Vague name, tests the mock rather than the code.
</Bad>

Hard to test usually means hard to use: a test that must mock everything
points at code that is too coupled.

Before writing or changing tests, adding a mock or a test helper, read
[writing-good-tests.md](writing-good-tests.md): every test names the break it
catches, expected values are derived without the code under test, mocks stay
at the slow or external level.
