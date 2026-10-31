# Provenance

Vendored from https://github.com/nidhinjs/prompt-master.git at `d15eabbe5d2122eedc060bae8a771381e9873d1b`
("docs: update MiniMax routing to M3 as default"), 2026-09-17.

Vendored rather than submoduled because every skill here is edited locally and a
submodule cannot hold those edits. To take an upstream update: clone it fresh,
`diff -r` against this directory, and port what you want.

Local changes since that commit:
- SKILL.md, hard rules and CoT guidance (hard rules, diagnostic checklist, Safe
  Techniques; templates.md Template E; patterns.md #26): current Claude models are
  reasoning-native — no CoT, thinking-depth wording or visible reasoning sections.
- SKILL.md, Claude routing and Claude Code sections: no model roster and no 4.x
  version notes; behaviour stated for current Claude models.
- templates.md Template M is the "Claude Task Brief" (was "Opus 4.7 / 4.8"); no
  thinking-depth lines; a final report instead of per-step progress lines.
- patterns.md #36 is model-neutral; SKILL.md names the 37-pattern reference.
- SKILL.md: plain-emphasis verification item; assumptions named in the 💡 line.
