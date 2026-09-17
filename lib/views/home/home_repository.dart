import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/api_service.dart';
import '../../utils/get_current_position.dart';
import '../../utils/session.dart';

class HomeRepository {
  HomeRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<String?> getToken() => getSession(SessionKeys.token);

  Future<Position?> getCurrentPosition() => getCurrentLocation();

  Future<Response<dynamic>> getUserDeviceList(Map<String, dynamic> data) {
    return _apiService.getUserDeviceList(data);
  }

  Future<Response<dynamic>> getDeviceInfo(String deviceId) {
    return _apiService.getDeviceInfo(deviceId);
  }

  Future<Response<dynamic>> getDeviceLastPosition(Map<String, dynamic> query) {
    return _apiService.getDeviceLastPosition(query);
  }

  Future<Response<dynamic>> getTrackPos(Map<String, dynamic> query) {
    return _apiService.getTrackPos(query);
  }

  Future<Response<dynamic>> deleteDevice(String deviceId) {
    return _apiService.deleteDevice(deviceId);
  }
}
