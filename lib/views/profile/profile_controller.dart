import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../../app/routes/router_instance.dart';
import '../../models/api_response.dart';
import '../../services/auth_session_service.dart';
import '../../services/session_expiry_coordinator.dart';
import '../../utils/logger.dart';
import '../../utils/session.dart';
import '../../models/profile/profile_model.dart';
import 'profile_repository.dart';

class ProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  ProfileController({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;
  final AuthSessionService _authSessionService = AuthSessionService();
  final isLoggedIn = false.obs;
  final profile = Rxn<UserProfileModel>();
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
    // 先用本地缓存渲染首屏，再点亮登录态：避免「车主用户 / 0」这类占位文案
    // 闪一下才跳成真实用户名与车辆数；随后仍由接口静默刷新为最新数据。
    await _restoreCached();
    if (await isLogin()) await fetchProfile();
  }

  /// 读取上次成功请求后缓存的资料与车辆数，用于首屏即时展示。
  Future<void> _restoreCached() async {
    final raw = await getSession(SessionKeys.userProfile);
    if (raw != null && raw.isNotEmpty) {
      try {
        final cached = UserProfileModel.fromJson(jsonMapFrom(jsonDecode(raw)));
        if (!_isClosed) profile.value = cached;
      } catch (_) {
        // 缓存结构异常时忽略，等接口返回覆盖。
      }
    }
    final parsed = int.tryParse(
      await getSession(SessionKeys.profileVehicleCount) ?? '',
    );
    if (parsed != null && !_isClosed) vehicleCount.value = parsed;
  }

  /// 接口获取成功后回写缓存，保证下次进入首屏即为最新数据。
  Future<void> _persistCached() async {
    try {
      final current = profile.value;
      if (current != null) {
        await setSession(
          SessionKeys.userProfile,
          jsonEncode(current.toJson()),
        );
      }
      await setSession(
        SessionKeys.profileVehicleCount,
        '${vehicleCount.value}',
      );
    } catch (_) {
      // 缓存写入失败不影响页面展示，忽略。
    }
  }

  /// 退出登录时清掉本地缓存，避免下个账号进入时先闪出上一个账号的资料。
  Future<void> _clearCached() async {
    try {
      await deleteSession(SessionKeys.userProfile);
      await deleteSession(SessionKeys.profileVehicleCount);
    } catch (_) {
      // 缓存清理失败不影响退出流程。
    }
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
        profile.value = profileResult.data == null
            ? null
            : UserProfileModel.fromJson(profileResult.data!);
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
      // 成功后回写缓存：下次进入首屏直接展示本次的最新数据。
      await _persistCached();
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
      await _clearCached();
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
