# CLAUDE.md

## Project Context

This is `flutter_sdk_base`, a Flutter package with no native code. The package
exposes a small, instance-based SDK through explicit public barrels and keeps
implementation details under `lib/src/`.

## Source of Truth

The engineering rules live in `docs/` and the approved design documents. Read
the relevant document before implementing anything, and update the owning
document when a rule changes.

| Read this for... | File |
| --- | --- |
| Layer boundaries, the request path, adding a capability | `docs/ARCHITECTURE.md` |
| Public API, error, logging and test rules | `docs/STANDARD.md` |
| The authoritative design decisions and their rationale | `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md` |
| Branching and commit conventions | `docs/GIT_FLOW.md` |

## Commands

- **Rename the package (do this first in a fresh clone):** `make rename NAME=my_company_sdk`
- **Analyze:** `make analyze` (must report 0 issues)
- **Test:** `make test`
- **Full local gate:** `make verify`
- **CI-equivalent:** `make ci`
- **Single test:** `flutter test test/path/to/test_file.dart`
