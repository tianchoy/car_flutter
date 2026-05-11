class DeviceModel {
  final String deviceId;
  final String deviceName;
  final String? deviceType;
  String? deviceStatus;
  String? latitude;
  String? longitude;
  String? deviceCreateTime;
  String? deviceUpdateTime;

  DeviceModel({
    required this.deviceId,
    required this.deviceName,
    this.deviceType,
    this.deviceStatus,
    this.latitude,
    this.longitude,
    this.deviceCreateTime,
    this.deviceUpdateTime,
  });

  // 从 JSON 解析设备模型
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    String toString(dynamic value) => value?.toString() ?? '';
    int toInt(dynamic value) => value as int;
    return DeviceModel(
      deviceId: toString(json['deviceId']),
      deviceName: toString(json['deviceName']),
      deviceType: toString(json['deviceType']),
      deviceStatus: toString(json['deviceStatus']),
      latitude: toString(json['latitude']),
      longitude: toString(json['longitude']),
      deviceCreateTime: toString(json['deviceCreateTime']),
      deviceUpdateTime: toString(json['deviceUpdateTime']),
    );
  }
}
