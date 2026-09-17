import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';

import 'reference_ui.dart';

DateTime _sixMonthsAgo(DateTime value) {
  final month = value.month - 6;
  final year = value.year + (month <= 0 ? -1 : 0);
  final normalizedMonth = month <= 0 ? month + 12 : month;
  final lastDay = DateTime(year, normalizedMonth + 1, 0).day;
  return DateTime(
    year,
    normalizedMonth,
    value.day > lastDay ? lastDay : value.day,
    value.hour,
    value.minute,
    value.second,
    value.millisecond,
    value.microsecond,
  );
}

/// Shows the shared date-and-time picker with the app's supported bounds.
///
/// Uses `flutter_cupertino_datetime_picker`, which is a Cupertino-native picker
/// presented via `Navigator.push` (a bottom sheet), so it works in this
/// Cupertino app without Material's `showModalBottomSheet`.
Future<DateTime?> showReferenceDateTimePicker({
  required BuildContext context,
  required DateTime initialDate,
  bool allowFuture = false,
}) {
  final now = DateTime.now();
  final minimumDate = allowFuture ? now : _sixMonthsAgo(now);
  final maximumDate = allowFuture
      ? DateTime(now.year + 100, now.month, now.day, 23, 59, 59)
      : now;
  final clampedInitial = initialDate.isBefore(minimumDate)
      ? minimumDate
      : initialDate.isAfter(maximumDate)
          ? maximumDate
          : initialDate;

  final completer = Completer<DateTime?>();
  // Guards against double completion (confirm/cancel also trigger onClose).
  var settled = false;
  void settle(DateTime? value) {
    if (!settled) {
      settled = true;
      completer.complete(value);
    }
  }

  DatePicker.showDatePicker(
    context,
    minDateTime: minimumDate,
    maxDateTime: maximumDate,
    initialDateTime: clampedInitial,
    dateFormat: 'yyyy-MM-dd HH:mm:ss',
    locale: DateTimePickerLocale.zh_cn,
    pickerTheme: DateTimePickerTheme(
      backgroundColor: CupertinoColors.systemBackground,
      itemTextStyle: TextStyle(color: AppColors.text, fontSize: 16),
      confirmTextStyle: TextStyle(
        color: AppColors.primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      cancelTextStyle: TextStyle(color: AppColors.secondaryText, fontSize: 16),
      pickerHeight: 230.0,
      titleHeight: 44.0,
    ),
    onCancel: () => settle(null),
    onConfirm: (dateTime, _) => settle(dateTime),
    onClose: () => settle(null),
  );

  return completer.future;
}
