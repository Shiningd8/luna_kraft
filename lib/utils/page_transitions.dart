import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luna_kraft/flutter_flow/nav/nav.dart'; // Import for TransitionInfo
import 'package:page_transition/page_transition.dart';

/// A utility class that provides consistent page transitions throughout the app
class AppPageTransitions {
  /// Get a standard slide transition from right to left (most common navigation pattern)
  static TransitionInfo slideTransition({Duration? duration}) {
    return TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.rightToLeft,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Get a fade transition (subtle transition between related screens)
  static TransitionInfo fadeTransition({Duration? duration}) {
    return TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.fade,
      duration: duration ?? const Duration(milliseconds: 400),
    );
  }

  /// Get a scale transition (good for dialogs or popovers)
  static TransitionInfo scaleTransition(
      {Duration? duration, Alignment? alignment}) {
    return TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.scale,
      duration: duration ?? const Duration(milliseconds: 350),
      alignment: alignment ?? Alignment.center,
    );
  }

  /// Get a bottom to top transition (good for bottom sheets or modals)
  static TransitionInfo bottomToTopTransition({Duration? duration}) {
    return TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.bottomToTop,
      duration: duration ?? const Duration(milliseconds: 350),
    );
  }

  /// Navigate to a new page with the specified transition
  static void navigateTo(
    BuildContext context,
    String routeName, {
    TransitionInfo? transition,
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
  }) {
    transition ??= slideTransition();

    context.pushNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: <String, dynamic>{
        kTransitionInfoKey: transition,
      },
    );
  }

  /// Navigate and replace the current page with the specified transition
  static void navigateAndReplace(
    BuildContext context,
    String routeName, {
    TransitionInfo? transition,
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
  }) {
    transition ??= fadeTransition();

    context.goNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: <String, dynamic>{
        kTransitionInfoKey: transition,
      },
    );
  }
}
