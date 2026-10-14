#!/usr/bin/env python3
"""render.py <sample.tsv> <out-dir> — one readable markdown file per sampled session.

Keeps human turns and assistant prose in full; tool calls become one line, tool
results only their error flag; skill bodies and subagent hand-backs collapse to
their first line. Every turn carries its timestamp, so a reader can tell which
setup was in force. Output may hold secrets from the transcripts — keep it out
of the repo.
"""
import csv, json, os, sys

COLLAPSE = ("Base directory for this skill", "Another Claude session sent a message")
KEY_ARGS = ("command", "file_path", "pattern", "skill", "subagent_type", "description", "url", "query", "path")


def one_line(s, n):
    s = " ".join(str(s).split())
    return s if len(s) <= n else s[: n - 1] + "…"


def tool_line(b):
    inp = b.get("input") or {}
    arg = next((f"{k}={one_line(inp[k], 140)}" for k in KEY_ARGS if k in inp), "")
    return f"  → {b.get('name')} {arg}"


def render(path, out):
    lines = [f"# {os.path.basename(path)}", ""]
    for raw in open(path, encoding="utf-8", errors="replace"):
        try:
            e = json.loads(raw)
        except ValueError:
            continue
        t, ts = e.get("type"), (e.get("timestamp") or "")[:16]
        if e.get("isSidechain"):
            continue
        content = (e.get("message") or {}).get("content")
        if t == "user":
            blocks = [{"type": "text", "text": content}] if isinstance(content, str) else (content or [])
            for b in blocks:
                if not isinstance(b, dict):
                    continue
                if b.get("type") == "text" and b.get("text", "").strip():
                    text = b["text"].strip()
                    if text.startswith(COLLAPSE):
                        lines.append(f"[{ts}] (injected) {one_line(text, 200)}")
                    elif text.startswith("<") and "command-name" not in text and "Request interrupted" not in text:
                        lines.append(f"[{ts}] (meta) {one_line(text, 160)}")
                    elif len(text) > 3000:  # compaction summaries and pastes; the human part is the head
                        lines += ["", f"## USER [{ts}] (long, {len(text)} chars, head only)", text[:1500], "…", ""]
                    else:
                        lines += ["", f"## USER [{ts}]", text, ""]
                elif b.get("type") == "tool_result" and b.get("is_error"):
                    c = b.get("content")
                    c = c if isinstance(c, str) else " ".join(x.get("text", "") for x in c or [] if isinstance(x, dict))
                    lines.append(f"  ✗ tool error: {one_line(c, 200)}")
        elif t == "assistant":
            for b in content or []:
                if b.get("type") == "text" and b.get("text", "").strip():
                    lines += [f"**AGENT [{ts}]:** {b['text'].strip()}"]
                elif b.get("type") == "tool_use":
                    lines.append(tool_line(b))
        elif t == "system" and e.get("subtype") not in ("hook_started", "hook_response", None):
            lines.append(f"[{ts}] (system {e.get('subtype')}) {one_line(e.get('content', ''), 160)}")
    with open(out, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    return len(lines)


def main(sample, outdir):
    os.makedirs(outdir, exist_ok=True)
    with open(sample, encoding="utf-8") as f:
        for i, row in enumerate(csv.DictReader(f, delimiter="\t"), 1):
            sid = os.path.basename(row["path"])[:-6]
            out = os.path.join(outdir, f"{i:02d}-{row['stratum']}-{sid[:8]}.md")
            print(f"{render(row['path'], out):6d} lines  {out}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
