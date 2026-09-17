import 'package:dio/dio.dart';

import 'package:car/services/api_service.dart';

class UserInfoRepository {
  UserInfoRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// 获取当前登录用户个人信息（优先 GET /system/appUser/profile，
  /// 后端未部署时自动回退旧接口）。
  Future<Response<dynamic>> fetchUserProfile() =>
      _apiService.getUserProfile();
}
