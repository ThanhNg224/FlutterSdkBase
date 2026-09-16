# GitHub Copilot Instructions for flutter_sdk_base

This is a **Flutter package with no native code** — not an application, not a
plugin. It ships an SDK that host apps depend on.

## Source of Truth

Read `docs/` before implementing. This file stays short on purpose and does not
restate the rules, so it cannot drift — if a rule changes, change it in `docs/`.

- `docs/ARCHITECTURE.md` — the barrel boundary, the single request path, how to add a capability.
- `docs/STANDARD.md` — public API, error, logging and test rules (the authoritative rulebook).
- `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md` — the approved design and the reasoning behind each decision.
- `docs/GIT_FLOW.md` — branching and commit conventions.

## Non-negotiables

These are enforced by CI, not by good intentions. Breaking one fails the build.

- `lib/src/` may import `package:flutter/foundation.dart` and nothing else from
  Flutter. No `material.dart`, `widgets.dart`, `services.dart`, no `dart:io`.
  Tests may use `dart:io`; they never ship.
- Only `lib/flutter_sdk_base.dart` and `lib/flutter_sdk_base_testing.dart` are
  public API, and they export with `show`. Everything else is `lib/src/`.
- No public signature mentions `package:http` or any other implementation type.
- Every public type is prefixed `Sdk`; every public member has a doc comment.
- No mutable static state — several `SdkClient` instances must run side by side.
- `example/` never imports `lib/src/` and never uses a relative import into the
  package.

## Verification

- Analysis: `make analyze` — must report `No issues found!`.
- Tests: `make test`.
- Layering: `make boundary`.
- Publish readiness: `make publish-check` — must report `Package has 0 warnings.`
- Local gate: `make verify`. CI-equivalent: `make ci`.

The SDK package itself has no code generation and must not gain a generator
dependency. The independent `example/` host intentionally uses Riverpod
Generator: run `make example-generate` after changing an annotated provider,
and keep the generated `example/lib/**/*.g.dart` files committed and formatted.
