import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '/backend/schema/posts_record.dart';
import '/backend/schema/user_record.dart';
import '/components/share_poster_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class ShareUtil {
  // Main method to share a post
  static Future<void> sharePost(
      BuildContext context, PostsRecord post, UserRecord user) async {
    if (!context.mounted) return;

    try {
      // Create the share poster widget
      final SharePosterWidget posterWidget = SharePosterWidget(
        post: post,
        user: user,
      );

      // Show preview dialog
      final bool? shouldShare = await _showSharePreview(context, posterWidget);

      // If user cancels, exit
      if (shouldShare != true || !context.mounted) return;

      // Show loading dialog
      _showLoadingDialog(context);

      // Wait a moment to make sure the loading dialog is shown and widgets are properly laid out
      await Future.delayed(const Duration(milliseconds: 300));

      // Get the state from the poster widget to access rendering methods
      final BuildContext dialogContext = context;

      try {
        // Create a temporary widget to render
        final tempKey = GlobalKey();
        final tempWidget = RepaintBoundary(
          key: tempKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: posterWidget,
              ),
            ),
          ),
        );

        // Insert the widget into the overlay
        final overlayState = Overlay.of(context);
        final overlayEntry = OverlayEntry(
          builder: (context) => tempWidget,
        );

        overlayState.insert(overlayEntry);

        // Wait for the widget to be rendered
        await Future.delayed(const Duration(milliseconds: 500));

        // Capture image data
        final tempDir = await getTemporaryDirectory();
        final file =
            File('${tempDir.path}/dream_post_${post.reference.id}.png');

        // Create simple image
        final boundary =
            tempKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          throw Exception('Failed to get image data');
        }

        // Save image to file
        await file.writeAsBytes(byteData.buffer.asUint8List());

        // Clean up overlay
        overlayEntry.remove();

        // Close loading dialog
        if (dialogContext.mounted) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        }

        // Share the file
        if (file.existsSync() && dialogContext.mounted) {
          await Share.shareXFiles(
            [XFile(file.path)],
            text: 'Check out this dream: ${post.title}',
            subject: 'Dream: ${post.title}',
          );
        } else {
          throw Exception('Image file not found or context unmounted');
        }
      } catch (e) {
        print('Error rendering or sharing image: $e');
        if (dialogContext.mounted) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Text('Error: Failed to share image. $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message if context is still mounted
      if (context.mounted) {
        // Close loading dialog if it's showing
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {
          // Ignore if not showing
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error sharing post: $e');
    }
  }

  // Method to share app invitation link
  static Future<void> shareAppInvitation(BuildContext context,
      {String? userName}) async {
    if (!context.mounted) return;

    try {
      final String appLink = 'https://lunakraft.com/';

      // Create personalized message
      final String message = userName != null && userName.isNotEmpty
          ? '${userName} invites you to join the dreamy experience on LunaKraft! Create, visualize and share your dreams with our AI-powered dream crafting platform. Check it out: $appLink'
          : 'Join me on the dreamy experience with LunaKraft! Create, visualize and share your dreams with our AI-powered dream crafting platform. Check it out: $appLink';

      try {
        // Share the invitation
        await Share.share(
          message,
          subject: 'Join me on LunaKraft!',
        );
      } catch (e) {
        // Show error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sharing invitation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }

        print('Error sharing invitation: $e');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error preparing invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      print('Error preparing invitation: $e');
    }
  }

  // Helper method to show a loading overlay
  static OverlayEntry _showLoadingOverlay(BuildContext context) {
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing to share...'),
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    return overlayEntry;
  }

  // Show a preview dialog with a share button
  static Future<bool?> _showSharePreview(
      BuildContext context, SharePosterWidget posterWidget) async {
    if (!context.mounted) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      // Use rootNavigator to ensure dialog appears above all routes
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with modern design
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(dialogContext).secondaryBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Preview',
                      style: FlutterFlowTheme.of(dialogContext)
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                    ),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(
                    begin: -0.1,
                    end: 0,
                    duration: 200.ms,
                    curve: Curves.easeOut,
                  ),

              // Poster Preview with improved styling
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(
                      0), // Removed padding for full-bleed design
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
                    ),
                    child: posterWidget,
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.0, 1.0),
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  ),

              // Action Button with more modern styling
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(dialogContext).secondaryBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                margin: const EdgeInsets.only(top: 20),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(dialogContext).pop(true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(dialogContext)
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.share_rounded,
                              size: 22,
                              color: FlutterFlowTheme.of(dialogContext).primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Share',
                            style: FlutterFlowTheme.of(dialogContext)
                                .titleMedium
                                ?.copyWith(
                                  color: FlutterFlowTheme.of(dialogContext)
                                      .primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 19,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(
                    begin: 0.1,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  ),
            ],
          ),
        );
      },
    );
  }

  // Show a loading dialog
  static void _showLoadingDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Creating image...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
