# Agent guidance

## Source of truth

- This file defines contribution workflow and package-wide invariants.
- `docs/ARCHITECTURE.md`: layers, request path, and capability changes.
- `docs/STANDARD.md`: public API, errors, observability, and tests.
- `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md`: approved design decisions.
- `docs/GIT_FLOW.md`: branches, commits, and release flow.
- `docs/AGENTS.md`: rules for editing documentation.

Read only the document relevant to the requested change. Keep a rule in one
authoritative place and link to it elsewhere instead of copying it.

## Package invariants

- Treat Dart `>=3.13.0 <4.0.0`, Flutter `>=3.47.0`, Android API 24+, and iOS
  15.0+ as support contracts.
- Keep host UI, routing, state management, persistence, native code, and
  mutable global state out of `lib/src/`.
- Consumers use the explicit public barrels; `lib/src/` is implementation
  detail.
- Route requests through `SdkRequestExecutor`. Preserve central error mapping,
  timeout, cancellation, authentication, and safe structured events. Events
  must not contain credentials, URI/path/query, headers, bodies, raw exceptions,
  or stack traces.

## Build and verification

- Build the example for only the ABI of the device being used. The default is
  `android-arm64`; use `android-x64` only for an x86_64 emulator. Set
  `EXAMPLE_ANDROID_TARGET_PLATFORMS` when building for that emulator.
- Use `make clean` to remove generated build outputs and local project caches;
  later builds recreate them.
- For source changes, run `make verify` and inspect the diff. Run `make ci` for
  CI or release-facing changes. For documentation-only changes, verify the
  diff and affected links without running unrelated gates.
