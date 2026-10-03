# Setup performance audit rollout — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cut the per-request baseline (main ~49K, subagent ~40K tokens), hidden `agent_summary` traffic and hook latency of the Claude Code setup, as decided in D1–D28.

**Architecture:** Mostly configuration (`.claude/settings.json`, agent frontmatter, per-repo `settings.local.json`), plus small changes to the flow hooks (`flow-state`, `task-brief`, `statusline`, `prompt-context`) under the existing bash test harness `hooks/flow-guard-test`, and text edits to the pipeline skills.

**Tech Stack:** Claude Code 2.1.284 settings schema, python3 (stdlib only) hooks, bash test harness, dotter (`.dotter/global.toml` maps `.claude/*` and `bin/` into `~` file by file).

**Spec:** none — dotfiles have no living `spec.md`; decisions D1–D28 live in the design record.

**Design record:** `/home/m/dotfiles/.flow/specs/2026-10-03-setup-perf-audit-design.md` (evidence: `/home/m/dotfiles/.flow/specs/2026-10-03-setup-perf-audit.md`)

## Global Constraints

- Do not touch `config/`, `hosts/`, or `config/mimeapps.list` — unrelated user changes live there.
- Hooks and scripts stay python3/bash with the standard library only; keep each file's existing style and comment density.
- `.claude/settings.json`: valid JSON, 2-space indentation, existing key order kept where a key survives.
- `CLAUDE.md` stays Polish; skills, agents and README stay English.
- The hook test suites must end green: `/home/m/dotfiles/.claude/hooks/flow-guard-test` and `/home/m/dotfiles/.claude/hooks/prompt-context-test` (run them from the worktree path — they test the files beside them).
- Cite code in docs by path and symbol, never by line number.
- The repo is PUBLIC and run reports under `.flow/sdd/` get committed: never copy the contents of any `settings.local.json`, `.credentials*`, `~/.claude.json` or env values into a report, test, script or commit — key names only (`python3 -c 'import json,sys; print(sorted(json.load(open(sys.argv[1]))))' FILE`).
- Run commands with literal paths (no `$(…)`, no `VAR=$(…) cmd $VAR`): the harness's worktree guard refuses computed commands. Throwaway check scripts live in `.flow/sdd/2026-10-03-setup-perf-audit/` and resolve their root from their own path.
- Live config is the main checkout (`~/.claude/*` symlinks into `/home/m/dotfiles`), so nothing in the worktree takes effect until merge + `dotter deploy`; verify settings with `claude --settings <file>`.

---

### Task 1: settings.json — the config package, verified against the real CLI

**Files:**
- Modify: `.claude/settings.json`
- Delete: `.claude/hooks/cbm-code-discovery-gate`, `.claude/hooks/cbm-subagent-reminder`
- Test: `.claude/hooks/flow-guard-test` (section `=== settings.json wiring ===`), `.claude/hooks/prompt-context-test` (wiring block at its end)

**Interfaces:**
- Consumes: nothing.
- Produces: the settings every later task assumes; `PreToolUse` Bash entry carries `"if": "Bash(*worktree add*)"`.

- [ ] **Step 1: Write the failing tests**

Only structural wiring goes into the suite — values such as `model` or `modelSettings` are rewritten by the CLI itself (`/model`, `/effort`, the first Workflow approval) and would make the suite flap; they are checked once in Step 5. In `flow-guard-test`, at the end of the `=== settings.json wiring ===` section (after the `statusLine points at the flow status line` check), append:

```bash
setting 'any(h.get("if") == "Bash(*worktree add*)" for e in cfg["hooks"]["PreToolUse"] if e.get("matcher") == "Bash" for h in e["hooks"])' \
  && report ok "flow-guard on Bash only spawns for worktree add" || report no "Bash flow-guard has no if filter"
setting 'not any("Grep" in (e.get("matcher") or "") for e in cfg["hooks"]["PreToolUse"])' \
  && report ok "dead Grep|Glob augmenter removed" || report no "Grep|Glob augmenter still wired"
[ ! -e "$HERE/cbm-code-discovery-gate" ] && [ ! -e "$HERE/cbm-subagent-reminder" ] \
  && report ok "removed cbm hook files are gone" || report no "cbm hook files still present"
```

In `prompt-context-test`, replace the `wired SubagentStart "" cbm-subagent-reminder` check (3 lines) with:

```bash
wired SubagentStart "" cbm-subagent-reminder \
  && report no "cbm-subagent-reminder is still wired (removed by D13)" \
  || report ok "cbm-subagent-reminder is no longer wired"
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.claude/hooks/flow-guard-test | grep -E '^FAIL'; .claude/hooks/prompt-context-test | grep -E '^FAIL'`
Expected: `FAIL  Bash flow-guard has no if filter`, `FAIL  Grep|Glob augmenter still wired`, `FAIL  cbm hook files still present` and `FAIL  cbm-subagent-reminder is still wired (removed by D13)` — assertion failures, not a harness crash.

- [ ] **Step 3: Implement**

Edit `.claude/settings.json`. The worktree is cut from HEAD, which has no `model`, `agentPushNotifEnabled` or `skipWorkflowUsageWarning` keys (those exist only as uncommitted edits in the laptop main checkout) — so below "add" means add:
- `env`: add `"CLAUDE_CODE_FORK_SUBAGENT": "0"` and `"CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS": "1"`.
- `permissions`: add `"deny": ["ReportFindings", "ShareOnboardingGuide"]` after `allow`.
- Add `"model": "sonnet"` right after `permissions`.
- `hooks.PreToolUse`: delete the `Grep|Glob` entry; on the `Bash` entry's flow-guard handler add `"if": "Bash(*worktree add*)"`. `hooks.SubagentStart`: delete the `cbm-subagent-reminder` handler (keep `flow-context` and `prompt-context`).
- `enabledPlugins`: `"claude-code-wakatime@wakatime": false`, `"cloudflare@cloudflare": false`, add `"cowork-plugin-management@synced": false`; others unchanged.
- Replace `"effortLevel"` and `"modelSettings"` with `"modelSettings": {"claude-sonnet-5-5": {"effortLevel": "high"}, "claude-opus-5-5": {"effortLevel": "high"}}`.
- Add `"agentPushNotifEnabled": false` (an explicit false blocks server-side hydration); do not add `skipWorkflowUsageWarning`.
- Add, before `"tui"`:

