import 'dart:ui';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/notification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ModernNotificationToast extends StatelessWidget {
  final NotificationPayload notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const ModernNotificationToast({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 64, left: 16, right: 16),
        child: GestureDetector(
          onTap: onTap,
          child: Dismissible(
            key: Key('notification-${DateTime.now().millisecondsSinceEpoch}'),
            direction: DismissDirection.up,
            onDismissed: (_) => onDismiss?.call(),
            child: Material(
              color: Colors.transparent,
              child: _buildGlassmorphicContainer(context),
            ),
          ),
        ),
      ),
    )
        .animate()
        .slideY(
          begin: -1,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutQuint,
        )
        .fade(
          begin: 0,
          end: 1,
          duration: 400.ms,
        );
  }

  Widget _buildGlassmorphicContainer(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
          child: Row(
            children: [
              _buildNotificationIcon(context),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (notification.body.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8),
              _buildViewButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    Color iconBackgroundColor = FlutterFlowTheme.of(context).primary;
    IconData iconData = Icons.notifications;

    // Determine icon based on notification type
    if (notification.isLike) {
      iconData = Icons.favorite;
      iconBackgroundColor = Colors.red.shade400;
    } else if (notification.isFollowRequest) {
      iconData = Icons.person_add;
      iconBackgroundColor = Colors.blue.shade400;
    } else if (notification.isReply) {
      iconData = Icons.reply;
      iconBackgroundColor = Colors.green.shade400;
    } else if (notification.type == 'test') {
      iconData = Icons.notifications_active;
      iconBackgroundColor = Colors.purple.shade400;
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: iconBackgroundColor.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: iconBackgroundColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconBackgroundColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: Colors.white,
        size: 22,
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.08, 1.08),
          duration: 1500.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildViewButton(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Text(
        'VIEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).shimmer(
          duration: 2000.ms,
          color: Colors.white.withOpacity(0.2),
        );
  }
}

class ModernNotificationOverlay {
  static OverlayEntry? _currentNotification;

  static void show({
    required BuildContext context,
    required NotificationPayload notification,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    try {
      // Dismiss any existing notification first
      dismiss();

      // Get the navigator's overlay context, which is more reliable
      // than using the direct context provided
      final navigatorState = Navigator.of(context, rootNavigator: true);
      final overlayState = navigatorState.overlay;

      if (overlayState == null) {
        print('No overlay state found. Make sure you are inside a Navigator.');
        return;
      }

      _currentNotification = OverlayEntry(
        builder: (context) => ModernNotificationToast(
          notification: notification,
          onTap: () {
            dismiss();
            onTap?.call();
          },
          onDismiss: dismiss,
        ),
      );

      overlayState.insert(_currentNotification!);

      // Auto dismiss after duration
      Future.delayed(duration, () {
        if (_currentNotification != null) {
          dismiss();
        }
      });
    } catch (e) {
      print('Error showing notification overlay: $e');
    }
  }

  static void dismiss() {
    try {
      if (_currentNotification != null) {
        _currentNotification!.remove();
        _currentNotification = null;
      }
    } catch (e) {
      print('Error dismissing notification overlay: $e');
      _currentNotification = null;
    }
  }
}
