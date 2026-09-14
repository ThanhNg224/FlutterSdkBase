# Standards

## Public API

- Every public type is prefixed `Sdk`.
- Every public member carries a doc comment (`public_member_api_docs` is on).
- Barrels export with `show`, never bare.
- Public signatures never mention transport-library, functional-programming, or
  code-generation implementation types.

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

## Commands

- `make verify` — format, analyze, boundary, test.
- `make ci` — the above plus `pub get` and the publish dry-run.
- `./tool/check_boundaries.sh` — layering rules.
