import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp, dateTimeFormat;
import '/components/userprofoptions_widget.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui';
import 'userpage_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luna_kraft/components/follow_status_popup.dart';
import 'package:luna_kraft/components/standardized_post_item.dart';
import '/widgets/lottie_background.dart';
export 'userpage_model.dart';

class UserpageWidget extends StatefulWidget {
  const UserpageWidget({
    super.key,
    required this.profileparameter,
  });

  final DocumentReference? profileparameter;

  static String routeName = 'Userpage';
  static String routePath = '/userpage';

  @override
  State<UserpageWidget> createState() => _UserpageWidgetState();
}

class _UserpageWidgetState extends State<UserpageWidget> {
  late UserpageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  bool _justUnfollowed = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UserpageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String getProfileImageUrl(UserRecord user) {
    if ((user.photoUrl ?? '').isEmpty) {
      return 'https://ui-avatars.com/api/?name=${(user.displayName ?? '').isNotEmpty ? (user.displayName ?? '')[0] : "?"}&background=random';
    }
    return user.photoUrl ?? '';
  }

  bool hasRealProfileImage(UserRecord user) {
    final photoUrl = user.photoUrl ?? '';
    // Only consider it NOT a real image if it's empty or explicitly contains ui-avatars.com
    return photoUrl.isNotEmpty && !photoUrl.contains('ui-avatars.com');
  }

