import 'package:car/models/api_response.dart';

class TrackTrip {
  const TrackTrip({
    required this.startTime,
    required this.endTime,
    required this.distanceMeters,
    required this.averageSpeed,
    required this.durationMilliseconds,
  });

  final String startTime;
  final String endTime;
  final double distanceMeters;
  final double averageSpeed;
  final int durationMilliseconds;

  factory TrackTrip.fromJson(Object? value) {
    final data = jsonMapFrom(value);
    return TrackTrip(
      startTime: _string(data, const ['startTime', 'start']),
      endTime: _string(data, const ['endTime', 'end']),
      distanceMeters: nullableDoubleValue(data['distance']) ?? 0,
      averageSpeed:
          nullableDoubleValue(data['averageSpeed']) ??
          nullableDoubleValue(data['avgSpeed']) ??
          0,
      durationMilliseconds: _durationMilliseconds(data['duration']),
    );
  }

  static int _durationMilliseconds(Object? value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (number == null) return 0;
    // The backend returns milliseconds. Accept seconds as a defensive fallback
    // for older installations that used a small duration value.
    return number < 100000 ? (number * 1000).round() : number.round();
  }

  static String _string(JsonMap data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }
}

class StopRecord {
  const StopRecord({
    required this.startTime,
    required this.endTime,
    required this.durationMilliseconds,
    this.latitude,
    this.longitude,
    this.address = '',
  });

  final String startTime;
  final String endTime;
  final int durationMilliseconds;
  final double? latitude;
  final double? longitude;
  final String address;

  /// 解析到中文地址后生成新实例（记录本身不可变）。
  StopRecord copyWith({String? address}) => StopRecord(
    startTime: startTime,
    endTime: endTime,
    durationMilliseconds: durationMilliseconds,
    latitude: latitude,
    longitude: longitude,
    address: address ?? this.address,
  );

  factory StopRecord.fromJson(Object? value) {
    final data = jsonMapFrom(value);
    return StopRecord(
      startTime: _string(data, const ['startTime', 'start']),
      endTime: _string(data, const ['endTime', 'end']),
      durationMilliseconds: _durationMilliseconds(data['duration']),
      latitude: nullableDoubleValue(data['latitude']),
      longitude: nullableDoubleValue(data['longitude']),
      address: _string(data, const ['address', 'location']),
    );
  }

  static int _durationMilliseconds(Object? value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (number == null) return 0;
    return number < 100000 ? (number * 1000).round() : number.round();
  }

  static String _string(JsonMap data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }
}

class MileageTripGroup {
  const MileageTripGroup({
    required this.date,
    required this.trips,
    required this.totalDistanceMeters,
  });

  final String date;
  final List<TrackTrip> trips;
  final double totalDistanceMeters;
}
