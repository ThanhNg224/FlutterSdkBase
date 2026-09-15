# Changelog

## 0.1.0 (unreleased)

- Initial public API: `SdkClient`, `SdkConfig`, `SdkHealthService`, `SdkHealth`.
- Injectable `SdkHttpTransport` with an internal `package:http` default.
- Typed failures via `SdkException` / `SdkFailure` / `SdkErrorCodes`.
- Silent-by-default `SdkLogger`; the API key is redacted in every record.
- `FakeSdkHttpTransport` in `flutter_sdk_base_testing.dart`.
- Added SDK-owned per-operation cancellation through `SdkCancelToken`; reuse a
  token deliberately to cancel a group of in-flight operations.
- Added `sdkVersion`, `X-Sdk-Version`, and per-request `X-Request-Id` headers;
  `SdkFailure.requestId` preserves the correlation ID for support diagnostics.
- Added value equality and matching `hashCode` implementations for `SdkConfig`,
  `SdkHealth`, and `SdkFailure`; failure equality excludes diagnostic `cause`.
