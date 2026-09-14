import 'package:flutter_sdk_base/core/errors/app_exception.dart';
import 'package:flutter_sdk_base/core/errors/error_handler.dart';
import 'package:flutter_sdk_base/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorHandler', () {
    test('should map PlatformException to PlatformFailure correctly', () {
      const exception = PlatformException(message: 'Face liveness failed', errorCode: 'ERR_100');
      final failure = ErrorHandler.handleException(exception);

      expect(failure, isA<PlatformFailure>());
      expect((failure as PlatformFailure).message, 'Face liveness failed');
      expect(failure.errorCode, 'ERR_100');
    });

    test('should map ServerException to ServerFailure correctly', () {
      const exception = ServerException(message: 'Internal Server Error', statusCode: 500);
      final failure = ErrorHandler.handleException(exception);

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 500);
    });

    test('guard should return Right(value) on success', () async {
      final result = await ErrorHandler.guard(() async => 'success_payload');

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => ''), 'success_payload');
    });

    test('guard should return Left(Failure) on exception', () async {
      final result = await ErrorHandler.guard(() async {
        throw const NetworkException(message: 'Connection dropped');
      });

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should have returned Left'),
      );
    });
  });
}
