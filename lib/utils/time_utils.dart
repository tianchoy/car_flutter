/// 时间格式化工具。
library;

/// 把时间转成「刚刚 / x分钟前 / x小时前 / x天前 / x个月前 / x年前」的相对描述。
///
/// 支持两种输入：
/// - 日期时间字符串，如 `2026-09-17 10:30:00`；
/// - 毫秒时间戳字符串，如 `1694938200000`。
///
/// 无法解析或入参为空时返回 [fallback]。
String relativeTime(String? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.trim();
  if (text.isEmpty) return fallback;

  DateTime? date = DateTime.tryParse(text.replaceFirst(' ', 'T'));
  if (date == null) {
    final millis = int.tryParse(text);
    if (millis != null) {
      date = DateTime.fromMillisecondsSinceEpoch(millis);
    }
  }
  if (date == null) return fallback;

  final difference = DateTime.now().difference(date);
  // 服务端时间可能略微超前于本地，按「刚刚」处理。
  if (difference.isNegative || difference.inMinutes < 1) return '刚刚';
  if (difference.inHours < 1) return '${difference.inMinutes}分钟前';
  if (difference.inDays < 1) return '${difference.inHours}小时前';

  final days = difference.inDays;
  if (days < 30) return '$days天前';
  final months = days ~/ 30;
  if (months < 12) return '$months个月前';
  return '${days ~/ 365}年前';
}

/// 格式化为 `yyyy-MM-dd HH:mm:ss`（接口通用的时间格式）。
String formatDateTime(DateTime value) {
  String pad(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${pad(value.month)}-${pad(value.day)} '
      '${pad(value.hour)}:${pad(value.minute)}:${pad(value.second)}';
}
