<div align="center">

# flutter_sdk_base

**A production-grade template and foundation for building Flutter SDK packages with zero native code.**

[![CI](https://img.shields.io/github/actions/workflow/status/ThanhNg224/FlutterSdkBase/ci.yml?branch=main&style=flat-square&label=CI&logo=github)](https://github.com/ThanhNg224/FlutterSdkBase/actions/workflows/ci.yml)
[![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2.svg?style=flat-square&logo=dart)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B.svg?style=flat-square&logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-API%2024%2B-3DDC84.svg?style=flat-square&logo=android)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-15.0%2B-000000.svg?style=flat-square&logo=apple)](https://developer.apple.com)
[![Code Style](https://img.shields.io/badge/style-flutter__lints-blue.svg?style=flat-square)](https://pub.dev/packages/flutter_lints)
[![Architecture](https://img.shields.io/badge/architecture-zero--native-success.svg?style=flat-square)](#key-architectural-principles)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg?style=flat-square)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/ThanhNg224/FlutterSdkBase/pulls)

</div>

---

## Overview

`flutter_sdk_base` provides an opinionated, production-ready foundation for authoring client SDK packages in Dart and Flutter. It eliminates native build failures, enforces safe error boundaries, and isolates host application concerns from core transport logic.

### Key Architectural Principles

- **Zero Native Code** — Pure Dart and Flutter (`package:flutter/foundation.dart` only). Runs consistently across supported platforms without native build tooling or channel overhead.
- **Unified Request Pipeline** — Every operation routes through `SdkRequestExecutor`, applying authentication, correlation IDs (`X-Request-Id`), SDK versioning (`X-Sdk-Version`), timeout, and centralized error classification.
- **Privacy-First Observability** — Emits structured `SdkOperationEvent` metrics to a host-injected observer while strictly redacting API keys, headers, URI query parameters, payloads, raw exceptions, and stack traces.
- **Deterministic Testing** — Ships with a dedicated testing barrel (`flutter_sdk_base_testing.dart`) featuring `FakeSdkHttpTransport` and `SdkClock` freezing for fast, offline, and reliable test suites.
- **Automated Rebranding** — Includes an idempotent rename tool (`make rename`) to rebrand the package, library barrels, and imports across the entire repository in one step.

---

## Getting Started

This repository is designed as a template. Rename the package to your desired name before adding custom capabilities:

```sh
# 1. Preview changes without modifying files
dart run tool/rename_package.dart my_company_sdk --dry-run

# 2. Apply rename across all files and verify
make rename NAME=my_company_sdk
make verify
```

> **Note:** The rename tool requires a clean Git working tree so the rename lands as a single reviewable commit. It does not rename the checkout directory or change the git remote.

---

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

## Architecture

All network operations flow through a single, centralized executor:

```text
SdkClient ──► SdkRequestExecutor ──► SdkHttpTransport ──► (package:http)
                    │
                    ├── authHeaders()       Inject apiKey (never leaked to telemetry)
                    ├── timeout + cancel    Best-effort cancellation via SdkCancelToken
                    ├── correlation headers X-Request-Id and X-Sdk-Version
                    ├── terminal event      Safe SdkOperationEvent dispatched to observer
                    └── failureForStatus()  Centralized HTTP status and network error table
```

For guidelines on adding new capabilities and service boundaries, consult [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Testing

Test your host integration or custom SDK capabilities without making real network calls using the testing barrel:

```dart
import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';

final transport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
final sdk = SdkClient(config: config, transport: transport);

final health = await sdk.health.check();
expect(health.status, 'ok');
```

---

## Support Matrix

| Platform / Surface | Supported Version | Notes |
| :--- | :--- | :--- |
| **Dart** | `>=3.13.0 <4.0.0` | Strict language contract |
| **Flutter** | `>=3.47.0` | Foundation only |
| **Android** | API 24+ | Fully validated |
| **iOS** | 15.0+ | Fully validated |

*Web and desktop targets may compile, but are untested and unsupported in this base.*

---

## Quality Gates

This repository enforces strict static analysis, code boundaries, and packaging checks via `make`:

| Command | Purpose |
| :--- | :--- |
| `make verify` | Formats code, runs analyzer, checks architectural boundaries, and executes unit tests. |
| `make ci` | Full local CI simulation: `pub get`, verification, Dartdoc links, Pana, and publish dry-run. |
| `make packaged-example PLATFORM=android` | Verifies the staged release artifact in an isolated consumer project to prove packaging readiness. |

For detailed engineering conventions and error hierarchies, see [docs/STANDARD.md](docs/STANDARD.md).

---

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md) — Request path, layer separation, and adding new capabilities.
- [Engineering Standards](docs/STANDARD.md) — Public API guidelines, error codes, observability, and test seams.
- [Git Flow & Release](docs/GIT_FLOW.md) — Branching conventions, versioning policy, and deployment pipeline.

## License

This project is licensed under the [MIT License](LICENSE).
