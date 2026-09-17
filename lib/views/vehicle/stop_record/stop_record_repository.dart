import 'package:dio/dio.dart';

import 'package:car/shared/services/api_service.dart';

class StopRecordRepository {
  StopRecordRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchTrack(Map<String, dynamic> query) =>
      _apiService.getTrackPos(query);
}
