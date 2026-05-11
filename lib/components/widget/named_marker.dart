import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Marker createNamedMarker({
  required LatLng point,
  required String deviceName,
  VoidCallback? onTap,
  double width = 90,
  double height = 65,
}) {
  return Marker(
    point: point,
    width: width,
    height: height,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 设备名称标签
        Container(
          constraints: const BoxConstraints(maxWidth: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            deviceName,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        // 位置图标，带点击事件
        GestureDetector(
          onTap: onTap,
          child: const Icon(Icons.location_on, color: Colors.red, size: 32),
        ),
      ],
    ),
  );
}
