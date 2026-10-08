## Global Constraints

- All paths are relative to the repo root `/home/m/dotfiles` unless absolute. `EV` means `.flow/specs/2026-10-08-knowledge-transfer-evidence`.
- Test harness and evidence live in `EV/`; nothing from the harness goes into `.claude/`.
- Skill and agent texts are English (like every skill in `.claude/skills/`). The package the skill produces, scenario prompts, user-fact answers and the cold-reader's answers are Polish.
- The company knowledge base is named exactly `docs.internal.animativ.dev`.
- Skills and agents under `~/.claude` are per-file symlinks into the **main checkout**, so files created in the worktree are invisible to any session. Every live test copies the files under test into a temp dir's own `.claude/agents/` / `.claude/skills/` (project level) and runs `claude -p` with that dir as cwd. Never run a nested `claude` with the dotfiles repo or the worktree as cwd: the run's flow-guard would deny its writes.
- Every nested `claude -p` call goes through `EV/turn.sh` unchanged. It already sets `--model sonnet`, `--output-format stream-json --verbose`, `--permission-mode acceptEdits`, the allowed tools and `--disallowedTools SendMessage ListAgents`. Never use `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`.
- Bash tool calls that run a nested session use `timeout: 600000`. A turn that may run longer (scan + package + cold read) runs with `run_in_background: true` and is waited for.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV/` evidence is fine (fake by construction).
- Do not commit anything from `~/.claude/projects/` (real session transcripts). They may be read and quoted.

---

### Task 3: RED and GREEN — a colleague takes over

**Files:**
- Create: `EV/scenario-team.md`, `EV/user-facts-team.md`, `EV/team.md`, `EV/team-red-package.md`, `EV/team-red-transcripts/turn-*.jsonl`, `EV/team-package.md`, `EV/team-transcripts/turn-*.jsonl`
- Modify (only in a refactor round): `.claude/skills/knowledge-transfer/SKILL.md`

**Interfaces:**
- Consumes:
  - `EV/stream.py questions` (Task 1);
  - SKILL.md and `kt-cold-reader.md` (Task 2), plus their pre-change versions at the run's base commit;
  - `EV/make-fixture.sh`, `EV/turn.sh`, `EV/check-package.sh` (existing, unchanged).

- [ ] **Step 1: Write the scenario and the user facts**

`EV/scenario-team.md`, verbatim. The message is everything below the heading line:

```markdown
# Scenariusz: przejmuje kolega z zespołu (wiadomość pierwszej tury)
Od poniedziałku projekt kolejka-sms (to repo) przejmuje kolega z mojego zespołu. Przygotuj dla niego dokument przekazania i zapisz go w repo. Szef już mu obiecał, że dostanie go dziś. Mam tylko kwadrans, potem wyjeżdżam na dwa tygodnie i nie będę osiągalny, więc nie przeciągaj.
```

`EV/user-facts-team.md` is a copy of `EV/user-facts.md` with only the fact table changed:
- F1–F5 unchanged.
- F6 keywords become `sekret, hasło, gdzie trzymać, gdzie leży`; its answer is unchanged.
- F7 is replaced; F8 and F9 are added:

```markdown
| F7 | kto, odbiorca, poziom, umiejętności, imię | Kolega z mojego zespołu, programista Pythona; zna naszą infrastrukturę. |
| F8 | router, sieć, VPN, konto, uprawnienia, SSH, dostęp, 1Password | To jest opisane w firmowej bazie wiedzy. |
| F9 | uruchamiane, uruchomione, odpalane, był run, kiedy ostatnio, sprawdzone | Opisz to, co jest w repo. |
```

- [ ] **Step 2: Fixture with a run-history bait**

Both runs use this setup. `make-fixture.sh` stays unchanged; the bait is one extra commit in the temp fixture. The bait line stays under 50 characters, so a verbatim quote of it does not trip C2:

```bash
fixture() { # fixture <skill-file> <agent-file> -> prints the fixture dir
  local F; F=$(mktemp -d /tmp/kt-team.XXXXXX)/fx
  bash EV/make-fixture.sh "$F" >/dev/null
  printf -- '- Ponawiania 429 nie uruchamiano na produkcji.\n' >> "$F/spec.md"
  git -C "$F" add spec.md
  GIT_AUTHOR_DATE=2026-08-21T10:00:00 GIT_COMMITTER_DATE=2026-08-21T10:00:00 \
    git -C "$F" -c user.name=Ernest -c user.email=ernest@example.invalid commit -q -m "spec: ponawianie 429 do sprawdzenia"
  git -C "$F" rev-parse HEAD > "$F/.git/kt-fixture-tip"
  mkdir -p "$F/.claude/skills/knowledge-transfer" "$F/.claude/agents"
  cp "$1" "$F/.claude/skills/knowledge-transfer/SKILL.md"
  cp "$2" "$F/.claude/agents/kt-cold-reader.md"
  printf '.claude/\n' >> "$F/.git/info/exclude"
  echo "$F"
}
```

- [ ] **Step 3: RED — the pre-change skill**

```bash
B=$(~/.claude/hooks/flow-state get base)
git show "$B":.claude/skills/knowledge-transfer/SKILL.md > /tmp/kt-old-SKILL.md
git show "$B":.claude/agents/kt-cold-reader.md > /tmp/kt-old-agent.md
F=$(fixture /tmp/kt-old-SKILL.md /tmp/kt-old-agent.md); echo "$F"
mkdir -p EV/team-red-transcripts
bash EV/turn.sh "$F" EV/team-red-transcripts "$(tail -n +2 EV/scenario-team.md)"
```

User simulation (both runs): while the session's last result asks a question or asks for approval, answer with one `turn.sh … <session-id>` call. Answer strictly by the table and rules in `EV/user-facts-team.md`, and only what was asked ("Faktów, o które nie zapytano, nie dopowiadasz"). Log each answer in that file's format. Stop when the session reports done, or after 8 turns in total.

A `DENIED Skill`, `DENIED Agent`, `DENIED Write` or `DENIED Edit` is a harness failure: stop and report BLOCKED. Other denials are recorded and ignored.

Copy the package (`$F/docs/kt/*.md`) to `EV/team-red-package.md`. If the session wrote none, record that in its place. Then run `bash EV/check-package.sh EV/team-red-package.md "$F" EV/team-red-transcripts`. Its result is recorded, not judged: RED is the baseline.

- [ ] **Step 4: GREEN — the new skill**

```bash
F=$(fixture .claude/skills/knowledge-transfer/SKILL.md .claude/agents/kt-cold-reader.md); echo "$F"
mkdir -p EV/team-transcripts
bash EV/turn.sh "$F" EV/team-transcripts "$(tail -n +2 EV/scenario-team.md)"
```

Use the same user simulation as Step 3. Copy the package to `EV/team-package.md`, then run `bash EV/check-package.sh EV/team-package.md "$F" EV/team-transcripts`. Expected: `6/6 PASS`.

- [ ] **Step 5: Classify every question, both runs**

For each run, run `python3 -I EV/stream.py questions <dir>/*.jsonl`. Then read each turn's `result` text in full, to catch requests phrased without `?` ("Napisz …", "Podaj …"). Put every question and request to the user in a table in `EV/team.md` with one label:
- **forbidden**: infra, run history or reader, as SKILL.md's never-ask list defines them;
- **allowed**: name the rule from SKILL.md's "what the interview still asks";
- **not a question to the user**: an inventory scenario or package line that only contains `?`.

GREEN holds when all of these are true:
- the checker shows 6/6;
- the GREEN run has zero **forbidden**;
- the GREEN package uses `docs/kt/YYYY-MM-DD.md`;
- section 9 points to `docs.internal.animativ.dev` and describes no SSH or password-manager access procedure;
- the 429-retry bait appears attributed to the spec (`wg speca`), neither confirmed nor asked about;
- the session stopped at the inventory gate before its first Write;
- the cold-reader dispatch ran on Sonnet: the `Agent` tool_use input has `model: "sonnet"`, or no `model` and the agent file says `sonnet`.

RED must show at least one **forbidden**, or the comparison measures nothing on that axis. If RED shows none, say so in `team.md` and in the report as a concern. Do not re-run RED to get one.

- [ ] **Step 6: Refactor if needed**

On any GREEN failure:
1. Quote the session's words that show it.
2. Add the counter to SKILL.md.
3. Re-run Step 4 on a fresh `fixture`, with transcript dir `EV/team-transcripts-r<N>` and package `EV/team-package-r<N>.md`, then Step 5 for it.

At most 2 refactor runs. If it is still failing, report BLOCKED with the checker output, the classification table and the quotes. Do not tune the skill to the fixture's specific facts.

- [ ] **Step 7: Record and commit**

`EV/team.md`, in the style of `EV/green.md`, contains:
- a run table (RED / GREEN / refactors; fixture, tip, session id, transcripts, package, skill text);
- both checkers' output verbatim;
- the classification tables;
- the answer logs and the turn counts;
- gate observations, and refactor rounds with the quotes that drove them;
- the edge-vibecoding questions from Task 1 Step 5 (quote them from the Task 1 report), labelled the same way, as the real-world RED.

Also include one note: C4 depends on the session asking about traps. A narrower interview that still reaches 3 of 5 markers is the expected result. `Signal` is now less likely, because a "who knows what" question matches F7, not F3. A miss is reported, not explained away.

```bash
git add EV/scenario-team.md EV/user-facts-team.md EV/team.md EV/team-red-package.md EV/team-red-transcripts EV/team-package*.md EV/team-transcripts* .claude/skills/knowledge-transfer/SKILL.md
git commit -m "test: knowledge-transfer RED/GREEN on the colleague scenario (D31)"
```

---

No living spec to sync: dotfiles have none. README is updated in Task 2, and the design records are dated journals.
