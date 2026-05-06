import 'package:dio/dio.dart';
import 'api_http.dart';
import 'url.dart';

class ApiService {
  final HttpService _httpService = HttpService(baseUrl: baseUrl);

  // 登录API
  Future<Response> login(String username, String password) async {
    final data = {'username': username, 'password': password};
    return await _httpService.post(loginUrl, data: data);
  }

  // 获取消息列表API
  Future<Response> getMessagesList() async {
    return await _httpService.get(messagesListUrl);
  }

  // 退出登录API
  Future<Response> logout() async {
    return await _httpService.post(logoutUrl);
  }
}
