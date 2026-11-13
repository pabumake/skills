#!/usr/bin/env python3
"""Share installed skills with Hermes and audit its older Claude imports."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def hermes_home():
    if os.environ.get("HERMES_HOME", "").strip():
        return Path(os.path.expandvars(os.environ["HERMES_HOME"])).expanduser().resolve()
    root = (Path.home() / ".hermes").resolve()
    selector = root / "active_profile"
    profile = selector.read_text().strip() if selector.exists() else "default"
    if not profile or profile == "default":
        return root
    if not re.fullmatch(r"[A-Za-z0-9_-]+", profile):
        raise ValueError("Invalid Hermes active_profile; set HERMES_HOME explicitly")
    home = root / "profiles" / profile
    if not home.is_dir():
        raise ValueError(f"Active Hermes profile does not exist: {home}")
    return home


def expanded_path(value, home):
    path = Path(os.path.expandvars(value)).expanduser()
    return (path if path.is_absolute() else home / path).resolve()


def configure(home, shared, dry_run):
    print(f"Hermes profile: {home}", flush=True)
    if dry_run:
        # Even a config-read CLI invocation can initialize Hermes runtime files.
        print(f"  would merge {shared} into skills.external_dirs using Hermes config CLI")
        return
    env = dict(os.environ, HERMES_HOME=str(home))

    def get_settings():
        result = subprocess.run(
            ["hermes", "config", "get", "skills", "--json"],
            env=env, check=True, capture_output=True, text=True,
        )
        settings = json.loads(result.stdout)
        if not isinstance(settings, dict):
            raise ValueError("Hermes skills configuration must be a mapping")
        entries = settings.get("external_dirs", [])
        if isinstance(entries, str):
            entries = [entries]
        if not isinstance(entries, list) or any(not isinstance(e, str) for e in entries):
            raise ValueError("Hermes skills.external_dirs must contain paths")
        return entries

    entries = get_settings()
    if any(expanded_path(entry, home) == shared for entry in entries):
        print("  shared directory already configured")
        return
    subprocess.run(
        ["hermes", "config", "set", "skills.external_dirs", json.dumps(entries + [str(shared)])],
        env=env, check=True,
    )
    if not any(expanded_path(entry, home) == shared for entry in get_settings()):
        raise ValueError("Hermes did not persist the shared skill directory")
    print("  shared directory configuration verified")


def skill_name(directory):
    text = (directory / "SKILL.md").read_text()
    if text.startswith("---\n"):
        header = text.split("\n---", 1)[0]
        match = re.search(r"^name:\s*([^\n]+)", header, re.MULTILINE)
        if match:
            return match.group(1).strip().strip("\"'")
    return directory.name


def skill_directories(root, ancestors=()):
    """Follow skill links, stopping at skill roots and rejecting directory cycles."""
    if not root.is_dir():
        return
    resolved = root.resolve()
    if resolved in ancestors:
        raise ValueError(f"Skill directory cycle: {root}")
    if (root / "SKILL.md").is_file():
        yield root
        return
    for child in sorted(root.iterdir()):
        if not child.name.startswith(".") and child.name != "node_modules":
            yield from skill_directories(child, (*ancestors, resolved))


def tree_signature(root):
    """Compare every file, directory and link, including executable bits."""
    result = {}

    def visit(directory):
        for path in sorted(directory.iterdir()):
            relative = str(path.relative_to(root))
            if path.is_symlink():
                target = path.resolve()
                try:
                    result[relative] = ("internal link", str(target.relative_to(root.resolve())))
                except ValueError:
                    result[relative] = ("external link", str(target))
            elif path.is_dir():
                result[relative] = ("directory",)
                visit(path)
            elif path.is_file():
                result[relative] = (
                    "file", path.stat().st_mode & 0o111,
                    hashlib.sha256(path.read_bytes()).hexdigest(),
                )
            else:
                raise ValueError(f"Unsupported file in skill: {path}")

    visit(root)
    return result


def audit_imports(home, shared, dry_run, deduplicate):
    sources = {}
    for directory in skill_directories(shared):
        sources.setdefault(skill_name(directory), []).append(directory)
    imports = home / "skills" / "claude-code-imports"
    backup = None
    identical = differing = 0
    for local in list(skill_directories(home / "skills")):
        candidates = sources.get(skill_name(local), [])
        if not candidates:
            continue
        if len(candidates) != 1:
            print(f"  retained override: {local} (ambiguous shared name)")
            continue
        source = candidates[0]
        if local.resolve() == source.resolve():
            continue
        if tree_signature(local) != tree_signature(source):
            differing += 1
            print(f"  retained override: {local} (different content)")
            continue
        identical += 1
        # Only migrate ordinary imported directories, never another installation's links.
        eligible = imports in local.parents and not any(
            path.is_symlink() for path in [local, *local.parents]
            if path == home or home in path.parents
        )
        if not deduplicate or not eligible:
            print(f"  identical local override: {local}")
        elif dry_run:
            print(f"  would back up duplicate import: {local}")
        else:
            if backup is None:
                backup_root = home / "skill-import-backups"
                backup_root.mkdir(mode=0o700, exist_ok=True)
                backup = Path(tempfile.mkdtemp(prefix="claude-code-imports-", dir=backup_root))
            destination = backup / local.relative_to(imports)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(local), str(destination))
            print(f"  backed up duplicate: {local} -> {destination}")
    print(f"Hermes overrides: {identical} identical, {differing} differing full directories")
    if identical and not deduplicate:
        print("Use --deduplicate-hermes-imports to back up identical imports and expose shared copies.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--shared-dir", required=True)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--deduplicate-imports", action="store_true")
    args = parser.parse_args()
    home = hermes_home()
    shared = Path(args.shared_dir).expanduser().resolve()
    configure(home, shared, args.dry_run)
    audit_imports(home, shared, args.dry_run, args.deduplicate_imports)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        raise SystemExit(f"Hermes skill setup failed: {error}")
