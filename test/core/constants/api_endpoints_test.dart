import 'package:flutter_sdk_base/core/constants/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not ship credential defaults', () {
    expect(ApiEndpoints.defaultProdToken, isEmpty);
    expect(ApiEndpoints.defaultDevToken, isEmpty);
    expect(ApiEndpoints.defaultProdClientKey, isEmpty);
  });
}
