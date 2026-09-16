# Flutter SDK Base Design

**Status:** Approved — reviewed 2026-09-14, amended, cleared for implementation

**Review amendments (2026-09-14).** Applied after review; each resolves a defect in the Proposed draft.

1. **Cancellation is best-effort and says so.** The draft promised prompt cancellation that `package:http` cannot deliver (§6).
2. **Platform floors are derived, not picked.** The draft's Android API 21 and iOS 14.0 matched neither Flutter 3.47 nor the repo; the real values are 24 and 15.0 (§2).
3. **Error taxonomy covers non-429 4xx.** The draft had no code for 401/403/404, so they would have collapsed into `server` (§5).
4. **The reference slice authenticates safely.** The draft carried no credential; `SdkConfig.apiKey` makes the event-safety invariant testable (§1, §4, §5).
5. `SdkHttpTransport` gained `close()` — the client owns the transport and had no way to release it (§6).
6. `example/` is generated fresh, never migrated, and owns the `implementation_imports` lint (§8, §9, §10).
7. The artifact-consumer gate uses an extracted archive instead of a temporary Git dependency (§10).
8. `SdkHealth.checkedAt` gained an internal clock seam so the fake transport is genuinely deterministic (§4).
9. Operations may be cancelled independently through an SDK-owned `SdkCancelToken`; cancellation remains best-effort and does not close the client (§4, §6).
10. Every request carries stable SDK-version and per-request correlation headers; failures retain the request ID for host support workflows (§5, §6).
11. The public value types define equality now, before hosts depend on field-by-field assertions (§4, §5).

**Goal:** Transform Flutter Core Base into a publishable Flutter SDK template that demonstrates a small, clean HTTP capability while remaining independent of host navigation, UI, state management, persistence, and native code.

**Package identity:** `flutter_sdk_base` (`Flutter SDK Base`)

## 1. Product Scope

This repository is a template that teams clone before implementing their own SDK. It is a **Flutter package without custom native code**, not a Dart-only package and not a Flutter plugin.

The v1 reference vertical slice is a health capability:

```dart
final sdk = SdkClient(
  config: SdkConfig(
    baseUri: Uri.parse('https://api.example.com'),
    apiKey: hostSuppliedKey,
  ),
);

final health = await sdk.health.check();
await sdk.close();
```

`SdkHealthService.check()` performs `GET /health` and maps a successful JSON response such as `{"status":"ok"}` to `SdkHealth`. It exists solely to show a complete public-contract → transport → error → host-test path. A product team replaces this service and its endpoint when cloning the base.

### In scope

- A Flutter package that may import `package:flutter/foundation.dart` only from Flutter.
- A public, instance-based client with a built-in HTTP implementation hidden behind SDK-owned transport value types.
- Host-supplied API-key authentication applied to every request, with safe structured operation events that never contain the key.
- Silent-by-default operation observation, typed failures wrapped in exceptions, best-effort cancellation, timeout, multiple concurrent client instances, a fake transport, and a consumer example.
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
| Flutter | `>=3.47.0` (no upper bound) |
| Android host | API 24 or higher |
| iOS host | iOS 15.0 or higher |
| Supported release platforms | Android and iOS |

The root `pubspec.yaml` declares exactly `android` and `ios` under `platforms:`.
This keeps pub.dev's platform metadata aligned with the Android/iOS support
commitment; web and desktop remain unsupported release targets.

The Flutter constraint deliberately carries **no upper bound**. Pub deprecates upper bounds on the Flutter SDK constraint (`dart.dev/go/flutter-upper-bound-deprecation`) and `pub publish` warns on one; a `<4.0.0` here would also lock hosts out of a future major for no demonstrated incompatibility. The Dart constraint keeps its `<4.0.0` — that form is conventional and draws no warning.

`docs/` holds this specification, the implementation plan, and internal engineering notes. None of it belongs in the published archive, so a root `.pubignore` containing `docs/` excludes it. This is not a workaround for pub's "rename `docs` to `doc`" warning: the directory is genuinely internal, and excluding it also keeps the archive small. Verified empirically — with `.pubignore` in place and no Flutter upper bound, `flutter pub publish --dry-run` reports `Package has 0 warnings.`

The Android and iOS floors are **derived from the declared Flutter floor, not chosen independently**. For Flutter 3.47 they are read from `packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt` (`minSdkVersion = 24`) and the `flutter create` iOS template (`IPHONEOS_DEPLOYMENT_TARGET = 15.0`). Raising the Flutter floor re-derives both numbers; neither may be hand-picked. The `ios/` folder inherited from the app base declares 13.0 and is stale — it is deleted rather than corrected, because `example/` is generated fresh.

