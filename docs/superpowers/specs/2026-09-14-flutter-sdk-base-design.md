# Flutter SDK Base Design

**Status:** Proposed — requires user review before implementation

**Goal:** Transform Flutter Core Base into a publishable Flutter SDK template that demonstrates a small, clean HTTP capability while remaining independent of host navigation, UI, state management, persistence, and native code.

**Package identity:** `flutter_sdk_base` (`Flutter SDK Base`)

## 1. Product Scope

This repository is a template that teams clone before implementing their own SDK. It is a **Flutter package without custom native code**, not a Dart-only package and not a Flutter plugin.

The v1 reference vertical slice is a health capability:

```dart
final sdk = SdkClient(
  config: SdkConfig(baseUri: Uri.parse('https://api.example.com')),
);

final health = await sdk.health.check();
await sdk.close();
```

`SdkHealthService.check()` performs `GET /health` and maps a successful JSON response such as `{"status":"ok"}` to `SdkHealth`. It exists solely to show a complete public-contract → transport → error → host-test path. A product team replaces this service and its endpoint when cloning the base.

### In scope

- A Flutter package that may import `package:flutter/foundation.dart` only from Flutter.
- A public, instance-based client with a built-in HTTP implementation hidden behind SDK-owned transport value types.
- Safe logging, typed failures wrapped in exceptions, cancellation, timeout, multiple concurrent client instances, a fake transport, and a consumer example.
- Android and iOS support for the package's v1 release.

### Explicitly out of scope

- Kotlin, Swift, FFI, `MethodChannel`, `EventChannel`, a plugin, or federated plugin packages.
- `BuildContext`, widgets, `MaterialApp`, theming, localization, GoRouter, Riverpod, screens, or app-wide singletons in SDK core.
- Persistence, token caching, session resume, connectivity preflight checks, automatic retry, uploads, multipart, streaming bodies, and Web or desktop support claims.
- Business APIs beyond the reference health slice.

Web and desktop must remain compilable when package dependencies allow it, but are untested and unsupported in v1. Browser CORS and credential semantics must not be represented as an SDK support promise before the product backend commits to them.

## 2. Support and Compatibility Policy

The package declares these floors:

| Surface | v1 commitment |
| --- | --- |
| Dart | `>=3.13.0 <4.0.0` |
| Flutter | `>=3.47.0 <4.0.0` |
| Android host | API 21 or higher |
| iOS host | iOS 14.0 or higher |
| Supported release platforms | Android and iOS |

The root package contains no Android or iOS runner. The `example/` host carries these deployment floors and CI must build it for both supported platforms. A package implementation must not use `dart:io` or platform-specific APIs.

Semantic versioning is mandatory from the first released version:

- Only declarations exported by `lib/flutter_sdk_base.dart` and `lib/flutter_sdk_base_testing.dart` are supported public API.
- `lib/src/` is implementation detail and has no compatibility guarantee.
- Removing or changing a public API, changing or removing an `SdkErrorCodes` value, or raising a support floor is a breaking change.
- Adding a documented API or a new error code is non-breaking.
- A deprecated public API remains supported for at least one minor release and the replacement plus removal target are recorded in `CHANGELOG.md`.
- Each release updates `CHANGELOG.md` with user-visible API, behavior, dependency, and support-matrix changes.

## 3. Package Boundary and Layout

The package moves all implementation below `lib/src/`; consumers import only public barrel files.

```text
lib/
├── flutter_sdk_base.dart             # supported production facade
├── flutter_sdk_base_testing.dart     # supported fake/test helpers
└── src/
    ├── client/
    │   ├── sdk_client.dart
    │   └── sdk_config.dart
    ├── health/
    │   ├── sdk_health.dart
    │   └── sdk_health_service.dart
    ├── transport/
    │   ├── sdk_http_call.dart
    │   ├── sdk_http_request.dart
    │   ├── sdk_http_response.dart
    │   ├── sdk_http_transport.dart
    │   └── package_http_transport.dart
    ├── errors/
    │   ├── sdk_error_codes.dart
    │   ├── sdk_exception.dart
    │   └── sdk_failure.dart
    └── logging/
        ├── sdk_log_level.dart
        ├── sdk_logger.dart
        └── silent_sdk_logger.dart
example/                              # independent Flutter host app
test/
docs/
```

`flutter_sdk_base.dart` exports `SdkClient`, `SdkConfig`, `SdkHealthService`, `SdkHealth`, `SdkHttpTransport`, `SdkHttpCall`, `SdkHttpRequest`, `SdkHttpResponse`, `SdkLogger`, `SdkLogLevel`, `SdkFailure`, `SdkException`, and `SdkErrorCodes`. The testing barrel exports `FakeSdkHttpTransport` and its deterministic response handler only.

