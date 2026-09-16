/// A host-owned snapshot of the SDK health response.
final class HealthSnapshot {
  /// Creates a health snapshot.
  const HealthSnapshot({
    required this.isHealthy,
    required this.status,
    required this.checkedAt,
  });

  /// Whether the service reported a healthy state.
  final bool isHealthy;

  /// The status reported by the service.
  final String status;

  /// When the SDK observed the response.
  final DateTime checkedAt;

  @override
  bool operator ==(Object other) =>
      other is HealthSnapshot && other.isHealthy == isHealthy && other.status == status && other.checkedAt == checkedAt;

  @override
  int get hashCode => Object.hash(isHealthy, status, checkedAt);
}
