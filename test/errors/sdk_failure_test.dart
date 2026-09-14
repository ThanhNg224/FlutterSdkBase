import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/errors/sdk_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SdkFailure', () {
    test('toString renders code, status and message', () {
      const failure = SdkFailure(
        code: SdkErrorCodes.server,
        message: 'Upstream unavailable.',
        isRetryable: true,
        statusCode: 503,
      );

      expect(failure.toString(), 'SdkFailure(server, status: 503): Upstream unavailable.');
    });

    test('toString never leaks cause', () {
      const failure = SdkFailure(
        code: SdkErrorCodes.transport,
        message: 'Transport failure.',
        isRetryable: true,
        cause: 'https://api.example.com?token=SUPERSECRET',
      );

      expect(failure.toString(), isNot(contains('SUPERSECRET')));
    });

    test('SdkException exposes its failure and renders it', () {
      const failure = SdkFailure(
        code: SdkErrorCodes.timeout,
        message: 'Timed out.',
        isRetryable: true,
      );
      const exception = SdkException(failure);

      expect(exception.failure, same(failure));
      expect(exception.toString(), contains('timeout'));
    });
  });
}
