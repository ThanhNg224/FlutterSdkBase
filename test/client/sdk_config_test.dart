import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SdkConfig defaults requestTimeout to 15 seconds', () {
    final config = SdkConfig(
      baseUri: Uri.parse('https://api.example.com'),
      apiKey: 'key',
    );

    expect(config.requestTimeout, const Duration(seconds: 15));
  });

  test('SdkConfig accepts an explicit timeout', () {
    final config = SdkConfig(
      baseUri: Uri.parse('https://api.example.com'),
      apiKey: 'key',
      requestTimeout: const Duration(seconds: 3),
    );

    expect(config.requestTimeout, const Duration(seconds: 3));
  });

  test('SdkConfig equality covers all fields', () {
    final first = SdkConfig(
      baseUri: Uri.parse('https://api.example.com'),
      apiKey: 'key',
      requestTimeout: Duration(seconds: 3),
    );
    final same = SdkConfig(
      baseUri: Uri.parse('https://api.example.com'),
      apiKey: 'key',
      requestTimeout: Duration(seconds: 3),
    );

    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(
      first,
      isNot(
        equals(
          SdkConfig(
            baseUri: Uri.parse('https://api.example.com'),
            apiKey: 'other-key',
            requestTimeout: Duration(seconds: 3),
          ),
        ),
      ),
    );
  });
}
