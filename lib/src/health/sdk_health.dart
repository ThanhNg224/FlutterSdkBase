/// The outcome of an API health check.
final class SdkHealth {
  /// Creates a health result.
  const SdkHealth({
    required this.isHealthy,
    required this.status,
    required this.checkedAt,
  });

  /// Whether the API reported itself healthy.
  final bool isHealthy;

  /// The raw status string the API returned, for display or logging.
  final String status;

  /// When the SDK observed the response.
  final DateTime checkedAt;
}
