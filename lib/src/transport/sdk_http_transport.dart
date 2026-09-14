import 'package:flutter_sdk_base/src/transport/sdk_http_call.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';

/// The injectable HTTP boundary.
///
/// A transport handed to `SdkClient` is **owned** by that client: the client
/// calls [close] during its own `close()`. Do not share one transport instance
/// between clients.
abstract interface class SdkHttpTransport {
  /// Starts [request] and returns a handle to it.
  SdkHttpCall open(SdkHttpRequest request);

  /// Releases every resource this transport holds.
  Future<void> close();
}
