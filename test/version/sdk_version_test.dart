import 'dart:io';

import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sdkVersion matches the root pubspec version', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? match = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);

    expect(match, isNotNull);
    expect(sdkVersion, match!.group(1));
  });
}
