import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_status_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('failureForStatus', () {
    test('401 and 403 map to unauthorized and are not retryable', () {
      for (final status in <int>[401, 403]) {
        final failure = failureForStatus(status);
        expect(failure.code, SdkErrorCodes.unauthorized, reason: 'status $status');
        expect(failure.isRetryable, isFalse, reason: 'status $status');
        expect(failure.statusCode, status);
      }
    });

    test('429 maps to rateLimited and is retryable', () {
      final failure = failureForStatus(429);
      expect(failure.code, SdkErrorCodes.rateLimited);
      expect(failure.isRetryable, isTrue);
    });

    test('other 4xx map to client and are not retryable', () {
      for (final status in <int>[400, 404, 409, 422]) {
        final failure = failureForStatus(status);
        expect(failure.code, SdkErrorCodes.client, reason: 'status $status');
        expect(failure.isRetryable, isFalse, reason: 'status $status');
      }
    });

    test('5xx map to server and are retryable', () {
      for (final status in <int>[500, 502, 503]) {
        final failure = failureForStatus(status);
        expect(failure.code, SdkErrorCodes.server, reason: 'status $status');
        expect(failure.isRetryable, isTrue, reason: 'status $status');
      }
    });

    test('a supplied message replaces the default', () {
      final failure = failureForStatus(404, message: 'No such dataset.');
      expect(failure.message, 'No such dataset.');
    });
  });
}
