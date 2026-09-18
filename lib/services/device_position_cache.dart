import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../models/api_response.dart';
import '../utils/session.dart';

/// 设备最近一次成功获取的定位缓存（坐标已为 GCJ-02，可直接用于地图展示）。
///
/// 设计要点：
/// - **同步内存层** [_memory]：页面 `onInit` 早于首帧 `build`，只有同步取值
///   才能让地图第一帧就落在车辆位置；`SharedPreferences` 是异步的，等它返回时
///   地图已经用默认坐标构建完成，之后再改坐标也不会移动镜头
///   （`MapOptions.initialCenter` 只在首次构建生效）。
/// - **持久化层**：启动时由 [prime] 一次性载入内存，退出后仍保留。
///
/// 缓存只用于「地图初始中心」，不参与轨迹计算等业务数据。
class DevicePositionCache {
  DevicePositionCache._();

  static final Map<String, LatLng> _memory = <String, LatLng>{};

  /// 同步读取：仅供 onInit 阶段使用，保证首帧即可拿到中心点。
  static LatLng? peek(String deviceKey) =>
      deviceKey.isEmpty ? null : _memory[deviceKey];

  /// 启动时把持久化缓存载入内存（在 runApp 之前 await，保证后续同步命中）。
  static Future<void> prime() async {
    final raw = await getSession(SessionKeys.deviceLastPositions);
    if (raw == null || raw.isEmpty) return;
    try {
      final all = jsonMapFrom(jsonDecode(raw));
      for (final entry in all.entries) {
        final item = entry.value;
        if (item is! Map) continue;
        final latitude = (item['latitude'] as num?)?.toDouble();
        final longitude = (item['longitude'] as num?)?.toDouble();
        if (latitude == null || longitude == null) continue;
        _memory[entry.key] = LatLng(latitude, longitude);
      }
    } catch (_) {
      // 缓存结构损坏时忽略，后续 save 会重建。
    }
  }

  /// 异步读取：内存优先，其次读持久化并回填内存。
  static Future<LatLng?> read(String deviceKey) async {
    if (deviceKey.isEmpty) return null;
    final cached = _memory[deviceKey];
    if (cached != null) return cached;
    final raw = await getSession(SessionKeys.deviceLastPositions);
    if (raw == null || raw.isEmpty) return null;
    try {
      final all = jsonMapFrom(jsonDecode(raw));
      final item = all[deviceKey];
      if (item is! Map) return null;
      final latitude = (item['latitude'] as num?)?.toDouble();
      final longitude = (item['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) return null;
      final point = LatLng(latitude, longitude);
      _memory[deviceKey] = point;
      return point;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String deviceKey, LatLng point) async {
    if (deviceKey.isEmpty) return;
    // 先更新内存：本次会话内其它页面可立即同步命中。
    _memory[deviceKey] = point;
    try {
      final raw = await getSession(SessionKeys.deviceLastPositions);
      final all = <String, dynamic>{};
      if (raw != null && raw.isNotEmpty) {
        try {
          all.addAll(jsonMapFrom(jsonDecode(raw)));
        } catch (_) {
          // 缓存结构损坏时直接重建，不影响主流程。
        }
      }
      all[deviceKey] = <String, dynamic>{
        'latitude': point.latitude,
        'longitude': point.longitude,
      };
      await setSession(SessionKeys.deviceLastPositions, jsonEncode(all));
    } catch (_) {
      // 缓存写入失败不影响主流程（内存层仍有效）。
    }
  }
}
