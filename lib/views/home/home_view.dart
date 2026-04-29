import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保 Controller 被绑定
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return MainScaffold(
          title: '首页',
          showBackButton: false,
          body: Obx(
            () => Stack(
              children: [
                FlutterMap(
                  mapController: controller.repository.mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      controller.latitude,
                      controller.longitude,
                    ),
                    initialZoom: 5.0,
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
                      urlTemplate:
                          'https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=7',
                      subdomains: const ['1', '2', '3', '4'],
                      userAgentPackageName: 'com.example.app', // 添加包名避免被限制
                    ),
                    // 加载指示器
                    if (controller.isLoading)
                      const Center(child: CircularProgressIndicator()),
                    // 错误提示
                    if (controller.errorMessage.isNotEmpty)
                      Positioned(
                        top: 20,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black54,
                          child: Text(
                            controller.errorMessage,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            controller.latitude,
                            controller.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              Get.snackbar(
                                '当前位置',
                                '经度: ${controller.longitude.toStringAsFixed(6)}, 纬度: ${controller.latitude.toStringAsFixed(6)}',
                                snackPosition: SnackPosition.BOTTOM,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
