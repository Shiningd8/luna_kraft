import 'package:flutter/material.dart';

/// Safely executes a function and returns its result, or null if an error occurs.
T? safeGet<T>(T Function() fn) {
  try {
    return fn();
  } catch (e) {
    return null;
  }
}

/// Converts a CSS color string to a Flutter Color.
Color? fromCssColor(String? cssColor) {
  if (cssColor == null) return null;
  try {
    // Handle hex colors
    if (cssColor.startsWith('#')) {
      final hex = cssColor.substring(1);
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      } else if (hex.length == 8) {
        return Color(int.parse('0x$hex'));
      }
    }
    // Handle rgb/rgba colors
    else if (cssColor.startsWith('rgb')) {
      final values = cssColor
          .replaceAll(RegExp(r'[rgb\(\)]'), '')
          .split(',')
          .map((e) => double.parse(e.trim()))
          .toList();
      if (values.length == 3) {
        return Color.fromRGBO(
          values[0].toInt(),
          values[1].toInt(),
          values[2].toInt(),
          1,
        );
      } else if (values.length == 4) {
        return Color.fromRGBO(
          values[0].toInt(),
          values[1].toInt(),
          values[2].toInt(),
          values[3],
        );
      }
    }
    return null;
  } catch (e) {
    return null;
  }
}

/// Extension method to convert Color to CSS string
extension ColorExtension on Color {
  String toCssString() {
    return '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
