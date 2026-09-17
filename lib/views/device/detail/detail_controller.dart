import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/app/route_arguments.dart';
import 'package:car/model/home/device_model.dart';
import 'package:car/model/home/device_detail_model.dart';
import 'package:car/model/home/track_summary.dart';
import 'package:car/shared/models/api_response.dart';
import 'package:car/shared/widgets/app_toast.dart';
import 'package:car/utils/CoordTransform.dart';
import 'package:car/utils/Logger.dart';
import 'detail_repository.dart';

class DetailController extends GetxController {
  DetailController({DetailRepository? repository})
    : _detailRepository = repository ?? DetailRepository();

  final DetailRepository _detailRepository;
  final DeviceModel? device = DeviceRouteArgs.deviceFrom(Get.arguments);
  final MapController mapController = MapController();
  final detail = Rxn<DeviceDetailModel>();
  final position = Rxn<JsonMap>();
  final trackSummary = Rx<TrackSummary>(
    const TrackSummary(tripCount: 0, totalDistanceMeters: 0, averageSpeed: 0),
  );
  final address = ''.obs;
  final isLoadingAddress = false.obs;
  /// 上一次成功解析中文地址时所用的坐标；用于判断是否需要再次展示「解析中文地址」。
  final resolvedPosition = Rxn<LatLng>();
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;
  final refreshIntervalSeconds = 5.obs;

  Timer? _refreshTimer;
  int _requestGeneration = 0;

  /// 在线状态：优先以最近一次详情接口返回的 connectionStatus 为准。
  ///
  /// 原实现为 `detail.value?.isOnline == true || device?.deviceStatus == 'online'`，
  /// 但 device 来自路由参数（进入页面后不再更新），只要进页时在线就永远为真，
  /// 导致「设备已离线」无法被感知。现改为：详情给出明确连接状态时以详情为准，
  /// 否则才回退到路由传入的初始状态。
  bool get isOnline {
    final connection = detail.value?.connectionStatus?.trim().toLowerCase();
    if (connection != null && connection.isNotEmpty) {
      return connection == 'online';
    }
    return device?.deviceStatus == 'online';
  }

  LatLng? get mapPosition {
    final rawLatitude = nullableDoubleValue(
      position.value?['latitude'] ?? device?.latitude,
    );
    final rawLongitude = nullableDoubleValue(
      position.value?['longitude'] ?? device?.longitude,
    );
    if (rawLatitude == null ||
        rawLongitude == null ||
        !isValidCoordinate(rawLongitude, rawLatitude)) {
      return null;
    }
    return transformToGCJ02(rawLongitude, rawLatitude);
  }

  String get positionUpdateTime =>
      _stringFromPosition('positionUpdateTime') ??
      _stringFromPosition('lastUpdateTime') ??
      detail.value?.lastUpdateTime ??
      '暂无位置';

  String get signalStrength => _numberText(
    _attributeValue('rssi') ??
        position.value?['signalStrength'] ??
        detail.value?.status.signalStrength,
  );

  String get satelliteCount =>
      _numberText(_attributeValue('sat') ?? position.value?['satelliteCount']);

  String get voltage => _numberText(
    position.value?['voltage'] ?? detail.value?.status.voltage,
    decimals: 1,
  );

  String get batteryPercent => _numberText(
    position.value?['batteryPercent'] ?? detail.value?.status.batteryPercent,
  );

  @override
  void onInit() {
    super.onInit();
    unawaited(loadDetails());
  }

