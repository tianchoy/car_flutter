import 'dart:convert';

const int businessLegacySuccessCode = 0;
const int businessSuccessCode = 200;
const int businessTokenExpiredCode = 401;

typedef JsonMap = Map<String, dynamic>;

bool isBusinessSuccessCode(int code) => code == businessSuccessCode;

bool isBusinessTokenExpiredCode(int code) => code == businessTokenExpiredCode;

/// 登录接口要求「先设置密码」的业务标志。
///
/// 后端返回位置不固定（`msg` 文本、`data` 字段、顶层字段均有可能），
/// 因此统一按「去掉分隔符后的文本」匹配：`NEED_SET_PASSWORD`、
/// `NEED_SET_PASSWORD:xxx`、`needSetPassword`、`need_set_password` 都能命中。
const String businessNeedSetPasswordFlag = 'NEED_SET_PASSWORD';

/// 登录接口要求「先完成注册」的业务标志（手机号首次短信登录）。
///
/// 与 Web 端一致：[businessNeedRegisterFlag] 与 [businessNeedSetPasswordFlag]
/// 后续处理完全相同，都跳转「设置密码」页补设密码。
const String businessNeedRegisterFlag = 'NEED_REGISTER';

/// 判定登录响应是否属于「手机号已注册但尚未设置密码」。
///
/// [message] 为响应的 `msg` / `message`；[payload] 为原始响应体
/// （`ApiBusinessException.payload` / `ApiResponse.raw`）。
bool isNeedSetPasswordSignal({required String message, Object? payload}) =>
    _hasBusinessFlag(message, businessNeedSetPasswordFlag) ||
    _hasBusinessFlagIn(payload, businessNeedSetPasswordFlag);

/// 判定登录响应是否属于「手机号尚未注册」。
bool isNeedRegisterSignal({required String message, Object? payload}) =>
    _hasBusinessFlag(message, businessNeedRegisterFlag) ||
    _hasBusinessFlagIn(payload, businessNeedRegisterFlag);

/// 登录是否要求先补设密码：补设密码与首次注册在后端是同一套流程
///（都会用手机号 + 验证码设置密码），因此共用「设置密码」页。
bool requiresPasswordSetup({required String message, Object? payload}) =>
    isNeedSetPasswordSignal(message: message, payload: payload) ||
    isNeedRegisterSignal(message: message, payload: payload);

bool _hasBusinessFlagIn(Object? value, String flag) {
  if (value == null) return false;
  if (value is String) return _hasBusinessFlag(value, flag);
  if (value is Map) {
    for (final entry in value.entries) {
      // 字段名本身也可能带标志（例如 needSetPassword: true）。
      if (_hasBusinessFlag('${entry.key}', flag)) return true;
      if (_hasBusinessFlagIn(entry.value, flag)) return true;
    }
    return false;
  }
  if (value is Iterable) {
    return value.any((item) => _hasBusinessFlagIn(item, flag));
  }
  return _hasBusinessFlag(value.toString(), flag);
}

bool _hasBusinessFlag(String value, String flag) {
  final normalized = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (normalized.isEmpty) return false;
  return normalized.contains(flag.replaceAll('_', ''));
}

/// A source-compatible backend envelope.
///
/// The production API uses `code` for business status independently of the HTTP
/// response status. `msg` is preferred, with `message` accepted for legacy
/// endpoints.
class ApiResponse<T> {
  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.raw = const <String, dynamic>{},
  });

  final int code;
  final String message;
  final T? data;
  final JsonMap raw;

  bool get isSuccess => isBusinessSuccessCode(code);
  bool get isTokenExpired => isBusinessTokenExpiredCode(code);

  factory ApiResponse.fromJson(
    Object? value, {
    T? Function(Object? data)? dataParser,
  }) {
    final raw = jsonMapFrom(value);
    final rawData = raw['data'];
    return ApiResponse<T>(
      code: intValue(raw['code'], fallback: -1),
      message: stringValue(raw['msg']).isNotEmpty
          ? stringValue(raw['msg'])
          : stringValue(raw['message']),
      data: dataParser == null ? rawData as T? : dataParser(rawData),
      raw: raw,
    );
  }
}

class ApiBusinessException implements Exception {
  const ApiBusinessException({required this.message, this.code, this.payload});

  final String message;
  final int? code;
  final Object? payload;

  @override
  String toString() => message;
}

class ApiNetworkException implements Exception {
  const ApiNetworkException(this.message, {this.statusCode, this.payload});

  final String message;
  final int? statusCode;
  final Object? payload;

  @override
  String toString() => message;
}

JsonMap jsonMapFrom(Object? value) {
  if (value is JsonMap) return Map<String, dynamic>.from(value);
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  if (value is String && value.isNotEmpty) {
    try {
      return jsonMapFrom(jsonDecode(value));
    } on FormatException {
      return const <String, dynamic>{};
    }
  }
  return const <String, dynamic>{};
}

List<Object?> jsonListFrom(Object? value) {
  if (value is List) return List<Object?>.from(value);
  return const <Object?>[];
}

String stringValue(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

int intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? nullableDoubleValue(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}
