# Standards

## Public API

- Every public type is prefixed `Sdk`.
- Every public member carries a doc comment (`public_member_api_docs` is on).
- Barrels export with `show`, never bare.
- Public signatures never mention transport-library, functional-programming, or
  code-generation implementation types.
- `SdkCancelToken` is the only public cancellation contract; cancellation is
  best-effort and never closes the client. `sdkVersion` is sent in
  `X-Sdk-Version`, and every request gets a lowercase hexadecimal
  `X-Request-Id`.
- `SdkConfig`, `SdkHealth`, and `SdkFailure` implement value equality. Failure
  equality excludes diagnostic `cause`, and `SdkFailure.toString()` never
  renders it.

## Errors

- Operations throw `SdkException`; nothing returns a result type.
- `StateError` is for host programming mistakes (use after close), never for
  runtime failures.
- HTTP-status `code` and `isRetryable` values come from `failureForStatus`,
  never from a capability call site. `SdkRequestExecutor` owns the central
  mappings for timeout, transport, and cancellation failures.
- `SdkFailure.toString()` never renders `cause`.

## Observability

- Silent by default. The host may inject an `SdkObserver` or get no events.
- The executor emits exactly one terminal `SdkOperationEvent` per public
  operation, including static operation name, request ID, SDK version, outcome, elapsed
  time, response status when available, and failure code/retry advice.
- Success events have null `failureCode` and `isRetryable`; failure events have
  both. Observer exceptions are swallowed.
- Events never contain or render API keys, URI/path/query, headers, bodies, raw
  exceptions, or stack traces. `SdkFailure.cause` remains only on the thrown
  failure.

## Tests

- No widget tests in the package — it ships no widgets.
- Drive capability and unit tests through `FakeSdkHttpTransport`. Use a local
  loopback integration server only to prove the default `package:http`
  transport on the wire; never depend on an external backend.
- Test `package:http` wiring with `MockClient` from `package:http/testing.dart`.
- Freeze time through the `SdkClock` seam rather than asserting on ranges.
- Assert request IDs are propagated from captured headers to every failure path,
  and assert the version header matches `sdkVersion` and `pubspec.yaml`.

## Commands

- `make verify` — format, analyze, boundary, test.
- `make ci` — the CI-equivalent local gate: `pub get`, verify, Dartdoc link
  validation, Pana, and the publish dry-run.
- `make packaged-example PLATFORM=android` — the committed-`HEAD` artifact
  consumer gate. It creates separate SDK and example snapshots with
  `git archive`, validates literal top-level `.pubignore` exclusions, rewrites
  only the staged path dependency, proves package resolution has no checkout
  path, regenerates and checks example source drift, then analyzes, tests, and
  builds the staged Android consumer. Use `PLATFORM=ios` for the corresponding
  local iOS build when the platform toolchain is available.
- `make doc` — generate API documentation with link validation and fail on
  unresolved links.
- `./tool/check_boundaries.sh` — layering rules.

## Release quality

- CI installs Pana as a global tool with `dart pub global activate pana` and
  runs `dart pub global run pana . --exit-code-threshold 0`.
- CI runs `dart doc --validate-links` before Pana so unresolved API
  documentation links fail before the package-quality gate and publish dry-run.
- The zero-deficit threshold is intentional: documentation, dependency, and
  platform metadata regressions must be fixed before publication rather than
  accepted as a lower package score. Pana is a CI tool, not a package
  dependency.
- A release is not ready on `make ci` alone. Commit the intended release files,
  run `make ci` and `make packaged-example PLATFORM=android`, then require the
  GitHub staged packaged-consumer matrix for Android and iOS. The packaged gate
  intentionally observes committed `HEAD`, not uncommitted working-tree
  changes.
