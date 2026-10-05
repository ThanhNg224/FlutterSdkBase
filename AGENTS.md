# Engineering Guidelines

A Flutter SDK package with an independent example host. Its public API and error/security contracts live in [Architecture](docs/ARCHITECTURE.md) and [Standards](docs/STANDARD.md).

## Workflow

- Read only the owning documents relevant to the task, then inspect current implementation, callers, and existing tests.
- Make the smallest complete change. Add infrastructure or abstractions only for a concrete requirement or failure mode.
- Work in the current branch and checkout. Do not create a branch or worktree unless explicitly requested; preserve other contributors' edits.
- Ask when unresolved intent or a tradeoff changes the work. Continue independent work while waiting.
- Handle small and tightly coupled changes directly. Delegate only when independent tracks reduce total effort; use a reviewer for high-risk changes or when requested.
- Use the smallest level in [Verification](docs/VERIFICATION.md). Test behavior, state, persistence, security, and concurrency when affected; do not add tests that merely mirror layout or styling.
- Report exact commands and results. Keep local checks, archive checks, builds, remote CI, and device evidence distinct.
- Keep rules in their owning documents and link elsewhere. Preserve active plans and decision records; keep handoff plans local under `docs/plans/` and delete them when completed.
- Follow [Git workflow](docs/GIT_FLOW.md). Do not commit, push, tag, publish, or deploy unless explicitly requested.

## Documents

- [Architecture](docs/ARCHITECTURE.md): ownership, dependencies, and data flow.
- [Verification](docs/VERIFICATION.md): risk levels, commands, side effects, and proof boundaries.
- [Git workflow](docs/GIT_FLOW.md): existing branch, commit, and release conventions.
- [Standards](docs/STANDARD.md): coding, API, error, and security contracts.
- [Documentation rules](docs/AGENTS.md): edits under `docs/`.

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

## Example builds

Build the example for the device ABI only: default `android-arm64`, or
`EXAMPLE_ANDROID_TARGET_PLATFORMS=android-x64` for an x86_64 emulator.
Packaged-consumer gates retain their separate existing build profiles.
