import 'package:flutter_sdk_base/core/config/app_config_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sdk_base/core/constants/app_constants.dart';
import 'package:flutter_sdk_base/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_sdk_base/core/network/interceptors/logging_interceptor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_client.g.dart';

/// Configured Dio HTTP client provider
@Riverpod(keepAlive: true)
Future<Dio> dioClient(Ref ref) async {
  final config = await ref.watch(appConfigControllerProvider.future);
  final configController = ref.read(appConfigControllerProvider.notifier);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(
      readConfig: () => config,
      clearCredentialOverrides: configController.clearCredentialOverrides,
      baseUri: Uri.parse(config.baseUrl),
    ),
    LoggingInterceptor(),
  ]);

  ref.onDispose(() => dio.close(force: true));
  return dio;
}
