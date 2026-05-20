import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../../shared/services/api_service.dart';
import '../../utils/getCurrentPosistion.dart';
import '../../utils/session.dart';

class HomeRepository {
  final ApiService _apiService = ApiService();

  // 检查 token
  Future<String?> getToken() async {
    try {
      return await getSession('token');
    } catch (e) {
      return null;
    }
  }

  // 获取当前位置
  Future<Position?> getCurrentPosition() async {
    return await getCurrentLocation();
  }

  // 获取用户设备列表
  Future<Response> getUserDeviceList(Map<String, dynamic> data) async {
    return await _apiService.getUserDeviceList(data);
  }
}
