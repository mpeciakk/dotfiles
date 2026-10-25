#!/usr/bin/env python3
"""runs.py — per run: go (stage=implement) → finish (stage=finish), wall/active/wait hours, human turns, interrupts, corrections, reviewer dispatches."""
import glob, json, os, re, sys, datetime as dt
ROOT = os.path.expanduser("~/.claude/projects")
SINCE, LEAN = "2026-09-26", "2026-10-11T00:49"
NOT_HUMAN = ("<", "Another Claude session", "Base directory for this skill", "Caveat:")
CORRECTION = re.compile(r"(^nie[ ,.!]|dlaczego|czemu|przecież|znowu|nadal|wciąż|still|miałeś|miałes|\bstop\b|źle|nie działa|nie dziala|why did)", re.I)
def norm(proj):
    p = re.sub(r"--claude-worktrees-.*$", "", proj)
    return "-home-m-dotfiles" if p.startswith("-home-m-dotfiles") else p
def t(s): return dt.datetime.fromisoformat(s.replace("Z", "+00:00"))
ev = {}  # normproj -> list of (ts, sid, kind, text)
for path in glob.glob(f"{ROOT}/*/*.jsonl"):
    proj = norm(path.split("/")[-2]); sid = os.path.basename(path)[:8]
    if "obsidian" in proj: continue
    for line in open(path, encoding="utf-8", errors="replace"):
        try: e = json.loads(line)
        except ValueError: continue
        ts = e.get("timestamp") or ""
        if ts < SINCE or e.get("isSidechain") or e.get("type") not in ("user", "assistant"): continue
        c = (e.get("message") or {}).get("content")
        blocks = [{"type": "text", "text": c}] if isinstance(c, str) else [b for b in c or [] if isinstance(b, dict)]
        for b in blocks:
            k, txt = "assistant" if e["type"] == "assistant" else "tool", ""
            if e["type"] == "user" and b.get("type") == "text":
                txt = b.get("text", "").strip()
                if txt.startswith("[Request interrupted"): k = "interrupt"
                elif txt and not txt.startswith(NOT_HUMAN): k = "human"
                else: k = "system"
            elif b.get("type") == "tool_use":
                inp = b.get("input") or {}
                cmd = inp.get("command", "") if b.get("name") == "Bash" else ""
                if "flow-state" in cmd and "stage=implement" in cmd: k, txt = "go", cmd
                elif "flow-state" in cmd and "stage=finish" in cmd: k = "finish"
                elif b.get("name") in ("Agent", "Task"): k, txt = "agent", inp.get("subagent_type", "general-purpose")
            ev.setdefault(proj, []).append((ts, sid, k, txt))
PROBE = re.compile(r"^(say ok|use (bash|the write tool) once|use the agent tool exactly once|kontynuuj$)", re.I)
hum_by = {}
for L in ev.values():
    for ts, sid, k, txt in L:
        if k == "human": hum_by.setdefault(sid, []).append(txt)
PROBES = {s for s, H in hum_by.items() if all(PROBE.search(h) for h in H)}
rows = []
for proj, L in ev.items():
    L.sort(); run = None
    for i, (ts, sid, k, txt) in enumerate(L):
        if k == "go":
            m = re.search(r"plan=\"?([^\s\"';]+)", txt)
            plan = m.group(1) if m else "?"
            if run and (run["plan"] == plan or plan == "?"): continue  # resumed run / repeated set
            if run: rows.append(run | {"end": "open"})
            run = {"proj": proj, "plan": plan, "go": ts, "sid": sid, "events": []}
        elif run:
            if k == "finish":
                run["end"] = ts; rows.append(run); run = None
            else: run["events"].append((ts, sid, k, txt))
    if run: rows.append(run | {"end": "open"})
w = csv = sys.stdout
print("period\tproj\tplan\tgo\tend\twall_h\twait_h\tactive_h\thuman\tinterrupt\tcorrective\ttask_rev\tbranch_rev\tagents\timpl_active_h")
for r in sorted(rows, key=lambda r: r["go"]):
    if r["end"] == "open": end = r["events"][-1][0] if r["events"] else r["go"]
    else: end = r["end"]
    prev, wait, hum, intr, corr, agents = {}, 0.0, [], 0, 0, {}
    own = {r["sid"]} | {sid for ts, sid, k, txt in r["events"] if k in ("agent", "go", "finish")}
    wait, hum, intr, corr, agents, last = 0.0, [], 0, 0, {}, r["go"]
    review_at, wait_at_review = None, 0.0
    for ts, sid, k, txt in r["events"]:
        if sid in PROBES or sid not in own: continue
        gap = max((t(ts) - t(last)).total_seconds(), 0)
        if k in ("human", "interrupt") or gap > 7200:  # >2h silent = machine off / session closed, not agent work
            wait += gap
        if k == "human": hum.append(txt); corr += bool(CORRECTION.search(txt))
        elif k == "interrupt": intr += 1
        if k == "agent": agents[txt] = agents.get(txt, 0) + 1
        if k == "agent" and txt in ("branch-reviewer", "code-reviewer", "final-reviewer") and review_at is None: review_at, wait_at_review = ts, wait
        last = ts
    wall = (t(end) - t(r["go"])).total_seconds() / 3600
    impl = ((t(review_at) - t(r["go"])).total_seconds() - wait_at_review) / 3600 if review_at else float("nan")
    period = "post" if r["go"] >= LEAN else "pre"
    print(f"{period}\t{r['proj'][7:]}\t{os.path.basename(r['plan'])}\t{r['go'][:16]}\t{end[:19]}\t{wall:.2f}{'*' if r['end']=='open' else ''}\t{wait/3600:.2f}\t{wall-wait/3600:.2f}\t{len(hum)}\t{intr}\t{corr}\t{agents.get('task-reviewer',0)}\t{agents.get('branch-reviewer',0)}\t{sum(agents.values())}\t{impl:.2f}")
    with open("/tmp/lean-measure/human-in-runs.txt", "a") as f:
        for h in hum: f.write(f"{period}\t{r['proj'][7:]}\t{os.path.basename(r['plan'])}\t{h[:300]!r}\n")
