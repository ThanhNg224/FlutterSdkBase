/// Host-owned configuration used to construct the demo SDK client.
final class AppConfig {
  /// Creates immutable host configuration.
  const AppConfig({
    required this.environmentName,
    required this.apiBaseUrl,
    required this.apiKey,
    required this.transportDescription,
  });

  /// The environment label shown by host diagnostics.
  final String environmentName;

  /// The API root supplied to the SDK client.
  final String apiBaseUrl;

  /// The credential supplied to the SDK client.
  final String apiKey;

  /// A host-readable description of the transport fixture.
  final String transportDescription;

  @override
  bool operator ==(Object other) =>
      other is AppConfig &&
      other.environmentName == environmentName &&
      other.apiBaseUrl == apiBaseUrl &&
      other.apiKey == apiKey &&
      other.transportDescription == transportDescription;

  @override
  int get hashCode => Object.hash(environmentName, apiBaseUrl, apiKey, transportDescription);
}
