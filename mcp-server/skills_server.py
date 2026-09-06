#!/usr/bin/env python3
"""MCP stdio server exposing skills as tools for Cline."""
import json
import os
import sys

# Colon-separated list of skill roots; falls back to single SKILLS_ROOT for
# backward compatibility with existing Cline MCP entries written before this change.
_roots_raw = os.environ.get("SKILLS_ROOTS", os.environ.get("SKILLS_ROOT", ""))
SKILLS_ROOTS = [r for r in _roots_raw.split(":") if r and os.path.isdir(r)]

TOOLS = [
    {
        "name": "list_skills",
        "description": "List all available skills with their one-line descriptions.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "get_skill",
        "description": "Return the full instruction text of a named skill.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "skill_name": {
                    "type": "string",
                    "description": "The skill name, e.g. code-review",
                }
            },
            "required": ["skill_name"],
        },
    },
]


def _skill_dirs():
    """Yield (skill_name, skill_md_path) for all promoted skills across all roots."""
    for root in SKILLS_ROOTS:
        for dirpath, dirs, files in os.walk(root):
            dirs.sort()
            rel = os.path.relpath(dirpath, root)
            category = rel.split(os.sep)[0] if rel != "." else ""
            if category in ("in-progress", "deprecated"):
                dirs.clear()
                continue
            if "SKILL.md" in files:
                yield os.path.basename(dirpath), os.path.join(dirpath, "SKILL.md")


def _read_description(skill_md_path):
    with open(skill_md_path, encoding="utf-8") as f:
        for line in f:
            if line.startswith("description:"):
                val = line[len("description:"):].strip()
                val = val.strip('"').strip("'")
                return val
    return ""


def _find_skill_md(skill_name):
    """Return path to SKILL.md for skill_name, or None."""
    real_roots = [os.path.realpath(r) for r in SKILLS_ROOTS]
    for name, md_path in _skill_dirs():
        if name == skill_name:
            real_md = os.path.realpath(md_path)
            if any(real_md.startswith(rr + os.sep) for rr in real_roots):
                return md_path
    return None


def _respond(msg_id, result):
    out = json.dumps({"jsonrpc": "2.0", "id": msg_id, "result": result})
    sys.stdout.write(out + "\n")
    sys.stdout.flush()


def _error(msg_id, code, message):
    out = json.dumps({"jsonrpc": "2.0", "id": msg_id, "error": {"code": code, "message": message}})
    sys.stdout.write(out + "\n")
    sys.stdout.flush()


def _text_result(text, is_error=False):
    return {"content": [{"type": "text", "text": text}], "isError": is_error}


def handle_initialize(msg_id, _params):
    _respond(msg_id, {
        "protocolVersion": "2024-11-05",
        "capabilities": {"tools": {}},
        "serverInfo": {"name": "skills", "version": "1.0.0"},
    })


def handle_tools_list(msg_id):
    _respond(msg_id, {"tools": TOOLS})


def handle_tools_call(msg_id, params):
    name = params.get("name", "")
    arguments = params.get("arguments", {})

    if name == "list_skills":
        lines = []
        for skill_name, md_path in _skill_dirs():
            desc = _read_description(md_path)
            lines.append(f"{skill_name}: {desc}" if desc else skill_name)
        _respond(msg_id, _text_result("\n".join(lines) if lines else "(no skills found)"))

    elif name == "get_skill":
        skill_name = arguments.get("skill_name", "")
        md_path = _find_skill_md(skill_name)
        if md_path is None:
            _respond(msg_id, _text_result(f"Skill '{skill_name}' not found.", is_error=True))
        else:
            with open(md_path, encoding="utf-8") as f:
                content = f.read()
            _respond(msg_id, _text_result(content))

    else:
        _error(msg_id, -32601, f"Unknown tool: {name}")


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue

        msg_id = msg.get("id")
        method = msg.get("method", "")

        if method == "initialize":
            handle_initialize(msg_id, msg.get("params", {}))
        elif method == "notifications/initialized":
            pass  # notification — no response
        elif method == "tools/list":
            handle_tools_list(msg_id)
        elif method == "tools/call":
            handle_tools_call(msg_id, msg.get("params", {}))
        else:
            if msg_id is not None:
                _error(msg_id, -32601, f"Method not found: {method}")


if __name__ == "__main__":
    main()
