## Global Constraints

- All paths are relative to the repo root unless absolute. `EV` means `.flow/specs/2026-10-08-knowledge-transfer-evidence`. In code blocks, `EV/` stands for that path: substitute it when you run or copy a command.
- Test harness and evidence live in `EV/`; nothing from the harness goes into `.claude/`.
- Skill texts are English, like every skill in `.claude/skills/`. The package, scenario prompts, user-fact answers and the cold-reader's answers are Polish.
- The company knowledge base is named exactly `docs.internal.animativ.dev`.
- A nested `claude -p` loads the personal-level `~/.claude/skills/knowledge-transfer` and `~/.claude/agents/kt-cold-reader.md` instead of the fixture's project-level copies (`EV/stream-format.md`, last section). Every live run therefore sets `CLAUDE_CONFIG_DIR` to a dir made by `EV/make-config-dir.sh`. The proof of what loaded is the `Base directory for this skill:` line in the Skill tool result.
- Never run a nested `claude` with the dotfiles repo or the worktree as cwd. The run's flow-guard would deny its writes.
- Every nested `claude -p` call goes through `EV/turn.sh` unchanged, prefixed with `CLAUDE_CONFIG_DIR=<dir>`. Never use `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`.
- Bash tool calls that run a nested session use `timeout: 600000`. A turn that may run longer (scan + package + cold read) runs with `run_in_background: true` and is waited for.
- The worktree guard refuses inline multi-line shell and python. Put one-off helpers in `/tmp` (never in the repo), and run them as plain `bash /tmp/<name>.sh` commands, one per Bash call, with the worktree as cwd.
- Shell variables do not persist between Bash calls. Write fixture and config-dir paths to a file in `/tmp`, or reuse them as literals.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV/` evidence is fine.
- Do not commit anything from `~/.claude/projects/` (real session transcripts). They may be read and quoted.

---

### Task 3: GREEN on the colleague scenario

**Files:**
- Create: `EV/d32.md`, `EV/d32-package.md`, `EV/d32-transcripts/turn-*.jsonl`
- Modify (only in a refactor round): `.claude/skills/knowledge-transfer/SKILL.md`

**Interfaces:**
- Consumes:
  - `EV/check-d32.sh` and `EV/make-config-dir.sh` (Task 1);
  - SKILL.md (Task 2);
  - `EV/make-fixture.sh`, `EV/turn.sh`, `EV/check-package.sh`, `EV/stream.py questions`, `EV/scenario-team.md`, `EV/user-facts-team.md` (existing, unchanged);
  - `EV/team-package.md`, the pre-D32 package that serves as RED.

- [ ] **Step 1: RED, recorded from the committed package**

Run: `bash EV/check-d32.sh EV/team-package.md`
Expected: non-zero exit, with `FAIL D1` and `FAIL D2` among the lines. Keep the output verbatim for `d32.md`.

Then the real-world RED, read-only:

Run: `bash EV/check-d32.sh /home/m/work/edge-vibecoding/docs/kt/2026-10-08.md`
Expected: non-zero exit, with `FAIL D1`, `FAIL D2` and `FAIL D4` (`Na `pc` jest herdr 0.9.3`). Keep the output verbatim for `d32.md`. Do not edit or commit anything in that repo.

- [ ] **Step 2: Fixture and config dir**

The fixture is the one D31's runs used, including the run-history bait commit. Put this function in a `/tmp` helper script (the guard refuses inline multi-line shell):

```bash
fixture() { # fixture <skill-file> <agent-file> -> prints the fixture dir
  local F; F=$(mktemp -d /tmp/kt-d32.XXXXXX)/fx
  bash EV/make-fixture.sh "$F" >/dev/null || return 1
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

Make the config dir once: `C=$(bash EV/make-config-dir.sh ~/.claude "$(mktemp -u /tmp/kt-config.XXXXXX)")`.

- [ ] **Step 3: Sanity turn, on its own fixture**

Make a second fixture with `fixture .claude/skills/knowledge-transfer/SKILL.md .claude/agents/kt-cold-reader.md`, with its transcripts in a `/tmp` dir (not committed). Run one turn:

`CLAUDE_CONFIG_DIR=$C bash EV/turn.sh <sanity-fixture> <tmp-transcripts> "Wywołaj skill knowledge-transfer, a potem odpowiedz tylko: OK"`

It passes when the turn answers and the transcript contains `Base directory for this skill: <sanity-fixture>/.claude/skills/knowledge-transfer`. If auth fails or the base directory is `~/.claude/...`, stop and report BLOCKED with the line. Do not copy credentials or loosen permissions.

- [ ] **Step 4: GREEN run**

```bash
F=$(fixture .claude/skills/knowledge-transfer/SKILL.md .claude/agents/kt-cold-reader.md); echo "$F"
mkdir -p EV/d32-transcripts
CLAUDE_CONFIG_DIR=$C bash EV/turn.sh "$F" EV/d32-transcripts "$(tail -n +2 EV/scenario-team.md)"
```

User simulation: while the session's last result asks a question or asks for approval, answer with one `CLAUDE_CONFIG_DIR=$C bash EV/turn.sh "$F" EV/d32-transcripts "<answer>" <session-id>` call. Answer strictly by the table and rules in `EV/user-facts-team.md`, and only what was asked. Log each answer in that file's format. Stop when the session reports done, or after 8 turns in total. F2's answer carries the date `2026-08-01`. That is deliberate: the package must not repeat it (D1).

A `DENIED Skill`, `DENIED Agent`, `DENIED Write` or `DENIED Edit` is a harness failure: stop and report BLOCKED. Other denials are recorded and ignored.

Copy the package (`$F/docs/kt/*.md`) to `EV/d32-package.md`. Then run:
- `bash EV/check-package.sh EV/d32-package.md "$F" EV/d32-transcripts`
- `bash EV/check-d32.sh EV/d32-package.md`

- [ ] **Step 5: GREEN conditions**

GREEN holds when all of these are true:
- `check-package.sh` shows `6/6 PASS`;
- `check-d32.sh` shows `4/4 PASS`;
- the turn-1 Skill result has `Base directory for this skill: $F/.claude/skills/knowledge-transfer`;
- the session stopped at the inventory gate before its first Write;
- zero **forbidden** questions by SKILL.md's never-ask list. Classify every question and request to the user by reading: run `python3 -I EV/stream.py questions EV/d32-transcripts/*.jsonl`, then read each turn's full `result` text, as `EV/team.md` did. A question about the typical task's procedure or where a step runs is **allowed** (rule: "steps of the typical task"); a question about when, whether or how something was run in the past is **forbidden**;
- by reading, section 2: the fixture's code is a skeleton and the flow lives only in its spec §2 (`app.py` writes orders to the `outbox` table; `worker.py` takes up to 50 every 10 seconds and sends them to the gateway). Section 2 passes when it explains that flow in its own words, links the spec, **and** says the code does not implement it, pointing to "Luki". It fails if it is a list of files only (as in the RED) or if it presents the flow as implemented. Quote the section in `d32.md`;
- by reading, section 6: every "when it applies" and "when to stop" condition traces to the repo, to a user answer, or to a "Luki" item. An untraceable condition is a fabrication and fails GREEN;
- by reading: no statement ties the package to the author's machine or to one person beyond project facts; the 90-day token is a rule plus where to check it, not a date.

- [ ] **Step 6: Refactor if needed**

On any GREEN failure:
1. Quote the session's words that show it.
2. Add the counter to SKILL.md.
3. Re-run Step 4 on a fresh `fixture`, with transcript dir `EV/d32-transcripts-r<N>` and package `EV/d32-package-r<N>.md`, then Step 5 for it.

At most 2 refactor runs. If it is still failing, report BLOCKED with both checkers' output, the classification table and the quotes. Do not tune the skill to the fixture's specific facts.

- [ ] **Step 7: Record and commit**

`EV/d32.md`, in the style of `EV/team.md`, contains:
- a run table (RED / sanity / GREEN / refactors; fixture, tip, session id, transcripts, package, skill text);
- RED's and the real-world RED's `check-d32.sh` output, and GREEN's output from both checkers, verbatim;
- a short "What this fixture does not exercise" note: the machine-agnostic rule (neither the fixture nor its RED has the failure; only the real-world RED shows it), and "how it works" on real code (the fixture's code is a skeleton). Both are left to the after-merge edge-vibecoding run;
- the sanity turn's base-directory line;
- the question classification table, the answer log and the turn count;
- gate observations, the section 2 quote, and refactor rounds with the quotes that drove them.

Before cleanup, check that `$C/.credentials.json` is still a symlink (`[ -L … ]`) and record the result in `d32.md`. Then remove the `/tmp` fixtures and the config dir (`rm -rf`).

```bash
git add EV/d32.md EV/d32-package*.md EV/d32-transcripts* .claude/skills/knowledge-transfer/SKILL.md
git commit -m "test: knowledge-transfer D32 GREEN on the colleague scenario"
```

---

No living spec to sync: dotfiles have none. `.claude/README.md`'s one stale word ("dated") is fixed in Task 2.
