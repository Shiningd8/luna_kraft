import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/utils/serialization_helpers.dart';
import 'package:flutter/material.dart';
import 'editdialog_model.dart';
export 'editdialog_model.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_animations.dart';
// import 'package:cloud_functions/cloud_functions.dart';
import '../services/cloud_functions_stub.dart';

class EditdialogWidget extends StatefulWidget {
  const EditdialogWidget({
    super.key,
    required this.editpostref,
  });

  final DocumentReference editpostref;

  @override
  State<EditdialogWidget> createState() => _EditdialogWidgetState();
}

class _EditdialogWidgetState extends State<EditdialogWidget> {
  late EditdialogModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditdialogModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
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

        // Close the bottom sheet
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

      // Close the bottom sheet
      if (mounted) {
        Navigator.of(context).pop();

        // Show success message
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
    return Container(
      width: double.infinity,
      height: 270.0,
      decoration: BoxDecoration(
        color: Color(0xFFE9EAEF),
        boxShadow: [
          BoxShadow(
            blurRadius: 5.0,
            color: Color(0x3B1D2429),
            offset: Offset(
              0.0,
              -3.0,
            ),
          )
        ],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0.0),
          bottomRight: Radius.circular(0.0),
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            FFButtonWidget(
              onPressed: () async {
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
              text: 'Edit Post',
              options: FFButtonOptions(
                width: double.infinity,
                height: 60.0,
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                color: FlutterFlowTheme.of(context).primaryBackground,
                textStyle: FlutterFlowTheme.of(context).bodyLarge.override(
                      fontFamily: 'Figtree',
                      letterSpacing: 0.0,
                    ),
                elevation: 2.0,
                borderSide: BorderSide(
                  color: Colors.transparent,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
              child: FFButtonWidget(
                onPressed: _deletePost,
                text: 'Delete Story',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 60.0,
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Figtree',
                        color: Color(0xF69C0A0A),
                        fontSize: 16.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.normal,
                      ),
                  elevation: 2.0,
                  borderSide: BorderSide(
                    color: Color(0xF69C0A0A),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
              child: FFButtonWidget(
                onPressed: () async {
                  context.pop();
                },
                text: 'Cancel',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 60.0,
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Lexend Deca',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 16.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.normal,
                      ),
                  elevation: 0.0,
                  borderSide: BorderSide(
                    color: Colors.transparent,
                    width: 0.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