  Future<void> loadDetails() async {
    final currentDevice = device;
    if (currentDevice == null) {
      errorMessage.value = '设备信息不存在';
      return;
    }
    final generation = ++_requestGeneration;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await Future.wait<void>([
        _loadDeviceDetail(currentDevice, generation),
        _loadPosition(currentDevice, generation),
        _loadTrackSummary(currentDevice, generation),
      ]);
      if (!_isCurrent(generation)) return;
      _updateRefreshTimer();
    } catch (error, stackTrace) {
      if (_isCurrent(generation)) {
        errorMessage.value = '加载设备详情失败，请稍后重试';
        Log.e('加载设备详情失败', error: error, stackTrace: stackTrace);
      }
    } finally {
      if (_isCurrent(generation)) isLoading.value = false;
    }
  }

  Future<void> refreshPosition() async {
    final currentDevice = device;
    if (currentDevice == null || isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      await _loadPosition(currentDevice, ++_requestGeneration);
    } catch (error, stackTrace) {
      Log.e('刷新设备位置失败', error: error, stackTrace: stackTrace);
      errorMessage.value = '刷新位置失败，请重试';
    } finally {
      if (!isClosed) isRefreshing.value = false;
    }
  }

  Future<void> moveToCurrentLocation() async {
    await refreshPosition();
    final point = mapPosition;
    if (point == null || isClosed) {
      errorMessage.value = '设备暂无有效定位';
      return;
    }
    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      mapController.move(point, mapController.camera.zoom);
    } catch (error, stackTrace) {
      Log.e('地图移动失败', error: error, stackTrace: stackTrace);
    }
  }

  /// 手动解析中文地址。
  /// 详情加载与自动刷新均不再调用逆地理接口，避免频繁请求，仅在用户点击「解析中文地址」时触发。
  Future<void> parseAddress() async {
    final currentDevice = device;
    if (currentDevice == null) return;
    await _loadAddress(currentDevice, ++_requestGeneration);
  }

  /// 断油电 / 恢复油电：走 /command/sendCmd 老接口。
  /// 参考 carConnectInternet：恢复油电 predictCmdId=2/type=2，断开油电 predictCmdId=1/type=1。
  Future<bool> sendPowerCommand({
    required bool restore,
    String password = '',
  }) async {
    final currentDevice = device;
    final deviceNo = currentDevice?.deviceNo ?? currentDevice?.deviceId ?? '';
    if (deviceNo.isEmpty) {
      AppToast.show('提示', '设备信息不存在');
      return false;
    }
    try {
      final response = await _detailRepository.sendCommand(
        <String, dynamic>{
          'deviceNo': deviceNo,
          'password': password,
          'params': <String>['1111'],
          'predictCmdId': restore ? 2 : 1,
          'type': restore ? 2 : 1,
        },
        // 恢复油电用 PUT，断开油电用 POST。
        put: restore,
      );
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (!result.isSuccess) {
        AppToast.show(
          '提示',
          result.message.isEmpty ? '操作失败' : result.message,
        );
        return false;
      }
      AppToast.show('提示', restore ? '恢复油电成功' : '断开油电成功');
      return true;
    } catch (error, stackTrace) {
      Log.e('发送油电指令失败', error: error, stackTrace: stackTrace);
      AppToast.show('提示', '操作失败，请稍后重试');
      return false;
    }
  }

  void setRefreshInterval(int seconds) {
    refreshIntervalSeconds.value = seconds;
    _updateRefreshTimer();
  }

  Future<void> _loadDeviceDetail(
    DeviceModel currentDevice,
    int generation,
  ) async {
    final response = await _detailRepository.fetchDeviceInfo(
      currentDevice.deviceId,
    );
    if (!_isCurrent(generation)) return;
    final result = ApiResponse<JsonMap>.fromJson(
      response.data,
      dataParser: jsonMapFrom,
    );
    if (result.isSuccess && result.data != null) {
      detail.value = DeviceDetailModel.fromJson(result.data!);
    } else if (result.message.isNotEmpty) {
      errorMessage.value = result.message;
    }
  }

  Future<void> _loadPosition(DeviceModel currentDevice, int generation) async {
    final response = await _detailRepository
        .fetchDevicePosition(<String, dynamic>{
          'deviceId': currentDevice.deviceId,
          if (currentDevice.deviceNo?.isNotEmpty == true)
            'deviceids': currentDevice.deviceNo,
        });
    if (!_isCurrent(generation)) return;
    final result = ApiResponse<List<Object?>>.fromJson(
      response.data,
      dataParser: jsonListFrom,
    );
    final raw = result.data?.whereType<Map>().firstOrNull;
    if (result.isSuccess && raw != null) {
      position.value = jsonMapFrom(raw);
    } else if (result.isSuccess) {
      position.value = null;
      errorMessage.value = '暂无设备定位数据';
    }
  }

  Future<void> _loadTrackSummary(
    DeviceModel currentDevice,
    int generation,
  ) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final response = await _detailRepository.fetchTrackData(<String, dynamic>{
      'deviceNo': currentDevice.deviceNo ?? currentDevice.deviceId,
      'startTime': _formatDateTime(start),
      'endTime': _formatDateTime(now),
      'minParkTime': 120,
      'withStop': false,
      'withPos': false,
      'withTrip': true,
    });
    if (!_isCurrent(generation)) return;
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

  /// 当前原始经纬度（WGS84，未做坐标转换），用于与已解析坐标做对比。
  LatLng? get _currentRawPosition {
    final latitude = nullableDoubleValue(position.value?['latitude']);
    final longitude = nullableDoubleValue(position.value?['longitude']);
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  /// 是否展示「解析中文地址」按钮：
  /// - 从未解析过 → 展示；
  /// - 解析过，但刷新后经纬度改变 → 重新展示；
  /// - 解析过且坐标未变 → 隐藏。
  bool get showParseAddressButton {
    final resolved = resolvedPosition.value;
    if (resolved == null) return true;
    final current = _currentRawPosition;
    if (current == null) return false;
    return current.latitude != resolved.latitude ||
        current.longitude != resolved.longitude;
  }

  Future<void> _loadAddress(DeviceModel currentDevice, int generation) async {
    if (!_isCurrent(generation)) return;
    final raw = _currentRawPosition;
    final current = _existingAddress;
    if (current != null) {
      address.value = current;
      resolvedPosition.value = raw;
      return;
    }
    final latitude = nullableDoubleValue(
      position.value?['latitude'] ?? currentDevice.latitude,
    );
    final longitude = nullableDoubleValue(
      position.value?['longitude'] ?? currentDevice.longitude,
    );
    if (latitude == null ||
        longitude == null ||
        !isValidCoordinate(longitude, latitude)) {
      address.value = '';
      resolvedPosition.value = raw;
      return;
    }
    isLoadingAddress.value = true;
    try {
      final value = await _detailRepository.fetchAddress(<String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        // 逆地理编码需携带设备标识（参考 carConnectInternet），补齐缺失的 deviceId。
        'deviceId': currentDevice.deviceId,
        if (currentDevice.deviceNo?.isNotEmpty == true)
          'deviceNo': currentDevice.deviceNo,
      });
      if (_isCurrent(generation) && value != null) {
        address.value = value;
        resolvedPosition.value = raw;
      }
    } catch (error, stackTrace) {
      Log.e('获取中文地址失败', error: error, stackTrace: stackTrace);
    } finally {
      if (_isCurrent(generation)) isLoadingAddress.value = false;
    }
  }

  String? get _existingAddress {
    for (final source in <Object?>[
      position.value?['address'],
      position.value?['location'],
      detail.value?.address,
    ]) {
      final value = source?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String get displayAddress =>
      address.value.trim().isEmpty ? '暂无中文地址' : address.value.trim();

  void _updateRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (!isOnline || refreshIntervalSeconds.value <= 0 || isClosed) return;
    _refreshTimer = Timer.periodic(
      Duration(seconds: refreshIntervalSeconds.value),
      (_) {
        // 设备离线时停止自动刷新（即使仍停留在详情页），避免无意义地轮询接口。
        if (!isOnline) {
          pauseAutoRefresh();
          return;
        }
        refreshPosition();
      },
    );
  }

  /// 离开本页（另一页面压栈）时暂停自动刷新，避免后台持续轮询。
  void pauseAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 返回本页（上层页面出栈）时恢复自动刷新。
  void resumeAutoRefresh() {
    if (isClosed) return;
    _updateRefreshTimer();
  }

  bool _isCurrent(int generation) =>
      !isClosed && generation == _requestGeneration;

  Object? _attributeValue(String key) {
    final attribute = position.value?['attribute'];
    return attribute is Map ? attribute[key] : null;
  }

  String? _stringFromPosition(String key) {
    final value = position.value?[key];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String _numberText(Object? value, {int decimals = 0}) {
    final number = nullableDoubleValue(value);
    if (number == null) return '--';
    return decimals == 0
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(decimals);
  }

  String _formatDateTime(DateTime value) {
    String pad(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${pad(value.month)}-${pad(value.day)} '
        '${pad(value.hour)}:${pad(value.minute)}:${pad(value.second)}';
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _requestGeneration++;
    super.onClose();
  }
}
