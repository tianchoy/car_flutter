class DeviceModel {
  final String deviceId;
  final String deviceName;
  final String? deviceType;
  String? deviceStatus;
  final String deviceLocation;
  String? deviceCreateTime;
  String? deviceUpdateTime;

  DeviceModel({
    required this.deviceId,
    required this.deviceName,
    this.deviceType,
    this.deviceStatus,
    required this.deviceLocation,
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
      deviceLocation: toString(json['deviceLocation']),
      deviceCreateTime: toString(json['deviceCreateTime']),
      deviceUpdateTime: toString(json['deviceUpdateTime']),
    );
  }
}
