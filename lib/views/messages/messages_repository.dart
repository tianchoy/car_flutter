import 'package:dio/dio.dart';

import '../../shared/services/api_service.dart';

class MessagesRepository {
  final ApiService _apiService = ApiService();

  Future<Response> fetchMessages() async {
    return await _apiService.getMessagesList();
  }
}
