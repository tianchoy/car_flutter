import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/Logger.dart';

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
