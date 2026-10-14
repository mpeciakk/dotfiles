# Error analysis brief — one note per session

You annotate Claude Code sessions of one user (Polish-speaking developer) to find
where their Claude setup fails. The output feeds an eval suite for that setup.

## Input

- Rendered sessions: `/tmp/error-analysis/renders/<NN>-<stratum>-<id>.md`. `## USER`
  = the human; `**AGENT**` = the main session; `→ Tool arg` = one tool call;
  `✗ tool error`; `(injected)` = a skill body or subagent hand-back collapsed to one
  line. Every turn has a UTC timestamp. Large files: read by range; you only need
  to read up to the first failure, plus a few turns after it to confirm.
- The setup as it is NOW: `~/dotfiles/.claude/CLAUDE.md`, `~/dotfiles/.claude/README.md`,
  `~/dotfiles/.claude/agents/*.md`, `~/dotfiles/.claude/skills/*/SKILL.md`.
- How it changed: `git -C ~/dotfiles log --since=2026-09-01 --format='%ci %h %s' -- .claude`
  and `git -C ~/dotfiles show <sha>:.claude/CLAUDE.md` for the version in force at a
  given date. Key dates: lean workflow merged 2026-10-11 00:49 UTC (design record
  `~/dotfiles/.flow/specs/2026-10-10-lean-workflow-design.md`, L1–L11);
  `0fc330d` 2026-10-13 20:41 UTC rewrote CLAUDE.md (English, Rules section).

## What a failure is

The agent did something other than what the user asked, or what the setup's rules
in force at that turn required, or stated something false (claimed done without
proof, asserted a fact a tool could have checked). Not a failure: the user changing
their mind, an outage outside the agent's control, a tool the harness refused —
unless the agent then handled it wrongly.

## Method — per session

1. Read from the start. Stop at the FIRST agent failure; later problems are
   usually its consequences. No failure in the whole session → `first_failure: "OK"`.
2. Open note first, in your own words: one sentence on what the agent DID
   (observable behaviour), not why. Do not reach for a category list.
3. Anchor:
   - `user` — a later human turn reacts to this failure (correction, "dlaczego",
     "miałeś", interruption, repeated request). Quote that human turn.
   - `model` — no human reaction; the failure is your judgement alone. Be strict
     with yourself: only record it if the transcript shows it plainly.
4. Then the rule lens, separately: which CLAUDE.md / skill / agent rule this breaks
   (name the section and quote ≤15 words), or `none`.
5. `still_applies`: would the CURRENT setup most likely produce the same failure?
   `yes` (the rule/mechanism behind it is unchanged or absent), `no` (the mechanism
   was removed or a later rule targets exactly this — name it), `?`. One-line reason.

## Output

Write one JSON object per line to the file named in your task (JSONL), one line per
session, as you go — not at the end:

```json
{"file": "03-signal-092cfb9b.md", "stratum": "signal", "project": "...",
 "first_failure": "one sentence, or OK", "failure_ts": "2026-09-07T13:26",
 "agent_quote": "≤200 chars of agent prose, or the tool call line",
 "anchor": "user|model|none", "user_quote": "≤200 chars, or empty",
 "rule_lens": "section: quoted rule, or none",
 "still_applies": "yes|no|?", "still_applies_why": "one line",
 "cost": "time|wrong_result|annoyance|none"}
```

Quotes: human turns and agent prose only — never tool output, file contents, IPs,
hostnames, keys or tokens. Do not modify anything outside your output file.

## Report back

Only: the output path, number of sessions done, and the 2–3 patterns you saw
repeat across your batch (one line each). No per-session summaries.