```json
  "skillOverrides": {
    "anthropic-skills:cloudflare": "off",
    "anthropic-skills:cloudflare-email-service": "off",
    "anthropic-skills:cloudflare-one": "off",
    "anthropic-skills:workers-best-practices": "off",
    "anthropic-skills:wrangler": "off",
    "anthropic-skills:google-workspace": "off",
    "anthropic-skills:import-memory": "off",
    "anthropic-skills:the-humanizer": "user-invocable-only",
    "anthropic-skills:docs": "name-only",
    "anthropic-skills:pdf": "name-only",
    "anthropic-skills:docx": "name-only",
    "anthropic-skills:pptx": "name-only",
    "anthropic-skills:xlsx": "name-only",
    "dataviz": "name-only",
    "update-config": "name-only",
    "artifact-capabilities": "name-only",
    "artifact-diagramming": "name-only",
    "artifact-design": "name-only",
    "schedule": "name-only",
    "loop": "name-only",
    "code-review": "user-invocable-only",
    "simplify": "user-invocable-only",
    "security-review": "user-invocable-only",
    "keybindings-help": "user-invocable-only",
    "fewer-permission-prompts": "user-invocable-only",
    "init": "user-invocable-only"
  },
  "deniedMcpServers": [
    {"serverName": "claude.ai Claude Docs"},
    {"serverName": "claude.ai Canva"},
    {"serverName": "claude.ai Microsoft 365"}
  ],
  "enableArtifact": false,
  "autoCompactWindow": 500000,
  "cleanupPeriodDays": 90,
  "promptSuggestionEnabled": false,
```

Then `git rm .claude/hooks/cbm-code-discovery-gate .claude/hooks/cbm-subagent-reminder`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m json.tool .claude/settings.json >/dev/null && .claude/hooks/flow-guard-test | tail -1 && .claude/hooks/prompt-context-test | tail -1`
Expected: both suites print `N passed, 0 failed`.

- [ ] **Step 5: Verify values and knobs against the real CLI (external dependency)**

Several keys are undocumented or documented as enterprise-only (`deniedMcpServers`), and the `if` filter gates the one-workspace guard — check them deterministically, not by asking a model. Use the literal worktree path printed by `~/.claude/hooks/flow-state get worktree` (written `<WT>` below).

1. Values: `python3 -c 'import json; c=json.load(open("<WT>/.claude/settings.json")); print(c["model"], c["modelSettings"], c["env"], c["autoCompactWindow"], c["cleanupPeriodDays"], c["enableArtifact"], c["promptSuggestionEnabled"], c["agentPushNotifEnabled"], "skipWorkflowUsageWarning" in c, c["permissions"]["deny"], c["deniedMcpServers"], c["enabledPlugins"], len(c["skillOverrides"]))'` — expect `sonnet`, both 5.5 keys at high, the two new env vars, `500000 90 False False False False`, the deny list, three denied servers, cloudflare/wakatime/cowork `false`, `26`.
2. Init event: from `/tmp`, `claude -p --model haiku --settings <WT>/.claude/settings.json --output-format stream-json --verbose 'reply ok' > /tmp/sp-after.jsonl`, and the same without `--settings` into `/tmp/sp-before.jsonl`. From each file's `{"type":"system","subtype":"init"}` event list `tools`, `mcp_servers`, `plugins`, `skills`. Expected after: no `Artifact`, `ReportFindings`, `ShareOnboardingGuide`; no `claude.ai Claude Docs`/`Canva`/`Microsoft 365` server; ClickUp present; no cloudflare plugin, MCP server or skills; no wakatime or cowork plugin; `init`/`code-review` still user-invocable. The before file shows them.
3. Skill listing as the model sees it: in the transcript of the after-run (`~/.claude/projects/-tmp/<session>.jsonl`, newest file), the skill-listing attachment has no `anthropic-skills:cloudflare`, `wrangler`, `google-workspace`, `import-memory`; `dataviz` and `anthropic-skills:docx` appear without a description; `code-review`, `init`, `anthropic-skills:the-humanizer` are absent.
4. The `if` filter: in a scratch repo (`git init /tmp/if-check && git -C /tmp/if-check commit --allow-empty -m x`), run `claude -p --model haiku --settings <WT>/.claude/settings.json --debug 'run the shell command: ls'` and `… 'run the shell command: git -C /tmp/if-check worktree add /tmp/if-check-wt'`; the debug output shows the flow-guard hook skipped (`Skipping hook due to if condition`) for `ls` and executed for `git … worktree add`. Remove `/tmp/if-check*` afterwards.

Paste the relevant lines (names only, no env values) into the report. If a knob did not take effect, report DONE_WITH_CONCERNS naming the key — do not invent a substitute.

- [ ] **Step 6: Commit**

```bash
git add .claude/settings.json .claude/hooks/flow-guard-test .claude/hooks/prompt-context-test
git commit -m "settings: audit config package (D2-D9, D11, D13-D16)"
```

---

### Task 2: Cloudflare plugin per repository

**Files (outside the repo — mutagen-synced to both machines; not committed anywhere):**
- Create or modify `.claude/settings.local.json` in: `/home/m/obsidian`, `/home/m/work/kid-aid-recordings-worker`, `/home/m/work/knowledge-base`, `/home/m/projects/ernest`, `/home/m/work/justom-static`, `/home/m/work/kid-aid-website-2026`, `/home/m/projects/cloud` (7 directories — `~/work/infrastructure-cloud` from the record does not exist)

**Interfaces:**
- Consumes: Task 1's `"cloudflare@cloudflare": false` at user scope.
- Produces: nothing later tasks use.

- [ ] **Step 1: Write the failing check** — save as `.flow/sdd/2026-10-03-setup-perf-audit/cf-check.py` in the worktree:

```python
import json, os, sys
DIRS = ["/home/m/obsidian", "/home/m/work/kid-aid-recordings-worker", "/home/m/work/knowledge-base",
        "/home/m/projects/ernest", "/home/m/work/justom-static", "/home/m/work/kid-aid-website-2026",
        "/home/m/projects/cloud"]
