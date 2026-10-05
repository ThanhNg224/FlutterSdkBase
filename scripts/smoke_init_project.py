#!/usr/bin/env python3
"""Check one real initializer scenario from a committed Git archive.

Default: rename/structure proof. --build adds real checks/builds in the same
throwaway clone. The source checkout, branch, index, and remote are never changed.
"""
from __future__ import annotations

import argparse
import hashlib
import os
import subprocess
import sys
import tarfile
import tempfile
from io import BytesIO
from pathlib import Path


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def run(command: list[str], root: Path, env: dict[str, str] | None = None) -> None:
    print("RUN " + " ".join(command), flush=True)
    result = subprocess.run(command, cwd=root, env=env, capture_output=True, text=True)
    if result.returncode:
        detail = result.stdout[-4000:] + result.stderr[-1000:]
        raise RuntimeError(f"Command exited {result.returncode}: {' '.join(command)}\n{detail}")


def text(root: Path, path: str) -> str:
    return (root / path).read_text(encoding="utf-8")


def tree_digest(root: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root)
        if path.is_file() and ".git" not in relative.parts:
            digest.update(relative.as_posix().encode())
            digest.update(path.read_bytes())
    return digest.hexdigest()


def archive_revision(repo: Path, revision: str, clone: Path) -> None:
    result = subprocess.run(["git", "archive", "--format=tar", revision], cwd=repo, check=True, capture_output=True)
    with tarfile.open(fileobj=BytesIO(result.stdout), mode="r:") as bundle:
        bundle.extractall(clone, filter="data")


def initialize_fixture_git(clone: Path) -> None:
    # This fixture owns its Git config and has no remote or user hooks.
    env = dict(os.environ, GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
    git = ["git", "-c", f"core.hooksPath={os.devnull}", "-c", "commit.gpgsign=false",
           "-c", "user.name=Initializer smoke", "-c", "user.email=initializer-smoke@example.invalid"]
    run([*git, "init", "-b", "main"], clone, env)
    run([*git, "add", "--force", "."], clone, env)
    run([*git, "commit", "-m", "Archive fixture"], clone, env)


def check_clone(clone: Path, build: bool) -> None:
    initialize_fixture_git(clone)
    # The rename tool imports only dart:io. Direct execution avoids pub/codegen side effects in dry-run.
    command = ["dart", "tool/rename_package.dart", "smoke_flutter_sdk"]
    before = tree_digest(clone)
    run([*command, "--dry-run"], clone)
    require(tree_digest(clone) == before, "Dry-run changed archived source files")
    run(command, clone)
    require("name: smoke_flutter_sdk" in text(clone, "pubspec.yaml"), "Package name is stale")
    for suffix in ("", "_testing"):
        require((clone / f"lib/smoke_flutter_sdk{suffix}.dart").is_file(), "Renamed public barrel is missing")
        require(not (clone / f"lib/flutter_sdk_base{suffix}.dart").exists(), "Old public barrel remains")
    require("smoke_flutter_sdk:" in text(clone, "example/pubspec.yaml"), "Example dependency is stale")
    for folder in ("lib", "test", "example/lib"):
        for path in (clone / folder).rglob("*.dart"):
            require("package:flutter_sdk_base/" not in path.read_text(), f"Old import in {path.relative_to(clone)}")
    run(["sh", "tool/check_boundaries.sh"], clone)
    if build:
        run(["flutter", "pub", "get"], clone)
        run(["make", "verify"], clone)
        run(["make", "example-build", "EXAMPLE_ANDROID_TARGET_PLATFORMS=android-arm64"], clone)
        require((clone / "example/build/app/outputs/flutter-apk/app-debug.apk").is_file(), "Example debug APK is missing")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--revision", default="HEAD")
    parser.add_argument("--build", action="store_true", help="Also verify/build the initialized temporary clone")
    args = parser.parse_args()
    try:
        with tempfile.TemporaryDirectory(prefix="fluttersdkbase-init-smoke-") as temp:
            clone = Path(temp)
            archive_revision(args.repo.resolve(), args.revision, clone)
            check_clone(clone, args.build)
    except (OSError, RuntimeError, subprocess.CalledProcessError, tarfile.TarError) as error:
        print(f"FAIL initializer smoke: {error}", file=sys.stderr)
        return 1
    print("PASS archive initializer: rename" + (" + build/check" if args.build else " only (build skipped)"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
