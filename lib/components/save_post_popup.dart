import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';

class SavePostPopup {
  // Shows either a popup (for save) or a snackbar (for unsave) based on the action
  static void showSavedPopup(BuildContext context, {required bool isSaved}) {
    // For saved actions (isSaved == true) - show bottom sheet popup
    if (isSaved) {
      _showSaveBottomSheetPopup(context);
    } else {
      // For unsaved actions (isSaved == false) - show capsule snackbar
      _showUnsaveSnackbar(context);
    }
  }

  // Bottom sheet popup for when a post is saved
  static void _showSaveBottomSheetPopup(BuildContext context) {
    // Create overlay entry for the popup
    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible touch handler for dismissing the popup
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                overlayEntry.remove();
              },
              // Using opaque:false allows touches to pass through
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // Popup content
          Center(
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                constraints: BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Gradient animated background
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              FlutterFlowTheme.of(context)
                                  .primary
                                  .withOpacity(0.2),
                              FlutterFlowTheme.of(context)
                                  .secondary
                                  .withOpacity(0.3),
                            ],
                          ),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .rotate(
                            duration: 10.seconds,
                            begin: 0,
                            end: 0.05,
                          )
                          .then()
                          .rotate(
                            duration: 10.seconds,
                            begin: 0.05,
                            end: 0,
                          ),
                    ),

                    // Glassmorphic container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .primaryBackground
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Floating shape decorations
                              Stack(
                                children: [
                                  // Animation area
                                  Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: SizedBox(
                                      width: 120,
                                      height: 120,
                                      child: Lottie.asset(
                                        'assets/jsons/save.json',
                                        fit: BoxFit.contain,
                                        repeat: false,
                                        frameRate: FrameRate(60),
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            child: Icon(
                                              Icons.bookmark,
                                              size: 40,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  // Decorative elements
                                  Positioned(
                                    right: 60,
                                    top: 30,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primary
                                            .withOpacity(0.7),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                        .animate(
                                            onPlay: (controller) =>
                                                controller.repeat())
                                        .scale(
                                          duration: 2.seconds,
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.5, 1.5),
                                        )
                                        .then()
                                        .scale(
                                          duration: 2.seconds,
                                          begin: const Offset(1.5, 1.5),
                                          end: const Offset(1, 1),
                                        ),
                                  ),
                                  Positioned(
                                    left: 70,
                                    top: 45,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondary
                                            .withOpacity(0.7),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                        .animate(
                                            onPlay: (controller) =>
                                                controller.repeat())
                                        .scale(
                                          duration: 2.5.seconds,
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.5, 1.5),
                                        )
                                        .then()
                                        .scale(
                                          duration: 2.5.seconds,
                                          begin: const Offset(1.5, 1.5),
                                          end: const Offset(1, 1),
                                        ),
                                  ),
                                ],
                              ),

                              // Text with gradient
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      colors: [
                                        FlutterFlowTheme.of(context).primary,
                                        FlutterFlowTheme.of(context).secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    'Post Saved!',
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          decoration: TextDecoration.none,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),

                              // Description
                              Padding(
                                padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                                child: Text(
                                  'This dream post has been added to your saved collection.',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .copyWith(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        decoration: TextDecoration.none,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              // Button
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      overlayEntry.remove();
                                      context.pushNamed('SavedPosts');
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                            FlutterFlowTheme.of(context)
                                                .secondary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: FlutterFlowTheme.of(context)
                                                .primary
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'View Saved Dreams',
                                          style: FlutterFlowTheme.of(context)
                                              .titleSmall
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: 200.ms)
                                    .move(
                                      begin: Offset(0, 10),
                                      end: Offset(0, 0),
                                      duration: 400.ms,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Add to overlay
    Overlay.of(context).insert(overlayEntry);

    // Auto-dismiss after 3 seconds if not viewing saved posts
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Snackbar for when a post is removed from saved
  static void _showUnsaveSnackbar(BuildContext context) {
    // Create overlay entry for the snackbar
    late final OverlayEntry overlayEntry;

    // Calculate safe area to position the snackbar
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: bottomPadding,
        left: 0,
        right: 0,
        child: Center(
          child: _buildUnsaveSnackbar(context),
        ),
      ),
    );

    // Add to overlay
    Overlay.of(context).insert(overlayEntry);

    // Auto-dismiss after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static Widget _buildUnsaveSnackbar(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FlutterFlowTheme.of(context).primary.withOpacity(0.6),
                    FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lottie animation or icon
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Lottie.asset(
                      'assets/jsons/unsave.json',
                      fit: BoxFit.contain,
                      repeat: false,
                      frameRate: FrameRate(60),
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.bookmark_border,
                          color: Colors.white,
                          size: 24,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  // Text
                  Text(
                    'Post Removed from Saved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(target: 1)
        .slideY(
          begin: 1.0,
          end: 0.0,
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .fade(
          begin: 0.0,
          end: 1.0,
          duration: 300.ms,
        );
  }
}
