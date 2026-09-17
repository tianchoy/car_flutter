import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Pure geographic helpers shared by tracking, playback, and geofences.
class GeoUtils {
  GeoUtils._();

  static const Distance _distance = Distance();

  static double distanceMeters(LatLng start, LatLng end) {
    return _distance.as(LengthUnit.Meter, start, end);
  }

  static double bearingDegrees(LatLng start, LatLng end) {
    final startLat = _radians(start.latitude);
    final endLat = _radians(end.latitude);
    final deltaLongitude = _radians(end.longitude - start.longitude);
    final y = math.sin(deltaLongitude) * math.cos(endLat);
    final x =
        math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(deltaLongitude);
    return (_degrees(math.atan2(y, x)) + 360) % 360;
  }

  static LatLng interpolate(LatLng start, LatLng end, double fraction) {
    final t = fraction.clamp(0, 1).toDouble();
    return LatLng(
      start.latitude + (end.latitude - start.latitude) * t,
      start.longitude + (end.longitude - start.longitude) * t,
    );
  }

  static double shortestAngleDelta(double from, double to) {
    return ((to - from + 540) % 360) - 180;
  }

  static double interpolateBearing(double from, double to, double fraction) {
    final t = fraction.clamp(0, 1).toDouble();
    return (from + shortestAngleDelta(from, to) * t + 360) % 360;
  }

  static LatLngBounds bounds(Iterable<LatLng> points) {
    final values = points.toList(growable: false);
    if (values.isEmpty) {
      throw ArgumentError.value(
        points,
        'points',
        'At least one point is required',
      );
    }
    return LatLngBounds.fromPoints(values);
  }

  static double _radians(double value) => value * math.pi / 180;

  static double _degrees(double value) => value * 180 / math.pi;
}
