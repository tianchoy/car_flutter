import '../api_response.dart';

class TrackSummary {
  const TrackSummary({
    required this.tripCount,
    required this.totalDistanceMeters,
    required this.averageSpeed,
  });

  final int tripCount;
  final double totalDistanceMeters;
  final double averageSpeed;

  factory TrackSummary.fromJson(Object? value) {
    final data = jsonMapFrom(value);
    final trips = data['trips'] is List
        ? (data['trips'] as List).whereType<Map>().toList()
        : const <Map>[];
    if (trips.isEmpty) {
      return const TrackSummary(
        tripCount: 0,
        totalDistanceMeters: 0,
        averageSpeed: 0,
      );
    }

    var distance = 0.0;
    var speed = 0.0;
    for (final trip in trips) {
      distance += nullableDoubleValue(trip['distance']) ?? 0;
      speed += nullableDoubleValue(trip['averageSpeed']) ?? 0;
    }
    return TrackSummary(
      tripCount: trips.length,
      totalDistanceMeters: distance,
      averageSpeed: speed / trips.length,
    );
  }
}
