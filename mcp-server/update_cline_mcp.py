#!/usr/bin/env python3
"""Atomically merge a skills MCP server entry into a Cline settings file."""
import json
import os
import sys


def main():
    if len(sys.argv) != 5:
        print("usage: update_cline_mcp.py <settings_file> <server_name> <skills_root> <server_script>", file=sys.stderr)
        sys.exit(1)

    settings_file, server_name, skills_root, server_script = sys.argv[1:]

    try:
        with open(settings_file, encoding="utf-8") as f:
            data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        data = {}

    if not isinstance(data.get("mcpServers"), dict):
        data["mcpServers"] = {}

    entry = {
        "command": "python3",
        "args": [server_script],
        "env": {"SKILLS_ROOT": skills_root},
    }

    existing = data["mcpServers"].get(server_name)
    if existing == entry:
        print(f"unchanged: {server_name}")
        return

    action = "updated" if server_name in data["mcpServers"] else "linked"
    data["mcpServers"][server_name] = entry

    tmp = settings_file + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, settings_file)

    print(f"{action}: {server_name}")


if __name__ == "__main__":
    main()
