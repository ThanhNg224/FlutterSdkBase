/// Global API endpoint constants and runtime credentials.
abstract class ApiEndpoints {
  static const String prodUrl = 'https://api.flutter_sdk_base.com';
  static const String devUrl = 'https://api-dev.flutter_sdk_base.com';

  static const String defaultProdToken = String.fromEnvironment('APP_PROD_TOKEN');
  static const String defaultDevToken = String.fromEnvironment('APP_DEV_TOKEN');
  static const String defaultProdClientKey = String.fromEnvironment('APP_PROD_CLIENT_KEY');
  static const String defaultDevClientKey = String.fromEnvironment('APP_DEV_CLIENT_KEY');
  static const String placeholderSdkVersion = '1.0.0';
}
