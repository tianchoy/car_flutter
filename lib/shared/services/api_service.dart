import 'package:dio/dio.dart';
import 'api_http.dart';
import 'url.dart';

class ApiService {
  final HttpService _httpService = HttpService(baseUrl: baseUrl);

  // 登录API
  Future<Response> login(String email, String password) async {
    final data = {'email': email, 'password': password};
    return await _httpService.post(loginUrl, data: data);
  }
}
