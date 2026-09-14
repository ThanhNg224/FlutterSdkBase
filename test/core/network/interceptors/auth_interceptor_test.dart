import 'package:dio/dio.dart';
import 'package:flutter_sdk_base/core/config/app_config.dart';
import 'package:flutter_sdk_base/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingAdapter implements HttpClientAdapter {
  final int statusCode;
  RequestOptions? requestOptions;

  RecordingAdapter({this.statusCode = 200});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestOptions = options;
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: const {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  test('adds configured bearer token and client key to requests', () async {
    final adapter = RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        readConfig: () => const AppConfig(appToken: 'token-value', clientKey: 'client-key-value'),
        clearCredentialOverrides: () async {},
        baseUri: Uri.parse('https://api.example.test'),
      ),
    );

    await dio.get<void>('/posts');

    expect(adapter.requestOptions?.headers['Authorization'], 'Bearer token-value');
    expect(adapter.requestOptions?.headers['X-Client-Key'], 'client-key-value');
  });

  test('clears credential overrides after a 401 response', () async {
    final adapter = RecordingAdapter(statusCode: 401);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))..httpClientAdapter = adapter;
    var clearCalls = 0;
    dio.interceptors.add(
      AuthInterceptor(
        readConfig: AppConfig.new,
        clearCredentialOverrides: () async => clearCalls++,
        baseUri: Uri.parse('https://api.example.test'),
      ),
    );

    await expectLater(dio.get<void>('/posts'), throwsA(isA<DioException>()));

    expect(clearCalls, 1);
  });

  test('does not clear credential overrides for a 401 from another origin', () async {
    final adapter = RecordingAdapter(statusCode: 401);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))..httpClientAdapter = adapter;
    var clearCalls = 0;
    dio.interceptors.add(
      AuthInterceptor(
        readConfig: AppConfig.new,
        clearCredentialOverrides: () async => clearCalls++,
        baseUri: Uri.parse('https://api.example.test'),
      ),
    );

    await expectLater(dio.get<void>('https://other.example.test/posts'), throwsA(isA<DioException>()));

    expect(clearCalls, 0);
  });
}
