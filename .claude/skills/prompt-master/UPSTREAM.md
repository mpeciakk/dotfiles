# Provenance

Vendored from https://github.com/nidhinjs/prompt-master.git at `d15eabbe5d2122eedc060bae8a771381e9873d1b`
("docs: update MiniMax routing to M3 as default"), 2026-09-17.

Vendored rather than submoduled because every skill here is edited locally and a
submodule cannot hold those edits. To take an upstream update: clone it fresh,
`diff -r` against this directory, and port what you want.

Local changes since that commit:
- SKILL.md, hard rules: the reasoning-native model list names Claude Opus 5.5 / Fable 5.1 /
  Sonnet 5 (extended thinking or an effort level) alongside o3, o4-mini,
  DeepSeek-R1 and Qwen3.
- SKILL.md, Claude routing and Claude Code sections: the current model line names
  Opus 5.5 / Sonnet 5 / Fable 5.1 / Haiku 4.5 instead of "Opus 4.8 (current
  default)"; the 4.x notes stay, labeled as the previous generation.
