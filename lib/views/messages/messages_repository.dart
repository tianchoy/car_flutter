import 'package:dio/src/response.dart';

import '../../shared/services/api_service.dart';

class MessagesRepository {
  final ApiService _apiService = ApiService();

  Future<Response<dynamic>> fetchMessages() async {
    return await _apiService.getMessagesList();
  }
}
