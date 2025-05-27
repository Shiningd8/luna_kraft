import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/utils/serialization_helpers.dart';
import 'package:flutter/material.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:async';
import '/components/share_options_dialog.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_animations.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_util.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luna_kraft/auth/firebase_auth/auth_util.dart';
// import 'package:cloud_functions/cloud_functions.dart';
import '../services/cloud_functions_stub.dart';

class AnimatedEditDialog extends StatefulWidget {
  const AnimatedEditDialog({
    Key? key,
    required this.editpostref,
  }) : super(key: key);

  final DocumentReference editpostref;

  static void show(BuildContext context, DocumentReference editpostref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => AnimatedEditDialog(editpostref: editpostref),
    );
  }

  @override
  State<AnimatedEditDialog> createState() => _AnimatedEditDialogState();
}

class _AnimatedEditDialogState extends State<AnimatedEditDialog> {
  // Timer for updating the countdown
  Timer? _countdownTimer;

  // Post creation time and calculated values
  DateTime? _postCreationTime;
  bool _isEditable = false;
  int _remainingSeconds = 0;
  double _progressValue = 0.0;

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime postDate) {
    // Cancel any existing timer
    _countdownTimer?.cancel();

    // Store post creation time
    _postCreationTime = postDate;

    // Update values immediately
    _updateTimerValues();

    // Set up a timer to update values every second
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimerValues();

        // If time has expired, cancel the timer
        if (!_isEditable) {
          timer.cancel();
        }
      }
    });
  }

  void _updateTimerValues() {
    if (_postCreationTime == null) {
      setState(() {
        _isEditable = false;
        _remainingSeconds = 0;
        _progressValue = 0.0;
      });
      return;
    }

    final currentTime = DateTime.now();
    final timeDifference = currentTime.difference(_postCreationTime!);
    final isEditable = timeDifference.inMinutes < 15;
    final remainingSeconds =
        isEditable ? (15 * 60) - timeDifference.inSeconds : 0;
    final progressValue =
        isEditable ? 1 - (timeDifference.inSeconds / (15 * 60)) : 0.0;

    setState(() {
      _isEditable = isEditable;
      _remainingSeconds = remainingSeconds;
      _progressValue = progressValue;
    });
  }

  Future<void> _deletePost() async {
    // Show confirmation dialog first
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
            ),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context)
                  .primaryBackground
                  .withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delete Dream',
                        style:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Are you sure you want to delete this dream?',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              fontFamily: 'Figtree',
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This action cannot be undone.',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Figtree',
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: () => Navigator.pop(context, false),
                          text: 'Cancel',
                          options: FFButtonOptions(
                            height: 40,
                            padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                            iconPadding:
                                EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  fontFamily: 'Figtree',
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                            elevation: 0,
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context)
                                  .primary
                                  .withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: () => Navigator.pop(context, true),
                          text: 'Delete',
                          options: FFButtonOptions(
                            height: 40,
                            padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                            iconPadding:
                                EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                            color: Colors.red,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  fontFamily: 'Figtree',
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                            elevation: 0,
                            borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      // Debug log
      print('Attempting to delete post with ID: ${widget.editpostref.id}');

      // First try with Cloud Function
      try {
        print('Trying to delete post using Cloud Function');
        final callable = FirebaseFunctions.instance.httpsCallable('deletePost');
        final result = await callable.call({
          'postId': widget.editpostref.id,
        });

        print('Cloud Function result: ${result.data}');

        // Close the dialog
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dream deleted successfully'),
              backgroundColor: FlutterFlowTheme.of(context).primary,
            ),
          );
        }
        return;
      } catch (cloudFunctionError) {
        print('Cloud Function error: $cloudFunctionError');
        print('Falling back to direct deletion...');
      }

      // Fallback to direct deletion
      // Get the post document
      final postDoc = await widget.editpostref.get();
      final postData = postDoc.data() as Map<String, dynamic>?;

      if (postData == null) {
        throw Exception('Post data not found');
      }

      // Check if current user is the owner
      final posterId = postData['poster'] is DocumentReference
          ? (postData['poster'] as DocumentReference).id
          : '';
      final userrefId = postData['userref'] is DocumentReference
          ? (postData['userref'] as DocumentReference).id
          : '';

      print('Current user: $currentUserUid, Post owner: $posterId/$userrefId');

      // Try to delete the post directly
      print('Attempting direct post deletion');
      await widget.editpostref.delete();
      print('Post deleted successfully with direct deletion');

      // Close the dialog
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dream deleted successfully'),
            backgroundColor: FlutterFlowTheme.of(context).primary,
          ),
        );
      }
    } catch (e) {
      print('Delete error: $e');

      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('insufficient permissions')) {
        print('Permission denied error - checking current user auth state...');
        final user = FirebaseAuth.instance.currentUser;
        print('Current user: ${user?.uid}');
        print('Is user signed in: ${user != null}');

        if (user != null) {
          try {
            // Try getting a fresh ID token
            print('Refreshing Firebase ID token...');
            await user.getIdToken(true);
            print('Token refreshed, attempting delete again...');

            // Try deletion after token refresh
            await widget.editpostref.delete();
            print('Post deleted successfully after token refresh');

            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dream deleted successfully'),
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                ),
              );
              return;
            }
          } catch (tokenError) {
            print(
                'Error refreshing token or second delete attempt: $tokenError');
          }
        }
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to delete dream. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PostsRecord>(
        stream: PostsRecord.getDocument(widget.editpostref),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final post = snapshot.data!;
          final postCreationTime = post.date;

          // Initialize timer if this is the first load and post date exists
          if (postCreationTime != null && _postCreationTime == null) {
            // Start the timer in the next frame to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startTimer(postCreationTime);
            });
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: 300,
                  ),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context)
                        .secondaryBackground
                        .withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dream Options',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 20,
                              ),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),

                      // Edit Button (only if within 15 minutes)
                      if (_isEditable)
                        Stack(
                          children: [
                            // Background progress indicator
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 16),
                              child: Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14.5),
                                  child: Stack(
                                    children: [
                                      // Progress fill
                                      FractionallySizedBox(
                                        widthFactor: _progressValue,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                FlutterFlowTheme.of(context)
                                                    .primary
                                                    .withOpacity(0.2),
                                                FlutterFlowTheme.of(context)
                                                    .primary
                                                    .withOpacity(0.05),
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

                            // Actual button - wrap in Positioned with alignment
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  splashColor: FlutterFlowTheme.of(context)
                                      .primary
                                      .withOpacity(0.3),
                                  highlightColor: FlutterFlowTheme.of(context)
                                      .primary
                                      .withOpacity(0.1),
                                  onTap: () {
                                    print(
                                        'Edit Dream button tapped - Post ID: ${widget.editpostref.id}');
                                    print(
                                        'Timer remaining: ${_formatRemainingTime(_remainingSeconds)}');

                                    // Close dialog
                                    Navigator.pop(context);

                                    // Navigate to edit page
                                    context.pushNamed(
                                      EditPageWidget.routeName,
                                      queryParameters: {
                                        'postPara': serializeParam(
                                          widget.editpostref,
                                          ParamType.DocumentReference,
                                        ),
                                      }.withoutNulls,
                                    );
                                  },
                                  child: Center(
                                    child: _buildOptionButton(
                                      context: context,
                                      icon: Icons.edit_outlined,
                                      text:
                                          'Edit Dream (${_formatRemainingTime(_remainingSeconds)})',
                                      bgColor: Colors.transparent,
                                      iconColor:
                                          FlutterFlowTheme.of(context).primary,
                                      onTap: () {}, // Handled by parent InkWell
                                      animationDelay: 100,
                                      noOuterPadding: true,
                                      addLeftPadding: true,
                                      disableInkWell:
                                          true, // Disable internal InkWell
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        // Show message that editing is no longer available - made more compact
                        Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.timer_off,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Editing Unavailable',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Figtree',
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Dreams can only be edited within 15 minutes',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'Figtree',
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                              duration: 300.ms,
                              delay: Duration(milliseconds: 100),
                              curve: Curves.easeOut,
                            )
                            .slideX(
                              begin: 0.2,
                              end: 0,
                              duration: 300.ms,
                              delay: Duration(milliseconds: 100),
                              curve: Curves.easeOut,
                            ),

                      // Delete Button - always available
                      _buildOptionButton(
                        context: context,
                        icon: Icons.delete_outline_rounded,
                        text: 'Delete Dream',
                        bgColor: Colors.red.withOpacity(0.1),
                        iconColor: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          _deletePost();
                        },
                        animationDelay: 200,
                      ),

                      // Share Dream Button (after Delete Button)
                      _buildOptionButton(
                        context: context,
                        icon: Icons.share_outlined,
                        text: 'Share Dream',
                        bgColor: Color(0xFF4B39EF).withOpacity(0.1),
                        iconColor: Color(0xFF4B39EF),
                        onTap: () {
                          // Don't pop here, let _sharePost handle it
                          _sharePost(context, post);
                        },
                        animationDelay: 250,
                      ),

                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fade(duration: 300.ms, curve: Curves.easeOut).scale(
                begin: Offset(0.9, 0.9),
                end: Offset(1, 1),
                duration: 300.ms,
                curve: Curves.easeOutBack,
              );
        });
  }

  // Helper function to format remaining time
  String _formatRemainingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
    required int animationDelay,
    bool noOuterPadding = false,
    bool addLeftPadding = false,
    bool disableInkWell = false,
  }) {
    Widget buttonContent = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: bgColor != Colors.transparent
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 0,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (addLeftPadding) SizedBox(width: 15),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Figtree',
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );

    // Apply animation to button content regardless of wrapper conditions
    Widget animatedContent = buttonContent
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: animationDelay),
          curve: Curves.easeOut,
        )
        .slideX(
          begin: 0.2,
          end: 0,
          duration: 300.ms,
          delay: Duration(milliseconds: animationDelay),
          curve: Curves.easeOut,
        );

    // Special case for no outer padding and disable inkwell - just return animated content
    if (noOuterPadding) {
      return animatedContent;
    }

    // Case with disableInkWell but with padding
    if (disableInkWell) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: animatedContent,
      );
    }

    // Default case - with InkWell and padding
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: buttonContent,
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: animationDelay),
          curve: Curves.easeOut,
        )
        .slideX(
          begin: 0.2,
          end: 0,
          duration: 300.ms,
          delay: Duration(milliseconds: animationDelay),
          curve: Curves.easeOut,
        );
  }

  // Add share post functionality
  void _sharePost(BuildContext context, PostsRecord post) {
    // Store the navigator context before popping
    final navigatorContext = Navigator.of(context).context;
    
    // Close the dialog first
    Navigator.pop(context);
    
    // Get the user record for the post using the navigator context
    UserRecord.getDocumentOnce(post.poster!).then((user) {
      if (user != null && navigatorContext.mounted) {
        // Use the stored navigator context which is still valid
        ShareOptionsDialog.show(navigatorContext, post, user);
      } else if (navigatorContext.mounted) {
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(
            content: Text('Cannot share: User information unavailable'),
            backgroundColor: FlutterFlowTheme.of(navigatorContext).error,
          ),
        );
      }
    });
  }
}
