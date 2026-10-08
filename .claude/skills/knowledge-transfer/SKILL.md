---
name: knowledge-transfer
description: Use when someone is taking over a project, system or technical topic from the user — a successor engineer, a semi-technical support person, or the user themselves months later — and needs a handover document. Triggers on "przekazanie projektu", "knowledge transfer", "KT", "ktoś przejmuje", "dokument przekazania", "dokument onboardingowy dla". Not for agent session continuity (handoff) or for describing what a project is (writing-specs).
---

# Knowledge Transfer

A KT package is a dated, recipient-prioritised snapshot of what the person
taking over cannot get from the repo: traps, workarounds, failure symptoms,
who to call. It is written for one named reader, and it is not trusted until a
reader with nothing but the package has tried to act on it.

## Boundary

| Artifact | Holds |
|---|---|
| spec (writing-specs) | what the project **is** |
| design records | **why** decisions were made |
| `handoff` | an agent session's continuity |
| KT package | what those do not hold, as of one date and one commit |

- The skill **reads** the spec and never edits it. A contradiction between spec
  and repo goes to the package's "Luki" section and to the final report.
- It opens no flow-state run. If the repo has a run with a workspace recorded,
  the flow-guard denies main-thread writes — finish or park that run first.

## Intake

Four fields. If any is missing, ask for all missing ones in **one** message.

1. **Profile:** `następca` (a successor engineer), `ja-później` (the user,
   months from now) or `support` (semi-technical; plain language, no code
   internals).
2. **Goal:** what the recipient must be able to do afterwards.
3. **Mode:** `projekt` (a repo exists) or `temat` (no repo — an output path is
   required, and never under `~/obsidian`: write elsewhere and tell the user to
   send the vault session a pointer).
4. **Extra materials** (optional): documents, links, chats.

## Process

1. **Intake**, as above.
2. **Scan** (`projekt` mode only): spec, README, design records, CI/deploy
   config, `git log`. Reverts, `fix:` commits and files that change often are
   trap candidates. Note `git rev-parse --short HEAD` — the package pins it.
3. **✋ Inventory.** List what the recipient needs, each item with a priority:
   high / medium / low = cost of not knowing × whether the repo lets them
   recover it. Add 5–8 scenarios with an answer key, built from the high
   items. Show it to the user and stop. Nothing is written before the yes.
