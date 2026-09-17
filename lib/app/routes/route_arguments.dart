import '../../models/home/device_model.dart';
import '../../models/api_response.dart';

/// Typed arguments shared by routes that operate on a device.
///
/// The parser intentionally accepts the old raw [DeviceModel] and JSON map
/// forms so existing deep links remain safe while callers migrate.
class DeviceRouteArgs {
  const DeviceRouteArgs(this.device);

  final DeviceModel device;

  static DeviceRouteArgs? parse(Object? value) {
    final device = deviceFrom(value);
    return device == null ? null : DeviceRouteArgs(device);
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
  const PlaybackRouteArgs(this.device, {this.startTime, this.endTime});

  final DeviceModel device;
  final DateTime? startTime;
  final DateTime? endTime;

  static PlaybackRouteArgs? parse(Object? value) {
    if (value is PlaybackRouteArgs) return value;
    final device = DeviceRouteArgs.deviceFrom(value);
    if (device == null) return null;
    DateTime? start;
    DateTime? end;
    if (value is Map) {
      start = _parseDateTime(value['startTime']);
      end = _parseDateTime(value['endTime']);
    }
    return PlaybackRouteArgs(device, startTime: start, endTime: end);
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceAll(' ', 'T'));
  }
}

/// Arguments for content rendered by the in-app web view.
class WebContentRouteArgs {
  const WebContentRouteArgs({required this.title, required this.url});

  final String title;
  final String url;

  Uri? get uri {
    final parsed = Uri.tryParse(url.trim());
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
    if (url.isEmpty) return null;
    return WebContentRouteArgs(title: title, url: url);
  }
}