bad = []
for d in DIRS:
    if not os.path.isdir(d):
        print(f"skip (missing): {d}"); continue
    p = os.path.join(d, ".claude", "settings.local.json")
    try:
        cfg = json.load(open(p))
    except (OSError, ValueError) as e:
        bad.append(f"{p}: {e}"); continue
    if cfg.get("enabledPlugins", {}).get("cloudflare@cloudflare") is not True:
        bad.append(f"{p}: cloudflare not enabled")
print("\n".join(bad) or "all present directories enabled")
sys.exit(1 if bad else 0)
```

- [ ] **Step 2: Run it to verify it fails**

Run (from the worktree): `python3 .flow/sdd/2026-10-03-setup-perf-audit/cf-check.py`
Expected: exit 1, lines naming the directories without the key. Record in the report which files already exist and their **top-level key names only** — at least one holds an API key in `env`; never `cat` these files (Global Constraints).

- [ ] **Step 3: Implement** — for each existing directory, load `settings.local.json` if present (else `{}`), set `enabledPlugins["cloudflare@cloudflare"] = true` keeping every other key and value untouched, write back with 2-space indent. Before writing, copy each pre-existing file to `<file>.bak-2026-10-03` beside it.

- [ ] **Step 4: Run it to verify it passes**

Run: `python3 .flow/sdd/2026-10-03-setup-perf-audit/cf-check.py`
Expected: `all present directories enabled`, exit 0. For each pre-existing file, compare with its backup in python: the loaded dicts differ only in `enabledPlugins["cloudflare@cloudflare"]` (print `same except enabledPlugins` — never the values). Then delete the backups.

- [ ] **Step 5: Commit** — `git add .flow/sdd/2026-10-03-setup-perf-audit/cf-check.py && git commit -m "chore: cloudflare per-repo enablement check (D11)"`.

---

### Task 3: agent definitions — Artifact and Skill off, reviewers build their own diff package

**Files:**
- Modify: `.claude/agents/implementer.md`, `.claude/agents/fixer.md`, `.claude/agents/task-reviewer.md`, `.claude/agents/branch-reviewer.md`, `.claude/agents/plan-red-team.md`
- Modify: `.claude/skills/subagent-driven-development/SKILL.md` (per-task loop step 5 and the "Your prompt supplies" table), `.claude/skills/requesting-code-review/SKILL.md` (How, step 2 and step 3)
- Test: `.claude/hooks/flow-guard-test` (new section)

**Interfaces:**
- Consumes: `review-package BASE HEAD` (existing; exit 4 = empty range).
- Produces: reviewers' prompts now carry BASE and HEAD instead of a diff-package path.

- [ ] **Step 1: Write the failing tests** — append to the end of the existing `=== agent definitions ===` section of `flow-guard-test` (no second header):

```bash
AG=$(cd "$HERE/../agents" && pwd)
fm() { awk '/^---$/{n++; next} n==1' "$AG/$1.md"; }
for a in implementer fixer task-reviewer branch-reviewer plan-red-team; do
  d=$(fm "$a" | grep '^disallowedTools:')
  case "$d" in *Artifact*Skill*|*Skill*Artifact*) report ok "$a withholds Artifact and Skill";;
    *) report no "$a withholds Artifact and Skill" "$d";; esac
done
for a in task-reviewer branch-reviewer; do
  grep -q 'scripts/review-package' "$AG/$a.md" && grep -q 'exit 4' "$AG/$a.md" && grep -q 'BLOCKED' "$AG/$a.md" \
    && report ok "$a builds its own diff package; exit 4 is BLOCKED" || report no "$a review-package step"
done
for a in implementer fixer; do
  grep -q 'polszczyzna/SKILL.md' "$AG/$a.md" && grep -q 'systematic-debugging/SKILL.md' "$AG/$a.md" \
    && report ok "$a knows the skill files it can no longer invoke" || report no "$a skill pointers"
done
SK=$(cd "$HERE/../skills" && pwd)
for f in subagent-driven-development/SKILL.md requesting-code-review/SKILL.md; do
  grep -qE 'PKG=|generate the review package|without a diff file|\[review-package|Package it with' "$SK/$f" \
    && report no "$f still has the controller build the review package" || report ok "$f: reviewer builds the package"
done
grep -q 'BLOCKED' "$SK/subagent-driven-development/SKILL.md" && grep -q 'git log --all --oneline -5' "$SK/subagent-driven-development/SKILL.md" \
  && report ok "SDD says what a reviewer BLOCKED on an empty range means" || report no "SDD reviewer BLOCKED handling"
