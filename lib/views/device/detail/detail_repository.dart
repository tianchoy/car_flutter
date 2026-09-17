import 'package:dio/dio.dart';

import 'package:car/shared/models/api_response.dart';
import 'package:car/shared/services/api_service.dart';
import 'package:car/utils/Logger.dart';

class DetailRepository {
  DetailRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchDeviceInfo(String deviceId) =>
      _apiService.getDeviceInfo(deviceId);

  Future<Response<dynamic>> fetchDevicePosition(Map<String, dynamic> query) =>
      _apiService.getDeviceLastPosition(query);

  Future<Response<dynamic>> sendCommand(
    Map<String, dynamic> data, {
    bool put = false,
  }) => _apiService.sendCommand(data, put: put);

  Future<Response<dynamic>> fetchGeocoderAddress(Map<String, dynamic> query) =>
      _apiService.getGeocoderAddress(query);

  Future<String?> fetchAddress(Map<String, dynamic> query) async {
    final response = await fetchGeocoderAddress(query);
    final result = ApiResponse<Object?>.fromJson(response.data);
    if (!result.isSuccess) {
      Log.w('获取中文地址失败: ${result.message}');
      return null;
    }
    return _addressFrom(result.data ?? result.raw['data']);
  }

  String? _addressFrom(Object? value) {
    final map = jsonMapFrom(value);
    for (final key in const ['address', 'formattedAddress', 'name']) {
      final text = stringValue(map[key]).trim();
      if (text.isNotEmpty) return text;
    }
    for (final key in const ['data', 'result', 'location']) {
      final nested = _addressFrom(map[key]);
      if (nested != null) return nested;
    }
    final text = stringValue(value).trim();
    return text.isEmpty || text == '{}' ? null : text;
  }

  Future<Response<dynamic>> fetchTrackData(Map<String, dynamic> data) =>
      _apiService.getTrackPos(data);

  Future<ApiResponse<JsonMap>> fetchTrackSummary(
    Map<String, dynamic> data,
  ) async {
    final response = await fetchTrackData(data);
    final result = ApiResponse<JsonMap>.fromJson(
      response.data,
      dataParser: jsonMapFrom,
    );
    if (!result.isSuccess) Log.w('获取轨迹失败: ${result.message}');
    return result;
  }
}
