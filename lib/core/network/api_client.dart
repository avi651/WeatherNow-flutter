import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../error/failures.dart';
import 'dio_exception_mapper.dart';

/// A thin, reusable wrapper around [Dio] used for all API communication.
///
/// Every method returns `Either<Failure, Response<T>>` instead of throwing,
/// so callers (repositories) get a predictable, typed result to `fold`
/// over rather than needing their own try/catch around Dio.
///
/// This class's only responsibility is making HTTP requests. It doesn't
/// know how Dio was configured (see `DioClientConfig`) and doesn't contain
/// error-mapping rules itself (see [DioExceptionMapper]) — both are
/// separate, focused classes so each concern can be tested and changed
/// independently.
///
/// [Dio] and [DioExceptionMapper] are injected via the constructor so
/// either can be swapped for a test double.
class ApiClient {
  ApiClient({
    required Dio dio,
    DioExceptionMapper exceptionMapper = const DioExceptionMapper(),
  }) : _dio = dio,
       _exceptionMapper = exceptionMapper;

  final Dio _dio;
  final DioExceptionMapper _exceptionMapper;

  Future<Either<Failure, Response<T>>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request<T>(
      () =>
          _dio.get<T>(path, queryParameters: queryParameters, options: options),
    );
  }

  Future<Either<Failure, Response<T>>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request<T>(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Either<Failure, Response<T>>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request<T>(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Either<Failure, Response<T>>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request<T>(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// Runs [request] and centralizes error handling: any [DioException] or
  /// unexpected error is caught here and mapped to a [Failure] instead of
  /// propagating up to the caller.
  Future<Either<Failure, Response<T>>> _request<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      final response = await request();
      return Right(response);
    } on DioException catch (error) {
      return Left(_exceptionMapper.mapDioException(error));
    } catch (error) {
      return Left(_exceptionMapper.mapUnknownError(error));
    }
  }
}