```

- [ ] **Step 2: Run to verify it fails**

Run: `.claude/hooks/flow-guard-test | grep -E 'Artifact and Skill|diff package|skill pointers|knows the skill|review package|builds the package|BLOCKED'`
Expected: FAIL for all five agents, both reviewers, both writers' pointers, both skills, and the BLOCKED check.

- [ ] **Step 3: Implement**
- Frontmatter: implementer and fixer get `disallowedTools: Artifact, Skill` (they have none today); task-reviewer, branch-reviewer, plan-red-team become `disallowedTools: Edit, Write, NotebookEdit, Artifact, Skill`. `skills: test-driven-development` stays — preloading does not need the Skill tool.
- implementer.md and fixer.md: two sentences — "You have no Skill tool. Text in Polish meant for people (docs, spec.md, Polish commit messages): read `~/.claude/skills/polszczyzna/SKILL.md` first. A bug or unexpected test result: read `~/.claude/skills/systematic-debugging/SKILL.md` and follow it."
- task-reviewer.md, section "The diff is your view of the change": first instruction becomes "Your prompt gives BASE and HEAD. Run `~/.claude/skills/subagent-driven-development/scripts/review-package <BASE> <HEAD>` (literal SHAs) and read the file it prints, once. Exit 4 means the range has no commits: report BLOCKED with its message — never APPROVED." Replace "If the file is missing, fall back to…" accordingly. Same for branch-reviewer.md ("What you are given" says BASE and HEAD instead of "a diff file").
- SDD per-task loop: delete step 5 (Review package) and renumber; step 6 (now 5) says the reviewer gets BASE and HEAD and builds the package itself; on a re-review pass the same `BASE` and the new HEAD. In the "Your prompt supplies" table, task-reviewer: "brief path, implementer report path, BASE and HEAD…" (drop "diff-package path"); branch-reviewer: "…BASE and HEAD…" (drop the package path).
- SDD, the other places that still have the controller package the diff: "Implementer status — **DONE** → generate the review package and review" becomes "→ dispatch the task reviewer with BASE and HEAD"; the Example line `[review-package … → dispatch task reviewer]` becomes `[dispatch task reviewer with BASE..HEAD]`; the "Never" item "Dispatch a reviewer without a diff file" becomes "Dispatch a reviewer without BASE and HEAD".
- SDD, after the reviewer step: "A reviewer BLOCKED on 'no commits in BASE..HEAD' means the implementer's commits are not in this tree: find them (`git log --all --oneline -5`) before anything else — never re-dispatch the reviewer unchanged." This replaces the empty-range guidance that lived in the deleted step 5.
- requesting-code-review: delete step 2 (Package the diff) and renumber; step 3 (now 2) prompt carries BASE and HEAD, no package path; step 4's "Package it with `review-package <fixbase> HEAD`" becomes "dispatch the re-review with BASE = the fix base and HEAD".

- [ ] **Step 4: Run to verify it passes**

Run: `.claude/hooks/flow-guard-test | tail -1`
Expected: `N passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/agents .claude/skills/subagent-driven-development/SKILL.md .claude/skills/requesting-code-review/SKILL.md .claude/hooks/flow-guard-test
git commit -m "agents: no Artifact/Skill; reviewers build their own diff package (D9, D12, D18)"
```

---

### Task 4: literal commands — flow-state resolves `.` and `HEAD`, task-brief finds the plan (E4)

**Files:**
- Modify: `.claude/hooks/flow-state` (`main`, commands `set` and `task`; the worktree error hint)
- Modify: `.claude/skills/subagent-driven-development/scripts/task-brief` (argument handling)
- Modify: `.claude/skills/using-git-worktrees/SKILL.md` (Step 1 ignore check, Step 2 record), `.claude/skills/subagent-driven-development/SKILL.md` (per-task loop steps 1–2), `.claude/skills/requesting-code-review/SKILL.md` (How, step 1)
- Test: `.claude/hooks/flow-guard-test` (new section)

**Interfaces:**
- Consumes: nothing new.
- Produces: `flow-state set worktree=. branch=. base=HEAD` (resolved against `--cwd`/cwd: worktree → `git rev-parse --show-toplevel`, branch → `git branch --show-current`, base → `git rev-parse HEAD`); `flow-state task N STATUS "base=HEAD …"` (and `fixbase=HEAD`) stores the resolved SHA in the note; `task-brief N` (one argument) reads the plan from `flow-state get plan`.

- [ ] **Step 1: Write the failing tests** — append to `flow-guard-test` before the final summary line:

```bash
echo "=== literal values in flow-state and task-brief (E4) ==="
LIT=$ROOT/literal; mkrepo "$LIT" >/dev/null || fixture_fail "literal repo"
"$STATE" --cwd "$LIT" init lit >/dev/null
"$STATE" --cwd "$LIT" set stage=isolate worktree=. branch=. base=HEAD >/dev/null 2>&1
[ "$("$STATE" --cwd "$LIT" get worktree)" = "$(git -C "$LIT" rev-parse --show-toplevel)" ] \
  && report ok "worktree=. resolves to the toplevel" || report no "worktree=." "$("$STATE" --cwd "$LIT" get worktree)"
[ "$("$STATE" --cwd "$LIT" get branch)" = "$(git -C "$LIT" branch --show-current)" ] \
  && report ok "branch=. resolves to the current branch" || report no "branch=."
[ "$("$STATE" --cwd "$LIT" get base)" = "$(git -C "$LIT" rev-parse HEAD)" ] \
  && report ok "base=HEAD resolves to a SHA" || report no "base=HEAD" "$("$STATE" --cwd "$LIT" get base)"
"$STATE" --cwd "$LIT" task 1 started "base=HEAD model=sonnet" >/dev/null 2>&1
note=$("$STATE" --cwd "$LIT" get tasks | python3 -c 'import json,sys; t=json.load(sys.stdin); print(t[0].get("note","") if t else "")')
[ "$note" = "base=$(git -C "$LIT" rev-parse HEAD) model=sonnet" ] \
  && report ok "task note base=HEAD is stored resolved" || report no "task note" "$note"
"$STATE" --cwd "$LIT" task branch-review started "fixbase=HEAD" >/dev/null 2>&1
note=$("$STATE" --cwd "$LIT" get tasks | python3 -c 'import json,sys; print([t.get("note","") for t in json.load(sys.stdin) if t["n"]=="branch-review"][0])')
[ "$note" = "fixbase=$(git -C "$LIT" rev-parse HEAD)" ] \
  && report ok "task note fixbase=HEAD is stored resolved" || report no "fixbase note" "$note"
out=$("$STATE" --cwd "$LIT" set worktree=relative/path 2>&1)
case "$out" in *'worktree=.'*) report ok "relative-worktree error suggests worktree=.";;
  *) report no "relative-worktree hint" "$out";; esac
