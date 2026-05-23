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

  // 退出登录API
  Future<Response> logout() async {
    return await _httpService.post(logoutUrl);
  }

  // 获取用户信息API
  Future<Response> getUserInfo() async {
    return await _httpService.get(userInfoUrl);
  }

  // 获取用户设备列表API
  Future<Response> getUserDeviceList(Map<String, dynamic> data) async {
    return await _httpService.post(userDeviceList, data: data);
  }

  // 获取消息列表API
  Future<Response> getMessagesList() async {
    return await _httpService.get(messagesListUrl);
  }

  // 获取轨迹位置API
  Future<Response> getTrackPos(Map<String, dynamic> data) async {
    return await _httpService.post(trackPos, data: data);
  }
}
