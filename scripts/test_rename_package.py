from __future__ import annotations

import hashlib
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

def git_fixture(root: Path) -> None:
    env = dict(os.environ, GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
    git = ["git", "-c", f"core.hooksPath={os.devnull}", "-c", "commit.gpgsign=false",
           "-c", "user.name=Tooling test", "-c", "user.email=tooling@example.invalid"]
    for args in (["init", "-b", "main"], ["add", "--force", "."], ["commit", "-m", "Fixture"]):
        subprocess.run([*git, *args], cwd=root, env=env, check=True, capture_output=True)


def digest(root: Path) -> str:
    value = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        if path.is_file() and ".git" not in path.relative_to(root).parts:
            value.update(path.relative_to(root).as_posix().encode())
            value.update(path.read_bytes())
    return value.hexdigest()


class TestPackageRename(unittest.TestCase):
    def fixture(self, root: Path) -> list[str]:
        (root / "tool").mkdir()
        source = Path(__file__).resolve().parents[1] / "tool/rename_package.dart"
        shutil.copy2(source, root / "tool/rename_package.dart")
        (root / "pubspec.yaml").write_text("name: flutter_sdk_base\nenvironment:\n  sdk: '>=3.13.0 <4.0.0'\ndependencies:\n  flutter:\n    sdk: flutter\n")
        (root / "lib/src").mkdir(parents=True)
        (root / "lib/src/value.dart").write_text("class Value {}\n")
        for suffix in ("", "_testing"):
            (root / f"lib/flutter_sdk_base{suffix}.dart").write_text(f"library flutter_sdk_base{suffix};\nexport 'src/value.dart' show Value;\n")
        (root / "example/lib").mkdir(parents=True)
        (root / "example/pubspec.yaml").write_text("name: example_host\ndependencies:\n  flutter_sdk_base:\n    path: ../\n")
        (root / "example/lib/main.dart").write_text("import 'package:flutter_sdk_base/flutter_sdk_base.dart';\n")
        git_fixture(root)
        return ["dart", "tool/rename_package.dart", "renamed_sdk"]

    def test_dry_run_is_read_only_and_apply_updates_host_imports(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            command = self.fixture(root)
            before = digest(root)
            preview = subprocess.run([*command, "--dry-run"], cwd=root, capture_output=True, text=True)
            self.assertEqual(preview.returncode, 0, preview.stderr)
            self.assertEqual(digest(root), before)
            result = subprocess.run(command, cwd=root, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((root / "lib/renamed_sdk.dart").is_file())
            self.assertTrue((root / "lib/renamed_sdk_testing.dart").is_file())
            self.assertFalse((root / "lib/flutter_sdk_base.dart").exists())
            self.assertIn("package:renamed_sdk/renamed_sdk.dart", (root / "example/lib/main.dart").read_text())
            self.assertIn("    sdk: flutter", (root / "pubspec.yaml").read_text())

    def test_invalid_name_fails_without_source_mutation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            command = self.fixture(root)
            before = digest(root)
            result = subprocess.run([*command[:-1], "flutter"], cwd=root, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(digest(root), before)


if __name__ == "__main__":
    unittest.main()
