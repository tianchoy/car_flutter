import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/main_scaffold.dart';
import './detail_controller.dart';

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '详情',
      showBackButton: true,
      body: Container(child: Text('详情')),
    );
  }
}
