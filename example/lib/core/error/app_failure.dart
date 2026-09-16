import 'package:flutter_sdk_base/flutter_sdk_base.dart';

/// A host-owned failure that carries stable SDK support metadata.
final class AppFailure implements Exception {
  /// Creates a host failure.
  const AppFailure({
    required this.code,
    required this.message,
    required this.isRetryable,
    required this.requestId,
  });

  /// Creates a host failure from an SDK exception.
  factory AppFailure.fromSdkException(SdkException exception) => AppFailure.fromSdkFailure(exception.failure);

  /// Creates a host failure from an SDK failure.
  factory AppFailure.fromSdkFailure(SdkFailure failure) => AppFailure(
    code: failure.code,
    message: failure.message,
    isRetryable: failure.isRetryable,
    requestId: failure.requestId,
  );

  /// The stable SDK error code.
  final String code;

  /// Diagnostic text supplied by the SDK.
  final String message;

  /// Whether retrying could plausibly succeed.
  final bool isRetryable;

  /// The SDK request correlation ID.
  final String requestId;

  @override
  String toString() => 'AppFailure($code): $message';
}
