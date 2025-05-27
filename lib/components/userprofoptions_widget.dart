import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/utils/serialization_helpers.dart';
import 'userprofoptions_model.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '/utils/deep_link_helper.dart';
import '/utils/ui_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
export 'userprofoptions_model.dart';

class UserprofoptionsWidget extends StatefulWidget {
  const UserprofoptionsWidget({
    super.key,
    required this.profpara,
  });

  final DocumentReference? profpara;

  @override
  State<UserprofoptionsWidget> createState() => _UserprofoptionsWidgetState();
}

class _UserprofoptionsWidgetState extends State<UserprofoptionsWidget> {
  late UserprofoptionsModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UserprofoptionsModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  Future<void> _blockUser(DocumentReference userRef) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final batch = FirebaseFirestore.instance.batch();

      // Update current user's document
      batch.update(currentUserReference!, {
        'blocked_users': FieldValue.arrayUnion([userRef]),
        'following_users': FieldValue.arrayRemove([userRef])
      });

      // Update blocked user's document
      batch.update(userRef, {
        'users_following_me': FieldValue.arrayRemove([currentUserReference])
      });

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User blocked successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error blocking user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error blocking user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // New function to unblock a user
  Future<void> _unblockUser(DocumentReference userRef) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Update current user's document to remove user from blocked list
      await currentUserReference!.update({
        'blocked_users': FieldValue.arrayRemove([userRef]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User unblocked successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error unblocking user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unblocking user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: StreamBuilder<UserRecord>(
        stream: UserRecord.getDocument(widget.profpara!),
        builder: (context, snapshot) {
          // Customize what your widget looks like when it's loading.
          if (!snapshot.hasData) {
            return Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            );
          }

          final containerUserRecord = snapshot.data!;

          return AnimatedContainer(
            duration: Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            width: 340.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24.0,
                  color: Colors.black.withOpacity(0.18),
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.18),
                        FlutterFlowTheme.of(context).primary.withOpacity(0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Options',
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            GestureDetector(
                              onTap: () => context.safePop(),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.close_rounded,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18),
                        // Block/Unblock/Report/Copy/Share options only
                        if (widget.profpara == currentUserReference)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                context.pushNamed(
                                  'blockedusers',
                                  queryParameters: {
                                    'userref': serializeParam(
                                      widget.profpara,
                                      ParamType.DocumentReference,
                                    ),
                                  }.withoutNulls,
                                );
                              },
                              child: _buildOptionRow(
                                context,
                                icon: Icons.person_remove_alt_1_rounded,
                                label: 'Show Blocked Users',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (widget.profpara == currentUserReference)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      containerUserRecord.isPrivate
                                          ? Icons.lock_outline
                                          : Icons.public,
                                      color: Colors.white,
                                      size: 24.0,
                                    ),
                                    SizedBox(width: 12.0),
                                    Text(
                                      'Private Account',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Figtree',
                                            color: Colors.white,
                                          ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: containerUserRecord.isPrivate,
                                  onChanged: (newValue) async {
                                    await currentUserReference!.update(
                                      createUserRecordData(
                                        isPrivate: newValue,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          newValue
                                              ? 'Your account is now private'
                                              : 'Your account is now public',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Figtree',
                                                color: Colors.white,
                                              ),
                                        ),
                                        duration: Duration(seconds: 2),
                                        backgroundColor:
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                      ),
                                    );
                                  },
                                  activeColor:
                                      FlutterFlowTheme.of(context).primary,
                                  activeTrackColor:
                                      FlutterFlowTheme.of(context).accent1,
                                  inactiveTrackColor:
                                      FlutterFlowTheme.of(context).alternate,
                                  inactiveThumbColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                ),
                              ],
                            ),
                          ),
                        if (widget.profpara != currentUserReference)
                          if ((currentUserDocument?.blockedUsers.toList() ?? [])
                                  .contains(containerUserRecord.reference) ==
                              false)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  await _blockUser(
                                      containerUserRecord.reference);
                                },
                                child: _buildOptionRow(
                                  context,
                                  icon: Icons.person_remove_rounded,
                                  label: 'Block User',
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                        if (widget.profpara != currentUserReference)
                          if ((currentUserDocument?.blockedUsers.toList() ?? [])
                                  .contains(containerUserRecord.reference) ==
                              true)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  await _unblockUser(
                                      containerUserRecord.reference);
                                },
                                child: _buildOptionRow(
                                  context,
                                  icon: Icons.person_remove_rounded,
                                  label: 'Unblock User',
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ),
                        if (widget.profpara != currentUserReference)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showReportUserDialog(containerUserRecord),
                              child: _buildOptionRow(
                                context,
                                icon: Icons.flag_rounded,
                                label: 'Report User',
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await _copyProfileLink(containerUserRecord);
                            },
                            child: _buildOptionRow(
                              context,
                              icon: Icons.content_copy_rounded,
                              label: 'Copy Profile Link',
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await _shareProfile(containerUserRecord);
                            },
                            child: _buildOptionRow(
                              context,
                              icon: Icons.share_rounded,
                              label: 'Share Profile',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Method to show a dialog for reporting a user
  Future<void> _showReportUserDialog(UserRecord user) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.flag_outlined,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Report User',
                      style: FlutterFlowTheme.of(context).titleLarge,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Why are you reporting this user?',
                  style: FlutterFlowTheme.of(context).bodyLarge,
                ),
                SizedBox(height: 16),
                _buildReportOption('Inappropriate content', user),
                _buildReportOption('Harassment or bullying', user),
                _buildReportOption('Spam', user),
                _buildReportOption('Impersonation', user),
                _buildReportOption('Other', user),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build a report option item
  Widget _buildReportOption(String reason, UserRecord user) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _submitUserReport(reason, user);
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: FlutterFlowTheme.of(context).primary,
            ),
            SizedBox(width: 12),
            Text(
              reason,
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // Method to handle the user report submission
  Future<void> _submitUserReport(String reason, UserRecord reportedUser) async {
    try {
      // First show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Submitting report...'),
            ],
          ),
          backgroundColor: FlutterFlowTheme.of(context).primary,
          duration: Duration(seconds: 1),
        ),
      );

      final currentUserDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(currentUserUid)
          .get();
      
      final currentUserEmail = currentUserDoc.data()?['email'] as String? ?? '';

      // Save report to Firestore
      await FirebaseFirestore.instance.collection('reports').add({
        'type': 'user',
        'reason': reason,
        'reported_user_id': reportedUser.reference.id,
        'reported_user_email': reportedUser.email,
        'reported_user_display_name': reportedUser.displayName,
        'reporter_id': currentUserUid,
        'reporter_email': currentUserEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'new',
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              ),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'User reported successfully. Thank you for helping improve our community.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error reporting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reporting user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOptionRow(BuildContext context,
      {required IconData icon, required String label, required Color color}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 14),
          Text(
            label,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Figtree',
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  // Method to generate a deep link for a user profile
  Future<String> _generateProfileDeepLink(UserRecord user) async {
    try {
      // Use the DeepLinkHelper to generate a deep link
      return DeepLinkHelper.generateUserProfileLink(user.reference);
    } catch (e) {
      print('Error generating profile link: $e');
      
      // Fallback to basic URL scheme if helper fails
      final userId = user.reference.id;
      return 'lunakraft://lunakraft.com/profile/$userId';
    }
  }

  // Method to copy the profile link to clipboard
  Future<void> _copyProfileLink(UserRecord user) async {
    final profileLink = await _generateProfileDeepLink(user);
    
    await Clipboard.setData(ClipboardData(text: profileLink));
    
    // Use the custom pill-shaped snackbar instead of the default Scaffold snackbar
    UIUtils.showPillSnackBar(
      context,
      message: 'Profile copied',
      icon: Icons.check_circle,
      backgroundColor: Color(0xFF6953CF), // Primary purple color
      duration: Duration(seconds: 2),
    );
    
    // Close the bottom sheet after copying
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Method to share the profile using share_plus
  Future<void> _shareProfile(UserRecord user) async {
    final displayName = user.displayName?.isEmpty == true || user.displayName == null
        ? 'a Luna Kraft user' 
        : user.displayName!;
    
    try {
      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Preparing to share...'),
            ],
          ),
          duration: Duration(seconds: 1),
          backgroundColor: FlutterFlowTheme.of(context).primary,
        ),
      );
      
      // Get shareable text with app and web URLs
      final shareText = DeepLinkHelper.generateShareableProfileLink(user.reference);
      
      // Use the Share.share method to bring up native sharing sheet
      await Share.share(
        shareText,
        subject: 'Luna Kraft - Check out this profile!',
      );
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
