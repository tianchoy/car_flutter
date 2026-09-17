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
  final DeviceModel? device = PlaybackRouteArgs.parse(Get.arguments)?.device;

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
  final currentSpeed = 0.0.obs;
  final currentTimeStr = ''.obs;
  final initialCenter = Rxn<LatLng>();

  late final AnimationController _animationController;
  PlaybackPoint? _startPoint;
  PlaybackPoint? _endPoint;
  int activeSegmentTargetIndex = -1;
  int _sessionId = 0;

  static const double _fallbackSpeedKmh = 20;
  static const double _minSegmentMs = 500;
  static const double _maxSegmentMs = 6000;

  double get totalDistanceMeters {
    var total = 0.0;
    for (var index = 1; index < points.length; index++) {
      total += GeoUtils.distanceMeters(
        points[index - 1].latLng,
        points[index].latLng,
      );
    }
    return total;
  }

  List<LatLng> get routePoints =>
      points.map((point) => point.latLng).toList(growable: false);

  /// Polyline points already travelled (blue, solid).
  List<LatLng> get playedRoutePoints {
    if (points.length < 2) return routePoints;
    final isAnimating = activeSegmentTargetIndex > currentIndex.value;
    final played = <LatLng>[];
    for (var index = 0;
        index <= currentIndex.value && index < points.length;
        index++) {
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
    final startIndex =
        isAnimating ? activeSegmentTargetIndex : currentIndex.value;
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
    final routeArgs = PlaybackRouteArgs.parse(Get.arguments);
    final deviceModel = device;
    if (deviceModel != null && deviceModel.hasLocation) {
      initialCenter.value = transformToGCJ02(
        deviceModel.longitude!,
        deviceModel.latitude!,
      );
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
        AppToast.show(
          '提示',
          result.message.isEmpty ? '轨迹加载失败' : result.message,
        );
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
    for (var index = 1; index < deduped.length; index++) {
      final previous = deduped[index - 1];
      final current = deduped[index];
      final rotation = GeoUtils.bearingDegrees(previous.latLng, current.latLng);
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
    currentIndex.value = 0;
    activeSegmentTargetIndex = -1;

    if (deduped.isNotEmpty) {
      currentPoint.value = deduped.first;
      currentSpeed.value = deduped.first.speed;
      currentTimeStr.value = deduped.first.time;
    }

    _fitTrack();
  }

  void _clearTrackDisplay() {
    pausePlayback();
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
      initialDate: start ? startTime.value : endTime.value,
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

    final distance = GeoUtils.distanceMeters(start.latLng, target.latLng);
    final recorded = start.speed > 0 && start.speed.isFinite
        ? start.speed
        : target.speed;
    final speedKmh =
        recorded > 0 && recorded.isFinite ? recorded : _fallbackSpeedKmh;
    final durationMs = (distance / (speedKmh / 3.6) * 1000 / playbackSpeed.value)
        .clamp(_minSegmentMs, _maxSegmentMs);

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
    final rotationDiff =
        GeoUtils.shortestAngleDelta(start.rotation, end.rotation);
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
    // Follow the car every frame so the smooth glide stays on screen.
    _moveMap(rendered.latLng);
  }

  void _finishPlayback() {
    pausePlayback();
    activeSegmentTargetIndex = -1;
    AppToast.show('提示', '轨迹回放完成');
  }

  LatLng? get currentLatLng => currentPoint.value?.latLng;

  void handleMapReady() {
    if (points.isNotEmpty) _fitTrack();
  }

  void _fitTrack() {
    if (points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    double zoom;
    if (maxDiff > 0.1) {
      zoom = 10;
    } else if (maxDiff > 0.05) {
      zoom = 12;
    } else if (maxDiff > 0.02) {
      zoom = 15;
    } else {
      zoom = 16;
    }
    // The source centres the map on the first track point.
    final target = points.first.latLng;
    try {
      mapController.move(target, zoom);
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
