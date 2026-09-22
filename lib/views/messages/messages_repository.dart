import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';

class MessagesRepository {
  MessagesRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<String?> getToken() => getSession(SessionKeys.token);

  Future<Response<dynamic>> fetchMessages({
    required int page,
    required int pageSize,
  }) {
    return _apiService.getMessagesList(
      queryParameters: <String, dynamic>{'page': page, 'pageSize': pageSize},
    );
  }

  Future<Response<dynamic>> markMessageRead(String messageId) {
    return _apiService.markMessageRead(messageId);
  }

  Future<Response<dynamic>> fetchUnreadCount() =>
      _apiService.getUnreadMessageCount();

  /// 一键已读全部消息（POST /usermessage/readAll，幂等）。
  Future<Response<dynamic>> markAllMessagesRead() =>
      _apiService.markAllMessagesRead();
}
