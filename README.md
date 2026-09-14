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
