import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp;
import '/components/emptylist_widget.dart';
import '/components/dream_calendar_dialog.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/utils/serialization_helpers.dart';
import '/utils/subscription_util.dart';
import '/index.dart';
import '/profile/edit_profile/edit_profile_widget.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:async';
import 'prof1_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:luna_kraft/components/animated_edit_dialog.dart';
import '/flutter_flow/app_navigation_helper.dart';
import '/services/app_state.dart';
import '/widgets/lottie_background.dart';
import '/services/comments_service.dart';
import '/components/share_options_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '/services/subscription_manager.dart';
import '/services/purchase_service.dart';
export 'prof1_model.dart';

class Prof1Widget extends StatefulWidget {
  const Prof1Widget({super.key});

  static String routeName = 'prof1';
  static String routePath = '/prof1';

  @override
  State<Prof1Widget> createState() => _Prof1WidgetState();
}

class _Prof1WidgetState extends State<Prof1Widget> {
  late Prof1Model _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isNavigating = false;
  Map<String, int> _cachedCounts = {};
  AppState? _appState;
  GoRouter? _goRouter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store AppState reference when dependencies change
    _appState = context.read<AppState>();
    // Store GoRouter reference when dependencies change
    _goRouter = GoRouter.of(context);
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Prof1Model());

    // Force refresh the current user data and clean up deleted user references
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentUserReference != null) {
        // First clean up any invalid user references
        _cleanupFollowerReferencesQuietly().then((_) {
          if (mounted) {
            // Then refresh the UI with the updated data
            setState(() {});
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose any controllers in the model
    _model.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation(DocumentReference userRef) async {
    if (_isNavigating) return;

    _isNavigating = true;

    try {
      // Close the dialog first if it's open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        await context.pushNamed(
          'Userpage',
          queryParameters: {
            'profileparameter': serializeParam(
              userRef,
              ParamType.DocumentReference,
            ),
          }.withoutNulls,
        );
      }
    } catch (e) {
      print('Navigation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  // Stream to get comment count for a specific post
  Stream<int> _getCommentCountStream(DocumentReference postRef) {
    return FirebaseFirestore.instance
        .collection('comments')
        .where('postref', isEqualTo: postRef)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        // Check if the comment is not deleted
        return data['deleted'] != true;
      }).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LottieBackground(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: AppBar(
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                elevation: 0,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).brightness == Brightness.light
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Profile',
                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                centerTitle: true,
                actions: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 12, 0),
                    child: FlutterFlowIconButton(
                      borderRadius: 8.0,
                      buttonSize: 40.0,
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 24.0,
                      ),
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: EdgeInsets.zero,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.85,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground
                                          .withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .primary
                                            .withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 20,
                                          spreadRadius: 5,
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
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary
                                                        .withOpacity(0.1),
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Options',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .override(
                                                          fontFamily: 'Outfit',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.close),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ListView(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          children: [
                                            if (currentUserReference != null)
                                              StreamBuilder<UserRecord>(
                                                stream: UserRecord.getDocument(
                                                    currentUserReference!),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData) {
                                                    return SizedBox.shrink();
                                                  }
                                                  final userDoc =
                                                      snapshot.data!;
                                                  return Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 12),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary
                                                              .withOpacity(0.1),
                                                        ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        StreamBuilder<
                                                            UserRecord>(
                                                          stream: UserRecord
                                                              .getDocument(
                                                                  currentUserReference!),
                                                          builder: (context,
                                                              privacySnapshot) {
                                                            if (!privacySnapshot
                                                                .hasData) {
                                                              return SizedBox
                                                                  .shrink();
                                                            }

                                                            final userRecord =
                                                                privacySnapshot
                                                                    .data!;
                                                            return Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                      userRecord.isPrivate
                                                                          ? Icons
                                                                              .lock_outline
                                                                          : Icons
                                                                              .public,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                      size:
                                                                          24.0,
                                                                    ),
                                                                    SizedBox(
                                                                        width:
                                                                            16),
                                                                    Text(
                                                                      'Private Account',
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            fontFamily:
                                                                                'Figtree',
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                Switch(
                                                                  value: userRecord
                                                                      .isPrivate,
                                                                  onChanged:
                                                                      (newValue) async {
                                                                    // Update the user's privacy setting
                                                                    await currentUserReference!
                                                                        .update(
                                                                      createUserRecordData(
                                                                        isPrivate:
                                                                            newValue,
                                                                      ),
                                                                    );

                                                                    // Show confirmation
                                                                    Navigator.pop(
                                                                        context);
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(
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
                                                                        duration:
                                                                            Duration(seconds: 2),
                                                                        backgroundColor:
                                                                            FlutterFlowTheme.of(context).primary,
                                                                      ),
                                                                    );
                                                                  },
                                                                  activeColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                  activeTrackColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .accent1,
                                                                  inactiveTrackColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .alternate,
                                                                  inactiveThumbColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                        SizedBox(height: 12),
                                                        _buildOptionItem(
                                                          'Edit Profile',
                                                          Icons.edit,
                                                          () => context.pushNamed(
                                                              EditProfileWidget
                                                                  .routeName),
                                                        ),
                                                        SizedBox(height: 12),
                                                        _buildOptionItem(
                                                          'Settings',
                                                          Icons.settings,
                                                          () =>
                                                              context.pushNamed(
                                                                  'Settings'),
                                                        ),
                                                        SizedBox(height: 12),
                                                        _buildOptionItem(
                                                          'Restore Purchases',
                                                          Icons.restore,
                                                          () async {
                                                            // Show loading indicator
                                                            showDialog(
                                                              context: context,
                                                              barrierDismissible: false,
                                                              builder: (BuildContext context) {
                                                                return AlertDialog(
                                                                  content: Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      CircularProgressIndicator(),
                                                                      SizedBox(height: 16),
                                                                      Text('Restoring purchases...'),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                            
                                                            try {
                                                              // Use PurchaseService to refresh
                                                              final result = await PurchaseService.refreshSubscriptionStatus();
                                                              
                                                              // Close loading dialog
                                                              if (Navigator.canPop(context)) {
                                                                Navigator.pop(context);
                                                              }
                                                              
                                                              // Show feedback to user
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    result 
                                                                      ? 'Purchases restored successfully!' 
                                                                      : 'No purchases found to restore'
                                                                  ),
                                                                  duration: Duration(seconds: 3),
                                                                ),
                                                              );
                                                              
                                                              // Refresh UI by forcing a rebuild
                                                              setState(() {});
                                                            } catch (e) {
                                                              // Close loading dialog on error
                                                              if (Navigator.canPop(context)) {
                                                                Navigator.pop(context);
                                                              }
                                                              
                                                              // Show error
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('Error restoring purchases: $e'),
                                                                  duration: Duration(seconds: 3),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                        SizedBox(height: 12),
                                                        _fixSignOutOption(),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
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
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 56,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context)
                        .secondaryBackground
                        .withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthUserStreamWidget(
                        builder: (context) => Container(
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
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.fade,
                                  child:
                                      _buildProfileImageExpandedView(context),
                                ),
                              );
                            },
                            child: Hero(
                              tag: currentUserDocument?.photoUrl ?? '',
                              transitionOnUserGestures: true,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  currentUserDocument?.photoUrl?.isEmpty == true
                                      ? 'https://ui-avatars.com/api/?name=${currentUserDisplayName.isNotEmpty ? currentUserDisplayName[0] : "U"}&background=random'
                                      : currentUserDocument?.photoUrl ?? '',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                        'Error loading profile image: $error');
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      child: Center(
                                        child: Text(
                                          currentUserDisplayName.isNotEmpty
                                              ? currentUserDisplayName[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                .info,
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
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AuthUserStreamWidget(
                              builder: (context) => Text(
                                currentUserDisplayName,
                                style: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .override(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            AuthUserStreamWidget(
                              builder: (context) => Text(
                                '@${valueOrDefault(currentUserDocument?.userName, '')}',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Figtree',
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                    ),
                              ),
                            ),
                            SizedBox(height: 16),
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
                                  StreamBuilder<List<PostsRecord>>(
                                    stream: queryPostsRecord(
                                      queryBuilder: (postsRecord) =>
                                          postsRecord.where(
                                        'poster',
                                        isEqualTo: currentUserReference,
                                      ),
                                    ),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return _buildStatColumn(
                                            '...', 'Dreams');
                                      }
                                      return _buildStatColumn(
                                          snapshot.data!.length.toString(),
                                          'Dreams');
                                    },
                                  ),
                                  AuthUserStreamWidget(
                                    builder: (context) => _buildStatColumn(
                                      (currentUserDocument
                                                  ?.usersFollowingMe.length ??
                                              0)
                                          .toString(),
                                      'Followers',
                                    ),
                                  ),
                                  AuthUserStreamWidget(
                                    builder: (context) => _buildStatColumn(
                                      (currentUserDocument
                                                  ?.followingUsers.length ??
                                              0)
                                          .toString(),
                                      'Following',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGlassmorphicButton(
                          'Dream Calendar',
                          Icons.calendar_month_outlined,
                          () => _showDreamCalendarDialog(context),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildGlassmorphicButton(
                          'Edit Profile',
                          Icons.edit_outlined,
                          () => context.pushNamed(EditProfileWidget.routeName),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: _buildGlassmorphicCard(
                    context,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dream Stats',
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        SizedBox(height: 12),
                        StreamBuilder<List<PostsRecord>>(
                          stream: queryPostsRecord(
                            queryBuilder: (postsRecord) => postsRecord.where(
                              'poster',
                              isEqualTo: currentUserReference,
                            ),
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final List<PostsRecord> posts = snapshot.data!;
                            final int dreamCount = posts.length;
                            final String weeklyAverage =
                                (dreamCount / 4).toStringAsFixed(1);

                            // Calculate dream streak based on post dates
                            String streakText = '0 days';
                            if (posts.isNotEmpty) {
                              // Sort posts by date (most recent first)
                              posts.sort((a, b) => b.date!.compareTo(a.date!));

                              // Check for consecutive days
                              int streak = 1;
                              DateTime? lastDate = posts[0].date;

                              // Initialize with today to handle today's posts
                              DateTime today = DateTime.now();
                              DateTime yesterday = DateTime(
                                  today.year, today.month, today.day - 1);

                              // If most recent post is not from today or yesterday, streak is broken
                              if (lastDate != null) {
                                DateTime lastPostDay = DateTime(lastDate.year,
                                    lastDate.month, lastDate.day);
                                DateTime todayDate = DateTime(
                                    today.year, today.month, today.day);

                                if (lastPostDay.isAfter(todayDate) ||
                                    todayDate.difference(lastPostDay).inDays >
                                        1) {
                                  streakText = '0 days';
                                } else {
                                  // Check for consecutive days
                                  DateTime currentDate = lastPostDay;
                                  streak = 1;

                                  // Group posts by date to handle multiple posts per day
                                  Map<String, bool> postedDates = {};

                                  for (var post in posts) {
                                    if (post.date != null) {
                                      final postDate = post.date!;
                                      final dateKey =
                                          '${postDate.year}-${postDate.month}-${postDate.day}';
                                      postedDates[dateKey] = true;
                                    }
                                  }

                                  // Check for continuous streak
                                  for (int i = 1; i <= 30; i++) {
                                    // Check up to last 30 days
                                    DateTime checkDate = DateTime(
                                        todayDate.year,
                                        todayDate.month,
                                        todayDate.day - i);

                                    final dateKey =
                                        '${checkDate.year}-${checkDate.month}-${checkDate.day}';

                                    if (postedDates.containsKey(dateKey)) {
                                      streak++;
                                    } else {
                                      break; // Streak is broken
                                    }
                                  }

                                  streakText = '$streak days';
                                }
                              }
                            }

                            return Column(
                              children: [
                                _buildStatRow(
                                    'Total Dreams', dreamCount.toString()),
                                Divider(height: 16),
                                _buildStatRow('Weekly Average', weeklyAverage),
                                Divider(height: 16),
                                _buildStatRow('Dream Streak', streakText),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          'Dream Analysis',
                          Icons.psychology,
                          () {
                            // Check if user has access to dream analysis
                            if (SubscriptionUtil.hasDreamAnalysis) {
                              context.pushNamed('DreamAnalysis');
                            } else {
                              // Redirect to membership page
                              context.pushNamed('MembershipPage');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Dream Analysis requires a premium subscription'),
                                  backgroundColor: FlutterFlowTheme.of(context).primary,
                                ),
                              );
                            }
                          },
                          FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickActionButton(
                          'Saved Dreams',
                          Icons.bookmark,
                          () => context.pushNamed('SavedPosts'),
                          FlutterFlowTheme.of(context).secondary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickActionButton(
                          'Collection',
                          Icons.collections,
                          () => _showBackgroundCollectionDialog(context),
                          FlutterFlowTheme.of(context).tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.zero,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Dreams',
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      StreamBuilder<List<PostsRecord>>(
                        stream: queryPostsRecord(
                          queryBuilder: (postsRecord) => postsRecord
                              .where('poster', isEqualTo: currentUserReference)
                              .orderBy('date', descending: true),
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          List<PostsRecord> posts = snapshot.data!;
                          if (posts.isEmpty) {
                            return EmptylistWidget();
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
                              // Show all posts for current user, including private ones
                              if (post.isPrivate &&
                                  post.poster != currentUserReference) {
                                return SizedBox.shrink();
                              }
                              return Container(
                                margin: index == 0 ? EdgeInsets.zero : null,
                                child: InkWell(
                                  onTap: () {
                                    AppNavigationHelper.navigateToDetailedPost(
                                      context,
                                      docref: serializeParam(
                                        post.reference,
                                        ParamType.DocumentReference,
                                      ),
                                      userref: serializeParam(
                                        post.poster,
                                        ParamType.DocumentReference,
                                      ),
                                    );
                                  },
                                  child: _buildEnhancedGlassmorphicCard(
                                    context,
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                post.title,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit_outlined),
                                              onPressed: () async {
                                                AnimatedEditDialog.show(
                                                  context,
                                                  post.reference,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          post.dream,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                // Like icon and count
                                                Icon(
                                                  Icons.favorite,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '${post.likes.length}',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium,
                                                ),
                                                SizedBox(width: 16),

                                                // Comment icon and count with StreamBuilder
                                                StreamBuilder<int>(
                                                  stream:
                                                      _getCommentCountStream(
                                                          post.reference),
                                                  builder: (context, snapshot) {
                                                    final commentCount =
                                                        snapshot.data ?? 0;
                                                    return InkWell(
                                                      onTap: () {
                                                        AppNavigationHelper
                                                            .navigateToDetailedPost(
                                                          context,
                                                          docref:
                                                              serializeParam(
                                                            post.reference,
                                                            ParamType
                                                                .DocumentReference,
                                                          ),
                                                          userref:
                                                              serializeParam(
                                                            post.poster,
                                                            ParamType
                                                                .DocumentReference,
                                                          ),
                                                          showComments: true,
                                                        );
                                                      },
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .mode_comment_outlined,
                                                            color: Colors.black,
                                                            size: 20,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            '$commentCount',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium,
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            Text(
                                              timeago.format(post.date!),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                                  .animate()
                                  .fade(
                                      duration: 600.ms,
                                      delay: (1100 + (index * 100)).ms,
                                      curve: Curves.easeOut)
                                  .slideY(
                                      begin: 0.2,
                                      end: 0,
                                      duration: 600.ms,
                                      delay: (1100 + (index * 100)).ms,
                                      curve: Curves.easeOut);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Developer Controls Section - Only visible in debug mode
                if (kDebugMode)
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16, 20, 16, 16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
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
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.developer_mode_rounded,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Developer Controls',
                                  style: FlutterFlowTheme.of(context).titleMedium.override(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Subscription Troubleshooting Tools',
                              style: FlutterFlowTheme.of(context).bodyMedium,
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await SubscriptionManager.instance.refreshSubscriptionStatus();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Subscription status refreshed'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.refresh),
                                    label: Text('Refresh Status'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FlutterFlowTheme.of(context).primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await SubscriptionManager.instance.applyMissingSubscriptionBenefits();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(result 
                                            ? 'Benefits applied successfully!' 
                                            : 'No subscription found or already applied'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.card_giftcard),
                                    label: Text('Apply Benefits'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FlutterFlowTheme.of(context).secondary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Testing mode button removed for release
                            SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                // Show loading dialog
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(width: 20),
                                          Text("Deep refreshing from RevenueCat...")
                                        ],
                                      ),
                                    );
                                  },
                                );
                                
                                // Use PurchaseService for deep refresh
                                try {
                                  final result = await PurchaseService.refreshSubscriptionStatus();
                                  
                                  // Close loading dialog
                                  Navigator.of(context, rootNavigator: true).pop();
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(result 
                                      ? 'Subscription refreshed from RevenueCat!' 
                                      : 'No active subscription found in RevenueCat'),
                                    duration: Duration(seconds: 4),
                                  ));
                                  
                                  setState(() {});
                                } catch (e) {
                                  // Close loading dialog on error
                                  Navigator.of(context, rootNavigator: true).pop();
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Error refreshing: ${e.toString()}'),
                                    duration: Duration(seconds: 4),
                                  ));
                                }
                              },
                              icon: Icon(Icons.sync_problem),
                              label: Text('Force RevenueCat Sync'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    // Only make followers and following clickable
    if (label == 'Dreams') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
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
      );
    }

    // For followers and following, use a direct stream from Firestore
    final refs = label == 'Followers'
        ? (currentUserDocument?.usersFollowingMe ?? [])
        : (currentUserDocument?.followingUsers ?? []);

    return InkWell(
      onTap: () {
        _showUsersListDialog(context, label, refs);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show static value initially (database stored count)
          Text(
            value,
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
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
    );
  }

  Future<void> _showUsersListDialog(
    BuildContext context,
    String title,
    List<DocumentReference> userRefs,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                // Header
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
                        title,
                        style:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Users List
                Flexible(
                  child: FutureBuilder<List<UserRecord>>(
                    future: _fetchExistingUsers(userRefs),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading users: ${snapshot.error}',
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final users = snapshot.data ?? [];

                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            'No $title yet',
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return InkWell(
                            onTap: () => _handleNavigation(user.reference),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  // Profile Picture
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      image: (user.photoUrl ?? '').isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                (user.photoUrl ?? '')
                                                        .contains('?')
                                                    ? user.photoUrl ?? ''
                                                    : (user.photoUrl ?? '') +
                                                        '?alt=media',
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: (user.photoUrl ?? '').isEmpty
                                        ? Center(
                                            child: Text(
                                              (user.displayName ?? '')
                                                      .isNotEmpty
                                                  ? (user.displayName ?? '')[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .info,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: 12),
                                  // User Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName ?? '',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Figtree',
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          '@${user.userName}',
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall
                                              .override(
                                                fontFamily: 'Figtree',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Follow Button
                                  StreamBuilder<UserRecord>(
                                    stream: UserRecord.getDocument(
                                        currentUserReference!),
                                    builder: (context, currentUserSnapshot) {
                                      if (!currentUserSnapshot.hasData) {
                                        return SizedBox.shrink();
                                      }

                                      final currentUser =
                                          currentUserSnapshot.data!;
                                      final isFollowing = currentUser
                                          .followingUsers
                                          .contains(user.reference);

                                      return TextButton(
                                        onPressed: () async {
                                          final followingUpdate = isFollowing
                                              ? FieldValue.arrayRemove(
                                                  [user.reference])
                                              : FieldValue.arrayUnion(
                                                  [user.reference]);
                                          final followersUpdate = isFollowing
                                              ? FieldValue.arrayRemove(
                                                  [currentUserReference])
                                              : FieldValue.arrayUnion(
                                                  [currentUserReference]);

                                          await currentUser.reference.update({
                                            'following_users': followingUpdate,
                                          });
                                          await user.reference.update({
                                            'users_following_me':
                                                followersUpdate,
                                          });

                                          // Create a notification for non-following
                                          if (!isFollowing) {
                                            await NotificationsRecord
                                                .createNotification(
                                              isALike: false,
                                              isFollowRequest: true,
                                              isRead: false,
                                              madeBy: currentUserReference,
                                              madeTo: user.reference?.id,
                                              date: getCurrentTimestamp,
                                              madeByUsername:
                                                  currentUser.userName ?? '',
                                            );
                                          }
                                        },
                                        child: Text(
                                          isFollowing ? 'Following' : 'Follow',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Figtree',
                                                color: isFollowing
                                                    ? FlutterFlowTheme.of(
                                                            context)
                                                        .primary
                                                    : Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .fade(
                                  duration: 400.ms,
                                  delay: (index * 50).ms,
                                  curve: Curves.easeOut)
                              .slideX(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 400.ms,
                                  delay: (index * 50).ms,
                                  curve: Curves.easeOut);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // New method to safely fetch users and filter out deleted users
  Future<List<UserRecord>> _fetchExistingUsers(
      List<DocumentReference> userRefs) async {
    if (userRefs.isEmpty) return [];

    List<UserRecord> results = [];

    for (var ref in userRefs) {
      try {
        // First check if document exists using direct Firestore reference
        final docSnapshot =
            await FirebaseFirestore.instance.doc(ref.path).get();

        if (docSnapshot.exists) {
          try {
            // Use the document data to create a user record manually
            final data = docSnapshot.data() as Map<String, dynamic>;
            if (data != null) {
              // Create user record only if we have valid data
              final user = UserRecord.fromSnapshot(docSnapshot);
              results.add(user);
            } else {
              print('User document ${ref.id} exists but has no data');
            }
          } catch (e) {
            print('Error parsing user ${ref.id}: $e');
          }
        } else {
          print('User document ${ref.id} does not exist');
        }
      } catch (e) {
        print('Error fetching user ${ref.id}: $e');
      }
    }

    return results;
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
        Text(
          value,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Figtree',
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildGlassmorphicButton(
      String text, IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 50,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
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
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Figtree',
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassmorphicCard(BuildContext context, Widget child) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildEnhancedGlassmorphicCard(BuildContext context, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context)
                .secondaryBackground
                .withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String text, IconData icon, VoidCallback onPressed, Color color) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              text,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Figtree',
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: FlutterFlowTheme.of(context).primary,
              size: 24,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Figtree',
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Spacer(),
            Icon(
              Icons.chevron_right,
              color: FlutterFlowTheme.of(context).secondaryText,
              size: 20,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fade(duration: 300.ms, curve: Curves.easeOut)
        .slideX(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, PostsRecord post) async {
    return showDialog(
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
                // Header
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 48,
                      )
                          .animate()
                          .scale(duration: 300.ms, curve: Curves.easeOut)
                          .fade(duration: 300.ms, curve: Curves.easeOut),
                      SizedBox(height: 16),
                      Text(
                        'Are you sure you want to delete this dream?',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              fontFamily: 'Figtree',
                              fontWeight: FontWeight.w500,
                            ),
                      )
                          .animate()
                          .fade(
                              duration: 300.ms,
                              delay: 200.ms,
                              curve: Curves.easeOut)
                          .slideY(
                              begin: 0.2,
                              end: 0,
                              duration: 300.ms,
                              delay: 200.ms,
                              curve: Curves.easeOut),
                    ],
                  ),
                ),
                // Buttons
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
                          onPressed: () => Navigator.pop(context),
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
                          onPressed: () async {
                            Navigator.pop(context);
                            try {
                              await post.reference.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Dream deleted successfully'),
                                  backgroundColor:
                                      FlutterFlowTheme.of(context).primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting dream: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
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
  }

  // Add a new method for cleaning up follower references
  Future<void> _cleanupFollowerReferences() async {
    try {
      if (currentUserReference == null) return;

      // Show a loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            width: 200,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context)
                  .primaryBackground
                  .withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Cleaning up followers...',
                  style: FlutterFlowTheme.of(context).bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      // Get current user data
      final userDoc = await UserRecord.getDocument(currentUserReference!).first;

      // Lists to store valid references
      List<DocumentReference> validFollowing = [];
      List<DocumentReference> validFollowers = [];

      // Check following users
      for (var followingRef in userDoc.followingUsers) {
        try {
          final followingUser =
              await UserRecord.getDocument(followingRef).first;
          // If we reach here, user exists
          validFollowing.add(followingRef);
        } catch (e) {
          print('Following user ${followingRef.id} no longer exists');
          // Reference to deleted user, we'll exclude it
        }
      }

      // Check followers
      for (var followerRef in userDoc.usersFollowingMe) {
        try {
          final followerUser = await UserRecord.getDocument(followerRef).first;
          // If we reach here, user exists
          validFollowers.add(followerRef);
        } catch (e) {
          print('Follower ${followerRef.id} no longer exists');
          // Reference to deleted user, we'll exclude it
        }
      }

      // Calculate removed counts
      int followingRemoved =
          userDoc.followingUsers.length - validFollowing.length;
      int followersRemoved =
          userDoc.usersFollowingMe.length - validFollowers.length;

      // Update user document with clean lists if needed
      if (followingRemoved > 0 || followersRemoved > 0) {
        await userDoc.reference.update({
          'following_users': validFollowing,
          'users_following_me': validFollowers,
        });
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show result dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Cleanup Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Removed $followingRemoved deleted users from your following list.'),
                SizedBox(height: 8),
                Text(
                    'Removed $followersRemoved deleted users from your followers list.'),
              ],
            ),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Refresh the page
                  setState(() {});
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error cleaning up follower references: $e');
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while cleaning up followers: $e'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  // A quiet version of cleanup that runs on page load without dialogs
  Future<void> _cleanupFollowerReferencesQuietly() async {
    try {
      if (currentUserReference == null) return;

      // Get current user data
      final userDoc = await UserRecord.getDocument(currentUserReference!).first;

      // Lists to store valid references
      List<DocumentReference> validFollowing = [];
      List<DocumentReference> validFollowers = [];

      // Check following users
      for (var followingRef in userDoc.followingUsers) {
        try {
          // Just check if document exists
          final docSnapshot =
              await FirebaseFirestore.instance.doc(followingRef.path).get();

          if (docSnapshot.exists) {
            validFollowing.add(followingRef);
          } else {
            print(
                'Following user ${followingRef.id} no longer exists - removing reference');
          }
        } catch (e) {
          print('Error checking following user ${followingRef.id}: $e');
        }
      }

      // Check followers
      for (var followerRef in userDoc.usersFollowingMe) {
        try {
          // Just check if document exists
          final docSnapshot =
              await FirebaseFirestore.instance.doc(followerRef.path).get();

          if (docSnapshot.exists) {
            validFollowers.add(followerRef);
          } else {
            print(
                'Follower ${followerRef.id} no longer exists - removing reference');
          }
        } catch (e) {
          print('Error checking follower ${followerRef.id}: $e');
        }
      }

      // Calculate removed counts
      int followingRemoved =
          userDoc.followingUsers.length - validFollowing.length;
      int followersRemoved =
          userDoc.usersFollowingMe.length - validFollowers.length;

      // Update user document with clean lists if needed
      if (followingRemoved > 0 || followersRemoved > 0) {
        print(
            'Cleaning up followers/following lists: removed $followersRemoved followers and $followingRemoved following');
        await userDoc.reference.update({
          'following_users': validFollowing,
          'users_following_me': validFollowers,
        });
      }
    } catch (e) {
      print('Error cleaning up follower references quietly: $e');
    }
  }

  // Helper method to build option items
  Widget _buildOptionItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: FlutterFlowTheme.of(context).primaryText,
                size: 24.0,
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Figtree',
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: FlutterFlowTheme.of(context).primaryText,
            size: 16.0,
          ),
        ],
      ),
    );
  }

  // Helper method for sign out option
  Widget _fixSignOutOption() {
    return InkWell(
      onTap: () async {
        // Confirm sign-out
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text('Sign Out'),
              content: Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Close dialog
                    Navigator.pop(dialogContext);

                    // Use the safe sign-out method
                    AuthUtil.signOutSafely();
                  },
                  child: Text('Sign Out'),
                ),
              ],
            );
          },
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.logout,
                color: FlutterFlowTheme.of(context).error,
                size: 24.0,
              ),
              SizedBox(width: 16),
              Text(
                'Sign Out',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Figtree',
                      color: FlutterFlowTheme.of(context).error,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: FlutterFlowTheme.of(context).error,
            size: 16.0,
          ),
        ],
      ),
    );
  }

  // Create a dialog to select background options
  void _showBackgroundCollectionDialog(BuildContext context) {
    // Get the AppState instance and force a refresh
    final appState = Provider.of<AppState>(context, listen: false);
    appState.forceReinitialize().then((_) {
      print('Showing dialog after reinitialization');

      // Now show the dialog
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext dialogContext) {
          return AuthUserStreamWidget(
            builder: (context) => Consumer<AppState>(
              builder: (context, appState, _) {
                // Get sorted background options (unlocked first)
                final sortedOptions = appState.sortedBackgroundOptions;

                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context)
                          .primaryBackground
                          .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            FlutterFlowTheme.of(context).primary.withOpacity(0.2),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
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
                                    'Background Collection',
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),

                            // User's Luna Coins
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 8
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                    ),
                                    child: Image.asset(
                                      'assets/images/lunacoin.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  AuthUserStreamWidget(
                                    builder: (context) => Text(
                                      '${_getLunaCoins()} LunaCoins',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Figtree',
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.light
                                                ? Colors.black
                                                : FlutterFlowTheme.of(context).warning,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Subscription Status
                            if (SubscriptionUtil.hasExclusiveThemes)
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: FlutterFlowTheme.of(context).primary,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Premium Subscriber - All Backgrounds Available!',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        fontFamily: 'Figtree',
                                        color: FlutterFlowTheme.of(context).primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Background Options
                            Flexible(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    children: sortedOptions
                                        .map<Widget>((bg) {
                                      final isSelected =
                                          appState.selectedBackground ==
                                              bg['file'];
                                      final isUnlocked = appState.isPremiumBackgroundAvailable(bg['file']!);
                                      final price = appState.getBackgroundPrice(bg['file']!);
                                      
                                      // For premium users, all backgrounds should be unlocked
                                      final canUse = isUnlocked;
                                      
                                      return Container(
                                        margin: EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? FlutterFlowTheme.of(context)
                                                  .primary
                                                  .withOpacity(0.1)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? FlutterFlowTheme.of(context)
                                                    .primary
                                                : FlutterFlowTheme.of(context)
                                                    .primary
                                                    .withOpacity(0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                if (canUse) {
                                                  // Set as active background if unlocked or premium
                                                  appState.setBackground(bg['file']!);
                                                  
                                                  // If premium user but not yet in their unlocked list, add it
                                                  if (SubscriptionUtil.hasExclusiveThemes) {
                                                    appState.unlockAllBackgroundsForPremium();
                                                  }
                                                } else {
                                                  // Show purchase dialog if locked
                                                  _showPurchaseDialog(
                                                    context, 
                                                    appState, 
                                                    bg['file']!, 
                                                    bg['name']!,
                                                    price
                                                  );
                                                }
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.all(12),
                                                child: Row(
                                                  children: [
                                                    // Preview
                                                    Stack(
                                                      children: [
                                                        Container(
                                                          width: 60,
                                                          height: 60,
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    8),
                                                            border: Border.all(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primary
                                                                  .withOpacity(0.3),
                                                              width: 1,
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors.black
                                                                    .withOpacity(0.1),
                                                                blurRadius: 4,
                                                                spreadRadius: 0,
                                                              ),
                                                            ],
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    8),
                                                            child: Stack(
                                                              children: [
                                                                Positioned.fill(
                                                                  child: Container(
                                                                    color: FlutterFlowTheme
                                                                            .of(context)
                                                                        .primaryBackground,
                                                                    child: Builder(
                                                                      builder:
                                                                          (context) {
                                                                        try {
                                                                          final bgFile =
                                                                              bg['file']!;
                                                                          final isImage = bgFile
                                                                                  .endsWith(
                                                                                      '.png') ||
                                                                              bgFile.endsWith(
                                                                                  '.jpg') ||
                                                                              bgFile.endsWith(
                                                                                  '.jpeg');

                                                                          if (isImage) {
                                                                            return Image
                                                                                .asset(
                                                                              'assets/images/$bgFile',
                                                                              fit: BoxFit
                                                                                  .cover,
                                                                              errorBuilder: (context,
                                                                                  error,
                                                                                  stackTrace) {
                                                                                return Center(
                                                                                  child: Icon(
                                                                                    Icons.image_not_supported,
                                                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                                                  ),
                                                                                );
                                                                              },
                                                                            );
                                                                          } else {
                                                                            return Lottie
                                                                                .asset(
                                                                              'assets/jsons/$bgFile',
                                                                              fit: BoxFit
                                                                                  .cover,
                                                                              animate:
                                                                                  true,
                                                                              repeat:
                                                                                  true,
                                                                              errorBuilder: (context,
                                                                                  error,
                                                                                  stackTrace) {
                                                                                return Center(
                                                                                  child:
                                                                                      Icon(
                                                                                        Icons.image_not_supported,
                                                                                        color: FlutterFlowTheme.of(context).secondaryText,
                                                                                      ),
                                                                                );
                                                                              },
                                                                            );
                                                                          }
                                                                        } catch (e) {
                                                                          return Center(
                                                                            child:
                                                                                Icon(
                                                                              Icons
                                                                                  .error_outline,
                                                                              color: FlutterFlowTheme.of(context)
                                                                                  .error,
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Lock overlay for locked backgrounds
                                                                if (!canUse)
                                                                  Positioned.fill(
                                                                    child: Container(
                                                                      color: Colors.black.withOpacity(0.5),
                                                                      child: Center(
                                                                        child: Icon(
                                                                          Icons.lock,
                                                                          color: Colors.white,
                                                                          size: 24,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(width: 16),

                                                    // Name and selection indicator
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            bg['name']!,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyLarge
                                                                .override(
                                                                  fontFamily:
                                                                      'Figtree',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                          if (isSelected)
                                                            Text(
                                                              'Currently Selected',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodySmall
                                                                  .override(
                                                                    fontFamily:
                                                                        'Figtree',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                  ),
                                                            )
                                                          else if (!isUnlocked && !SubscriptionUtil.hasExclusiveThemes)
                                                            Text(
                                                              '$price LunaCoins',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodySmall
                                                                  .override(
                                                                    fontFamily:
                                                                        'Figtree',
                                                                    color: Theme.of(context).brightness == Brightness.light
                                                                        ? Colors.black
                                                                        : FlutterFlowTheme.of(context).warning,
                                                                  ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),

                                                    // Selection indicator or unlock button
                                                    if (isSelected)
                                                      Icon(
                                                        Icons.check_circle,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                      )
                                                    else if (!canUse)
                                                      Icon(
                                                        Icons.lock,
                                                        color: FlutterFlowTheme.of(context).secondaryText,
                                                        size: 20,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    });
  }

  // Show purchase dialog for locked backgrounds
  void _showPurchaseDialog(BuildContext context, AppState appState, String backgroundFile, String backgroundName, int price) {
    // Quick double-check if it's already available to this user
    if (appState.isPremiumBackgroundAvailable(backgroundFile)) {
      // If it's already available, just set it and return
      appState.setBackground(backgroundFile);
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 350,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  'Unlock Background',
                  style: FlutterFlowTheme.of(context).titleLarge.override(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  backgroundName,
                  style: FlutterFlowTheme.of(context).titleMedium,
                ),
                SizedBox(height: 16),
                
                // Background preview
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Builder(
                      builder: (context) {
                        try {
                          final isImage = backgroundFile.endsWith('.png') ||
                              backgroundFile.endsWith('.jpg') ||
                              backgroundFile.endsWith('.jpeg');

                          if (isImage) {
                            return Image.asset(
                              'assets/images/$backgroundFile',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                  ),
                                );
                              },
                            );
                          } else {
                            return Lottie.asset(
                              'assets/jsons/$backgroundFile',
                              fit: BoxFit.cover,
                              animate: true,
                              repeat: true,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                  ),
                                );
                              },
                            );
                          }
                        } catch (e) {
                          return Center(
                            child: Icon(
                              Icons.error_outline,
                              color: FlutterFlowTheme.of(context).error,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 24),
                
                // Price and user balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Price',
                          style: FlutterFlowTheme.of(context).labelMedium,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                              ),
                              child: Image.asset(
                                'assets/images/lunacoin.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '$price',
                              style: FlutterFlowTheme.of(context).bodyLarge.override(
                                fontFamily: 'Figtree',
                                fontWeight: FontWeight.bold,
                                color: FlutterFlowTheme.of(context).warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(width: 40),
                    Column(
                      children: [
                        Text(
                          'Your Balance',
                          style: FlutterFlowTheme.of(context).labelMedium,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: FlutterFlowTheme.of(context).secondary,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            AuthUserStreamWidget(
                              builder: (context) {
                                final lunaCoins = _getLunaCoins();
                                return Text(
                                  '$lunaCoins',
                                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                                    fontFamily: 'Figtree',
                                    fontWeight: FontWeight.bold,
                                    color: lunaCoins >= price
                                      ? FlutterFlowTheme.of(context).secondary
                                      : FlutterFlowTheme.of(context).error,
                                  ),
                                );
                              }
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
                // Purchase button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FFButtonWidget(
                      onPressed: () => Navigator.pop(dialogContext),
                      text: 'Cancel',
                      options: FFButtonOptions(
                        width: 120,
                        height: 50,
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        textStyle: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'Figtree',
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                        elevation: 0,
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    AuthUserStreamWidget(
                      builder: (context) {
                        final lunaCoins = _getLunaCoins();
                        return FFButtonWidget(
                          onPressed: lunaCoins >= price
                            ? () async {
                                try {
                                  // Close purchase dialog
                                  Navigator.pop(dialogContext);
                                  
                                  // Unlock the background
                                  bool success = await appState.unlockBackground(backgroundFile);
                                  
                                  // Verify context is still mounted
                                  if (!context.mounted) return;
                                  
                                  if (success) {
                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Successfully unlocked $backgroundName background!',
                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                            fontFamily: 'Figtree',
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: FlutterFlowTheme.of(context).primary,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    
                                    // Use the synchronous check first to avoid async issues
                                    if (appState.isPremiumBackgroundAvailable(backgroundFile)) {
                                      // Apply the background (this is async but we've verified it's available)
                                      appState.setBackground(backgroundFile);
                                      
                                      // Refresh the dialog to show updated state
                                      Navigator.pop(context); // Close the entire collection dialog
                                      _showBackgroundCollectionDialog(context); // Reopen it
                                    }
                                  } else {
                                    // Show error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to unlock background. Please try again.',
                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                            fontFamily: 'Figtree',
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: FlutterFlowTheme.of(context).error,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('Error during background purchase: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('An error occurred. Please try again.'),
                                        backgroundColor: FlutterFlowTheme.of(context).error,
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                          text: 'Purchase',
                          options: FFButtonOptions(
                            width: 120,
                            height: 50,
                            color: lunaCoins >= price
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).alternate,
                            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Figtree',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            elevation: 3,
                            borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            disabledColor: FlutterFlowTheme.of(context).alternate,
                            disabledTextColor: FlutterFlowTheme.of(context).secondaryText,
                          ),
                        );
                      }
                    ),
                  ],
                ),
                
                // Information text
                AuthUserStreamWidget(
                  builder: (context) {
                    final lunaCoins = _getLunaCoins();
                    if (lunaCoins < price) {
                      return Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          'Not enough LunaCoins',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Figtree',
                            color: FlutterFlowTheme.of(context).error,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }
                ),
                
                // Premium suggestion
                if (!SubscriptionUtil.hasExclusiveThemes)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(dialogContext); // Close purchase dialog
                        Navigator.pop(context); // Close background dialog
                        context.pushNamed('MembershipPage'); // Go to membership page
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Access all backgrounds with Premium',
                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Figtree',
                                color: FlutterFlowTheme.of(context).primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                // Additional explanation for premium access
                if (!SubscriptionUtil.hasExclusiveThemes)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Figtree',
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 10,
                        ),
                        children: [
                          TextSpan(
                            text: 'Note: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: 'Premium gives temporary access to all themes. Purchased themes are yours forever.',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDreamCalendarDialog(BuildContext context) async {
    if (currentUserReference == null) return;

    try {
      // Fetch user's dreams using the stream
      final List<PostsRecord> dreams = await queryPostsRecord(
        queryBuilder: (postsRecord) => postsRecord
            .where('poster', isEqualTo: currentUserReference)
            .orderBy('date', descending: true),
      ).first;

      if (!mounted) return;

      // Show the dream calendar dialog
      return showDialog(
        context: context,
        builder: (dialogContext) {
          return DreamCalendarDialog(
            dreams: dreams,
            userReference: currentUserReference!,
          );
        },
      );
    } catch (e) {
      print('Error loading dreams for calendar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dreams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check if the user has a real profile image (not a generated avatar)
  bool _hasRealProfileImage() {
    final photoUrl = currentUserDocument?.photoUrl;
    // Only consider it NOT a real image if it's empty or explicitly contains ui-avatars.com
    return photoUrl != null &&
        photoUrl.isNotEmpty &&
        !photoUrl.contains('ui-avatars.com');
  }

  // Build the expanded profile image view
  Widget _buildProfileImageExpandedView(BuildContext context) {
    final hasRealImage = _hasRealProfileImage();
    final photoUrl = currentUserDocument?.photoUrl;

    if (hasRealImage) {
      // Real image - show photo view
      return FlutterFlowExpandedImageView(
        image: Image.network(
          photoUrl ?? '',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialAvatar();
          },
        ),
        allowRotation: false,
        tag: photoUrl ?? '',
        useHeroAnimation: true,
      );
    } else {
      // Fallback - create a styled avatar view
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
                      tag: photoUrl ?? '',
                      child: Text(
                        currentUserDisplayName.isNotEmpty
                            ? currentUserDisplayName[0].toUpperCase()
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

  // Helper method for creating the initial avatar
  Widget _buildInitialAvatar() {
    return Container(
      color: FlutterFlowTheme.of(context).primary,
      child: Center(
        child: Text(
          currentUserDisplayName.isNotEmpty
              ? currentUserDisplayName[0].toUpperCase()
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

  // Add a method to check if a theme is available based on subscription status
  bool _isThemeAvailable(String themeName) {
    // Premium users have access to all themes
    if (SubscriptionUtil.hasExclusiveThemes) {
      return true;
    }
    
    // Free themes list for non-premium users
    final freeThemes = [
      'default', 'basic', 'simple', 'minimalist'
      // Add other free theme names here
    ];
    
    return freeThemes.contains(themeName.toLowerCase());
  }
  
  // Show dialog when premium theme is selected by non-premium user
  void _showPremiumThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Premium Theme'),
        content: Text('This theme is only available with a premium subscription.'),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Get Premium'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, 'MembershipPage');
            },
          ),
        ],
      ),
    );
  }
  
  // Adjust the existing theme selection methods to use the subscription check
  Future<void> _selectTheme(String themeName) async {
    if (_isThemeAvailable(themeName)) {
      // Apply the theme (implement your existing theme change logic here)
      // Update the user's theme preference
      try {
        await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
          'themePreference': themeName,
        });
        
        Navigator.pop(context); // Close theme dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme updated successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Error updating theme: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update theme: $e'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      _showPremiumThemeDialog();
    }
  }
  
  // Add a widget to show subscription status in theme selection dialog
  Widget _buildSubscriptionStatus() {
    if (SubscriptionUtil.isPremium) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FlutterFlowTheme.of(context).primary.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: FlutterFlowTheme.of(context).primary,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Premium Subscriber',
              style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                color: FlutterFlowTheme.of(context).primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              color: Colors.grey,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Premium themes locked',
              style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                color: Colors.grey,
              ),
            ),
            SizedBox(width: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close theme dialog
                Navigator.pushNamed(context, 'MembershipPage');
              },
              child: Text('Upgrade'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: Size(0, 0),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Helper method to get luna_coins with proper field name
  int _getLunaCoins() {
    if (currentUserDocument == null) return 0;
    try {
      // Access the field directly using the property names as defined in UserRecord
      return currentUserDocument!.lunaCoins;
    } catch (e) {
      print('Error getting luna_coins: $e');
      return 0;
    }
  }
}
