import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'home_controller.dart';
import '../../shared/services/url.dart';

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
            FlutterMap(
              mapController: controller.mapController,
              options: MapOptions(
                initialCenter: LatLng(
                  controller.latitude,
                  controller.longitude,
                ),
                initialZoom: 4.5,
                minZoom: 3.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: mapUrl,
                  subdomains: const ['1', '2', '3', '4'],
                  userAgentPackageName: 'com.example.app',
                ),
                if (controller.isLoading.value)
                  const Center(child: CircularProgressIndicator()),
                if (controller.errorMessage.value.isNotEmpty)
                  Positioned(
                    top: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black54,
                      child: Text(
                        controller.errorMessage.value,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                MarkerLayer(
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
                        },
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                    Marker(
                      point: const LatLng(
                        39.9042,
                        116.4074, // 北京市中心坐标
                      ),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          Get.snackbar(
                            '北京',
                            '经度: 116.4074, 纬度: 39.9042',
                            snackPosition: SnackPosition.TOP,
                          );
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
