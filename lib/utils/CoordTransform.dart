import 'package:coordtransform/coordtransform.dart';
import 'package:latlong2/latlong.dart';

//火星坐标转换GCJ02坐标
LatLng transformToGCJ02(double longitude, double latitude) {
  CoordResult gcj = CoordTransform.transformWGS84toGCJ02(longitude, latitude);
  return LatLng(gcj.lat, gcj.lon);
}
