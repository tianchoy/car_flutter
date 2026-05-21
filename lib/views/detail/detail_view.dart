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
      title: '车辆状态',
      label: '状态',
      onClickFunction: () {},
      showDivider: true,
    );
  }

  Widget _circularProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircularProgress(
          tips: '速度',
          value: '150',
          label: 'km/h',
          circleColor: Colors.lightGreenAccent,
        ),
        CircularProgress(
          tips: '速度',
          value: '150',
          label: 'km/h',
          circleColor: Colors.orangeAccent,
        ),
      ],
    );
  }
}
