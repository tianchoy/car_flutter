import 'dart:convert';

const int businessLegacySuccessCode = 0;
const int businessSuccessCode = 200;
const int businessTokenExpiredCode = 401;

typedef JsonMap = Map<String, dynamic>;

bool isBusinessSuccessCode(int code) => code == businessSuccessCode;

bool isBusinessTokenExpiredCode(int code) => code == businessTokenExpiredCode;

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
