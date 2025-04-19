import 'package:flutter/material.dart';

/// A custom page route that combines multiple animations for a smoother, more engaging transition
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Curve curve;
  final Duration duration;
  final bool fadeIn;
  final bool scaleUp;
  final bool slideIn;
  final bool slideFromBottom;

  SmoothPageRoute({
    required this.page,
    this.curve = Curves.easeInOut,
    this.duration = const Duration(milliseconds: 400),
    this.fadeIn = true,
    this.scaleUp = true,
    this.slideIn = true,
    this.slideFromBottom = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            var result = child;

            // Apply fade animation
            if (fadeIn) {
              result = FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0)
                    .animate(curvedAnimation),
                child: result,
              );
            }

            // Apply scale animation
            if (scaleUp) {
              result = ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0)
                    .animate(curvedAnimation),
                child: result,
              );
            }

            // Apply slide animation
            if (slideIn) {
              final begin = slideFromBottom
                  ? const Offset(0.0, 0.2) // Slide up from slightly below
                  : const Offset(0.05, 0.0); // Slide from right (slight)

              result = SlideTransition(
                position: Tween<Offset>(
                  begin: begin,
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: result,
              );
            }

            return result;
          },
        );
}

/// Extension methods to make using the custom transitions easier
extension BuildContextPageTransitionExtension on BuildContext {
  /// Navigate with a smooth, combined animation (fade + scale + slight slide)
  Future<T?> pushSmoothPage<T extends Object?>({
    required Widget page,
    Duration? duration,
    Curve curve = Curves.easeInOut,
    bool fadeIn = true,
    bool scaleUp = true,
    bool slideIn = true,
    bool slideFromBottom = false,
  }) {
    return Navigator.of(this).push<T>(
      SmoothPageRoute<T>(
        page: page,
        duration: duration ?? const Duration(milliseconds: 400),
        curve: curve,
        fadeIn: fadeIn,
        scaleUp: scaleUp,
        slideIn: slideIn,
        slideFromBottom: slideFromBottom,
      ),
    );
  }

  /// Replace the current screen with a smooth, combined animation
  Future<T?> pushReplacementSmoothPage<T extends Object?, TO extends Object?>({
    required Widget page,
    Duration? duration,
    Curve curve = Curves.easeInOut,
    bool fadeIn = true,
    bool scaleUp = true,
    bool slideIn = true,
    bool slideFromBottom = false,
    TO? result,
  }) {
    return Navigator.of(this).pushReplacement<T, TO>(
      SmoothPageRoute<T>(
        page: page,
        duration: duration ?? const Duration(milliseconds: 400),
        curve: curve,
        fadeIn: fadeIn,
        scaleUp: scaleUp,
        slideIn: slideIn,
        slideFromBottom: slideFromBottom,
      ),
      result: result,
    );
  }
}
