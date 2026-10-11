---
name: knowledge-transfer
description: Use when another Animativ employee — or the user, months later — is taking over a company project and needs a handover document. Triggers on "przekazanie projektu", "knowledge transfer", "KT", "ktoś przejmuje", "dokument przekazania", "dokument onboardingowy dla". Not for agent session continuity (handoff) or for describing what a project is (writing-specs).
---

# Knowledge Transfer

A KT package is one document from which a company colleague understands how
the project works and what state it is in, and can do the goal set at intake.
It is a standalone document for the company knowledge base, readable outside
the repository. It explains the knowledge needed for the goal in its own words;
the spec and code are sources for the author, not required reading for the
recipient. The spec stays the source of truth. Every KT covers a company
(Animativ) repo. The reader is another employee of the same company, or the
author months later; either knows the company's infrastructure and has the
company knowledge base `docs.internal.animativ.dev`. Check source accuracy,
reader comprehension and coverage of the goal separately. A reader answering
from the document does not prove that its procedures work on a real system.

Build understanding in this order: the problem and intended result → where
the parts run and how they relate → one concrete task → implementation details
and exceptions. Assume company knowledge, but no prior knowledge of this
project or the author's workflow. The section list organizes this explanation;
filling its headings with facts is not enough.

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
2. **Scan:** pin the full SHA with `git rev-parse HEAD` before reading sources;
   use its short form in the package. Check `git status --short` for staged,
   unstaged and untracked files. Read spec, README, design records, code and
   CI/deploy config from that pinned commit (`git show <SHA>:<path>`), and
   history with `git log <SHA>`, even if HEAD changes later. Reverts, `fix:`
   commits and files that change often are trap candidates. Never attribute
   working-tree changes to the pinned commit. If relevant material exists
   only locally, list its exclusion and the consequence in "Luki" and the
   final report; do not commit it as part of KT. Use the scan questions in
   [authoring checks](references/authoring-checks.md) to find relevant concerns,
   including required resources outside Git. Identify those resources and
   their sources separately; the pinned SHA describes repository content only.
3. **✋ Inventory.** List what the reader must be able to do, each item with
   a priority:
   high / medium / low = how much the goal depends on it × how hard it is to
   get right without the package. Mark which capabilities are essential:
   without them the intake goal cannot be achieved. Add 5–8 scenarios with
   an answer key, built from the high items. Include a scenario explaining
   inputs → cooperating parts → useful output, and a separate scenario walking
   through a normal task with prerequisites, decisions and completion evidence.
   Use the others for relevant failures and changes; a set of troubleshooting
   questions alone is insufficient. Map essential capabilities to
   planned sections and scenarios; a single example may not cover the whole
   goal. Mark unknown answers as gaps, not guessed keys. Show the inventory
   to the user and stop. Nothing is written before the yes.
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
     Obtain the missing inputs for one small, concrete example of the typical
     task: sample requirements or input, project-specific documentation or
     resource locations, and the expected result. Ask about the reason for a
     central design choice when the sources do not explain it. These are
     questions about how the project works, not about past runs; never ask for
     secret values. If unanswered, mark the example's blocked step explicitly.
     When spec and code disagree, you may ask where the actual implementation
     lives (repo, branch or deployment path) and which component or version the
     spec describes. Record the contradiction in "Luki"; locating its source
     is allowed, asking whether or when it was run is not.
     For relevant gaps, ask what depends on manual intervention, how to tell
     slow progress from a stuck process, and which tempting recovery action
     would make things worse. Use the interview prompts in authoring checks
     selectively, not as another mandatory questionnaire.
   - **Never ask:**
     - **Company infrastructure:** network, router, VPN, the company's
       accounts, permissions, SSH or server access, getting into the password
       manager and its procedures. The package carries one line pointing to
       `docs.internal.animativ.dev` instead.
     - **Run history:** when or whether something was run, and
       how it was run in the past. The procedure of the typical task and where
       each step runs may be asked; how to get access there goes to
       `docs.internal.animativ.dev`. The package describes the mechanism as the
       code has it. Where the spec says what was or was not run or verified, the
       package attributes it to the spec, using the phrase `wg speca`, and
       neither confirms nor questions that run-history claim. This restriction
       does not prohibit the source-location and spec-scope questions above.
     - **The reader:** no name, no profile, no skill level.
