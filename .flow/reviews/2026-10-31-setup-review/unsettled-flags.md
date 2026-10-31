# Prompt audit — flags left for the user (lean workflow v2, task 5)

Flag-only findings from `prompt-audit/slice-{a,b,c}.md` that this run did not
settle. Each needs a decision; none was applied.

## Conflicts with a decision in force

1. **codex-rescue writes in the tree unasked** (slice C, P1). The plugin's agent
   says "use proactively" and defaults to a write-capable run. W1 makes the
   session the only writer. Options: a CLAUDE.md line limiting it to explicit
   `/codex:rescue`, or disable the plugin's agent.
2. ~~**Per-task review example** (slice B, F5). `writing-skills/persuasion-principles.md`
   still models "after completing a task, immediately request review"; W4 has
   one branch review.~~ Settled 2026-10-31 by skills-cleanup D5: the file is
   deleted.
3. ~~**writing-skills Iron Law covers trivial edits; CLAUDE.md exempts them**
   (slice B, F2).~~ Settled 2026-10-31 by skills-cleanup D4: no Iron Law;
   only discipline skills need a baseline vs treatment test.
4. **finishing menu is fixed English** (slice A, F-L1) against "reply in the
   language of my message".

## Plugin and synced-skill flags (slice C, Part 2 — not editable here)

5. P2–P9: see `slice-c.md` "Part 2 findings" — deprecated Cloudflare MCP
   servers, duplicated claude.ai skills, and the rest; each carries its option.

## Low — observations, no change proposed

- Slice A: F-L3 (kt-cold-reader conditional block), F-L4 (plan size target),
  F-L6 and F-L9 (kept by design), F-L10 (partly settled by W1; the
  inline-change reviewer gate stays).
- Slice B: F4, F8, F9, F10, F12, F13. Settled 2026-10-31 by skills-cleanup
  (`.flow/plans/2026-10-31-skills-cleanup.md`): F1 (D1, trigger-only
  descriptions), F6 (D5, vendored doc replaced by links), F7 (D5, file
  deleted), F11 (D5, writing-skills rewritten).
- Slice C: L1–L4 (prompt-master zones, `/compact` threshold, step cadence,
  numeric caps in generated prompts).

Settled by this run: F-L2, F-L5, F-L8 (implementer deleted), F-L7 (applied),
F3 (W3).
