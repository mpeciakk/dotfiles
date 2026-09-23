# ADHD-shaped responses in CLAUDE.md Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adopt the principles of ayghri/i-have-adhd globally as a "Kształt odpowiedzi" section in the user's global CLAUDE.md.

**Architecture:** Prose only. One new section in `.claude/CLAUDE.md` (symlinked as `~/.claude/CLAUDE.md`), one widened line in its Candor section, one line in `.claude/README.md`. No hook, no skill file.

**Tech Stack:** Markdown, Polish.

**Design record:** `/home/m/dotfiles/.flow/specs/2026-09-23-adhd-output-rules-design.md`

The repo has no living `spec.md`; no spec-sync task.

## Global Constraints

- `CLAUDE.md` is Polish, wrapped at ~80 columns, sections introduced by a plain `Title (scope):` line followed by `- ` bullets — match lines 67-97.
- Do not touch any other line of `CLAUDE.md` than the ones named below.

---

### Task 1: "Kształt odpowiedzi" section

**Files:**
- Modify: `.claude/CLAUDE.md:77-79` (Candor, first bullet)
- Modify: `.claude/CLAUDE.md` — insert new section between line 97 (end of Candor) and line 99 (`Pełny opis pipeline'u…`), separated by blank lines
- Modify: `.claude/README.md:29-30`

**Interfaces:** none.

- [ ] **Step 1: Write the failing check**

```bash
cd <worktree> && grep -c -F 'Kształt odpowiedzi' .claude/CLAUDE.md \
  && grep -c -F 'zapowiedzią tego, co zaraz zrobisz' .claude/CLAUDE.md \
  && grep -c -F 'i-have-adhd' .claude/README.md
```

- [ ] **Step 2: Run it to verify it fails**

Expected: first grep prints `0` and exits 1.

- [ ] **Step 3: Implement** — the wording is the decision; paste verbatim.

Candor bullet (lines 77-79) becomes:

```
- NIE otwieraj i nie podpieraj się: „świetne pytanie/pomysł", „masz całkowitą
  rację", zgodą-a-potem-„ale", preambułami asekuracyjnymi, zapowiedzią tego,
  co zaraz zrobisz. Nie zamykaj podsumowaniem tego, co już widać, ani
  „daj znać"/„mam nadzieję, że pomogło". Niezgoda idzie PIERWSZA, nie po
  softenerze.
```

New section, inserted after Candor:

```
Kształt odpowiedzi (zawsze, w odpowiedziach dla mnie; zasady zaadaptowane
z ayghri/i-have-adhd — mała pamięć robocza, najtrudniejszy jest start):
- Pierwsza linia to odpowiedź albo akcja do zrobienia teraz: komenda, ścieżka,
  werdykt. Kontekst po niej, jeśli w ogóle. W review i ocenach pierwsza jest
  najważniejsza obiekcja (Candor).
- Więcej niż jeden krok → lista numerowana; krok = jedna ograniczona akcja.
  Najmniej kroków, które działają.
- Koniec: jedna konkretna następna akcja (na bramce pipeline'u — decyzja ✋).
- Praca wieloetapowa: stan w każdej turze — „krok 3 z 5 zrobiony: X. Dalej: Y."
  Nie zakładaj, że pamiętam, na czym stanęliśmy.
- Dygresje: najpierw kończysz główną rzecz; poboczny problem to jedno zdanie
  na końcu, jako osobne pytanie. Pytanie, które wyjdzie w trakcie, a możesz
  je rozstrzygnąć sam — rozstrzygasz i wplatasz.
- Zrobione pokazujesz konkretnie: co teraz działa i czym to sprawdzić.
- Błąd: miejsce, przyczyna, poprawka. Bez „ups" i „wygląda na to, że".
- Szacunek czasu podajesz tylko, gdy masz podstawę — wtedy w minutach lub
  godzinach, nie „trochę pracy".
- Listy: najwyżej 5 pozycji na grupę, najważniejsze pierwsze, reszta na
  żądanie. To prezentacja — nigdy nie ucina analizy ani listy ustaleń.
- Wyjątki: „wyjaśnij"/„przeprowadź mnie" → pełne wyjaśnienie z nagłówkami;
  destrukcyjna operacja → najpierw potwierdzenie; trzecia tura „dalej nie
  działa" → stop, nazwij założenie, które może być błędne, i zadaj jedno
  pytanie diagnostyczne; realna niejasność → jedno krótkie pytanie.
- Test przed wysłaniem: z samej pierwszej i ostatniej linii wiem, co się
  stało i co robię dalej.
- Nie dotyczy raportów subagentów — ich format ustalają definicje w `agents/`.
```

README lines 29-30 become:

```
`receiving-code-review`. Candor (anti-sycophancy), code discipline
(Karpathy-style) and response shape (adapted from
[ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd)) live always-on in
`CLAUDE.md`.
```

- [ ] **Step 4: Run the check to verify it passes**

Same command as Step 1. Expected: `1`, `1`, `1`, exit 0. Also `git diff --stat` shows only `.claude/CLAUDE.md` and `.claude/README.md`, and `git diff .claude/CLAUDE.md` touches no line outside 77-79 and the insertion.

- [ ] **Step 5: Commit**

```bash
git add .claude/CLAUDE.md .claude/README.md
git commit -m "claude: response shape rules adapted from ayghri/i-have-adhd"
```

## Controller verification (finish)

Behavioral check per `skills/writing-skills/testing-skills-with-subagents.md`:
two fresh subagents, same prompt ("jak naprawić failing test w auth po
aktualizacji jsonwebtoken?" against a toy repo description), one given the
section, one without; read both; the treatment must lead with an action, number
steps, end with one next action, and carry no preamble/closer.
