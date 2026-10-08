# Task 3 report — DONE_WITH_CONCERNS

Commit: `2660463` test: knowledge-transfer RED/GREEN on the colleague scenario (D31). Full evidence is in
`.flow/specs/2026-10-08-knowledge-transfer-evidence/team.md` (EV = that dir); this report is the summary.

## What was done

- Step 1-2: `EV/scenario-team.md`, `EV/user-facts-team.md` (F6 keywords, F7 replaced, F8/F9 added), fixture recipe as a /tmp script.
- Step 3 RED: old skill from `cb4a9a0`, session `55263c6e-...`, 3 turns, package `team-red-package.md`.
- First GREEN attempt voided (harness failure, see below), kept as `team-green-void-*`.
- Resumed per the coordinator (option 1): throwaway `CLAUDE_CONFIG_DIR` (`/tmp/kt-config.lSMR8L`, symlinks only, minus the personal
  `knowledge-transfer` skill and `kt-cold-reader.md`), `turn.sh` unchanged. Sanity turn first: auth OK, `Base directory for this
  skill: /tmp/kt-team.VgRZ1h/fx/.claude/skills/knowledge-transfer`, fixture text contains `docs.internal.animativ.dev`.
- Step 4 GREEN: session `629bf395-e055-43bf-80fe-fe7ad83ce27d`, 3 turns, fixture `/tmp/kt-team.k2Y3j8/fx`, package `team-package.md`
  (`docs/kt/2026-10-08.md`). No refactor round needed.
- Step 5-7: classified both runs plus the 16 edge-vibecoding questions, wrote `team.md` (with a "Harness deviation" section and the
  C4 note), committed. SKILL.md untouched.

## Evidence

Voided run, turn-1 Skill result: `Base directory for this skill: /home/m/.claude/skills/knowledge-transfer` (personal symlink into
main, old text). Valid GREEN, turn-1 Skill result: `Base directory for this skill: /tmp/kt-team.k2Y3j8/fx/.claude/skills/knowledge-transfer`.

RED checker (old skill): 6/6 PASS. GREEN checker (new skill):

```
PASS C1 sekret
PASS C2 bez kopii speca
PASS C3 cold-reader
PASS C4 wiedza ukryta
PASS C5 snapshot
PASS C6 bez zmian w istniejących plikach
6/6 PASS
```

GREEN criteria (Step 5), all met:
- 6/6: yes. Zero forbidden questions: yes (4 interview questions, all allowed; 0 reader, 0 infra, 0 run-history).
- Package at `docs/kt/2026-10-08.md` (RED, old skill: `2026-10-08-nastepca.md`).
- Section 9: "Dostęp do `sms1` i pozostała infrastruktura firmowa: `docs.internal.animativ.dev`"; 1Password line is location only.
- 429 bait: "Ponawiania 429 nie uruchamiano na produkcji (wg speca)", not asked, not confirmed (RED stated it as fact).
- Gate: turn 1 = Skill/Bash/Read only; first Write in turn 2 after approval.
- Cold-reader `Agent` tool_use: `model: "sonnet"`, `subagent_type: kt-cold-reader`, foreground; fixture agent file `model: sonnet`
  and the personal agent file absent from the throwaway config.

TDD evidence (evidence-run task): RED command `bash /tmp/kt-turn.sh /tmp/kt-team.qmkcts/fx <EV>/team-red-transcripts /tmp/kt-msg1.txt`
(wrapper around `EV/turn.sh`, old skill) produced the old behaviour: assumed reader profile, `-nastepca` filename, bait stated
as fact, SMSAPI-account question, no `docs.internal.animativ.dev`. GREEN command `bash /tmp/kt-turn-cfg.sh /tmp/kt-team.k2Y3j8/fx
<EV>/team-transcripts /tmp/kt-msg1.txt` (same wrapper with `CLAUDE_CONFIG_DIR` set) produced the new behaviour above. The checker is
6/6 on both, so it does not discriminate RED from GREEN; the discrimination is the classification and the criteria list.

## Files changed (committed)

`EV/scenario-team.md`, `EV/user-facts-team.md`, `EV/team.md`, `EV/team-red-package.md`, `EV/team-red-transcripts/`,
`EV/team-package.md`, `EV/team-transcripts/`, `EV/team-green-void-package.md`, `EV/team-green-void-transcripts/`.
/tmp helper scripts and the throwaway config dir are not committed.

## Concerns

1. **Synthetic RED shows 0 forbidden** (brief Step 5 wants at least one). Not re-run, as instructed. The scenario names "kolega z
   zespołu", so the old skill never asked about the reader. The real-world RED (edge-vibecoding) carries the axis: 11 of 16 forbidden
   (9 clear, 2 borderline).
2. **SMSAPI-account-holder question** classified allowed ("project's own external dependency / who knows what"), rule named in
   `team.md`. The never-ask bullet says "accounts"; a stricter reader would count it forbidden (RED 1, GREEN 1).
3. **C4 `Signal` reached by a keyword accident** ("zgłasza" in a question about who submits orders matched F3), not by a
   who-knows-what question. VACUUM missing (F5 not asked); 4/5 markers. Reported in `team.md`.
4. **Cold-read gate**: 2 of 8 scenarios returned `NIE WIEM Z PAKIETU`; the session did not patch/re-run because the answer key was
   itself "unknown". Defensible, but literal SKILL.md wording says patch and re-run. Not changed.
5. The throwaway config dir makes Claude Code print "Claude configuration file not found" and create its own `.claude.json` there;
   session transcripts still land in the real `~/.claude/projects` through the symlink.
6. Known Minor residue (SKILL.md "recipient", agent description "Stand-in recipient") untouched; no GREEN failure traced to it.
