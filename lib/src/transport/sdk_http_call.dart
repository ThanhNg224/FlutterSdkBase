import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';

/// One in-flight request.
abstract interface class SdkHttpCall {
  /// Completes with the response, or with an error if the call fails or is
  /// cancelled.
  Future<SdkHttpResponse> get response;

  /// Abandons this call.
  ///
  /// Cancellation is **best-effort**: the SDK stops waiting and [response]
  /// completes with an error, but the underlying connection may remain open
  /// until the server replies. Never treat a cancelled call as proof that the
  /// server did not receive or process the request.
  Future<void> cancel();
}

/// Internal marker completing a call that was cancelled.
///
/// Never exported: hosts observe cancellation as an `SdkFailure` whose code is
/// `SdkErrorCodes.cancelled`.
final class SdkCallCancelled implements Exception {
  /// Creates the marker.
  const SdkCallCancelled();

  @override
  String toString() => 'SdkCallCancelled';
}
