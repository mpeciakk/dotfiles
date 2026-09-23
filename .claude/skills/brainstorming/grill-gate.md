# Grill Gate

A conditional completeness check that runs **after** initial clarifying questions
and **before** proposing approaches. Its job: guarantee every decision that
shapes the design is resolved *by the user*, not silently assumed by you — but
stay completely quiet when nothing is actually open.

## The rule

Before you propose approaches, scan your current understanding for **open
decision points**. An open decision point is any one of:

- an **assumption** you would otherwise make that the user has not stated, and
  that changes the design if it turns out wrong
- a **requirement** that can be read two different ways
- a **fork** (X vs Y) where you would otherwise silently pick a side
- a **dependency between decisions** not yet resolved (deciding A changes what B
  can be)
- a **success / acceptance criterion** not yet pinned down
- an **error or edge-case behavior** left undefined

Then branch:

- **Zero open decision points → skip the grill entirely.** Ask nothing, proceed
  straight to approaches, and don't announce the skip — silence is the correct
  output when everything is clear. Skip only when the request pins down purpose,
  solution shape, success criteria, and obvious edge-case behavior, such that any
  competent implementer would build materially the same thing ("rename this env
  var everywhere" is a skip; a change whose outcome depends on an unvoiced choice
  is a grill, however small).
- **One or more open decision points → grill.** A single genuine open point is
  enough to trigger this. Sensitivity is deliberate: err toward surfacing a
  decision rather than assuming it.

## The grill loop (only when triggered)

Interview relentlessly until every open decision point is closed. Walk down each
branch of the decision tree, resolving dependencies **first** (a decision that
gates other decisions comes before them).

- **One question at a time.** Wait for the answer before the next. Multiple
  questions at once is bewildering.
- **Every question carries your recommended default** and one line of reasoning,
  so the user can just confirm.
- **Facts you look up; decisions you ask.** If something is discoverable from the
  filesystem, tools, or docs, find it yourself — never ask the user for a fact
  you can retrieve. Only genuine *decisions* go to the user.
- **Re-scan after each answer.** An answer can open new points or close several
  at once. Continue until the scan returns zero.

Do not proceed to approaches until the scan is clean.

## Recording decisions

When the grill runs, every resolved decision lands where brainstorming's "The
Project Spec" puts decisions: the chosen option and its one-line rationale in the
living spec (its decision table, or the section it governs); the branch the user
turned down, and why, in the deliberation record. On the spec-intake path, fold
it back into the provided spec. Nothing gets a third copy.

A decision point where both branches lead to materially the same
implementation is not open: pick one, record it the same way, and move on.

## Anti-patterns

- **Grilling to look thorough.** If the scan is genuinely empty, asking anyway is
  noise. Don't manufacture questions.
- **Silent assumption.** The failure this gate exists to prevent: picking a side
  on a real fork without telling the user. When in doubt, it's a decision — ask.
