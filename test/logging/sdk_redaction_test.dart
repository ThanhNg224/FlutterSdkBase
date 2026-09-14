import 'package:flutter_sdk_base/src/logging/sdk_redaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SdkRedaction.secret', () {
    test('keeps only the first and last four characters of a long value', () {
      expect(SdkRedaction.secret('abcdefghijklmnop'), 'abcd…mnop');
    });

    test('fully masks a value too short to reveal safely', () {
      expect(SdkRedaction.secret('abcdefgh'), '********');
      expect(SdkRedaction.secret('abc'), '***');
    });

    test('renders a null value as an explicit marker', () {
      expect(SdkRedaction.secret(null), '(none)');
    });

    test('never returns the input verbatim for a realistic key', () {
      const key = 'sk_live_5f2b9c7e4a1d';
      expect(SdkRedaction.secret(key), isNot(contains('5f2b9c7e')));
    });
  });
}
