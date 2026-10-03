import json, os, sys
DIRS = ["/home/m/obsidian", "/home/m/work/kid-aid-recordings-worker", "/home/m/work/knowledge-base",
        "/home/m/projects/ernest", "/home/m/work/justom-static", "/home/m/work/kid-aid-website-2026",
        "/home/m/projects/cloud"]
bad = []
for d in DIRS:
    if not os.path.isdir(d):
        print(f"skip (missing): {d}"); continue
    p = os.path.join(d, ".claude", "settings.local.json")
    try:
        cfg = json.load(open(p))
    except (OSError, ValueError) as e:
        bad.append(f"{p}: {e}"); continue
    if cfg.get("enabledPlugins", {}).get("cloudflare@cloudflare") is not True:
        bad.append(f"{p}: cloudflare not enabled")
print("\n".join(bad) or "all present directories enabled")
sys.exit(1 if bad else 0)
