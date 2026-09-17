class DeviceModel {
  DeviceModel({
    required this.deviceId,
    this.deviceName,
    this.deviceType,
    this.deviceStatus,
    required this.latitude,
    required this.longitude,
    this.deviceCreateTime,
    this.deviceUpdateTime,
    this.deviceNo,
    this.iccid,
    this.plateNo,
    this.simMerchant,
    this.carType,
    this.deptId,
  });

  final String deviceId;
  String? deviceName;
  final String? deviceType;
  String? deviceStatus;
  final double? latitude;
  final double? longitude;
  String? deviceCreateTime;
  String? deviceUpdateTime;
  String? deviceNo;
  String? iccid;
  String? plateNo;
  String? simMerchant;
  String? carType;
  String? deptId;

  bool get hasLocation => latitude != null && longitude != null;
  bool get isOnline => deviceStatus?.toLowerCase() == 'online';

  /// 判等依据：deviceNo 优先、deviceId 兜底。
  /// 这样无论设备列表如何排序、是否重新拉取生成新实例，
  /// 「当前选中设备」都能被正确识别（选择弹窗的高亮勾选依赖 == 比较）。
  String get _identityKey {
    final value = deviceNo ?? '';
    return value.isNotEmpty ? value : deviceId;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceModel && _identityKey == other._identityKey;
  }

  @override
  int get hashCode => _identityKey.hashCode;

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    String? nullableString(dynamic value) {
      final normalized = value?.toString().trim();
      return normalized == null || normalized.isEmpty ? null : normalized;
    }

    double? nullableDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString().trim() ?? '');
    }

    return DeviceModel(
      deviceId:
          nullableString(json['deviceId']) ?? nullableString(json['id']) ?? '',
      deviceName: nullableString(json['deviceName']),
      deviceType: nullableString(json['deviceType']),
      deviceStatus:
          nullableString(json['connectionStatus']) ??
          nullableString(json['status']),
      latitude: nullableDouble(json['latitude']),
      longitude: nullableDouble(json['longitude']),
      deviceCreateTime: nullableString(json['deviceCreateTime']),
      deviceUpdateTime: nullableString(json['deviceUpdateTime']),
      deviceNo: nullableString(json['deviceNo']) ?? nullableString(json['imei']),
      iccid: nullableString(json['iccid']),
      plateNo: nullableString(json['plateNo']),
      simMerchant: nullableString(json['simMerchant']),
      carType: nullableString(json['carType']),
      deptId:
          nullableString(json['deptId']) ?? nullableString(json['companyId']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'connectionStatus': deviceStatus,
      'latitude': latitude,
      'longitude': longitude,
      'deviceCreateTime': deviceCreateTime,
      'deviceUpdateTime': deviceUpdateTime,
      'deviceNo': deviceNo,
      'iccid': iccid,
      'plateNo': plateNo,
      'simMerchant': simMerchant,
      'carType': carType,
      'deptId': deptId,
    };
  }
}
