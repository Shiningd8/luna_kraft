import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luna_kraft/utils/custom_page_transitions.dart';
import 'package:luna_kraft/flutter_flow/nav/nav.dart';
import 'package:page_transition/page_transition.dart';

/// A custom GoRouter transition page that uses our smooth transitions
class SmoothTransitionPage<T> extends CustomTransitionPage<T> {
  SmoothTransitionPage({
    required Widget child,
    required TransitionInfo transitionInfo,
  }) : super(
          key: ValueKey(
              '${child.runtimeType}_${DateTime.now().millisecondsSinceEpoch}'),
          child: child,
          transitionDuration: transitionInfo.duration,
          maintainState: true,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );

            var result = child;

            // Apply fade animation
            result = FadeTransition(
              opacity:
                  Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
              child: result,
            );

            // Apply scale animation
            result = ScaleTransition(
              scale:
                  Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
              child: result,
            );

            // Apply slide animation
            final begin = const Offset(0.03, 0.0); // Slight slide from right
            result = SlideTransition(
              position: Tween<Offset>(
                begin: begin,
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: result,
            );

            return result;
          },
        );
}

/// Create an enhanced GoRouter extension for smoother transitions
extension GoRouterExtensions on GoRouter {
  /// Navigate with the smooth combined transition effect
  void pushWithSmoothTransition(
    BuildContext context,
    String routeName, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Duration duration = const Duration(milliseconds: 400),
  }) {
    // Create transition info with the smooth transition flag
    final transitionInfo = TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.fade, // Base type, will be overridden
      duration: duration,
    );

    // Pass extra data with a special flag for smooth transitions
    pushNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: <String, dynamic>{
        kTransitionInfoKey: transitionInfo,
        'useSmoothTransition': true, // Custom flag for our router
      },
    );
  }
}
