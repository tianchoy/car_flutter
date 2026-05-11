import 'package:coordtransform/coordtransform.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../shared/services/api_service.dart';
import '../../utils/Logger.dart';
import '../../utils/session.dart';

class HomeRepository {
  final ApiService _apiService = ApiService();

  // 只返回原始数据，不持有状态
  Future<Position?> getCurrentLocation() async {
    try {
      // 检查定位服务是否开启
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Log.w('定位服务未开启');
        await Geolocator.openLocationSettings();
        return null;
      }

      // 检查并请求权限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Log.w('位置权限被拒绝');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Log.w('位置权限被永久拒绝');
        await openAppSettings();
        return null;
      }

      // 获取当前位置
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      Log.e('获取位置失败', error: e);
      return null;
    }
  }

  // 坐标转换
  LatLng transformToGCJ02(double longitude, double latitude) {
    CoordResult gcj = CoordTransform.transformWGS84toGCJ02(longitude, latitude);
    return LatLng(gcj.lat, gcj.lon);
  }

  // 检查 token
  Future<bool> checkToken() async {
    try {
      final token = await getSession('token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 获取用户设备列表
  Future<Response> getUserDeviceList() async {
    return await _apiService.getUserDeviceList();
  }
}
