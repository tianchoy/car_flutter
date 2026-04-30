import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:coordtransform/coordtransform.dart';
import '../../shared/services/api_service.dart';
import '../../utils/Logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeRepository {
  final ApiService _apiService = ApiService();
  final MapController mapController = MapController();

  final latitude = 39.9042.obs;
  final longitude = 116.4074.obs;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isLoggedIn = false.obs;

  // Future<dynamic> fetchHomeData() async {
  //   try {
  //     final response = await _apiService.fetchHomeData();
  //     if (response.statusCode == 200) {
  //       return response.data.json();
  //     } else {
  //       throw Exception('Failed to load data: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     Logger().d(e);
  //     rethrow;
  //   }
  // }

  Future<bool> checkToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      isLoggedIn.value = token != null && token.isNotEmpty;
      Log.i('token: ${isLoggedIn.value}');
      return isLoggedIn.value;
    } catch (e) {
      Log.e('检查 token 失败', error: e);
      isLoggedIn.value = false;
      return false;
    }
  }

  Future<bool> getCurrentLocation() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // 检查定位服务是否开启
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage.value = '请开启定位服务';
        Log.w('定位服务未开启');
        return false;
      }

      // 检查并请求权限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage.value = '需要位置权限';
          Log.w('位置权限被拒绝');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage.value = '请在系统设置中开启位置权限';
        Log.w('位置权限被永久拒绝');
        return false;
      }

      // 获取当前位置
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      CoordResult gcj = CoordTransform.transformWGS84toGCJ02(
        position.longitude,
        position.latitude,
      );
      longitude.value = gcj.lon;
      latitude.value = gcj.lat;

      await Future.delayed(const Duration(milliseconds: 500));
      moveToCurrentLocation();

      return true;
    } catch (e) {
      errorMessage.value = '获取位置失败: ${e.toString()}';
      Log.e('获取位置失败', error: e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void moveToCurrentLocation() {
    mapController.move(
      LatLng(latitude.value, longitude.value),
      mapController.camera.zoom,
    );
  }
}
