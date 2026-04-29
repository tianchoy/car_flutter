import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HttpService {
  late Dio _dio;
  final String baseUrl;
  final Duration timeout;

  HttpService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
  }) {
    _initDio();
    _setupInterceptors();
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 添加认证头，例如 JWT Token
          options.headers['Authorization'] = 'Bearer your_token_here';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // 统一处理响应
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // 统一处理错误
          final errorResponse = _handleError(e);
          return handler.reject(errorResponse);
        },
      ),
    );
  }

  DioException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return DioException(
          requestOptions: error.requestOptions,
          error: '网络连接超时，请稍后重试',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        String message = '请求失败，状态码: $statusCode';
        if (statusCode == 401) {
          message = '未授权，请重新登录';
          // 处理未授权，例如跳转到登录页
        } else if (statusCode == 404) {
          message = '请求资源不存在';
        } else if (statusCode >= 500) {
          message = '服务器内部错误，请稍后重试';
        }
        return DioException(
          requestOptions: error.requestOptions,
          error: message,
          response: error.response,
        );
      case DioExceptionType.cancel:
        return DioException(
          requestOptions: error.requestOptions,
          error: '请求已取消',
        );
      case DioExceptionType.badCertificate:
        return DioException(
          requestOptions: error.requestOptions,
          error: 'SSL证书验证失败，请检查服务器证书',
        );
      case DioExceptionType.connectionError:
        return DioException(
          requestOptions: error.requestOptions,
          error: '网络连接错误，请检查网络设置',
        );
      case DioExceptionType.unknown:
        return DioException(
          requestOptions: error.requestOptions,
          error: '发生未知错误，请稍后重试',
        );
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