The root package contains no Android or iOS runner. The `example/` host carries these deployment floors and CI must build it for both supported platforms. A package implementation must not use `dart:io` or platform-specific APIs; package tests may, because they never ship.

The package is pre-1.0 and under active development. Semantic-version-style
release labels are still useful, but API compatibility is not a promise yet:

- Only declarations exported by `lib/flutter_sdk_base.dart` and `lib/flutter_sdk_base_testing.dart` are supported public API.
- `lib/src/` is implementation detail and has no compatibility guarantee.
- Removing or changing a public API, changing or removing an `SdkErrorCodes` value,
  or raising a support floor may be done between pre-1.0 releases when it
  improves the long-term design. Such changes must be recorded in
  `CHANGELOG.md`.
- Additive changes are preferred, but no deprecation-duration guarantee is
  made before the first stable release.
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
    │   ├── sdk_cancel_token.dart
    │   ├── sdk_config.dart
    │   └── sdk_request_executor.dart
    ├── version/
    │   └── sdk_version.dart
    ├── health/
    │   ├── sdk_health.dart
    │   └── sdk_health_service.dart
    ├── transport/
    │   ├── fake_sdk_http_transport.dart
    │   ├── sdk_http_call.dart
    │   ├── sdk_http_request.dart
    │   ├── sdk_http_response.dart
    │   ├── sdk_http_transport.dart
    │   └── package_http_transport.dart
    ├── errors/
    │   ├── sdk_error_codes.dart
    │   ├── sdk_exception.dart
    │   ├── sdk_failure.dart
    │   └── sdk_status_mapping.dart
    ├── logging/
    │   ├── sdk_observer.dart
    │   └── sdk_operation_event.dart
    └── util/
        └── sdk_uri.dart
example/                              # independent Flutter host app
test/
docs/
```

`flutter_sdk_base.dart` exports `SdkClient`, `SdkCancelToken`, `SdkConfig`, `SdkHealthService`, `SdkHealth`, `SdkHttpTransport`, `SdkHttpCall`, `SdkHttpRequest`, `SdkHttpResponse`, `SdkObserver`, `SdkOperationEvent`, `SdkOperationOutcome`, `SdkFailure`, `SdkException`, `SdkErrorCodes`, and the `sdkVersion` constant. The testing barrel exports `FakeSdkHttpTransport` only. Its deterministic behaviour is configured through that class's own methods; no separate handler type is exported.

`lib/src/` may import `package:flutter/foundation.dart` for `kDebugMode`, `debugPrint`, and `@visibleForTesting`. It must not import `package:flutter/material.dart`, `package:flutter/widgets.dart`, or `package:flutter/services.dart`.

## 4. Public Contract

All public type names use the `Sdk` prefix to avoid collisions with host app types such as Flutter's `PlatformException`.

```dart
final class SdkClient {
  SdkClient({
    required SdkConfig config,
    SdkHttpTransport? transport,
    SdkObserver? observer,
  });

  SdkHealthService get health;

  Future<void> close();
}

final class SdkConfig {
  const SdkConfig({
    required this.baseUri,
    required this.apiKey,
    this.requestTimeout = const Duration(seconds: 15),
  });

  final Uri baseUri;
  final String apiKey;
  final Duration requestTimeout;
}

/// The package version sent in `X-Sdk-Version` on every request.
const String sdkVersion = '0.1.0';

final class SdkCancelToken {
  /// Cancels operations using this token. Idempotent.
  void cancel();

  /// Whether [cancel] has been called.
  bool get isCancelled;
}

