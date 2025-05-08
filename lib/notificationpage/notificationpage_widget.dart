import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/utils/serialization_helpers.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'notificationpage_model.dart';
export 'notificationpage_model.dart';

class NotificationpageWidget extends StatefulWidget {
  const NotificationpageWidget({super.key});

  static String routeName = 'Notificationpage';
  static String routePath = '/notificationpage';

  @override
  State<NotificationpageWidget> createState() => _NotificationpageWidgetState();
}

class _NotificationpageWidgetState extends State<NotificationpageWidget>
    with SingleTickerProviderStateMixin {
  late NotificationpageModel _model;
  late TabController _tabController;
  String _selectedTab = 'All';

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NotificationpageModel());
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _getTabName(_tabController.index);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'All';
      case 1:
        return 'Likes';
      case 2:
        return 'Comments';
      case 3:
        return 'Follows';
      default:
        return 'All';
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildNotificationItem(NotificationsRecord notification) {
    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(notification.madeBy!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userRecord = snapshot.data!;
        final photoUrl = userRecord.photoUrl ?? '';
        final displayName = userRecord.displayName ?? '';
        final firstLetter = displayName.isNotEmpty ? displayName[0] : '?';

        return AnimatedOpacity(
          duration: Duration(milliseconds: 600),
          opacity: 1.0,
          child: InkWell(
            onTap: () async {
              if (notification.isFollowRequest) {
                // Navigate to user's profile
                context.pushNamed(
                  'Userpage',
                  queryParameters: {
                    'profileparameter': serializeParam(
                      notification.madeBy,
                      ParamType.DocumentReference,
                    ),
                  }.withoutNulls,
                );
              } else if (notification.postRef != null) {
                // Navigate to the post
                context.pushNamed(
                  'Detailedpost',
                  queryParameters: {
                    'docref': serializeParam(
                      notification.postRef,
                      ParamType.DocumentReference,
                    ),
                    'userref': serializeParam(
                      notification.madeBy,
                      ParamType.DocumentReference,
                    ),
                    'showComments': serializeParam(
                      !notification.isALike,
                      ParamType.bool,
                    ),
                  }.withoutNulls,
                );
              }
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: photoUrl.isEmpty
                          ? Container(
                              color: FlutterFlowTheme.of(context).primary,
                              child: Center(
                                child: Text(
                                  firstLetter.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Image.network(
                              photoUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: FlutterFlowTheme.of(context).primary,
                                  child: Center(
                                    child: Text(
                                      firstLetter.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            children: [
                              TextSpan(
                                text: displayName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                  text:
                                      ' ${_getNotificationText(notification)}'),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          notification.date != null
                              ? timeago.format(notification.date!)
                              : 'recently',
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                fontFamily: 'Figtree',
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (notification.isFollowRequest &&
                      notification.status == 'pending')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => _acceptFollowRequest(notification),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                FlutterFlowTheme.of(context).primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          child: Text('Accept'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getNotificationText(NotificationsRecord notification) {
    if (notification.isALike) {
      return 'liked your post';
    } else if (notification.isFollowRequest) {
      if (notification.status == 'pending') {
        return 'requested to follow you';
      } else if (notification.status == 'followed') {
        return 'started following you';
      } else {
        return 'requested to follow you';
      }
    } else {
      return 'commented on your post';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  fontFamily: 'Outfit',
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: FlutterFlowTheme.of(context).primaryText,
            size: 24.0,
          ),
          onPressed: () async {
            context.safePop();
          },
        ),
        title: Text(
          'Notifications',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Outfit',
                letterSpacing: 0.0,
              ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: FlutterFlowTheme.of(context).primary,
              unselectedLabelColor: FlutterFlowTheme.of(context).secondaryText,
              indicatorColor: FlutterFlowTheme.of(context).primary,
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Likes'),
                Tab(text: 'Comments'),
                Tab(text: 'Follows'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList('all'),
                _buildNotificationList('likes'),
                _buildNotificationList('comments'),
                _buildNotificationList('follows'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(String type) {
    print('Building notification list for type: $type');
    return StreamBuilder<List<NotificationsRecord>>(
      stream: queryNotificationsRecord(
        queryBuilder: (notificationsRecord) {
          // Use a more comprehensive query
          // This way we get all notifications and filter them client-side
          // to handle potential format differences in the ID
          print('Current user ID: ${currentUser?.uid}');
          final baseQuery =
              notificationsRecord.orderBy('date', descending: true);

          return baseQuery;
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in stream: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Get all notifications first
        final allNotifications = snapshot.data!;
        print('Retrieved ${allNotifications.length} total notifications');

        // Filter for current user, looking for exact or partial ID matches
        final currentUserID = currentUser?.uid ?? '';
        print('Filtering for current user ID: $currentUserID');

        final userNotifications = allNotifications.where((notification) {
          try {
            // Handle both string and DocumentReference types for made_to field
            String madeTo = '';
            if (notification.madeTo is String) {
              madeTo = notification.madeTo ?? '';
            } else if (notification.snapshotData['made_to']
                is DocumentReference) {
              // If made_to is a DocumentReference, get its ID
              final madeToRef =
                  notification.snapshotData['made_to'] as DocumentReference?;
              madeTo = madeToRef?.id ?? '';
            }

            final isMatch = madeTo == currentUserID ||
                (currentUserID.isNotEmpty && madeTo.contains(currentUserID)) ||
                (madeTo.isNotEmpty && currentUserID.contains(madeTo));
            print('Checking notification ${notification.reference.id}:');
            print('  - Made To: "$madeTo"');
            print('  - Current User ID: "$currentUserID"');
            print('  - Is Match: $isMatch');
            return isMatch;
          } catch (e) {
            print(
                'Error processing notification ${notification.reference.id}: $e');
            return false;
          }
        }).toList();

        print(
            'Found ${userNotifications.length} notifications for current user');

        // Filter notifications based on type
        List<NotificationsRecord> notifications = [];

        if (type == 'all') {
          notifications = userNotifications;
        } else if (type == 'likes') {
          notifications = userNotifications
              .where((notification) => notification.isALike)
              .toList();
        } else if (type == 'comments') {
          notifications = userNotifications
              .where((notification) =>
                  !notification.isALike && !notification.isFollowRequest)
              .toList();
        } else if (type == 'follows') {
          notifications = userNotifications
              .where((notification) =>
                  notification.isFollowRequest &&
                  (notification.status == 'pending' ||
                      notification.status == 'followed'))
              .toList();
        }

        print('Filtered notifications for "$type": ${notifications.length}');

        if (notifications.isEmpty) {
          print('No notifications after filtering');
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            print('Building notification item ${index + 1}');
            return _buildNotificationItem(notifications[index]);
          },
        );
      },
    );
  }

  Future<void> _acceptFollowRequest(NotificationsRecord notification) async {
    try {
      // Update the notification status
      await notification.reference.update({
        'status': 'approved',
      });

      // Add the user to the followers list
      if (notification.madeBy != null && currentUserReference != null) {
        await currentUserReference!.update({
          'users_following_me': FieldValue.arrayUnion([notification.madeBy]),
        });

        await notification.madeBy!.update({
          'following_users': FieldValue.arrayUnion([currentUserReference]),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Follow request accepted'),
          backgroundColor: FlutterFlowTheme.of(context).primary,
        ),
      );
    } catch (e) {
      print('Error accepting follow request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting follow request'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }
}
