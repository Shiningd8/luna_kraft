import 'dart:ui';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/notification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

class ModernNotificationToast extends StatefulWidget {
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
  State<ModernNotificationToast> createState() =>
      _ModernNotificationToastState();
}

class _ModernNotificationToastState extends State<ModernNotificationToast> {
  // Store theme data to prevent context access during disposal
  late ThemeData _theme;
  late Color _primaryColor;

  // Focus node for handling focus safely
  final FocusScopeNode _focusNode = FocusScopeNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache theme values when dependencies change
    _theme = Theme.of(context);
    _primaryColor = FlutterFlowTheme.of(context).primary;
  }

  @override
  void dispose() {
    // Clean up focus node to prevent memory leaks
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      // Use a dedicated FocusScope to isolate this widget's focus handling
      node: _focusNode,
      canRequestFocus: false, // Prevents auto-focusing
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 64, left: 16, right: 16),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Dismissible(
              key: Key('notification-${DateTime.now().millisecondsSinceEpoch}'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss?.call(),
              child: Material(
                color: Colors.transparent,
                child: _buildGlassmorphicContainer(),
              ),
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

  Widget _buildGlassmorphicContainer() {
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
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primaryColor.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
          child: Row(
            children: [
              _buildNotificationIcon(),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.notification.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (widget.notification.body.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        widget.notification.body,
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
              _buildViewButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    Color iconBackgroundColor = _primaryColor;
    IconData iconData = Icons.notifications;

    // Determine icon based on notification type
    if (widget.notification.isLike) {
      iconData = Icons.favorite;
      iconBackgroundColor = Colors.red.shade400;
    } else if (widget.notification.isFollowRequest) {
      iconData = Icons.person_add;
      iconBackgroundColor = Colors.blue.shade400;
    } else if (widget.notification.isReply) {
      iconData = Icons.reply;
      iconBackgroundColor = Colors.green.shade400;
    } else if (widget.notification.type == 'test') {
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

  Widget _buildViewButton() {
    // Use a raw Material button without InkWell to avoid focus-related issues
    return Material(
      color: _primaryColor.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        // Disabling highlighting capabilities to avoid focus issues
        highlightColor: Colors.transparent,
        splashColor: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primaryColor.withOpacity(0.3),
              width: 1,
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
  static Timer? _dismissTimer;

  static void show({
    required BuildContext context,
    required NotificationPayload notification,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    try {
      // Dismiss any existing notification first
      dismiss();

      // Make sure context is still valid
      if (!context.mounted) {
        print('Context is no longer mounted, cannot show notification');
        return;
      }

      // Get the overlay state from the nearest Overlay widget
      final OverlayState? overlayState = Overlay.of(context);
      if (overlayState == null) {
        print('No overlay state found. Make sure you are inside a Navigator.');
        return;
      }

      // Pre-cache theme data to avoid context dependency in overlay
      final primaryColor = FlutterFlowTheme.of(context).primary;

      // Create a builder that doesn't depend on the original context
      _currentNotification = OverlayEntry(
        builder: (overlayContext) => NotificationLifecycleWrapper(
          child: Material(
            type: MaterialType.transparency,
            child: ModernNotificationToast(
              notification: notification,
              onTap: () {
                dismiss();
                if (WidgetsBinding.instance.lifecycleState ==
                    AppLifecycleState.resumed) {
                  onTap?.call();
                }
              },
              onDismiss: dismiss,
            ),
          ),
        ),
      );

      overlayState.insert(_currentNotification!);

      // Cancel any existing timer
      _dismissTimer?.cancel();

      // Auto dismiss after duration
      _dismissTimer = Timer(duration, () {
        dismiss();
      });
    } catch (e) {
      print('Error showing notification overlay: $e');
      // Recovery: make sure we don't have dangling overlays
      _cleanupResources();
    }
  }

  static void dismiss() {
    try {
      // Cancel timer if it exists
      _dismissTimer?.cancel();
      _dismissTimer = null;

      // Remove overlay entry if it exists
      if (_currentNotification != null) {
        _currentNotification!.remove();
        _currentNotification = null;
      }
    } catch (e) {
      print('Error dismissing notification overlay: $e');
      _cleanupResources();
    }
  }

  // Clean up all resources as a safety measure
  static void _cleanupResources() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentNotification = null;
  }
}

// Wrapper widget to handle lifecycle events for notifications
class NotificationLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const NotificationLifecycleWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<NotificationLifecycleWrapper> createState() =>
      _NotificationLifecycleWrapperState();
}

class _NotificationLifecycleWrapperState
    extends State<NotificationLifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      // App is going to background, dismiss any notifications
      ModernNotificationOverlay.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
