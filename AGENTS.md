# AGENTS.md

## Mission

This document defines how AI assistants and developers contribute to
`flutter_sdk_base`. Contributions must preserve the package boundary, the
explicit public barrels, the single request path, and the support policy in the
approved design.

## Engineering Documents

Read the relevant engineering document before implementing a change:

| Read this for... | File |
| --- | --- |
| Layer boundaries, the request path, adding a capability | `docs/ARCHITECTURE.md` |
| Public API, error, logging and test rules | `docs/STANDARD.md` |
| The authoritative design decisions and their rationale | `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md` |
| Branching and commit conventions | `docs/GIT_FLOW.md` |

The approved design declares Dart `>=3.13.0 <4.0.0`, Flutter `>=3.47.0`,
Android API 24+, and iOS 15.0+. Treat those floors as compatibility contracts.

## Core Engineering Principles

- Understand the existing code and relevant documents before implementing.
- Keep host concerns out of `lib/src/`; do not add UI, routing, state
  management, persistence, native code, or mutable global state.
- Keep consumers on the public barrels; `lib/src/` is implementation detail.
- Route requests through `SdkRequestExecutor` and preserve the central failure
  mapping, timeout, cancellation, authentication, and redaction guarantees.
- Prefer the smallest complete change and preserve existing conventions.

## AI Workflow

For every request:

1. Understand the requested behavior and inspect the relevant implementation.
2. Read the applicable engineering documents and approved design decisions.
3. Implement the smallest complete solution within the package boundary.
4. Run `make verify` and inspect the diff before presenting results.
5. For release or CI changes, run the corresponding `make ci` and boundary gates.

## Commands

- **Rename the package (do this first in a fresh clone):** `make rename NAME=my_company_sdk`
- **Analyze:** `make analyze` (must report 0 issues)
- **Test:** `make test`
- **Full local gate:** `make verify`
- **CI-equivalent:** `make ci`
- **Single test:** `flutter test test/path/to/test_file.dart`