case "$out" in *'$('*) report no "hint still recommends command substitution" "$out";; *) report ok "hint has no command substitution";; esac
mkdir -p "$LIT/.flow/plans"
printf '# P\n\n## Global Constraints\n\nNone.\n\n### Task 1: one\n\nbody-one\n' > "$LIT/.flow/plans/p.md"
"$STATE" --cwd "$LIT" set plan="$LIT/.flow/plans/p.md" >/dev/null
TB=$(cd "$HERE/../skills/subagent-driven-development/scripts" && pwd)/task-brief
brief=$(cd "$LIT" && "$TB" 1 2>/dev/null)
[ -n "$brief" ] && grep -q body-one "$brief" \
  && report ok "task-brief N reads the plan from flow-state" || report no "task-brief N without a plan path" "$brief"
```

- [ ] **Step 2: Run to verify it fails**

Run: `.claude/hooks/flow-guard-test | grep -E 'resolves|stored resolved|worktree=\.|substitution|reads the plan'`
Expected: FAIL on each (today `worktree=.` dies with "worktree must be absolute", `branch=.` stores a literal dot, `task-brief 1` prints its usage).

- [ ] **Step 3: Implement**
- `flow-state` `set`: before validation, map literal values — `worktree=.` → toplevel of the effective cwd (use the module's `git(cwd, "rev-parse", "--show-toplevel")`), `branch=.` → `git(cwd, "branch", "--show-current")`, `base=HEAD` → `git(cwd, "rev-parse", "HEAD")`; die with a clear message if git fails. Relative-worktree error hint becomes: ``worktree must be absolute — the hooks compare realpaths: use `worktree=.` from inside the worktree``.
- `flow-state` `task`: in the note, replace a `base=HEAD` or `fixbase=HEAD` token with the resolved full SHA from the effective cwd.
- `task-brief`: accept `task-brief N [OUTFILE]` when the first argument is all digits — then `plan=$(<.claude>/hooks/flow-state get plan)` where the hooks dir is resolved from the script's realpath (`readlink -f "$0"` → `scripts` → `subagent-driven-development` → `skills` → `.claude`); keep the existing `PLAN N [OUTFILE]` form. Update the usage line and header comment.
- using-git-worktrees Step 1: move the ignore check **before** `EnterWorktree`, run in the main checkout as literal commands: `mkdir -p .claude/worktrees && git check-ignore -q .claude/worktrees || { echo '.claude/worktrees/' >> .gitignore && git add .gitignore && git commit -m "chore: ignore worktrees"; }` (the directory exists, so check-ignore answers correctly; the commit lands on HEAD before the branch is cut). Drop the `MAIN=$(…)` block and the paragraph about running the check after creation.
- using-git-worktrees Step 2: `~/.claude/hooks/flow-state set stage=isolate worktree=. branch=. base=HEAD`.
- SDD per-task loop step 1: `~/.claude/skills/subagent-driven-development/scripts/task-brief N` (prints the brief path); step 2: `~/.claude/hooks/flow-state task N started "base=HEAD model=<haiku|sonnet>"`, then read the base back with `~/.claude/hooks/flow-state get tasks` when the reviewer needs it.
- requesting-code-review step 1: `~/.claude/hooks/flow-state get base` and `git rev-parse HEAD` as two separate literal commands; fall back to `git merge-base HEAD main` as its own command; pass the printed SHAs on. Step 4 (the fix range): `flow-state task branch-review started "fixbase=$(git rev-parse --short HEAD)"` becomes `~/.claude/hooks/flow-state task branch-review started "fixbase=HEAD"`.
- Add to the Step 1 tests: `grep -qE '\$\(' "$SK/using-git-worktrees/SKILL.md" "$SK/requesting-code-review/SKILL.md" && report no "skills still prescribe \$(…) commands" || report ok "worktree/review skills prescribe literal commands"` (with `SK=$(cd "$HERE/../skills" && pwd)` if not yet defined in that section); in SDD check only the per-task loop: `awk '/^## The per-task loop/,/^## Implementer status/' "$SK/subagent-driven-development/SKILL.md" | grep -q '\$(' && report no "SDD loop still uses \$(…)" || report ok "SDD loop is literal"`.

- [ ] **Step 4: Run to verify it passes**

Run: `.claude/hooks/flow-guard-test | tail -1`
Expected: `N passed, 0 failed` (all earlier sections still green, including the fixture's absolute-path `set`).

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/flow-state .claude/hooks/flow-guard-test .claude/skills/subagent-driven-development .claude/skills/using-git-worktrees/SKILL.md .claude/skills/requesting-code-review/SKILL.md
git commit -m "flow: literal workspace commands the worktree guard accepts (D17)"
```

---

### Task 5: status line limits and absolute context; cheaper hook starts

**Files:**
- Modify: `.claude/hooks/statusline` (`context_segment`, `cost_segment`, new `limits_segment`, `git`, `main`)
- Modify: `.claude/hooks/prompt-context` (module imports)
- Test: `.claude/hooks/flow-guard-test` (section `=== status line ===`)

**Interfaces:**
- Consumes: statusLine payload fields verified in the 2.1.284 bundle: `context_window.total_input_tokens` (int, current prompt size = input + cache creation + cache read), `rate_limits.five_hour` / `rate_limits.seven_day` each `{used_percentage: number, resets_at: epoch seconds}`, either may be absent or null.
- Produces: `limits_segment(payload) -> str | None`.

- [ ] **Step 1: Write the failing tests** — append to the `=== status line ===` section of `flow-guard-test`, after `status line survives junk input`:

