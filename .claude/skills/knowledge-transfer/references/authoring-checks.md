# KT authoring checks

Use the scan questions before the inventory and the writing patterns when
drafting procedures. Select what the intake goal and system require. This is
not a list of extra mandatory sections or questions to ask the user verbatim.

## Scan for missing capabilities and resources

For each relevant area, record covered / gap / not applicable in working notes.
Turn a gap that prevents the intake goal into an essential capability blocker.

| Area | Questions to resolve from sources, then interview if needed |
|---|---|
| Purpose and decisions | What useful result does the system produce? What counts as success? What does the reader decide, and what does the system do automatically? |
| Dependencies and environments | What runs where? Which external systems, hardware, images, datasets or manual configuration are required? Which environment or variant is described? What happens when a dependency is unavailable? |
| Persistent state and recovery | What survives a restart? What can be regenerated, and what must be preserved? Where are required copies or recovery artifacts, and how is state restored when relevant? |
| Operation and change | How does the reader start, stop, resume, check health, test, release and undo a change? Which actions can be repeated safely, and how is partial completion recognized? |
| Recurring work and ownership | What manual maintenance, renewals or scheduled tasks keep it working? Where is their status checked? Who knows, decides or can resolve a gap? |

Do not demand a backup procedure for a stateless library or an on-call rota
for a local utility. Do not infer schedules or limits from generic guidance.
Company access procedures remain in `docs.internal.animativ.dev`; project
dependencies and the location of project-specific actions belong in the KT.
Never read secret values to fill an inventory.

## Interview prompts for tacit knowledge

Choose only prompts that address a gap left by the scan:

- What needs manual intervention even though it appears automated in the repo?
- What observation distinguishes slow progress from a stuck process?
- Which apparently reasonable recovery action would worsen this problem, and why?
- What must be preserved to reproduce the system without the author's setup?
- Which workaround still applies, and what would make it unnecessary?

Use a concrete hypothesis from the sources where possible. Ask about current
mechanisms and rules, not dates or whether a previous run succeeded.

## Procedure pattern

Keep one concrete example on the normal path. Put extended explanations in
sections 1–2 and diagnosis in section 6, all within the same KT document.
Use only fields that matter for this task; missing required information is a gap.

```text
Cel i wynik: what the reader will have at the end.
Warunki wejścia: when this procedure applies and what must already be true.
Gdzie: target environment, machine role and working directory.
Dane wejściowe: sample input and how to obtain reader-specific values.
Skutki: state changes, interruptions or data loss relevant to this operation.

1. Exact action or command.
   Oczekiwany wynik: an observable signal, including what to notice.
   Jeśli wynik jest inny: the relevant diagnosis or stopping point.

Potwierdzenie końca: check the task's useful result, not just command exit status.
Przerwanie / ponowienie / cofnięcie: documented conditions and procedure, if relevant.
```

State unavailable or unknown recovery before an affected action. Do not invent
a rollback to fill the template. A failed prerequisite must not be hidden in
the final gap list while the procedure proceeds as if it were satisfied.

## Diagnosis pattern

```text
Objaw i wpływ: what is observed and what function is affected.
Możliwe przyczyny: supported possibilities; distinguish from a confirmed cause.
Sprawdzenie: the observation or read-only check that separates them.
Wynik A → meaning → supported action.
Wynik B → meaning → supported action.
Brak rozstrzygnięcia → missing information or the established escalation path.
Po działaniu: how to confirm that the function has recovered.
```

For an unambiguous error, a short entry is sufficient. For an unknown cause,
do not supply a confident fix. Conditions and commands come from project
sources, not from these examples or general operational habits.

## Capability coverage

Maintain a compact working map:

| Capability from intake | Essential? | KT section | Scenario | Covered or blocked, and why |
|---|---|---|---|---|

Update it after the interview and cold read. A matching "unknown" answer is
honest comprehension, but leaves the capability blocked if the missing fact
is needed to perform it. Unknown information that does not prevent the goal
is a nonblocking gap. Include the essential capabilities and blockers in the
final report; do not publish the working source ledger in place of a readable KT.

## Challenge summaries against sources

Use these observed failure patterns when checking claims and scenario keys:

