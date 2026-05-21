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
      showBottomNavBar: true,
      body: Obx(
        () => Stack(
          children: [
            MapTile(
              isLoading: controller.isLoading.value,
              errMsg: controller.errorMessage.value,
              latitude: controller.currentPosition.value.latitude,
              longitude: controller.currentPosition.value.longitude,
              mapController: controller.mapController,
              markers: [
                ...controller.deviceList.map((device) {
                  final latitude = device.latitude.toString();
                  final longitude = device.longitude.toString();
                  return createNamedMarker(
                    point: LatLng(
                      double.parse(latitude),
                      double.parse(longitude),
                    ),
                    deviceName: device.plateNo ?? device.deviceName ?? '未知设备',
                    onTap: () {
                      Get.toNamed('/detail', arguments: device);
                    },
                  );
                }).whereType<Marker>(),
                Marker(
                  width: 40,
                  height: 40,
                  point: LatLng(
                    controller.currentPosition.value.latitude,
                    controller.currentPosition.value.longitude,
                  ),
                  child: Icon(Icons.place, color: Colors.blue, size: 30),
                  alignment: Alignment.center,
                ),
              ],
            ),
            if (!controller.isLoggedIn.value) const IsLogin(),
          ],
        ),
      ),
    );
  }
}
