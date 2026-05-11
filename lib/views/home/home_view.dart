import 'package:car/components/widget/is_login.dart';
import 'package:car/components/widget/named_marker.dart'; // 导入工厂方法
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
              markers: controller.deviceList
                  .map((device) {
                    final latitude = device.latitude?.toString() ?? '';
                    final longitude = device.longitude?.toString() ?? '';

                    if (latitude == null || longitude == null) {
                      return null;
                    }
                    return createNamedMarker(
                      point: LatLng(
                        double.parse(latitude),
                        double.parse(longitude),
                      ),
                      deviceName: device.deviceName ?? '未知设备',
                      onTap: () {
                        Get.snackbar(
                          '设备信息',
                          '设备名称: ${device.deviceName}',
                          snackPosition: SnackPosition.TOP,
                          duration: const Duration(seconds: 2),
                        );
                        Get.toNamed('/detail');
                      },
                    );
                  })
                  .whereType<Marker>()
                  .toList(),
            ),
            if (!controller.isLoggedIn.value) const IsLogin(),
          ],
        ),
      ),
    );
  }
}
