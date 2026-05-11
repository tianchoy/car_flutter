import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../shared/services/url.dart';

class MapTile extends StatelessWidget {
  final bool isLoading;
  final String errMsg;
  final double latitude;
  final double longitude;
  final double initialZoom;
  final MapController? mapController;
  final List<Marker> markers;
  final List<Polygon> polygons;
  final void Function(LatLng)? onMapTap;

  const MapTile({
    super.key,
    required this.isLoading,
    required this.errMsg,
    required this.latitude,
    required this.longitude,
    this.initialZoom = 4.5,
    this.mapController,
    this.markers = const [],
    this.polygons = const [],
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(latitude, longitude),
            initialZoom: initialZoom,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
            onTap: onMapTap != null ? (_, point) => onMapTap!(point) : null,
          ),
          children: [
            TileLayer(
              urlTemplate: mapUrl,
              subdomains: const ['1', '2', '3', '4'],
              userAgentPackageName: 'com.example.app',
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                size: const Size(40, 40),
                markers: markers,
                maxClusterRadius: 120,
                disableClusteringAtZoom: 18,
                // 自定义聚合点样式
                builder: (context, markers) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.blue,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Text(
                        markers.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            PolygonLayer(polygons: polygons),
          ],
        ),
        if (isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const CircularProgressIndicator(color: Colors.white),
            ),
          ),
        if (errMsg.isNotEmpty)
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errMsg,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
