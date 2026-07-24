import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_exception.dart';

/// Thin wrapper around Dio. No auth headers/interceptors needed since the
/// Flutter app only ever talks to the public, read-only API surface.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _unwrap(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return _unwrap(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Map<String, dynamic> _unwrap(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {'data': data};
  }

  ApiException _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException('Connection timed out. Please check your internet and try again.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException('No internet connection. Please check your network.');
    }
    final statusCode = e.response?.statusCode;
    final serverMessage = e.response?.data is Map ? e.response?.data['message'] : null;
    return ApiException(
      serverMessage ?? 'Something went wrong. Please try again.',
      statusCode: statusCode,
    );
  }
}
