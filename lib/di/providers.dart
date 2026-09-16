import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/dio_exception_mapper.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'YOUR_BASE_URL'));
});

final dioExceptionMapperProvider = Provider<DioExceptionMapper>((ref) {
  return const DioExceptionMapper();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    dio: ref.watch(dioProvider),
    exceptionMapper: ref.watch(dioExceptionMapperProvider),
  );
});
