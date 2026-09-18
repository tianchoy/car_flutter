import 'package:dio/dio.dart';

import 'package:car/models/api_response.dart';
import 'package:car/services/api_service.dart';

class StopRecordRepository {
  StopRecordRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchTrack(Map<String, dynamic> query) =>
      _apiService.getTrackPos(query);

  /// 逆地理编码：把经纬度解析成中文地址（与「设备详情」解析中文地址同一接口）。
  Future<String?> fetchAddress(Map<String, dynamic> query) async {
    final response = await _apiService.getGeocoderAddress(query);
    final result = ApiResponse<Object?>.fromJson(response.data);
    if (!result.isSuccess) return null;
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
}
