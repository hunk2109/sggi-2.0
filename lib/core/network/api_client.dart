import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/storage_service.dart';

class ApiClient {
  late final Dio dio;
  final StorageService storageService;
  void Function()? onUnauthorized;

  ApiClient({required this.storageService, this.onUnauthorized}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            storageService.clearSession();
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }
}
