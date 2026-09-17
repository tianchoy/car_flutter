import 'package:coordtransform/coordtransform.dart';
import 'package:latlong2/latlong.dart';

/// Coordinate helpers for the WGS-84 server contract and 高德's GCJ-02 map.
LatLng transformToGCJ02(double longitude, double latitude) {
  final gcj = CoordTransform.transformWGS84toGCJ02(longitude, latitude);
  return LatLng(gcj.lat, gcj.lon);
}

LatLng transformToWGS84(double longitude, double latitude) {
  final wgs84 = CoordTransform.transformGCJ02toWGS84(longitude, latitude);
  return LatLng(wgs84.lat, wgs84.lon);
}

bool isValidCoordinate(double longitude, double latitude) {
  return longitude.isFinite &&
      latitude.isFinite &&
      longitude >= -180 &&
      longitude <= 180 &&
      latitude >= -90 &&
      latitude <= 90 &&
      !(longitude == 0 && latitude == 0);
}
