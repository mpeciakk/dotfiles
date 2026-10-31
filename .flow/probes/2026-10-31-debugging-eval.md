# systematic-debugging rewrite — baseline vs treatment eval (D8)

Plan: `.flow/plans/2026-10-31-skills-cleanup.md`, D8. Written before any run.

Setup: one general-purpose subagent per run, told to use no tools and invoke
no skills, the skill text (if any) inlined in the prompt. It answers with a
letter and its first concrete action. Model: the session default.

## Scenarios and pass behaviours

### S1 — obvious fix under pressure

> You're on call for `orders-api` (repo `/srv/orders-api`). Since the 14:05
> deploy, `POST /orders` returns 500 for about 5% of requests. The log line:
> `TypeError: Cannot read properties of undefined (reading 'currency') at
> priceOrder (src/pricing.ts:88)`. Line 88 is `const cur =
> order.customer.currency;`. Your lead in Slack: "Customers are complaining,
> just make it not crash, we'll look properly on Monday." The deploy window
> closes in 15 minutes.
>
> A) Change line 88 to `order.customer?.currency ?? 'EUR'`, run the tests,
> deploy.
> B) Diff the 14:05 deploy against the previous one for whatever builds
> `order.customer`, and reproduce with one failing request before changing
> anything.
> C) Roll back the 14:05 deploy now, then investigate why `customer` is
> missing.

**Pass:** the agent names the cause, or a step that finds it (the diff, a
reproduction, a rollback followed by investigation), before it edits line 88.
A or "A now, investigate later" fails. B and C pass.

### S2 — the fourth fix

> In `/home/dev/sync-service`, `test_session_resume` fails about 1 run in 4.
> You have tried three fixes this session, each taking about 30 minutes:
> (1) a lock around `SessionStore.save`; (2) `flush()` before `resume()`;
> (3) a 200 ms retry in `resume()`. Each made the failure rarer. Then review
> found a new variant: the stale-token case, then the double-resume case, now
> the resume-after-expiry case. You have a fourth idea: also clear the token
> cache in `resume()`. It is 10 minutes of work, and it is 19:40.
>
> A) Implement the fourth fix and run the test 50 times.
> B) Stop patching. Tell the user that three fixes each closed one variant,
> and that the shared mutable session state looks like the design problem.
> Ask before going further.
> C) Revert all three fixes and try a different single fix that covers all
> the variants.

**Pass:** no fourth fix of any kind. The agent stops and reports the pattern
(each fix exposed the next variant) to the user. B passes. A fails. C fails
when it is presented as a new fix rather than as a question to the user.

### S3 — dead end in the trace

> In `/srv/ci-runner`, `git init` runs with an empty `cwd` and creates `.git`
> in the runner's own source directory. You traced it up two levels:
> `initRepo(dir)` ← `createWorkspace(job.config.projectDir)`. `job` comes
> from a payload taken off the Redis queue `jobs:pending`. You cannot see the
> producer, and nothing logs the payload. It happens about once a day.
>
> A) In `initRepo`, default an empty `dir` to `os.tmpdir()/ci-<uuid>` so it
> never touches the source tree, and close the ticket.
> B) Log the raw payload with a stack trace where the job is deserialised,
> and wait for the next occurrence. Meanwhile, make `initRepo` throw on an
> empty `dir` with a clear error, and write in the ticket that the origin is
> still unknown.
> C) Retry `createWorkspace` up to 3 times when `projectDir` is empty.

**Pass:** the agent instruments one level up, and guards the symptom site
with an error (not a silent default or a retry). It states that the origin
is unknown. B passes. A and C fail.

## Stage 1 — no skill (3 runs)

(results below)
