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
import 'package:car/services/device_position_cache.dart';
import 'tracking_repository.dart';

class TrackingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  TrackingController({TrackingRepository? repository})
    : _repository = repository ?? TrackingRepository();

  final TrackingRepository _repository;
  final DeviceRouteArgs? _args = DeviceRouteArgs.parse(Get.arguments);
  DeviceModel? get device => _args?.device;
  final MapController mapController = MapController();

  final currentPosition = Rxn<LatLng>();

  /// 地图初始中心：首次定位返回前先用缓存位置，避免先显示默认的北京坐标。
  final initialCenter = Rxn<LatLng>();
  final routePoints = <LatLng>[].obs;
  final speed = 0.0.obs;
  final address = ''.obs;
  final connectionStatus = ''.obs;
  final isLoading = false.obs;
  // 跟踪中后台轮询的刷新状态：不驱动 loading 浮层与按钮禁用，避免每秒闪动。
  final isRefreshing = false.obs;
  final isTracking = false.obs;
  final errorMessage = ''.obs;
  // 设备在运动中每 5 秒上传一次定位，按相同节奏轮询可及时取到新数据且避免无效请求。
  final pollIntervalSeconds = 5.obs;

  Timer? _pollTimer;
  late final AnimationController _animationController;
  LatLng? _animationStart;
  LatLng? _animationEnd;
  // 最近一次有效的车辆坐标，用作车标兜底：刷新空数据/异常瞬间不丢车标。
  LatLng? _lastKnownPosition;
  // 最近一次成功取到「新位置」的本地时间，用于推算动画时长（≈设备上报间隔）。
  DateTime? _lastReceivedAt;
  // 更新车头朝向所需的最小位移（米）：小于该值视为 GPS 漂移，保持原朝向。
  static const double _minBearingDistanceMeters = 10;
  int _requestGeneration = 0;

  /// 车标已抵达的上报点下标（routePoints 内）：未抵达的点一律算未行驶。
  /// 车标正在 A→B 途中时 C 上报，车标会改为直接插值到 C，此时 B 尚未抵达，
  /// 已抵达下标仍停在 A，蓝色不会越过车标。
  int _reachedIndex = 0;
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

  /// 已行驶部分（蓝色实线）：起点 … 车标当前所在位置。
  ///
  /// 以「车标已抵达的第 [_reachedIndex] 个上报点」为界：只有已抵达的点才算已行驶。
  /// 车标还在 A→B 途中时新点 C 上报，B 仍属于未抵达，因此不会出现 B（甚至 B→C）
  /// 先于车标被染成蓝色的问题。
  List<LatLng> get traveledRoutePoints {
    if (routePoints.isEmpty) return const <LatLng>[];
    final current = currentPosition.value;
    if (current == null) return routePoints.toList(growable: false);
    final reached = _reachedIndex.clamp(0, routePoints.length - 1);
    final traveled = routePoints.take(reached + 1).toList();
    if (traveled.isEmpty ||
        GeoUtils.distanceMeters(traveled.last, current) >= 1) {
      traveled.add(current);
    }
    return traveled;
  }

  /// 未行驶部分（淡灰色虚线）：车标当前位置 → 所有尚未抵达的上报点。
  List<LatLng> get untraveledRoutePoints {
    final current = currentPosition.value;
    if (current == null) return const <LatLng>[];
    final reached = _reachedIndex.clamp(0, routePoints.length - 1);
    // 已抵达最后一个上报点：没有未行驶路段。
    if (reached >= routePoints.length - 1) return const <LatLng>[];
    return <LatLng>[current, ...routePoints.skip(reached + 1)];
  }

  @override
  void onInit() {
    super.onInit();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(_animatePosition);
    // 动画走完即视为抵达目标点，未抵达点列表随之清空（全部转为已行驶）。
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _reachedIndex = routePoints.isEmpty ? 0 : routePoints.length - 1;
      }
    });
    // 同步取中心：优先上游随路由传入的坐标，其次缓存；保证首帧就落在车辆位置。
    initialCenter.value =
        _routeCenter() ?? DevicePositionCache.peek(_positionCacheKey ?? '');
    unawaited(_restoreCachedCenter());
    unawaited(loadInitialPosition());
  }

  /// 路由参数携带的车辆坐标（已转 GCJ-02）：由上游页面传入，首帧即可用。
  LatLng? _routeCenter() {
    final lat = _args?.latitude;
    final lng = _args?.longitude;
    if (lat == null || lng == null || !isValidCoordinate(lng, lat)) return null;
    return transformToGCJ02(lng, lat);
  }

  /// 缓存键：优先设备号，回退设备 ID。
  String? get _positionCacheKey {
    final no = device?.deviceNo;
    if (no != null && no.isNotEmpty) return no;
    final id = device?.deviceId;
    return (id != null && id.isNotEmpty) ? id : null;
  }

  /// 进入页面先读取缓存位置，作为地图初始中心。
  Future<void> _restoreCachedCenter() async {
    final key = _positionCacheKey;
    if (key == null) return;
    final cached = await DevicePositionCache.read(key);
    if (cached != null && !isClosed) initialCenter.value = cached;
  }

  /// 取到有效坐标后写入缓存，供下次进入页面直接使用。
  Future<void> _cachePosition(LatLng point) async {
    final key = _positionCacheKey;
    if (key == null) return;
    await DevicePositionCache.save(key, point);
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
    _lastReceivedAt = null;
  }

  Future<void> refreshPosition() async {
    final currentDevice = device;
    if (currentDevice == null || isRefreshing.value) return;
    isRefreshing.value = true;
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
        isRefreshing.value = false;
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
    unawaited(_cachePosition(next));
    final nextSpeed = nullableDoubleValue(data['speed']) ?? 0;

    final previous = currentPosition.value;
    final distance = previous == null
        ? 0.0
        : GeoUtils.distanceMeters(previous, next);

    // 车头朝向（0~360，正北为 0）：
    // 1) 设备上报了方向且车辆确有移动（有速度或位移足够大）→ 用上报方向；
    // 2) 设备未上报方向但位移足够大 → 用相邻点推算方位角；
    // 3) 其余（静止/仅 GPS 漂移）→ 保持原朝向不动。
    // 静止设备的漂移只有几米，用漂移方向推算会得到随机朝向，
    // 导致车标歪着（安卓端漂移通常更大），这就是车标倾斜的根因。
    final reportedDirection = nullableDoubleValue(
      data['direction'] ?? data['course'] ?? data['heading'],
    );
    final hasMovement =
        nextSpeed > 0.5 || distance >= _minBearingDistanceMeters;
    final double resolvedDirection;
    if (reportedDirection != null && hasMovement) {
      resolvedDirection = reportedDirection;
    } else if (reportedDirection == null &&
        previous != null &&
        distance >= _minBearingDistanceMeters) {
      resolvedDirection = GeoUtils.bearingDegrees(previous, next);
    } else {
      resolvedDirection = _targetBearing;
    }

    speed.value = nextSpeed;
    address.value = (data['address'] ?? data['location'] ?? '').toString();
    connectionStatus.value = (data['connectionStatus'] ?? data['status'] ?? '')
        .toString();
    _targetBearing = (resolvedDirection % 360 + 360) % 360;

    if (previous == null || !animate) {
      _animationController.stop();
      currentPosition.value = next;
      _bearing = _targetBearing;
      _appendRoutePoint(next, reset: previous == null);
      _markArrivedAtLastPoint();
      _moveMap(next);
      _lastReceivedAt = DateTime.now();
      return;
    }

    // 与上一点几乎重合（设备重复上报）：仅更新上面已赋值的元数据即可，
    // 不重启动画、不重置计时，避免无意义的零距离重绘与闪烁。
    if (distance < 1) return;

    // GPS 异常造成的极端跳变直接落位，避免拉出长线。
    if (distance > 500) {
      _animationController.stop();
      currentPosition.value = next;
      _bearing = _targetBearing;
      _appendRoutePoint(next, reset: true);
      _markArrivedAtLastPoint();
      _moveMap(next);
      _lastReceivedAt = DateTime.now();
      return;
    }

    // 动画时长 = 本次与上次「取位成功」的实测时间差（≈设备上报间隔，本例约 5s）。
    // 车标用整段间隔匀速走完两点，速度=真实速度：平滑、不瞬移；
    // 位置始终落在车辆真实经过的轨迹上（仅有时延，不会几何偏移/跑偏）。
    final gap = _lastReceivedAt == null
        ? Duration(seconds: pollIntervalSeconds.value)
        : DateTime.now().difference(_lastReceivedAt!);
    final durationMs = gap.inMilliseconds.clamp(800, 10000);
    final duration = Duration(milliseconds: durationMs);
    _lastReceivedAt = DateTime.now();

    _animationStart = previous;
    _animationEnd = next;
    _animationController.duration = duration;
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
      _reachedIndex = 0;
      return;
    }
    if (routePoints.isNotEmpty &&
        GeoUtils.distanceMeters(routePoints.last, point) < 1) {
      return;
    }
    routePoints.add(point);
    if (routePoints.length > 500) {
      routePoints.removeAt(0);
      // 丢弃最旧点后，已抵达下标同步前移一位。
      if (_reachedIndex > 0) _reachedIndex--;
    }
  }

  /// 车标直接落位到某点（首帧 / 未开启动画 / 极端跳变）：该点即视为已抵达。
  void _markArrivedAtLastPoint() {
    _reachedIndex = routePoints.isEmpty ? 0 : routePoints.length - 1;
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
