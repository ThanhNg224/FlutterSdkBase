import 'package:flutter_sdk_base/src/util/sdk_uri.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SdkUri.join', () {
    test('appends to a bare host', () {
      expect(
        SdkUri.join(Uri.parse('https://api.example.com'), 'health').toString(),
        'https://api.example.com/health',
      );
    });

    test('preserves a base path segment', () {
      expect(
        SdkUri.join(Uri.parse('https://api.example.com/v1'), 'health').toString(),
        'https://api.example.com/v1/health',
      );
    });

    test('does not double the separator when the base ends with a slash', () {
      expect(
        SdkUri.join(Uri.parse('https://api.example.com/v1/'), 'health').toString(),
        'https://api.example.com/v1/health',
      );
    });

    test('accepts a leading slash on the path', () {
      expect(
        SdkUri.join(Uri.parse('https://api.example.com/v1'), '/health').toString(),
        'https://api.example.com/v1/health',
      );
    });

    test('keeps the base query out of the way', () {
      expect(
        SdkUri.join(Uri.parse('https://api.example.com/v1'), 'health').query,
        isEmpty,
      );
    });
  });
}