5. **Write** `docs/kt/YYYY-MM-DD.md`, by the section list below. This is the
   source artifact for publication in the company knowledge base; its content
   must remain complete and readable when moved out of the repository. Use
   the procedure and diagnosis patterns in authoring checks as needed. Update
   the capability map and answer keys with interview findings; never change
   a key merely to make a reader's answer pass. Before verification, apply the
   condensation pass in authoring checks; retain information needed for the
   agreed goal, without a word or line quota.
6. **Source check**, then **cold read**, below.
7. **✋ Final.** Show the package and the verification report, separating:
   - **Source accuracy:** what was checked, unsupported claims and contradictions.
   - **Comprehension:** scenario results and unresolved reader observations.
   - **Goal coverage:** each essential capability covered or blocked, with
     its gap and consequence. Correctly answering "unknown" does not remove
     a blocker. Do not present a scenario pass rate as readiness to take over.
   - **Practical validation:** what, if anything, was actually exercised in
     this KT session; otherwise say it was not performed. Do not ask about
     past runs or treat spec claims as this session's evidence.

   The report includes unanswered questions and the basis for closing each
   blocker. The user's yes = a commit of the package file only, not proof of
   practical readiness. Do not run deployments, recovery or destructive
   exercises just to validate a document without separate authorization.

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
  diagnosing a failure. State any essential capability blocked by a known gap
  here, with a pointer to "Luki", so the opening does not promise an
  unattainable result. Name the applicable environment or variant; outside-repo
  facts are attributed to their sources, not implied to be pinned by the SHA.
- **1:** the problem the project solves, what goes in, the useful result and
  what the project does not do. Explain the central design choice that makes
  the result useful, using its documented reason. Do not invent motivation
  from the implementation; an unknown reason is a gap.
- **2:** first give a map of the system: what runs where, what communicates
  with what, where inputs and outputs live, and which parts are tools versus
  artifacts they produce. Use a small diagram or table when it clarifies the
  relationships; a list of source files is not a map. Choose a diagram or
  table rather than two representations of the same facts. Then summarize
  one normal flow, explaining roles and why the main stages are needed;
  executable steps belong in section 5. Distinguish automatic work from the
  reader's interventions.
  Keep protocol syntax and internal state bookkeeping for sections 6–7 unless
  needed to understand the flow. File names may identify implementations,
  without links. A reader who stops here can explain the system in their own
  words. Where the spec describes a flow the code does not implement, say so
  in this section, next to the flow, and point
  to "Luki"; never write the spec's flow as plain present-tense fact.
- **3:** version, what works, debt and open risks, in the present tense. A spec
  claim that something is unverified is stated as state, with `wg speca` and no
  date.
- **4:** what the reader needs installed or at hand. Project secrets: where,
  never what. Company infrastructure: one line pointing to
  `docs.internal.animativ.dev`.
- **5:** one small, concrete worked example from start to finish, chosen from
  the intake goal. Supply the sample input and required project resources
  from the repo or interview, then carry that same example through to its
  expected output. Explain how to obtain any reader-specific values that must
  remain placeholders. Each step names where it runs, what the reader does,
  what happens automatically and how success looks. At each decision, say
  what to inspect and what approval authorizes. An unresolved prerequisite
  appears at the blocked step with a pointer to "Luki"; do not claim the
  example is executable when it is not. Present the normal path first, with
  failures handled in section 6. Before a state-changing operation, explain
  its prerequisites and effects, including interruption or data loss where
  relevant. Describe how to recognize partial completion, whether it can be
  repeated and how to stop, resume or roll back when those matter. Unknown
  recovery or repeatability is a gap stated before the affected action.
- **6:** symptom and impact → diagnostic check → interpretation → action →
  confirmation of recovery. Distinguish possible causes from confirmed ones;
  when a symptom has several causes, include an observation that distinguishes
  them before choosing a workaround. A concise lookup entry is enough for an
  unambiguous case. A reported mismatch or timeout alone does not establish
  its cause. Each action says when it applies and when to stop; knowing how
  to restart or retry does not establish when it is appropriate. If the
  choice cannot be resolved, keep it unresolved rather than recommend a fix.
  Checks, thresholds, recovery and escalation steps must come from the repo,
  user or attributed extra materials; if unknown, state the limitation and
  list the gap. A "Luki" item documents
  missing evidence; it cannot serve as evidence for an invented procedure.
