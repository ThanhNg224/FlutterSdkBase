# Flutter SDK Base Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn this clone of Flutter Core Base into `flutter_sdk_base` — a publishable Flutter package, with no native code, that exposes one instance-based HTTP capability behind an SDK-owned public contract.

**Architecture:** A single package whose entire implementation lives under `lib/src/` and reaches consumers through two barrels. `SdkClient` composes a config, a transport, and a logger, and owns their lifecycle. Every network call runs through one internal executor that applies auth, timeout, cancellation, and a single error-mapping table, so no call site invents its own behaviour. The reference `health` slice exists only to exercise that path end to end.

**Tech Stack:** Flutter 3.47 / Dart 3.13, `package:http` (internal only), `package:meta`, `flutter_test`, no code generation, no Riverpod, no Freezed, no Dio.

**Authoritative spec:** `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md`. Where this plan and the spec disagree, the spec wins — stop and report the conflict rather than guessing.

## Global Constraints

Every task inherits these. They are not repeated per task.

- Package name `flutter_sdk_base`; version `0.1.0` (no `+build` suffix).
- Dart `>=3.13.0 <4.0.0`; Flutter `>=3.47.0` — **no upper bound on Flutter**, pub deprecates it and warns.
- Android floor API 24; iOS floor 15.0. Both are **derived** from Flutter 3.47, never hand-picked.
- Supported release platforms: Android and iOS. Web and desktop are untested and unsupported.
- Every public type name is prefixed `Sdk`.
- `lib/src/` may import `package:flutter/foundation.dart`. It must **never** import `package:flutter/material.dart`, `package:flutter/widgets.dart`, or `package:flutter/services.dart`.
- `lib/` must never import `dart:io`. Tests may.
- No public signature may mention `package:http`, Dio, or `fpdart` types.
- Public operations return their value and throw `SdkException`. Never a mix of result types and throws.
- Use-after-`close()` throws `StateError`, not `SdkException`.
- Cancellation is best-effort: the SDK stops waiting; the socket may live on.
- The SDK never retries automatically.
- `SdkConfig.apiKey` must never appear verbatim in anything handed to an `SdkLogger`.
- No mutable static state anywhere in `lib/`. Multiple `SdkClient` instances must work concurrently.
- Formatter: `page_width: 120`, `trailing_commas: preserve`.
- Analyzer must stay at zero issues under `flutter analyze --fatal-infos`.

---

### Task 1: Strip the application and establish the package baseline

Everything that follows assumes an empty, analyzable package. Doing this first means later tasks never fight leftover Riverpod/Freezed generated code.

**Files:**
- Delete: `lib/main.dart`, `lib/app/`, `lib/features/`, `lib/l10n/`, `lib/core/`, `l10n.yaml`
- Delete: `android/`, `ios/`, `macos/`, `windows/`, `web/`, `assets/`, `scripts/`, `py/`, `tools/`
- Delete: `test/` (entire tree — it tests deleted code)
- Delete: `.github/workflows/build_and_deploy_web_production.yml`, `.github/workflows/build_and_deploy_web_staging.yml`, `.github/workflows/build_web.yml`
- Modify: `pubspec.yaml`, `analysis_options.yaml`, `Makefile`, `.gitignore`
- Create: `CHANGELOG.md`

- [ ] **Step 1: Delete every application artifact**

```bash
cd /Users/thanhng224/Dev/Personal/GitHub/FlutterSdkBase
git rm -r --quiet lib/main.dart lib/app lib/features lib/l10n lib/core l10n.yaml
git rm -r --quiet android ios macos windows web assets scripts py tools test
git rm -r --quiet .github/workflows/build_and_deploy_web_production.yml \
  .github/workflows/build_and_deploy_web_staging.yml \
  .github/workflows/build_web.yml
rm -rf .dart_tool build .flutter-plugins-dependencies
```

- [ ] **Step 2: Replace `pubspec.yaml` entirely**

`publish_to: none` is deliberately absent — `pub publish --dry-run` refuses to run on a package that declares it, and that gate must work from commit one.

```yaml
name: flutter_sdk_base
description: "A template for building a Flutter SDK package with no native code: instance-based client, injectable HTTP transport, typed failures, and safe logging."
version: 0.1.0
homepage: https://github.com/ThanhNg224/FlutterSdkBase
repository: https://github.com/ThanhNg224/FlutterSdkBase
issue_tracker: https://github.com/ThanhNg224/FlutterSdkBase/issues

environment:
  sdk: ">=3.13.0 <4.0.0"
  flutter: ">=3.47.0"

dependencies:
  flutter:
    sdk: flutter
  http: ^1.0.0
  meta: ^1.16.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: false
```

- [ ] **Step 3: Replace `analysis_options.yaml`**

