import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/app/routes/route_arguments.dart';
import 'package:car/models/home/device_model.dart';
import 'package:car/models/api_response.dart';
import 'package:car/utils/coord_transform.dart';
import 'package:car/utils/geo_utils.dart';
import 'package:car/utils/car_icon.dart';
import 'tracking_repository.dart';

class TrackingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  TrackingController({TrackingRepository? repository})
    : _repository = repository ?? TrackingRepository();

  final TrackingRepository _repository;
  final DeviceModel? device = DeviceRouteArgs.deviceFrom(Get.arguments);
  final MapController mapController = MapController();

  final currentPosition = Rxn<LatLng>();
  final routePoints = <LatLng>[].obs;
  final speed = 0.0.obs;
  final positionTime = ''.obs;
  final address = ''.obs;
  final connectionStatus = ''.obs;
  final isLoading = false.obs;
  final isTracking = false.obs;
  final errorMessage = ''.obs;
  final pollIntervalSeconds = 1.obs;

  Timer? _pollTimer;
  late final AnimationController _animationController;
  LatLng? _animationStart;
  LatLng? _animationEnd;
  // 最近一次有效的车辆坐标，用作车标兜底：刷新空数据/异常瞬间不丢车标。
  LatLng? _lastKnownPosition;
  int _requestGeneration = 0;
  double _bearing = 0;
  double _targetBearing = 0;

  bool get isOnline => connectionStatus.value.toLowerCase() == 'online';

  List<Marker> get markers {
    // 优先用实时坐标，缺失时回退到最后已知点，避免刷新瞬间车标消失。
    final point = currentPosition.value ?? _lastKnownPosition;
    if (point == null) return const <Marker>[];
    return [
      Marker(
        point: point,
        width: 44,
        height: 48,
        child: Transform.rotate(
          angle: _bearing * 3.141592653589793 / 180,
          child: Image.asset(
            deviceIconPath(online: isOnline, carType: device?.carType),
            width: 36,
            height: 36,
            fit: BoxFit.contain,
            // 每帧重建 marker 时保留旧图，避免图片解析间隙导致车标闪白/丢失。
            gaplessPlayback: true,
          ),
        ),
      ),
    ];
  }

  @override
  void onInit() {
    super.onInit();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(_animatePosition);
    unawaited(loadInitialPosition());
  }

  Future<void> loadInitialPosition() async {
    final currentDevice = device;
    if (currentDevice == null) {
      errorMessage.value = '设备信息不存在';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final position = await _fetchPosition(currentDevice);
      if (isClosed) return;
      if (position == null) {
        errorMessage.value = '暂无有效定位信息';
        return;
      }
      _setPosition(position, animate: false);
    } catch (_) {
      errorMessage.value = '获取车辆位置失败，请稍后重试';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> toggleTracking() async {
    if (isTracking.value) {
      stopTracking();
      return;
    }
    if (currentPosition.value == null) {
      await loadInitialPosition();
    }
    if (isClosed) return;
    errorMessage.value = '';
    isTracking.value = true;
    _startPolling();
    await refreshPosition();
  }

  void stopTracking() {
    isTracking.value = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _animationController.stop();
  }

  Future<void> refreshPosition() async {
    final currentDevice = device;
    if (currentDevice == null || isLoading.value) return;
    isLoading.value = true;
    final generation = ++_requestGeneration;
    try {
      final position = await _fetchPosition(currentDevice);
      if (isClosed || generation != _requestGeneration) return;
      if (position == null) {
        if (errorMessage.value.isEmpty) errorMessage.value = '暂无有效定位信息';
        return;
      }
      errorMessage.value = '';
      _setPosition(position, animate: currentPosition.value != null);
    } catch (_) {
      if (!isClosed && generation == _requestGeneration) {
        errorMessage.value = '位置更新失败';
      }
    } finally {
      if (!isClosed && generation == _requestGeneration) {
        isLoading.value = false;
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(seconds: pollIntervalSeconds.value),
      (_) => unawaited(refreshPosition()),
    );
  }

  Future<Map<String, dynamic>?> _fetchPosition(
    DeviceModel currentDevice,
  ) async {
    final response = await _repository.fetchLastPosition(<String, dynamic>{
      'deviceId': currentDevice.deviceId,
      'deviceids': currentDevice.deviceNo ?? currentDevice.deviceId,
      if (currentDevice.deptId != null && currentDevice.deptId!.isNotEmpty)
        'deptId': currentDevice.deptId,
    });
    final result = ApiResponse<Object?>.fromJson(response.data);
    if (result.isTokenExpired) {
      errorMessage.value = '登录状态已失效';
      return null;
    }
    if (!result.isSuccess) {
      errorMessage.value = result.message.isEmpty
          ? '获取车辆位置失败，请稍后重试'
          : result.message;
      return null;
    }
    return _firstPosition(result.data ?? result.raw['data']);
  }

  Map<String, dynamic>? _firstPosition(Object? value) {
    if (value is List && value.isNotEmpty) {
      return _positionMap(value.first);
    }
    final data = jsonMapFrom(value);
    if (data.isEmpty) return null;
    for (final key in const ['list', 'rows', 'positions', 'data']) {
      final list = data[key];
      if (list is List && list.isNotEmpty) {
        final item = _positionMap(list.first);
        if (item != null) return item;
      }
    }
    return _positionMap(data);
  }

  Map<String, dynamic>? _positionMap(Object? value) {
    final data = jsonMapFrom(value);
    final longitude = nullableDoubleValue(data['longitude']);
    final latitude = nullableDoubleValue(data['latitude']);
    if (longitude == null ||
        latitude == null ||
        !isValidCoordinate(longitude, latitude)) {
      return null;
    }
    return data;
  }

  void _setPosition(Map<String, dynamic> data, {required bool animate}) {
    final longitude = nullableDoubleValue(data['longitude'])!;
    final latitude = nullableDoubleValue(data['latitude'])!;
    final next = transformToGCJ02(longitude, latitude);
    _lastKnownPosition = next;
    final nextSpeed = nullableDoubleValue(data['speed']) ?? 0;
    final direction =
        nullableDoubleValue(
          data['direction'] ?? data['course'] ?? data['heading'],
        ) ??
        (currentPosition.value == null
            ? 0
            : GeoUtils.bearingDegrees(currentPosition.value!, next));

    speed.value = nextSpeed;
    positionTime.value =
        (data['positionUpdateTime'] ??
                data['deviceTime'] ??
                data['gpsTime'] ??
                data['time'] ??
                '')
            .toString();
    address.value = (data['address'] ?? data['location'] ?? '').toString();
    connectionStatus.value = (data['connectionStatus'] ?? data['status'] ?? '')
        .toString();
    _targetBearing = (direction % 360 + 360) % 360;

    final previous = currentPosition.value;
    if (previous == null || !animate) {
      _animationController.stop();
      currentPosition.value = next;
      _bearing = _targetBearing;
      _appendRoutePoint(next, reset: previous == null);
      _moveMap(next);
      return;
    }

    final distance = GeoUtils.distanceMeters(previous, next);
    // GPS 异常造成的极端跳变直接落位，避免拉出长线。
    if (distance > 500) {
      _animationController.stop();
      currentPosition.value = next;
      _bearing = _targetBearing;
      _appendRoutePoint(next, reset: true);
      _moveMap(next);
      return;
    }

    // 以轮询间隔为动画时长，让车标在「上一个点 → 下一个点」之间匀速移动，
    // 恰好在下次刷新到达时到位：既不会提前到位后空等，也不会瞬移。
    _animationStart = previous;
    _animationEnd = next;
    _animationController.duration = Duration(seconds: pollIntervalSeconds.value);
    _animationController.forward(from: 0);
    _appendRoutePoint(next);
  }

  void _animatePosition() {
    final start = _animationStart;
    final end = _animationEnd;
    if (start == null || end == null || isClosed) return;
    final t = Curves.linear.transform(_animationController.value);
    currentPosition.value = GeoUtils.interpolate(start, end, t);
    _bearing = GeoUtils.interpolateBearing(_bearing, _targetBearing, t);
    _moveMap(currentPosition.value!);
  }

  void _appendRoutePoint(LatLng point, {bool reset = false}) {
    if (reset) {
      routePoints.assignAll([point]);
      return;
    }
    if (routePoints.isNotEmpty &&
        GeoUtils.distanceMeters(routePoints.last, point) < 1) {
      return;
    }
    routePoints.add(point);
    if (routePoints.length > 500) {
      routePoints.removeAt(0);
    }
  }

  void _moveMap(LatLng point) {
    try {
      mapController.move(point, mapController.camera.zoom);
    } catch (_) {
      // MapController is not attached before the first frame.
    }
  }

  @override
  void onClose() {
    _requestGeneration++;
    stopTracking();
    _animationController
      ..removeListener(_animatePosition)
      ..dispose();
    super.onClose();
  }
}
