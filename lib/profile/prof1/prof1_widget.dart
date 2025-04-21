import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp;
import '/components/editdialog_widget.dart';
import '/components/emptylist_widget.dart';
import '/components/userprofoptions_widget.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/backend/firebase_storage/storage.dart';
import '/profile/edit_profile/edit_profile_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui';
import 'prof1_model.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '/pendingfollows/pendingfollows_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:luna_kraft/components/standardized_post_item.dart';
import 'package:luna_kraft/components/editdialog_widget.dart';
import 'package:luna_kraft/components/animated_edit_dialog.dart';
import '/flutter_flow/app_navigation_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/app_state.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '/widgets/lottie_background.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context)
                    .primaryBackground
                    .withOpacity(0.4),
                border: Border(
                  bottom: BorderSide(
                    color:
                        FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: GradientText(
          'Profile',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
            fontFamily: 'Outfit',
            color: FlutterFlowTheme.of(context).primaryText,
            fontSize: 22,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          colors: [
            FlutterFlowTheme.of(context).primary,
            FlutterFlowTheme.of(context).secondary
          ],
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
                color: FlutterFlowTheme.of(context).primaryText,
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
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
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
                                        color: FlutterFlowTheme.of(context)
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
                                          final userDoc = snapshot.data!;
                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary
                                                      .withOpacity(0.1),
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                StreamBuilder<UserRecord>(
                                                  stream: UserRecord.getDocument(
                                                      currentUserReference!),
                                                  builder: (context,
                                                      privacySnapshot) {
                                                    if (!privacySnapshot
                                                        .hasData) {
                                                      return SizedBox.shrink();
                                                    }

                                                    final userRecord =
                                                        privacySnapshot.data!;
                                                    return Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              userRecord
                                                                      .isPrivate
                                                                  ? Icons
                                                                      .lock_outline
                                                                  : Icons
                                                                      .public,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primaryText,
                                                              size: 24.0,
                                                            ),
                                                            SizedBox(width: 16),
                                                            Text(
                                                              'Private Account',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'Figtree',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
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
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  newValue
                                                                      ? 'Your account is now private'
                                                                      : 'Your account is now public',
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        fontFamily:
                                                                            'Figtree',
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                ),
                                                                duration:
                                                                    Duration(
                                                                        seconds:
                                                                            2),
                                                                backgroundColor:
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
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
                                                  () => context
                                                      .pushNamed('Settings'),
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
      body: LottieBackground(
        child: Stack(
          children: [
            // Content with a slight overlay to make content readable
            SingleChildScrollView(
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
                        // Left side - Profile Picture
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
                                    child: FlutterFlowExpandedImageView(
                                      image: Image.network(
                                        currentUserDocument
                                                    ?.photoUrl?.isEmpty ==
                                                true
                                            ? 'https://ui-avatars.com/api/?name=${currentUserDisplayName.isNotEmpty ? currentUserDisplayName[0] : "U"}&background=random'
                                            : currentUserDocument?.photoUrl
                                                        ?.contains(
                                                            'firebasestorage.googleapis.com') ==
                                                    true
                                                ? 'https://ui-avatars.com/api/?name=${currentUserDisplayName.isNotEmpty ? currentUserDisplayName[0] : "U"}&background=random'
                                                : currentUserDocument
                                                        ?.photoUrl ??
                                                    '',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          print(
                                              'Error loading profile image: $error');
                                          return Container(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            child: Center(
                                              child: Text(
                                                currentUserDisplayName
                                                        .isNotEmpty
                                                    ? currentUserDisplayName[0]
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
                                      allowRotation: false,
                                      tag: currentUserDocument?.photoUrl ?? '',
                                      useHeroAnimation: true,
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: currentUserDocument?.photoUrl ?? '',
                                transitionOnUserGestures: true,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(
                                    currentUserDocument?.photoUrl?.isEmpty ==
                                            true
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
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        child: Center(
                                          child: Text(
                                            currentUserDisplayName.isNotEmpty
                                                ? currentUserDisplayName[0]
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
                  )
                      .animate()
                      .fade(duration: 800.ms, curve: Curves.easeOut)
                      .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 800.ms,
                          curve: Curves.easeOut),

                  // Glassmorphic Action buttons
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildGlassmorphicButton(
                            'Share Dream',
                            Icons.add_circle_outline,
                            () => context.pushNamed('DreamEntrySelection'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildGlassmorphicButton(
                            'Edit Profile',
                            Icons.edit_outlined,
                            () =>
                                context.pushNamed(EditProfileWidget.routeName),
                          ),
                        ),
                      ],
                    ),
                  )
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
                          curve: Curves.easeOut),

                  // Dream Stats Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: _buildGlassmorphicCard(
                      context,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dream Stats',
                            style: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
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
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              final List<PostsRecord> posts = snapshot.data!;
                              final int dreamCount = posts.length;
                              final String weeklyAverage =
                                  (dreamCount / 4).toStringAsFixed(1);

                              // Calculate dream streak based on post dates
                              String streakText = '0 days';
                              if (posts.isNotEmpty) {
                                // Sort posts by date (most recent first)
                                posts
                                    .sort((a, b) => b.date!.compareTo(a.date!));

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
                                  _buildStatRow(
                                      'Weekly Average', weeklyAverage),
                                  Divider(height: 16),
                                  _buildStatRow('Dream Streak', streakText),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fade(
                          duration: 800.ms,
                          delay: 600.ms,
                          curve: Curves.easeOut)
                      .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 800.ms,
                          delay: 600.ms,
                          curve: Curves.easeOut),

                  // Quick Actions
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            'Dream Analysis',
                            Icons.psychology,
                            () => context.pushNamed('DreamAnalysis'),
                            FlutterFlowTheme.of(context).primary,
                          )
                              .animate()
                              .fade(
                                  duration: 600.ms,
                                  delay: 800.ms,
                                  curve: Curves.easeOut)
                              .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 600.ms,
                                  delay: 800.ms,
                                  curve: Curves.easeOut),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickActionButton(
                            'Saved Dreams',
                            Icons.bookmark,
                            () => context.pushNamed('SavedPosts'),
                            FlutterFlowTheme.of(context).secondary,
                          )
                              .animate()
                              .fade(
                                  duration: 600.ms,
                                  delay: 900.ms,
                                  curve: Curves.easeOut)
                              .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 600.ms,
                                  delay: 900.ms,
                                  curve: Curves.easeOut),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickActionButton(
                            'Collection',
                            Icons.collections,
                            () => _showBackgroundCollectionDialog(context),
                            FlutterFlowTheme.of(context).tertiary,
                          )
                              .animate()
                              .fade(
                                  duration: 600.ms,
                                  delay: 1000.ms,
                                  curve: Curves.easeOut)
                              .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 600.ms,
                                  delay: 1000.ms,
                                  curve: Curves.easeOut),
                        ),
                      ],
                    ),
                  ),

                  // Recent Dreams Heading and List combined in a single container
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Heading with zero padding
                        Container(
                          margin: EdgeInsets.only(bottom: 2),
                          padding: EdgeInsets.zero,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Dreams',
                                style:
                                    FlutterFlowTheme.of(context).headlineSmall,
                              ),
                            ],
                          ),
                        ),

                        // Recent Dreams List with enhanced glassmorphism
                        StreamBuilder<List<PostsRecord>>(
                          stream: queryPostsRecord(
                            queryBuilder: (postsRecord) => postsRecord
                                .where('poster',
                                    isEqualTo: currentUserReference)
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
                                      AppNavigationHelper
                                          .navigateToDetailedPost(
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
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .titleMedium,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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

                                                  // Comment icon and count
                                                  StreamBuilder<
                                                      List<CommentsRecord>>(
                                                    stream: queryCommentsRecord(
                                                      queryBuilder:
                                                          (commentsRecord) =>
                                                              commentsRecord
                                                                  .where(
                                                        'postref',
                                                        isEqualTo:
                                                            post.reference,
                                                      ),
                                                    ),
                                                    builder:
                                                        (context, snapshot) {
                                                      final commentCount =
                                                          snapshot.data
                                                                  ?.length ??
                                                              0;
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
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondary,
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
                  )
                      .animate()
                      .fade(
                          duration: 800.ms,
                          delay: 1100.ms,
                          curve: Curves.easeOut)
                      .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 800.ms,
                          delay: 1100.ms,
                          curve: Curves.easeOut),

                  // Add bottom padding for scrolling
                  SizedBox(height: 80),
                ],
              ),
            ),
          ],
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
                                                color: Colors.white,
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

  // Helper method to build option items for the menu
  Widget _buildOptionItem(String label, IconData icon, VoidCallback onTap,
      {Color? optionColor}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: optionColor ?? FlutterFlowTheme.of(context).primaryText,
              size: 24,
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Figtree',
                    color:
                        optionColor ?? FlutterFlowTheme.of(context).primaryText,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Create a super simple sign out approach
  Widget _fixSignOutOption() {
    return _buildOptionItem(
      'Sign Out',
      Icons.logout,
      () {
        // Store navigator and context references before async operations
        final navigatorContext = context;

        // Close the menu
        Navigator.pop(context);

        // Show a confirmation dialog
        showDialog(
          context: navigatorContext,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (BuildContext dialogContext) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.5 + (0.5 * value),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context)
                          .primaryBackground
                          .withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                size: 50,
                                color: FlutterFlowTheme.of(context)
                                    .error
                                    .withOpacity(0.8),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Sign Out',
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Are you sure you want to sign out?',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor:
                                            FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        elevation: 0,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          side: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText
                                                .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Text('Cancel'),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        // Close the dialog first to avoid context issues
                                        Navigator.of(dialogContext).pop();

                                        // Call the separate method that handles sign out
                                        await _performSignOut();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            FlutterFlowTheme.of(context)
                                                .error
                                                .withOpacity(0.8),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text('Sign Out'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      optionColor: FlutterFlowTheme.of(context).error,
    );
  }

  // Create a dialog to select background options
  void _showBackgroundCollectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext dialogContext) {
        return Consumer<AppState>(
          builder: (context, appState, _) {
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

                        // Background Options
                        Flexible(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: appState.backgroundOptions
                                    .map<Widget>((bg) {
                                  final isSelected =
                                      appState.selectedBackground == bg['file'];
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
                                            appState.setBackground(bg['file']!);
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                // Preview
                                                Container(
                                                  width: 60,
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
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
                                                          child: Lottie.asset(
                                                            'assets/jsons/${bg['file']}',
                                                            fit: BoxFit.cover,
                                                            animate: true,
                                                            repeat: true,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
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
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
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
                                                        ),
                                                    ],
                                                  ),
                                                ),

                                                // Selection indicator
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
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
        );
      },
    );
  }

  // Separate method to perform sign out without using context
  Future<void> _performSignOut() async {
    try {
      if (!mounted) return;

      // Add a flag to track if sign out is in progress
      bool isSigningOut = true;

      try {
        await AuthUtil.safeSignOut(
          context: context,
          shouldNavigate: true,
          navigateTo: '/',
        );
        // If we reach here, sign-out was successful
        isSigningOut = false;
      } catch (e) {
        // If there's an error, mark sign-out as complete and show error
        isSigningOut = false;
        debugPrint('Error during sign out: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error during sign out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
          ),
        );
      }
    }
  }
}