`implementation_imports` is deliberately NOT here — it fires at the import site, so it belongs to `example/` (Task 11).

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  exclude:
    - example/**

formatter:
  trailing_commas: preserve
  page_width: 120

linter:
  rules:
    - always_declare_return_types
    - always_use_package_imports
    - prefer_single_quotes
    - public_member_api_docs
```

- [ ] **Step 4: Replace `Makefile`**

```makefile
SHELL := /bin/sh

FLUTTER ?= flutter
DART ?= dart

.DEFAULT_GOAL := help

.PHONY: help pub-get format format-check analyze test verify boundary publish-check ci

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

pub-get: ## Resolve package dependencies
	$(FLUTTER) pub get

format: ## Format all Dart files
	$(DART) format .

format-check: ## Verify formatting without changing files
	$(DART) format --output=none --set-exit-if-changed .

analyze: ## Run static analysis with infos treated as errors
	$(FLUTTER) analyze --fatal-infos

test: ## Run the package test suite
	$(FLUTTER) test

boundary: ## Fail if lib/src reaches into Flutter UI or dart:io
	@! grep -rn "package:flutter/material.dart\|package:flutter/widgets.dart\|package:flutter/services.dart\|dart:io" lib/ \
	  || (echo "BOUNDARY VIOLATION in lib/"; exit 1)
	@echo "boundary ok"

publish-check: ## Verify the package would publish cleanly
	$(FLUTTER) pub publish --dry-run

verify: format-check analyze boundary test ## Local pre-commit gate

ci: pub-get verify publish-check ## CI-equivalent local gate
```

- [ ] **Step 5: Create `CHANGELOG.md` and `.pubignore`**

`CHANGELOG.md`:

```markdown
# Changelog

## 0.1.0 (unreleased)

Initial package skeleton. No public API yet.
```

`.pubignore` — `docs/` holds the spec, the plan, and internal notes. None of it
belongs in the published archive. Excluding it also clears pub's "rename `docs`
to `doc`" warning, but that is a side effect, not the reason.

```text
docs/
tool/
.github/
```

- [ ] **Step 6: Verify the empty package is clean**

```bash
flutter pub get && flutter analyze --fatal-infos && flutter pub publish --dry-run
```

Expected: `pub get` resolves; analyze reports `No issues found!`; dry-run ends with
`Package has 0 warnings.`

Zero warnings is reachable and was verified empirically on Flutter 3.47.2. It
depends on exactly three things, all already in place by this step:

1. `.pubignore` excludes `docs/`.
2. The Flutter constraint has **no** upper bound (`>=3.47.0`). Pub deprecates
   Flutter upper bounds and warns on them.
3. No stale platform or build output remains — Step 1 removed `android/`, `ios/`,
   `macos/`, `windows/`, `web/`, `build/`, and `.dart_tool/`.

If a warning survives, it is a defect in this task, not a gate to relax: re-check
those three before anything else. A warning about a missing `lib/` entrypoint is
the one acceptable exception at this step — Task 10 adds the barrels.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "chore: strip application concerns and establish package baseline

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Error contract

**Files:**
- Create: `lib/src/errors/sdk_error_codes.dart`, `lib/src/errors/sdk_failure.dart`, `lib/src/errors/sdk_exception.dart`, `lib/src/errors/sdk_status_mapping.dart`
- Test: `test/errors/sdk_failure_test.dart`, `test/errors/sdk_status_mapping_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `SdkErrorCodes` (const String members `cancelled`, `timeout`, `transport`, `unauthorized`, `client`, `rateLimited`, `server`, `invalidResponse`); `SdkFailure({required String code, required String message, required bool isRetryable, int? statusCode, Object? cause})`; `SdkException(SdkFailure failure)` with field `failure`; `SdkFailure failureForStatus(int statusCode, {String? message})`.

- [ ] **Step 1: Write the failing tests**

`test/errors/sdk_failure_test.dart`:

```dart
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/errors/sdk_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SdkFailure', () {
    test('toString renders code, status and message', () {
      const failure = SdkFailure(
        code: SdkErrorCodes.server,
        message: 'Upstream unavailable.',
        isRetryable: true,
        statusCode: 503,
      );

      expect(failure.toString(), 'SdkFailure(server, status: 503): Upstream unavailable.');
    });

    test('toString never leaks cause', () {
      const failure = SdkFailure(
        code: SdkErrorCodes.transport,
        message: 'Transport failure.',
        isRetryable: true,
        cause: 'https://api.example.com?token=SUPERSECRET',
      );

      expect(failure.toString(), isNot(contains('SUPERSECRET')));
    });

    test('SdkException exposes its failure and renders it', () {
      const failure = SdkFailure(
        code: SdkErrorCodes.timeout,
        message: 'Timed out.',
        isRetryable: true,
      );
      const exception = SdkException(failure);

      expect(exception.failure, same(failure));
      expect(exception.toString(), contains('timeout'));
    });
  });
}
```

`test/errors/sdk_status_mapping_test.dart`:

```dart
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_status_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('failureForStatus', () {
    test('401 and 403 map to unauthorized and are not retryable', () {
      for (final status in <int>[401, 403]) {
        final failure = failureForStatus(status);
        expect(failure.code, SdkErrorCodes.unauthorized, reason: 'status $status');
        expect(failure.isRetryable, isFalse, reason: 'status $status');
        expect(failure.statusCode, status);
      }
    });

    test('429 maps to rateLimited and is retryable', () {
      final failure = failureForStatus(429);
      expect(failure.code, SdkErrorCodes.rateLimited);
      expect(failure.isRetryable, isTrue);
    });

    test('other 4xx map to client and are not retryable', () {
      for (final status in <int>[400, 404, 409, 422]) {
        final failure = failureForStatus(status);
        expect(failure.code, SdkErrorCodes.client, reason: 'status $status');
        expect(failure.isRetryable, isFalse, reason: 'status $status');
      }
    });

    test('5xx map to server and are retryable', () {
      for (final status in <int>[500, 502, 503]) {
        final failure = failureForStatus(status);
        expect(failure.code, SdkErrorCodes.server, reason: 'status $status');
        expect(failure.isRetryable, isTrue, reason: 'status $status');
      }
    });

    test('a supplied message replaces the default', () {
      final failure = failureForStatus(404, message: 'No such dataset.');
      expect(failure.message, 'No such dataset.');
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/errors/
```

Expected: FAIL — `Target of URI doesn't exist: 'package:flutter_sdk_base/src/errors/sdk_failure.dart'`.

- [ ] **Step 3: Implement the error contract**

`lib/src/errors/sdk_error_codes.dart`:

```dart
/// Stable identifiers carried by [SdkFailure.code].
///
/// Adding a code is a non-breaking change. Changing or removing one is
/// breaking, because hosts branch on these values.
abstract final class SdkErrorCodes {
  /// The operation was cancelled because its client was closed.
  static const String cancelled = 'cancelled';

  /// The operation exceeded `SdkConfig.requestTimeout`.
  static const String timeout = 'timeout';

  /// The request never produced an HTTP response.
  static const String transport = 'transport';

  /// The API rejected the credential (HTTP 401 or 403).
  static const String unauthorized = 'unauthorized';

  /// The request was rejected as invalid (HTTP 4xx other than 401/403/429).
  static const String client = 'client';

  /// The API applied rate limiting (HTTP 429).
  static const String rateLimited = 'rate_limited';

  /// The API failed to serve the request (HTTP 5xx).
  static const String server = 'server';

  /// A successful response carried a body the SDK could not parse.
  static const String invalidResponse = 'invalid_response';
}
```

`lib/src/errors/sdk_failure.dart`:

```dart
/// A structured description of why an SDK operation did not succeed.
///
/// Hosts branch on [code] and map it to their own user-facing copy. [message]
/// is English diagnostic text for developers and is never localized.
final class SdkFailure {
  /// Creates a failure.
  const SdkFailure({
    required this.code,
    required this.message,
    required this.isRetryable,
    this.statusCode,
    this.cause,
  });

  /// A stable identifier drawn from `SdkErrorCodes`.
  final String code;

  /// English diagnostic text for developers. Not for end-user UI.
  final String message;

  /// Whether retrying the same operation could plausibly succeed.
  ///
  /// Advice only — the SDK never retries on its own.
  final bool isRetryable;

  /// The HTTP status that produced this failure, when there was one.
  final int? statusCode;

  /// The underlying error, for diagnostics only.
  ///
  /// Its type and contents carry no compatibility guarantee. Never branch on
  /// it, and never render it to an end user.
  final Object? cause;

  @override
  String toString() => 'SdkFailure($code, status: $statusCode): $message';
}
```

`lib/src/errors/sdk_exception.dart`:

```dart
import 'package:flutter_sdk_base/src/errors/sdk_failure.dart';

/// The exception every public SDK operation throws on an expected failure.
///
/// Programming mistakes — such as using a client after `close()` — throw
/// [StateError] instead, so they surface during development rather than
/// hiding inside a host's error branch.
final class SdkException implements Exception {
  /// Wraps [failure].
  const SdkException(this.failure);

  /// What went wrong.
  final SdkFailure failure;

  @override
  String toString() => 'SdkException: $failure';
}
```

`lib/src/errors/sdk_status_mapping.dart`:

```dart
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_failure.dart';

/// Maps a non-success HTTP status onto the single failure table defined by the
/// design spec, so no call site decides `code` or `isRetryable` on its own.
SdkFailure failureForStatus(int statusCode, {String? message}) {
  final (String code, bool isRetryable, String defaultMessage) = switch (statusCode) {
    401 || 403 => (SdkErrorCodes.unauthorized, false, 'The API rejected the supplied credential.'),
    429 => (SdkErrorCodes.rateLimited, true, 'The API applied rate limiting.'),
    >= 400 && < 500 => (SdkErrorCodes.client, false, 'The API rejected the request as invalid.'),
    _ => (SdkErrorCodes.server, true, 'The API failed to serve the request.'),
  };

  return SdkFailure(
    code: code,
    message: message ?? defaultMessage,
    isRetryable: isRetryable,
    statusCode: statusCode,
  );
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/errors/ && flutter analyze --fatal-infos
```

Expected: all tests pass; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/src/errors test/errors
git commit -m "feat(errors): add SdkFailure, SdkException and the status mapping table

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Logging contract and redaction

**Files:**
- Create: `lib/src/logging/sdk_log_level.dart`, `lib/src/logging/sdk_logger.dart`, `lib/src/logging/silent_sdk_logger.dart`, `lib/src/logging/sdk_redaction.dart`
- Test: `test/logging/sdk_redaction_test.dart`, `test/logging/silent_sdk_logger_test.dart`
- Create: `test/support/recording_sdk_logger.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `enum SdkLogLevel { debug, info, warn, error }`; `abstract interface class SdkLogger { void log(SdkLogLevel level, String message, {Object? error, StackTrace? stackTrace}) }`; `const SilentSdkLogger()`; `SdkRedaction.secret(String?, {int visible})`. Test helper `RecordingSdkLogger` with `List<String> lines` and `String get combined`.

- [ ] **Step 1: Write the failing tests**

`test/logging/sdk_redaction_test.dart`:

```dart
import 'package:flutter_sdk_base/src/logging/sdk_redaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SdkRedaction.secret', () {
    test('keeps only the first and last four characters of a long value', () {
      expect(SdkRedaction.secret('abcdefghijklmnop'), 'abcd…mnop');
    });

    test('fully masks a value too short to reveal safely', () {
      expect(SdkRedaction.secret('abcdefgh'), '********');
      expect(SdkRedaction.secret('abc'), '***');
    });

    test('renders a null value as an explicit marker', () {
      expect(SdkRedaction.secret(null), '(none)');
    });

    test('never returns the input verbatim for a realistic key', () {
      const key = 'key';
      expect(SdkRedaction.secret(key), isNot(contains('5f2b9c7e')));
    });
  });
}
```

`test/logging/silent_sdk_logger_test.dart`:

```dart
import 'package:flutter_sdk_base/src/logging/sdk_log_level.dart';
import 'package:flutter_sdk_base/src/logging/silent_sdk_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SilentSdkLogger accepts every level without emitting or throwing', () {
    const logger = SilentSdkLogger();

    for (final level in SdkLogLevel.values) {
      expect(() => logger.log(level, 'anything', error: Exception('x')), returnsNormally);
    }
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/logging/
```

Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Implement logging**

`lib/src/logging/sdk_log_level.dart`:

```dart
/// Severity of a record handed to an `SdkLogger`.
enum SdkLogLevel {
  /// Routine detail useful while integrating.
  debug,

  /// A notable but expected event.
  info,

  /// Something the host probably wants to investigate.
  warn,

  /// An operation failed.
  error,
}
```

`lib/src/logging/sdk_logger.dart`:

```dart
import 'package:flutter_sdk_base/src/logging/sdk_log_level.dart';

/// Receives diagnostic records from the SDK.
///
/// The SDK redacts credentials and omits headers and bodies before calling
/// this, so an implementation may forward records anywhere the host wants.
abstract interface class SdkLogger {
  /// Handles one record.
  void log(
    SdkLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}
```

`lib/src/logging/silent_sdk_logger.dart`:

```dart
import 'package:flutter_sdk_base/src/logging/sdk_log_level.dart';
import 'package:flutter_sdk_base/src/logging/sdk_logger.dart';

/// The default logger: discards every record.
///
/// An SDK must be silent unless its host asks for output.
final class SilentSdkLogger implements SdkLogger {
  /// Creates the silent logger.
  const SilentSdkLogger();

  @override
  void log(
    SdkLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
```

`lib/src/logging/sdk_redaction.dart`:

```dart
/// Masking helpers applied before any value reaches an `SdkLogger`.
///
/// Internal: never exported from a public barrel.
abstract final class SdkRedaction {
  /// Rendered in place of a null value.
  static const String absentMarker = '(none)';

  /// Masks a credential, keeping [visible] characters at each end.
  ///
  /// A value short enough that the retained characters would reveal most of it
  /// is masked completely.
  static String secret(String? value, {int visible = 4}) {
    if (value == null) {
      return absentMarker;
    }
    if (value.length <= visible * 2) {
      return '*' * value.length;
    }
    return '${value.substring(0, visible)}…${value.substring(value.length - visible)}';
  }
}
```

`test/support/recording_sdk_logger.dart`:

```dart
import 'package:flutter_sdk_base/src/logging/sdk_log_level.dart';
import 'package:flutter_sdk_base/src/logging/sdk_logger.dart';

/// Captures every record so tests can assert on what the SDK emitted.
final class RecordingSdkLogger implements SdkLogger {
  final List<String> lines = <String>[];

  /// Every record joined, for substring assertions.
  String get combined => lines.join('\n');

  @override
  void log(
    SdkLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    lines.add('${level.name}: $message${error == null ? '' : ' error=$error'}');
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/logging/ && flutter analyze --fatal-infos
```

Expected: all tests pass; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/src/logging test/logging test/support
git commit -m "feat(logging): add SdkLogger contract, silent default and redaction

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: Transport contract and value types

This is the boundary that keeps `package:http` out of the public API. Nothing here mentions a third-party type.

**Files:**
- Create: `lib/src/transport/sdk_http_request.dart`, `lib/src/transport/sdk_http_response.dart`, `lib/src/transport/sdk_http_call.dart`, `lib/src/transport/sdk_http_transport.dart`
- Test: `test/transport/sdk_http_types_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `SdkHttpRequest({required String method, required Uri uri, required Map<String, String> headers, Uint8List? body})`; `SdkHttpResponse({required int statusCode, required Map<String, String> headers, required Uint8List body})` with `String get bodyAsString`; `abstract interface class SdkHttpCall { Future<SdkHttpResponse> get response; Future<void> cancel(); }`; `abstract interface class SdkHttpTransport { SdkHttpCall open(SdkHttpRequest request); Future<void> close(); }`; internal marker `const SdkCallCancelled()`.

- [ ] **Step 1: Write the failing test**

`test/transport/sdk_http_types_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SdkHttpRequest carries method, uri, headers and an optional body', () {
    final request = SdkHttpRequest(
      method: 'GET',
      uri: Uri.parse('https://api.example.com/health'),
      headers: const <String, String>{'accept': 'application/json'},
    );

    expect(request.method, 'GET');
    expect(request.uri.path, '/health');
    expect(request.headers['accept'], 'application/json');
    expect(request.body, isNull);
  });

  test('SdkHttpResponse decodes its body as UTF-8', () {
    final response = SdkHttpResponse(
      statusCode: 200,
      headers: const <String, String>{},
      body: Uint8List.fromList(utf8.encode('{"status":"ok"}')),
    );

    expect(response.bodyAsString, '{"status":"ok"}');
  });

  test('SdkHttpResponse.bodyAsString tolerates malformed UTF-8', () {
    final response = SdkHttpResponse(
      statusCode: 200,
      headers: const <String, String>{},
      body: Uint8List.fromList(<int>[0xC3, 0x28]),
    );

    expect(response.bodyAsString, isNotEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/transport/sdk_http_types_test.dart
```

Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Implement the transport contract**

`lib/src/transport/sdk_http_request.dart`:

```dart
import 'dart:typed_data';

/// An HTTP request expressed in SDK-owned types.
///
/// The SDK builds these; a transport implementation consumes them. No HTTP
/// library type appears here, so the default transport can be replaced
/// without a breaking change.
final class SdkHttpRequest {
  /// Creates a request.
  const SdkHttpRequest({
    required this.method,
    required this.uri,
    required this.headers,
    this.body,
  });

  /// The HTTP method, upper-case (for example `GET`).
  final String method;

  /// The fully resolved target.
  final Uri uri;

  /// Headers to send. Already includes authentication.
  final Map<String, String> headers;

  /// The request body, or null when there is none.
  ///
  /// v1 represents bodies as bytes only: there is no streaming or multipart.
  final Uint8List? body;
}
```

`lib/src/transport/sdk_http_response.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

/// An HTTP response expressed in SDK-owned types.
final class SdkHttpResponse {
  /// Creates a response.
  const SdkHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  /// The HTTP status code.
  final int statusCode;

  /// Response headers, lower-cased by the transport.
  final Map<String, String> headers;

  /// The response body as bytes.
  final Uint8List body;

  /// The body decoded as UTF-8, substituting replacement characters rather
  /// than throwing on malformed input.
  String get bodyAsString => const Utf8Decoder(allowMalformed: true).convert(body);
}
```

`lib/src/transport/sdk_http_call.dart`:

```dart
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';

/// One in-flight request.
abstract interface class SdkHttpCall {
  /// Completes with the response, or with an error if the call fails or is
  /// cancelled.
  Future<SdkHttpResponse> get response;

  /// Abandons this call.
  ///
  /// Cancellation is **best-effort**: the SDK stops waiting and [response]
  /// completes with an error, but the underlying connection may remain open
  /// until the server replies. Never treat a cancelled call as proof that the
  /// server did not receive or process the request.
  Future<void> cancel();
}

/// Internal marker completing a call that was cancelled.
///
/// Never exported: hosts observe cancellation as an `SdkFailure` whose code is
/// `SdkErrorCodes.cancelled`.
final class SdkCallCancelled implements Exception {
  /// Creates the marker.
  const SdkCallCancelled();

  @override
  String toString() => 'SdkCallCancelled';
}
```

`lib/src/transport/sdk_http_transport.dart`:

```dart
import 'package:flutter_sdk_base/src/transport/sdk_http_call.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';

/// The injectable HTTP boundary.
///
/// A transport handed to `SdkClient` is **owned** by that client: the client
/// calls [close] during its own `close()`. Do not share one transport instance
/// between clients.
abstract interface class SdkHttpTransport {
  /// Starts [request] and returns a handle to it.
  SdkHttpCall open(SdkHttpRequest request);

  /// Releases every resource this transport holds.
  Future<void> close();
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/transport/ && flutter analyze --fatal-infos
```

Expected: all tests pass; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/src/transport test/transport
git commit -m "feat(transport): add SDK-owned HTTP request, response, call and transport contracts

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: Fake transport

The fake lands before the executor because every later test drives the SDK through it.

**Files:**
- Create: `lib/src/transport/fake_sdk_http_transport.dart`
- Test: `test/transport/fake_sdk_http_transport_test.dart`

**Interfaces:**
- Consumes: `SdkHttpTransport`, `SdkHttpCall`, `SdkHttpRequest`, `SdkHttpResponse`, `SdkCallCancelled` from Task 4.
- Produces: `FakeSdkHttpTransport()` with `List<SdkHttpRequest> requests`, `bool isClosed`, `void enqueueJson(String body, {int statusCode})`, `void enqueueError(Object error)`, `void enqueueNeverCompletes()`, `bool get hasPendingCancellation`.

- [ ] **Step 1: Write the failing test**

`test/transport/fake_sdk_http_transport_test.dart`:

```dart
import 'package:flutter_sdk_base/src/transport/fake_sdk_http_transport.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_test/flutter_test.dart';

SdkHttpRequest _request() => SdkHttpRequest(
      method: 'GET',
      uri: Uri.parse('https://api.example.com/health'),
      headers: const <String, String>{},
    );

void main() {
  group('FakeSdkHttpTransport', () {
    test('serves queued responses in order and records requests', () async {
      final transport = FakeSdkHttpTransport()
        ..enqueueJson('{"status":"ok"}')
        ..enqueueJson('{"status":"degraded"}', statusCode: 503);

      final first = await transport.open(_request()).response;
      final second = await transport.open(_request()).response;

      expect(first.statusCode, 200);
      expect(first.bodyAsString, '{"status":"ok"}');
      expect(second.statusCode, 503);
      expect(transport.requests, hasLength(2));
    });

    test('surfaces an enqueued error', () async {
      final transport = FakeSdkHttpTransport()..enqueueError(const SocketFailure());

      await expectLater(transport.open(_request()).response, throwsA(isA<SocketFailure>()));
    });

    test('cancel completes a never-completing call with an error', () async {
      final transport = FakeSdkHttpTransport()..enqueueNeverCompletes();
      final call = transport.open(_request());

      final pending = expectLater(call.response, throwsA(anything));
      await call.cancel();
      await pending;

      expect(transport.hasPendingCancellation, isTrue);
    });

    test('throws a clear error when nothing is queued', () {
      final transport = FakeSdkHttpTransport();

      expect(() => transport.open(_request()), throwsStateError);
    });

    test('close marks the transport closed', () async {
      final transport = FakeSdkHttpTransport();
      await transport.close();

      expect(transport.isClosed, isTrue);
    });
  });
}

final class SocketFailure implements Exception {
  const SocketFailure();
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/transport/fake_sdk_http_transport_test.dart
```

Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Implement the fake**

`lib/src/transport/fake_sdk_http_transport.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_sdk_base/src/transport/sdk_http_call.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_transport.dart';

/// A deterministic transport for host tests and for the bundled example.
///
/// Queue an outcome per expected call, then assert against [requests]. This is
/// a supported testing helper, never a production transport.
final class FakeSdkHttpTransport implements SdkHttpTransport {
  /// Creates an empty fake. Queue outcomes before use.
  FakeSdkHttpTransport();

  /// Every request the SDK issued, in order.
  final List<SdkHttpRequest> requests = <SdkHttpRequest>[];

  /// Whether the owning client closed this transport.
  bool isClosed = false;

  final List<FutureOr<SdkHttpResponse> Function(SdkHttpRequest request)> _outcomes =
      <FutureOr<SdkHttpResponse> Function(SdkHttpRequest request)>[];
  final List<_FakeSdkHttpCall> _calls = <_FakeSdkHttpCall>[];

  /// Whether any call was cancelled.
  bool get hasPendingCancellation => _calls.any((_FakeSdkHttpCall call) => call.wasCancelled);

  /// Queues a JSON response.
  void enqueueJson(String body, {int statusCode = 200}) {
    _outcomes.add(
      (SdkHttpRequest _) => SdkHttpResponse(
        statusCode: statusCode,
        headers: const <String, String>{'content-type': 'application/json'},
        body: Uint8List.fromList(utf8.encode(body)),
      ),
    );
  }

  /// Queues a transport-level failure.
  void enqueueError(Object error) {
    _outcomes.add((SdkHttpRequest _) => Future<SdkHttpResponse>.error(error));
  }

  /// Queues a call that never completes, so a test can exercise timeout or
  /// cancellation.
  void enqueueNeverCompletes() {
    _outcomes.add((SdkHttpRequest _) => Completer<SdkHttpResponse>().future);
  }

  @override
  SdkHttpCall open(SdkHttpRequest request) {
    requests.add(request);
    if (_outcomes.isEmpty) {
      throw StateError(
        'FakeSdkHttpTransport received ${requests.length} request(s) but no outcome was queued.',
      );
    }
    final call = _FakeSdkHttpCall(_outcomes.removeAt(0)(request));
    _calls.add(call);
    return call;
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }
}

final class _FakeSdkHttpCall implements SdkHttpCall {
  _FakeSdkHttpCall(FutureOr<SdkHttpResponse> outcome) {
    Future<SdkHttpResponse>.value(outcome).then(
      (SdkHttpResponse value) {
        if (!_completer.isCompleted) {
          _completer.complete(value);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_completer.isCompleted) {
          _completer.completeError(error, stackTrace);
        }
      },
    );
  }

  final Completer<SdkHttpResponse> _completer = Completer<SdkHttpResponse>();

  bool wasCancelled = false;

  @override
  Future<SdkHttpResponse> get response => _completer.future;

  @override
  Future<void> cancel() async {
    wasCancelled = true;
    if (!_completer.isCompleted) {
      _completer.completeError(const SdkCallCancelled());
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/transport/ && flutter analyze --fatal-infos
```

Expected: all tests pass; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/src/transport/fake_sdk_http_transport.dart test/transport/fake_sdk_http_transport_test.dart
git commit -m "feat(transport): add deterministic fake transport for host tests

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 6: Configuration and URI joining

`Uri.resolve` silently drops a base path segment, which would break any host whose API lives under `/v1`. This task makes that a tested rule instead of a latent bug.

**Files:**
- Create: `lib/src/client/sdk_config.dart`, `lib/src/util/sdk_uri.dart`
- Test: `test/util/sdk_uri_test.dart`, `test/client/sdk_config_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `SdkConfig({required Uri baseUri, required String apiKey, Duration requestTimeout = const Duration(seconds: 15)})`; `SdkUri.join(Uri base, String path)`.

- [ ] **Step 1: Write the failing tests**

`test/util/sdk_uri_test.dart`:

```dart
import 'package:flutter_sdk_base/src/util/sdk_uri.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SdkUri.join', () {
    test('appends to a bare host', () {
      expect(
        SdkUri.join(Uri.parse('https://api.example.com'), 'health').toString(),
        'https://api.example.com/health',
      );
    });

    test('preserves a base path segment', () {
      expect(
        SdkUri.join(Uri.parse('https://api.example.com/v1'), 'health').toString(),
        'https://api.example.com/v1/health',
      );
    });

    test('does not double the separator when the base ends with a slash', () {
      expect(
        SdkUri.join(Uri.parse('https://api.example.com/v1/'), 'health').toString(),
        'https://api.example.com/v1/health',
      );
    });

    test('accepts a leading slash on the path', () {
      expect(
        SdkUri.join(Uri.parse('https://api.example.com/v1'), '/health').toString(),
        'https://api.example.com/v1/health',
      );
    });

    test('keeps the base query out of the way', () {
      expect(
        SdkUri.join(Uri.parse('https://api.example.com/v1'), 'health').query,
        isEmpty,
      );
    });
  });
}
```

`test/client/sdk_config_test.dart`:

```dart
import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SdkConfig defaults requestTimeout to 15 seconds', () {
    final config = SdkConfig(
      baseUri: Uri.parse('https://api.example.com'),
      apiKey: 'key',
    );

    expect(config.requestTimeout, const Duration(seconds: 15));
  });

  test('SdkConfig accepts an explicit timeout', () {
    final config = SdkConfig(
      baseUri: Uri.parse('https://api.example.com'),
      apiKey: 'key',
      requestTimeout: const Duration(seconds: 3),
    );

    expect(config.requestTimeout, const Duration(seconds: 3));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/util/ test/client/
```

Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Implement config and URI joining**

`lib/src/util/sdk_uri.dart`:

```dart
/// URI helpers shared by SDK services.
abstract final class SdkUri {
  /// Appends [path] to [base] without discarding the base's own path.
  ///
  /// `Uri.resolve` would turn `https://host/v1` + `health` into
  /// `https://host/health`, silently dropping the API version. This does not.
  static Uri join(Uri base, String path) {
    final String basePath = base.path.endsWith('/') ? base.path.substring(0, base.path.length - 1) : base.path;
    final String suffix = path.startsWith('/') ? path : '/$path';
    return base.replace(path: '$basePath$suffix');
  }
}
```

`lib/src/client/sdk_config.dart`:

```dart
/// Everything an `SdkClient` needs to talk to an API.
///
/// The SDK stores nothing: a host supplies this on every construction and
/// keeps whatever it needs across app restarts.
final class SdkConfig {
  /// Creates a configuration.
  const SdkConfig({
    required this.baseUri,
    required this.apiKey,
    this.requestTimeout = const Duration(seconds: 15),
  });

  /// The API root. A path here is preserved, so `https://host/v1` works.
  final Uri baseUri;

  /// The credential sent with every request.
  ///
  /// The SDK redacts this in every record it hands to an `SdkLogger`.
  final String apiKey;

  /// How long a single operation may run before it fails with
  /// `SdkErrorCodes.timeout`.
  final Duration requestTimeout;
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/util/ test/client/ && flutter analyze --fatal-infos
```

Expected: all tests pass; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/src/client/sdk_config.dart lib/src/util test/util test/client
git commit -m "feat(client): add SdkConfig and path-preserving URI joining

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 7: Request executor — auth, timeout, cancellation, error mapping

This is the heart of the SDK. Every behavioural guarantee in the spec is enforced here, once.

**Files:**
- Create: `lib/src/client/sdk_request_executor.dart`
- Test: `test/client/sdk_request_executor_test.dart`

**Interfaces:**
- Consumes: `SdkConfig` (Task 6), `SdkHttpTransport`/`SdkHttpRequest`/`SdkHttpResponse`/`SdkCallCancelled` (Task 4), `FakeSdkHttpTransport` (Task 5), `SdkLogger`/`SdkLogLevel`/`SdkRedaction` (Task 3), `SdkFailure`/`SdkException`/`SdkErrorCodes` (Task 2).
- Produces: `SdkRequestExecutor({required SdkConfig config, required SdkHttpTransport transport, required SdkLogger logger})` with `Future<SdkHttpResponse> send(SdkHttpRequest request)`, `Future<void> close()`, `bool get isClosed`, and `Map<String, String> authHeaders()`.

- [ ] **Step 1: Write the failing test**

`test/client/sdk_request_executor_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/client/sdk_request_executor.dart';
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/transport/fake_sdk_http_transport.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_sdk_logger.dart';

const String _apiKey = 'key';

SdkConfig _config({Duration timeout = const Duration(seconds: 15)}) => SdkConfig(
      baseUri: Uri.parse('https://api.example.com'),
      apiKey: _apiKey,
      requestTimeout: timeout,
    );

SdkHttpRequest _request() => SdkHttpRequest(
      method: 'GET',
      uri: Uri.parse('https://api.example.com/health'),
      headers: const <String, String>{},
    );

void main() {
  group('SdkRequestExecutor', () {
    test('returns the transport response unchanged on success', () async {
      final transport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: transport,
        logger: RecordingSdkLogger(),
      );

      final response = await executor.send(_request());

      expect(response.statusCode, 200);
    });

    test('authHeaders carries the api key and a JSON accept header', () {
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: FakeSdkHttpTransport(),
        logger: RecordingSdkLogger(),
      );

      expect(executor.authHeaders()['X-Api-Key'], _apiKey);
      expect(executor.authHeaders()['Accept'], 'application/json');
    });

    test('maps a transport error to a retryable transport failure', () async {
      final transport = FakeSdkHttpTransport()..enqueueError(Exception('socket down'));
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: transport,
        logger: RecordingSdkLogger(),
      );

      final SdkException error = await _captureSdkException(() => executor.send(_request()));

      expect(error.failure.code, SdkErrorCodes.transport);
      expect(error.failure.isRetryable, isTrue);
      expect(error.failure.cause, isNotNull);
    });

    test('fails with timeout and cancels the call when the deadline passes', () async {
      final transport = FakeSdkHttpTransport()..enqueueNeverCompletes();
      final executor = SdkRequestExecutor(
        config: _config(timeout: const Duration(milliseconds: 30)),
        transport: transport,
        logger: RecordingSdkLogger(),
      );

      final SdkException error = await _captureSdkException(() => executor.send(_request()));

      expect(error.failure.code, SdkErrorCodes.timeout);
      expect(error.failure.isRetryable, isTrue);
      expect(transport.hasPendingCancellation, isTrue);
    });

    test('close cancels an in-flight call, which fails as cancelled', () async {
      final transport = FakeSdkHttpTransport()..enqueueNeverCompletes();
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: transport,
        logger: RecordingSdkLogger(),
      );

      final Future<SdkException> pending = _captureSdkException(() => executor.send(_request()));
      await Future<void>.delayed(Duration.zero);
      await executor.close();

      final SdkException error = await pending;
      expect(error.failure.code, SdkErrorCodes.cancelled);
      expect(error.failure.isRetryable, isFalse);
      expect(transport.isClosed, isTrue);
    });

    test('close is idempotent', () async {
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: FakeSdkHttpTransport(),
        logger: RecordingSdkLogger(),
      );

      await executor.close();
      await expectLater(executor.close(), completes);
      expect(executor.isClosed, isTrue);
    });

    test('send after close throws StateError, not SdkException', () async {
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: FakeSdkHttpTransport(),
        logger: RecordingSdkLogger(),
      );
      await executor.close();

      expect(() => executor.send(_request()), throwsStateError);
    });

    test('never logs the api key verbatim, on any path', () async {
      final logger = RecordingSdkLogger();
      final transport = FakeSdkHttpTransport()
        ..enqueueJson('{}', statusCode: 401)
        ..enqueueError(Exception('socket down'));
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: transport,
        logger: logger,
      );

      await executor.send(_request());
      await _captureSdkException(() => executor.send(_request()));

      expect(logger.combined, isNot(contains(_apiKey)));
      expect(logger.combined, contains('sk_l…4a1d'));
    });
  });
}

Future<SdkException> _captureSdkException(Future<void> Function() action) async {
  try {
    await action();
  } on SdkException catch (error) {
    return error;
  }
  fail('expected an SdkException');
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/client/sdk_request_executor_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: '.../sdk_request_executor.dart'`.

- [ ] **Step 3: Implement the executor**

`lib/src/client/sdk_request_executor.dart`:

```dart
import 'dart:async';

import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/errors/sdk_failure.dart';
import 'package:flutter_sdk_base/src/logging/sdk_log_level.dart';
import 'package:flutter_sdk_base/src/logging/sdk_logger.dart';
import 'package:flutter_sdk_base/src/logging/sdk_redaction.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_call.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_transport.dart';
import 'package:meta/meta.dart';

/// Runs every SDK request through one place, so authentication, timeout,
/// cancellation, logging, and failure mapping cannot diverge per call site.
///
/// Internal: not exported from any public barrel.
@internal
final class SdkRequestExecutor {
  /// Creates an executor that owns [transport].
  SdkRequestExecutor({
    required SdkConfig config,
    required SdkHttpTransport transport,
    required SdkLogger logger,
  })  : _config = config,
        _transport = transport,
        _logger = logger;

  final SdkConfig _config;
  final SdkHttpTransport _transport;
  final SdkLogger _logger;
  final Set<_ActiveCall> _active = <_ActiveCall>{};

  bool _closed = false;

  /// Whether [close] has run.
  bool get isClosed => _closed;

  /// Headers every SDK request carries.
  Map<String, String> authHeaders() => <String, String>{
        'Accept': 'application/json',
        'X-Api-Key': _config.apiKey,
      };

  /// Sends [request], applying the configured timeout.
  ///
  /// Throws [StateError] if the client was closed — that is host misuse, not a
  /// recoverable failure. Throws [SdkException] for everything else.
  Future<SdkHttpResponse> send(SdkHttpRequest request) async {
    if (_closed) {
      throw StateError('This SdkClient has been closed. Create a new client to make further calls.');
    }

    _logger.log(SdkLogLevel.debug, '${request.method} ${request.uri.path}');

    final _ActiveCall entry = _ActiveCall(_transport.open(request));
    _active.add(entry);

    try {
      final SdkHttpResponse response = await entry.call.response.timeout(
        _config.requestTimeout,
        onTimeout: () {
          entry.cancelCode = SdkErrorCodes.timeout;
          unawaited(entry.call.cancel());
          throw TimeoutException('SDK request timed out', _config.requestTimeout);
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        _logger.log(
          SdkLogLevel.warn,
          'auth rejected (HTTP ${response.statusCode}) for apiKey=${SdkRedaction.secret(_config.apiKey)}',
        );
      }

      return response;
    } on TimeoutException {
      const SdkFailure failure = SdkFailure(
        code: SdkErrorCodes.timeout,
        message: 'The request exceeded the configured timeout.',
        isRetryable: true,
      );
      _logger.log(SdkLogLevel.error, 'request failed with code ${failure.code}');
      throw const SdkException(failure);
    } on Object catch (error, stackTrace) {
      final SdkFailure failure = entry.cancelCode == SdkErrorCodes.cancelled
          ? const SdkFailure(
              code: SdkErrorCodes.cancelled,
              message: 'The request was cancelled because the client was closed.',
              isRetryable: false,
            )
          : SdkFailure(
              code: SdkErrorCodes.transport,
              message: 'The request did not reach the API.',
              isRetryable: true,
              cause: error,
            );
      _logger.log(
        SdkLogLevel.error,
        'request failed with code ${failure.code}',
        error: failure.code == SdkErrorCodes.transport ? error : null,
        stackTrace: stackTrace,
      );
      throw SdkException(failure);
    } finally {
      _active.remove(entry);
    }
  }

  /// Cancels every in-flight call, releases the transport, and blocks further
  /// sends. Safe to call more than once.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;

    final List<_ActiveCall> pending = List<_ActiveCall>.of(_active);
    for (final _ActiveCall entry in pending) {
      entry.cancelCode = SdkErrorCodes.cancelled;
    }
    await Future.wait<void>(pending.map((_ActiveCall entry) => entry.call.cancel()));
    await _transport.close();
  }
}

final class _ActiveCall {
  _ActiveCall(this.call);

  final SdkHttpCall call;

  String? cancelCode;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/client/ && flutter analyze --fatal-infos
```

Expected: all tests pass; `No issues found!`. If the `RecordingSdkLogger()` call sites fail to compile, drop `const` there.

- [ ] **Step 5: Commit**

```bash
git add lib/src/client/sdk_request_executor.dart test/client/sdk_request_executor_test.dart
git commit -m "feat(client): add request executor with auth, timeout, cancellation and failure mapping

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 8: Health slice

**Files:**
- Create: `lib/src/health/sdk_health.dart`, `lib/src/health/sdk_health_service.dart`
- Test: `test/health/sdk_health_service_test.dart`

**Interfaces:**
- Consumes: `SdkRequestExecutor` (Task 7), `SdkConfig`/`SdkUri` (Task 6), `failureForStatus`/`SdkException`/`SdkErrorCodes` (Task 2), `FakeSdkHttpTransport` (Task 5).
- Produces: `typedef SdkClock = DateTime Function();`; `SdkHealth({required bool isHealthy, required String status, required DateTime checkedAt})`; `SdkHealthService({required SdkRequestExecutor executor, required SdkConfig config, required SdkClock clock})` (constructor annotated `@internal`) with `Future<SdkHealth> check()`.

- [ ] **Step 1: Write the failing test**

`test/health/sdk_health_service_test.dart`:

```dart
import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/client/sdk_request_executor.dart';
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/health/sdk_health.dart';
import 'package:flutter_sdk_base/src/health/sdk_health_service.dart';
import 'package:flutter_sdk_base/src/transport/fake_sdk_http_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_sdk_logger.dart';

final DateTime _frozenNow = DateTime.utc(2026, 9, 14, 10, 30);

({SdkHealthService service, FakeSdkHttpTransport transport}) _subject({
  Uri? baseUri,
  RecordingSdkLogger? logger,
}) {
  final transport = FakeSdkHttpTransport();
  final config = SdkConfig(
    baseUri: baseUri ?? Uri.parse('https://api.example.com'),
    apiKey: 'key',
  );
  final service = SdkHealthService(
    executor: SdkRequestExecutor(
      config: config,
      transport: transport,
      logger: logger ?? RecordingSdkLogger(),
    ),
    config: config,
    clock: () => _frozenNow,
  );
  return (service: service, transport: transport);
}

void main() {
  group('SdkHealthService.check', () {
    test('maps an ok status to a healthy result stamped by the injected clock', () async {
      final subject = _subject()..transport.enqueueJson('{"status":"ok"}');

      final SdkHealth health = await subject.service.check();

      expect(health.isHealthy, isTrue);
      expect(health.status, 'ok');
      expect(health.checkedAt, _frozenNow);
    });

    test('maps any other status to an unhealthy result', () async {
      final subject = _subject()..transport.enqueueJson('{"status":"degraded"}');

      final SdkHealth health = await subject.service.check();

      expect(health.isHealthy, isFalse);
      expect(health.status, 'degraded');
    });

    test('requests GET /health under the configured base path with auth', () async {
      final subject = _subject(baseUri: Uri.parse('https://api.example.com/v1'))
        ..transport.enqueueJson('{"status":"ok"}');

      await subject.service.check();

      final request = subject.transport.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.toString(), 'https://api.example.com/v1/health');
      expect(request.headers['X-Api-Key'], 'key');
    });

    test('maps 401 to unauthorized', () async {
      final subject = _subject()..transport.enqueueJson('{}', statusCode: 401);

      final SdkException error = await _captureSdkException(subject.service.check);

      expect(error.failure.code, SdkErrorCodes.unauthorized);
      expect(error.failure.statusCode, 401);
      expect(error.failure.isRetryable, isFalse);
    });

    test('maps 404 to client', () async {
      final subject = _subject()..transport.enqueueJson('{}', statusCode: 404);

      final SdkException error = await _captureSdkException(subject.service.check);

      expect(error.failure.code, SdkErrorCodes.client);
    });

    test('maps 503 to a retryable server failure', () async {
      final subject = _subject()..transport.enqueueJson('{}', statusCode: 503);

      final SdkException error = await _captureSdkException(subject.service.check);

      expect(error.failure.code, SdkErrorCodes.server);
      expect(error.failure.isRetryable, isTrue);
    });

    test('maps a 2xx body that is not JSON to invalidResponse', () async {
      final subject = _subject()..transport.enqueueJson('<html>oops</html>');

      final SdkException error = await _captureSdkException(subject.service.check);

      expect(error.failure.code, SdkErrorCodes.invalidResponse);
      expect(error.failure.isRetryable, isFalse);
    });

    test('maps a 2xx JSON body without a status field to invalidResponse', () async {
      final subject = _subject()..transport.enqueueJson('{"state":"ok"}');

      final SdkException error = await _captureSdkException(subject.service.check);

      expect(error.failure.code, SdkErrorCodes.invalidResponse);
    });
  });
}

Future<SdkException> _captureSdkException(Future<void> Function() action) async {
  try {
    await action();
  } on SdkException catch (error) {
    return error;
  }
  fail('expected an SdkException');
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/health/
```

Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Implement the health slice**

`lib/src/health/sdk_health.dart`:

```dart
/// The outcome of an API health check.
final class SdkHealth {
  /// Creates a health result.
  const SdkHealth({
    required this.isHealthy,
    required this.status,
    required this.checkedAt,
  });

  /// Whether the API reported itself healthy.
  final bool isHealthy;

  /// The raw status string the API returned, for display or logging.
  final String status;

  /// When the SDK observed the response.
  final DateTime checkedAt;
}
```

`lib/src/health/sdk_health_service.dart`:

```dart
import 'dart:convert';

import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/client/sdk_request_executor.dart';
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/errors/sdk_failure.dart';
import 'package:flutter_sdk_base/src/errors/sdk_status_mapping.dart';
import 'package:flutter_sdk_base/src/health/sdk_health.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_sdk_base/src/util/sdk_uri.dart';
import 'package:meta/meta.dart';

/// Supplies the current time. Internal seam so tests can freeze the clock.
typedef SdkClock = DateTime Function();

/// The reference capability: a single `GET /health` call.
///
/// This exists to demonstrate one complete public-contract → transport →
/// error → host-test path. A product team replaces it when cloning this base.
final class SdkHealthService {
  /// Creates the service.
  ///
  /// Obtain one from `SdkClient.health` rather than constructing it: this
  /// constructor is internal and its shape carries no compatibility guarantee.
  @internal
  SdkHealthService({
    required SdkRequestExecutor executor,
    required SdkConfig config,
    required SdkClock clock,
  })  : _executor = executor,
        _config = config,
        _clock = clock;

  final SdkRequestExecutor _executor;
  final SdkConfig _config;
  final SdkClock _clock;

  /// Asks the API whether it is healthy.
  ///
  /// Throws [SdkException] when the request fails, the API rejects it, or the
  /// response body cannot be parsed. Throws [StateError] if the owning client
  /// has been closed.
  Future<SdkHealth> check() async {
    final SdkHttpResponse response = await _executor.send(
      SdkHttpRequest(
        method: 'GET',
        uri: SdkUri.join(_config.baseUri, 'health'),
        headers: _executor.authHeaders(),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SdkException(failureForStatus(response.statusCode));
    }

    final Object? decoded = _decode(response.bodyAsString);
    if (decoded is! Map<String, Object?>) {
      throw const SdkException(
        SdkFailure(
          code: SdkErrorCodes.invalidResponse,
          message: 'The health endpoint did not return a JSON object.',
          isRetryable: false,
        ),
      );
    }

    final Object? status = decoded['status'];
    if (status is! String) {
      throw const SdkException(
        SdkFailure(
          code: SdkErrorCodes.invalidResponse,
          message: 'The health response did not contain a string "status" field.',
          isRetryable: false,
        ),
      );
    }

    return SdkHealth(
      isHealthy: status == 'ok',
      status: status,
      checkedAt: _clock(),
    );
  }

  static Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/health/ && flutter analyze --fatal-infos
```

Expected: all tests pass; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/src/health test/health
git commit -m "feat(health): add the reference health capability with a frozen-clock seam

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 9: Default `package:http` transport

The only file in `lib/` that knows `package:http` exists.

**Files:**
- Create: `lib/src/transport/package_http_transport.dart`
- Test: `test/transport/package_http_transport_test.dart`

**Interfaces:**
- Consumes: `SdkHttpTransport`/`SdkHttpCall`/`SdkHttpRequest`/`SdkHttpResponse`/`SdkCallCancelled` (Task 4).
- Produces: `PackageHttpTransport({http.Client? client})` — the named parameter is internal and never reaches a public barrel signature.

- [ ] **Step 1: Write the failing test**

`test/transport/package_http_transport_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_sdk_base/src/transport/package_http_transport.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

SdkHttpRequest _request() => SdkHttpRequest(
      method: 'GET',
      uri: Uri.parse('https://api.example.com/health'),
      headers: const <String, String>{'X-Api-Key': 'key'},
    );

void main() {
  group('PackageHttpTransport', () {
    test('forwards method, uri and headers, and returns status and body', () async {
      late http.Request seen;
      final transport = PackageHttpTransport(
        client: MockClient((http.Request request) async {
          seen = request;
          return http.Response('{"status":"ok"}', 200);
        }),
      );

      final SdkHttpResponse response = await transport.open(_request()).response;

      expect(seen.method, 'GET');
      expect(seen.url.toString(), 'https://api.example.com/health');
      expect(seen.headers['X-Api-Key'], 'key');
      expect(response.statusCode, 200);
      expect(response.bodyAsString, '{"status":"ok"}');
    });

    test('surfaces a client error through the response future', () async {
      final transport = PackageHttpTransport(
        client: MockClient((http.Request request) async => throw const http.ClientException('boom')),
      );

      await expectLater(transport.open(_request()).response, throwsA(isA<http.ClientException>()));
    });

    test('cancel completes the pending response with an error', () async {
      final Completer<http.Response> never = Completer<http.Response>();
      final transport = PackageHttpTransport(
        client: MockClient((http.Request request) => never.future),
      );

      final call = transport.open(_request());
      final Future<void> pending = expectLater(call.response, throwsA(anything));
      await call.cancel();
      await pending;
    });

    test('close releases the underlying client', () async {
      final transport = PackageHttpTransport(
        client: MockClient((http.Request request) async => http.Response('{}', 200)),
      );

      await expectLater(transport.close(), completes);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/transport/package_http_transport_test.dart
```

Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Implement the default transport**

`lib/src/transport/package_http_transport.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sdk_base/src/transport/sdk_http_call.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_transport.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// The default transport, backed by `package:http`.
///
/// This is the only file in `lib/` that references an HTTP library. Nothing it
/// exposes reaches a public signature, so the library can be replaced without
/// a breaking change.
///
/// Cancellation is best-effort. `package:http` cannot abort a single request;
/// [SdkHttpCall.cancel] therefore stops the SDK waiting and discards the
/// result while the socket may run to completion. The alternative — one client
/// per request — was rejected because it costs a TCP and TLS handshake on
/// every call.
@internal
final class PackageHttpTransport implements SdkHttpTransport {
  /// Creates a transport, optionally over a supplied client (tests only).
  PackageHttpTransport({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  SdkHttpCall open(SdkHttpRequest request) => _PackageHttpCall(_client, request);

  @override
  Future<void> close() async => _client.close();
}

final class _PackageHttpCall implements SdkHttpCall {
  _PackageHttpCall(this._client, this._request) {
    unawaited(_start());
  }

  final http.Client _client;
  final SdkHttpRequest _request;
  final Completer<SdkHttpResponse> _completer = Completer<SdkHttpResponse>();

  bool _cancelled = false;

  @override
  Future<SdkHttpResponse> get response => _completer.future;

  @override
  Future<void> cancel() async {
    if (_completer.isCompleted) {
      return;
    }
    _cancelled = true;
    _completer.completeError(const SdkCallCancelled());
  }

  Future<void> _start() async {
    try {
      final http.Request outgoing = http.Request(_request.method, _request.uri)
        ..headers.addAll(_request.headers);
      final Uint8List? body = _request.body;
      if (body != null) {
        outgoing.bodyBytes = body;
      }

      final http.StreamedResponse streamed = await _client.send(outgoing);
      final Uint8List bytes = await streamed.stream.toBytes();

      if (_cancelled || _completer.isCompleted) {
        return;
      }
      _completer.complete(
        SdkHttpResponse(
          statusCode: streamed.statusCode,
          headers: streamed.headers,
          body: bytes,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (!_completer.isCompleted) {
        _completer.completeError(error, stackTrace);
      }
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test && flutter analyze --fatal-infos && make boundary
```

Expected: every test passes; `No issues found!`; `boundary ok`.

- [ ] **Step 5: Commit**

```bash
git add lib/src/transport/package_http_transport.dart test/transport/package_http_transport_test.dart
git commit -m "feat(transport): add the default package:http transport with best-effort cancel

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 10: `SdkClient` and the public barrels

**Files:**
- Create: `lib/src/client/sdk_client.dart`, `lib/flutter_sdk_base.dart`, `lib/flutter_sdk_base_testing.dart`
- Create: `README.md` (replace the inherited one)
- Modify: `CHANGELOG.md`
- Test: `test/client/sdk_client_test.dart`, `test/public_api_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 2–9.
- Produces: `SdkClient({required SdkConfig config, SdkHttpTransport? transport, SdkLogger? logger})` with `SdkHealthService get health` and `Future<void> close()`. Public barrel exports `SdkClient`, `SdkConfig`, `SdkHealthService`, `SdkHealth`, `SdkHttpTransport`, `SdkHttpCall`, `SdkHttpRequest`, `SdkHttpResponse`, `SdkLogger`, `SdkLogLevel`, `SdkFailure`, `SdkException`, `SdkErrorCodes`. Testing barrel exports `FakeSdkHttpTransport` only.

- [ ] **Step 1: Write the failing tests**

`test/client/sdk_client_test.dart`:

```dart
import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';
import 'package:flutter_test/flutter_test.dart';

SdkConfig _config() => SdkConfig(
      baseUri: Uri.parse('https://api.example.com'),
      apiKey: 'key',
    );

void main() {
  group('SdkClient', () {
    test('performs a health check through an injected transport', () async {
      final transport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
      final client = SdkClient(config: _config(), transport: transport);

      final SdkHealth health = await client.health.check();

      expect(health.isHealthy, isTrue);
      await client.close();
    });

    test('returns the same health service on repeated access', () {
      final client = SdkClient(config: _config(), transport: FakeSdkHttpTransport());

      expect(identical(client.health, client.health), isTrue);
    });

    test('close is idempotent and closes the owned transport', () async {
      final transport = FakeSdkHttpTransport();
      final client = SdkClient(config: _config(), transport: transport);

      await client.close();
      await expectLater(client.close(), completes);
      expect(transport.isClosed, isTrue);
    });

    test('an operation after close throws StateError', () async {
      final client = SdkClient(config: _config(), transport: FakeSdkHttpTransport());
      await client.close();

      expect(client.health.check, throwsStateError);
    });

    test('two clients run concurrently without sharing state', () async {
      final firstTransport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
      final secondTransport = FakeSdkHttpTransport()..enqueueJson('{"status":"degraded"}');
      final first = SdkClient(config: _config(), transport: firstTransport);
      final second = SdkClient(config: _config(), transport: secondTransport);

      final List<SdkHealth> results = await Future.wait<SdkHealth>(<Future<SdkHealth>>[
        first.health.check(),
        second.health.check(),
      ]);

      expect(results[0].status, 'ok');
      expect(results[1].status, 'degraded');

      await first.close();
      expect(secondTransport.isClosed, isFalse, reason: 'closing one client must not affect another');
      await second.close();
    });

    test('a host can observe failures through SdkException only', () async {
      final transport = FakeSdkHttpTransport()..enqueueJson('{}', statusCode: 500);
      final client = SdkClient(config: _config(), transport: transport);

      try {
        await client.health.check();
        fail('expected an SdkException');
      } on SdkException catch (error) {
        expect(error.failure.code, SdkErrorCodes.server);
        expect(error.failure.isRetryable, isTrue);
      }

      await client.close();
    });
  });
}
```

`test/public_api_test.dart` — this is the consumer-shaped guard: it imports the barrels *only*, exactly as a host would.

```dart
import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every documented public type is reachable from the barrels', () {
    expect(SdkClient, isNotNull);
    expect(SdkConfig, isNotNull);
    expect(SdkHealthService, isNotNull);
    expect(SdkHealth, isNotNull);
    expect(SdkHttpTransport, isNotNull);
    expect(SdkHttpCall, isNotNull);
    expect(SdkHttpRequest, isNotNull);
    expect(SdkHttpResponse, isNotNull);
    expect(SdkLogger, isNotNull);
    expect(SdkLogLevel, isNotNull);
    expect(SdkFailure, isNotNull);
    expect(SdkException, isNotNull);
    expect(SdkErrorCodes, isNotNull);
    expect(FakeSdkHttpTransport, isNotNull);
  });

  test('a host can build every public value type without reaching into src', () {
    final config = SdkConfig(baseUri: Uri.parse('https://api.example.com'), apiKey: 'k');
    const failure = SdkFailure(code: SdkErrorCodes.timeout, message: 'x', isRetryable: true);

    expect(config.apiKey, 'k');
    expect(const SdkException(failure).failure.code, SdkErrorCodes.timeout);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/client/sdk_client_test.dart test/public_api_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:flutter_sdk_base/flutter_sdk_base.dart'`.

- [ ] **Step 3: Implement the client and barrels**

`lib/src/client/sdk_client.dart`:

```dart
import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/client/sdk_request_executor.dart';
import 'package:flutter_sdk_base/src/health/sdk_health_service.dart';
import 'package:flutter_sdk_base/src/logging/sdk_logger.dart';
import 'package:flutter_sdk_base/src/logging/silent_sdk_logger.dart';
import 'package:flutter_sdk_base/src/transport/package_http_transport.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_transport.dart';

/// The entry point to the SDK.
///
/// Create one per configuration, use it, then [close] it. The SDK holds no
/// global state, so several clients may run at once with different
/// configuration, transports, and loggers.
///
/// ```dart
/// final sdk = SdkClient(
///   config: SdkConfig(baseUri: apiRoot, apiKey: key),
/// );
/// final health = await sdk.health.check();
/// await sdk.close();
/// ```
final class SdkClient {
  /// Creates a client.
  ///
  /// [transport] defaults to the SDK's own `package:http` implementation, and
  /// [logger] to a silent one. A supplied transport is **owned** by this
  /// client and is closed by [close]; do not share one between clients.
  SdkClient({
    required SdkConfig config,
    SdkHttpTransport? transport,
    SdkLogger? logger,
  }) : this._(
          config: config,
          transport: transport ?? PackageHttpTransport(),
          logger: logger ?? const SilentSdkLogger(),
          clock: DateTime.now,
        );

  SdkClient._({
    required SdkConfig config,
    required SdkHttpTransport transport,
    required SdkLogger logger,
    required SdkClock clock,
  }) : _executor = SdkRequestExecutor(config: config, transport: transport, logger: logger) {
    _health = SdkHealthService(executor: _executor, config: config, clock: clock);
  }

  final SdkRequestExecutor _executor;

  late final SdkHealthService _health;

  /// The reference health capability.
  SdkHealthService get health => _health;

  /// Cancels in-flight work, releases the transport, and blocks further calls.
  ///
  /// Idempotent. Any operation attempted afterwards throws [StateError].
  /// In-flight operations fail with `SdkErrorCodes.cancelled`; cancellation is
  /// best-effort, so a request already delivered may still be processed by the
  /// server.
  Future<void> close() => _executor.close();
}
```

`lib/flutter_sdk_base.dart`:

```dart
/// A Flutter SDK package with no native code: an instance-based client, an
/// injectable HTTP transport, typed failures, and silent-by-default logging.
///
/// Only the declarations exported here and from `flutter_sdk_base_testing.dart`
/// are supported API. Everything under `src/` may change in any release.
library;

export 'src/client/sdk_client.dart' show SdkClient;
export 'src/client/sdk_config.dart' show SdkConfig;
export 'src/errors/sdk_error_codes.dart' show SdkErrorCodes;
export 'src/errors/sdk_exception.dart' show SdkException;
export 'src/errors/sdk_failure.dart' show SdkFailure;
export 'src/health/sdk_health.dart' show SdkHealth;
export 'src/health/sdk_health_service.dart' show SdkHealthService;
export 'src/logging/sdk_log_level.dart' show SdkLogLevel;
export 'src/logging/sdk_logger.dart' show SdkLogger;
export 'src/transport/sdk_http_call.dart' show SdkHttpCall;
export 'src/transport/sdk_http_request.dart' show SdkHttpRequest;
export 'src/transport/sdk_http_response.dart' show SdkHttpResponse;
export 'src/transport/sdk_http_transport.dart' show SdkHttpTransport;
```

`lib/flutter_sdk_base_testing.dart`:

```dart
/// Supported test doubles for hosts integrating `flutter_sdk_base`.
///
/// Import this from tests and from example code only.
library;

export 'src/transport/fake_sdk_http_transport.dart' show FakeSdkHttpTransport;
```

- [ ] **Step 4: Write `README.md`**

```markdown
# flutter_sdk_base

A template for building a Flutter SDK package with no native code.

## Install

```yaml
dependencies:
  flutter_sdk_base: ^0.1.0
```

## Support matrix

| Surface | Supported |
| --- | --- |
| Dart | `>=3.13.0 <4.0.0` |
| Flutter | `>=3.47.0` |
| Android | API 24+ |
| iOS | 15.0+ |

Web and desktop may compile but are untested and unsupported.

## Usage

```dart
final sdk = SdkClient(
  config: SdkConfig(
    baseUri: Uri.parse('https://api.example.com'),
    apiKey: hostSuppliedKey,
  ),
);

try {
  final health = await sdk.health.check();
  print(health.status);
} on SdkException catch (error) {
  if (error.failure.code == SdkErrorCodes.unauthorized) {
    // map to your own copy — the SDK never produces user-facing text
  }
} finally {
  await sdk.close();
}
```

## Errors

Operations throw `SdkException`, which carries an `SdkFailure`. Branch on
`failure.code` (see `SdkErrorCodes`) and translate it yourself. `failure.message`
is English developer text. `failure.isRetryable` is advice — the SDK never
retries on its own. `failure.cause` is diagnostic only and carries no
compatibility guarantee.

Using a client after `close()` throws `StateError`, not `SdkException`: that is
a programming mistake rather than a runtime failure.

## Lifecycle

Create a client, use it, close it. `close()` is idempotent, cancels in-flight
work, and releases the transport.

**Cancellation is best-effort.** `close()` makes the SDK stop waiting and fail
pending operations with `SdkErrorCodes.cancelled`, but the underlying socket may
remain open until the server replies. Never treat a cancelled call as proof the
server did not process the request.

## Testing

```dart
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';

final transport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
final sdk = SdkClient(config: config, transport: transport);
```

## Compatibility

Semantic versioning. Only `flutter_sdk_base.dart` and
`flutter_sdk_base_testing.dart` are supported API; `src/` is not. Adding an API
or an error code is non-breaking; removing or changing either, or raising a
support floor, is breaking. Deprecations last at least one minor release.
```

- [ ] **Step 5: Update `CHANGELOG.md`**

```markdown
# Changelog

## 0.1.0 (unreleased)

- Initial public API: `SdkClient`, `SdkConfig`, `SdkHealthService`, `SdkHealth`.
- Injectable `SdkHttpTransport` with an internal `package:http` default.
- Typed failures via `SdkException` / `SdkFailure` / `SdkErrorCodes`.
- Silent-by-default `SdkLogger`; the API key is redacted in every record.
- `FakeSdkHttpTransport` in `flutter_sdk_base_testing.dart`.
```

- [ ] **Step 6: Run the full gate**

```bash
flutter test && flutter analyze --fatal-infos && make boundary && flutter pub publish --dry-run
```

Expected: every test passes; `No issues found!`; `boundary ok`; `Package has 0 warnings.`

- [ ] **Step 7: Commit**

```bash
git add lib README.md CHANGELOG.md test
git commit -m "feat(client): add SdkClient and the public barrels

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 11: Example host

Generated fresh. Never migrated from the inherited app.

**Files:**
- Create: `example/` (via `flutter create`), then replace `example/lib/main.dart`, `example/pubspec.yaml`, `example/analysis_options.yaml`
- Delete: `example/test/`

- [ ] **Step 1: Generate a fresh host at the derived floors**

```bash
cd /Users/thanhng224/Dev/Personal/GitHub/FlutterSdkBase
flutter create --platforms=android,ios --org com.example --project-name flutter_sdk_base_example example
rm -rf example/test
```

- [ ] **Step 2: Verify the generated floors match the spec**

```bash
grep -n "minSdk" example/android/app/build.gradle.kts
grep -n "IPHONEOS_DEPLOYMENT_TARGET" example/ios/Runner.xcodeproj/project.pbxproj | sort -u
```

Expected: Android inherits `flutter.minSdkVersion` (24 on Flutter 3.47); iOS shows `15.0`. If either differs from the spec's support matrix, **stop and report** — the spec's derivation rule, not the generated value, is what must be corrected.

- [ ] **Step 3: Replace `example/pubspec.yaml`**

```yaml
name: flutter_sdk_base_example
description: "Host application demonstrating flutter_sdk_base through its public API only."
publish_to: none
version: 0.1.0

environment:
  sdk: ">=3.13.0 <4.0.0"
  flutter: ">=3.47.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_sdk_base:
    path: ../

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
```

- [ ] **Step 4: Create `example/analysis_options.yaml`**

`implementation_imports` lives here, not in the package: the lint fires at the import site.

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

formatter:
  trailing_commas: preserve
  page_width: 120

linter:
  rules:
    - always_use_package_imports
    - implementation_imports
    - prefer_single_quotes
```

- [ ] **Step 5: Replace `example/lib/main.dart`**

This is the consumer-shaped proof: it imports the barrels only, maps `failure.code` to its own copy, and closes the client in `dispose`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'flutter_sdk_base example',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF1E56A0), useMaterial3: true),
        home: const HealthPage(),
      );
}

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  // A real host points this at its own API and supplies a real key. The fake
  // transport keeps this example runnable with no backend.
  late final FakeSdkHttpTransport _transport = FakeSdkHttpTransport();
  late final SdkClient _sdk = SdkClient(
    config: SdkConfig(
      baseUri: Uri.parse('https://api.example.com'),
      apiKey: 'example-key',
    ),
    transport: _transport,
  );

  String _message = 'Tap check to call the SDK.';
  bool _isBusy = false;

  @override
  void dispose() {
    _sdk.close();
    super.dispose();
  }

  Future<void> _check({required int statusCode, required String body}) async {
    setState(() {
      _isBusy = true;
    });
    _transport.enqueueJson(body, statusCode: statusCode);

    try {
      final SdkHealth health = await _sdk.health.check();
      setState(() => _message = 'API reports "${health.status}" at ${health.checkedAt}.');
    } on SdkException catch (error) {
      setState(() => _message = _copyFor(error.failure));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  // Host-owned copy. The SDK deliberately never produces user-facing text.
  String _copyFor(SdkFailure failure) => switch (failure.code) {
        SdkErrorCodes.unauthorized => 'Your API key was rejected.',
        SdkErrorCodes.rateLimited => 'Too many requests — try again shortly.',
        SdkErrorCodes.server => 'The service is having trouble. Try again.',
        SdkErrorCodes.timeout => 'That took too long. Check your connection.',
        SdkErrorCodes.transport => 'We could not reach the service.',
        _ => 'Something went wrong (${failure.code}).',
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('SDK health')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(_message, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isBusy ? null : () => _check(statusCode: 200, body: '{"status":"ok"}'),
                  child: const Text('Check health'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isBusy ? null : () => _check(statusCode: 401, body: '{}'),
                  child: const Text('Simulate rejected key'),
                ),
              ],
            ),
          ),
        ),
      );
}
```

- [ ] **Step 6: Verify the example builds and respects the boundary**

```bash
cd example && flutter pub get && flutter analyze --fatal-infos && cd ..
! grep -rn "package:flutter_sdk_base/src/" example/lib || (echo "EXAMPLE REACHES INTO src/"; exit 1)
```

Expected: `No issues found!` and no grep match.

- [ ] **Step 7: Commit**

```bash
git add example
git commit -m "feat(example): add a fresh host consuming only the public barrels

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 12: CI gates

**Files:**
- Modify: `.github/workflows/ci.yml`
- Create: `tool/check_boundaries.sh`

- [ ] **Step 1: Create `tool/check_boundaries.sh`**

```bash
#!/bin/sh
set -eu

fail=0

if grep -rn "package:flutter/material.dart\|package:flutter/widgets.dart\|package:flutter/services.dart" lib/; then
  echo "BOUNDARY: lib/ must not import Flutter UI libraries"
  fail=1
fi

if grep -rn "dart:io" lib/; then
  echo "BOUNDARY: lib/ must not import dart:io"
  fail=1
fi

if grep -rn "package:flutter_sdk_base/src/" example/lib/; then
  echo "BOUNDARY: example/ must not import package internals"
  fail=1
fi

if grep -rn "^import '\.\./\|^import '\.\./\.\./" example/lib/; then
  echo "BOUNDARY: example/ must not use relative imports into the package"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "boundary ok"
fi

exit "$fail"
```

```bash
chmod +x tool/check_boundaries.sh && ./tool/check_boundaries.sh
```

Expected: `boundary ok`.

- [ ] **Step 2: Replace `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:

env:
  FLUTTER_VERSION: 3.47.2

jobs:
  package:
    name: Package gates
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze --fatal-infos
      - run: ./tool/check_boundaries.sh
      - run: flutter test --coverage
      - run: flutter pub publish --dry-run

  example-from-archive:
    name: Example builds from the publishable archive
    runs-on: ubuntu-latest
    needs: package
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
      - name: Pack the publishable archive and resolve the example against it
        run: |
          set -eux
          flutter pub get
          # --dry-run lists exactly what would ship; build the same set as a tarball.
          mkdir -p /tmp/pkg
          git ls-files | tar -czf /tmp/package.tar.gz -T -
          tar -xzf /tmp/package.tar.gz -C /tmp/pkg
          rm -rf /tmp/pkg/example
          cd example
          # Point at the extracted snapshot instead of the working tree.
          sed -i 's|path: ../|path: /tmp/pkg|' pubspec.yaml
          flutter pub get
          flutter analyze --fatal-infos
          flutter build apk --debug

  android:
    name: Android host (minSdk 24)
    runs-on: ubuntu-latest
    needs: package
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
      - run: flutter pub get
      - working-directory: example
        run: |
          set -eux
          flutter pub get
          grep -q "flutter.minSdkVersion" android/app/build.gradle.kts
          flutter build apk --debug

  ios:
    name: iOS host (deployment target 15.0)
    runs-on: macos-latest
    needs: package
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
      - run: flutter pub get
      - working-directory: example
        run: |
          set -eux
          flutter pub get
          grep -q "IPHONEOS_DEPLOYMENT_TARGET = 15.0" ios/Runner.xcodeproj/project.pbxproj
          flutter build ios --debug --no-codesign
```

- [ ] **Step 3: Run the full local gate**

```bash
cd /Users/thanhng224/Dev/Personal/GitHub/FlutterSdkBase
make ci && ./tool/check_boundaries.sh
```

Expected: format-check silent; `No issues found!`; `boundary ok`; every test passes; `Package has 0 warnings.`

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml tool/check_boundaries.sh
git commit -m "ci: add boundary, publish dry-run, archive-consumer and platform gates

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 13: Replace the inherited documentation

The app-era docs in `docs/` describe Riverpod, Freezed, and feature modules that no longer exist. Leaving them is worse than having no docs.

**Files:**
- Rewrite: `docs/ARCHITECTURE.md`, `docs/STANDARD.md`
- Delete: `docs/CORE_MODULES.md`, `docs/FEATURE_TEMPLATE.md`
- Modify: `CLAUDE.md`, `AGENTS.md`
- Keep unchanged: `docs/GIT_FLOW.md`, `docs/superpowers/`

- [ ] **Step 1: Delete the app-only documents**

```bash
git rm --quiet docs/CORE_MODULES.md docs/FEATURE_TEMPLATE.md
```

- [ ] **Step 2: Replace `docs/ARCHITECTURE.md`**

```markdown
# Architecture

`flutter_sdk_base` is a Flutter package with no native code. It has three rules.

## 1. Everything is behind a barrel

`lib/flutter_sdk_base.dart` and `lib/flutter_sdk_base_testing.dart` are the only
supported API. Everything else lives under `lib/src/` and may change in any
release. A new public type is added by exporting it explicitly with `show`.

## 2. The core owns no host concerns

`lib/src/` may import `package:flutter/foundation.dart` and nothing else from
Flutter. No `BuildContext`, widgets, theming, routing, Riverpod, or persistence.
No `dart:io`. No mutable static state — several `SdkClient` instances must run
side by side.

## 3. One path through the SDK

Every request goes through `SdkRequestExecutor`. It applies authentication, the
timeout, cancellation, logging, and the failure-mapping table. A capability such
as `SdkHealthService` builds a request and interprets a response; it never
invents its own error handling or retry policy.

```
SdkClient ──► SdkRequestExecutor ──► SdkHttpTransport ──► (package:http)
                    │
                    ├── authHeaders()      apiKey, redacted in every log
                    ├── timeout + cancel   best-effort
                    └── failureForStatus() the single error table
```

## Adding a capability

1. Add `lib/src/<capability>/` with a value type and a service.
2. Give the service an `@internal` constructor taking the executor and config.
3. Build the request with `SdkUri.join` and `executor.authHeaders()`.
4. Map non-2xx through `failureForStatus`; map unparseable 2xx to
   `SdkErrorCodes.invalidResponse`.
5. Expose it from `SdkClient` and export it from the barrel with `show`.
6. Add the error codes it introduces to `SdkErrorCodes` and `CHANGELOG.md`.
```

- [ ] **Step 3: Replace `docs/STANDARD.md`**

```markdown
# Standards

## Public API

- Every public type is prefixed `Sdk`.
- Every public member carries a doc comment (`public_member_api_docs` is on).
- Barrels export with `show`, never bare.
- Public signatures never mention `package:http`, Dio, `fpdart`, or Freezed types.

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
```

- [ ] **Step 4: Update `CLAUDE.md` and `AGENTS.md`**

Replace the routing table in both files so it points at documents that exist:

```markdown
| Read this for... | File |
| --- | --- |
| Layer boundaries, the request path, adding a capability | `docs/ARCHITECTURE.md` |
| Public API, error, logging and test rules | `docs/STANDARD.md` |
| The authoritative design decisions and their rationale | `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md` |
| Branching and commit conventions | `docs/GIT_FLOW.md` |
```

And replace the Commands section in both with:

```markdown
## Commands
- **Analyze:** `make analyze` (must report 0 issues)
- **Test:** `make test`
- **Full local gate:** `make verify`
- **CI-equivalent:** `make ci`
- **Single test:** `flutter test test/path/to/test_file.dart`
```

Delete any remaining reference to `make codegen`, Riverpod, Freezed, or feature modules from both files.

- [ ] **Step 5: Verify no document references a deleted file**

```bash
cd /Users/thanhng224/Dev/Personal/GitHub/FlutterSdkBase
! grep -rn "CORE_MODULES\|FEATURE_TEMPLATE\|make codegen\|Riverpod\|Freezed" CLAUDE.md AGENTS.md docs/*.md \
  || (echo "STALE DOC REFERENCE"; exit 1)
echo "docs consistent"
```

Expected: `docs consistent`.

- [ ] **Step 6: Commit**

```bash
git add -A docs CLAUDE.md AGENTS.md
git commit -m "docs: replace app-era documentation with SDK architecture and standards

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Final verification

Run every gate from a clean checkout before declaring the migration done.

```bash
cd /Users/thanhng224/Dev/Personal/GitHub/FlutterSdkBase
rm -rf .dart_tool example/.dart_tool
make ci
./tool/check_boundaries.sh
cd example && flutter pub get && flutter analyze --fatal-infos && cd ..
```

Expected, all of it: formatting clean, `No issues found!` for both package and
example, `boundary ok`, every test green, `Package has 0 warnings.`

Then confirm by hand, because CI cannot:

- [ ] `grep -rn "http\." lib/ --include=*.dart | grep -v package_http_transport` returns nothing — only one file knows the HTTP library.
- [ ] `lib/flutter_sdk_base.dart` exports exactly the 13 types the spec lists, no more.
- [ ] `README.md` states that cancellation is best-effort.
- [ ] The support matrix in `README.md`, `pubspec.yaml`, and the spec agree.
