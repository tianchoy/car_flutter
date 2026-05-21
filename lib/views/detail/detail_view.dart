import 'package:car/components/widget/map_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

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
            buildMap(),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 4,
                    backgroundColor: Colors.transparent,
                    color: Colors.grey[300],
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Transform.rotate(
                  angle: 360 * 3.14159 / 180,
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: 0.8,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      color: Colors.green,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Km',
                      style: TextStyle(
                        fontSize: 150 * 0.08,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '150',
                      style: TextStyle(
                        fontSize: 150 * 0.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'label',
                      style: TextStyle(
                        fontSize: 150 * 0.08,
                        color: Colors.grey[500],
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
  }

  Widget buildMap() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: EdgeInsets.fromLTRB(10.0, 0, 10.0, 10.0),
      margin: EdgeInsets.all(10.0),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(padding: EdgeInsets.zero, child: Text('车辆定位')),
              TextButton(
                onPressed: () async {
                  await controller.moveToCurrentLocation();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFFF0F9F0),
                  foregroundColor: Color(0xFF07C160),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  minimumSize: Size(0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('定位', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 200,
            child: MapTile(
              isLoading: false,
              errMsg: '',
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
          ),
        ],
      ),
    );
  }
}
