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
  String? simMerchant;
  String? carType;
  String? deptId;

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
    this.simMerchant,
    this.carType,
    this.deptId,
  });

  // 从 JSON 解析设备模型
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    String toString(dynamic value) => value?.toString() ?? '';
    return DeviceModel(
      deviceId: toString(json['deviceId']),
      deviceName: toString(json['deviceName']),
      deviceType: toString(json['deviceType']),
      deviceStatus: toString(json['connectionStatus']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      deviceCreateTime: toString(json['deviceCreateTime']),
      deviceUpdateTime: toString(json['deviceUpdateTime']),
      imei: toString(json['imei']),
      iccid: toString(json['iccid']),
      plateNo: toString(json['plateNo']),
      simMerchant: toString(json['simMerchant']),
      carType: toString(json['carType']),
      deptId: toString(json['companyId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'connectionStatus': deviceStatus,
      'latitude': latitude,
      'longitude': longitude,
      'deviceCreateTime': deviceCreateTime,
      'deviceUpdateTime': deviceUpdateTime,
      'imei': imei,
      'iccid': iccid,
      'plateNo': plateNo,
      'simMerchant': simMerchant,
      'carType': carType,
      'companyId': deptId,
    };
  }
}