```bash
sl_rl() { python3 -c '
import json, sys
print(json.dumps({"workspace": {"current_dir": sys.argv[1], "project_dir": sys.argv[1]},
  "model": {"display_name": "Sonnet 5.5"},
  "context_window": {"used_percentage": 40, "total_input_tokens": int(sys.argv[2])},
  "rate_limits": {"five_hour": {"used_percentage": float(sys.argv[3]), "resets_at": 1790000000},
                  "seven_day": {"used_percentage": 12.0, "resets_at": 1790500000}},
  "cost": {"total_cost_usd": 3.21, "total_lines_added": 9, "total_lines_removed": 2}}))' "$@"; }
line=$(sl_rl "$COLD" 412000 93 | "$SL" | head -1)
case "$line" in *'$'*) report no "status line still shows dollars" "$line";; *) report ok "no dollar amount on a subscription";; esac
case "$line" in *"+9"*) report ok "lines added/removed kept";; *) report no "lines counter dropped" "$line";; esac
case "$line" in *$'\033[31m412K'*) report ok "context in absolute tokens, red at >=300K";; *) report no "absolute context" "$line";; esac
line=$(sl_rl "$COLD" 100000 20 | "$SL" | head -1)
case "$line" in *$'\033[32m100K'*) report ok "context green under 150K";; *) report no "context colour" "$line";; esac
line=$(sl_rl "$COLD" 200000 93 | "$SL" | head -1)
case "$line" in *$'\033[33m200K'*) report ok "context yellow under 300K";; *) report no "context yellow" "$line";; esac
case "$line" in *"5h "$'\033[31m93%'*) report ok "5h limit red at >=90%";; *) report no "5h limit" "$line";; esac
case "$line" in *"7d "$'\033[32m12%'*) report ok "7d limit shown";; *) report no "7d limit" "$line";; esac
line=$(sl_payload "$COLD" | "$SL" | head -1)
case "$line" in *"5h"*) report no "limits shown without rate_limits" "$line";; *) report ok "no limits segment without rate_limits";; esac
case "$line" in *"ctx "*"42%"*) report ok "falls back to percent without total_input_tokens";; *) report no "context fallback" "$line";; esac
grep -q 'GIT_OPTIONAL_LOCKS' "$SL" && report ok "status line git takes no optional locks" || report no "GIT_OPTIONAL_LOCKS"
grep -qE '^import traceback' "$HERE/prompt-context" && report no "prompt-context imports traceback eagerly" || report ok "traceback imported lazily"
```

- [ ] **Step 2: Run to verify it fails**

Run: `.claude/hooks/flow-guard-test | grep -E 'dollar|absolute|green under|yellow under|limit|GIT_OPTIONAL|traceback'`
Expected: FAIL on dollars, absolute context, colours, limits, GIT_OPTIONAL_LOCKS and traceback; the two fallback checks may already pass.

- [ ] **Step 3: Implement**
- `context_segment`: if `total_input_tokens` is an int, render `ctx {colour}{round(n/1000)}K{RESET}` with GREEN < 150000, YELLOW < 300000, else RED; otherwise keep today's percentage rendering.
- `cost_segment`: drop the dollar part; keep lines added/removed.
- `limits_segment(payload)`: for `five_hour` then `seven_day` (labels `5h`, `7d`) with a numeric `used_percentage`: `f"{label} {colour}{int(p)}%{RESET}"`, colour GREEN < 70, YELLOW < 90, else RED; after the 5h value append `f" {DIM}→{HH:MM}{RESET}"` from `resets_at` in local time when present; join the two with two spaces; `None` when neither is present. Add it to `main`'s segment tuple after `context_segment`.
- `git()`: pass `env={**os.environ, "GIT_OPTIONAL_LOCKS": "0"}` to `subprocess.run`.
- `prompt-context`: remove the module-level `import traceback`; import it inside the `except` block that prints the traceback.

- [ ] **Step 4: Run to verify it passes**

Run: `.claude/hooks/flow-guard-test | tail -1 && .claude/hooks/prompt-context-test | tail -1`
Expected: both `N passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/statusline .claude/hooks/prompt-context .claude/hooks/flow-guard-test
git commit -m "statusline: limits and absolute context, no dollars; lazy traceback (D13, D22)"
```

---

### Task 6: pipeline skill text — background dispatch, Opus triggers, model table, run boundaries

**Files:**
- Modify: `.claude/skills/subagent-driven-development/SKILL.md` (Dispatching / per-task loop step 3 and the reviewer step; "Pass `model:` only to override" paragraph; the "Your prompt supplies" table row for task-reviewer)
- Modify: `.claude/skills/requesting-code-review/SKILL.md` (the dispatch step)
- Modify: `.claude/skills/development-workflow/SKILL.md` (`## Model & effort per stage`, `## Triage`)
- Modify: `.claude/skills/finishing-a-development-branch/SKILL.md` (the closing "Finally, end the run" line)
- Modify: `.claude/agents/task-reviewer.md` (section "What you are given")
- Modify: `.claude/skills/writing-plans/red-team.md` (`## Dispatch`)
- Modify: `.claude/hooks/statusline` (`model_hint`), test `.claude/hooks/flow-guard-test` (`hint_case` lines)

**Interfaces:**
- Consumes: Task 3's renumbered SDD loop and reviewer prompt contents.
- Produces: nothing code depends on.

- [ ] **Step 1: Write the failing checks** — save as `.flow/sdd/2026-10-03-setup-perf-audit/text-check.sh` in the worktree:

