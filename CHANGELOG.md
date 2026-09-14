# Changelog

## 0.1.0 (unreleased)

- Initial public API: `SdkClient`, `SdkConfig`, `SdkHealthService`, `SdkHealth`.
- Injectable `SdkHttpTransport` with an internal `package:http` default.
- Typed failures via `SdkException` / `SdkFailure` / `SdkErrorCodes`.
- Silent-by-default `SdkLogger`; the API key is redacted in every record.
- `FakeSdkHttpTransport` in `flutter_sdk_base_testing.dart`.