- **7:** one worked example of a typical change: which files, which tests, when
  a run on real hardware or a real environment is needed, how a change is
  released. Explain relevant decisions and their reasons here; decision IDs
  and source file names may be given without links.
- **8:** who knows what, who decides and how to escalate. If known, name who
  maintains the KT in the knowledge base and which changes require a new
  snapshot (for example a changed deployment procedure or external dependency).
  Do not assign an owner or review schedule yourself.
- **9:** blockers first. Each item has the form
  `- **<gap>.** Skutek: <what the reader cannot do>. Do czasu ustalenia: <what to do meanwhile>.`
  For blockers, add `Domknięcie:` — the information or evidence needed to
  close the gap and who can supply it, if known. Do not invent interim actions;
  say when no supported way to proceed is known.
- **10:** 5–8 scenarios with an answer key (the cold read runs on them), then
  2–3 practical tasks derived from the goal, without solutions but with the
  required environment and observable completion criteria. Label a task whose
  prerequisites are missing as blocked. A proposed exercise is not evidence
  that it was performed.

Rules for all sections:

- **Complete for the goal, economical to read.** Include details that help
  the reader understand, act, decide or diagnose within the agreed scope.
  Explain each topic fully in one place and use short internal references
  elsewhere. Keep critical conditions and warnings at the point of action.
  Do not repeat the whole flow in the overview, procedure and answer keys,
  or move essential knowledge out of the document to make it shorter.
- **Current state, not events.** Apart from the commit line, the package holds
  no dates, no test-run results, no descriptions of past runs and no "last
  time" statements. Write a recurring deadline as its rule and where to check
  it, not as a date: „token wygasa co 90 dni; datę wygaśnięcia pokazuje panel
  SMSAPI”.
- **Machine- and person-agnostic.** The package has no names of the author's
  machines, no home or `/tmp` paths, no local tool versions, no author's
  personal tooling as context, and no addressee. Facts about people as project
  state are fine: „projekt zna tylko autor”.
- **Explain, don't copy.** Synthesize in your own words, with enough detail
  for the reader to act and decide. Include the explanations, procedures and
  decision reasons needed for the goal in
  the package itself. Preserve exact commands, identifiers, messages and
  definitions where paraphrasing would change their meaning. Do not paste
  spec passages in place of an explanation.
- **Introduce concepts before notation.** Explain project-specific terms at
  first use and prefer ordinary Polish over the author's workflow jargon.
  Name a problem or decision by its meaning; a decision ID or spec section
  number can supplement that name, never replace it. Introduce commands and
  protocol tokens where the reader needs to use or recognize them.
- **Standalone outside the repo.** No links or embeds pointing to project
  files, whether relative, local or hosted in a repository browser. File names
  and repo-relative paths in plain text or inline code are fine as identifiers,
  for example `src/worker.py`; they never replace an explanation with "see this
  file". Links within the KT document and to the company knowledge base or
  external services are allowed. Internal heading links use real anchors.
- Every claim traces to the repo, to something the user said, or to
  explicitly attributed extra materials. An unresolved claim is marked as
  unconfirmed where it appears and recorded in "Luki", never used as a premise
  for an instruction. Nothing else is written —
  not an inferred schedule, not a procedure nobody described, not arithmetic
  dressed as a limit.

## Source check

Before cold reading, check operational claims and answer keys against their
sources: exact commands and arguments, working directories, required resources,
effects, limits, diagnostic interpretations, recovery and success criteria.
Use the pinned code for what it implements, the spec for intent and attributed
verification claims, and user answers or extra materials for external facts.
Code presence does not prove deployment or successful execution. Preserve the
run-history boundary; do not seek fresh confirmation of historical spec claims.

