import 'package:dio/dio.dart';

import 'api_http.dart';
import 'url.dart';

/// Low-level source-compatible endpoint facade.
///
/// Feature repositories should parse these raw transport responses into typed
/// models rather than leaking Dio into controllers.
class ApiService {
  ApiService({HttpService? httpService})
    : _httpService = httpService ?? HttpService(baseUrl: AppConfig.apiBaseUrl);

  final HttpService _httpService;

  Future<Response<dynamic>> personalPasswordLogin({
    required String username,
    required String password,
  }) {
    return _httpService.post<dynamic>(
      ApiEndpoints.authLogin,
      data: <String, dynamic>{
        'grantType': 'password',
        'username': username,
        'password': password,
        'tenantId': AppConfig.tenantId,
        'clientId': AppConfig.clientId,
      },
    );
  }

  /// Compatibility alias for the existing password-login repository.
  Future<Response<dynamic>> login(String username, String password) {
    return personalPasswordLogin(username: username, password: password);
  }

  Future<Response<dynamic>> smsLogin({
    required String phoneNumber,
    required String smsCode,
  }) {
    return _httpService.post<dynamic>(
      ApiEndpoints.authLogin,
      data: <String, dynamic>{
        'grantType': 'sms',
        'phonenumber': phoneNumber,
        'smsCode': smsCode,
        'tenantId': AppConfig.tenantId,
        'clientId': AppConfig.clientId,
      },
    );
  }

  Future<Response<dynamic>> sendSmsCode({
    required String phoneNumber,
    String? scene,
  }) {
    return _httpService.get<dynamic>(
      ApiEndpoints.smsCode,
      queryParameters: <String, dynamic>{
        'phonenumber': phoneNumber,
        'tenantId': AppConfig.tenantId,
        if (scene != null && scene.isNotEmpty) 'scene': scene,
      },
    );
  }

  Future<Response<dynamic>> register(Map<String, dynamic> data) {
    return _httpService.post<dynamic>(ApiEndpoints.register, data: data);
  }

  Future<Response<dynamic>> resetForgotPassword(Map<String, dynamic> data) {
    return _httpService.post<dynamic>(
      ApiEndpoints.forgotPasswordReset,
      data: data,
    );
  }

  Future<Response<dynamic>> changePassword(Map<String, dynamic> data) {
    return _httpService.post<dynamic>(ApiEndpoints.changePassword, data: data);
  }

  Future<Response<dynamic>> logout() {
    return _httpService.post<dynamic>(ApiEndpoints.logout);
  }

  /// 获取当前登录用户个人信息（GET /system/appUser/profile）。
  /// 仅需登录态，token 由 HttpService 统一放在请求头。
  Future<Response<dynamic>> getUserProfile() {
    return _httpService.get<dynamic>(ApiEndpoints.appUserProfile);
  }

  Future<Response<dynamic>> getUserDeviceList(Map<String, dynamic> data) {
    return _httpService.post<dynamic>(ApiEndpoints.userDeviceList, data: data);
  }

  Future<Response<dynamic>> getDeviceLastPosition(Map<String, dynamic> query) {
    return _httpService.get<dynamic>(
      ApiEndpoints.deviceLastPosition,
      queryParameters: query,
    );
  }

  Future<Response<dynamic>> getDeviceInfo(String deviceId) {
    return _httpService.get<dynamic>('${ApiEndpoints.deviceInfo}$deviceId');
  }

  Future<Response<dynamic>> addDevice(Map<String, dynamic> data) {
    return _httpService.post<dynamic>(ApiEndpoints.addDevice, data: data);
  }

  Future<Response<dynamic>> deleteDevice(String deviceId) {
    return _httpService.post<dynamic>(
      ApiEndpoints.deleteDevice,
      data: <String, dynamic>{'deviceId': deviceId},
    );
  }

  Future<Response<dynamic>> updateDevice(Map<String, dynamic> data) {
    return _httpService.put<dynamic>(ApiEndpoints.updateDevice, data: data);
  }

  Future<Response<dynamic>> getGeocoderAddress(Map<String, dynamic> query) {
    return _httpService.get<dynamic>(
      ApiEndpoints.geocoderAddress,
      queryParameters: query,
    );
  }

  Future<Response<dynamic>> getGeofenceList() {
    return _httpService.get<dynamic>(ApiEndpoints.geofence);
  }

  Future<Response<dynamic>> addGeofence(Map<String, dynamic> data) {
    return _httpService.post<dynamic>(ApiEndpoints.geofence, data: data);
  }

  Future<Response<dynamic>> updateGeofence(Map<String, dynamic> data) {
    return _httpService.put<dynamic>(ApiEndpoints.geofence, data: data);
  }

