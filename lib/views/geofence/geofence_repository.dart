import 'package:dio/dio.dart';

import 'package:car/shared/models/api_response.dart';
import 'package:car/shared/services/api_service.dart';

class GeofenceRepository {
  GeofenceRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<ApiResponse<List<Object?>>> fetchFences() async {
    final response = await _apiService.getGeofenceList();
    return ApiResponse<List<Object?>>.fromJson(
      response.data,
      dataParser: jsonListFrom,
    );
  }

  Future<ApiResponse<Object?>> createFence(Map<String, dynamic> data) async {
    final response = await _apiService.addGeofence(data);
    return ApiResponse<Object?>.fromJson(response.data);
  }

  Future<ApiResponse<Object?>> updateFence(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.updateGeofence(<String, dynamic>{
      'id': id,
      ...data,
    });
    return ApiResponse<Object?>.fromJson(response.data);
  }

  Future<ApiResponse<Object?>> deleteFence(String id) async {
    final response = await _apiService.deleteGeofence(id);
    return ApiResponse<Object?>.fromJson(response.data);
  }

  Future<Response<dynamic>> getBoundDevices(Map<String, dynamic> query) {
    return _apiService.getBoundGeofenceDevices(query);
  }

  Future<Response<dynamic>> getUnboundDevices(Map<String, dynamic> query) {
    return _apiService.getUnboundGeofenceDevices(query);
  }

  Future<ApiResponse<Object?>> bindDevices(Map<String, dynamic> data) async {
    final response = await _apiService.bindGeofenceDevices(data);
    return ApiResponse<Object?>.fromJson(response.data);
  }

  Future<ApiResponse<Object?>> unbindDevices(Map<String, dynamic> data) async {
    final response = await _apiService.unbindGeofenceDevices(data);
    return ApiResponse<Object?>.fromJson(response.data);
  }
}
