import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luna_kraft/flutter_flow/nav/nav.dart';
import 'package:luna_kraft/utils/page_transitions.dart';
import 'package:page_transition/page_transition.dart';

/// A helper class for app navigation with consistent transition animations
class AppNavigationHelper {
  /// General purpose navigation with fade transition (for most pages)
  static void navigateWithFade(
    BuildContext context,
    String routeName, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    // Create the transition info
    final transitionInfo = TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.fade,
      duration: duration,
    );

    // Add the transition info to the extra data
    final Map<String, dynamic> extraData =
        extra != null ? (extra as Map<String, dynamic>) : <String, dynamic>{};

    extraData[kTransitionInfoKey] = transitionInfo;

    // Navigate using the Go Router
    context.pushNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extraData,
    );
  }

  /// Specific navigation to detailed post with scale transition
  static void navigateToDetailedPost(
    BuildContext context, {
    required dynamic docref,
    required dynamic userref,
    bool showComments = false,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // Create the transition info with scale effect
    final transitionInfo = TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.scale,
      alignment: Alignment.center,
      duration: duration,
    );

    // Convert references to string IDs if they're document references
    String? docId;
    String? userId;

    // Handle document references or string IDs for post reference
    if (docref is String) {
      docId = docref;
    } else if (docref != null) {
      try {
        docId = docref.id; // Get ID from DocumentReference
      } catch (e) {
        print('Error extracting post ID: $e');
      }
    }

    // Handle document references or string IDs for user reference
    if (userref is String) {
      userId = userref;
    } else if (userref != null) {
      try {
        userId = userref.id; // Get ID from DocumentReference
      } catch (e) {
        print('Error extracting user ID: $e');
      }
    }

    print('Navigating to detail post with:'
        '\ndocId: $docId'
        '\nuserId: $userId'
        '\nshowComments: $showComments');

    // Navigate to the detailed post with scale transition
    context.pushNamed(
      'Detailedpost',
      queryParameters: {
        if (docId != null) 'docref': docId,
        if (userId != null) 'userref': userId,
        if (showComments) 'showComments': showComments.toString(),
      },
      extra: <String, dynamic>{
        kTransitionInfoKey: transitionInfo,
      },
    );
  }

  /// Navigate with combined fade and scale transition (smooth blend)
  static void navigateWithCombinedEffect(
    BuildContext context,
    String routeName, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Duration duration = const Duration(milliseconds: 400),
  }) {
    // Create transition info with smooth combined effect
    final transitionInfo = TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.fade,
      duration: duration,
    );

    // Navigate with the combined effect flag
    context.pushNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: <String, dynamic>{
        kTransitionInfoKey: transitionInfo,
        'useSmoothTransition': true, // This is a custom flag we'll use later
      },
    );
  }
}
