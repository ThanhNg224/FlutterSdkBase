import 'package:dio/dio.dart';
import 'package:flutter_sdk_base/core/errors/app_exception.dart';
import 'package:flutter_sdk_base/core/errors/failure.dart';
import 'package:flutter_sdk_base/core/logging/logging.dart';
import 'package:fpdart/fpdart.dart';

const _log = AppLogger('Errors');

/// Centralized error handling and mapping from Exception to Failure.
abstract class ErrorHandler {
  /// Converts an exception into a domain [Failure] and logs it.
  static Failure handleException(Object error, [StackTrace? stackTrace]) {
    final failure = _mapToFailure(error);
    _log.error(
      'exception mapped to failure',
      error: error,
      stackTrace: stackTrace ?? _traceOf(error) ?? StackTrace.current,
      data: {'failure': Redacted.type(failure)},
    );
    return failure;
  }

  /// Maps DioException to domain Failure
  static Failure handleDioError(DioException dioError) {
    return switch (dioError.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => const Failure.network(
        message: 'Connection timed out. Please check your network.',
      ),
      DioExceptionType.badResponse => () {
        final statusCode = dioError.response?.statusCode;
        final responseData = dioError.response?.data;
        final message = responseData is Map && responseData.containsKey('message')
            ? responseData['message'].toString()
            : 'Server error with status code $statusCode';
        if (statusCode == 401 || statusCode == 403) {
          return Failure.unauthorized(message: message);
        }
        return Failure.server(message: message, statusCode: statusCode);
      }(),
      DioExceptionType.cancel => const Failure.unexpected(message: 'Request was cancelled'),
      _ => Failure.unexpected(message: dioError.message ?? 'An unexpected network error occurred'),
    };
  }

  /// Wraps an async call in an `Either<Failure, T>`.
  static Future<Either<Failure, T>> guard<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      return Right(result);
    } catch (e, st) {
      return Left(handleException(e, st));
    }
  }

  static Failure _mapToFailure(Object error) {
    if (error is AppException) {
      return switch (error) {
        ServerException(:final message, :final statusCode) => Failure.server(message: message, statusCode: statusCode),
        NetworkException(:final message) => Failure.network(message: message),
        PlatformException(:final message, :final errorCode) => Failure.platform(message: message, errorCode: errorCode),
        StorageException(:final message) => Failure.storage(message: message),
        UnauthorizedException(:final message) => Failure.unauthorized(message: message),
        UnexpectedException(:final message) => Failure.unexpected(message: message),
      };
    }

    if (error is DioException) {
      return handleDioError(error);
    }

    return Failure.unexpected(message: error.toString());
  }

  static StackTrace? _traceOf(Object error) => switch (error) {
    AppException(:final stackTrace) => stackTrace,
    DioException(:final stackTrace) => stackTrace,
    _ => null,
  };
}
