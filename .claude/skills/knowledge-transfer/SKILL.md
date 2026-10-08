---
name: knowledge-transfer
description: Use when another Animativ employee — or the user, months later — is taking over a company project and needs a handover document. Triggers on "przekazanie projektu", "knowledge transfer", "KT", "ktoś przejmuje", "dokument przekazania", "dokument onboardingowy dla". Not for agent session continuity (handoff) or for describing what a project is (writing-specs).
---

# Knowledge Transfer

A KT package is a dated, reader-prioritised snapshot of what the person
taking over cannot get from the repo: traps, workarounds, failure symptoms,
who to call. Every KT covers a company (Animativ) repo. The reader is another
employee of the same company, or the author months later; either knows the
company's infrastructure and has the company knowledge base
`docs.internal.animativ.dev`. The package is not trusted until a reader with
nothing but the package has tried to act on it.

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

Two fields. If any is missing, ask for all missing ones together, in **one**
message.

1. **Goal:** what the reader must be able to do afterwards.
2. **Extra materials** (optional): documents, links, chats.

## Process

1. **Intake**, as above.
2. **Scan:** spec, README, design records, CI/deploy config, `git log`.
   Reverts, `fix:` commits and files that change often are trap candidates.
   Note `git rev-parse --short HEAD` — the package pins it.
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
   - **Still asked:** traps and workarounds that are not in the code, who knows
     what, the project's own external dependencies, and where a secret the repo
     names is kept (location only — allowed even when the answer is "in the
     password manager").
   - **Never ask:**
     - **Company infrastructure:** network, router, VPN, accounts,
       permissions, SSH or server access, getting into the password manager
       and its procedures. The package carries one line pointing to
       `docs.internal.animativ.dev` instead.
     - **Run history:** when something was last run, whether it has been run,
       how the user runs it. The package describes the mechanism as the code
       has it. Where the spec says what was or was not run or verified, the
       package attributes it to the spec, using the phrase `wg speca`, and
       neither confirms nor questions it. A spec–code contradiction goes to
       "Luki" without a question.
     - **The reader:** no name, no profile, no skill level.
5. **Write** `docs/kt/YYYY-MM-DD.md`, by the section list below.
6. **Cold read**, below.
7. **✋ Final.** Show the package and the gap report (what the cold read still
   failed, what the user left unanswered, spec–repo contradictions). The
   user's yes = a commit of the package file only.

## Sections

One list, in this order:

```
0. Jak czytać, stan na (data, SHA)
1. Co to robi (dwa zdania i link do speca)
2. Mapa systemu (linki do speca i kodu)
3. Uruchomienie i zmiany (build, test, release; runbooki jako linki)
4. Decyzje i dlaczego (linki do rekordów)
5. Dług i otwarte ryzyka
6. Gdzie stanąłem, jak odtworzyć środowisko
7. Pułapki i obejścia (z objawami)
8. Kto co wie, eskalacja
9. Dostępy projektu: gdzie, nigdy jakie; infrastruktura firmowa: docs.internal.animativ.dev
10. Sprawdź się: scenariusze z odpowiedziami
11. Luki
```

- **Link to the spec instead of restating it.** Section 1 is two sentences and
  a link, not the spec's purpose section reworded.
- Every claim traces to the repo, to something the user said, or to an
  explicit line in "Luki" saying it is unconfirmed. Nothing else is written —
  not an inferred schedule, not a procedure nobody described, not arithmetic
  dressed as a limit.

## Cold read

Verification by someone who has only the package. Dispatch the agent
`kt-cold-reader` in the **foreground** (`run_in_background: false` — the next
step needs its answers):

- `subagent_type: "kt-cold-reader"`, always `model: "sonnet"`.
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
- **Polish**, written per the `polszczyzna` skill.
- **Commit only the package**, only after the final ✋.

## Common mistakes

The rows come from two runs: the skill-less baseline run
(`.flow/specs/2026-10-08-knowledge-transfer-evidence/baseline.md`) and the first
real KT run (edge-vibecoding, 2026-10-08).

| Mistake | Counter |
|---|---|
| Wrote the whole package first, asked nothing: "przed wyjazdem sam musisz uzupełnić jego sekcję 7 (sześć punktów, które trzeba wpisać)" | The inventory gate and the interview come before the first Write. A gap is yours to ask about, with a hypothesis; the user's closing task list is not a deliverable. |
| Handed the remaining work back: "Dalej: wpisz odpowiedzi do sekcji 7 i wyślij Kasi plik albo link." | What the user leaves unanswered goes into "Luki" and the final report. |
| Claims nothing supported: "Limit przepustowości: 50 SMS-ów na 10 sekund, czyli ok. 300 na minutę", "Powtarzaj to w każdy poniedziałek rano", "najlepiej w środę 28 października", renewal steps nobody described | Trace each claim to repo, user or a "Luki" line. A batch size in a spec is not a gateway limit. |
| Restated the spec: "Usługa przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI. …" (section 2, near-verbatim from spec section 1; D1/D2 likewise) | Link to the spec. A line-level copy check misses a paraphrase, so check by reading. |
| No pinned repo state — nothing says which commit the package describes | Section 0: date and short SHA, "stan na". |
| Verified by its own hand: "Wszystkie cztery ustalenia są już w `PRZEKAZANIE.md` (grep wyżej)" — a grep of its own file for the words it had just been given | The cold read is the check: a reader with only the package, answering scenarios. |
| Asked about company infrastructure: „Sieć: hipoteza — 10.100.100.205 to rezerwacja DHCP na routerze labu, który Ty administrujesz; kolejna płytka wymaga dopisania jej MAC tam. Kto/gdzie?” (the answer: „po prostu router w biurze”) | Company infrastructure is in `docs.internal.animativ.dev`. One line in the package points there; never ask. |
| Asked about run history: „Od 2026-09-28 był jakiś run?” | Describe the mechanism as the code has it; a spec's claim about what was run or verified goes in `wg speca`. |
| Asked who the reader is: „Odbiorca: git na tej maszynie ma użytkownika „Ernest”, commity są od mpeciakk. Pakiet jest dla Ernesta?” | The reader is a company employee or the author later; no name, no profile. |
