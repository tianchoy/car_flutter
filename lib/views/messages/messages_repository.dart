import 'package:dio/dio.dart';

import '../../shared/services/api_service.dart';
import '../../utils/session.dart';

class MessagesRepository {
  final ApiService _apiService = ApiService();

  // 检查 token
  Future<bool> checkToken() async {
    try {
      final token = await getSession('token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<Response> fetchMessages() async {
    return await _apiService.getMessagesList();
  }
}
