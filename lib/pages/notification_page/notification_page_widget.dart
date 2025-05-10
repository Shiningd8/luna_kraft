import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp, dateTimeFormat;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart' hide createModel;
import '/utils/serialization_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'notification_page_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:luna_kraft/components/follow_status_popup.dart';
import '/flutter_flow/app_navigation_helper.dart';
import '/widgets/lottie_background.dart';
export 'notification_page_model.dart';

T createModel<T>(BuildContext context, T Function() model) => model();

class NotificationPageWidget extends StatefulWidget {
  const NotificationPageWidget({Key? key}) : super(key: key);

  @override
  _NotificationPageWidgetState createState() => _NotificationPageWidgetState();
}

class _NotificationPageWidgetState extends State<NotificationPageWidget>
    with SingleTickerProviderStateMixin {
  late NotificationPageModel _model;
  late TabController _tabController;
  String _selectedTab = 'All';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NotificationPageModel());
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _getTabName(_tabController.index);
      });
    });
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

  // Accept a follow request
  Future<void> _acceptFollowRequest(NotificationsRecord notification) async {
    try {
      // Check if we have the required references
      if (notification.madeBy == null) {
        print('Cannot accept follow request: madeBy is null');
        return;
      }

      // Check madeTo - it should be a String now based on our model changes
      final String? madeTo = notification.madeTo;
      if (madeTo == null || madeTo.isEmpty) {
        print('Cannot accept follow request: madeTo is null or empty');
        return;
      }

      // Verify that the notification is for the current user
      final currentUserId = currentUserReference?.id;
      if (currentUserId == null || !madeTo.contains(currentUserId)) {
        print('Cannot accept follow request: not for current user');
        return;
      }

      // Create a batch to perform multiple operations
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update the notification status
      batch.update(notification.reference, {
        'is_read': true,
        'status': 'approved',
      });

      // 2. Add the follower to the user's followers list
      // First, get the current user
      final currentUserDoc = await currentUserReference!.get();
      final currentUserRecord = UserRecord.fromSnapshot(currentUserDoc);

      // Then, add the follower to the followers list
      batch.update(currentUserReference!, {
        'users_following_me': FieldValue.arrayUnion([notification.madeBy]),
        'followers': FieldValue.arrayUnion([notification.madeBy]),
      });

      // 3. Add the user to the follower's following list
      // Get the follower user
      final followerDoc = await notification.madeBy!.get();
      if (followerDoc.exists) {
        batch.update(notification.madeBy!, {
          'following_users': FieldValue.arrayUnion([currentUserReference]),
          'following': FieldValue.arrayUnion([currentUserReference]),
        });
      }

      // 4. Remove the user from the pending requests list
      batch.update(currentUserReference!, {
        'pending_follow_requests':
            FieldValue.arrayRemove([notification.madeBy]),
      });

      // Commit all operations at once
      await batch.commit();

      // Show a success message
      FollowStatusPopup.showFollowStatusPopup(
        context,
        isFollowed: true,
        status: 'request_accepted',
      );
    } catch (e) {
      print('Error accepting follow request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting follow request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Deny a follow request
  Future<void> _denyFollowRequest(NotificationsRecord notification) async {
    try {
      // Check if we have the required references
      if (notification.madeBy == null) {
        print('Cannot deny follow request: madeBy is null');
        return;
      }

      // Check madeTo - it should be a String now based on our model changes
      final String? madeTo = notification.madeTo;
      if (madeTo == null || madeTo.isEmpty) {
        print('Cannot deny follow request: madeTo is null or empty');
        return;
      }

      // Verify that the notification is for the current user
      final currentUserId = currentUserReference?.id;
      if (currentUserId == null || !madeTo.contains(currentUserId)) {
        print('Cannot deny follow request: not for current user');
        return;
      }

      // Create a batch to perform multiple operations
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update the notification status
      batch.update(notification.reference, {
        'is_read': true,
        'status': 'declined',
      });

      // 2. Remove the user from the pending requests list
      if (currentUserReference != null) {
        batch.update(currentUserReference!, {
          'pending_follow_requests':
              FieldValue.arrayRemove([notification.madeBy]),
        });
      }

      // Commit all operations at once
      await batch.commit();

      // Show a success message
      FollowStatusPopup.showFollowStatusPopup(
        context,
        isFollowed: false,
        status: 'request_cancelled',
      );
    } catch (e) {
      print('Error denying follow request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error denying follow request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LottieBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Notifications',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Figtree',
                  color: Colors.white,
                  fontSize: 22,
                ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: FlutterFlowTheme.of(context).primary,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.6),
                  labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Figtree',
                        fontWeight: FontWeight.bold,
                      ),
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
        ),
      ),
    );
  }

  Widget _buildNotificationList(String type) {
    return StreamBuilder<List<NotificationsRecord>>(
      stream: queryNotificationsRecord(
        queryBuilder: (notificationsRecord) {
          // Just get all recent notifications and we'll filter for the current user
          return notificationsRecord.orderBy('date', descending: true).limit(
              100); // Increased limit to ensure we get all recent notifications
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in notifications stream: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error loading notifications',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Figtree',
                        color: Colors.white.withOpacity(0.7),
                      ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                FlutterFlowTheme.of(context).primary,
              ),
            ),
          );
        }

        // Get all notifications
        final allNotifications = snapshot.data!;

        // Filter notifications for current user
        final userNotifications = allNotifications.where((notification) {
          try {
            // Get the current user ID
            final currentUserID = currentUserReference?.id ?? '';
            if (currentUserID.isEmpty) return false;

            // Debug the notification
            print('Processing notification: ${notification.reference.id}');
            print('Raw made_to value: ${notification.snapshotData['made_to']}');
            print(
                'Runtime type: ${notification.snapshotData['made_to']?.runtimeType}');

            // Handle mixed types in madeTo field safely
            String? notificationMadeTo;

            // Get madeTo as String - check the schema's getter first
            notificationMadeTo = notification.madeTo;
            print('notification.madeTo getter result: $notificationMadeTo');

            // If that's null, try to extract from the raw data
            if (notificationMadeTo == null &&
                notification.snapshotData.containsKey('made_to')) {
              final rawMadeTo = notification.snapshotData['made_to'];
              print('Raw madeTo value: $rawMadeTo (${rawMadeTo?.runtimeType})');

              if (rawMadeTo is String) {
                notificationMadeTo = rawMadeTo;
              } else if (rawMadeTo is DocumentReference) {
                notificationMadeTo = rawMadeTo.id;
              } else if (rawMadeTo != null) {
                // Last resort fallback
                try {
                  notificationMadeTo = rawMadeTo.toString();
                } catch (e) {
                  print('Error converting madeTo to string: $e');
                }
              }
            }

            // Now compare the IDs
            if (notificationMadeTo != null) {
              // Compare directly or check if one contains the other
              final isMatch = notificationMadeTo == currentUserID ||
                  notificationMadeTo.contains(currentUserID) ||
                  currentUserID.contains(notificationMadeTo);
              print('Notification match result: $isMatch');
              return isMatch;
            }

            print('No madeTo value found, skipping notification');
            return false;
          } catch (e) {
            print('Error filtering notification: $e');
            print('Stack trace: ${StackTrace.current}');
            // Skip this notification if it can't be processed
            return false;
          }
        }).toList();

        // Filter notifications based on type
        List<NotificationsRecord> notifications = [];

        if (type == 'all') {
          notifications = userNotifications;
        } else if (type == 'likes') {
          notifications = userNotifications.where((notification) {
            // Handle all possible ways that isALike could be stored
            if (notification.isALike == true) return true;

            // Check in the raw snapshot data as fallback
            final rawValue = notification.snapshotData['is_a_like'];
            return rawValue == true || rawValue == "true" || rawValue == 1;
          }).toList();
        } else if (type == 'comments') {
          notifications = userNotifications.where((notification) {
            // Comments are notifications that are not likes and not follow requests
            final isLike = notification.isALike == true ||
                notification.snapshotData['is_a_like'] == true ||
                notification.snapshotData['is_a_like'] == "true" ||
                notification.snapshotData['is_a_like'] == 1;

            final isFollow = notification.isFollowRequest == true ||
                notification.snapshotData['is_follow_request'] == true ||
                notification.snapshotData['is_follow_request'] == "true" ||
                notification.snapshotData['is_follow_request'] == 1;

            return !isLike && !isFollow;
          }).toList();
        } else if (type == 'follows') {
          notifications = userNotifications.where((notification) {
            // Check for follow requests in all possible formats
            return notification.isFollowRequest == true ||
                notification.snapshotData['is_follow_request'] == true ||
                notification.snapshotData['is_follow_request'] == "true" ||
                notification.snapshotData['is_follow_request'] == 1;
          }).toList();
        }

        // Print debug information
        print('Total notifications found: ${userNotifications.length}');
        print(
            'Filtered notifications for tab "$type": ${notifications.length}');
        for (var i = 0; i < notifications.length && i < 5; i++) {
          print('Notification ${i + 1}: ${notifications[i].reference.id}');
          print('  - isLike: ${notifications[i].isALike}');
          print('  - isFollow: ${notifications[i].isFollowRequest}');
          print('  - madeBy: ${notifications[i].madeBy}');
          print('  - madeTo: ${notifications[i].madeTo}');
          print('  - date: ${notifications[i].date}');
        }

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            // Wait for the state to rebuild
            await Future.delayed(Duration(milliseconds: 500));
          },
          color: FlutterFlowTheme.of(context).primary,
          backgroundColor: Colors.white.withOpacity(0.1),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No notifications found for ${_selectedTab} tab',
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: 'Figtree',
                    color: Colors.white.withOpacity(0.7),
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'Current user ID: ${currentUserReference?.id ?? 'Not logged in'}',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Figtree',
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Show a diagnostic popup with debugging information
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Notification Diagnostics'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Current User ID: ${currentUserReference?.id ?? 'None'}'),
                        SizedBox(height: 8),
                        Text('Current Tab: $_selectedTab'),
                        SizedBox(height: 16),
                        FutureBuilder<QuerySnapshot>(
                          future: NotificationsRecord.collection.get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return CircularProgressIndicator();
                            }

                            final notifications = snapshot.data!.docs;
                            return Text(
                                'Total Notifications in DB: ${notifications.length}');
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                foregroundColor: Colors.white,
              ),
              child: Text('Diagnostics'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationsRecord notification, int index) {
    if (notification.snapshotData == null) {
      // Skip rendering if we don't have valid snapshot data
      return SizedBox.shrink();
    }

    // Check if we have a valid reference for the madeBy
    if (notification.madeBy == null) {
      return Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.madeByUsername.isEmpty
                                  ? 'Unknown User'
                                  : notification.madeByUsername,
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _getNotificationText(notification),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                            ),
                            if (notification.date != null) ...[
                              SizedBox(height: 4),
                              Text(
                                timeago.format(notification.date!),
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Figtree',
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fade(
            duration: 600.ms,
            delay: (index * 100).ms,
            curve: Curves.easeOut,
          );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: notification.madeBy?.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) {
          return SizedBox.shrink();
        }

        final photoUrl = userData['photo_url'] as String?;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                // Mark as read when tapped
                if (!notification.isRead) {
                  await notification.reference.update({
                    'is_read': true,
                  });
                }

                // Navigate based on notification type
                if (notification.isFollowRequest) {
                  if (notification.madeBy != null) {
                    try {
                      await context.pushNamed(
                        'Userpage',
                        queryParameters: {
                          'profileparameter': serializeParam(
                            notification.madeBy,
                            ParamType.DocumentReference,
                          ),
                        }.withoutNulls,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error opening user profile'),
                          backgroundColor: FlutterFlowTheme.of(context).error,
                        ),
                      );
                    }
                  }
                } else if (notification.postRef != null) {
                  // For likes and comments, verify post exists first
                  try {
                    final postSnapshot = await notification.postRef!.get();
                    if (postSnapshot.exists) {
                      // Check if post has a poster field and use that for navigation
                      final postData =
                          postSnapshot.data() as Map<String, dynamic>?;
                      if (postData != null && postData.containsKey('poster')) {
                        final posterRef =
                            postData['poster'] as DocumentReference?;

                        // Navigate to the post with the correct user reference (post owner)
                        AppNavigationHelper.navigateToDetailedPost(
                          context,
                          docref: serializeParam(
                            notification.postRef,
                            ParamType.DocumentReference,
                          ),
                          userref: serializeParam(
                            posterRef,
                            ParamType.DocumentReference,
                          ),
                          showComments: !notification.isALike,
                        );
                      } else {
                        // Fallback to basic navigation with notification's madeBy
                        AppNavigationHelper.navigateToDetailedPost(
                          context,
                          docref: serializeParam(
                            notification.postRef,
                            ParamType.DocumentReference,
                          ),
                          userref: null,
                          showComments: !notification.isALike,
                        );
                      }
                    } else {
                      // Post doesn't exist, show error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('This post is no longer available'),
                          backgroundColor: FlutterFlowTheme.of(context).error,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error opening post'),
                        backgroundColor: FlutterFlowTheme.of(context).error,
                      ),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User avatar
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          backgroundImage:
                              photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl) as ImageProvider
                                  : AssetImage('assets/images/avatar.png')
                                      as ImageProvider,
                        ),
                        SizedBox(width: 12),
                        // Notification content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.madeByUsername.isEmpty
                                    ? (userData['user_name'] as String? ??
                                        'Unknown User')
                                    : notification.madeByUsername,
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Figtree',
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _getNotificationText(notification),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Figtree',
                                      color: Colors.white.withOpacity(0.8),
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
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Unread indicator
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    // Follow request buttons
                    if (notification.isFollowRequest &&
                        (notification.status == 'pending' ||
                            notification.status == ''))
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => _denyFollowRequest(notification),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                    color: Colors.white.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Text('Decline'),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _acceptFollowRequest(notification),
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
                      ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fade(
              duration: 600.ms,
              delay: (index * 100).ms,
              curve: Curves.easeOut,
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
      } else if (notification.status == 'approved' ||
          notification.status == 'followed') {
        return 'started following you';
      } else {
        return 'requested to follow you';
      }
    } else {
      // Use the isReply field to determine the correct notification text
      if (notification.isReply) {
        return 'replied to your comment';
      } else {
        return 'commented on your post';
      }
    }
  }
}