final class SdkHealthService {
  /// Cancellation is best-effort: it stops the SDK waiting but cannot prove
  /// that the server did not receive the request.
  Future<SdkHealth> check({SdkCancelToken? cancelToken});
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

`sdkVersion` is required to match the root `pubspec.yaml` version exactly; a
package test reads that declaration so the wire header cannot drift from the
published package metadata.

`SdkCancelToken` is SDK-owned; it does not expose a transport-library type. A
host normally creates one token per operation. Reusing one token deliberately
groups those operations: cancelling it cancels every in-flight operation that
uses it. Cancelling before an operation starts produces the same
`SdkErrorCodes.cancelled` failure without opening a transport call. Cancelling
an operation never closes the `SdkClient`, so independent operations and later
requests remain usable.

`SdkConfig`, `SdkHealth`, and `SdkFailure` are value types. Their `==` and
`hashCode` cover their stable public fields. `SdkFailure.cause` is explicitly
excluded because it is diagnostic-only and has no compatibility guarantee.
For `SdkFailure`, those stable fields are `code`, `message`, `isRetryable`,
`statusCode`, and `requestId`.

`SdkHealth.checkedAt` is the moment the SDK observed the response. The clock is an internal seam (`DateTime Function()`) injected through an `@internal`-annotated constructor so package tests can freeze it. `SdkClient`'s public constructor exposes no clock parameter, and the analyzer flags any host that reaches for the internal one.

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
    required this.requestId,
    this.cause,
  });

  final String code;
  final String message;
  final bool isRetryable;
  final int? statusCode;
  final String requestId;
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
  static const String unauthorized = 'unauthorized';
  static const String client = 'client';
  static const String rateLimited = 'rate_limited';
  static const String server = 'server';
  static const String invalidResponse = 'invalid_response';
}
```

`message` is concise English diagnostic text for developers. It is never localized or intended for end-user UI. Hosts map `code` to their own copy. `cause` is diagnostic-only: its type and contents have no compatibility guarantee and hosts must not use it for control flow.

The SDK maps every outcome through one table, so `code` and `isRetryable` are never decided ad hoc at a call site:

| Outcome | `code` | `isRetryable` |
| --- | --- | --- |
| Transport/socket failure | `transport` | `true` |
| `SdkConfig.requestTimeout` elapsed | `timeout` | `true` |
| Cancelled by `close()` or `SdkCancelToken` | `cancelled` | `false` |
| HTTP 401 or 403 | `unauthorized` | `false` |
| HTTP 429 | `rate_limited` | `true` |
| Other HTTP 4xx | `client` | `false` |
| HTTP 5xx | `server` | `true` |
| 2xx with a body the SDK cannot parse | `invalid_response` | `false` |

The SDK never retries automatically; `isRetryable` is advice for the host.

`SdkFailure.toString()` renders `code`, `statusCode`, and `message` only. It must never render `cause`, because `cause` may carry a URI or header captured from a failing request.

Every failure produced for an SDK operation carries that operation's non-empty
`requestId`. Hosts may give it to support staff; it is not a credential and is
safe to render. A manually constructed `SdkFailure` must also supply it so new
fields do not become an optional compatibility trap later.

```dart
enum SdkOperationOutcome { succeeded, failed }

final class SdkOperationEvent {
  const SdkOperationEvent({
    required this.operation,
    required this.requestId,
    required this.sdkVersion,
    required this.outcome,
    required this.elapsed,
    this.statusCode,
    this.failureCode,
    this.isRetryable,
  });

  final String operation;
  final String requestId;
  final String sdkVersion;
  final SdkOperationOutcome outcome;
  final Duration elapsed;
  final int? statusCode;
  final String? failureCode;
  final bool? isRetryable;
}

abstract interface class SdkObserver {
  void onOperation(SdkOperationEvent event);
}
```

Operation observation is no-op by default. A host may inject `SdkObserver`; the
executor emits exactly one terminal `SdkOperationEvent` per public operation.
Success events have null `failureCode` and `isRetryable`; failures have both.
The SDK swallows observer exceptions. Events contain only operation metadata,
and never credentials, URI/path/query, headers, bodies, raw exceptions, or
stack traces. `SdkFailure.cause` remains only on the thrown failure.

## 6. HTTP Transport, Timeout, and Lifecycle

The public transport boundary contains no Dio or `package:http` types:

```dart
abstract interface class SdkHttpTransport {
  SdkHttpCall open(SdkHttpRequest request);

  Future<void> close();
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