  Future<Response<dynamic>> deleteGeofence(String fenceId) {
    return _httpService.delete<dynamic>(
      '${ApiEndpoints.geofenceDelete}$fenceId',
    );
  }

  Future<Response<dynamic>> getBoundGeofenceDevices(
    Map<String, dynamic> query,
  ) {
    return _httpService.get<dynamic>(
      ApiEndpoints.boundGeofenceDevices,
      queryParameters: query,
    );
  }

  Future<Response<dynamic>> getUnboundGeofenceDevices(
    Map<String, dynamic> query,
  ) {
    return _httpService.get<dynamic>(
      ApiEndpoints.unboundGeofenceDevices,
      queryParameters: query,
    );
  }

  Future<Response<dynamic>> bindGeofenceDevices(Map<String, dynamic> data) {
    return _httpService.post<dynamic>(
      ApiEndpoints.bindGeofenceDevices,
      data: data,
    );
  }

  Future<Response<dynamic>> unbindGeofenceDevices(Map<String, dynamic> data) {
    return _httpService.delete<dynamic>(
      ApiEndpoints.unbindGeofenceDevices,
      data: data,
    );
  }

  Future<Response<dynamic>> getTrackPos(Map<String, dynamic> query) {
    return _httpService.get<dynamic>(
      ApiEndpoints.trackPosition,
      queryParameters: query,
    );
  }

  Future<Response<dynamic>> getMessagesList({
    Map<String, dynamic>? queryParameters,
  }) {
    return _httpService.get<dynamic>(
      ApiEndpoints.messages,
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> getUnreadMessageCount() {
    return _httpService.get<dynamic>(ApiEndpoints.messageUnreadCount);
  }

  Future<Response<dynamic>> markMessageRead(String messageId) {
    return _httpService.get<dynamic>('${ApiEndpoints.messageDetail}$messageId');
  }

  Future<Response<dynamic>> getAvailableCommands(String deviceId) {
    return _httpService.get<dynamic>(
      ApiEndpoints.availableAppCommands,
      queryParameters: <String, dynamic>{'deviceId': deviceId},
    );
  }

  /// 老的指令下发接口（/command/sendCmd），用于断油电 / 恢复油电。
  /// 按接口文档：断开油电用 POST，恢复油电用 PUT。
  Future<Response<dynamic>> sendCommand(
    Map<String, dynamic> data, {
    bool put = false,
  }) {
    return put
        ? _httpService.put<dynamic>(ApiEndpoints.commandSend, data: data)
        : _httpService.post<dynamic>(ApiEndpoints.commandSend, data: data);
  }

  Future<Response<dynamic>> sendAppCommand(Map<String, dynamic> data) {
    return _httpService.post<dynamic>(ApiEndpoints.sendAppCommand, data: data);
  }

  Future<Response<dynamic>> getAppCommandHistory(Map<String, dynamic> query) {
    return _httpService.get<dynamic>(
      ApiEndpoints.appCommandHistory,
      queryParameters: query,
    );
  }

  Future<Response<dynamic>> getAppCommandDetail(String commandId) {
    return _httpService.get<dynamic>(
      '${ApiEndpoints.appCommandDetail}$commandId',
    );
  }

  Future<Response<dynamic>> retryAppCommand(String commandId) {
    return _httpService.get<dynamic>(
      '${ApiEndpoints.retryAppCommand}$commandId',
    );
  }

  Future<Response<dynamic>> getDeviceShareEnabled() {
    return _httpService.get<dynamic>(ApiEndpoints.deviceShareEnabled);
  }

  Future<Response<dynamic>> createDeviceShare(Map<String, dynamic> data) {
    return _httpService.post<dynamic>(ApiEndpoints.deviceShare, data: data);
  }

  Future<Response<dynamic>> getSentDeviceShares(Map<String, dynamic> query) {
    return _httpService.get<dynamic>(
      ApiEndpoints.deviceShareSent,
      queryParameters: query,
    );
  }

  Future<Response<dynamic>> getReceivedDeviceShares(
    Map<String, dynamic> query,
  ) {
    return _httpService.get<dynamic>(
      ApiEndpoints.deviceShareReceived,
      queryParameters: query,
    );
  }

  Future<Response<dynamic>> getDeviceSharees(
    String deviceId,
    Map<String, dynamic> query,
  ) {
    return _httpService.get<dynamic>(
      '${ApiEndpoints.deviceShare}/$deviceId/sharees',
      queryParameters: query,
    );
  }

  Future<Response<dynamic>> revokeDeviceShare(String shareId) {
    return _httpService.delete<dynamic>('${ApiEndpoints.deviceShare}/$shareId');
  }

  Future<Response<dynamic>> exitDeviceShare(String deviceId) {
    return _httpService.post<dynamic>(
      ApiEndpoints.deviceShareExit,
      data: <String, dynamic>{'deviceId': deviceId},
    );
  }
}
