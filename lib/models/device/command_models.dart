import 'package:car/models/api_response.dart';

class CommandTemplate {
  const CommandTemplate({
    required this.id,
    required this.name,
    this.code = '',
    this.remark = '',
    this.allowed = true,
    this.paramSchema = const <CommandParameter>[],
  });

  final String id;
  final String name;
  final String code;
  final String remark;
  final bool allowed;
  final List<CommandParameter> paramSchema;

  bool get needsParameters => paramSchema.isNotEmpty;

  factory CommandTemplate.fromJson(Map<String, dynamic> json) {
    final rawParams = json['paramSchema'];
    final params = <CommandParameter>[];
    if (rawParams is List) {
      params.addAll(
        rawParams.whereType<Map>().map(
          (item) => CommandParameter.fromJson(jsonMapFrom(item)),
        ),
      );
    } else if (rawParams is String && rawParams.trim().isNotEmpty) {
      try {
        final parsed = jsonMapFrom(<String, dynamic>{'items': rawParams});
        final encoded = parsed['items'];
        // A schema supplied as JSON text is parsed by the controller so this
        // model remains tolerant of malformed backend metadata.
        if (encoded is List) {
          params.addAll(
            encoded.whereType<Map>().map(
              (item) => CommandParameter.fromJson(jsonMapFrom(item)),
            ),
          );
        }
      } catch (_) {}
    }
    return CommandTemplate(
      id: stringValue(json['cmdId'] ?? json['id']),
      name: stringValue(json['cmdName'] ?? json['name'], fallback: '未命名指令'),
      code: stringValue(json['cmdCode'] ?? json['code']),
      remark: stringValue(json['remark']),
      allowed: _boolValue(json['appAllowed'], fallback: true),
      paramSchema: params,
    );
  }

  static bool _boolValue(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value == '1' || value.toLowerCase() == 'true') return true;
      if (value == '0' || value.toLowerCase() == 'false') return false;
    }
    return fallback;
  }
}

class CommandParameter {
  const CommandParameter({
    required this.key,
    required this.label,
    this.type = 'text',
    this.placeholder = '',
    this.required = false,
    this.defaultValue = '',
    this.min,
    this.max,
    this.options = const <CommandOption>[],
  });

  final String key;
  final String label;
  final String type;
  final String placeholder;
  final bool required;
  final String defaultValue;
  final double? min;
  final double? max;
  final List<CommandOption> options;

  factory CommandParameter.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return CommandParameter(
      key: stringValue(json['key']),
      label: stringValue(json['label'], fallback: '参数'),
      type: stringValue(json['type'], fallback: 'text'),
      placeholder: stringValue(json['placeholder']),
      required: CommandTemplate._boolValue(json['required'], fallback: false),
      defaultValue: stringValue(json['default']),
      min: nullableDoubleValue(json['min']),
      max: nullableDoubleValue(json['max']),
      options: rawOptions is List
          ? rawOptions
                .whereType<Map>()
                .map((item) => CommandOption.fromJson(jsonMapFrom(item)))
                .toList(growable: false)
          : const <CommandOption>[],
    );
  }
}

class CommandOption {
  const CommandOption({required this.value, required this.label});

  final String value;
  final String label;

  factory CommandOption.fromJson(Map<String, dynamic> json) => CommandOption(
    value: stringValue(json['value']),
    label: stringValue(
      json['label'] ?? json['name'],
      fallback: stringValue(json['value']),
    ),
  );
}

class CommandRecord {
  const CommandRecord({required this.data});

  final JsonMap data;

  String get id => stringValue(data['id'] ?? data['commandId']);
  String get name =>
      stringValue(data['cmdName'] ?? data['commandType'], fallback: '未知指令');
  String get status => stringValue(data['sendStatus']);
  String get time => stringValue(data['sendTime'] ?? data['createTime']);
  String get reason => stringValue(data['reason'] ?? data['responseContent']);
  int get retryCount => intValue(data['retryCount']);
}
