import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the package test harness runs before public API contracts are added', () {
    expect(0, isZero);
  });
}
