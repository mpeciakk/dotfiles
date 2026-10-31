# Condition-Based Waiting

**Read this when** a test sleeps for a fixed delay (`setTimeout`, `sleep`,
`time.sleep()`), passes locally and fails under load or in CI, or times out
when tests run in parallel.

A fixed delay is a guess about how long something takes. Wait for the
condition you actually care about instead.

Not for testing timing behaviour itself (debounce, throttle, intervals): use
a fake clock there (`executing-plans/writing-good-tests.md`).

## Pattern

```typescript
// Before: a guess
await new Promise(r => setTimeout(r, 50));
expect(getResult()).toBeDefined();

// After: the condition
await waitFor(() => getResult() !== undefined, 'result to be set');
expect(getResult()).toBeDefined();
```

| Waiting for | Call |
|---|---|
| an event | `waitFor(() => events.find(e => e.type === 'DONE'), 'DONE event')` |
| a state | `waitFor(() => machine.state === 'ready', 'machine ready')` |
| a count | `waitFor(() => items.length >= 5, '5 items')` |
| a file | `waitFor(() => fs.existsSync(path), \`${path} to exist\`)` |

## Helper

```typescript
async function waitFor<T>(
  condition: () => T | undefined | null | false,
  description: string,
  timeoutMs = 5000
): Promise<T> {
  const start = Date.now();
  while (true) {
    const result = condition();
    if (result) return result;
    if (Date.now() - start > timeoutMs) {
      throw new Error(`Timeout waiting for ${description} after ${timeoutMs}ms`);
    }
    await new Promise(r => setTimeout(r, 10));
  }
}
```

- Poll about every 10 ms; 1 ms burns CPU.
- Always a timeout, with the description in its error.
- Read the state inside the condition, never a value cached before the loop.

## When a fixed delay is right

Only for timing you cannot fake — a real process or tool on the wall clock —
after waiting for the triggering condition, for a known duration, with a
comment saying why:

```typescript
await waitFor(() => events.find(e => e.type === 'TOOL_STARTED'), 'tool start');
await new Promise(r => setTimeout(r, 200)); // the tool ticks every 100 ms; 2 ticks give partial output
```
