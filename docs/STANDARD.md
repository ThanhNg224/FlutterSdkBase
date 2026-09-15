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
- `code` and `isRetryable` come from `failureForStatus`, never from a call site.
- `SdkFailure.toString()` never renders `cause`.

## Logging

- Silent by default. The host injects an `SdkLogger` or gets nothing.
- `SdkConfig.apiKey` never appears verbatim in a record. Use `SdkRedaction`.
- Never log headers or bodies.

## Tests

- No widget tests in the package — it ships no widgets.
- Drive the SDK through `FakeSdkHttpTransport`, not a live server.
- Test `package:http` wiring with `MockClient` from `package:http/testing.dart`.
- Freeze time through the `SdkClock` seam rather than asserting on ranges.
- Assert request IDs are propagated from captured headers to every failure path,
  and assert the version header matches `sdkVersion` and `pubspec.yaml`.

## Commands

- `make verify` — format, analyze, boundary, test.
- `make ci` — the above plus `pub get` and the publish dry-run.
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
