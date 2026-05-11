import 'package:car/components/widget/is_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../components/widget/map_tile.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '首页',
      showBackButton: false,
      body: Obx(
        () => Stack(
          children: [
            MapTile(
              isLoading: controller.isLoading.value,
              errMsg: controller.errorMessage.value,
              latitude: 39.9042,
              longitude: 116.4074,
              mapController: controller.mapController,
              onMapTap: (point) {
                Get.snackbar(
                  '点击地图',
                  '经度: ${point.longitude.toStringAsFixed(6)}, 纬度: ${point.latitude.toStringAsFixed(6)}',
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 1),
                );
              },
              markers: [
                ...controller.deviceList.map(
                  (device) => Marker(
                    point: LatLng(
                      double.parse(device.latitude ?? '0'),
                      double.parse(device.longitude ?? '0'),
                    ),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        Get.snackbar(
                          '点击设备',
                          '设备名称: ${device.deviceName ?? '无'}',
                          snackPosition: SnackPosition.TOP,
                          duration: const Duration(seconds: 1),
                        );
                        Get.toNamed('/detail');
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!controller.isLoggedIn.value) IsLogin(),
          ],
        ),
      ),
    );
  }
}
