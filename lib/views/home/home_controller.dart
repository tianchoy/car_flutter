import 'package:car/utils/Logger.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../model/home/device_model.dart';
import '../../utils/CoordTransform.dart';
import 'home_repository.dart';

class HomeController extends GetxController {
  final HomeRepository _repository = HomeRepository();

  // 地图控制器
  final MapController mapController = MapController();

  // UI 状态
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isLoggedIn = false.obs;

  // 设备列表
  final deviceList = <DeviceModel>[].obs;

  // 位置数据
  final currentPosition = const LatLng(39.9042, 116.4074).obs;

  @override
  void onInit() {
    super.onInit();
    _initializeHomePage();
  }

  // 初始化首页
  Future<void> _initializeHomePage() async {
    await _loadCurrentLocation();
    if (await _checkLoginStatus()) {
      await _getUserDeviceList();
    }
  }

  // 检查登录状态
  Future<bool> _checkLoginStatus() async {
    try {
      isLoggedIn.value = await _repository.checkToken();
      return isLoggedIn.value;
    } catch (e) {
      errorMessage.value = '检查登录状态失败: ${e.toString()}';
      Log.e('检查登录状态失败', error: e);
      return false; // 异常时返回 false
    }
  }

  // 加载当前位置
  Future<void> _loadCurrentLocation() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final position = await _repository.getCurrentLocation();

      if (position != null) {
        // 转换坐标
        final gcjPosition = transformToGCJ02(
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

  // 移动地图到当前位置
  Future<void> _moveToCurrentLocation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    mapController.move(currentPosition.value, mapController.camera.zoom);
  }

  // 获取用户设备列表
  Future<void> _getUserDeviceList() async {
    final response = await _repository.getUserDeviceList({'pageSize': 1000});
    if (response.data != null && response.data['code'] == 0) {
      final data = response.data['data'];
      if (data != null) {
        final List<dynamic> list = data['list'] ?? [];
        // 转换坐标并创建设备模型
        final convertedList = list.map((json) {
          final gcjLocation = transformToGCJ02(
            json['longitude'],
            json['latitude'],
          );
          json['longitude'] = gcjLocation.longitude;
          json['latitude'] = gcjLocation.latitude;

          return DeviceModel.fromJson(json);
        }).toList();

        // 更新设备列表
        deviceList.value = convertedList;
      }
    } else {
      errorMessage.value = '获取设备列表失败: ${response.data['msg'] ?? '未知错误'}';
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
