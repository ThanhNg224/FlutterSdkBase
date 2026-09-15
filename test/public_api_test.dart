import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every documented public type is reachable from the barrels', () {
    expect(SdkClient, isNotNull);
    expect(SdkCancelToken, isNotNull);
    expect(SdkConfig, isNotNull);
    expect(SdkHealthService, isNotNull);
    expect(SdkHealth, isNotNull);
    expect(SdkHttpTransport, isNotNull);
    expect(SdkHttpCall, isNotNull);
    expect(SdkHttpRequest, isNotNull);
    expect(SdkHttpResponse, isNotNull);
    expect(SdkLogger, isNotNull);
    expect(SdkLogLevel, isNotNull);
    expect(SdkFailure, isNotNull);
    expect(SdkException, isNotNull);
    expect(SdkErrorCodes, isNotNull);
    expect(sdkVersion, isNotEmpty);
    expect(FakeSdkHttpTransport, isNotNull);
  });

  test('a host can build every public value type without reaching into src', () {
    final config = SdkConfig(baseUri: Uri.parse('https://api.example.com'), apiKey: 'k');
    const failure = SdkFailure(
      code: SdkErrorCodes.timeout,
      message: 'x',
      isRetryable: true,
      requestId: 'request-id',
    );

    expect(config.apiKey, 'k');
    expect(const SdkException(failure).failure.code, SdkErrorCodes.timeout);
  });
}
