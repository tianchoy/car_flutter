import 'dart:async';
import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../model/home/device_detail_model.dart';
import '../../model/home/device_model.dart';
import '../../model/home/track_summary.dart';
import '../../shared/models/api_response.dart';
import '../../shared/widgets/app_toast.dart';
import '../../utils/CoordTransform.dart';
import '../../utils/Logger.dart';
import '../../utils/session.dart';
import 'home_repository.dart';

class HomeController extends GetxController {
  HomeController({HomeRepository? repository})
    : _repository = repository ?? HomeRepository();

  final HomeRepository _repository;
  final MapController mapController = MapController();
  final isLoading = false.obs;
  final isLoadingDetails = false.obs;
  final isRefreshingPosition = false.obs;
  final errorMessage = ''.obs;
  final isLoggedIn = false.obs;
  final deviceList = <DeviceModel>[].obs;
  final selectedDevice = Rxn<DeviceModel>();
  final deviceDetail = Rxn<DeviceDetailModel>();
  final trackSummary = Rx<TrackSummary>(
    const TrackSummary(tripCount: 0, totalDistanceMeters: 0, averageSpeed: 0),
  );
  final currentPosition = const LatLng(39.9042, 116.4074).obs;
  final devicePosition = Rxn<LatLng>();
  final positionState = 'loading'.obs;

  int _loadGeneration = 0;
  // 详情加载专用编号：确保由「最新一次」请求负责关闭加载态，避免被后续加载抢占后
  // isLoadingDetails 永久停留在 true（表现为首页一直转圈）。
  int _detailsGeneration = 0;
  bool _isClosed = false;

  @override
  void onInit() {
    super.onInit();
    _initializeHomePage();
  }

  Future<void> _initializeHomePage() async {
    await restoreSelectionState();
    await _loadCurrentLocation();
    if (_isClosed) return;
    if (await _checkLoginStatus()) await loadDeviceList();
  }

  Future<bool> _checkLoginStatus() async {
    final token = await _repository.getToken();
    final loggedIn = token != null && token.trim().isNotEmpty;
    if (!_isClosed) isLoggedIn.value = loggedIn;
    return loggedIn;
  }

