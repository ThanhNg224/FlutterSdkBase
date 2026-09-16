/// A Flutter SDK package with no native code: an instance-based client, an
/// injectable HTTP transport, typed failures, and safe operation observability.
///
/// Only the declarations exported here and from `flutter_sdk_base_testing.dart`
/// are supported API. Everything under `src/` may change in any release.
library;

export 'src/client/sdk_client.dart' show SdkClient;
export 'src/client/sdk_cancel_token.dart' show SdkCancelToken;
export 'src/client/sdk_config.dart' show SdkConfig;
export 'src/errors/sdk_error_codes.dart' show SdkErrorCodes;
export 'src/errors/sdk_exception.dart' show SdkException;
export 'src/errors/sdk_failure.dart' show SdkFailure;
export 'src/health/sdk_health.dart' show SdkHealth;
export 'src/health/sdk_health_service.dart' show SdkHealthService;
export 'src/logging/sdk_observer.dart' show SdkObserver;
export 'src/logging/sdk_operation_event.dart' show SdkOperationEvent, SdkOperationOutcome;
export 'src/transport/sdk_http_call.dart' show SdkHttpCall;
export 'src/transport/sdk_http_request.dart' show SdkHttpRequest;
export 'src/transport/sdk_http_response.dart' show SdkHttpResponse;
export 'src/transport/sdk_http_transport.dart' show SdkHttpTransport;
export 'src/version/sdk_version.dart' show sdkVersion;
