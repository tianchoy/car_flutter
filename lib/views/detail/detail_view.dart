import 'package:car/components/widget/map_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../components/usedLess/CircularProgress.dart';
import '../../components/widget/card.dart';
import '../../shared/widgets/main_scaffold.dart';
import './detail_controller.dart';

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: controller.device?.plateNo ?? '设备详情',
      showBackButton: true,
      showBottomNavBar: false,
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
        child: Column(children: [buildMap(), buildCircularProgress()]),
      ),
    );
  }

  Widget buildMap() {
    return CustomCard(
      buildBody: MapTile(
        isLoading: false,
        errMsg: '',
        initialZoom: 14,
        mapController: controller.mapController,
        markers: [
          Marker(
            width: 40,
            height: 40,
            point: LatLng(
              controller.device?.latitude ?? 0.0,
              controller.device?.longitude ?? 0.0,
            ),
            child: Icon(Icons.place, color: Colors.blue, size: 30),
            alignment: Alignment.center,
          ),
        ],
      ),
      title: '车辆定位',
      label: '定位',
      onClickFunction: () {
        controller.moveToCurrentLocation();
      },
    );
  }

  Widget buildCircularProgress() {
    return CustomCard(
      buildBody: _circularProgress(),
      title: '轨迹记录',
      label: '更多轨迹',
      onClickFunction: () {},
      showDivider: true,
    );
  }

  Widget _circularProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgress(
          diameter: 150,
          tips: '条',
          value: '150',
          label: '今日轨迹',
          circleColor: Colors.greenAccent,
        ),
        SizedBox(width: 30),
        CircularProgress(
          diameter: 150,
          tips: 'km',
          value: '150',
          label: '今日里程',
          circleColor: Colors.orangeAccent,
        ),
      ],
    );
  }
}
