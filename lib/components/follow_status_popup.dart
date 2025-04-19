import 'package:flutter/material.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class FollowStatusPopup {
  // Show a popup with animation when a user is followed/unfollowed
  static void showFollowStatusPopup(BuildContext context,
      {required bool isFollowed, String status = ''}) {
    // Create overlay entry for the popup
    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child:
                _buildPopupContent(context, isFollowed, overlayEntry, status),
          ),
        ),
      ),
    );

    // Add to overlay
    Overlay.of(context).insert(overlayEntry);

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static Widget _buildPopupContent(BuildContext context, bool isFollowed,
      OverlayEntry overlayEntry, String status) {
    // Determine text and icon based on status
    String displayText;
    IconData displayIcon;
    Color iconColor;

    switch (status) {
      case 'request_sent':
        displayText = 'Follow Request Sent';
        displayIcon = Icons.send;
        iconColor = FlutterFlowTheme.of(context).primary;
        break;
      case 'request_cancelled':
        displayText = 'Follow Request Cancelled';
        displayIcon = Icons.cancel_outlined;
        iconColor = Colors.grey;
        break;
      case 'request_accepted':
        displayText = 'Follow Request Accepted';
        displayIcon = Icons.check_circle_outline;
        iconColor = FlutterFlowTheme.of(context).primary;
        break;
      case 'followed':
        displayText = 'Started Following';
        displayIcon = Icons.person_add;
        iconColor = FlutterFlowTheme.of(context).primary;
        break;
      case 'unfollowed':
        displayText = 'Unfollowed User';
        displayIcon = Icons.person_remove;
        iconColor = Colors.grey;
        break;
      default:
        // Default behavior (backward compatible)
        displayText = isFollowed ? 'Followed User' : 'Unfollowed User';
        displayIcon = isFollowed ? Icons.person_add : Icons.person_remove;
        iconColor =
            isFollowed ? FlutterFlowTheme.of(context).primary : Colors.grey;
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          width: 280,
          decoration: BoxDecoration(
            color:
                FlutterFlowTheme.of(context).primaryBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isFollowed
                  ? FlutterFlowTheme.of(context).primary.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animated container
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isFollowed
                      ? FlutterFlowTheme.of(context).primary.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    displayIcon,
                    size: 16,
                    color: iconColor,
                  ),
                ),
              ),
              SizedBox(width: 10),
              // Text
              Flexible(
                child: Text(
                  displayText,
                  style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fade(duration: 300.ms)
        .scale(
          begin: Offset(0.8, 0.8),
          end: Offset(1, 1),
          duration: 350.ms,
          curve: Curves.easeOutBack,
        )
        .then(delay: 1500.ms)
        .fadeOut(duration: 300.ms);
  }
}
