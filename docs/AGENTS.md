# AGENTS.md

## Mission

This directory contains the engineering guidance and approved design records for
`flutter_sdk_base`, a Flutter package with no native code. Contributions must
preserve the package boundary, explicit public barrels, and the single request
path described by the approved design.

## Engineering Documents

| Read this for... | File |
| --- | --- |
| Layer boundaries, the request path, adding a capability | `docs/ARCHITECTURE.md` |
| Public API, error, logging and test rules | `docs/STANDARD.md` |
| The authoritative design decisions and their rationale | `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md` |
| Branching and commit conventions | `docs/GIT_FLOW.md` |

The approved support floors are Dart `>=3.13.0 <4.0.0`, Flutter `>=3.47.0`,
Android API 24+, and iOS 15.0+. Treat them as compatibility contracts.

## Contribution Principles

- Understand the existing implementation and read the relevant document first.
- Keep host concerns, native code, UI, routing, state management, persistence,
  and mutable global state out of `lib/src/`.
- Keep consumers on the explicit public barrels; `lib/src/` is implementation
  detail and has no compatibility guarantee.
- Route requests through `SdkRequestExecutor`, preserving authentication,
  timeout, best-effort cancellation, central failure mapping, and redaction.
- Make the smallest complete change and preserve existing conventions.

## Verification

Run `make verify` and inspect the diff before presenting an implementation. Run
`make ci` and `./tool/check_boundaries.sh` for CI or release-facing changes.
