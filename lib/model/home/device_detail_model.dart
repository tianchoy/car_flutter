import '../../shared/models/api_response.dart';

class DeviceStatusModel {
  const DeviceStatusModel({
    this.batteryPercent = 0,
    this.voltage = 0,
    this.signalStrength = 0,
  });

  final double batteryPercent;
  final double voltage;
  final double signalStrength;

  factory DeviceStatusModel.fromJson(Object? value) {
    final data = jsonMapFrom(value);
    return DeviceStatusModel(
      batteryPercent: nullableDoubleValue(data['batteryPercent']) ?? 0,
      voltage: nullableDoubleValue(data['voltage']) ?? 0,
      signalStrength:
          nullableDoubleValue(data['signalStrength']) ??
          nullableDoubleValue(data['rssi']) ??
          0,
    );
  }
}

class DeviceDetailModel {
  const DeviceDetailModel({
    required this.status,
    this.connectionStatus,
    this.lastUpdateTime,
    this.address,
  });

  final DeviceStatusModel status;
  final String? connectionStatus;
  final String? lastUpdateTime;
  final String? address;

  bool get isOnline => connectionStatus?.toLowerCase() == 'online';

  factory DeviceDetailModel.fromJson(Map<String, dynamic> json) {
    return DeviceDetailModel(
      status: DeviceStatusModel.fromJson(
        json['deviceStatus'] ?? json['status'],
      ),
      connectionStatus: _nullableString(
        json['connectionStatus'] ?? json['deviceStatusText'],
      ),
      lastUpdateTime: _nullableString(json['lastUpdateTime']),
      address: _nullableString(
        json['address'] ?? json['formattedAddress'] ?? json['location'],
      ),
    );
  }

  static String? _nullableString(Object? value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? null : result;
  }
}
