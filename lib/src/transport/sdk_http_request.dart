import 'dart:typed_data';

/// An HTTP request expressed in SDK-owned types.
///
/// The SDK builds these; a transport implementation consumes them. No HTTP
/// library type appears here, so the default transport can be replaced
/// without a breaking change.
final class SdkHttpRequest {
  /// Creates a request.
  const SdkHttpRequest({
    required this.method,
    required this.uri,
    required this.headers,
    this.body,
  });

  /// The HTTP method, upper-case (for example `GET`).
  final String method;

  /// The fully resolved target.
  final Uri uri;

  /// Headers to send. Already includes authentication.
  final Map<String, String> headers;

  /// The request body, or null when there is none.
  ///
  /// v1 represents bodies as bytes only: there is no streaming or multipart.
  final Uint8List? body;
}
