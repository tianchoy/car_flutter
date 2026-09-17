import 'dart:async';

import 'package:get/get.dart';

import '../../app/routes/router_instance.dart';
import '../../models/api_response.dart';
import '../../services/auth_session_service.dart';
import '../../services/session_expiry_coordinator.dart';
import '../../utils/logger.dart';
import '../../models/profile/profile_model.dart';
import 'profile_repository.dart';

class ProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  ProfileController({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;
  final AuthSessionService _authSessionService = AuthSessionService();
  final isLoggedIn = false.obs;
  final profile = Rx<UserModel?>(null);
  final vehicleCount = 0.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  bool _isClosed = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (await isLogin()) await fetchProfile();
  }

  Future<void> fetchProfile() async {
    if (_isClosed) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final responses = await Future.wait([
        _repository.fetchProfile(),
        _repository.fetchDevices(),
      ]);
      if (_isClosed) return;

      final profileResult = ApiResponse<JsonMap>.fromJson(
        responses[0].data,
        dataParser: jsonMapFrom,
      );
      if (profileResult.isTokenExpired) {
        await SessionExpiryCoordinator.handleExpiredSession();
        return;
      }
      if (profileResult.isSuccess) {
        profile.value = UserModel.fromJson(
          profileResult.data ?? const <String, dynamic>{},
        );
      } else {
        errorMessage.value = profileResult.message;
        Log.w('获取用户信息失败: ${profileResult.message}');
      }

      final devicesResult = ApiResponse<JsonMap>.fromJson(
        responses[1].data,
        dataParser: jsonMapFrom,
      );
      if (devicesResult.isTokenExpired) {
        await SessionExpiryCoordinator.handleExpiredSession();
        return;
      }
      if (devicesResult.isSuccess) {
        final data = devicesResult.data ?? const <String, dynamic>{};
        final list = data['list'] is List
            ? data['list'] as List
            : data['rows'] is List
            ? data['rows'] as List
            : const <dynamic>[];
        vehicleCount.value = intValue(
          data['totalCount'] ?? data['total'],
          fallback: list.length,
        );
      }
    } catch (error, stackTrace) {
      if (!_isClosed) {
        errorMessage.value = '获取用户信息失败，请稍后重试';
        Log.e('获取用户中心数据失败', error: error, stackTrace: stackTrace);
      }
    } finally {
      if (!_isClosed) isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    if (await isLogin()) {
      await fetchProfile();
    } else {
      isLoggedIn.value = false;
      profile.value = null;
      vehicleCount.value = 0;
    }
  }

  Future<void> logout() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _authSessionService.logout();
      if (!_isClosed) {
        profile.value = null;
        vehicleCount.value = 0;
        isLoggedIn.value = false;
      }
      Get.offAllNamed(Routes.login);
    } finally {
      if (!_isClosed) isLoading.value = false;
    }
  }

  Future<bool> isLogin() async {
    final token = await _repository.getToken();
    final loggedIn = token != null && token.trim().isNotEmpty;
    if (!_isClosed) isLoggedIn.value = loggedIn;
    return loggedIn;
  }

  @override
  void onClose() {
    _isClosed = true;
    super.onClose();
  }
}
