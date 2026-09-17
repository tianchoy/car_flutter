import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_launcher/map_launcher.dart';

import '../../components/widget/app_popup.dart';
import '../../utils/CoordTransform.dart';
import 'app_toast.dart';

/// 一键寻车：检测手机已安装的地图 App。
/// - 未安装任何地图：提示用户。
/// - 仅安装一个：直接拉起该地图进行导航。
/// - 安装多个：底部弹出选择框，由用户选择地图 App。
///
/// [destination] 需为 GCJ-02 坐标（与 App 内高德地图瓦片一致）。
/// 高德/百度/腾讯使用 GCJ-02；苹果地图/Google 使用 WGS-84，
/// 本方法会按地图类型自动转换坐标。
Future<void> startFindCar(
  BuildContext context, {
  required LatLng destination,
  String? title,
}) async {
  const mapsToCheck = [
    MapApp.amap,
    MapApp.baidu,
    MapApp.tencent,
    MapApp.apple,
    MapApp.google,
  ];

  List<SupportedMap> supported;
  try {
    supported = await MapLauncher.getAvailableMaps(mapsToCheck);
  } catch (e) {
    AppToast.show('提示', '无法获取地图应用列表');
    return;
  }

  final installed = supported.where((map) => map.isInstalled).toList();
  if (installed.isEmpty) {
    AppToast.show('提示', '未检测到已安装的地图应用');
    return;
  }

  if (installed.length == 1) {
    await _launch(installed.first, destination, title);
    return;
  }

  if (!context.mounted) return;
  final map = await AppPopup.show<SupportedMap>(
    context: context,
    title: '选择地图导航',
    options: installed,
    displayText: _mapDisplayName,
    isShowMessage: false,
  );
  if (map != null) await _launch(map, destination, title);
}

/// 地图应用名称中文化（map_launcher 默认返回英文名称，如 "AMap"）。
String _mapDisplayName(SupportedMap map) {
  switch (map.map.id) {
    case 'amap':
      return '高德地图';
    case 'baidu':
      return '百度地图';
    case 'tencent':
      return '腾讯地图';
    case 'apple':
      return '苹果地图';
    case 'google':
      return '谷歌地图';
    default:
      return map.name;
  }
}

Future<void> _launch(
  SupportedMap map,
  LatLng destination,
  String? title,
) async {
  final coords = _coordsFor(map.map, destination, title);
  final request = MapLauncher.directions(coords, mode: TravelMode.driving);
  try {
    await request.show(map: map.map);
  } catch (e) {
    AppToast.show('提示', '启动地图失败，请稍后重试');
  }
}

/// 根据地图类型将 GCJ-02 坐标转换为对应坐标系统。
LocationCoords _coordsFor(MapApp map, LatLng gcj02, String? title) {
  // 苹果地图 / Google 使用 WGS-84，其余（高德/百度/腾讯）使用 GCJ-02。
  if (map.id == 'apple' || map.id == 'google') {
    final wgs84 = transformToWGS84(gcj02.longitude, gcj02.latitude);
    return Location.coords(wgs84.latitude, wgs84.longitude, title: title);
  }
  return Location.coords(gcj02.latitude, gcj02.longitude, title: title);
}
