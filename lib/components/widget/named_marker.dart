import 'package:flutter/cupertino.dart';
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
        Container(
          constraints: const BoxConstraints(maxWidth: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            deviceName,
            style: const TextStyle(
              color: CupertinoColors.black,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: onTap,
          child: const Icon(
            CupertinoIcons.location_solid,
            color: CupertinoColors.systemRed,
            size: 32,
          ),
        ),
      ],
    ),
  );
}