For each operational guarantee ("automatically", "only", "all", "enough"),
check the source's conditions, optional branches and known exceptions. Preserve
them in summaries and answer keys as well as detailed procedures. Distinguish
creating a prerequisite from preserving an existing one, and successful program
exit from achieving the reader's goal. Inspect relevant open risks and failure
paths; a supporting happy-path excerpt is not enough. For diagnoses, verify
both what establishes the cause and what authorizes the proposed remedy.
Follow the operational consistency check in authoring checks on the final
draft, including after condensation: cross-check procedures, prerequisites,
gaps and answer keys, and verify actual intervention points in sources.
For each relevant source risk or exception, record in working notes where
the package handles it or why it is outside the agreed goal. In a revision,
also account for previously identified review findings; rewriting does not
close them. These checks do not add sections to the published KT.

Keep a compact claim → source → result ledger in working notes (repo path at
the SHA, user answer or supplied material). It supports the final report and
does not require links in the KT or a second committed artifact. Fix mismatches;
state unresolved conflicts and their practical consequences in "Luki" and
beside the affected procedure. Recheck changed claims and keys after repairs.
Repeating a claim in the package, the key and a cold-reader answer is not
independent evidence that it is true.

## Cold read

Before dispatch, check that no link or embed targets a project file and that
no explanation needed for the goal is deferred to another project document.
Include that knowledge in the package, or list it in "Luki" if it is unknown.
Read sections 1, 2 and 5 in sequence: can a newcomer understand the purpose,
locate the parts and follow the example without reconstructing the process
from the troubleshooting tables? Repair the explanation if not. Scenario
answers must also cover these connections and the reader's decisions;
command lookup alone does not demonstrate understanding. A cold read checks
textual completeness, not successful execution on a real system.

Verification by someone who has only the package. Dispatch the agent
`kt-cold-reader` in the **foreground** (`run_in_background: false` — the next
step needs its answers):

- `subagent_type: "kt-cold-reader"`, always `model: "sonnet"`.
- Prompt: `PAKIET:` + the package with the answers of "Sprawdź się" removed +
  `SCENARIUSZE:` + the numbered scenarios.
- The practical tasks of section 10 are not sent as scenarios.
- A scenario **fails comprehension** when `Podstawa` is `NIE WIEM Z PAKIETU`
  or `ZGADUJĘ`, or the answer contradicts the key — except a scenario whose key says the package
  does not know: it passes comprehension on `NIE WIEM Z PAKIETU` and still
  fails on `ZGADUJĘ` or a confident answer. If that unknown blocks an essential
  capability, goal coverage remains blocked even though comprehension passes.
- Review `Przeszkoda` in each answer and the final `Uwagi do pakietu` for
  missing context, undefined terms, ambiguous instructions and contradictions.
  An issue that prevents correct understanding or action fails the relevant
  capability's check even if the short answer matches the key. Adjudicate
  findings against sources; do not invent facts to satisfy a reader.
- Patch supported omissions or misreadings, recording unresolved ones as gaps, then
  **re-run**: a fresh dispatch of `kt-cold-reader` with the patched package.
  An unchecked patch is not a patch — not when the dispatch costs time, and
  not when you believe the fix is obvious. At most **2 patch rounds**. What
  still fails goes into "Luki" and the final report. There is no third round.
  If final gap annotations change the package after the last read, disclose
  that this final version was not re-read; do not claim it passed in full.

## Hard rules

- **Secrets: location only** — the vault, the 1Password entry, the env var
  name — never a value. Check the package for values before the cold-reader
  dispatch too, since the prompt carries the whole package. Do not open
  `.env`-style files to see what is in them (templates such as `.env.example`
  are fine).
- **Polish**, written per the `polszczyzna` skill.
- **Commit only the package**, only after the final ✋.

## Common mistakes

The quoted rows come from three runs: the skill-less baseline run
(`.flow/specs/2026-10-08-knowledge-transfer-evidence/baseline.md`), the first
real KT run (edge-vibecoding, D31) and the second real KT run (edge-vibecoding,
D32). The unquoted generic rows describe failures seen in the D32 fixture runs
(`.flow/specs/2026-10-08-knowledge-transfer-evidence/d32.md`).