```bash
#!/usr/bin/env bash
R=$(cd "$(dirname "$0")/../../.." && pwd)/.claude; S=$R/skills; A=$R/agents
f=0; chk() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; f=1; fi; }
chk "SDD dispatches in background" "grep -q 'run_in_background: true' $S/subagent-driven-development/SKILL.md"
chk "review skill dispatches in background" "grep -q 'run_in_background: true' $S/requesting-code-review/SKILL.md"
chk "Opus triggers named" "grep -q 'auth' $S/subagent-driven-development/SKILL.md && grep -q '400 changed lines' $S/subagent-driven-development/SKILL.md"
chk "no vague non-trivial trigger" "! grep -q 'non-trivial, security- or concurrency-touching' $S/subagent-driven-development/SKILL.md"
chk "Explore row gone" "! grep -q 'Read-only exploration' $S/development-workflow/SKILL.md"
chk "model table says Sonnet 5.5" "grep -q 'Sonnet 5.5' $S/development-workflow/SKILL.md && ! grep -q 'Sonnet 5 ·' $S/development-workflow/SKILL.md"
chk "triage asks for /clear after a finished run" "grep -q '120K' $S/development-workflow/SKILL.md"
chk "finishing ends with /clear" "grep -q '/clear' $S/finishing-a-development-branch/SKILL.md"
chk "no second Global Constraints paste (SDD)" "! grep -q 'Global Constraints copied verbatim' $S/subagent-driven-development/SKILL.md"
chk "reviewer reads constraints from the brief" "grep -q 'brief already carries' $A/task-reviewer.md"
chk "red-team dispatched in background" "grep -q 'run_in_background: true' $S/writing-plans/red-team.md"
chk "model switches are session-only" "grep -q 'session only' $S/development-workflow/SKILL.md && ! grep -qE 'answers with .?/clear.?, .?/model sonnet.?, then' $S/development-workflow/SKILL.md"
chk "no stale 'runs Sonnet 5;'" "! grep -q 'runs Sonnet 5;' $S/subagent-driven-development/SKILL.md"
chk "statusline hints are session-only" "grep -q 'session only' $R/hooks/statusline"
exit $f
```

- [ ] **Step 2: Run to verify it fails**

Run (from the worktree): `bash .flow/sdd/2026-10-03-setup-perf-audit/text-check.sh`
Expected: FAIL on every line.

