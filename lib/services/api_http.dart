import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/api_response.dart';
import '../../utils/session.dart';
import 'session_expiry_coordinator.dart';
import 'url.dart';

class HttpService {
  HttpService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: timeout,
               receiveTimeout: timeout,
               contentType: Headers.jsonContentType,
               responseType: ResponseType.json,
             ),
           ) {
    _setupInterceptors();
  }

  final Dio _dio;
  final String baseUrl;
  final Duration timeout;

  @visibleForTesting
  Dio get dio => _dio;

  @visibleForTesting
  static Map<String, String> buildAuthenticationHeaders(String? token) {
    final headers = <String, String>{'clientId': AppConfig.clientId};
    final normalizedToken = token?.trim();
    if (normalizedToken != null && normalizedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $normalizedToken';
    }
    return headers;
  }

  void _setupInterceptors() {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          // 打印请求信息（URL、方法、query 参数）：便于核对接口路径与入参。
          request: true,
          // 打印请求头（含 Authorization: Bearer <token>、clientId）。
          requestHeader: true,
          // 打印请求体（POST/PUT 的入参）。
          requestBody: true,
          responseHeader: false,
          responseBody: false,
          error: true,
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getSession(SessionKeys.token);
          options.headers.addAll(buildAuthenticationHeaders(token));
          handler.next(options);
        },
        onResponse: (response, handler) {
          final envelope = ApiResponse<Object?>.fromJson(response.data);
          if (envelope.isTokenExpired) {
            unawaited(SessionExpiryCoordinator.handleExpiredSession());
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            unawaited(SessionExpiryCoordinator.handleExpiredSession());
          }
          handler.reject(_normalizeError(error));
        },
      ),
    );
  }

  DioException _normalizeError(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => '网络连接超时，请稍后重试',
      DioExceptionType.transformTimeout => '数据转换超时，请稍后重试',
      DioExceptionType.cancel => '请求已取消',
      DioExceptionType.badCertificate => 'SSL证书验证失败，请检查服务器证书',
      DioExceptionType.connectionError => '网络连接错误，请检查网络设置',
      DioExceptionType.badResponse => _httpStatusMessage(statusCode),
      DioExceptionType.unknown => '发生未知错误，请稍后重试',
    };

    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: ApiNetworkException(
        message,
        statusCode: statusCode,
        payload: error.response?.data,
      ),
      stackTrace: error.stackTrace,
    );
  }

  String _httpStatusMessage(int? statusCode) {
    if (statusCode == 401) return '未授权，请重新登录';
    if (statusCode == 403) return '没有权限访问';
    if (statusCode == 404) return '请求资源不存在';
    if (statusCode != null && statusCode >= 500) return '服务器错误，请稍后重试';
    return '请求失败${statusCode == null ? '' : '，状态码: $statusCode'}';
  }

  Future<void> clearToken() {
    return SessionExpiryCoordinator.handleExpiredSession();
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