`lib/src/` may import `package:flutter/foundation.dart` for `kDebugMode`, `debugPrint`, and `@visibleForTesting`. It must not import `package:flutter/material.dart`, `package:flutter/widgets.dart`, or `package:flutter/services.dart`.

## 4. Public Contract

All public type names use the `Sdk` prefix to avoid collisions with host app types such as Flutter's `PlatformException`.

```dart
final class SdkClient {
  SdkClient({
    required SdkConfig config,
    SdkHttpTransport? transport,
    SdkLogger? logger,
  });

  SdkHealthService get health;

  Future<void> close();
}

final class SdkConfig {
  const SdkConfig({
    required this.baseUri,
    this.requestTimeout = const Duration(seconds: 15),
  });

  final Uri baseUri;
  final Duration requestTimeout;
}

final class SdkHealthService {
  Future<SdkHealth> check();
}

final class SdkHealth {
  const SdkHealth({
    required this.isHealthy,
    required this.status,
    required this.checkedAt,
  });

  final bool isHealthy;
  final String status;
  final DateTime checkedAt;
}
```

Public operations return their success value and throw `SdkException` for expected runtime failures. The SDK never mixes `SdkResult<T>` and thrown failures. Every public operation documents its `SdkException` behavior with `@throws`.

Calling an operation on a client after `close()` throws `StateError`; this is host programming misuse, not a recoverable SDK failure. A client can run multiple operations concurrently. Multiple `SdkClient` instances may also run concurrently with distinct configuration and transports; no mutable static state is permitted.

## 5. Errors and Logging

```dart
final class SdkFailure {
  const SdkFailure({
    required this.code,
    required this.message,
    required this.isRetryable,
    this.statusCode,
    this.cause,
  });

  final String code;
  final String message;
  final bool isRetryable;
  final int? statusCode;
  final Object? cause;
}

final class SdkException implements Exception {
  const SdkException(this.failure);

  final SdkFailure failure;
}

abstract final class SdkErrorCodes {
  static const String cancelled = 'cancelled';
  static const String timeout = 'timeout';
  static const String transport = 'transport';
  static const String server = 'server';
  static const String rateLimited = 'rate_limited';
  static const String invalidResponse = 'invalid_response';
}
```

`message` is concise English diagnostic text for developers. It is never localized or intended for end-user UI. Hosts map `code` to their own copy. `cause` is diagnostic-only: its type and contents have no compatibility guarantee and hosts must not use it for control flow.

The SDK calculates `isRetryable` consistently: transport failures, HTTP 429, and HTTP 5xx are `true`; other HTTP 4xx and malformed successful responses are `false`. The SDK never retries automatically.

```dart
abstract interface class SdkLogger {
  void log(
    SdkLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}
```

Logging is no-op by default. A host may inject `SdkLogger`; SDK logs must omit credentials, headers, request/response bodies, and other sensitive values before calling it. Existing redaction utilities and silent/debug sink concepts may be reused internally, but `Redacted`, log records, and sinks are not public API.

## 6. HTTP Transport, Timeout, and Lifecycle

The public transport boundary contains no Dio or `package:http` types:

```dart
abstract interface class SdkHttpTransport {
  SdkHttpCall open(SdkHttpRequest request);
}

abstract interface class SdkHttpCall {
  Future<SdkHttpResponse> get response;
  Future<void> cancel();
}

final class SdkHttpRequest {
  const SdkHttpRequest({
    required this.method,
    required this.uri,
    required this.headers,
    this.body,
  });

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final Uint8List? body;
}

final class SdkHttpResponse {
  const SdkHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Uint8List body;
}
```

The sole v1 body representation is bytes. There is no file upload, multipart, stream, or streaming response support. Adding one later requires a deliberate, versioned contract extension rather than widening this reference slice accidentally.

`package:http: ^1.0.0` is the internal default transport implementation. It is never mentioned by a public signature, and a host can inject a custom `SdkHttpTransport`. A transport supplied to `SdkClient` is owned by that client and must support cancellation through `SdkHttpCall.cancel()`.

The SDK, not the transport, enforces `SdkConfig.requestTimeout`: on timeout it calls `cancel()` and throws `SdkException` with `SdkErrorCodes.timeout`. A transport must complete cancellation promptly; the SDK maps a cancellation caused by `close()` to `SdkErrorCodes.cancelled` for the affected in-flight operations.

`close()` is idempotent. It rejects new calls with `StateError`, calls `cancel()` for every active `SdkHttpCall`, waits for their cancellation/teardown, and then completes. It neither persists state nor retries or restarts those operations.

