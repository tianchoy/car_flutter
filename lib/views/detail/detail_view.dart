import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/main_scaffold.dart';
import './detail_controller.dart';

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: controller.device?.plateNo ?? '设备详情',
      showBackButton: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F9E6), Color(0xFFE8F0F8), Color(0xFFE0F0FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          children: [
            Text('设备名称: ${controller.device?.plateNo ?? '未知设备'}'),
            Text('经度: ${controller.device?.longitude ?? '未知经度'}'),
            Text('纬度: ${controller.device?.latitude ?? '未知纬度'}'),
            Icon(Icons.arrow_right_rounded, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }
}
