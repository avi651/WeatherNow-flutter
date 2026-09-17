import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_now_flutter/core/config/app_environment.dart';

import '../core/network/api_client.dart';
import '../core/network/dio_exception_mapper.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: AppEnvironment.baseUrl));
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
