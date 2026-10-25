#!/usr/bin/env python3
"""fixes.py — landed changes (runs from runs.tsv + inline commits) and the fix commits that touch their code files within 7 days."""
import csv, subprocess, re, datetime as dt, glob, os
# every repo under ~/projects, ~/work and ~/dotfiles with commits in the window; the vault is not code
REPOS = sorted({os.path.relpath(os.path.dirname(g), "/home/m") for g in glob.glob("/home/m/projects/*/.git") + glob.glob("/home/m/work/*/.git") + ["/home/m/dotfiles/.git"]
    if subprocess.run(["git", "-C", os.path.dirname(g), "log", "-1", "--since=2026-09-27", "--format=%h"], capture_output=True, text=True).stdout})
FIX = re.compile(r"^(fix|revert|hotfix)\b|napraw", re.I)
NOT_CODE = re.compile(r"(\.md$|^\.flow/|^docs/|spec\.md)")
WEEK = dt.timedelta(days=7)
REVIEW = re.compile(r"review|przegl|red-team|redteam", re.I)
def T(s): return dt.datetime.fromisoformat(s.replace("Z", "+00:00"))
def projkey(repo): return "-" + ("dotfiles" if repo == "dotfiles" else repo.replace("/", "-"))
runs = [r for r in csv.DictReader(open("/tmp/lean-measure/runs.tsv"), delimiter="\t") if "*" not in r["wall_h"] and float(r["wall_h"]) > 0.01]
out, seen = [], set()  # clones of one repo (a spike, a renamed copy) share commits; count each once
for repo in REPOS:
    path = f"/home/m/{repo}"
    br = subprocess.run(["git", "-C", path, "symbolic-ref", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()
    log = subprocess.run(["git", "-C", path, "log", br, "--no-merges", "--since=2026-09-20", "--format=@@%H\t%aI\t%s", "--numstat"], capture_output=True, text=True).stdout
    commits = []
    for chunk in log.split("@@")[1:]:
        head, *files = chunk.strip().split("\n")
        sha, ad, subj = head.split("\t", 2)
        F, lines = set(), 0
        for f in files:
            p = f.split("\t")
            if len(p) == 3:
                F.add(p[2]); lines += int(p[0]) + int(p[1]) if p[0] != "-" else 0
        commits.append({"sha": sha[:8], "t": T(ad), "subj": subj, "files": F, "code": {f for f in F if not NOT_CODE.search(f)}, "lines": lines})
    rr = [r for r in runs if r["proj"] == projkey(repo)[1:] or r["proj"] == projkey(repo)]
    # each commit belongs to the run whose [go, end] holds its author date, else it is inline
    changes, burst, lastinline = {}, 0, None
    for c in sorted(commits, key=lambda c: c["t"]):
        run = next((r for r in rr if T(r["go"] + ":00Z") <= c["t"] <= T(r["end"] + "Z")), None)
        if not run:
            if lastinline is None or c["t"] - lastinline > dt.timedelta(hours=2): burst += 1
            lastinline = c["t"]
        key = ("run", run["plan"] + run["go"]) if run else ("inline", burst)
        ch = changes.setdefault(key, {"repo": repo, "kind": key[0], "id": run["plan"] if run else c["sha"], "start": c["t"], "end": c["t"], "code": set(), "lines": 0, "subj": c["subj"], "commits": [], "isfix": True})
        ch["end"] = max(ch["end"], c["t"]); ch["start"] = min(ch["start"], c["t"]); ch["code"] |= c["code"]; ch["lines"] += c["lines"]; ch["commits"].append(c["sha"])
        ch["isfix"] &= bool(FIX.search(c["subj"]))  # an inline change that is itself a fix still counts as landed code
    owner = {}
    for c in commits:
        if not FIX.search(c["subj"]) or REVIEW.search(c["subj"]): continue
        cands = [ch for ch in changes.values() if c["sha"] not in ch["commits"] and ch["end"] < c["t"] <= ch["end"] + WEEK and c["code"] & ch["code"]]
        if cands: owner.setdefault(id(max(cands, key=lambda ch: ch["end"])), []).append(c)
    for key, ch in changes.items():
        if not ch["code"] or seen & set(ch["commits"]): continue
        seen |= set(ch["commits"])
        later = owner.get(id(ch), [])
        out.append((ch["end"].astimezone(dt.timezone.utc).isoformat()[:16], repo, ch["kind"], ch["id"], ch["lines"], len(later), " | ".join(f"{c['sha']} {c['subj'][:70]}" for c in later), ch["subj"][:70]))
w = csv.writer(open("/tmp/lean-measure/fixes.tsv", "w"), delimiter="\t")
w.writerow(["landed", "repo", "kind", "id", "lines", "fixes7d", "fix_commits", "subject"])
w.writerows(sorted(out))
