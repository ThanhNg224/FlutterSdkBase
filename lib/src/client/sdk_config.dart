/// Everything an `SdkClient` needs to talk to an API.
///
/// The SDK stores nothing: a host supplies this on every construction and
/// keeps whatever it needs across app restarts.
final class SdkConfig {
  /// Creates a configuration.
  const SdkConfig({
    required this.baseUri,
    required this.apiKey,
    this.requestTimeout = const Duration(seconds: 15),
  });

  /// The API root. A path here is preserved, so `https://host/v1` works.
  final Uri baseUri;

  /// The credential sent with every request.
  ///
  /// This value is sent as an authentication header and is never included in
  /// an `SdkOperationEvent`.
  final String apiKey;

  /// How long a single operation may run before it fails with
  /// `SdkErrorCodes.timeout`.
  final Duration requestTimeout;

  @override
  bool operator ==(Object other) =>
      other is SdkConfig &&
      other.baseUri == baseUri &&
      other.apiKey == apiKey &&
      other.requestTimeout == requestTimeout;

  @override
  int get hashCode => Object.hash(baseUri, apiKey, requestTimeout);
}
