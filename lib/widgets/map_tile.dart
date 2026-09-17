import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../services/url.dart';

class MapTile extends StatelessWidget {
  final bool isLoading;
  final String errMsg;
  final double latitude;
  final double longitude;
  final double initialZoom;
  final MapController? mapController;
  final List<Marker> markers;
  final List<Marker> regularMarkers;
  final List<CircleMarker> circles;
  final List<Polygon> polygons;
  final List<Polyline> polylines;
  final bool clusterMarkers;
  final void Function(LatLng)? onMapTap;
  final VoidCallback? onMapReady;

  const MapTile({
    super.key,
    required this.isLoading,
    required this.errMsg,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.initialZoom = 4.5,
    this.mapController,
    this.markers = const [],
    this.regularMarkers = const [],
    this.circles = const [],
    this.polygons = const [],
    this.polylines = const [],
    this.clusterMarkers = true,
    this.onMapTap,
    this.onMapReady,
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
            onMapReady: onMapReady,
          ),
          children: [
            TileLayer(
              urlTemplate: AppConfig.amapTileUrl,
              subdomains: const ['1', '2', '3', '4'],
              userAgentPackageName: AppConfig.androidPackageName,
            ),
            if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
            if (circles.isNotEmpty) CircleLayer(circles: circles),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            if (clusterMarkers)
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  size: const Size(40, 40),
                  markers: markers,
                  maxClusterRadius: 120,
                  disableClusteringAtZoom: 18,
                  builder: (context, clusteredMarkers) {
                    return _buildClusterMarker(context, clusteredMarkers);
                  },
                ),
              )
            else if (markers.isNotEmpty)
              MarkerLayer(markers: markers),
            if (regularMarkers.isNotEmpty) MarkerLayer(markers: regularMarkers),
          ],
        ),
        if (isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.black.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const CupertinoActivityIndicator(
                radius: 12,
                color: CupertinoColors.white,
              ),
            ),
          ),
        // 设备无数据等提示：5 秒后自动淡出，避免长期遮挡地图。
        if (errMsg.isNotEmpty) MapInfoHint(message: errMsg),
      ],
    );
  }

  Widget _buildClusterMarker(BuildContext context, List<Marker> markers) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: CupertinoColors.systemBlue,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .3),
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
            color: CupertinoColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// 地图上的轻量提示（如「设备暂无数据」）。
/// 采用浅色卡片样式，展示 5 秒后自动淡出，取代原先黑底白字的刺眼样式。
class MapInfoHint extends StatefulWidget {
  const MapInfoHint({super.key, required this.message});

  final String message;

  @override
  State<MapInfoHint> createState() => MapInfoHintState();
}

class MapInfoHintState extends State<MapInfoHint> {
  bool _visible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleDismiss();
  }

  @override
  void didUpdateWidget(covariant MapInfoHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _visible = true;
      _scheduleDismiss();
    }
  }

  void _scheduleDismiss() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: IgnorePointer(
          ignoring: !_visible,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x1A000000)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.info_circle,
                    size: 18,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
