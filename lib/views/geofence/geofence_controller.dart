import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/app/routes/route_arguments.dart';
import 'package:car/models/home/device_model.dart';
import 'package:car/models/api_response.dart';
import 'package:car/widgets/app_toast.dart';
import 'package:car/widgets/reference_ui.dart';
import 'package:car/utils/coord_transform.dart';
import 'package:car/utils/geo_utils.dart';
import 'package:car/utils/car_icon.dart';
import 'package:car/services/device_position_cache.dart';
import 'geofence_repository.dart';

class GeofenceRecord {
  GeofenceRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.area,
    this.alarmType = 1,
    this.deviceCount = 0,
  });

  final String id;
  final String name;
  final String type;
  final String area;
  final int alarmType;
  final int deviceCount;

  bool get isCircle =>
      type.toLowerCase() == 'circle' || area.startsWith('CIRCLE');

  factory GeofenceRecord.fromJson(Map<String, dynamic> json) {
    final area = stringValue(json['area']);
    return GeofenceRecord(
      id: stringValue(json['id']).isNotEmpty
          ? stringValue(json['id'])
          : stringValue(json['geoId']),
      name: stringValue(json['name'], fallback: '未命名围栏'),
      type: stringValue(
        json['type'],
        fallback: area.startsWith('CIRCLE') ? 'circle' : 'polygon',
      ),
      area: area,
      alarmType: intValue(json['alarmType'], fallback: 1),
      deviceCount: intValue(json['deviceCount']),
    );
  }
}

class GeofenceController extends GetxController {
  GeofenceController({GeofenceRepository? repository})
    : _repository = repository ?? GeofenceRepository();

  final GeofenceRepository _repository;
  final DeviceRouteArgs? _args = DeviceRouteArgs.parse(Get.arguments);
  DeviceModel? get device => _args?.device;
  final MapController mapController = MapController();
  final fences = <GeofenceRecord>[].obs;
  final selectedFence = Rxn<GeofenceRecord>();
  final drawingMode = 'polygon'.obs;
  final isDrawing = false.obs;
  final draftPoints = <LatLng>[].obs;
  final circleCenter = Rxn<LatLng>();
  final circleRadius = 0.0.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  /// 底部围栏列表是否展开：进入页面默认展开，向下拖动可收起。
  final fenceListExpanded = true.obs;

  void toggleFenceList() => fenceListExpanded.value = !fenceListExpanded.value;

  void collapseFenceList() => fenceListExpanded.value = false;
  final deviceTab = 0.obs;
  final boundDevices = <Map<String, dynamic>>[].obs;
  final unboundDevices = <Map<String, dynamic>>[].obs;
  final isLoadingDevices = false.obs;

  /// 正在提交绑定状态变更的设备编号：用于开关的乐观显示，避免提交期间开关回弹。
  final pendingDeviceNos = <String>{}.obs;
  final initialCenter = Rxn<LatLng>();

  /// 车辆最新定位：路由参数可能不带坐标，需单独拉取；用于车标与地图居中。
  final devicePosition = Rxn<LatLng>();
  bool _didCenterMap = false;

