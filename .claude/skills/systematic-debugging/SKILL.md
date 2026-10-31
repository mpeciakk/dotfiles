---
name: systematic-debugging
description: Use when a bug, test failure, build failure, performance problem or unexpected behaviour appears, before proposing a fix — and when a fix did not work.
---

# Systematic Debugging

Find the root cause before you fix anything. A fix at the symptom leaves the
cause to come back somewhere else, and a guess that happens to pass teaches
nothing. No fix before Phase 1 is done.

## Several independent failures

The phases run per bug. Failures in different test files or subsystems with
unrelated causes: dispatch one read-only subagent per failure, in one message,
each with its symptom evidence inline and one deliverable — root cause, the
lines involved, the minimal change it recommends. You apply the fixes, one at
a time. If fixing one might affect another, or they touch the same code,
investigate them together.

## Phase 1: Root cause

1. **Read the error completely** — the whole stack trace, line numbers,
   paths, codes, the warnings before it.
2. **Build a feedback loop:** one command that goes red on *this* bug. With
   it, bisection and hypotheses become mechanical; without it, reading code
   rarely saves you. In roughly this order:
   - a failing test at whatever seam reaches the bug;
   - a curl/HTTP script against a running dev server;
   - a CLI run on a fixture, diffed against known-good output;
   - a headless browser script asserting on DOM, console or network;
   - a captured real request or event log replayed through the code path;
   - a throwaway harness: one service, mocked dependencies, one call;
   - a property/fuzz loop for "sometimes wrong";
   - `git bisect run` for "worked at X, broken at Y";
   - a differential run of old and new version on the same input;
   - last resort, a script that walks a human through the manual steps.

   Then make it faster, sharper (assert the user's exact symptom, not "didn't
   crash") and deterministic (pin time, seed, filesystem, network). A flaky
   bug needs a higher reproduction rate, not a clean repro: loop the trigger,
   add stress, narrow the timing window. Once red, shrink the scenario until
   every remaining element is needed.

   Phase 1 is not done until you can name a command you have run that goes
   red on this bug. Cannot build one: say so, list what you tried, and ask for
   access, a captured artifact or permission to instrument.
3. **Check recent changes:** the diff, recent commits, dependencies, config,
   environment.
4. **Several components** (CI → build → signing, API → service → database):
   log what enters and leaves each boundary, run once, and find *where* it
   breaks before asking why. Log a secret's presence, never its value. Tag
   every temporary log with one prefix (`[DEBUG-a4f2]`) so removing them is
   one grep. Performance: measure a baseline and bisect instead of logging.
5. **Error deep in the stack:** trace the bad value back to where it
   originates, grepping the callers at each level, and fix there. Method,
   dead ends and guards after the fix: [root-cause-tracing.md](root-cause-tracing.md).

## Phase 2: Compare

Find similar code that works in the same codebase. If you are following a
reference implementation, read its relevant range in full. List every
difference between working and broken, however small, and what each depends
on: config, environment, assumptions.

## Phase 3: One hypothesis at a time

State it: "X is the root cause because Y." Test it with the smallest change,
one variable at a time. Confirmed → Phase 4. Refuted → a new hypothesis, with
the previous change removed, not built on. Don't know → say "I don't
understand X" and research or ask.

## Phase 4: Fix

1. **A failing test or script that reproduces the bug**, before the fix
   ([writing-good-tests.md](../executing-plans/writing-good-tests.md)).
2. **One fix, at the root cause.** No "while I'm here" changes.
3. **Verify:** the reproduction passes, the full suite passes, and the
   original symptom is gone in the real thing.
4. **The fix did not work:** remove it and go back to Phase 1 with what you
   learned. The same error after 2 fix attempts: call the advisor (CLAUDE.md
   workflow rule 7).
5. **Three failed fixes: stop.** No fourth fix. Three fixes that each close
   one variant, or that each surface a new problem elsewhere, point at the
   design — shared state, coupling, a pattern that does not fit. Put that to
   the user, with what each fix showed, before changing anything else.

## Dead end: no root cause found

When the trace stops — the origin is in code or data you cannot see:

1. Instrument one level up: log the input and a stack trace where the bad
   value enters, and run (or wait for the next occurrence) once more.
2. Still no origin: guard the symptom site — validation that fails loudly
   with a clear error, never a silent default — and say in your report that
   the origin is unknown and where the instrumentation is.

A retry or a timeout is the fix only for a cause proven environmental or
external (a network blip, a rate limit, a slow dependency), and it logs each
retry. On an unexplained failure it hides the bug.

## Signs you skipped Phase 1

Return to Phase 1 when you catch yourself:

- proposing a fix, or listing "the main problems", before tracing the data
  flow or having a red command;
- "quick fix now, investigate later", or "just try X and see";
- changing several things before one test run;
- skipping the reproduction because you "checked it manually";
- adapting a reference pattern you have not read in full;
- reaching for "one more fix" after two failed ones.

Or when the user: asks whether what you asserted is actually happening; asks
what a change would *show*; tells you to stop guessing or to think about
fundamentals; or is visibly frustrated that the approach is not working.

## Supporting files

- [root-cause-tracing.md](root-cause-tracing.md) — tracing backwards, stack
  trace instrumentation, dead ends, guards after the fix.
- [condition-based-waiting.md](condition-based-waiting.md) — flaky tests that
  sleep: wait for the condition, not a guessed delay.
- `find-polluter.sh` — finds the test that leaves a file or directory behind.

## The measured case

In this setup, one task took 8 fix rounds over 2 hours 40 minutes. Each
round patched the next variant of one defect, and none went back to Phase 1.
The prompt that finally closed it said so: "the previous three rounds each
fixed one variant and review kept finding the next."
