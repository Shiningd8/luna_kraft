import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({Key? key}) : super(key: key);

  static Future<bool> show(BuildContext context) async {
    // Check if we already asked and don't show again
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked =
        prefs.getBool('notification_permission_asked') ?? false;
    final alreadyGranted =
        prefs.getBool('notification_permission_granted') ?? false;

    // If permission is already granted, don't show dialog
    if (alreadyGranted) {
      return true;
    }

    // Otherwise, always show the dialog for consistency
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return NotificationPermissionDialog();
      },
    );

    // Mark as asked
    await prefs.setBool('notification_permission_asked', true);

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              color: FlutterFlowTheme.of(context).primary,
              size: 36,
            ),
          ),
          SizedBox(height: 20),

          // Title
          Text(
            'Stay Connected!',
            style: FlutterFlowTheme.of(context).headlineMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),

          // Description
          Text(
            'Get notified when someone likes your post, follows you, or comments on your content.',
            style: FlutterFlowTheme.of(context).bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop(false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        FlutterFlowTheme.of(context).secondaryBackground,
                    foregroundColor: FlutterFlowTheme.of(context).primaryText,
                    side: BorderSide(
                      color: FlutterFlowTheme.of(context)
                          .primaryText
                          .withOpacity(0.3),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Not Now'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final hasPermission =
                        await NotificationService().requestPermission();
                    Navigator.of(context).pop(hasPermission);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Enable'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
