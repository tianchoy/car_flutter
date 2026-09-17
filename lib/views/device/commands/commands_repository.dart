import 'package:dio/dio.dart';

import 'package:car/shared/services/api_service.dart';

class CommandsRepository {
  CommandsRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchAvailableCommands(String deviceId) =>
      _apiService.getAvailableCommands(deviceId);

  Future<Response<dynamic>> sendCommand(Map<String, dynamic> data) =>
      _apiService.sendAppCommand(data);

  Future<Response<dynamic>> fetchHistory(Map<String, dynamic> query) =>
      _apiService.getAppCommandHistory(query);

  Future<Response<dynamic>> fetchDetail(String commandId) =>
      _apiService.getAppCommandDetail(commandId);

  Future<Response<dynamic>> retry(String commandId) =>
      _apiService.retryAppCommand(commandId);
}
