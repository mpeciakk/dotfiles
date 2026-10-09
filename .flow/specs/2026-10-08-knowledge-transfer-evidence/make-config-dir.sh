#!/usr/bin/env bash
# make-config-dir.sh <src> <dst> — a throwaway CLAUDE_CONFIG_DIR: symlinks to
# every entry of <src>, except that skills/ and agents/ are real dirs holding
# symlinks minus skills/knowledge-transfer and agents/kt-cold-reader.md, so a
# nested claude loads the fixture's project-level copies of those two.
set -eu
SRC=$1; DST=$2
[ ! -e "$DST" ] && [ ! -L "$DST" ] || { echo "make-config-dir.sh: $DST already exists" >&2; exit 1; }
shopt -s dotglob nullglob
mkdir -p "$DST"
for e in "$SRC"/*; do
  name=${e##*/}
  case "$name" in
    skills|agents)
      mkdir "$DST/$name"
      for s in "$e"/*; do
        sub=${s##*/}
        [ "$name/$sub" = "skills/knowledge-transfer" ] || [ "$name/$sub" = "agents/kt-cold-reader.md" ] && continue
        ln -s "$s" "$DST/$name/$sub"
      done ;;
    *) ln -s "$e" "$DST/$name" ;;
  esac
done
echo "$DST"
