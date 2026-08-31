import 'package:akademihub_mob/core/error/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DioException responseError(int status, dynamic data) => DioException(
    requestOptions: RequestOptions(path: '/test'),
    response: Response(
      requestOptions: RequestOptions(path: '/test'),
      statusCode: status,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );

  test('maps HTTP error semantics and messages', () {
    expect(
      mapDioException(responseError(401, {'message': 'expired'})),
      isA<AuthException>(),
    );
    final forbidden = mapDioException(
      responseError(403, {'message': 'denied'}),
    );
    expect(forbidden, isA<ForbiddenException>());
    expect(forbidden.message, 'denied');
    expect(mapDioException(responseError(404, {})), isA<NotFoundException>());
    expect(
      mapDioException(responseError(422, {'errors': {}})),
      isA<ValidationException>(),
    );
    expect(
      mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        ),
      ),
      isA<NetworkException>(),
    );
    final server = mapDioException(
      responseError(500, {'message': 'internal database detail'}),
    );
    expect(server, isA<ServerException>());
    expect(
      server.message,
      'Server sedang bermasalah. Silakan coba lagi nanti.',
    );
    expect(server.message, isNot(contains('database')));
  });
}
