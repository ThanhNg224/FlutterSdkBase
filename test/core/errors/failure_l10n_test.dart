import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sdk_base/core/errors/failure.dart';
import 'package:flutter_sdk_base/core/errors/failure_l10n.dart';
import 'package:flutter_sdk_base/l10n/app_localizations.dart';

void main() {
  const failures = <Failure>[
    Failure.network(),
    Failure.unauthorized(),
    Failure.server(message: 'raw server text'),
    Failure.platform(message: 'PlatformException(401, Something went wrong, ...)'),
    Failure.storage(message: 'raw storage text'),
    Failure.unexpected(message: 'raw unexpected text'),
  ];

  for (final locale in AppLocalizations.supportedLocales) {
    group('FailureL10n in ${locale.languageCode}', () {
      testWidgets('every failure maps to distinct, non-empty user-facing copy', (tester) async {
        final l10n = await AppLocalizations.delegate.load(locale);

        final messages = failures.map((failure) => failure.localizedMessage(l10n)).toList();
        expect(messages.every((message) => message.trim().isNotEmpty), isTrue);
        expect(messages.toSet().length, failures.length, reason: 'duplicates: $messages');
      });

      testWidgets('never leaks the raw technical message into the UI copy', (tester) async {
        final l10n = await AppLocalizations.delegate.load(locale);

        for (final failure in failures) {
          expect(
            failure.localizedMessage(l10n),
            isNot(contains('PlatformException')),
            reason: '$failure',
          );
          expect(failure.localizedMessage(l10n), isNot(contains('raw ')), reason: '$failure');
        }
      });
    });
  }

  testWidgets('English and Vietnamese copy actually differ', (tester) async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final vi = await AppLocalizations.delegate.load(const Locale('vi'));

    for (final failure in failures) {
      expect(failure.localizedMessage(en), isNot(failure.localizedMessage(vi)), reason: '$failure');
    }
  });
}
