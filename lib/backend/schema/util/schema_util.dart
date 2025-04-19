import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

DateTime get getCurrentTimestamp => DateTime.now();

Timestamp getCurrentTimestampAsTimestamp() {
  return Timestamp.fromDate(getCurrentTimestamp);
}

DateTime fromTimestamp(Timestamp timestamp) {
  return timestamp.toDate();
}

Timestamp toTimestamp(DateTime dateTime) {
  return Timestamp.fromDate(dateTime);
}

String dateTimeFormat(String format, DateTime? dateTime) {
  if (dateTime == null) return '';
  return format.replaceAllMapped(
    RegExp(r'(y|M|d|H|m|s|E|a|h)'),
    (match) {
      switch (match.group(1)) {
        case 'y':
          return dateTime.year.toString();
        case 'M':
          return dateTime.month.toString().padLeft(2, '0');
        case 'd':
          return dateTime.day.toString().padLeft(2, '0');
        case 'H':
          return dateTime.hour.toString().padLeft(2, '0');
        case 'm':
          return dateTime.minute.toString().padLeft(2, '0');
        case 's':
          return dateTime.second.toString().padLeft(2, '0');
        case 'E':
          return dateTime.weekday.toString();
        case 'a':
          return dateTime.hour < 12 ? 'AM' : 'PM';
        case 'h':
          return (dateTime.hour % 12).toString().padLeft(2, '0');
        default:
          return match.group(0)!;
      }
    },
  );
}

bool mapEquals<T, U>(Map<T, U>? a, Map<T, U>? b) {
  if (a == null) return b == null;
  if (b == null) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) return false;
  }
  return true;
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (b[i] != a[i]) return false;
  }
  return true;
}

bool setEquals<T>(Set<T>? a, Set<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (final value in a) {
    if (!b.contains(value)) return false;
  }
  return true;
}
