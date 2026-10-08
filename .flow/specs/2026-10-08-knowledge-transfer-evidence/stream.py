"""stream.py — read `claude -p --output-format stream-json --verbose` transcripts.

  python3 -I stream.py agent-results <subagent_type> <jsonl>...
  python3 -I stream.py subagent-tools <jsonl>...

Key spellings are the ones recorded in stream-format.md.
"""
import json
import sys

HANDBACK_TOOL = "SubagentHandback"  # harness-injected, not a tool the subagent chose


def events(path):
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                yield json.loads(line)
            except ValueError:
                continue


def blocks(event):
    message = event.get("message")
    content = message.get("content") if isinstance(message, dict) else None
    return content if isinstance(content, list) else []


def result_text(content):
    if isinstance(content, str):
        return content
    return "\n".join(b.get("text", "") for b in content or [] if b.get("type") == "text")


def agent_results(subagent_type, paths):
    for path in paths:
        dispatches, results, handbacks = [], {}, {}
        for ev in events(path):
            for b in blocks(ev):
                if b.get("type") == "tool_use" and b.get("name") == "Agent" \
                        and (b.get("input") or {}).get("subagent_type") == subagent_type:
                    dispatches.append(b["id"])
                elif b.get("type") == "tool_result":
                    results[b.get("tool_use_id")] = b
            if ev.get("type") == "system" and ev.get("subtype") == "task_notification" \
                    and isinstance(ev.get("handback_report"), dict):
                handbacks[ev.get("tool_use_id")] = ev["handback_report"].get("text", "")
        for tid in dispatches:
            if tid not in results:
                out = {"is_error": True, "text": "NO RESULT"}
            else:
                r = results[tid]
                text = handbacks[tid] if tid in handbacks else result_text(r.get("content"))
                out = {"is_error": bool(r.get("is_error", False)), "text": text}
            print(json.dumps(out, ensure_ascii=False))


def subagent_tools(paths):
    for path in paths:
        for ev in events(path):
            if ev.get("type") != "assistant" or not ev.get("parent_tool_use_id"):
                continue
            for b in blocks(ev):
                if b.get("type") == "tool_use" and b.get("name") != HANDBACK_TOOL:
                    print(b.get("name"))


def main(argv):
    if len(argv) >= 4 and argv[1] == "agent-results":
        agent_results(argv[2], argv[3:])
    elif len(argv) >= 3 and argv[1] == "subagent-tools":
        subagent_tools(argv[2:])
    else:
        sys.exit("usage: stream.py agent-results <subagent_type> <jsonl>... | subagent-tools <jsonl>...")


if __name__ == "__main__":
    main(sys.argv)
