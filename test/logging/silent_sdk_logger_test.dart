import 'package:flutter_sdk_base/src/logging/sdk_log_level.dart';
import 'package:flutter_sdk_base/src/logging/silent_sdk_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SilentSdkLogger accepts every level without emitting or throwing', () {
    const logger = SilentSdkLogger();

    for (final level in SdkLogLevel.values) {
      expect(
        () => logger.log(level, 'anything', error: Exception('x')),
        returnsNormally,
      );
    }
  });
}
