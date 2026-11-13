"""Isolated tests for tool detection, Hermes configuration, and import migration."""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
HELPER = REPO / "scripts/configure-hermes-skills.py"
spec = importlib.util.spec_from_file_location("hermes_skills", HELPER)
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)

HERMES_STUB = '''
import json, os, sys
from pathlib import Path
home = Path(os.environ["HERMES_HOME"])
home.mkdir(parents=True, exist_ok=True)
path = home / "config-test.json"
config = json.loads(path.read_text()) if path.exists() else {"skills": {}, "model": "keep"}
with (home / "cli-calls").open("a") as log:
    log.write(" ".join(sys.argv[1:]) + "\\n")
if sys.argv[1:4] == ["config", "get", "skills"]:
    print(json.dumps(config["skills"]))
elif sys.argv[1:4] == ["config", "set", "skills.external_dirs"]:
    config["skills"]["external_dirs"] = json.loads(sys.argv[4])
    path.write_text(json.dumps(config))
else:
    sys.exit(2)
'''


def skill(path, body="body", support="reference"):
    path.mkdir(parents=True)
    (path / "SKILL.md").write_text(f"---\nname: {path.name}\ndescription: Test skill\n---\n{body}\n")
    (path / "reference.txt").write_text(support)


def snapshot(path):
    return helper.tree_signature(path)


class SkillSetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="skills-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.home = self.root / "home"
        self.home.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for tool in ["bash", "basename", "dirname", "find", "sort", "sed", "head", "readlink", "rm", "mkdir", "ln"]:
            (self.bin / tool).symlink_to(shutil.which(tool))
        (self.bin / "python3").symlink_to(sys.executable)
        self.env = {key: value for key, value in os.environ.items() if not key.startswith(
            ("HERMES_", "OPENCODE_", "CLAUDE_", "CODEX_", "AGENT_", "XDG_", "CLINE_")
        )}
        self.env.update(HOME=str(self.home), PATH=str(self.bin), PYTHONDONTWRITEBYTECODE="1")
        self.shared = self.home / ".agents/skills"
        self.profile = self.home / ".hermes"

    def executable(self, name, text):
        path = self.bin / name
        path.write_text(f"#!{sys.executable}\n" + text)
        path.chmod(0o755)

    def run_helper(self, *args):
        return subprocess.run([sys.executable, "-B", str(HELPER), "--shared-dir", str(self.shared), *args],
                              env=self.env, text=True, capture_output=True, check=True).stdout

    def fixture_installer(self):
        repo = self.root / "repo"
        repo.mkdir()
        shutil.copy(REPO / "install.sh", repo / "install.sh")
        shutil.copytree(REPO / "scripts", repo / "scripts")
        skill(repo / "skills/general/example")
        external = repo / "skills/general/pbmk-skill-install/scripts/install-mattpocock.sh"
        external.parent.mkdir(parents=True)
        external.write_text('''#!/bin/bash
printf '%s\\n' "$@" > "$HOME/external-targets"
mkdir -p "${AGENT_SKILLS_DIR:-$HOME/.agents/skills}/baseline"
printf -- '---\\nname: baseline\\ndescription: Baseline\\n---\\n' > "${AGENT_SKILLS_DIR:-$HOME/.agents/skills}/baseline/SKILL.md"
''')
        external.chmod(0o755)
        return repo / "install.sh"

    def test_installed_tool_matrix(self):
        installer = self.fixture_installer()
        for tools in [(), ("opencode",), ("hermes",), ("opencode", "hermes")]:
            with self.subTest(tools=tools):
                for name in ["opencode", "hermes"]:
                    (self.bin / name).unlink(missing_ok=True)
                for name in tools:
                    self.executable(name, HERMES_STUB if name == "hermes" else "pass\n")
                shutil.rmtree(self.home)
                self.home.mkdir()
                result = subprocess.run(["/bin/bash", str(installer)], env=self.env,
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual((self.shared / "example/SKILL.md").is_file(), bool(tools))
                self.assertEqual((self.shared / "baseline/SKILL.md").is_file(), bool(tools))
                self.assertEqual((self.profile / "config-test.json").exists(), "hermes" in tools)
                if "hermes" in tools:
                    self.assertIn("codex", (self.home / "external-targets").read_text())

    def test_dry_run_preserves_home_and_never_invokes_hermes(self):
        installer = self.fixture_installer()
        self.executable("hermes", HERMES_STUB)
        self.shared.mkdir(parents=True)
        (self.shared / "retired").symlink_to(installer.parent / "skills/deprecated/retired")
        before = snapshot(self.home)
        result = subprocess.run(["/bin/bash", str(installer), "--dry-run"], env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(before, snapshot(self.home))
        self.assertIn("would merge", result.stdout)

    def test_config_merge_is_idempotent_and_preserves_settings(self):
        self.executable("hermes", HERMES_STUB)
        self.profile.mkdir()
        config = self.profile / "config-test.json"
        config.write_text(json.dumps({"skills": {"external_dirs": ["~/team"], "disabled": ["old"]}, "model": "keep"}))
        self.run_helper()
        first = config.read_bytes()
        self.run_helper()
        self.assertEqual(first, config.read_bytes())
        data = json.loads(first)
        self.assertEqual(data["skills"]["external_dirs"], ["~/team", str(self.shared)])
        self.assertEqual(data["skills"]["disabled"], ["old"])
        self.assertEqual(data["model"], "keep")
        self.assertEqual((self.profile / "cli-calls").read_text().count("config set"), 1)

    def test_custom_home_and_active_profile(self):
        self.executable("hermes", HERMES_STUB)
        self.profile.mkdir()
        (self.profile / "active_profile").write_text("work")
        work = self.profile / "profiles/work"
        work.mkdir(parents=True)
        self.run_helper()
        self.assertTrue((work / "config-test.json").exists())
        self.assertFalse((self.profile / "config-test.json").exists())
        custom = self.root / "custom-profile"
        self.env["HERMES_HOME"] = str(custom)
        self.run_helper()
        self.assertTrue((custom / "config-test.json").exists())

    def test_equivalent_existing_path_is_not_added_twice(self):
        self.executable("hermes", HERMES_STUB)
        self.profile.mkdir()
        config = self.profile / "config-test.json"
        config.write_text(json.dumps({"skills": {"external_dirs": "~/.agents/skills"}}))
        self.run_helper()
        self.assertNotIn("config set", (self.profile / "cli-calls").read_text())

    def test_full_tree_deduplication_preserves_modified_support_files(self):
        self.executable("hermes", HERMES_STUB)
        imports = self.profile / "skills/claude-code-imports"
        for name in ["same", "modified", "executable", "external-link"]:
            skill(self.shared / name)
            skill(imports / name)
        (imports / "modified/reference.txt").write_text("local change")
        (imports / "executable/reference.txt").chmod(0o755)
        # Equal relative link text can refer to different files outside the skill.
        (self.shared / "external-link/link.txt").symlink_to("../outside.txt")
        (imports / "external-link/link.txt").symlink_to("../outside.txt")
        (self.shared / "outside.txt").write_text("shared dependency")
        (imports / "outside.txt").write_text("local dependency")
        self.run_helper()  # An ordinary install reports overrides only.
        self.assertTrue((imports / "same").is_dir())
        before = snapshot(self.home)
        self.run_helper("--dry-run", "--deduplicate-imports")
        self.assertEqual(before, snapshot(self.home))
        output = self.run_helper("--deduplicate-imports")
        self.assertFalse((imports / "same").exists())
        self.assertTrue((imports / "modified").is_dir())
        self.assertTrue((imports / "executable").is_dir())
        self.assertTrue((imports / "external-link").is_dir())
        backups = list((self.profile / "skill-import-backups").glob("*/same"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(snapshot(backups[0]), snapshot(self.shared / "same"))
        self.assertIn("3 differing", output)

    def test_custom_shared_path_gets_opencode_native_links(self):
        installer = self.fixture_installer()
        self.executable("opencode", "pass\n")
        custom = self.root / "shared skills"
        native = self.root / "opencode-config"
        self.env.update(AGENT_SKILLS_DIR=str(custom), OPENCODE_CONFIG_DIR=str(native))
        result = subprocess.run(["/bin/bash", str(installer)], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((custom / "example/SKILL.md").is_file())
        self.assertTrue((native / "skills/example/SKILL.md").is_file())


if __name__ == "__main__":
    unittest.main()