  Future<void> _loadCurrentLocation() async {
    if (_isClosed) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final position = await _repository.getCurrentPosition();
      if (_isClosed) return;
      if (position != null &&
          isValidCoordinate(position.longitude, position.latitude)) {
        currentPosition.value = transformToGCJ02(
          position.longitude,
          position.latitude,
        );
        _moveToCurrentLocation();
      } else {
        errorMessage.value = '无法获取当前位置';
      }
    } catch (error, stackTrace) {
      if (!_isClosed) {
        errorMessage.value = '获取位置失败，请检查定位权限';
        Log.e('加载位置失败', error: error, stackTrace: stackTrace);
      }
    } finally {
      if (!_isClosed) isLoading.value = false;
    }
  }

  void _moveToCurrentLocation() {
    try {
      mapController.move(currentPosition.value, mapController.camera.zoom);
    } catch (_) {
      // MapController is not attached until the first map frame.
    }
  }

  /// 把地图视角移动到当前选中设备的位置，使车标回到地图中心。
  void _moveToDeviceLocation() {
    final point = devicePosition.value;
    if (point == null) return;
    try {
      mapController.move(point, mapController.camera.zoom);
    } catch (_) {
      // MapController is not attached until the first map frame.
    }
  }

  Future<void> loadDeviceList() async {
    final generation = ++_loadGeneration;
    if (_isClosed) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _repository.getUserDeviceList({'pageSize': 1000});
      if (_isClosed || generation != _loadGeneration) return;
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (result.isTokenExpired) {
        errorMessage.value = '登录已过期，请重新登录';
        return;
      }
      if (!result.isSuccess) {
        errorMessage.value = result.message.isEmpty
            ? '获取设备列表失败'
            : result.message;
        return;
      }

      final data = result.data ?? const <String, dynamic>{};
      final rawList = data['list'] is List
          ? data['list'] as List
          : data['rows'] is List
          ? data['rows'] as List
          : const <dynamic>[];
      final loaded = rawList
          .whereType<Map>()
          .map((item) => DeviceModel.fromJson(jsonMapFrom(item)))
          .where((device) => device.deviceId.isNotEmpty)
          .toList();
      deviceList.assignAll(loaded);
      final device = _restoreSelectedDevice(loaded);
      selectedDevice.value = device;
      if (device == null) {
        _clearSelectedDevicePersistence();
        devicePosition.value = null;
        positionState.value = 'empty';
        return;
      }
      await _loadSelectedDevice(device, generation: generation);
    } catch (error, stackTrace) {
      if (!_isClosed && generation == _loadGeneration) {
        errorMessage.value = '获取设备列表失败，请稍后重试';
        Log.e('获取设备列表失败', error: error, stackTrace: stackTrace);
      }
    } finally {
      if (!_isClosed && generation == _loadGeneration) isLoading.value = false;
    }
  }

  DeviceModel? _restoreSelectedDevice(List<DeviceModel> devices) {
    final savedJson = _sessionJsonValue;
    DeviceModel? device;
    if (savedJson != null) {
      final saved = DeviceModel.fromJson(savedJson);
      device = _findMatchingDevice(devices, saved);
    }
    device ??= devices.firstOrNull;
    if (device != null) {
      unawaited(
        setSession(SessionKeys.selectedDeviceInfo, jsonEncode(device.toJson())),
      );
      final index = devices.indexOf(device);
      unawaited(setSession(SessionKeys.selectedDeviceIndex, '$index'));
    }
    return device;
  }

  JsonMap? get _sessionJsonValue => _savedDeviceJson;
  JsonMap? _savedDeviceJson;

  Future<void> restoreSelectionState() async {
    final raw = await getSession(SessionKeys.selectedDeviceInfo);
    if (raw != null && raw.isNotEmpty) {
      try {
        _savedDeviceJson = jsonMapFrom(jsonDecode(raw));
      } catch (_) {
        _savedDeviceJson = null;
      }
    }
  }

  DeviceModel? _findMatchingDevice(
    List<DeviceModel> devices,
    DeviceModel saved,
  ) {
    if (saved.deviceNo != null && saved.deviceNo!.isNotEmpty) {
      for (final device in devices) {
        if (device.deviceNo == saved.deviceNo) return device;
      }
    }
    if (saved.deviceId.isNotEmpty) {
      for (final device in devices) {
        if (device.deviceId == saved.deviceId) return device;
      }
    }
    return null;
  }

  Future<void> _loadSelectedDevice(
    DeviceModel device, {
    required int generation,
  }) async {
    if (_isClosed || generation != _loadGeneration) return;
    final detailsToken = ++_detailsGeneration;
    isLoadingDetails.value = true;
    positionState.value = 'loading';
    try {
      await Future.wait<void>([
        _loadDeviceDetail(device, generation: generation),
        _loadDevicePosition(device, generation: generation),
        _loadTrackSummary(device, generation: generation),
      ]);
    } finally {
      if (!_isClosed && detailsToken == _detailsGeneration) {
        isLoadingDetails.value = false;
      }
    }
  }

  Future<void> _loadDeviceDetail(
    DeviceModel device, {
    required int generation,
  }) async {
    final response = await _repository.getDeviceInfo(device.deviceId);
    if (_isClosed || generation != _loadGeneration) return;
    final result = ApiResponse<JsonMap>.fromJson(
      response.data,
      dataParser: jsonMapFrom,
    );
    if (result.isSuccess && result.data != null) {
      deviceDetail.value = DeviceDetailModel.fromJson(result.data!);
    }
  }

  Future<void> _loadDevicePosition(
    DeviceModel device, {
    required int generation,
  }) async {
    try {
      final response = await _repository
          .getDeviceLastPosition(<String, dynamic>{
            'deviceId': device.deviceId,
            if (device.deviceNo != null && device.deviceNo!.isNotEmpty)
              'deviceids': device.deviceNo,
          });
      if (_isClosed || generation != _loadGeneration) return;
      final result = ApiResponse<List<Object?>>.fromJson(
        response.data,
        dataParser: jsonListFrom,
      );
      final raw = result.data?.whereType<Map>().firstOrNull;
      if (!result.isSuccess || raw == null) {
        positionState.value = 'empty';
        devicePosition.value = null;
        return;
      }
      final longitude = nullableDoubleValue(raw['longitude']);
      final latitude = nullableDoubleValue(raw['latitude']);
      if (longitude == null ||
          latitude == null ||
          !isValidCoordinate(longitude, latitude)) {
        positionState.value = 'invalid';
        devicePosition.value = null;
        return;
      }
      devicePosition.value = transformToGCJ02(longitude, latitude);
      positionState.value = 'available';
    } catch (error, stackTrace) {
      if (!_isClosed && generation == _loadGeneration) {
        positionState.value = 'failed';
        Log.e('加载设备位置失败', error: error, stackTrace: stackTrace);
      }
    }
  }

  Future<void> _loadTrackSummary(
    DeviceModel device, {
    required int generation,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final response = await _repository.getTrackPos(<String, dynamic>{
      'deviceNo': device.deviceNo ?? device.deviceId,
      'startTime': _formatDateTime(start),
      'endTime': _formatDateTime(now),
      'minParkTime': 120,
      'withStop': false,
      'withPos': false,
      'withTrip': true,
    });
    if (_isClosed || generation != _loadGeneration) return;
    final result = ApiResponse<JsonMap>.fromJson(
      response.data,
      dataParser: jsonMapFrom,
    );
    trackSummary.value = result.isSuccess
        ? TrackSummary.fromJson(result.data)
        : const TrackSummary(
            tripCount: 0,
            totalDistanceMeters: 0,
            averageSpeed: 0,
          );
  }

  String _formatDateTime(DateTime value) {
    String pad(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${pad(value.month)}-${pad(value.day)} '
        '${pad(value.hour)}:${pad(value.minute)}:${pad(value.second)}';
  }

  Future<void> selectDevice(DeviceModel device) async {
    final index = deviceList.indexOf(device);
    if (index < 0) return;
    selectedDevice.value = device;
    await setSession(
      SessionKeys.selectedDeviceInfo,
      jsonEncode(device.toJson()),
    );
    await setSession(SessionKeys.selectedDeviceIndex, '$index');
    final generation = ++_loadGeneration;
    await _loadSelectedDevice(device, generation: generation);
  }

  Future<void> refreshLocation() async {
    final device = selectedDevice.value;
    if (device == null) {
      await _loadCurrentLocation();
      return;
    }
    final generation = ++_loadGeneration;
    isRefreshingPosition.value = true;
    try {
      await _loadDevicePosition(device, generation: generation);
    } finally {
      if (!_isClosed) isRefreshingPosition.value = false;
    }
    // 用户把地图移开后，刷新位置应让车标回到地图中心。
    if (!_isClosed && generation == _loadGeneration) _moveToDeviceLocation();
  }

  /// 下拉 / 点击「刷新」：重新拉取设备列表并加载选中设备的详情/位置/轨迹。
  /// 与 [loadDeviceList] 保持一致，保证新添加的设备能通过「刷新」出现在首页；
  /// 数据就绪后让定位地图回到选中设备的位置。
  Future<void> refreshAll() async {
    isRefreshingPosition.value = true;
    try {
      await loadDeviceList();
      if (!_isClosed && devicePosition.value != null) _moveToDeviceLocation();
    } finally {
      if (!_isClosed) isRefreshingPosition.value = false;
    }
  }

  /// 删除设备：成功后刷新设备列表（选中设备若被一并移除会回到未选中态）。
  Future<bool> deleteDevice(DeviceModel device) async {
    try {
      final response = await _repository.deleteDevice(device.deviceId);
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (!result.isSuccess) {
        AppToast.show(
          '提示',
          result.message.isEmpty ? '删除失败' : result.message,
        );
        return false;
      }
      AppToast.show('提示', '删除成功');
      await loadDeviceList();
      return true;
    } catch (error, stackTrace) {
      Log.e('删除设备失败', error: error, stackTrace: stackTrace);
      AppToast.show('提示', '删除失败，请稍后重试');
      return false;
    }
  }

  void _clearSelectedDevicePersistence() {
    unawaited(deleteSession(SessionKeys.selectedDeviceInfo));
    unawaited(deleteSession(SessionKeys.selectedDeviceIndex));
    _savedDeviceJson = null;
  }

  @override
  void onClose() {
    _isClosed = true;
    _loadGeneration++;
    super.onClose();
  }
}
