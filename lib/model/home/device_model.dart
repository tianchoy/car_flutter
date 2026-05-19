class DeviceModel {
  final String deviceId;
  String? deviceName;
  final String? deviceType;
  String? deviceStatus;
  double latitude;
  double longitude;
  String? deviceCreateTime;
  String? deviceUpdateTime;
  String? imei;
  String? iccid;
  String? plateNo;

  DeviceModel({
    required this.deviceId,
    this.deviceName,
    this.deviceType,
    this.deviceStatus,
    required this.latitude,
    required this.longitude,
    this.deviceCreateTime,
    this.deviceUpdateTime,
    this.imei,
    this.iccid,
    this.plateNo,
  });

  // 从 JSON 解析设备模型
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    String toString(dynamic value) => value?.toString() ?? '';
    return DeviceModel(
      deviceId: toString(json['deviceId']),
      deviceName: toString(json['deviceName']),
      deviceType: toString(json['deviceType']),
      deviceStatus: toString(json['deviceStatus']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      deviceCreateTime: toString(json['deviceCreateTime']),
      deviceUpdateTime: toString(json['deviceUpdateTime']),
      imei: toString(json['imei']),
      iccid: toString(json['iccid']),
      plateNo: toString(json['plateNo']),
    );
  }
}
