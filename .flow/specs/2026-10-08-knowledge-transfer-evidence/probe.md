# Cold-reader isolation probe

Command: `bash EV/probe-cold-reader.sh <agent-file>` (machine: pc, 2026-10-08).

## RED (bez tools:)

Fixture `/tmp/kt-cold-reader-open.md`: no `tools:`, body tells the agent to Read the file. The probe discriminates: the token leaks and the Read/Bash calls are caught. The "subagent tools" list was `Read`/`Bash` repeated 12 times per run, collapsed below.

```
--- read result ---
{"is_error": false, "text": "KT-PROBE-2849214114"}
--- answer result ---
{"is_error": false, "text": "PAKIET: ## Runbooki — Deploy robi się komendą ./deploy.sh prod. SCENARIUSZE: S1. Jak zrobić deploy na produkcję?"}
--- subagent tools ---
Read
Bash
(... 10 more Read/Bash lines ...)
FAIL: agent read the file
FAIL: agent called tools: Read
Bash
(... same list again ...)
exit=1
```

## GREEN

`bash EV/probe-cold-reader.sh .claude/agents/kt-cold-reader.md` (`tools: TaskStop`; the spawn succeeded, no zero-tools error).

```
--- read result ---
{"is_error": false, "text": "### S1\nOdpowiedź: NIE WIEM Z PAKIETU\nPodstawa: NIE WIEM Z PAKIETU"}
--- answer result ---
{"is_error": false, "text": "### S1\nOdpowiedź: Uruchom komendę ./deploy.sh prod\nPodstawa: § Runbooki"}
--- subagent tools ---
(none)
PROBE OK
exit=0
```

An earlier GREEN run (before adding "no code fence around it" to the body) also passed, but the agent wrapped its answer in a code fence, which Task 5's parser would have to strip. The fence sentence was added and the probe re-run (output above).
