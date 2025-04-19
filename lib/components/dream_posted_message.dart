import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'dart:ui';

class DreamPostedMessage {
  // Static method to show the successful post message
  static void show(BuildContext context,
      {bool isError = false, String? errorMessage, String? message}) {
    // Overlay entry for showing the message on top of all content
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => _DreamPostedMessageContent(
        isError: isError,
        message: isError
            ? (errorMessage ?? 'An error occurred')
            : (message ?? 'Dream Posted'),
      ),
    );

    // Insert the overlay
    Overlay.of(context).insert(overlayEntry);

    // Auto-dismiss after 3 seconds
    Future.delayed(Duration(milliseconds: 3000), () {
      overlayEntry.remove();
    });
  }
}

class _DreamPostedMessageContent extends StatelessWidget {
  final bool isError;
  final String message;

  const _DreamPostedMessageContent({
    this.isError = false,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 300),
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: (isError
                            ? Colors.red.withOpacity(0.08)
                            : Colors.white.withOpacity(0.12)),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: (isError
                              ? Colors.red.withOpacity(0.2)
                              : Colors.white.withOpacity(0.3)),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isError
                                  ? Colors.red.withOpacity(0.3)
                                  : FlutterFlowTheme.of(context)
                                      .primary
                                      .withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isError
                                  ? Icons.error_outline
                                  : Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              message,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fade(
          duration: 350.ms,
          curve: Curves.easeOut,
          begin: 0,
          end: 1,
        )
        .slide(
          duration: 400.ms,
          curve: Curves.easeOutQuint,
          begin: Offset(0, 0.5),
          end: Offset.zero,
        )
        .then(delay: 2500.ms)
        .fade(
          duration: 500.ms,
          curve: Curves.easeIn,
          begin: 1,
          end: 0,
        );
  }
}
