#!/usr/bin/env python3
"""List Claude Code sessions as JSON for DMS Agent history."""
import json, os, glob, time, sys

action = sys.argv[1] if len(sys.argv) > 1 else "list"
_home = os.path.expanduser("~")
_project = "-" + _home.lstrip("/").replace("/", "-")
base = os.path.join(_home, ".claude", "projects", _project) + "/"

if action == "list":
    results = []
    for f in sorted(glob.glob(base + "*.jsonl"), key=os.path.getmtime, reverse=True)[:20]:
        sid = os.path.basename(f).replace(".jsonl", "")
        mtime = os.path.getmtime(f)
        title = ""
        with open(f) as fh:
            for line in fh:
                try:
                    d = json.loads(line)
                    if d.get("type") == "user" and not d.get("isMeta"):
                        content = d.get("message", {}).get("content", "")
                        if isinstance(content, str) and not content.startswith("<"):
                            title = content[:60].replace("\n", " ")
                        elif isinstance(content, list):
                            for c in content:
                                if isinstance(c, dict) and c.get("type") == "text" and not c["text"].startswith("<"):
                                    title = c["text"][:60].replace("\n", " ")
                                    break
                        if title:
                            break
                except:
                    pass
        if title:
            results.append({"id": sid, "title": title, "date": int(mtime * 1000)})
    print(json.dumps(results))

elif action == "restore":
    sid = sys.argv[2] if len(sys.argv) > 2 else ""
    session_file = base + sid + ".jsonl"
    msgs = []
    if os.path.exists(session_file):
        with open(session_file) as f:
            for line in f:
                try:
                    d = json.loads(line)
                    if d.get("type") == "user" and not d.get("isMeta"):
                        content = d.get("message", {}).get("content", "")
                        if isinstance(content, str) and not content.startswith("<"):
                            msgs.append({"role": "user", "content": content})
                        elif isinstance(content, list):
                            for c in content:
                                if isinstance(c, dict) and c.get("type") == "text" and not c["text"].startswith("<"):
                                    msgs.append({"role": "user", "content": c["text"]})
                                    break
                    elif d.get("type") == "assistant":
                        content = d.get("message", {}).get("content", [])
                        if isinstance(content, str) and content.strip():
                            msgs.append({"role": "assistant", "content": content})
                        elif isinstance(content, list):
                            for c in content:
                                if isinstance(c, dict) and c.get("type") == "text" and c["text"].strip():
                                    msgs.append({"role": "assistant", "content": c["text"]})
                                    break
                except:
                    pass
    print(json.dumps(msgs[-20:]))
