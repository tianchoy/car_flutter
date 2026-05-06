import 'package:car/utils/Logger.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'home_repository.dart';

class HomeController extends GetxController {
  final HomeRepository _repository = HomeRepository();

  // 地图控制器
  final MapController mapController = MapController();

  // UI 状态
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isLoggedIn = false.obs;

  // 位置数据
  final currentPosition = const LatLng(39.9042, 116.4074).obs;

  double get latitude => currentPosition.value.latitude;
  double get longitude => currentPosition.value.longitude;

  @override
  void onInit() {
    super.onInit();
    _initializeHomePage();
  }

  Future<void> _initializeHomePage() async {
    await _checkLoginStatus();
    await _loadCurrentLocation();
  }

  Future<void> _checkLoginStatus() async {
    isLoggedIn.value = await _repository.checkToken();
    Log.i('登录状态: ${isLoggedIn.value}');
  }

  Future<void> _loadCurrentLocation() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final position = await _repository.getCurrentLocation();

      if (position != null) {
        // 转换坐标
        final gcjPosition = _repository.transformToGCJ02(
          position.longitude,
          position.latitude,
        );
        currentPosition.value = gcjPosition;

        // 移动地图到当前位置
        await _moveToCurrentLocation();
      } else {
        errorMessage.value = '无法获取当前位置';
      }
    } catch (e) {
      errorMessage.value = '获取位置失败: ${e.toString()}';
      Log.e('加载位置失败', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _moveToCurrentLocation() async {
    // 确保地图控制器已准备好
    await Future.delayed(const Duration(milliseconds: 100));
    mapController.move(currentPosition.value, mapController.camera.zoom);
  }

  // 供 UI 调用的公开方法
  Future<void> refreshLocation() async {
    await _loadCurrentLocation();
  }

  void moveToMyLocation() {
    if (currentPosition.value != null) {
      mapController.move(currentPosition.value, mapController.camera.zoom);
    }
  }
}