## 7. Persistence and Connectivity Rules

v1 has no persistence contract or plugin dependency. It does not cache tokens, retain credentials, persist configuration, or resume a session after an app restart. A host recreates `SdkClient` and supplies current configuration whenever needed.

`shared_preferences`, `flutter_secure_storage`, and `connectivity_plus` are removed. In particular, preflight connectivity checks are prohibited: network state is inherently racy and does not prove the API is reachable. The SDK performs the request and maps the observed failure.

If a future product capability demonstrably requires persistence, it first introduces an SDK-owned injectable contract. It must not add a storage plugin as a hidden global dependency.

## 8. Consumer-First Example and Test Doubles

The `example/` Flutter app is an independent host, not an SDK-owned UI. It imports `package:flutter_sdk_base/flutter_sdk_base.dart`; it must never import `lib/src/` or use a relative import into the package.

Its initial flow creates a client, calls `sdk.health.check()`, renders a host-owned result, handles `SdkException` by mapping its `failure.code` to host copy, and calls `close()` during teardown. The example uses `FakeSdkHttpTransport` so it remains deterministic without a real backend.

The fake provides queued or handler-defined `SdkHttpResponse`/failure behavior and records SDK-owned requests. It supports tests of status mapping, timeout, cancellation, multiple instances, and no request after close. It is a supported testing helper, not a production transport.

## 9. Migration Boundaries

The clone is initialized with the existing quick-start script solely to establish the new project identity. The SDK migration then removes app-only artifacts:

- `lib/main.dart`, `lib/app/`, `lib/features/`, `lib/l10n/`, `lib/core/routing/`, `lib/core/theme/`, `lib/core/widgets/`, settings/config controllers, app storage providers, app network providers, and all generated files coupled to them.
- Android, iOS, macOS, Windows, Linux, Web, branding assets, flavor configuration, application launchers, `init_project.py`, and app deployment workflows move out of the package root. The new `example/` becomes the only Flutter application and owns its platform folders.
- `flutter_riverpod`, `riverpod_annotation`, `go_router`, `dio`, `fpdart`, `freezed`, `json_serializable`, storage/connectivity plugins, fonts, animation, launcher icon, splash, localization, and their generators are removed unless a later public SDK requirement proves one is necessary.

The retained ideas are strict analysis, focused tests, release-safe logging/redaction, error mapping, documentation discipline, and CI. The following existing code is candidate source material only and must be adapted behind the new contracts: `lib/core/logging/`, `lib/core/errors/`, `lib/core/utils/redaction.dart`, and the current network tests. No app-specific type crosses the new public boundary.

Existing app architecture, standards, core-module, and feature-template documents are replaced during migration with SDK-focused versions. This design document is authoritative for the transition where it conflicts with current app documentation.

## 10. Quality and Release Gates

The migration replaces application gates with package gates:

1. `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos`, and `flutter test` pass.
2. Analyzer enables strict inference/casts/raw types, `public_member_api_docs`, and `implementation_imports`.
3. A repository check fails if a file under `lib/src/` imports `flutter/material.dart`, `flutter/widgets.dart`, or `flutter/services.dart`.
4. A repository check fails if `example/` imports `package:flutter_sdk_base/src/` or uses a relative import into package source.
5. `flutter pub publish --dry-run` passes. The workflow never runs a real publish command.
6. CI creates an isolated archive snapshot of the package, exposes it through a temporary Git dependency, and builds/tests the example against that snapshot rather than a path dependency. This proves the example consumes only the public artifact surface.
7. CI builds the example Android host with `minSdk 21`; a macOS CI job builds the iOS host with deployment target 14.0. Both jobs use the declared Flutter floor.

`README.md` describes installation, minimal usage, error handling, lifecycle, support matrix, and the testing barrel. `CHANGELOG.md`, `LICENSE`, public API docs, and compatibility policy are release requirements, not deferred polish.

## 11. Implementation Order

Implementation must be consumer-first:

1. Replace app-oriented package metadata and root documentation with SDK metadata and the compatibility policy.
2. Write public barrel declarations, their API documentation, and example integration code before porting any app implementation.
3. Write failing consumer and unit tests for the facade, exception contract, transport mapping, timeout, cancellation, close behavior, multiple instances, and fake transport.
4. Implement SDK-owned contracts and the internal `package:http` transport under `lib/src/`.
5. Remove app concerns and dependencies; move the independent host into `example/`.
6. Add boundary, publish dry-run, isolated-artifact consumer, Android, and iOS CI gates.
7. Run every release gate and review the public API as a consumer before a `1.0.0` release.

No implementation begins until this document is reviewed and approved.