- [ ] **Step 3: Implement**
- SDD and requesting-code-review: every dispatch instruction says "dispatch with `run_in_background: true`, then end the turn and wait for the task notification" (with `CLAUDE_CODE_FORK_SUBAGENT=0` the parameter is back and a foreground dispatch would block the session).
- SDD reviewer step: replace "with `model: "opus"` for a non-trivial, security- or concurrency-touching diff" with: `model: "opus"` when the diff touches auth, secrets or untrusted input; concurrency or lock order; a data migration or storage format; a public API contract — or exceeds ~400 changed lines; docs/spec-sync diffs stay on Sonnet; a re-review keeps the first review's model. Record it in the ledger note: `model=opus reason=<trigger>`. Mirror the trigger list in the "Pass `model:` only to override" paragraph.
- development-workflow `## Model & effort per stage`: "Sonnet 5" → "Sonnet 5.5" throughout (session default Sonnet 5.5 · high via `modelSettings` keyed `claude-sonnet-5-5`); task-reviewer row → "Sonnet 5.5 · high (Opus 5.5 on the named triggers in subagent-driven-development)"; delete the `Read-only exploration (Explore)` row.
- development-workflow `## Triage`: add a paragraph before "Small, with one decision": "**A finished run still in context.** If this conversation already carried a run through finish and the context is above ~120K, ask for `/clear` (or a handoff) before opening the next run — every request of the new run would otherwise re-read the old one."
- finishing: the closing line becomes "Finally, end the run: `~/.claude/hooks/flow-state clear` — and tell the user the next step is `/clear` before the next change."
- Model switches are session-only (the CLI's `/model` otherwise writes the pick into the tracked `settings.json`): development-workflow's "the user answers with `/clear`, `/model sonnet`, then `go`" becomes "the user answers with `/clear`, `/model sonnet` choosing *session only* in the picker (or a fresh `claude`, whose committed default is Sonnet), then `go`"; the Opus switch for stages 1–2 likewise names `/model opus` (session only) or `claude --model opus`. `statusline` `model_hint`: every `/model X` hint gains ` (session only)` (e.g. `⚠ /model opus (session only)`, `go → /clear · /model sonnet (session only) · go`); update the matching expected strings in the `hint_case` lines of `flow-guard-test`.
- red-team.md `## Dispatch`: add "dispatch with `run_in_background: true`" before "Then end the turn".
- SDD step 3: "The definition runs Sonnet 5;" → "The definition runs Sonnet 5.5;". Statusline module docstring example: drop `$0.42`, show `ctx 412K` and a `5h 40%  7d 12%` limits segment.
- SDD "Your prompt supplies" table, task-reviewer row: drop "and the plan's Global Constraints copied verbatim"; task-reviewer.md "What you are given": the brief already carries the plan's Global Constraints — name only the ones the diff touches.

- [ ] **Step 4: Run to verify it passes**

Run (from the worktree): `bash .flow/sdd/2026-10-03-setup-perf-audit/text-check.sh && .claude/hooks/flow-guard-test | tail -1`
Expected: all PASS, exit 0; suite `0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills .claude/agents/task-reviewer.md .claude/hooks/statusline .claude/hooks/flow-guard-test .flow/sdd/2026-10-03-setup-perf-audit/text-check.sh
git commit -m "skills: background dispatch, named Opus triggers, Sonnet 5.5 table, /clear at run end (D5, D16, D19, D23, D24)"
```

---

### Task 7: brainstorming/writing-plans rules inline, CLAUDE.md rules 2 and 5, README, experiment note

**Files:**
- Modify: `.claude/skills/brainstorming/SKILL.md` (Checklist item 3)
- Modify: `.claude/skills/writing-plans/SKILL.md` (`## Red-Team Pass`)
- Modify: `.claude/CLAUDE.md` (rules 2 and 5 — Polish)
- Modify: `.claude/README.md` (`## Model & effort`, `## codebase-memory (cbm)`, the plan-granularity paragraph)
- Modify (outside repo, synced): `/home/m/.claude/projects/-home-m-dotfiles/memory/plan-granularity-experiment.md`, `/home/m/.claude/projects/-home-m-dotfiles/memory/MEMORY.md`

**Interfaces:**
- Consumes: Task 1 (models, hooks removed), Task 6 (model table).
- Produces: nothing code depends on.

- [ ] **Step 1: Write the failing checks** — save as `.flow/sdd/2026-10-03-setup-perf-audit/text-check-2.sh` in the worktree:

```bash
#!/usr/bin/env bash
R=$(cd "$(dirname "$0")/../../.." && pwd)/.claude; M=/home/m/.claude/projects/-home-m-dotfiles/memory
f=0; chk() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; f=1; fi; }
chk "grill rule inline in brainstorming checklist" "grep -qE '^3\. \*\*Grill gate\*\*.*recommended default and why' $R/skills/brainstorming/SKILL.md"
chk "minor-objection rule inline in writing-plans" "awk '/^## Red-Team Pass/,/^## Execution/' $R/skills/writing-plans/SKILL.md | grep -q 'verdict PROCEED'"
chk "rule 2 names grep/find via Bash" "grep -q 'grep/find' $R/CLAUDE.md && ! grep -q 'Grep/Glob/Read tylko' $R/CLAUDE.md"
chk "rule 2 names the cbm project convention" "grep -q 'home-m-projects-' $R/CLAUDE.md"
chk "rule 5 marked main-thread" "grep -q 'dotyczy głównego wątku' $R/CLAUDE.md"
chk "README: no Sonnet 5 xhigh default" "! grep -q 'Sonnet 5 · xhigh' $R/README.md"
chk "README: no Grep/Glob augmenter" "! grep -q 'PreToolUse augmenter' $R/README.md"
chk "experiment note closed" "! grep -q 'Still open' $M/plan-granularity-experiment.md && grep -q 'Haiku' $M/plan-granularity-experiment.md"
exit $f
```

- [ ] **Step 2: Run to verify it fails**

Run (from the worktree): `bash .flow/sdd/2026-10-03-setup-perf-audit/text-check-2.sh`
Expected: FAIL on every line.

- [ ] **Step 3: Implement**
- brainstorming Checklist item 3 (the line starting `3. **Grill gate**`): state the rule inline on that line — "grill one question at a time, each with a recommended default and why" — keeping the pointer to `grill-gate.md` for the rest.
- writing-plans `## Red-Team Pass`: inline the minor-only rule from `red-team.md` — "Minor objections only, or none: verdict PROCEED; apply the list to the plan without a gate and name it in one line at the plan gate."
- CLAUDE.md rule 2 (Polish): replace "Grep/Glob/Read tylko do tekstu…" with grep/find przez Bash + Read for text, configs and non-code; add one sentence: nazwa projektu w cbm to ścieżka main checkoutu z myślnikami (np. `home-m-projects-harmonia`), także gdy pracujesz w worktree. Keep "Projekt bez indeksu → najpierw index_repository". Rule 5: append "(dotyczy głównego wątku)" to its first sentence.
- README: `## Model & effort` → session default Sonnet 5.5 · high, design/plan Opus 5.5 · high, roles as in development-workflow's table, task-reviewer Opus on named triggers; `## codebase-memory (cbm)` → drop the PreToolUse augmenter and the SubagentStart reminder sentence (the protocol lives in CLAUDE.md rule 2); plan-granularity paragraph → the middle-variant plans are kept (D25).
- Memory note: replace the "Still open" sentence with the outcome (revert criterion not met; Haiku override on the implementer accepted), keep `0d2c8b3` as a historical pointer; update its line in MEMORY.md (`— closed 2026-10-03: middle-variant plans kept`).

- [ ] **Step 4: Run to verify it passes**

Run (from the worktree): `bash .flow/sdd/2026-10-03-setup-perf-audit/text-check-2.sh`
Expected: all PASS, exit 0.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/brainstorming/SKILL.md .claude/skills/writing-plans/SKILL.md .claude/CLAUDE.md .claude/README.md .flow/sdd/2026-10-03-setup-perf-audit/text-check-2.sh
git commit -m "docs: inline grill/red-team rules, CLAUDE.md rules 2 and 5, README to current config (D20, D21, D24, D25)"
```

---

### Task 8: `bin/claude-baseline` — the before/after measurement

**Files:**
- Modify: `bin/claude-baseline` (committed verbatim with the plan from the audit's `baseline.py`; this task edits it in place)

**Interfaces:**
- Consumes: nothing.
- Produces: `claude-baseline [FROM=YYYY-MM-DD] [TO=YYYY-MM-DD]` — read-only report on `~/.claude/projects` (first-request size by machine/kind, cache share, compactions).

- [ ] **Step 1: Write the failing check**

Run: `grep -q 'lastModelUsage' bin/claude-baseline`
Expected: exit 1 (the analysis rules are not in the header yet).

- [ ] **Step 2: Implement** — extend its docstring (keep it Polish, like the file) with the analysis rules (F7): output tokens of subagents since 2.1.280 are ~3× under-reported in transcripts — use `~/.claude.json` `lastModelUsage` / cost state for output; window by entry `timestamp`, never file mtime; machine from the `[CTX]` line, else version; keep accounts apart if more than one shows up. Keep the `LAP`/`PC` version sets (they are the host fallback) and add a comment above them that they need updating when either machine upgrades.

- [ ] **Step 3: Run to verify it works**

Run: `bin/claude-baseline 2026-09-27 2026-10-03`
Expected: prints first-request medians for main/sub by machine (laptop main ~49K, pc main ~51K on this window) and a compaction count; exit 0.

- [ ] **Step 4: Commit**

```bash
git add bin/claude-baseline
git commit -m "bin: claude-baseline analysis rules (D28)"
```

---

No living-spec sync task: the dotfiles have no `spec.md`; README (Task 7) is the state document.

Before the finish merge (laptop main checkout): it carries uncommitted edits to `.claude/settings.json` that Task 1 supersedes, which would make `git merge` refuse — run `git -C /home/m/dotfiles checkout -- .claude/settings.json` (that one path only; never `stash` or `checkout .`, which would sweep the user's `config/` and `hosts/` edits).

After merge (by the user, both machines, not part of execution): on pc `git -C ~/dotfiles checkout .claude/settings.json` before `pull` (D1); `dotter deploy` on both machines (removes the deleted hooks' symlinks, links `bin/claude-baseline`); then the manual items from the design record — mutagen force-poll (D26), cbm watcher off in `~/obsidian` and `~/work/knowledge-base` (D27), pc Cloudflare skill copies (A7).
