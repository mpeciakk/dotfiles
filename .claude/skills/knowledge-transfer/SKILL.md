---
name: knowledge-transfer
description: Use when another Animativ employee — or the user, months later — is taking over a company project and needs a handover document. Triggers on "przekazanie projektu", "knowledge transfer", "KT", "ktoś przejmuje", "dokument przekazania", "dokument onboardingowy dla". Not for agent session continuity (handoff) or for describing what a project is (writing-specs).
---

# Knowledge Transfer

A KT package is one document from which a company colleague understands how
the project works and what state it is in, and can do the goal set at intake.
It explains at a flat level, in its own words, and links into the spec and the
code for depth; the spec stays the source of truth. Every KT covers a company
(Animativ) repo. The reader is another employee of the same company, or the
author months later; either knows the company's infrastructure and has the
company knowledge base `docs.internal.animativ.dev`. The package is not trusted
until a reader with nothing but the package has tried to act on it.

## Boundary

| Artifact | Holds |
|---|---|
| spec (writing-specs) | what the project **is** |
| design records | **why** decisions were made |
| `handoff` | an agent session's continuity |
| KT package | how the project works and its current state, at one commit, readable by anyone in the company |

- The skill **reads** the spec and never edits it. A contradiction between spec
  and repo goes to the package's "Luki" section and to the final report.
- It opens no flow-state run. If the repo has a run with a workspace recorded,
  the flow-guard denies main-thread writes — finish or park that run first.

## Intake

Two fields. If any is missing, ask for all missing ones together, in **one**
message.

1. **Goal:** what the reader must be able to do afterwards. It drives section 5
   and the practical tasks in section 10.
2. **Extra materials** (optional): documents, links, chats.

## Process

1. **Intake**, as above.
2. **Scan:** spec, README, design records, CI/deploy config, `git log`.
   Reverts, `fix:` commits and files that change often are trap candidates.
   Note `git rev-parse --short HEAD` — the package pins it.
3. **✋ Inventory.** List what the reader needs, each item with a priority:
   high / medium / low = how much the goal depends on it × how hard it is to
   get right without the package. Add 5–8 scenarios with an answer key, built
   from the high items. Show it to the user and stop. Nothing is written before
   the yes.
4. **Interview, on gaps only.** What the repo cannot tell you, you ask. One
   question carries one hypothesis from the repo for the user to confirm,
   reject or correct ("the deploy script restarts only the web service — is the
   worker restarted somewhere else?") wherever the repo or the materials
   suggest one; where they cannot (people, external systems), ask directly.
   Never a bare "anything else?". Time pressure shortens the interview to the
   high items; it never removes it.
   - **Still asked:** traps and workarounds that are not in the code, who knows
     what, the project's own external dependencies (who owns the account at one
     is allowed), where a secret the repo names is kept (location only —
     allowed even when the answer is "in the password manager"), the steps of
     the typical task (section 5) that the repo does not describe, and for each
     workaround, when it applies and when to stop.
   - **Never ask:**
     - **Company infrastructure:** network, router, VPN, the company's
       accounts, permissions, SSH or server access, getting into the password
       manager and its procedures. The package carries one line pointing to
       `docs.internal.animativ.dev` instead.
     - **Run history:** When or whether something was run, and
       how it was run in the past. The procedure of the typical task and where
       each step runs may be asked; how to get access there goes to
       `docs.internal.animativ.dev`. The package describes the mechanism as the
       code has it. Where the spec says what was or was not run or verified, the
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

Exactly these eleven headings, in this order:

```
## 0. Jak czytać
## 1. Cel i granice
## 2. Jak to działa
## 3. Stan projektu
## 4. Środowisko i dostępy
## 5. Typowe zadanie krok po kroku
## 6. Awarie i obejścia
## 7. Rozwój
## 8. Kto co wie
## 9. Luki
## 10. Sprawdź się
```

Use these headings verbatim; `###` subheadings are free.

- **0:** the line `Opisuje commit <short SHA>.`, the goal from intake, and which
  sections to read for which need: taking over operation, developing,
  diagnosing a failure.
- **1:** what goes in, what comes out, what the project does not do. Two to
  five sentences.
- **2:** the parts and how a typical run flows through them, in its own words,
  one level deep. Each part links to its spec section or file. A reader who
  stops here knows how the project works. Where the spec describes a flow the
  code does not implement, say so in this section, next to the flow, and point
  to "Luki"; never write the spec's flow as plain present-tense fact.
- **3:** version, what works, debt and open risks, in the present tense. A spec
  claim that something is unverified is stated as state, with `wg speca` and no
  date.
- **4:** what the reader needs installed or at hand. Project secrets: where,
  never what. Company infrastructure: one line pointing to
  `docs.internal.animativ.dev`.
- **5:** one typical task from start to finish, chosen from the intake goal.
  Each step names where it runs (for example the operator's machine, a server,
  a device console) and how success looks.
- **6:** symptom → cause → workaround. Each workaround says when it applies and
  when to stop instead. Both conditions come from the repo, from a user answer
  or from a "Luki" item. Where none gives a stop condition, write that it is
  unknown and list the gap; never invent a threshold, an escalation step or a
  procedure the user did not describe.
- **7:** one worked example of a typical change: which files, which tests, when
  a run on real hardware or a real environment is needed, how a change is
  released. Decisions as links to the spec's decision records.
- **8:** who knows what, and escalation.
- **9:** blockers first. Each item has the form
  `- **<gap>.** Skutek: <what the reader cannot do>. Do czasu ustalenia: <what to do meanwhile>.`
- **10:** 5–8 scenarios with an answer key (the cold read runs on them), then
  2–3 practical tasks derived from the goal, without answers.

