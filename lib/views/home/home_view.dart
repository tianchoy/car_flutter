import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../shared/widgets/mapTile.dart';
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
              initialZoom: 4.5,
              mapController: controller.mapController,
              markers: [
                  Marker(
                    point: LatLng(controller.latitude, controller.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        Get.snackbar(
                          '当前位置',
                          '经度: ${controller.longitude.toStringAsFixed(6)}, 纬度: ${controller.latitude.toStringAsFixed(6)}',
                          snackPosition: SnackPosition.TOP,
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
                ],
            ),
            if (!controller.isLoggedIn.value)
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed('/login');
                  },
                  child: const Text('请登录以获取更多功能'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