  @override
  void onInit() {
    super.onInit();
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
      initialCenter.value = DevicePositionCache.peek(_positionCacheKey ?? '');
    }
    loadFences();
    unawaited(_loadDevicePosition());
  }

  Future<void> loadFences() async {
    isLoading.value = true;
    try {
      final result = await _repository.fetchFences();
      if (result.isSuccess) {
        fences.assignAll(
          result.data
                  ?.whereType<Map>()
                  .map((item) => GeofenceRecord.fromJson(jsonMapFrom(item)))
                  .where((fence) => fence.id.isNotEmpty)
                  .toList() ??
              const <GeofenceRecord>[],
        );
      } else {
        AppToast.show('提示', result.message.isEmpty ? '获取围栏失败' : result.message);
      }
    } catch (_) {
      AppToast.show('提示', '获取围栏失败，请稍后重试');
    } finally {
      if (!isClosed) isLoading.value = false;
    }
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

  /// 车标位置与地图初始中心：
  /// 路由参数带坐标时直接用；否则先读缓存，再用接口拉取最新定位。
  /// 之前「围栏页缩小后没有车标」就是因为路由参数没有经纬度且从未拉取位置。
  Future<void> _loadDevicePosition() async {
    final model = device;
    if (model == null) return;
    if (model.hasLocation) {
      _applyDevicePosition(transformToGCJ02(model.longitude!, model.latitude!));
      return;
    }
    final key = _positionCacheKey;
    if (key != null) {
      final cached = await DevicePositionCache.read(key);
      if (cached != null && !isClosed) _applyDevicePosition(cached);
    }
    try {
      final response = await _repository
          .getDeviceLastPosition(<String, dynamic>{
            'deviceId': model.deviceId,
            if (model.deviceNo != null && model.deviceNo!.isNotEmpty)
              'deviceids': model.deviceNo,
          });
      if (isClosed) return;
      final result = ApiResponse<List<Object?>>.fromJson(
        response.data,
        dataParser: jsonListFrom,
      );
      final raw = result.data?.whereType<Map>().firstOrNull;
      if (!result.isSuccess || raw == null) return;
      final longitude = nullableDoubleValue(raw['longitude']);
      final latitude = nullableDoubleValue(raw['latitude']);
      if (longitude == null ||
          latitude == null ||
          !isValidCoordinate(longitude, latitude)) {
        return;
      }
      _applyDevicePosition(transformToGCJ02(longitude, latitude));
    } catch (_) {
      // 拉取车辆位置失败不影响围栏本身的绘制与编辑。
    }
  }

  /// 记录车辆位置：写入缓存，并在未选中围栏时把镜头居中一次。
  void _applyDevicePosition(LatLng point) {
    if (isClosed) return;
    devicePosition.value = point;
    initialCenter.value = point;
    final key = _positionCacheKey;
    if (key != null) unawaited(DevicePositionCache.save(key, point));
    _centerMapOnce(point);
  }

  /// 只在首次拿到车辆位置时居中一次（且未选中围栏），
  /// 避免打断用户后续的拖动/缩放，或把镜头从正在查看的围栏上拽走。
  void _centerMapOnce(LatLng point) {
    if (_didCenterMap || selectedFence.value != null) return;
    try {
      mapController.move(point, mapController.camera.zoom);
      _didCenterMap = true;
    } catch (_) {
      // MapController 尚未挂载（首帧），等 onMapReady 再补一次。
    }
  }

  /// 地图就绪回调：补做一次居中，覆盖「首帧控制器未挂载」的情况。
  void handleMapReady() {
    final point = devicePosition.value;
    if (point != null) _centerMapOnce(point);
  }

  void setDrawingMode(String mode) {
    if (mode != 'circle' && mode != 'polygon') return;
    drawingMode.value = mode;
    clearDraft();
  }

  void startDrawing() {
    selectedFence.value = null;
    isDrawing.value = true;
    clearDraft();
  }

  /// 根据当前绘制类型生成一个未占用的默认名称，例如「圆形围栏1」。
  String defaultFenceName() {
    final typeLabel = drawingMode.value == 'circle' ? '圆形围栏' : '多边形围栏';
    final existingNames = fences.map((fence) => fence.name).toSet();
    var sequence = 1;
    while (existingNames.contains('$typeLabel$sequence')) {
      sequence++;
    }
    return '$typeLabel$sequence';
  }

  /// 取消本次编辑/绘制：放弃草稿并退出绘制态，不改动已保存的围栏数据。
  void cancelDrawing() {
    isDrawing.value = false;
    clearDraft();
  }

  void clearDraft() {
    draftPoints.clear();
    circleCenter.value = null;
    circleRadius.value = 0;
  }

  void finishDrawing() {
    if (!canFinishDrawing) return;
    isDrawing.value = false;
  }

  bool get canFinishDrawing => drawingMode.value == 'polygon'
      ? draftPoints.length >= 3
      : circleCenter.value != null && circleRadius.value > 0;

  void handleMapTap(LatLng point) {
    if (!isDrawing.value) return;
    if (drawingMode.value == 'polygon') {
      draftPoints.add(point);
      return;
    }
    final center = circleCenter.value;
    if (center == null) {
      circleCenter.value = point;
    } else {
      circleRadius.value = GeoUtils.distanceMeters(center, point);
    }
  }

  void selectFence(GeofenceRecord fence) {
    selectedFence.value = fence;
    isDrawing.value = false;
    clearDraft();
    boundDevices.clear();
    unboundDevices.clear();
    pendingDeviceNos.clear();
    loadFenceDevices();
  }

  Future<void> loadFenceDevices() async {
    final fence = selectedFence.value;
    if (fence == null || isLoadingDevices.value) return;
    isLoadingDevices.value = true;
    try {
      final loadedBound = await loadBoundDevices(fenceId: fence.id);
      final loadedUnbound = await loadUnboundDevices(fenceId: fence.id);
      boundDevices.assignAll(loadedBound);
      unboundDevices.assignAll(loadedUnbound);
    } finally {
      if (!isClosed) isLoadingDevices.value = false;
    }
  }

  String deviceNoOf(Map<String, dynamic> device) => stringValue(
    device['deviceNo'] ?? device['imei'] ?? device['deviceId'] ?? device['id'],
  );

  String deviceTitle(Map<String, dynamic> device) => stringValue(
    device['deviceName'] ??
        device['plateNo'] ??
        device['deviceNo'] ??
        device['imei'] ??
        device['deviceId'],
    fallback: '未命名设备',
  );

  /// 单个设备的绑定开关：开启即绑定、关闭即解绑，操作即时生效（无需批量按钮）。
  Future<void> setDeviceBound(
    Map<String, dynamic> device, {
    required bool bound,
  }) async {
    final fence = selectedFence.value;
    final deviceNo = deviceNoOf(device);
    if (fence == null || deviceNo.isEmpty) return;
    // 提交期间先按目标状态显示，避免开关在列表刷新完成前弹回原状态。
    pendingDeviceNos.add(deviceNo);
    pendingDeviceNos.refresh();
    try {
      if (bound) {
        await bindDevices(fenceId: fence.id, deviceNos: <String>[deviceNo]);
      } else {
        await unbindDevices(fenceId: fence.id, deviceNos: <String>[deviceNo]);
      }
      await loadFenceDevices();
    } finally {
      pendingDeviceNos.remove(deviceNo);
      pendingDeviceNos.refresh();
    }
  }

  void editSelectedFence() {
    final fence = selectedFence.value;
    if (fence == null) return;
    drawingMode.value = fence.isCircle ? 'circle' : 'polygon';
    final parsed = parseArea(fence.area, fence.isCircle);
    if (fence.isCircle && parsed.isNotEmpty) {
      circleCenter.value = parsed.first;
      circleRadius.value = parsed.length > 1
          ? GeoUtils.distanceMeters(parsed.first, parsed[1])
          : 0;
    } else {
      draftPoints.assignAll(parsed);
    }
    isDrawing.value = true;
  }

  Future<void> saveFence({required String name, int alarmType = 1}) async {
    if (name.trim().isEmpty || !canFinishDrawing) return;
    final area = _draftArea;
    if (area == null) return;
    isSaving.value = true;
    try {
      final selected = selectedFence.value;
      final data = <String, dynamic>{
        'name': name.trim(),
        'area': area,
        'alarmType': alarmType,
        'type': drawingMode.value,
      };
      final result = selected == null
          ? await _repository.createFence(data)
          : await _repository.updateFence(selected.id, data);
      if (result.isSuccess) {
        selectedFence.value = null;
        isDrawing.value = false;
        clearDraft();
        await loadFences();
      } else {
        AppToast.show('提示', result.message.isEmpty ? '保存围栏失败' : result.message);
      }
    } catch (_) {
      AppToast.show('提示', '保存围栏失败，请稍后重试');
    } finally {
      if (!isClosed) isSaving.value = false;
    }
  }

  Future<void> deleteSelectedFence() async {
    final fence = selectedFence.value;
    if (fence == null) return;
    try {
      final result = await _repository.deleteFence(fence.id);
      if (result.isSuccess) {
        selectedFence.value = null;
        await loadFences();
        // 删除结果统一用顶部弹出提示反馈。
        AppToast.show('成功', '围栏已删除');
      } else {
        AppToast.show('提示', result.message.isEmpty ? '删除围栏失败' : result.message);
      }
    } catch (_) {
      AppToast.show('提示', '删除围栏失败，请稍后重试');
    }
  }

  Future<void> bindDevices({
    required String fenceId,
    required List<String> deviceNos,
  }) async {
    if (deviceNos.isEmpty) return;
    try {
      final result = await _repository.bindDevices({
        'geofenceId': fenceId,
        'deviceNos': deviceNos,
      });
      if (!result.isSuccess) {
        AppToast.show('提示', result.message.isEmpty ? '绑定设备失败' : result.message);
      }
    } catch (_) {
      AppToast.show('提示', '绑定设备失败，请稍后重试');
    }
  }

  Future<void> unbindDevices({
    required String fenceId,
    required List<String> deviceNos,
  }) async {
    if (deviceNos.isEmpty) return;
    try {
      final result = await _repository.unbindDevices({
        'geofenceId': fenceId,
        'deviceNos': deviceNos,
      });
      if (!result.isSuccess) {
        AppToast.show('提示', result.message.isEmpty ? '解绑设备失败' : result.message);
      }
    } catch (_) {
      AppToast.show('提示', '解绑设备失败，请稍后重试');
    }
  }

  Future<List<Map<String, dynamic>>> loadBoundDevices({
    required String fenceId,
    int page = 1,
    int pageSize = 10,
  }) => _loadDevicePage(
    query: <String, dynamic>{
      'pageNum': page,
      'pageSize': pageSize,
      'geoId': fenceId,
    },
    bound: true,
  );

  Future<List<Map<String, dynamic>>> loadUnboundDevices({
    required String fenceId,
    int page = 1,
    int pageSize = 10,
  }) => _loadDevicePage(
    query: <String, dynamic>{
      'pageNum': page,
      'pageSize': pageSize,
      'geoId': fenceId,
    },
    bound: false,
  );

  Future<List<Map<String, dynamic>>> _loadDevicePage({
    required Map<String, dynamic> query,
    required bool bound,
  }) async {
    try {
      final response = bound
          ? await _repository.getBoundDevices(query)
          : await _repository.getUnboundDevices(query);
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (!result.isSuccess) return const <Map<String, dynamic>>[];
      final data = result.data ?? const <String, dynamic>{};
      final list = data['list'] is List
          ? data['list'] as List
          : const <dynamic>[];
      return list.whereType<Map>().map(jsonMapFrom).toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  List<LatLng> parseArea(String area, bool circle) {
    if (circle && area.startsWith('CIRCLE')) {
      final value = area.replaceFirst('CIRCLE (', '').replaceFirst(')', '');
      final parts = value.split(',');
      if (parts.length != 2) return const <LatLng>[];
      final coordinate = parts.first.trim().split(RegExp(r'\s+'));
      if (coordinate.length != 2) return const <LatLng>[];
      final latitude = double.tryParse(coordinate[0]);
      final longitude = double.tryParse(coordinate[1]);
      if (latitude == null ||
          longitude == null ||
          !isValidCoordinate(longitude, latitude)) {
        return const <LatLng>[];
      }
      final center = transformToGCJ02(longitude, latitude);
      final radius = double.tryParse(parts[1].trim()) ?? 0;
      final edge = _offsetByMeters(center, radius, 90);
      return edge == null ? [center] : [center, edge];
    }
    if (!area.startsWith('POLYGON')) return const <LatLng>[];
    final value = area.replaceFirst('POLYGON ((', '').replaceFirst('))', '');
    return value
        .split(',')
        .map((pair) {
          final coordinate = pair.trim().split(RegExp(r'\s+'));
          if (coordinate.length != 2) return null;
          final latitude = double.tryParse(coordinate[0]);
          final longitude = double.tryParse(coordinate[1]);
          if (latitude == null ||
              longitude == null ||
              !isValidCoordinate(longitude, latitude)) {
            return null;
          }
          return transformToGCJ02(longitude, latitude);
        })
        .whereType<LatLng>()
        .toList();
  }

  String? get _draftArea {
    if (drawingMode.value == 'circle') {
      final center = circleCenter.value;
      if (center == null || circleRadius.value <= 0) return null;
      final wgs = transformToWGS84(center.longitude, center.latitude);
      return 'CIRCLE (${wgs.latitude} ${wgs.longitude}, ${circleRadius.value})';
    }
    if (draftPoints.length < 3) return null;
    final values = draftPoints
        .map((point) {
          final wgs = transformToWGS84(point.longitude, point.latitude);
          return '${wgs.latitude} ${wgs.longitude}';
        })
        .join(', ');
    return 'POLYGON (($values))';
  }

  LatLng? _offsetByMeters(LatLng origin, double meters, double bearing) {
    if (meters <= 0) return null;
    const radius = 6371000.0;
    final angularDistance = meters / radius;
    final bearingRadians = bearing * math.pi / 180;
    final latitude = origin.latitude * math.pi / 180;
    final longitude = origin.longitude * math.pi / 180;
    final destinationLatitude = math.asin(
      math.sin(latitude) * math.cos(angularDistance) +
          math.cos(latitude) *
              math.sin(angularDistance) *
              math.cos(bearingRadians),
    );
    final destinationLongitude =
        longitude +
        math.atan2(
          math.sin(bearingRadians) *
              math.sin(angularDistance) *
              math.cos(latitude),
          math.cos(angularDistance) -
              math.sin(latitude) * math.sin(destinationLatitude),
        );
    return LatLng(
      destinationLatitude * 180 / math.pi,
      destinationLongitude * 180 / math.pi,
    );
  }

  List<Polygon> get polygons {
    final result = <Polygon>[];
    // 编辑已有围栏时，旧范围以更淡的描边作为参考一直保留，
    // 不会因开始绘制新点而消失。
    final editing = isDrawing.value ? selectedFence.value : null;
    if (editing != null && !editing.isCircle) {
      final oldPoints = parseArea(editing.area, false);
      if (oldPoints.length >= 3) {
        result.add(
          Polygon(
            points: oldPoints,
            color: AppColors.danger.withValues(alpha: 0.08),
            borderColor: AppColors.danger.withValues(alpha: 0.5),
            borderStrokeWidth: 1.5,
          ),
        );
      }
    }
    if (isDrawing.value &&
        drawingMode.value == 'polygon' &&
        draftPoints.length >= 3) {
      result.add(
        Polygon(
          points: draftPoints.toList(),
          color: AppColors.danger.withValues(alpha: 0.2),
          borderColor: AppColors.danger,
          borderStrokeWidth: 2,
        ),
      );
    }
    for (final fence in fences) {
      if (fence == editing || fence.isCircle) continue;
      final points = parseArea(fence.area, false);
      if (points.length >= 3) {
        result.add(
          Polygon(
            points: points,
            color: AppColors.danger.withValues(alpha: 0.15),
            borderColor: AppColors.danger,
            borderStrokeWidth: 2,
          ),
        );
      }
    }
    return result;
  }

  /// 绘制中的草稿点（含圆形中心）以独立标记实时显示：点击即出现一个点，
  /// 不再等到第三个点形成面才显示。
  List<Marker> get draftMarkers {
    final result = <Marker>[];
    if (!isDrawing.value) return result;
    if (drawingMode.value == 'circle') {
      final center = circleCenter.value;
      if (center != null) result.add(_dotMarker(center, isCenter: true));
    } else {
      for (final point in draftPoints) {
        result.add(_dotMarker(point));
      }
    }
    return result;
  }

  /// 地图标记：设备当前位置车标 + 绘制中的草稿点。
  List<Marker> get mapMarkers {
    final result = <Marker>[];
    // 车标统一取 devicePosition（路由参数带坐标时用它，否则用接口拉取的结果），
    // 避免路由参数没有经纬度时地图上完全没有车标。
    final point = devicePosition.value;
    if (point != null) {
      result.add(
        Marker(
          width: 32,
          height: 32,
          point: point,
          child: Image.asset(
            deviceIconPath(
              online: device?.isOnline ?? false,
              carType: device?.carType,
            ),
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      );
    }
    result.addAll(draftMarkers);
    return result;
  }

  /// 编辑围栏时，已有顶点可在地图上自由拖动（只支持移动，不支持删除）。
  void updateDraftPoint(LatLng original, LatLng updated) {
    final index = draftPoints.indexOf(original);
    if (index < 0) return;
    draftPoints[index] = updated;
    draftPoints.refresh();
  }

  /// 把屏幕像素位移换算为经纬度位移，得到顶点拖动后的新坐标。
  LatLng? _moveByPixels(LatLng origin, MapCamera camera, Offset delta) {
    try {
      final reference = camera.center;
      // flutter_map v8：屏幕偏移以地图左上角为原点、y 轴向下，与手势位移方向一致。
      final referenceOffset = camera.latLngToScreenOffset(reference);
      final moved = camera.screenOffsetToLatLng(referenceOffset + delta);
      return LatLng(
        origin.latitude + (moved.latitude - reference.latitude),
        origin.longitude + (moved.longitude - reference.longitude),
      );
    } catch (_) {
      return null;
    }
  }

  Marker _dotMarker(LatLng point, {bool isCenter = false}) => Marker(
    point: point,
    width: 30,
    height: 30,
    child: Builder(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            final camera = MapCamera.of(context);
            final updated = _moveByPixels(point, camera, details.delta);
            if (updated == null) return;
            if (isCenter) {
              circleCenter.value = updated;
            } else {
              updateDraftPoint(point, updated);
            }
          },
          child: Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isCenter ? AppColors.primary : AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: CupertinoColors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 3),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  List<CircleMarker> get circles {
    final result = <CircleMarker>[];
    // 编辑已有围栏时，旧范围作为参考一直保留，不会因开始绘制新半径而消失。
    final editing = isDrawing.value ? selectedFence.value : null;
    if (editing != null && editing.isCircle) {
      final points = parseArea(editing.area, true);
      if (points.isNotEmpty) {
        final radius = points.length > 1
            ? GeoUtils.distanceMeters(points[0], points[1])
            : 0.0;
        result.add(
          CircleMarker(
            point: points.first,
            radius: radius,
            color: AppColors.danger.withValues(alpha: 0.08),
            borderColor: AppColors.danger.withValues(alpha: 0.5),
            borderStrokeWidth: 1.5,
            useRadiusInMeter: true,
          ),
        );
      }
    }
    for (final fence in fences.where((item) => item.isCircle)) {
      if (fence == editing) continue;
      final points = parseArea(fence.area, true);
      if (points.isNotEmpty) {
        final radius = points.length > 1
            ? GeoUtils.distanceMeters(points[0], points[1])
            : 0.0;
        result.add(
          CircleMarker(
            point: points.first,
            radius: radius,
            color: AppColors.danger.withValues(alpha: 0.15),
            borderColor: AppColors.danger,
            borderStrokeWidth: 2,
            useRadiusInMeter: true,
          ),
        );
      }
    }
    final center = circleCenter.value;
    if (isDrawing.value &&
        drawingMode.value == 'circle' &&
        center != null &&
        circleRadius.value > 0) {
      result.add(
        CircleMarker(
          point: center,
          radius: circleRadius.value,
          color: AppColors.danger.withValues(alpha: 0.2),
          borderColor: AppColors.danger,
          borderStrokeWidth: 2,
          useRadiusInMeter: true,
        ),
      );
    }
    return result;
  }
}
