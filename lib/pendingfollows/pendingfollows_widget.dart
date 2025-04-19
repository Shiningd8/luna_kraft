import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luna_kraft/components/follow_status_popup.dart';

class PendingfollowsWidget extends StatefulWidget {
  const PendingfollowsWidget({super.key});

  static String routeName = 'pendingfollows';
  static String routePath = '/pendingfollows';

  @override
  State<PendingfollowsWidget> createState() => _PendingfollowsWidgetState();
}

class _PendingfollowsWidgetState extends State<PendingfollowsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              context.safePop();
            },
            child: Icon(
              Icons.arrow_back,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 24.0,
            ),
          ),
          title: Text(
            'Follow Requests',
            style: FlutterFlowTheme.of(context).headlineLarge.override(
                  fontFamily: 'Outfit',
                  letterSpacing: 0.0,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: AuthUserStreamWidget(
                    builder: (context) {
                      // Get both reference-based and path-based requests
                      final pendingRefRequests = currentUserDocument
                              ?.pendingFollowRequests
                              ?.toList() ??
                          [];

                      // Convert path-based requests to DocumentReferences
                      final pendingPathRequests = (currentUserDocument
                                  ?.pendingFollowRequestsPaths
                                  ?.toList() ??
                              [])
                          .map((path) => FirebaseFirestore.instance.doc(path))
                          .toList();

                      // Combine both lists
                      final pendingRequests = [
                        ...pendingRefRequests,
                        ...pendingPathRequests
                      ];

                      // Remove duplicates
                      final uniqueRequests = pendingRequests.toSet().toList();

                      if (uniqueRequests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_add_disabled_outlined,
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                size: 60.0,
                              ),
                              SizedBox(height: 16.0),
                              Text(
                                'No pending follow requests',
                                style: FlutterFlowTheme.of(context).titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                'When someone requests to follow you,\nit will appear here.',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: uniqueRequests.length,
                        itemBuilder: (context, index) {
                          final requestUserRef = uniqueRequests[index];

                          return StreamBuilder<UserRecord>(
                            stream: UserRecord.getDocument(requestUserRef),
                            builder: (context, snapshot) {
                              // Customize what your widget looks like when it's loading.
                              if (!snapshot.hasData) {
                                return Container(
                                  height: 70,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                    ),
                                  ),
                                );
                              }

                              final requestUser = snapshot.data!;

                              // Also look up the notification for this request to update it later
                              return StreamBuilder<List<NotificationsRecord>>(
                                stream: queryNotificationsRecord(
                                  queryBuilder: (notificationsRecord) =>
                                      notificationsRecord
                                          .where('made_by',
                                              isEqualTo: requestUserRef)
                                          .where('made_to',
                                              isEqualTo: currentUserReference)
                                          .where('is_follow_request',
                                              isEqualTo: true)
                                          .where('status',
                                              isEqualTo: 'pending'),
                                  limit: 1,
                                ),
                                builder: (context, notifSnapshot) {
                                  final notifications =
                                      notifSnapshot.data ?? [];
                                  final notificationRecord =
                                      notifications.isNotEmpty
                                          ? notifications.first
                                          : null;

                                  return Card(
                                    margin: EdgeInsets.only(bottom: 12.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          // User Avatar
                                          Container(
                                            width: 50.0,
                                            height: 50.0,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                            ),
                                            child: Image.network(
                                              requestUser.photoUrl?.isEmpty ==
                                                      true
                                                  ? 'https://ui-avatars.com/api/?name=${requestUser.displayName?.isNotEmpty == true ? requestUser.displayName![0] : "U"}&background=random'
                                                  : requestUser.photoUrl ?? '',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Image.network(
                                                'https://ui-avatars.com/api/?name=${requestUser.displayName?.isNotEmpty == true ? requestUser.displayName![0] : "U"}&background=random',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12.0),

                                          // User Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  requestUser.displayName ?? '',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .titleMedium,
                                                ),
                                                Text(
                                                  '@${requestUser.userName ?? ''}',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Action Buttons
                                          Row(
                                            children: [
                                              TextButton(
                                                onPressed: () async {
                                                  try {
                                                    // Update notification if it exists
                                                    if (notificationRecord !=
                                                        null) {
                                                      await notificationRecord
                                                          .reference
                                                          .update(
                                                        createNotificationsRecordData(
                                                          isRead: true,
                                                          status: 'declined',
                                                        ),
                                                      );
                                                    }

                                                    if (currentUserReference !=
                                                        null) {
                                                      // Get current pending requests and remove the request user
                                                      final userDoc =
                                                          await FirebaseFirestore
                                                              .instance
                                                              .doc(
                                                                  currentUserReference!
                                                                      .path)
                                                              .get();

                                                      List<dynamic>
                                                          pendingRequests =
                                                          (userDoc.data()?[
                                                                      'pending_follow_requests'] ??
                                                                  [])
                                                              .where((ref) =>
                                                                  ref.path !=
                                                                  requestUserRef
                                                                      .path)
                                                              .toList();

                                                      // Update the document with filtered list
                                                      await currentUserReference!
                                                          .update({
                                                        'pending_follow_requests':
                                                            pendingRequests,
                                                      });

                                                      FollowStatusPopup
                                                          .showFollowStatusPopup(
                                                        context,
                                                        isFollowed: false,
                                                      );
                                                    }
                                                  } catch (e) {
                                                    print(
                                                        'Error declining follow request: $e');
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Error declining request: $e'),
                                                        backgroundColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .error,
                                                      ),
                                                    );
                                                  }

                                                  setState(() {});
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .error,
                                                ),
                                                child: Text('Decline'),
                                              ),
                                              SizedBox(width: 8.0),
                                              FFButtonWidget(
                                                onPressed: () async {
                                                  try {
                                                    // Update notification if it exists
                                                    if (notificationRecord !=
                                                        null) {
                                                      await notificationRecord
                                                          .reference
                                                          .update(
                                                        createNotificationsRecordData(
                                                          isRead: true,
                                                          status: 'approved',
                                                        ),
                                                      );
                                                    }

                                                    // First, remove from pending requests
                                                    if (currentUserReference !=
                                                        null) {
                                                      final userDoc =
                                                          await FirebaseFirestore
                                                              .instance
                                                              .doc(
                                                                  currentUserReference!
                                                                      .path)
                                                              .get();

                                                      // Get current pending requests
                                                      List<dynamic>
                                                          pendingRequests =
                                                          userDoc.data()?[
                                                                  'pending_follow_requests'] ??
                                                              [];

                                                      // Filter out the request user
                                                      pendingRequests =
                                                          pendingRequests
                                                              .where((ref) =>
                                                                  ref.path !=
                                                                  requestUserRef
                                                                      .path)
                                                              .toList();

                                                      // Update the document with filtered list
                                                      await currentUserReference!
                                                          .update({
                                                        'pending_follow_requests':
                                                            pendingRequests,
                                                      });

                                                      // Now add to users_following_me
                                                      await currentUserReference!
                                                          .update({
                                                        'users_following_me':
                                                            FieldValue
                                                                .arrayUnion([
                                                          requestUserRef
                                                        ]),
                                                      });

                                                      // Add current user to requestUser's following_users
                                                      await requestUserRef
                                                          .update({
                                                        'following_users':
                                                            FieldValue
                                                                .arrayUnion([
                                                          currentUserReference
                                                        ]),
                                                      });

                                                      FollowStatusPopup
                                                          .showFollowStatusPopup(
                                                        context,
                                                        isFollowed: true,
                                                      );
                                                    }
                                                  } catch (e) {
                                                    print(
                                                        'Error accepting follow request: $e');
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Error accepting request: $e'),
                                                        backgroundColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .error,
                                                      ),
                                                    );
                                                  }

                                                  setState(() {});
                                                },
                                                text: 'Accept',
                                                options: FFButtonOptions(
                                                  width: 80,
                                                  height: 36,
                                                  padding: EdgeInsets.zero,
                                                  iconPadding: EdgeInsets.zero,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  textStyle: FlutterFlowTheme
                                                          .of(context)
                                                      .titleSmall
                                                      .override(
                                                        fontFamily: 'Figtree',
                                                        color: Colors.white,
                                                      ),
                                                  elevation: 2,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