Rules for all sections:

- **Current state, not events.** Apart from the commit line, the package holds
  no dates, no test-run results, no descriptions of past runs and no "last
  time" statements. Write a recurring deadline as its rule and where to check
  it, not as a date: „token wygasa co 90 dni; datę wygaśnięcia pokazuje panel
  SMSAPI”.
- **Machine- and person-agnostic.** The package has no names of the author's
  machines, no home or `/tmp` paths, no local tool versions, no author's
  personal tooling as context, and no addressee. Facts about people as project
  state are fine: „projekt zna tylko autor”.
- **Explain, don't copy.** Write in your own words, one level deep, and link
  for depth. A copied spec sentence is still a mistake.
- **Links are relative Markdown links**, for example
  `[spec, sekcja 5](../../spec.md)`. Link to a heading only with its real
  anchor, taken from the heading as it stands in the file.
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
- The practical tasks of section 10 are not sent as scenarios.
- A scenario **fails** when `Podstawa` is `NIE WIEM Z PAKIETU` or `ZGADUJĘ`, or
  the answer contradicts the key — except a scenario whose key says the package
  does not know: it passes on `NIE WIEM Z PAKIETU` and still fails on `ZGADUJĘ`
  or a confident answer.
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

The rows come from three runs: the skill-less baseline run
(`.flow/specs/2026-10-08-knowledge-transfer-evidence/baseline.md`), the first
real KT run (edge-vibecoding, D31) and the second real KT run (edge-vibecoding,
D32).

| Mistake | Counter |
|---|---|
| Wrote the whole package first, asked nothing: "przed wyjazdem sam musisz uzupełnić jego sekcję 7 (sześć punktów, które trzeba wpisać)" | The inventory gate and the interview come before the first Write. A gap is yours to ask about, with a hypothesis; the user's closing task list is not a deliverable. |
| Handed the remaining work back: "Dalej: wpisz odpowiedzi do sekcji 7 i wyślij Kasi plik albo link." | What the user leaves unanswered goes into "Luki" and the final report. |
| Claims nothing supported: "Limit przepustowości: 50 SMS-ów na 10 sekund, czyli ok. 300 na minutę", "Powtarzaj to w każdy poniedziałek rano", "najlepiej w środę 28 października", renewal steps nobody described | Trace each claim to repo, user or a "Luki" line. A batch size in a spec is not a gateway limit. |
| Restated the spec: "Usługa przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI. …" (section 2, near-verbatim from spec section 1; D1/D2 likewise) | Explain in your own words, one level deep, and link to the spec; never copy its sentences. A line-level copy check misses a near-verbatim paraphrase, so check by reading. |
| No pinned repo state — nothing says which commit the package describes | Section 0: `Opisuje commit <short SHA>.` — the one pin in the package. |
| Verified by its own hand: "Wszystkie cztery ustalenia są już w `PRZEKAZANIE.md` (grep wyżej)" — a grep of its own file for the words it had just been given | The cold read is the check: a reader with only the package, answering scenarios. |
| Asked about company infrastructure: „Sieć: hipoteza — 10.100.100.205 to rezerwacja DHCP na routerze labu, który Ty administrujesz; kolejna płytka wymaga dopisania jej MAC tam. Kto/gdzie?” (the answer: „po prostu router w biurze”) | Company infrastructure is in `docs.internal.animativ.dev`. One line in the package points there; never ask. |
| Asked about run history: „Od 2026-09-28 był jakiś run?” | Describe the mechanism as the code has it; a spec's claim about what was run or verified goes in `wg speca`. |
| Asked who the reader is: „Odbiorca: git na tej maszynie ma użytkownika „Ernest”, commity są od mpeciakk. Pakiet jest dla Ernesta?” | The reader is a company employee or the author later; no name, no profile. |
| Wrote events with dates: „2026-10-08 na `9c09e78` przeszło 194 z 194 testów”, „Wg speca pełne e2e z reflashem 2026-09-28 zakończyło się akceptacją A2 na płytce pod adresem 10.100.100.205” | Current state only; the commit line in section 0 is the one pin. |
| Tied the package to the author's setup: „Na `pc` jest herdr 0.9.3”, „`.flow/` (…) to archiwum uzasadnień z osobistego workflow autora — nie musisz go kontynuować” | Machine- and person-agnostic: no author machines, paths, local versions or personal tooling. |
| Sent the reader to the exceptions first: „Najpierw przeczytaj sekcję 7 (pułapki), potem 3 i 6.” | Normal flow first: how it works, then a typical task, then failures. |
| Left „Co to robi” at two sentences plus a link, and the map as a table of file paths | Section 2 explains how a typical run flows through the parts; a reader who stops there knows how the project works. |
| Wrote a flow the spec describes as plain present-tense steps in section 2, over code that does not implement it; the gap appears only in another section | Section 2 says next to the flow that the code does not implement it, and points to "Luki". |
| Invented a stop condition or a procedure the user never described: a threshold, an escalation step, a step that restores something | Each "when it applies" and "when to stop" traces to repo, user or "Luki"; an unknown stop condition is a listed gap. |
| Patched the package after the cold read and skipped the re-dispatch, reasoning that the patch changes no facts | Every patch gets a fresh dispatch; a patch that adds a step or a condition is new content nobody has read cold. |
| Listed a gap with no consequence: „**Kontakt do SoMLabs** — nieznany pakietowi.” | Each gap: `Skutek:` and `Do czasu ustalenia:`; blockers first. |
| Gave a workaround with no condition: „Porównaj MAC-i interfejsów przewodowych z sondą i odpowiedz `dalej`.” | Each workaround says when it applies and when to stop instead. |
