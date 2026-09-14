import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sdk_base/core/logging/logging.dart';
import 'package:flutter_sdk_base/core/utils/redaction.dart';

void main() {
  group('Redacted', () {
    test('secret delegates to the same masking the Settings screen uses', () {
      const token = 'demo_live_abcdef_9f3a';
      expect(Redacted.secret(token).toString(), Redaction.secret(token));
    });

    test('secret never renders the raw value', () {
      const token = 'demo_live_SECRETMIDDLE_9f3a';
      expect(Redacted.secret(token).toString(), isNot(token));
      expect(Redacted.secret(token).toString(), isNot(contains('SECRETMIDDLE')));
    });

    test('phone keeps only the trailing digits', () {
      expect(Redacted.phone('0912345678').toString(), '*******678');
    });

    test('length reveals size only', () {
      expect(Redacted.length('0912345678').toString(), '<10 chars>');
    });

    test('type reveals the runtime type only', () {
      expect(Redacted.type(const Duration(days: 1)).toString(), 'Duration');
    });

    test('count and flag render plain non-identifying values', () {
      expect(Redacted.count(37).toString(), '37');
      expect(Redacted.flag(true).toString(), 'true');
      expect(Redacted.flag(false).toString(), 'false');
    });

    test('unredacted passes the value through, which is why it needs a reason', () {
      expect(
        Redacted.unredacted('GET', because: 'HTTP verb carries no user data').toString(),
        'GET',
      );
    });
  });
}
