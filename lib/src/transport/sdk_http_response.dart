import 'dart:convert';
import 'dart:typed_data';

/// An HTTP response expressed in SDK-owned types.
final class SdkHttpResponse {
  /// Creates a response.
  const SdkHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  /// The HTTP status code.
  final int statusCode;

  /// Response headers, lower-cased by the transport.
  final Map<String, String> headers;

  /// The response body as bytes.
  final Uint8List body;

  /// The body decoded as UTF-8, substituting replacement characters rather
  /// than throwing on malformed input.
  String get bodyAsString => const Utf8Decoder(allowMalformed: true).convert(body);
}
