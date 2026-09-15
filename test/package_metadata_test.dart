import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares only the supported Android and iOS platforms', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final List<String> lines = pubspec.split('\n');
    final int platformsIndex = lines.indexOf('platforms:');

    expect(platformsIndex, isNonNegative);

    final List<String> platformEntries = <String>[];
    for (final String line in lines.skip(platformsIndex + 1)) {
      if (line.isEmpty || line.startsWith(' ')) {
        if (line.startsWith('  ') && !line.startsWith('   ')) {
          platformEntries.add(line.trim());
        }
        continue;
      }
      break;
    }

    expect(platformEntries, <String>['android:', 'ios:']);
    expect(pubspec, contains('sdk: ">=3.13.0 <4.0.0"'));
    expect(pubspec, contains('flutter: ">=3.47.0"'));
  });
}