  /// The body decoded as UTF-8, tolerating malformed bytes.
  String get bodyAsString;
}
```

The sole v1 body representation is bytes. There is no file upload, multipart, stream, or streaming response support. Adding one later requires a deliberate, versioned contract extension rather than widening this reference slice accidentally.

`package:http: ^1.0.0` is the internal default transport implementation. It is never mentioned by a public signature, and a host can inject a custom `SdkHttpTransport`. A transport supplied to `SdkClient` is owned by that client: the client calls `SdkHttpTransport.close()` during its own `close()`, so a host must not reuse one transport instance across clients.

**Cancellation is best-effort, and this is a documented public promise, not an implementation detail.** `package:http` has no per-request abort: `Client.close()` tears down every request sharing that client. `SdkHttpCall.cancel()` therefore means *the SDK stops waiting* — the pending operation completes with `SdkErrorCodes.cancelled` and the response is discarded — while the underlying socket may remain open until the server replies. A host must not read `cancel()` as a guarantee that the server did not receive or process the request. This is stated in the `SdkHttpCall.cancel()` API doc and in `README.md`. The alternative, one `http.Client` per request, was rejected: it would cost a fresh TCP and TLS handshake on every call, which is the wrong trade on mobile.

The SDK, not the transport, enforces `SdkConfig.requestTimeout`: on timeout it calls `cancel()` and throws `SdkException` with `SdkErrorCodes.timeout`. A transport must complete cancellation promptly; the SDK maps a cancellation caused by `close()` to `SdkErrorCodes.cancelled` for the affected in-flight operations.

Before opening every SDK request, `SdkRequestExecutor` creates a fresh 128-bit
lowercase hexadecimal request ID (32 hex characters), adds `X-Request-Id`, and adds
`X-Sdk-Version: sdkVersion`. It is the only request path, so capabilities never
invent version or correlation headers. The executor retains that ID for all
failure paths, including timeout, close, token cancellation, transport errors,
HTTP status mapping, and invalid successful bodies.

The executor emits exactly one terminal `SdkOperationEvent` for every public
operation, including pre-cancelled, timed out, transport-failed, HTTP-failed,
and invalid-response outcomes. A success event has null `failureCode` and
`isRetryable`; a failure event has both. `statusCode` is present whenever an
HTTP response existed. Observer exceptions are swallowed, and event fields
never include credentials, URI/path/query, headers, bodies, raw exceptions, or
stack traces.

Token cancellation follows the same teardown path as client close for its one
operation: it invokes `SdkHttpCall.cancel()`, maps the operation to
`SdkErrorCodes.cancelled`, and discards a late response. It does not call
`SdkHttpTransport.close()`. As with every transport cancellation, this is
best-effort and is not proof that the server did not process the request.

`close()` is idempotent. It rejects new calls with `StateError`, calls `cancel()` for every active `SdkHttpCall`, awaits those `cancel()` futures, closes the owned transport, and then completes. Awaiting `cancel()` means awaiting the SDK's own teardown, not socket termination — see the best-effort rule above. `close()` neither persists state nor retries or restarts those operations.

## 7. Persistence and Connectivity Rules

v1 has no persistence contract or plugin dependency. It does not cache tokens, retain credentials, persist configuration, or resume a session after an app restart. A host recreates `SdkClient` and supplies current configuration whenever needed.

`shared_preferences`, `flutter_secure_storage`, and `connectivity_plus` are removed. In particular, preflight connectivity checks are prohibited: network state is inherently racy and does not prove the API is reachable. The SDK performs the request and maps the observed failure.

If a future product capability demonstrably requires persistence, it first introduces an SDK-owned injectable contract. It must not add a storage plugin as a hidden global dependency.

## 8. Consumer-First Example and Test Doubles

The `example/` Flutter app is an independent host, not an SDK-owned UI. **It is generated fresh with `flutter create`, never migrated from the existing app.** Moving the inherited host would drag `home_screen`, `settings`, `l10n`, and theming back in — the exact concerns being removed. It imports `package:flutter_sdk_base/flutter_sdk_base.dart`; it must never import `lib/src/` or use a relative import into the package.

`example/` carries its own `pubspec.yaml` and its own `analysis_options.yaml`. The `implementation_imports` lint belongs in the **example's** analyzer config, not the package's: the lint fires at the import site, so enabling it only on the package would never inspect the consumer.

Its initial flow creates a client, calls `sdk.health.check()`, renders a host-owned result, handles `SdkException` by mapping its `failure.code` to host copy, and calls `close()` during teardown. The example uses `FakeSdkHttpTransport` so it remains deterministic without a real backend.

The fake provides queued or handler-defined `SdkHttpResponse`/failure behavior and records SDK-owned requests. It supports tests of status mapping, timeout, cancellation, multiple instances, and no request after close. It is a supported testing helper, not a production transport.

## 9. Migration Boundaries

The clone is initialized with the existing quick-start script solely to establish the new project identity. The SDK migration then removes app-only artifacts:

- `lib/main.dart`, `lib/app/`, `lib/features/`, `lib/l10n/`, `lib/core/routing/`, `lib/core/theme/`, `lib/core/widgets/`, settings/config controllers, app storage providers, app network providers, and all generated files coupled to them.
- Android, iOS, macOS, Windows, Linux, Web, branding assets, flavor configuration, application launchers, `init_project.py`, and app deployment workflows are **deleted** from the package root. The new `example/`, generated by `flutter create`, becomes the only Flutter application and owns freshly generated platform folders at the derived floors. Nothing is moved; the inherited platform folders carry stale deployment targets and flavor wiring.
- `flutter_riverpod`, `riverpod_annotation`, `go_router`, `dio`, `fpdart`, `freezed`, `json_serializable`, storage/connectivity plugins, fonts, animation, launcher icon, splash, localization, and their generators are removed unless a later public SDK requirement proves one is necessary.

The retained ideas are strict analysis, focused tests, safe operation observation, error mapping, documentation discipline, and CI. The following existing code is candidate source material only and must be adapted behind the new contracts: `lib/core/logging/`, `lib/core/errors/`, `lib/core/utils/redaction.dart`, and the current network tests. No app-specific type crosses the new public boundary.

Existing app architecture, standards, core-module, and feature-template documents are replaced during migration with SDK-focused versions. This design document is authoritative for the transition where it conflicts with current app documentation.

## 10. Quality and Release Gates

The migration replaces application gates with package gates:

1. `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos`, and `flutter test` pass.
2. The package analyzer enables strict inference/casts/raw types and `public_member_api_docs`. The `example/` analyzer enables `implementation_imports`.
3. A repository check fails if a file under `lib/src/` imports `flutter/material.dart`, `flutter/widgets.dart`, or `flutter/services.dart`.
4. A repository check fails if `example/` imports `package:flutter_sdk_base/src/` or uses a relative import into package source.
5. `flutter pub publish --dry-run` reports `Package has 0 warnings.`, and the package declares no `publish_to: none` that would disable it. Reaching zero requires a root `.pubignore` excluding `docs/` and a Flutter constraint with no upper bound; both are deliberate, not concessions. The workflow never runs a publish command without `--dry-run`.
6. CI packs the publishable archive, extracts it to a temporary directory, and resolves `example/` against **that extraction** instead of the working tree. This proves the example builds from only the files that would actually ship. Combined with gates 3 and 4 it replaces the heavier temporary-Git-dependency scheme: the archive proves file completeness, the lint and grep prove the example never reaches into `lib/src/`.
7. CI builds the example Android host at `minSdk 24`; a macOS CI job builds the iOS host at deployment target 15.0. Both host jobs run for the declared Flutter floor and latest stable through the matrix. If a future Flutter floor changes either derived number, this gate is what catches it.
8. CI checks the declared Flutter floor (`3.47.0`) and latest stable through a
   matrix. A support floor that is never compiled is not a compatibility
   commitment.
9. CI runs `dart doc` and Pana with no missing points. Pana is the pub.dev
   package-quality analyzer; documentation, dependency freshness, and platform
   metadata regressions must fail before publication.
10. CI does not generate coverage data without reading it. The package either
    enforces a documented coverage threshold or omits `--coverage`; v1 omits
    the unused artifact rather than presenting it as a gate.

Pana remains a global CI tool rather than a package dependency. The package
gate installs it with `dart pub global activate pana` and runs
`dart pub global run pana . --exit-code-threshold 0`; the zero-deficit
threshold does not accept a lower score. The generated API documentation gate
runs immediately before Pana so documentation and package-quality regressions
are checked together before the publish dry-run. Locally, `make doc` runs
`dart doc --validate-links`, and generated `doc/api` output remains ignored by
Git and excluded from the publish archive.

`README.md` describes installation, minimal usage, error handling, lifecycle, support matrix, and the testing barrel. `CHANGELOG.md`, `LICENSE`, public API docs, and compatibility policy are release requirements, not deferred polish.

## 11. Implementation Order

Implementation must be consumer-first:

1. Delete app concerns and dependencies, then replace app-oriented package metadata and root documentation with SDK metadata and the compatibility policy. `pubspec.yaml` takes an SDK description, version `0.1.0` (no `+build` suffix — build numbers belong to applications), and `repository` / `issue_tracker` / `homepage` fields. **`publish_to: none` is removed immediately**, because `pub publish` refuses to run at all — including `--dry-run` — on a package that declares it, and gate 5 must be live from the first commit. Removing it does not publish anything: publishing requires `flutter pub publish` without `--dry-run` plus pub.dev credentials, and CI never issues that command.
2. Write public barrel declarations, their API documentation, and example integration code before porting any app implementation.
3. Write failing consumer and unit tests for the facade, exception contract, transport mapping, timeout, cancellation, close behavior, multiple instances, and fake transport.
4. Implement SDK-owned contracts and the internal `package:http` transport under `lib/src/`.
5. Generate `example/` fresh with `flutter create` and write its integration against the public barrel only.
6. Add boundary, publish dry-run, isolated-artifact consumer, Android, and iOS CI gates.
7. Run every release gate and review the public API as a consumer before a `1.0.0` release.

No implementation begins until this document is reviewed and approved.
