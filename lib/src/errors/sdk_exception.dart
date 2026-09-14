import 'package:flutter_sdk_base/src/errors/sdk_failure.dart';

/// The exception every public SDK operation throws on an expected failure.
///
/// Programming mistakes — such as using a client after `close()` — throw
/// [StateError] instead, so they surface during development rather than
/// hiding inside a host's error branch.
final class SdkException implements Exception {
  /// Wraps [failure].
  const SdkException(this.failure);

  /// What went wrong.
  final SdkFailure failure;

  @override
  String toString() => 'SdkException: $failure';
}
