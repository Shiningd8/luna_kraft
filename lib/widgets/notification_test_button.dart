import 'package:flutter/material.dart';
import '/services/notification_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// A debug button for testing notifications.
///
/// This widget is intended for development and testing only.
/// To use it, add this button to your debug UI components:
///
/// ```dart
/// NotificationTestButton()
/// ```
class NotificationTestButton extends StatelessWidget {
  const NotificationTestButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.notifications),
      label: Text('Debug Notification'),
      onPressed: () async {
        // Use the simplified manual test notification method
        await NotificationService().manualTestNotification();

        // Print FCM token for debugging
        await NotificationService().debugPrintFCMToken();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
