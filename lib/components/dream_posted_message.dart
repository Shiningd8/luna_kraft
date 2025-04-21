import 'package:flutter/material.dart';
import '../flutter_flow/flutter_flow_theme.dart';

class DreamPostedMessage {
  static void show(
    BuildContext context, {
    bool isError = false,
    String errorMessage = '',
    int? remainingUploads,
    String? message,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();

    // Base success message
    String displayMessage = message ?? 'Dream shared successfully!';

    // If there's an error, show the error message
    if (isError) {
      displayMessage =
          errorMessage.isEmpty ? 'Failed to share dream' : errorMessage;
    }

    // Add remaining uploads info if provided
    if (!isError && remainingUploads != null) {
      if (remainingUploads == 0) {
        displayMessage += ' You\'ve used all your free uploads for today.';
      } else if (remainingUploads == 1) {
        displayMessage += ' You have 1 free upload left today.';
      } else {
        displayMessage +=
            ' You have $remainingUploads free uploads left today.';
      }
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              if (!isError)
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                )
              else
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayMessage,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Figtree',
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isError ? Color(0xFFE57373) : Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }
}
