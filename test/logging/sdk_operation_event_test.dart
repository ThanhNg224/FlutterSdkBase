import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('operation events expose the structured terminal contract', () {
    const event = SdkOperationEvent(
      operation: 'health.check',
      requestId: '0123456789abcdef0123456789abcdef',
      sdkVersion: '0.1.0',
      outcome: SdkOperationOutcome.failed,
      elapsed: Duration(milliseconds: 12),
      statusCode: 503,
      failureCode: SdkErrorCodes.server,
      isRetryable: true,
    );

    expect(event.operation, 'health.check');
    expect(event.requestId, hasLength(32));
    expect(event.outcome, SdkOperationOutcome.failed);
    expect(event.statusCode, 503);
    expect(event.failureCode, SdkErrorCodes.server);
    expect(event.isRetryable, isTrue);
  });
}
