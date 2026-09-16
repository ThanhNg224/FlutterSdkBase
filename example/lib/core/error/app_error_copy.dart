import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base_example/core/error/app_failure.dart';

/// Maps host failures to user-facing English copy.
abstract final class AppErrorCopy {
  /// Returns safe user-facing text for [error].
  static String messageFor(Object error) {
    if (error is! AppFailure) {
      return 'Something went wrong. Please try again.';
    }

    return switch (error.code) {
      SdkErrorCodes.cancelled => 'The request was cancelled.',
      SdkErrorCodes.timeout => 'That took too long. Check your connection.',
      SdkErrorCodes.transport => 'We could not reach the service.',
      SdkErrorCodes.unauthorized => 'Your API key was rejected.',
      SdkErrorCodes.client => 'The request was not accepted.',
      SdkErrorCodes.rateLimited => 'Too many requests — try again shortly.',
      SdkErrorCodes.server => 'The service is having trouble. Try again.',
      SdkErrorCodes.invalidResponse => 'The service returned an invalid response.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
