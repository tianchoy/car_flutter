import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/app/routes/route_arguments.dart';
import 'package:car/models/home/device_model.dart';
import 'package:car/models/api_response.dart';
import 'package:car/widgets/app_toast.dart';
import 'package:car/widgets/reference_date_time_picker.dart';
import 'package:car/utils/coord_transform.dart';
import 'package:car/utils/geo_utils.dart';
import 'package:car/services/device_position_cache.dart';
import 'package:car/models/vehicle/playback_models.dart';
import 'playback_repository.dart';
import 'package:car/utils/time_utils.dart';

class PlaybackController extends GetxController
    with GetSingleTickerProviderStateMixin {
  PlaybackController({PlaybackRepository? repository})
    : _repository = repository ?? PlaybackRepository();

  final PlaybackRepository _repository;
  // 支持 PlaybackRouteArgs / DeviceRouteArgs / DeviceModel / Map 四种入参：
  // 首页「更多轨迹」传入的是 PlaybackRouteArgs，若只按 DeviceRouteArgs 解析会取不到设备。
  final PlaybackRouteArgs? _args = PlaybackRouteArgs.parse(Get.arguments);
  DeviceModel? get device => _args?.device;

  final MapController mapController = MapController();
  final startTime = DateTime.now().subtract(const Duration(hours: 6)).obs;
  final endTime = DateTime.now().obs;

  final points = <PlaybackPoint>[].obs;
  final currentPoint = Rxn<PlaybackPoint>();
  final currentIndex = 0.obs;
  final isLoading = false.obs;
  final isPlaying = false.obs;
  final isTrackPlayable = false.obs;
  final playbackSpeed = 1.0.obs;
  final playbackProgress = 0.0.obs;
  final currentSpeed = 0.0.obs;
  final currentTimeStr = ''.obs;
  final initialCenter = Rxn<LatLng>();

  bool _isSeeking = false;
  bool _wasPlayingBeforeSeek = false;
  double _segmentStartProgress = 0;
  double _segmentEndProgress = 0;

  /// 底部播放面板是否展开：进入页面默认展开，可下滑收起。
  final panelExpanded = true.obs;

  void togglePanel() => panelExpanded.value = !panelExpanded.value;

  void collapsePanel() => panelExpanded.value = false;

  late final AnimationController _animationController;
  PlaybackPoint? _startPoint;
  PlaybackPoint? _endPoint;
  int activeSegmentTargetIndex = -1;
  int _sessionId = 0;

  static const double _fallbackSpeedKmh = 20;
  static const double _minSegmentMs = 500;
  static const double _maxSegmentMs = 6000;
  // 更新车头朝向所需的最小位移（米）：小于该值视为停车点的 GPS 漂移。
  // 静止点的漂移只有几米，若仍按漂移方向推算朝向，播放时车标会乱转。
  static const double _minBearingDistanceMeters = 10;

  double get playbackProgressValue {
    if (points.length < 2) return 0;
    if (activeSegmentTargetIndex > currentIndex.value) {
      final t = _animationController.value;
      return (_segmentStartProgress +
              (_segmentEndProgress - _segmentStartProgress) * t)
          .clamp(0.0, 1.0);
    }
    return (currentIndex.value / (points.length - 1)).clamp(0.0, 1.0);
  }

  void beginSeek() {
    // 拖动过程中可能重复收到 start（点击按下 + 拖动开始）：
    // 第一次已经暂停并记录状态，后续重复调用必须忽略，
    // 否则 _wasPlayingBeforeSeek 会被覆盖成 false，松手后无法续播。
    if (_isSeeking) return;
    _isSeeking = true;
    _wasPlayingBeforeSeek = isPlaying.value;
    if (_wasPlayingBeforeSeek) pausePlayback();
  }

  void seekTo(double progress) {
    if (points.length < 2) return;
    final normalized = progress.clamp(0.0, 1.0).toDouble();
    final scaledIndex = normalized * (points.length - 1);
    final index = scaledIndex.floor().clamp(0, points.length - 1);
    final fraction = index >= points.length - 1 ? 0.0 : scaledIndex - index;
    final point = index >= points.length - 1
        ? points.last
        : _interpolatePoint(points[index], points[index + 1], fraction);

    _sessionId++;
    _animationController.stop();
    isPlaying.value = false;
    activeSegmentTargetIndex = fraction > 0 ? index + 1 : -1;
    currentIndex.value = index;
    currentPoint.value = point;
    currentSpeed.value = point.speed;
    currentTimeStr.value = point.time;
    playbackProgress.value = normalized;
    _segmentStartProgress = normalized;
    _segmentEndProgress = index >= points.length - 1
        ? 1
        : (index + 1) / (points.length - 1);
    _moveMap(point.latLng);
  }

  void endSeek() {
    if (!_isSeeking) return;
    _isSeeking = false;
    final shouldResume = _wasPlayingBeforeSeek;
    _wasPlayingBeforeSeek = false;
    if (shouldResume && playbackProgress.value < 1) startPlayback();
  }

  PlaybackPoint _interpolatePoint(
    PlaybackPoint start,
    PlaybackPoint end,
    double progress,
  ) {
    final rotationDiff = GeoUtils.shortestAngleDelta(
      start.rotation,
      end.rotation,
    );
    return PlaybackPoint(
      latitude: start.latitude + (end.latitude - start.latitude) * progress,
      longitude: start.longitude + (end.longitude - start.longitude) * progress,
      speed: start.speed + (end.speed - start.speed) * progress,
      rotation: (start.rotation + rotationDiff * progress + 360) % 360,
      time: progress < .5 ? start.time : end.time,
      direction: start.direction + (end.direction - start.direction) * progress,
    );
  }

  /// 累计里程前缀和：下标即“走到该点已行驶的距离（米）”。
  /// 用它替代每帧遍历整条轨迹，底部面板/气泡每帧都会读取里程。
  final List<double> _cumulativeDistance = <double>[0];

  double get totalDistanceMeters =>
      _cumulativeDistance.isEmpty ? 0 : _cumulativeDistance.last;

  /// 已播放里程（米）：已完成分段的累计 + 当前动画片段走到渲染点的这一小段。
  double get playedDistanceMeters {
    if (points.isEmpty || _cumulativeDistance.length != points.length) return 0;
    final index = currentIndex.value.clamp(0, points.length - 1);
    var distance = _cumulativeDistance[index];
    final rendered = currentPoint.value;
    if (rendered != null && activeSegmentTargetIndex > index) {
      distance += GeoUtils.distanceMeters(
        points[index].latLng,
        rendered.latLng,
      );
    }
    final total = totalDistanceMeters;
    return distance <= total ? distance : total;
  }

  List<LatLng> get routePoints =>
      points.map((point) => point.latLng).toList(growable: false);

  /// Polyline points already travelled (blue, solid).
  List<LatLng> get playedRoutePoints {
    if (points.length < 2) return routePoints;
    final isAnimating = activeSegmentTargetIndex > currentIndex.value;
    final played = <LatLng>[];
    for (
      var index = 0;
      index <= currentIndex.value && index < points.length;
      index++
    ) {
      played.add(points[index].latLng);
    }
    final rendered = currentPoint.value;
    if (isAnimating && rendered != null) played.add(rendered.latLng);
    return played;
  }

  /// Polyline points not yet travelled (grey, dashed).
  List<LatLng> get unplayedRoutePoints {
    if (points.length < 2) return const [];
    final isAnimating = activeSegmentTargetIndex > currentIndex.value;
    final startIndex = isAnimating
        ? activeSegmentTargetIndex
        : currentIndex.value;
    final unplayed = <LatLng>[];
    final rendered = currentPoint.value;
    if (isAnimating && rendered != null) unplayed.add(rendered.latLng);
    for (var index = startIndex; index < points.length; index++) {
      unplayed.add(points[index].latLng);
    }
    return unplayed;
  }

  @override
  void onInit() {
    super.onInit();
    _animationController = AnimationController(vsync: this)
      ..addListener(_animate);
    final routeArgs = _args;
    final deviceModel = device;
    // 中心点优先级：上游随路由传入的坐标 > 设备自带坐标 > 缓存。
    final fromRoute = _routeCenter();
    if (fromRoute != null) {
      initialCenter.value = fromRoute;
    } else if (deviceModel != null && deviceModel.hasLocation) {
      initialCenter.value = transformToGCJ02(
        deviceModel.longitude!,
        deviceModel.latitude!,
      );
    } else {
      // 兜底：同步取缓存保证首帧命中，再异步读持久化缓存。
      initialCenter.value = DevicePositionCache.peek(_positionCacheKey ?? '');
      unawaited(_restoreCachedCenter());
    }
    if (routeArgs?.startTime != null) {
      startTime.value = routeArgs!.startTime!;
    }
    if (routeArgs?.endTime != null) {
      endTime.value = routeArgs!.endTime!;
    }
    load();
  }

  Future<void> load() async {
    final currentDevice = device;
    if (currentDevice == null) {
      AppToast.show('提示', '设备信息不存在');
      return;
    }
    pausePlayback();
    if (endTime.value.isBefore(startTime.value)) {
      AppToast.show('提示', '结束时间不能早于开始时间');
      return;
    }
    isLoading.value = true;
    _clearTrackDisplay();
    final session = ++_sessionId;
    try {
      final response = await _repository.fetchTrack(<String, dynamic>{
        'deviceNo': currentDevice.deviceNo ?? currentDevice.deviceId,
        'startTime': formatDateTime(startTime.value),
        'endTime': formatDateTime(endTime.value),
        'minParkTime': 2,
        'withStop': false,
        'withPos': true,
        'withTrip': false,
      });
      if (session != _sessionId) return;
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (isClosed || session != _sessionId) return;
      if (!result.isSuccess) {
        AppToast.show('提示', result.message.isEmpty ? '轨迹加载失败' : result.message);
        return;
      }
      final raw = result.data?['positions'];
      final loaded = raw is List
          ? raw.map(PlaybackPoint.fromJson).where(_validPoint).toList()
          : <PlaybackPoint>[];
      _processTrackData(loaded);
      // 「暂无轨迹」按不可播放来判定：少于 2 个点（0 个，或只有 1 个静止点）
      // 都算无轨迹，与播放按钮的 isTrackPlayable 判定保持一致，
      // 避免出现「没轨迹可播却不提示」的空白状态。
      if (!isTrackPlayable.value) {
        AppToast.show('提示', '当前时间段暂无轨迹数据');
        _showCurrentPosition();
        return;
      }
      isLoading.value = false;
    } catch (_) {
      if (!isClosed && session == _sessionId) {
        AppToast.show('提示', '轨迹加载失败，请稍后重试');
      }
    } finally {
      if (!isClosed && session == _sessionId) isLoading.value = false;
    }
  }

  void _processTrackData(List<PlaybackPoint> list) {
    // Drop consecutive duplicate coordinates.
    final deduped = <PlaybackPoint>[];
    for (final point in list) {
      if (deduped.isNotEmpty) {
        final last = deduped.last;
        if (last.latitude == point.latitude &&
            last.longitude == point.longitude) {
          continue;
        }
      }
      deduped.add(point);
    }
    // Heading is derived from neighbouring points (mirrors the source project,
    // which ignores the device-reported direction).
    // 但只有真正位移了（≥ [_minBearingDistanceMeters]）才更新朝向：
    // 停车点去重后仍剩几米 GPS 漂移，按漂移方向推算会得到随机朝向，
    // 播放到停车段时车标会乱转/歪着。
    for (var index = 1; index < deduped.length; index++) {
      final previous = deduped[index - 1];
      final current = deduped[index];
      final moved =
          GeoUtils.distanceMeters(previous.latLng, current.latLng) >=
          _minBearingDistanceMeters;
      final rotation = moved
          ? GeoUtils.bearingDegrees(previous.latLng, current.latLng)
          : previous.rotation;
      deduped[index] = PlaybackPoint(
        latitude: current.latitude,
        longitude: current.longitude,
        speed: current.speed,
        rotation: rotation,
        time: current.time,
        direction: current.direction,
      );
    }
    if (deduped.length > 1) {
      final last = deduped.last;
      final previous = deduped[deduped.length - 2];
      deduped[deduped.length - 1] = PlaybackPoint(
        latitude: last.latitude,
        longitude: last.longitude,
        speed: last.speed,
        rotation: previous.rotation,
        time: last.time,
        direction: last.direction,
      );
    }

    points.assignAll(deduped);
    isTrackPlayable.value = deduped.length > 1;
    _rebuildCumulativeDistance();
    currentIndex.value = 0;
    activeSegmentTargetIndex = -1;
    _segmentStartProgress = 0;
    _segmentEndProgress = 0;
    playbackProgress.value = 0;

    if (deduped.isNotEmpty) {
      currentPoint.value = deduped.first;
      currentSpeed.value = deduped.first.speed;
      currentTimeStr.value = deduped.first.time;
    }

    _fitTrack();
  }

  /// 重算累计里程前缀和（轨迹点变化时调用）。
  void _rebuildCumulativeDistance() {
    _cumulativeDistance
      ..clear()
      ..add(0);
    for (var index = 1; index < points.length; index++) {
      _cumulativeDistance.add(
        _cumulativeDistance[index - 1] +
            GeoUtils.distanceMeters(
              points[index - 1].latLng,
              points[index].latLng,
            ),
      );
    }
  }

  void _clearTrackDisplay() {
    pausePlayback();
    _cumulativeDistance
      ..clear()
      ..add(0);
    points.clear();
    currentPoint.value = null;
    currentIndex.value = 0;
    activeSegmentTargetIndex = -1;
    currentSpeed.value = 0;
    currentTimeStr.value = '';
    isTrackPlayable.value = false;
  }

  void _showCurrentPosition() {
    isTrackPlayable.value = false;
    final deviceModel = device;
    if (deviceModel != null && deviceModel.hasLocation) {
      final converted = transformToGCJ02(
        deviceModel.longitude!,
        deviceModel.latitude!,
      );
      currentPoint.value = PlaybackPoint(
        latitude: converted.latitude,
        longitude: converted.longitude,
        speed: 0,
        rotation: 0,
        time: formatDateTime(DateTime.now()),
      );
      _moveMap(LatLng(converted.latitude, converted.longitude));
    }
  }

  Future<void> pickDate({
    required bool start,
    required BuildContext context,
  }) async {
    final selected = await showReferenceDateTimePicker(
      context: context,
      initialDate: start ? startTime.value : DateTime.now(),
    );
    if (selected == null) return;
    if (start) {
      startTime.value = selected;
    } else {
      endTime.value = selected;
    }
    await load();
  }

  void togglePlayback() {
    if (!isTrackPlayable.value) {
      AppToast.show('提示', '没有轨迹数据');
      return;
    }
    if (isPlaying.value) {
      pausePlayback();
    } else {
      startPlayback();
    }
  }

  void startPlayback() {
    if (!isTrackPlayable.value) {
      AppToast.show('提示', '没有轨迹数据');
      return;
    }
    if (currentIndex.value >= points.length - 1) _resetPlayback();
    activeSegmentTargetIndex = -1;
    isPlaying.value = true;
    _animateNextSegment();
  }

  void setSpeed(double speed) {
    playbackSpeed.value = speed.clamp(1, 30).toDouble();
    // Apply immediately: restart the current segment from the rendered point.
    if (isPlaying.value) {
      _animationController.stop();
      _animateNextSegment();
    }
  }

  void pausePlayback() {
    isPlaying.value = false;
    _animationController.stop();
  }

  void _resetPlayback() {
    pausePlayback();
    activeSegmentTargetIndex = -1;
    currentIndex.value = 0;
    playbackProgress.value = 0;
    if (points.isNotEmpty) {
      currentPoint.value = points.first;
      currentSpeed.value = points.first.speed;
      currentTimeStr.value = points.first.time;
    }
  }

  void _animateNextSegment() {
    if (!isPlaying.value || points.length < 2) return;
    if (currentIndex.value >= points.length - 1) {
      _finishPlayback();
      return;
    }
    final start = currentPoint.value ?? points[currentIndex.value];
    final target = points[currentIndex.value + 1];
    activeSegmentTargetIndex = currentIndex.value + 1;
    _startPoint = start;
    _endPoint = target;
    // 片段起止进度必须先算好：播放中每帧按这两个值插值，
    // 否则进度条会停在 0%，仅到分段结束才跳一下（表现为 0%/1% 闪动）。
    final lastIndex = points.length - 1;
    _segmentStartProgress = (currentIndex.value / lastIndex).clamp(0.0, 1.0);
    _segmentEndProgress = ((currentIndex.value + 1) / lastIndex).clamp(
      0.0,
      1.0,
    );

    final distance = GeoUtils.distanceMeters(start.latLng, target.latLng);
    final recorded = start.speed > 0 && start.speed.isFinite
        ? start.speed
        : target.speed;
    final speedKmh = recorded > 0 && recorded.isFinite
        ? recorded
        : _fallbackSpeedKmh;
    final durationMs =
        (distance / (speedKmh / 3.6) * 1000 / playbackSpeed.value).clamp(
          _minSegmentMs,
          _maxSegmentMs,
        );

    final session = ++_sessionId;
    _animationController.duration = Duration(milliseconds: durationMs.round());
    _animationController.forward(from: 0).whenCompleteOrCancel(() {
      if (session != _sessionId || !isPlaying.value) return;
      if (currentIndex.value >= points.length - 1) {
        _finishPlayback();
        return;
      }
      currentIndex.value = currentIndex.value + 1;
      currentPoint.value = points[currentIndex.value];
      activeSegmentTargetIndex = -1;
      playbackProgress.value = currentIndex.value / (points.length - 1);
      // renderPlaybackIndex: update displayed speed/time at segment boundary.
      currentSpeed.value = points[currentIndex.value].speed;
      currentTimeStr.value = points[currentIndex.value].time;
      _animateNextSegment();
    });
  }

  void _animate() {
    final start = _startPoint;
    final end = _endPoint;
    if (start == null || end == null || !isPlaying.value) return;
    final t = _animationController.value;
    final latitude = start.latitude + (end.latitude - start.latitude) * t;
    final longitude = start.longitude + (end.longitude - start.longitude) * t;
    final rotationDiff = GeoUtils.shortestAngleDelta(
      start.rotation,
      end.rotation,
    );
    final rotation = (start.rotation + rotationDiff * t + 360) % 360;
    // Mirrors the source: position/rotation are interpolated, while speed/time
    // follow the target point (displayed values update at segment boundaries).
    final rendered = PlaybackPoint(
      latitude: latitude,
      longitude: longitude,
      speed: end.speed,
      rotation: rotation,
      time: end.time,
      direction: rotation,
    );
    currentPoint.value = rendered;
    playbackProgress.value = playbackProgressValue;
    // Follow the car every frame so the smooth glide stays on screen.
    _moveMap(rendered.latLng);
  }

  void _finishPlayback() {
    pausePlayback();
    activeSegmentTargetIndex = -1;
    playbackProgress.value = 1;
    currentIndex.value = points.length - 1;
    if (points.isNotEmpty) {
      currentPoint.value = points.last;
      currentSpeed.value = points.last.speed;
      currentTimeStr.value = points.last.time;
    }
    AppToast.show('提示', '轨迹回放完成');
  }

  LatLng? get currentLatLng => currentPoint.value?.latLng;

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

  /// 路由参数没带坐标时用缓存位置作为地图初始中心，避免先显示默认坐标。
  Future<void> _restoreCachedCenter() async {
    final key = _positionCacheKey;
    if (key == null) return;
    final cached = await DevicePositionCache.read(key);
    if (cached != null && !isClosed) initialCenter.value = cached;
  }

  void handleMapReady() {
    if (points.isNotEmpty) _fitTrack();
  }

  void _fitTrack() {
    if (points.isEmpty) return;
    try {
      final fit = CameraFit.coordinates(
        coordinates: points.map((point) => point.latLng).toList(),
        padding: const EdgeInsets.all(48),
        maxZoom: 16,
      );
      final cam = fit.fit(mapController.camera);
      mapController.move(cam.center, cam.zoom);
    } catch (_) {
      // Map is not attached yet.
    }
  }

  void _moveMap(LatLng point) {
    try {
      mapController.move(point, mapController.camera.zoom);
    } catch (_) {
      // Map is not attached yet.
    }
  }

  bool _validPoint(PlaybackPoint point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude.abs() <= 90 &&
      point.longitude.abs() <= 180 &&
      point.time.isNotEmpty &&
      !(point.latitude == 0 && point.longitude == 0);

  @override
  void onClose() {
    _sessionId++;
    pausePlayback();
    _animationController
      ..removeListener(_animate)
      ..dispose();
    super.onClose();
  }
}
