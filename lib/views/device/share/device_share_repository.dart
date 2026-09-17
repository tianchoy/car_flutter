import 'package:dio/dio.dart';

import 'package:car/services/api_service.dart';

class DeviceShareRepository {
  DeviceShareRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchEnabled() =>
      _apiService.getDeviceShareEnabled();

  Future<Response<dynamic>> fetchShares(
    String deviceId,
    Map<String, dynamic> query,
  ) => _apiService.getDeviceSharees(deviceId, query);

  Future<Response<dynamic>> createShare(Map<String, dynamic> data) =>
      _apiService.createDeviceShare(data);

  Future<Response<dynamic>> revokeShare(String shareId) =>
      _apiService.revokeDeviceShare(shareId);
}
