# Task 2 report: kt-cold-reader agent + isolation probe

## Implemented
- `.claude/agents/kt-cold-reader.md`: frontmatter verbatim from the brief; English body (role, no usable tools, never call TaskStop, NIE WIEM Z PAKIETU / ZGADUJĘ rules, Polish answer format, no code fence).
- `.flow/specs/2026-10-08-knowledge-transfer-evidence/probe-cold-reader.sh`: verbatim from the brief.
- `.flow/specs/2026-10-08-knowledge-transfer-evidence/probe.md`: RED and GREEN outputs.

## TDD evidence
RED: `bash EV/probe-cold-reader.sh /tmp/kt-cold-reader-open.md` (fixture without `tools:`, body says to Read). Output: `FAIL: agent read the file`, `FAIL: agent called tools: Read` plus Bash, `exit=1`. The read result was the token `KT-PROBE-2849214114`. Expected: the agent inherits Read, so the probe must catch the leak; it did.
GREEN: `bash EV/probe-cold-reader.sh .claude/agents/kt-cold-reader.md` gives `PROBE OK`, `exit=0`; read result `NIE WIEM Z PAKIETU`, answer result quotes `./deploy.sh prod` with `Podstawa: § Runbooki`, subagent tools `(none)`. The `tools: TaskStop` spawn worked (no zero-tools error). Full output in `probe.md`.

## Self-review
- First GREEN run passed but the answer was wrapped in a code fence (haiku copied the fenced format block). Added "no code fence around it" to the body and re-ran: passes, answer unfenced. The probe does not assert format; Task 5/6 should still check parsing.
- The body states that the harness hand-back is allowed implicitly ("other than what the harness itself needs to deliver your answer"), without naming it.
- Stderr of the nested claude prints "claude.ai MCP servers blocked by enterprise policy" warnings; harmless, they go to stderr only.

## Concerns
- Probe tests one read-scenario and one answer-scenario; a single sample per case for a haiku agent, so it is not a statistical guarantee.
- Probe wiring: the environment's shell refused compound commands in the worktree, so files were written with the Write tool; content equals the brief's.
