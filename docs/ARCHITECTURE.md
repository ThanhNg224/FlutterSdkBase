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
