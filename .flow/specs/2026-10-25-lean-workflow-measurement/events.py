#!/usr/bin/env python3
"""events.py — dump run-relevant events from main Claude Code sessions since 2026-09-27 as TSV."""
import glob, json, os, re, sys
ROOT = os.path.expanduser("~/.claude/projects")
SINCE = "2026-09-27"
NOT_HUMAN = ("<", "Another Claude session", "Base directory for this skill", "Caveat:", "[Request interrupted")
out = sys.stdout
for path in glob.glob(f"{ROOT}/*/*.jsonl"):
    if os.path.getmtime(path) < 1790000000 - 10**7:  # cheap prefilter, refined by timestamp below
        pass
    sid = os.path.basename(path)[:-6]
    proj = path.split("/")[-2]
    pending = {}
    for line in open(path, encoding="utf-8", errors="replace"):
        try: e = json.loads(line)
        except ValueError: continue
        ts = e.get("timestamp") or ""
        if ts < SINCE or e.get("isSidechain"): continue
        msg = e.get("message") or {}
        content = msg.get("content")
        if e.get("type") == "user":
            if isinstance(content, str):
                text = content.strip()
                if text.startswith("[Request interrupted"):
                    out.write(f"{ts}\t{proj}\t{sid}\tinterrupt\t\n"); continue
                if text and not text.startswith(NOT_HUMAN):
                    out.write(f"{ts}\t{proj}\t{sid}\thuman\t{text[:150]!r}\n")
                continue
            for b in content or []:
                if not isinstance(b, dict): continue
                if b.get("type") == "text":
                    t = b.get("text", "").strip()
                    if t.startswith("[Request interrupted"):
                        out.write(f"{ts}\t{proj}\t{sid}\tinterrupt\t\n")
                    elif t and not t.startswith(NOT_HUMAN):
                        out.write(f"{ts}\t{proj}\t{sid}\thuman\t{t[:150]!r}\n")
                elif b.get("type") == "tool_result" and b.get("tool_use_id") in pending:
                    kind = pending.pop(b["tool_use_id"])
                    c = b.get("content")
                    if isinstance(c, list): c = " ".join(x.get("text", "") for x in c if isinstance(x, dict))
                    out.write(f"{ts}\t{proj}\t{sid}\t{kind}-result\t{str(c)[-300:]!r}\n")
        elif e.get("type") == "assistant":
            for b in content or []:
                if not isinstance(b, dict) or b.get("type") != "tool_use": continue
                inp = b.get("input") or {}
                name = b.get("name")
                if name == "Bash" and "flow-state" in inp.get("command", "") and re.search(r"\b(init|set|clear|task)\b", inp.get("command", "")):
                    out.write(f"{ts}\t{proj}\t{sid}\tflow\t{inp['command'][:200]!r}\n")
                elif name in ("Agent", "Task"):
                    st = inp.get("subagent_type", "general-purpose")
                    pending[b["id"]] = f"agent:{st}"
                    out.write(f"{ts}\t{proj}\t{sid}\tagent:{st}\t{inp.get('description','')[:80]!r}\n")
                elif name == "Skill":
                    out.write(f"{ts}\t{proj}\t{sid}\tskill\t{inp.get('skill')}\n")