  Widget buildProfileImageView(BuildContext context, UserRecord user) {
    final photoUrl = getProfileImageUrl(user);
    final hasImage = hasRealProfileImage(user);

    if (hasImage) {
      return FlutterFlowExpandedImageView(
        image: Image.network(
          photoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialAvatar(user);
          },
        ),
        allowRotation: false,
        tag: valueOrDefault<String>(
          user.photoUrl,
          'default_profile_image',
        ),
        useHeroAnimation: true,
      );
    } else {
      return Material(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Hero(
                      tag: valueOrDefault<String>(
                        user.photoUrl,
                        'default_profile_image',
                      ),
                      child: Text(
                        (user.displayName ?? '').isNotEmpty
                            ? (user.displayName ?? '')[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 96,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildInitialAvatar(UserRecord user) {
    return Container(
      color: FlutterFlowTheme.of(context).primary,
      child: Center(
        child: Text(
          (user.displayName ?? '').isNotEmpty
              ? (user.displayName ?? '')[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 96,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profileparameter == null) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: FlutterFlowTheme.of(context).error,
              ),
              SizedBox(height: 16),
              Text(
                'Profile reference is missing',
                style: FlutterFlowTheme.of(context).titleMedium,
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () => context.safePop(),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(widget.profileparameter!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: FlutterFlowTheme.of(context).error,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: FlutterFlowTheme.of(context).titleMedium,
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.safePop(),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }

        final userpageUserRecord = snapshot.data!;
        if (userpageUserRecord == null) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 48,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'User not found',
                    style: FlutterFlowTheme.of(context).titleMedium,
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.safePop(),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return Material(
          color: Colors.transparent,
          child: Scaffold(
            key: scaffoldKey,
            extendBody: true,
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.transparent
                          : FlutterFlowTheme.of(context)
                              .primaryBackground
                              .withOpacity(0.4),
                      border: Border(
                        bottom: BorderSide(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              leading: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              actions: [
                Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () async {
                      await showModalBottomSheet(
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (context) {
                          return GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            child: Padding(
                              padding: MediaQuery.viewInsetsOf(context),
                              child: UserprofoptionsWidget(
                                profpara: widget.profileparameter,
                              ),
                            ),
                          );
                        },
                      ).then((value) => safeSetState(() {}));
                    },
                  ),
                ),
              ],
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
            ),
            body: LottieBackground(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add padding for app bar
                    SizedBox(height: MediaQuery.of(context).padding.top + 56),

                    // Profile Header Section with Instagram-like layout
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left side - Profile Picture
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context).primary,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        PageTransition(
                                          type: PageTransitionType.fade,
                                          child: buildProfileImageView(
                                              context, userpageUserRecord),
                                        ),
                                      );
                                    },
                                    child: Hero(
                                      tag: valueOrDefault<String>(
                                        userpageUserRecord.photoUrl,
                                        'default_profile_image',
                                      ),
                                      transitionOnUserGestures: true,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: Image.network(
                                          getProfileImageUrl(
                                              userpageUserRecord),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: 100,
                                              height: 100,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              child: Center(
                                                child: Text(
                                                  (userpageUserRecord
                                                                  .displayName ??
                                                              '')
                                                          .isNotEmpty
                                                      ? (userpageUserRecord
                                                                  .displayName ??
                                                              '')[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                                  .animate()
                                  .fade(duration: 600.ms, curve: Curves.easeOut)
                                  .slideX(
                                      begin: -0.1,
                                      end: 0,
                                      duration: 600.ms,
                                      curve: Curves.easeOut),
                              SizedBox(width: 20),
                              // Right side - Stats and info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User Info
                                    Text(
                                      userpageUserRecord.displayName ?? '',
                                      style: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .override(
                                            fontFamily: 'Outfit',
                                            fontWeight: FontWeight.bold,
                                          ),
                                    )
                                        .animate()
                                        .fade(
                                            duration: 600.ms,
                                            delay: 200.ms,
                                            curve: Curves.easeOut)
                                        .slideY(
                                            begin: -0.2,
                                            end: 0,
                                            duration: 600.ms,
                                            delay: 200.ms,
                                            curve: Curves.easeOut),
                                    SizedBox(height: 4),
                                    Text(
                                      '@${userpageUserRecord.userName}',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Figtree',
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                          ),
                                    )
                                        .animate()
                                        .fade(
                                            duration: 600.ms,
                                            delay: 400.ms,
                                            curve: Curves.easeOut)
                                        .slideY(
                                            begin: -0.2,
                                            end: 0,
                                            duration: 600.ms,
                                            delay: 400.ms,
                                            curve: Curves.easeOut),
                                    SizedBox(height: 16),
                                    // Stats Row
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground
                                            .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          // Dreams count
                                          FutureBuilder<int>(
                                            future: queryPostsRecordCount(
                                              queryBuilder: (postsRecord) =>
                                                  postsRecord.where(
                                                'poster',
                                                isEqualTo: userpageUserRecord
                                                    .reference,
                                              ),
                                            ),
                                            builder: (context, snapshot) {
                                              int count = snapshot.data ?? 0;
                                              return _buildStatColumn(
                                                context,
                                                count.toString(),
                                                'Dreams',
                                              );
                                            },
                                          ),
                                          // Followers count
                                          _buildStatColumn(
                                            context,
                                            userpageUserRecord
                                                .usersFollowingMe.length
                                                .toString(),
                                            'Followers',
                                          ),
                                          // Following count
                                          _buildStatColumn(
                                            context,
                                            userpageUserRecord
                                                .followingUsers.length
                                                .toString(),
                                            'Following',
                                          ),
                                        ],
                                      ),
                                    )
                                        .animate()
                                        .fade(
                                            duration: 600.ms,
                                            delay: 600.ms,
                                            curve: Curves.easeOut)
                                        .scale(
                                            begin: const Offset(0.95, 0.95),
                                            end: const Offset(1, 1),
                                            duration: 600.ms,
                                            delay: 600.ms,
                                            curve: Curves.easeOut),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fade(duration: 800.ms, curve: Curves.easeOut)
                        .slideY(
                            begin: 0.1,
                            end: 0,
                            duration: 800.ms,
                            curve: Curves.easeOut),

                    // Follow/Unfollow Button
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: AuthUserStreamWidget(
                        builder: (context) {
                          final isFollowing =
                              (currentUserDocument?.followingUsers.toList() ??
                                      [])
                                  .contains(userpageUserRecord.reference);

                          final isPendingRequest =
                              (userpageUserRecord.pendingFollowRequests ?? [])
                                      .contains(currentUserReference) ||
                                  ((userpageUserRecord
                                              .pendingFollowRequestsPaths ??
                                          [])
                                      .contains(currentUserReference?.path));

                          Widget button;
                          if (isFollowing) {
                            button = _buildGlassmorphicButton(
                              context,
                              'Unfollow',
                              Icons.person_remove,
                              () async {
                                setState(() {
                                  _isLoading = true;
                                  _justUnfollowed = true;
                                });
                                try {
                                  await userpageUserRecord.reference.update({
                                    ...mapToFirestore(
                                      {
                                        'users_following_me':
                                            FieldValue.arrayRemove(
                                                [currentUserReference]),
                                      },
                                    ),
                                  });

                                  await currentUserReference!.update({
                                    ...mapToFirestore(
                                      {
                                        'following_users':
                                            FieldValue.arrayRemove(
                                                [userpageUserRecord.reference]),
                                      },
                                    ),
                                  });

                                  if (mounted) {
                                    FollowStatusPopup.showFollowStatusPopup(
                                      context,
                                      isFollowed: false,
                                      status: 'unfollowed',
                                    );
                                  }
                                } catch (e) {
                                  print('Error unfollowing user: $e');
                                  if (mounted) {
                                    FollowStatusPopup.showFollowStatusPopup(
                                      context,
                                      isFollowed: false,
                                      status: 'unfollowed',
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                      _justUnfollowed = false;
                                    });
                                  }
                                }
                              },
                            );
                          } else if (isPendingRequest && !_justUnfollowed) {
                            button = _buildGlassmorphicButton(
                              context,
                              'Cancel Request',
                              Icons.cancel_outlined,
                              () async {
                                setState(() => _isLoading = true);
                                try {
                                  await userpageUserRecord.reference.update({
                                    ...mapToFirestore(
                                      {
                                        'pending_follow_requests':
                                            FieldValue.arrayRemove(
                                                [currentUserReference]),
                                      },
                                    ),
                                  });

                                  // Find and update any existing notifications
                                  final notifications = await FirebaseFirestore
                                      .instance
                                      .collection('notifications')
                                      .where('made_by',
                                          isEqualTo: currentUserReference)
                                      .where('made_to',
                                          isEqualTo:
                                              userpageUserRecord.reference.id)
                                      .where('is_follow_request',
                                          isEqualTo: true)
                                      .where('status', isEqualTo: 'pending')
                                      .get();

                                  // Update the notifications
                                  final batch =
                                      FirebaseFirestore.instance.batch();
                                  for (final doc in notifications.docs) {
                                    batch.update(
                                        doc.reference, {'status': 'cancelled'});
                                  }
                                  await batch.commit();

                                  if (mounted) {
                                    FollowStatusPopup.showFollowStatusPopup(
                                      context,
                                      isFollowed: false,
                                      status: 'request_cancelled',
                                    );
                                  }
                                } catch (e) {
                                  print('Error cancelling follow request: $e');
                                  if (mounted) {
                                    FollowStatusPopup.showFollowStatusPopup(
                                      context,
                                      isFollowed: false,
                                      status: 'request_cancelled',
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                            );
                          } else if (userpageUserRecord.isPrivate) {
                            button = _buildGlassmorphicButton(
                              context,
                              'Request to Follow',
                              Icons.person_add,
                              () async {
                                setState(() => _isLoading = true);
                                try {
                                  await userpageUserRecord.reference.update({
                                    ...mapToFirestore(
                                      {
                                        'pending_follow_requests':
                                            FieldValue.arrayUnion(
                                                [currentUserReference]),
                                      },
                                    ),
                                  });

                                  await NotificationsRecord.createNotification(
                                    isALike: false,
                                    isRead: false,
                                    madeBy: currentUserReference,
                                    madeTo: userpageUserRecord.reference?.id,
                                    date: getCurrentTimestamp,
                                    madeByUsername: currentUserDisplayName,
                                    isFollowRequest: true,
                                    status: 'pending',
                                  );

                                  if (mounted) {
                                    FollowStatusPopup.showFollowStatusPopup(
                                      context,
                                      isFollowed: true,
                                      status: 'request_sent',
                                    );
                                  }
                                } catch (e) {
                                  print('Error sending follow request: $e');
                                  if (mounted) {
                                    FollowStatusPopup.showFollowStatusPopup(
                                      context,
                                      isFollowed: true,
                                      status: 'request_sent',
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                            );
                          } else {
                            button = _buildGlassmorphicButton(
                              context,
                              'Follow',
                              Icons.person_add,
                              () async {
                                setState(() => _isLoading = true);
                                try {
                                  await userpageUserRecord.reference.update({
                                    ...mapToFirestore(
                                      {
                                        'users_following_me':
                                            FieldValue.arrayUnion(
                                                [currentUserReference]),
                                      },
                                    ),
                                  });

                                  await currentUserReference!.update({
                                    ...mapToFirestore(
                                      {
                                        'following_users':
                                            FieldValue.arrayUnion(
                                                [userpageUserRecord.reference]),
                                      },
                                    ),
                                  });

                                  await NotificationsRecord.createNotification(
                                    isALike: false,
                                    isRead: false,
                                    madeBy: currentUserReference,
                                    madeTo: userpageUserRecord.reference?.id,
                                    date: getCurrentTimestamp,
                                    madeByUsername: currentUserDisplayName,
                                    isFollowRequest: true,
                                    status: 'followed',
                                  );

                                  if (mounted) {
                                    FollowStatusPopup.showFollowStatusPopup(
                                      context,
                                      isFollowed: true,
                                      status: 'followed',
                                    );
                                  }
                                } catch (e) {
                                  print('Error following user: $e');
                                  if (mounted) {
                                    FollowStatusPopup.showFollowStatusPopup(
                                      context,
                                      isFollowed: true,
                                      status: 'followed',
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                            );
                          }
                          return button
                              .animate()
                              .fade(
                                  duration: 800.ms,
                                  delay: 400.ms,
                                  curve: Curves.easeOut)
                              .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 800.ms,
                                  delay: 400.ms,
                                  curve: Curves.easeOut);
                        },
                      ),
                    ),

                    // Posts Grid
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Heading with zero padding
                          Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.zero,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Dreams',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall,
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fade(
                                  duration: 800.ms,
                                  delay: 800.ms,
                                  curve: Curves.easeOut)
                              .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 800.ms,
                                  delay: 800.ms,
                                  curve: Curves.easeOut),

                          // Recent Dreams List with enhanced glassmorphism
                          StreamBuilder<List<PostsRecord>>(
                            stream: queryPostsRecord(
                              queryBuilder: (postsRecord) => postsRecord
                                  .where('poster',
                                      isEqualTo: widget.profileparameter)
                                  .orderBy('date', descending: true),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error loading posts'),
                                );
                              }

                              if (!snapshot.hasData) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final posts = snapshot.data!;

                              if (userpageUserRecord.isPrivate &&
                                  !(currentUserDocument?.followingUsers
                                          .contains(widget.profileparameter) ??
                                      false)) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 48,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'This account is private',
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Follow this user to see their posts',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (posts.isEmpty) {
                                return Center(
                                  child: Text('No posts yet'),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: posts.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final post = posts[index];
                                  return Container(
                                    margin: index == 0 ? EdgeInsets.zero : null,
                                    child: StreamBuilder<UserRecord>(
                                      stream:
                                          UserRecord.getDocument(post.poster!),
                                      builder: (context, userSnapshot) {
                                        if (!userSnapshot.hasData) {
                                          return Container(
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }

                                        final user = userSnapshot.data!;

                                        return StandardizedPostItem(
                                          post: post,
                                          user: user,
                                          animateEntry: true,
                                          animationIndex: index,
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(BuildContext context, String count, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Add any tap functionality here if needed
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Outfit',
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Figtree',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassmorphicButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context)
              .secondaryBackground
              .withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: FlutterFlowTheme.of(context).primary,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        text,
                        style: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Figtree',
                              color: FlutterFlowTheme.of(context).primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
