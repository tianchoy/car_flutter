import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../model/home/device_model.dart';
import 'detail_repository.dart';
import '../../utils/Logger.dart';

class DetailController extends GetxController {
  final DetailRepository _detailRepository = DetailRepository();
  final DeviceModel? device = Get.arguments as DeviceModel?;
  final MapController mapController = MapController();

  @override
  void onInit() {
    super.onInit();
    _initPages();
  }

  Future<void> _initPages() async {
    await moveToCurrentLocation();
  }

  Future<void> moveToCurrentLocation() async {
    if (device == null) return;
    await _detailRepository.fetchDetailData(device);
    await Future.delayed(const Duration(milliseconds: 100));
    final currentPosition = LatLng(device!.latitude, device!.longitude);
    try {
      mapController.move(currentPosition, mapController.camera.zoom);
    } catch (e) {
      Log.i('地图移动失败: $e');
    }
  }
}
