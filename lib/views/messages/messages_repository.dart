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

  // 未读数不再走本仓库：它由 UnreadCountService 全局维护（tabbar 角标与消息页
  // 共用同一份数据），这里若再暴露一个入口会出现两条互相覆盖的取数路径。

  /// 一键已读全部消息（POST /usermessage/readAll，幂等）。
  Future<Response<dynamic>> markAllMessagesRead() =>
      _apiService.markAllMessagesRead();
}
