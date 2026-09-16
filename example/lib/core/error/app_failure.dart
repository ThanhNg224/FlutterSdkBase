import 'package:flutter_sdk_base/flutter_sdk_base.dart';

/// A host-owned failure that carries stable SDK support metadata.
final class AppFailure implements Exception {
  /// Creates a host failure.
  const AppFailure({
    required this.code,
    required this.isRetryable,
    required this.requestId,
    this.statusCode,
  });

  /// Creates a host failure from an SDK exception.
  factory AppFailure.fromSdkException(SdkException exception) => AppFailure.fromSdkFailure(exception.failure);

  /// Creates a host failure from an SDK failure.
  factory AppFailure.fromSdkFailure(SdkFailure failure) => AppFailure(
    code: failure.code,
    isRetryable: failure.isRetryable,
    requestId: failure.requestId,
    statusCode: failure.statusCode,
  );

  /// The stable SDK error code.
  final String code;

  /// Whether retrying could plausibly succeed.
  final bool isRetryable;

  /// The SDK request correlation ID.
  final String requestId;

  /// The HTTP status that produced this failure, when there was one.
  final int? statusCode;

  @override
  String toString() => 'AppFailure($code, status: $statusCode)';
}