| Claim | What must be checked |
|---|---|
| "The script performs the entire bootstrap" | Does it create missing prerequisites or only preserve existing values? Are any steps conditional on optional files? State the required manual preparation. |
| "The environment is isolated" | Which configuration sources are excluded, and which can still be inherited? Keep relevant exceptions beside the guarantee and in setup requirements. |
| "A mismatch means configuration was lost" | Could a documented change in names or measurement produce the same observation? Establish which case applies before prescribing recovery. |
| "If nothing appears to happen, resume" | What distinguishes failure from ongoing work, and under which conditions is resuming supported? A resume command's existence is not evidence for using it now. |

The reader cannot detect a factual error that the explanation and key repeat
consistently. These checks belong to source verification, not the cold reader.

## Operational consistency check

Check the final draft across sections, not just sentence by sentence. For
each action in a procedure or answer key, compare its prerequisites and
claimed outcome with the relevant failure entry and "Luki". Resolve conflicts
against sources; an unknown recovery listed in gaps cannot become an option
elsewhere through wording such as "nothing to do except retry".

Verify these distinctions where relevant:

| Instruction | Required evidence and wording |
|---|---|
| "When the program prints X, stop before the next step" | Trace what happens after X: does execution actually pause for input? A log message is not a gate. Put required checks before launching an uninterrupted operation. If no supported precheck or pause exists, mark the procedure blocked rather than imply that the reader can safely interrupt it. |
| "Approve this command" | Check the role, intended task, target, effects and secret restrictions. Read-only access, a tool name or output redirection alone is not authorization. Preserve both permitted actions and relevant prohibitions in any shortened rule or answer key. |
| "The system restores the previous state" | Separate the attempted recovery from its verified result. Explain which result establishes success and what remains uncertain if recovery fails; entering a recovery phase is not proof that state was restored. |

In working notes, track relevant exceptions and prior review findings as
handled (with a KT location), unresolved (with its consequence), or outside
scope (with a reason). Check setup requirements as well as troubleshooting:
an inherited configuration exception belongs before starting the system.
An omitted warning is not resolved merely because the broad guarantee was
removed. Recheck the affected keys after correcting the procedure.

## Condensation pass before verification

Keep all eleven headings, with depth proportional to the agreed goal. There
is no target length: line count depends on wrapping, and a complex takeover
may need a long document. Shorten repeated explanation before cutting coverage.

- Give each detail a main home: sections 1–2 explain purpose and relationships;
  4 holds shared prerequisites; 5 gives actions and observable outcomes;
  6 distinguishes failures; 7 explains changes; 9 records unresolved gaps.
  Elsewhere use a brief reminder and the relevant internal heading reference.
- In the normal procedure, combine automatic stages between reader decisions
  when the reader only needs their result. Describe internal steps only when
  they explain a decision, an outcome or a failure the reader must recognize.
- Omit exhaustive message catalogs, internal schemas and implementation limits
  unless they support an agreed capability. Use one map; do not repeat its
  contents as both a table and a diagram without a distinct purpose.
- Keep answer keys to the decisive action, reason and essential conditions,
  with an internal reference for the full procedure. Do not duplicate whole
  troubleshooting entries in the keys.
- After shortening, follow the normal task again: are its inputs, conditions,
  commands, decisions, warnings and completion checks still available? Keep
  blockers visible at affected steps even when fully described in "Luki".
  Verify the condensed version against sources and with the cold reader.

## Reference basis

These sources informed the patterns; they are not additional workflows to run.
The KT skill's scope, user gates and single-document output take precedence.

- [Anthropic doc-coauthoring](https://github.com/anthropics/skills/blob/main/skills/doc-coauthoring/SKILL.md): fresh-reader questions and ambiguity/context checks; omit its per-section approval workflow.
- [Anthropic operations/runbook](https://github.com/anthropics/knowledge-work-plugins/blob/main/operations/skills/runbook/SKILL.md): prerequisites, expected results, failure handling and rollback; omit run history and automatic publication.
- [Diátaxis](https://diataxis.fr/start-here/): separate explanation, guided learning and lookup material within the KT.
- [AWS playbooks](https://docs.aws.amazon.com/wellarchitected/latest/framework/ops_ready_to_support_use_playbooks.html): diagnose before choosing a remedy.
- [Research and comparison](research-2026-10-09.md): rationale, additional sources and future evaluation suggestions; consult when revising the skill, not during every KT.
