import 'package:dio/dio.dart';

import 'package:car/services/api_service.dart';

class MileageRepository {
  MileageRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchTrack(Map<String, dynamic> query) =>
      _apiService.getTrackPos(query);
}
