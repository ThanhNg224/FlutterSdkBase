# Changelog

## 0.1.0 (unreleased)

- Initial public API: `SdkClient`, `SdkConfig`, `SdkHealthService`, `SdkHealth`.
- Injectable `SdkHttpTransport` with an internal `package:http` default.
- Typed failures via `SdkException` / `SdkFailure` / `SdkErrorCodes`.
- Replaced `SdkLogger`, `SdkLogLevel`, and redaction APIs with silent-by-default
  structured `SdkObserver` operation events. Events contain only safe outcome,
  timing, correlation, status, and retry metadata.
- Added a vendor-neutral host observability boundary: hosts own SDK telemetry,
  error-reporting policy, unhandled Flutter/platform error bindings, and
  user-facing error copy; the base release remains silent by default.
- Added an independent packaged-consumer release gate for staged Android and
  iOS example builds from committed `git archive HEAD` snapshots.
- `FakeSdkHttpTransport` in `flutter_sdk_base_testing.dart`.
- Added SDK-owned per-operation cancellation through `SdkCancelToken`; reuse a
  token deliberately to cancel a group of in-flight operations.
- Added `sdkVersion`, `X-Sdk-Version`, and per-request `X-Request-Id` headers;
  `SdkFailure.requestId` preserves the correlation ID for support diagnostics.
- Added value equality and matching `hashCode` implementations for `SdkConfig`,
  `SdkHealth`, and `SdkFailure`; failure equality excludes diagnostic `cause`.
- Declared Android and iOS as the package's supported pub.dev platforms, matching
  the documented release support policy.
