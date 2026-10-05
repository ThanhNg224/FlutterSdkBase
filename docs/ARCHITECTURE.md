# Architecture

`flutter_sdk_base` is a Flutter package with no native code. It has three rules.

## 1. Everything is behind a barrel

`lib/flutter_sdk_base.dart` and `lib/flutter_sdk_base_testing.dart` are the only
supported API. Everything else lives under `lib/src/` and may change in any
release. A new public type is added by exporting it explicitly with `show`.

## 2. The core owns no host concerns

`lib/src/` may import `package:flutter/foundation.dart` and nothing else from
Flutter. No `BuildContext`, widgets, theming, routing, state management, or persistence.
No `dart:io`. No mutable static state — several `SdkClient` instances must run
side by side.

## 3. One path through the SDK

Every request goes through `SdkRequestExecutor`. It applies authentication, the
timeout, cancellation, structured operation observation, and the failure-mapping table. A capability such
as `SdkHealthService` builds a request and interprets a response; it never
invents its own error handling or retry policy.

```
SdkClient ──► SdkRequestExecutor ──► SdkHttpTransport ──► (package:http)
                    │
                    ├── authHeaders()      apiKey, never included in events
                    ├── timeout + cancel   best-effort
                    ├── cancellation + correlation headers
                    ├── terminal event    one safe event per operation
                    └── failureForStatus() the single error table
```

## Adding a capability

1. Add `lib/src/<capability>/` with a value type and a service.
2. Give the service an `@internal` constructor taking the executor and config.
3. Build the request with `SdkUri.join` and `executor.authHeaders()`.
4. Let the executor map non-2xx through `failureForStatus` and capture one
   terminal event. Decode only successful 2xx responses; map unparseable bodies
   to `SdkErrorCodes.invalidResponse`. The executor supplies the request ID to
   every failure path.
5. Expose it from `SdkClient` and export it from the barrel with `show`.
6. Add the error codes it introduces to `SdkErrorCodes` and `CHANGELOG.md`.

Per-operation cancellation is SDK-owned through `SdkCancelToken`. It is
best-effort and never closes the client; reusing one token deliberately groups
operations. The executor adds `X-Sdk-Version` and a fresh `X-Request-Id` to
every outgoing request, and capabilities retain that ID when mapping response
or parsing failures.

## Installation

Add `flutter_sdk_base` to your host project's `pubspec.yaml`:

```yaml
dependencies:
  flutter_sdk_base: ^0.1.0
```

Consumers access capabilities strictly through public barrel exports (`flutter_sdk_base.dart` and `flutter_sdk_base_testing.dart`); `lib/src/` is an internal implementation detail.

---

## Usage

### Quick Start

Initialize `SdkClient` and execute operations:

```dart
import 'package:flutter_sdk_base/flutter_sdk_base.dart';

final sdk = SdkClient(
  config: SdkConfig(
    baseUri: Uri.parse('https://api.example.com'),
    apiKey: hostSuppliedKey,
  ),
);

try {
  final health = await sdk.health.check();
  print('Status: ${health.status}');
} finally {
  await sdk.close();
}
```

<details>
<summary><b>Advanced: Error Handling & Cancellation</b></summary>

```dart
final cancelToken = SdkCancelToken();

try {
  final health = await sdk.health.check(cancelToken: cancelToken);
  print(health.status);
} on SdkException catch (error) {
  // Branch on typed failure codes; map to host user-facing copy
  if (error.failure.code == SdkErrorCodes.unauthorized) {
    // Handle unauthorized access
  } else if (error.failure.isRetryable) {
    // Handle transient error based on SDK retry advice
  }
} finally {
  await sdk.close();
}
```

- **Cancellation Contract:** Cancellation is **best-effort**. `SdkCancelToken.cancel()` and `close()` instruct the SDK to stop waiting and fail pending operations with `SdkErrorCodes.cancelled`. However, the underlying socket may remain open until the server replies; never treat a cancelled call as proof the server did not process the request.
- **Client Lifecycle:** `close()` is idempotent, cancels in-flight work, and releases transport resources. Using a client after `close()` throws `StateError`, as this is a programming mistake rather than a runtime failure.

</details>

<details>
<summary><b>Advanced: Observability & Telemetry</b></summary>

The SDK is silent by default. A host may supply an `SdkObserver` callback to receive terminal operation metrics:

```dart
final sdk = SdkClient(
  config: config,
  observer: (SdkOperationEvent event) {
    print('${event.operationName} finished in ${event.durationMs}ms (status: ${event.status})');
  },
);
```

- **Safe Structured Events:** Dispatches exactly one terminal event per operation containing only static operation name, request ID, SDK version, duration, outcome, HTTP status, and failure code.
- **Strict Privacy Guarantee:** Events never contain credentials, URI paths/query parameters, headers, request/response bodies, raw exceptions, stack traces, or diagnostic causes.
- **Isolation:** Observer exceptions are caught and swallowed by the SDK to guarantee telemetry cannot disrupt host execution.

</details>

---
