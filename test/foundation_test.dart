import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/utils/coord_transform.dart';
import 'package:car/models/api_response.dart';
import 'package:car/utils/geo_utils.dart';

void main() {
  group('ApiResponse', () {
    test('parses source success and string numeric values', () {
      final response = ApiResponse<JsonMap>.fromJson(<String, dynamic>{
        'code': '200',
        'msg': 'ok',
        'data': <String, dynamic>{'total': '3'},
      }, dataParser: jsonMapFrom);

      expect(response.isSuccess, isTrue);
      expect(response.data?['total'], '3');
      expect(response.message, 'ok');
    });

    test('recognizes business token expiration', () {
      final response = ApiResponse<Object?>.fromJson(<String, dynamic>{
        'code': 401,
        'message': 'expired',
      });

      expect(response.isTokenExpired, isTrue);
      expect(response.isSuccess, isFalse);
    });
  });

  test('parses defensive integer and double values', () {
    expect(intValue('12.5'), 0);
    expect(intValue(12.5), 12);
    expect(nullableDoubleValue('39.9'), 39.9);
    expect(nullableDoubleValue(null), isNull);
  });

  test('converts coordinates and preserves out-of-China coordinates', () {
    final beijing = transformToGCJ02(116.4074, 39.9042);
    expect(beijing.latitude, isNot(39.9042));
    expect(beijing.longitude, isNot(116.4074));

    final outsideChina = transformToGCJ02(-73.9857, 40.7484);
    expect(outsideChina.latitude, closeTo(40.7484, 0.000001));
    expect(outsideChina.longitude, closeTo(-73.9857, 0.000001));
  });

  test('calculates geographic helpers', () {
    const start = LatLng(39.9042, 116.4074);
    const end = LatLng(39.9142, 116.4074);

    expect(GeoUtils.distanceMeters(start, end), greaterThan(1000));
    expect(GeoUtils.bearingDegrees(start, end), closeTo(0, 1));
    expect(
      GeoUtils.interpolate(start, end, 0.5).latitude,
      closeTo(39.9092, 0.000001),
    );
    expect(GeoUtils.shortestAngleDelta(350, 10), closeTo(20, 0.000001));
    expect(
      GeoUtils.bounds([start, end]).north,
      closeTo(end.latitude, 0.000001),
    );
  });
}
