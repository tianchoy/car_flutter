import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/main_scaffold.dart';
import './detail_controller.dart';

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: controller.device?.deviceName ?? '详情',
      showBackButton: true,
      body: Container(
        child: Column(
          children: [
            Text('设备名称: ${controller.device?.deviceName ?? '未知设备'}'),
            Text('经度: ${controller.device?.longitude ?? '未知经度'}'),
            Text('纬度: ${controller.device?.latitude ?? '未知纬度'}'),
          ],
        ),
      ),
    );
  }
}