4. **Interview, on gaps only.** What the repo cannot tell you, you ask. One
   question carries one hypothesis from the repo for the user to confirm,
   reject or correct ("the deploy script restarts only the web service — is the
   worker restarted somewhere else?") wherever the repo or the materials
   suggest one; where they cannot (people, external systems), ask directly.
   Never a bare "anything else?". Time pressure shortens the interview to the
   high items; it never removes it.
5. **Write** `docs/kt/YYYY-MM-DD-<profil>.md` (`temat` mode: the intake path),
   by the matrix below.
6. **Cold read**, below.
7. **✋ Final.** Show the package and the gap report (what the cold read still
   failed, what the user left unanswered, spec–repo contradictions). The
   user's yes = a commit of the package file only.

## Section matrix

Sections 0, 1, traps, "Sprawdź się" and "Luki" are in every package; the rest
by profile (`link` = a link or one line, not a section of prose).

| Sekcja | support | następca | ja-później |
|---|---|---|---|
| 0 Jak czytać, stan na (data, SHA) | ✓ | ✓ | ✓ |
| 1 Co to robi i dla kogo | ✓ | ✓ | ✓ |
| Objawy awarii i jak je rozpoznać | ✓ | — | — |
| Runbooki (uruchom, wdróż, rollback) | ✓ | link | link |
| Mapa systemu (linki do speca i kodu) | — | ✓ | link |
| Jak zmieniać (build, test, release) | — | ✓ | — |
| Decyzje i dlaczego (linki do rekordów) | — | ✓ | — |
| Dług i otwarte ryzyka | — | ✓ | ✓ |
| Gdzie stanąłem, jak odtworzyć środowisko | — | — | ✓ |
| Pułapki i obejścia | ✓ | ✓ | ✓ |
| Eskalacja: kiedy i do kogo | ✓ | kto co wie | — |
| Dostępy: gdzie, nigdy jakie | ✓ | ✓ | — |
| Sprawdź się: scenariusze z odpowiedziami | ✓ | ✓ | ✓ |
| Luki | ✓ | ✓ | ✓ |

- **Link to the spec instead of restating it.** Section 1 is two sentences and
  a link, not the spec's purpose section reworded.
- `ja-później`: if the package reads like a copy of the spec, cut it to links
  plus traps.
- Every claim traces to the repo, to something the user said, or to an
  explicit line in "Luki" saying it is unconfirmed. Nothing else is written —
  not an inferred schedule, not a procedure nobody described, not arithmetic
  dressed as a limit.
- `temat`: section 0 carries the date only; no commit, report the path.

## Cold read

Verification by someone who has only the package. Dispatch the agent
`kt-cold-reader` in the **foreground** (`run_in_background: false` — the next
step needs its answers):

- `subagent_type: "kt-cold-reader"`; `model: "haiku"` for `support`,
  `model: "sonnet"` for `następca` and `ja-później`.
- Prompt: `PAKIET:` + the package with the answers of "Sprawdź się" removed +
  `SCENARIUSZE:` + the numbered scenarios.
- A scenario **fails** when `Podstawa` is `NIE WIEM Z PAKIETU` or `ZGADUJĘ`, or
  the answer contradicts the key.
- Patch the package wherever a scenario failed or the reader misread, then
  **re-run**: a fresh dispatch of `kt-cold-reader` with the patched package.
  An unchecked patch is not a patch — not when the dispatch costs time, and
  not when you believe the fix is obvious. At most **2 patch rounds**. What
  still fails goes into "Luki" and the final report. There is no third round.

## Hard rules

- **Secrets: location only** — the vault, the 1Password entry, the env var
  name — never a value. Check the package for values before the cold-reader
  dispatch too, since the prompt carries the whole package. Do not open
  `.env`-style files to see what is in them (templates such as `.env.example`
  are fine).
- **Polish**, written per the `polszczyzna` skill; plain language for
  `support`.
- **Commit only the package**, only after the final ✋.

## Common mistakes

Each row is something the skill-less baseline run actually did
(`.flow/specs/2026-10-08-knowledge-transfer-evidence/baseline.md`).

| Mistake | Counter |
|---|---|
| Wrote the whole package first, asked nothing: "przed wyjazdem sam musisz uzupełnić jego sekcję 7 (sześć punktów, które trzeba wpisać)" | The inventory gate and the interview come before the first Write. A gap is yours to ask about, with a hypothesis; the user's closing task list is not a deliverable. |
| Handed the remaining work back: "Dalej: wpisz odpowiedzi do sekcji 7 i wyślij Kasi plik albo link." | What the user leaves unanswered goes into "Luki" and the final report. |
| Claims nothing supported: "Limit przepustowości: 50 SMS-ów na 10 sekund, czyli ok. 300 na minutę", "Powtarzaj to w każdy poniedziałek rano", "najlepiej w środę 28 października", renewal steps nobody described | Trace each claim to repo, user or a "Luki" line. A batch size in a spec is not a gateway limit. |
| Restated the spec: "Usługa przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI. …" (section 2, near-verbatim from spec section 1; D1/D2 likewise) | Link to the spec. A line-level copy check misses a paraphrase, so check by reading. |
| No pinned repo state — nothing says which commit the package describes | Section 0: date and short SHA, "stan na". |
| Verified by its own hand: "Wszystkie cztery ustalenia są już w `PRZEKAZANIE.md` (grep wyżej)" — a grep of its own file for the words it had just been given | The cold read is the check: a reader with only the package, answering scenarios. |
