import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sdk_base/core/utils/redaction.dart';

void main() {
  group('Redaction.secret', () {
    test('keeps 4 leading and 4 trailing characters of a long credential', () {
      expect(Redaction.secret('abcdefghijklmnop'), 'abcd…mnop');
    });

    test('never reveals the middle of the value', () {
      const token = 'demo_live_SECRETMIDDLE_9f3a';
      final masked = Redaction.secret(token);

      expect(masked.contains('SECRETMIDDLE'), isFalse);
      expect(masked.length, lessThan(token.length));
    });

    test('masks the value completely when head + tail would reveal all of it', () {
      expect(Redaction.secret('12345678'), '********');
      expect(Redaction.secret('123456789'), '1234…6789');
    });

    test('masks short values entirely rather than partially', () {
      expect(Redaction.secret('abc'), '***');
    });

    test('renders an empty credential as empty, matching the Settings hint', () {
      expect(Redaction.secret(''), '');
    });

    test('renders null as an explicit absent marker', () {
      expect(Redaction.secret(null), Redaction.absentMarker);
    });

    test('honours a custom visible width', () {
      expect(Redaction.secret('abcdefghij', visible: 2), 'ab…ij');
    });
  });

  group('Redaction.tail', () {
    test('keeps only the trailing digits of a phone number', () {
      expect(Redaction.tail('0912345678'), '*******678');
    });

    test('preserves the original length so the shape is still recognisable', () {
      const phone = '0912345678';
      expect(Redaction.tail(phone).length, phone.length);
    });

    test('masks values no longer than the visible window', () {
      expect(Redaction.tail('12'), '**');
    });

    test('renders null as an explicit absent marker', () {
      expect(Redaction.tail(null), Redaction.absentMarker);
    });
  });

  group('Redaction.length', () {
    test('reports size without any content', () {
      expect(Redaction.length('contact-dump'), '<12 chars>');
    });

    test('renders null as an explicit absent marker', () {
      expect(Redaction.length(null), Redaction.absentMarker);
    });
  });

  group('Redaction.typeOf', () {
    test('reports the runtime type only', () {
      expect(Redaction.typeOf(<String>['0912345678']), contains('List<String>'));
    });

    test('renders null as an explicit absent marker', () {
      expect(Redaction.typeOf(null), Redaction.absentMarker);
    });
  });
}