| Mistake | Counter |
|---|---|
| Wrote the whole package first, asked nothing: "przed wyjazdem sam musisz uzupełnić jego sekcję 7 (sześć punktów, które trzeba wpisać)" | The inventory gate and the interview come before the first Write. A gap is yours to ask about, with a hypothesis; the user's closing task list is not a deliverable. |
| Handed the remaining work back: "Dalej: wpisz odpowiedzi do sekcji 7 i wyślij Kasi plik albo link." | What the user leaves unanswered goes into "Luki" and the final report. |
| Claims nothing supported: "Limit przepustowości: 50 SMS-ów na 10 sekund, czyli ok. 300 na minutę", "Powtarzaj to w każdy poniedziałek rano", "najlepiej w środę 28 października", renewal steps nobody described | Trace each claim to repo, user or attributed materials. Record missing evidence in "Luki"; the gap entry is not evidence. A batch size in a spec is not a gateway limit. |
| Restated the spec: "Usługa przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI. …" (section 2, near-verbatim from spec section 1; D1/D2 likewise) | Explain the flow and reasons in your own words with enough context to understand the package on its own. Preserve exact technical literals where needed; do not replace explanation with pasted spec prose. Check by reading, not only by matching lines. |
| No pinned repo state — nothing says which commit the package describes | Section 0: `Opisuje commit <short SHA>.` — the one pin in the package. |
| Verified by its own hand: "Wszystkie cztery ustalenia są już w `PRZEKAZANIE.md` (grep wyżej)" — a grep of its own file for the words it had just been given | Check facts against sources, comprehension with the cold-reader, and goal coverage against essential capabilities. Finding a phrase in the package proves none of these by itself. |
| Asked about company infrastructure: „Sieć: hipoteza — 10.100.100.205 to rezerwacja DHCP na routerze labu, który Ty administrujesz; kolejna płytka wymaga dopisania jej MAC tam. Kto/gdzie?” (the answer: „po prostu router w biurze”) | Company infrastructure is in `docs.internal.animativ.dev`. One line in the package points there; never ask. |
| Asked about run history: „Od 2026-09-28 był jakiś run?” | Describe the mechanism as the code has it; a spec's claim about what was run or verified goes in `wg speca`. |
| Asked who the reader is: „Odbiorca: git na tej maszynie ma użytkownika „Ernest”, commity są od mpeciakk. Pakiet jest dla Ernesta?” | The reader is a company employee or the author later; no name, no profile. |
| Wrote events with dates: „2026-10-08 na `9c09e78` przeszło 194 z 194 testów”, „Wg speca pełne e2e z reflashem 2026-09-28 zakończyło się akceptacją A2 na płytce pod adresem 10.100.100.205” | Current state only; the commit line in section 0 is the one pin. |
| Tied the package to the author's setup: „Na `pc` jest herdr 0.9.3”, „`.flow/` (…) to archiwum uzasadnień z osobistego workflow autora — nie musisz go kontynuować” | Machine- and person-agnostic: no author machines, paths, local versions or personal tooling. |
| Sent the reader to the exceptions first: „Najpierw przeczytaj sekcję 7 (pułapki), potem 3 i 6.” | Normal flow first: how it works, then a typical task, then failures. |
| Left „Co to robi” at two sentences plus a link, and the map as a table of file paths | Section 2 explains how a typical run flows through the parts; a reader who stops there knows how the project works. |
| Wrote a flow the spec describes as plain present-tense steps in section 2, over code that does not implement it; the gap appears only in another section | Section 2 says next to the flow that the code does not implement it, and points to "Luki". |
| Invented a stop condition or a procedure the user never described: a threshold, an escalation step, a step that restores something | Each condition and action has source evidence. An unknown condition is a listed gap, not a procedure legitimized by mentioning it in "Luki". |
| Patched the package after the cold read and skipped the re-dispatch, reasoning that the patch changes no facts | Every patch gets a fresh dispatch; a patch that adds a step or a condition is new content nobody has read cold. |
| Listed a gap with no consequence: „**Kontakt do SoMLabs** — nieznany pakietowi.” | Each gap: `Skutek:` and `Do czasu ustalenia:`; blockers first. |
| Gave a workaround with no condition: „Porównaj MAC-i interfejsów przewodowych z sondą i odpowiedz `dalej`.” | Each workaround says when it applies and when to stop instead. |
