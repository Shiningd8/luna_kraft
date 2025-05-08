import 'package:flutter/material.dart';

/// A utility class for managing colors and contrast
class ColorUtils {
  /// Determines if a color is light or dark
  static bool isLightColor(Color color) {
    // Using the perceived brightness calculation formula
    final double luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5;
  }

  /// Returns appropriate text color (white or black) based on background color
  static Color getTextColorForBackground(Color backgroundColor) {
    return isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }

  /// Returns appropriate contrast color with proper opacity
  static Color getContrastColor(BuildContext context, Color backgroundColor,
      {double opacity = 1.0}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isLightBg = isLightColor(backgroundColor);

    if (isDark) {
      // In dark mode
      return isLightBg
          ? Colors.black.withOpacity(opacity)
          : Colors.white.withOpacity(opacity);
    } else {
      // In light mode
      return isLightBg
          ? Colors.black.withOpacity(opacity)
          : Colors.white.withOpacity(opacity);
    }
  }

  /// Gets a proper shadow color based on current theme
  static Color getShadowColor(BuildContext context, {double opacity = 0.1}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.black.withOpacity(opacity)
        : Colors.black
            .withOpacity(opacity / 2); // Lighter shadow for light mode
  }
}
