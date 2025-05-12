import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/utils/serialization_helpers.dart';
import 'package:flutter/material.dart';
import 'userprofoptions_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
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
                                  await _blockUser(
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
                            child: _buildOptionRow(
                              context,
                              icon: Icons.flag_rounded,
                              label: 'Report User',
                              color: Colors.redAccent,
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: _buildOptionRow(
                            context,
                            icon: Icons.content_copy_rounded,
                            label: 'Copy Profile Link',
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: _buildOptionRow(
                            context,
                            icon: Icons.share_rounded,
                            label: 'Share Profile',
                            color: Colors.white,
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
}
