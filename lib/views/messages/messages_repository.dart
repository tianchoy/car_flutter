import 'package:dio/dio.dart';

import '../../shared/services/api_service.dart';
import '../../utils/session.dart';

class MessagesRepository {
  final ApiService _apiService = ApiService();

  // 检查 token
  Future<String?> getToken() async {
    try {
      return await getSession('token');
    } catch (e) {
      return null;
    }
  }

  Future<Response> fetchMessages() async {
    return await _apiService.getMessagesList();
  }
}
