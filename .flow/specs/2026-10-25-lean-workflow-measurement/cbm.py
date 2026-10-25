#!/usr/bin/env python3
"""cbm.py — codebase-memory-mcp calls vs grep/find searches, pre/post lean, by session role (main or subagent type)."""
import glob, json, os, re, collections
ROOT = os.path.expanduser("~/.claude/projects")
LEAN = "2026-10-11T00:49"
cnt = collections.Counter()
for path in glob.glob(f"{ROOT}/*/*.jsonl") + glob.glob(f"{ROOT}/*/*/subagents/*.jsonl"):
    if "obsidian" in path: continue
    role = "main"
    if "/subagents/" in path:
        meta = path[:-6] + ".meta.json"
        role = json.load(open(meta)).get("agentType", "subagent?") if os.path.exists(meta) else "subagent?"
    for line in open(path, encoding="utf-8", errors="replace"):
        if '"tool_use"' not in line: continue
        try: e = json.loads(line)
        except ValueError: continue
        ts = e.get("timestamp") or ""
        if ts < "2026-09-27": continue
        per = "post" if ts >= LEAN else "pre"
        for b in (e.get("message") or {}).get("content") or []:
            if not isinstance(b, dict) or b.get("type") != "tool_use": continue
            n = b.get("name", "")
            if n.startswith("mcp__codebase-memory-mcp__"): cnt[(per, role, n.split("__")[-1])] += 1
            elif n == "Grep" or (n == "Bash" and re.match(r"\s*(cd [^;&]+[;&]+\s*)?(rg|grep|find)\b", (b.get("input") or {}).get("command", ""))): cnt[(per, role, "grep/find")] += 1
for k in sorted(cnt): print(*k, cnt[k], sep="\t")
