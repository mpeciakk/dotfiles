## Global Constraints

- Labels are exactly `pc` and `laptop`. `host-pc` → `pc`, `host-mac` → `laptop`; any other `host-<name>` falls back to `<name>`.
- Host identity comes from `<repo>/.dotter/local.toml` only. Never `hostname`, `/etc/hostname`, `uname -n` or `hostnamectl` — both machines answer `ciek`.
- Unknown host is reported as `unknown (<reason>)`, never guessed and never silent.
- No state file and no transcript scanning. The line is emitted on every matching event.
- Stdlib only. The hooks in this directory take no third-party dependency.
- Hook scripts carry no file extension (`flow-context`, `flow-state`), are executable, and exit 0 on malformed input rather than raising.

---

### Task 3: Tell the reader there are two machines

**Files:**
- Modify: `.claude/CLAUDE.md` (insert between the cross-session block ending `…zgłosisz następnym razem.` and the line `Dyscyplina kodu (Karpathy — zawsze; …`)
- Modify: `README.md` (section `## Per-host hardware`, after the third bullet, before `To add a machine:`)

**Interfaces:**
- Consumes: the label vocabulary (`pc`, `laptop`) and the hook name from Tasks 1–2.
- Produces: nothing.

No test: this task changes prose only. It is verified by reading the diff and by
the two `grep` checks in Step 4.

- [ ] **Step 1: Add the section to `.claude/CLAUDE.md`**

Insert this block, with one blank line before and after, immediately after the
line `w repo, zgłosisz następnym razem.` and before `Dyscyplina kodu (Karpathy`:

```markdown
Dwie maszyny — `pc` (desktop) i `laptop` (MacBook Air M2, Asahi):
- Oba systemy raportują hostname `ciek`, tego samego usera i ten sam prompt.
  Maszyny NIE wnioskujesz z hostname'a, promptu ani ścieżek — mówi ją wyłącznie
  linia `[CTX] <host>` wstrzykiwana przez hook `prompt-context` przy każdej
  wiadomości i przy starcie każdego subagenta.
- `~/projects`, `~/work`, `~/obsidian` i `~/.claude/projects` są
  synchronizowane mutagenem przez `sirius`. Wspólne jest **drzewo robocze, nie
  historia gita** (`~/work` ma `Ignore VCS`): każda maszyna ma tam własną
  historię. Nie mergujesz i nie rebase'ujesz historii między hostami — raz
  zjadło to 23 commity.
- Tura **bez** linii `[CTX]` nie znaczy „ta sama maszyna, co poprzednio" — znaczy
  maszynę bez wdrożonego hooka albo sesję sprzed jego powstania. Nieoznaczonej
  tury nie przypisujesz do żadnego hosta.
- Zapisując fakt zależny od maszyny (spec, notatka, commit, raport), nazywasz ją
  `pc` albo `laptop`. „Na tej maszynie" i „na `ciek`" są niejednoznaczne i były
  już źródłem siedmiu poprawek naraz.
```

- [ ] **Step 2: Add the line to `README.md`**

In `## Per-host hardware`, after the `hosts/pc/herdr-mirror-hosts.toml` bullet
and before the paragraph starting `To add a machine:`, add:

```markdown
`.dotter/local.toml` is also read by `.claude/hooks/prompt-context`, which names
the machine in every Claude Code session — both hosts report hostname `ciek`, so
the selected `host-*` package is the only thing that tells them apart. A checkout
without that file reports `[CTX] unknown (…)`.
```

- [ ] **Step 3: Run the hook's test suite once more**

Run: `.claude/hooks/prompt-context-test`

Expected: PASS — `18 passed, 0 failed`. Nothing in this task should have
affected it; a failure here means Step 1 or 2 edited the wrong file.

- [ ] **Step 4: Verify both edits landed where intended**

Run:

```bash
grep -c 'prompt-context' .claude/CLAUDE.md README.md
grep -n 'Dwie maszyny' .claude/CLAUDE.md
```

Expected: `.claude/CLAUDE.md:1` and `README.md:1` from the first command, and a
single `Dwie maszyny` line from the second, positioned before the
`Dyscyplina kodu` block.

- [ ] **Step 5: Commit**

```bash
git add .claude/CLAUDE.md README.md
git commit -m "docs: record that this configuration runs on two machines"
```

---
