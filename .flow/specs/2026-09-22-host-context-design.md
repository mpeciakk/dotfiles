# Host identity in session context — 2026-09-22

Deliberation record. What was rejected and why; the chosen mechanism lives in
the plan and in the code it produces.

## Problem

Two machines, `pc` (desktop, i5-8600 + RTX 2070) and `laptop` (MacBook Air M2,
Asahi Linux, own name `fairydust`). **Both report hostname `ciek`**, same user
`m`, same prompt `m@ciek` — so no session can tell which machine it is on, and
neither can anyone reading the transcript afterwards.

Not hypothetical. The vault session reports three incidents: a 2026-09-14 sweep
rewrote "on `ciek`" to "on the desktop (`host-pc`)" across seven notes at once;
on 2026-09-21 a session sitting on the desktop recorded "conflicts resolved in
favour of the laptop (`fairydust`)", corrected in three places the next day; a
note claimed a project lived only on `fairydust` when the directories existed on
neither machine.

The ambiguity is amplified by sync: `~/projects`, `~/work`, `~/obsidian` and
`~/.claude/projects` are mutagen-synced through `sirius`, so transcripts move
between machines and the same working tree path exists on both.

## D1 — What identifies the machine

`.dotter/local.toml`'s `packages` entry (`host-pc` / `host-mac`), mapped to the
labels `pc` / `laptop`.

Rejected: **hostname** (`hostnamectl`, `/etc/hostname`, `uname -n`) — it is
`ciek` on both machines, which is what created the problem. Rejected: **chassis
type** (`hostnamectl` reports desktop vs laptop) — generic, and it would report
a machine identity the repo has no other use for. The dotter package is the
repo's existing notion of host identity and the file already exists per machine
and is git-ignored.

Rejected: **renaming `host-mac` → `host-laptop`** so all three names agree
(dotter says `mac`, ssh and herdr-mirror say `laptop`). It would need a manual
edit of `.dotter/local.toml` on the laptop at the next pull, and until then
dotter would silently stop deploying that machine's monitor layout and GPU env.
The mapping lives in the hook instead; the cost is one place to update when a
third machine appears.

## D2 — Which event carries it

`UserPromptSubmit` (every user turn) plus `SubagentStart`.

Rejected: **`SessionStart` only** (startup/resume/clear/compact), which was the
first recommendation. It is correct that a process never migrates between
machines mid-session, and each switch is a resume that fires `SessionStart`. It
is wrong about what the injection is for: with the transcript shared between
machines and switched mid-conversation *often*, the turns themselves need to be
attributable. A `SessionStart` line marks the switch point and then sits fifty
turns back while every turn above and below it looks identical — "I checked the
file exists" from turn 12 still names no machine. Per-turn labelling is what
makes a bounced transcript readable.

Rejected: **true change detection**. Now feasible without a state file: the hook
payload carries `transcript_path`, the transcript is the same file on both
machines, so scanning its tail for the last marker and injecting only on a
difference would work. It buys back ~12 tokens per message in exchange for a
tail scan on every prompt and a new failure mode — marker not found, nothing
injected. The per-turn mark is worth more than the tokens it costs.

Rejected: **a state file keyed by session id**. Per-machine state cannot see
what the other machine injected; state in a synced directory lies. The
transcript is the only honest record, and reading it is the variant above.

## D3 — Where the code goes

Merged into the existing `timestamp-injector`, renamed, rather than a second
hook on the same event. Two hooks on `UserPromptSubmit` means two Python
processes per prompt for one line of output, and a hook named
`timestamp-injector` that also emits host identity is misnamed.

## Out of scope, deliberately

The vault session supplied two further traps, both real and both about the
*environment* rather than about which machine it is:

- `XDG_{CACHE,CONFIG,DATA,STATE}_HOME` come from the systemd user manager and do
  not exist in an SSH session; a config that expands `${XDG_CACHE_HOME}` itself
  then creates a directory named literally that, relative to cwd.
- 1Password is the SSH agent and signs commits; after auto-lock `git commit`
  fails with "agent refused operation" while `ssh-add -l` may still look fine.

They are not host-identity facts, and CLAUDE.md is the most expensive text in
this setup — it loads into every session. Left out until asked for.

Also out of scope: a living `spec.md` for dotfiles. The repo has a thorough
README.md and no spec; writing one is its own job (`writing-specs`), not a side
effect of this change.
