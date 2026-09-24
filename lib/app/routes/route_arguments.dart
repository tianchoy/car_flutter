import '../../models/home/device_model.dart';
import '../../models/api_response.dart';

/// Typed arguments shared by routes that operate on a device.
///
/// The parser intentionally accepts the old raw [DeviceModel] and JSON map
/// forms so existing deep links remain safe while callers migrate.
class DeviceRouteArgs {
  const DeviceRouteArgs(this.device, {this.latitude, this.longitude});

  final DeviceModel device;

  /// 上游页面已知的车辆坐标（原始 WGS-84，未做偏移转换）。
  ///
  /// 随路由一起传入，使下游页面**首帧**就能居中到真实位置，无需等待
  /// 接口返回，也不必依赖缓存。设备列表接口并不保证下发经纬度，因此
  /// 由上游传入是最可靠的来源。
  final double? latitude;
  final double? longitude;

  static DeviceRouteArgs? parse(Object? value) {
    final device = deviceFrom(value);
    if (device == null) return null;
    double? lat;
    double? lng;
    if (value is DeviceRouteArgs) {
      lat = value.latitude;
      lng = value.longitude;
    } else if (value is Map) {
      lat = nullableDoubleValue(value['lat'] ?? value['latitude']);
      lng = nullableDoubleValue(value['lng'] ?? value['longitude']);
    }
    return DeviceRouteArgs(
      device,
      latitude: lat ?? device.latitude,
      longitude: lng ?? device.longitude,
    );
  }

  static DeviceModel? deviceFrom(Object? value) {
    if (value is DeviceRouteArgs) return value.device;
    if (value is DeviceModel) return value;
    if (value is Map) {
      final device = DeviceModel.fromJson(jsonMapFrom(value));
      return device.deviceId.isEmpty ? null : device;
    }
    return null;
  }
}

/// Arguments for the trajectory playback screen.
///
/// Carries the target [device] plus an optional preselected time range so a
/// mileage / stop-record segment can jump straight into the matching replay.
class PlaybackRouteArgs {
  const PlaybackRouteArgs(
    this.device, {
    this.startTime,
    this.endTime,
    this.latitude,
    this.longitude,
  });

  final DeviceModel device;
  final DateTime? startTime;
  final DateTime? endTime;

  /// 上游已知的车辆坐标（原始 WGS-84），用途同 [DeviceRouteArgs.latitude]。
  final double? latitude;
  final double? longitude;

  static PlaybackRouteArgs? parse(Object? value) {
    if (value is PlaybackRouteArgs) return value;
    final device = DeviceRouteArgs.deviceFrom(value);
    if (device == null) return null;
    DateTime? start;
    DateTime? end;
    double? lat;
    double? lng;
    if (value is Map) {
      start = _parseDateTime(value['startTime']);
      end = _parseDateTime(value['endTime']);
      lat = nullableDoubleValue(value['lat'] ?? value['latitude']);
      lng = nullableDoubleValue(value['lng'] ?? value['longitude']);
    }
    return PlaybackRouteArgs(
      device,
      startTime: start,
      endTime: end,
      latitude: lat ?? device.latitude,
      longitude: lng ?? device.longitude,
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceAll(' ', 'T'));
  }
}

/// Arguments for the「设置登录密码」screen.
///
/// 登录接口返回 `NEED_SET_PASSWORD`（手机号已注册但未设置密码）时跳转本页，
/// 需要带上本次短信登录用的手机号与验证码，设置成功后可直接完成登录。
class SetPasswordArgs {
  const SetPasswordArgs({required this.phonenumber, required this.smsCode});

  final String phonenumber;
  final String smsCode;

  static SetPasswordArgs? parse(Object? value) {
    if (value is SetPasswordArgs) {
      return value.phonenumber.trim().isEmpty ? null : value;
    }
    if (value is Map) {
      final rawPhone = value['phonenumber'] ?? value['phone'];
      final phone = rawPhone?.toString().trim() ?? '';
      if (phone.isEmpty) return null;
      return SetPasswordArgs(
        phonenumber: phone,
        smsCode: stringValue(value['smsCode']).trim(),
      );
    }
    return null;
  }
}

/// Arguments for content rendered by the in-app web view.
///
/// 内容来源二选一：
/// - [url]：远程地址（http/https）；
/// - [assetPath]：随包分发的本地资源（如 `assets/legal/privacy_policy.html`）。
///
/// 本地资源优先，避免因服务端路由缺失或断网导致协议页无法查看。
class WebContentRouteArgs {
  const WebContentRouteArgs({required this.title, this.url, this.assetPath});

  final String title;
  final String? url;
  final String? assetPath;

  String get trimmedAssetPath => (assetPath ?? '').trim();

  bool get hasAsset => trimmedAssetPath.isNotEmpty;

  Uri? get uri {
    final raw = (url ?? '').trim();
    if (raw.isEmpty) return null;
    final parsed = Uri.tryParse(raw);
    if (parsed == null ||
        (parsed.scheme != 'http' && parsed.scheme != 'https') ||
        parsed.host.isEmpty) {
      return null;
    }
    return parsed;
  }

  static WebContentRouteArgs? parse(Object? value) {
    if (value is WebContentRouteArgs) return value;
    if (value is! Map) return null;
    final title = stringValue(value['title']).trim();
    final url = stringValue(value['url']).trim();
    final assetPath = stringValue(value['assetPath']).trim();
    if (url.isEmpty && assetPath.isEmpty) return null;
    return WebContentRouteArgs(
      title: title,
      url: url.isEmpty ? null : url,
      assetPath: assetPath.isEmpty ? null : assetPath,
    );
  }
}
