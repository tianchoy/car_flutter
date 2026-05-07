import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './detail_controller.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../shared/services/url.dart';

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '详情',
      showBackButton: true,
      body: Container(
        child: Text('详情'),
      ),
    );
  }
}
