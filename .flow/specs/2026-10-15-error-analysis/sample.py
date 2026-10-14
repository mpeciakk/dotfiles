#!/usr/bin/env python3
"""sample.py <out.tsv> [exclude-session-id...] — stratified sample of main Claude Code sessions for error analysis.

Population: main sessions (no subagents) under ~/.claude/projects whose first human
turn is on or after 2026-09-01, excluding the vault (obsidian) and /tmp projects.
Strata use the first human turn's timestamp, not file mtime (a resumed session
keeps the setup it started under).
"""
import datetime, glob, json, os, random, re, sys

ROOT = os.path.expanduser("~/.claude/projects")
START = datetime.datetime(2026, 9, 1, tzinfo=datetime.timezone.utc)
LEAN = datetime.datetime(2026, 10, 11, 1, tzinfo=datetime.timezone.utc)  # merge 4e11030, 02:49 +0200
SEED = 20261015
SIZES = {"signal": 15, "quiet": 15, "lean": 10}
CORRECTION = re.compile(
    r"(\[Request interrupted|^nie[ ,.!]|dlaczego|czemu|przecież|znowu|nadal|wciąż|"
    r"still|miałeś|miałes|\bstop\b|źle|nie działa|nie dziala|why did)", re.I)
NOT_HUMAN = ("<", "Another Claude session", "Base directory for this skill", "Caveat:")


def human_turns(path):
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            e = json.loads(line)
        except ValueError:
            continue
        if e.get("type") != "user" or e.get("isSidechain"):
            continue
        m = e.get("message", {}).get("content")
        if isinstance(m, str):
            text = m
        else:
            text = " ".join(b.get("text", "") for b in m or [] if isinstance(b, dict) and b.get("type") == "text")
        text = text.strip()
        if text and not text.startswith(NOT_HUMAN):
            yield e.get("timestamp"), text


def main(out, exclude):
    rows = []
    for path in glob.glob(f"{ROOT}/*/*.jsonl"):
        if os.path.basename(path)[:-6] in exclude:  # the session running the analysis
            continue
        project = path.split("/")[-2]
        if "obsidian" in project or project.startswith("-tmp"):
            continue
        turns = list(human_turns(path))
        if not turns or not turns[0][0]:
            continue
        first = datetime.datetime.fromisoformat(turns[0][0].replace("Z", "+00:00"))
        if first < START:
            continue
        signal = any(CORRECTION.search(t) for _, t in turns)
        stratum = "lean" if first >= LEAN else ("signal" if signal else "quiet")
        rows.append((stratum, first.isoformat(timespec="minutes"), project, path, len(turns), turns[0][1][:100].replace("\t", " ").replace("\n", " ")))
    rng = random.Random(SEED)
    picked = []
    for stratum, n in SIZES.items():
        pool = sorted(r for r in rows if r[0] == stratum)
        print(f"{stratum}: {len(pool)} in pool, taking {min(n, len(pool))}", file=sys.stderr)
        picked += rng.sample(pool, min(n, len(pool)))
    with open(out, "w", encoding="utf-8") as f:
        f.write("stratum\tfirst_turn\tproject\tpath\thuman_turns\tfirst_message\n")
        for r in picked:
            f.write("\t".join(map(str, r)) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], set(sys.argv[2:]))
