import 'package:car/models/api_response.dart';
import 'package:car/utils/coord_transform.dart';
import 'package:latlong2/latlong.dart';

class PlaybackPoint {
  const PlaybackPoint({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.rotation,
    required this.time,
    this.direction = 0,
  });

  final double latitude;
  final double longitude;
  final double speed;

  /// Heading in degrees (0~360), computed from neighbouring track points.
  final double rotation;
  final String time;

  /// Raw heading reported by the device (kept for reference, unused for rotation).
  final double direction;

  LatLng get latLng => LatLng(latitude, longitude);

  factory PlaybackPoint.fromJson(Object? value) {
    final data = jsonMapFrom(value);
    final longitude = nullableDoubleValue(data['longitude']) ?? 0;
    final latitude = nullableDoubleValue(data['latitude']) ?? 0;
    final converted = transformToGCJ02(longitude, latitude);
    return PlaybackPoint(
      latitude: converted.latitude,
      longitude: converted.longitude,
      speed: nullableDoubleValue(data['speed']) ?? 0,
      rotation: 0,
      direction:
          nullableDoubleValue(
            data['direction'] ?? data['course'] ?? data['heading'],
          ) ??
          0,
      time:
          (data['deviceTime'] ??
                  data['positionUpdateTime'] ??
                  data['gpsTime'] ??
                  data['time'] ??
                  '')
              .toString(),
    );
  }
}
