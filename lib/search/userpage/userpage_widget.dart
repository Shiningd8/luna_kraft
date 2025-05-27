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

  // Accept either a DocumentReference or a string ID
  final dynamic profileparameter;

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
  bool _hasShownFollowRequestSnackbar = false;
  OverlayEntry? _overlayEntry;

  // Add a field to store the resolved document reference
  DocumentReference? _profileReference;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UserpageModel());

    // Resolve the profile reference
    _resolveProfileReference();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  // Convert string parameter to document reference if needed
  void _resolveProfileReference() {
    try {
      if (widget.profileparameter is DocumentReference) {
        _profileReference = widget.profileparameter as DocumentReference;
        print(
            'Profile reference already a DocumentReference: ${_profileReference?.path}');
      } else if (widget.profileparameter is String) {
        final profileId = widget.profileparameter as String;
        print('Converting profile ID to reference: $profileId');

        if (profileId.contains('/')) {
          // Handle full path format
          _profileReference = FirebaseFirestore.instance.doc(profileId);
          print('Using full path: ${_profileReference?.path}');
        } else {
          // Use just the ID with correct collection name
          _profileReference =
              FirebaseFirestore.instance.collection('User').doc(profileId);
          print('Created User reference with ID: ${_profileReference?.path}');
        }
      }
    } catch (e) {
      print('Error resolving profile reference: $e');
      print('Debug info - profileparameter: ${widget.profileparameter}');
    }
  }

  @override
  void dispose() {
    _removeSnackbar();
    _model.dispose();
    super.dispose();
  }

  void _removeSnackbar() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  // Check if the viewed profile has sent a follow request to the current user
  Future<bool> _checkForPendingFollowRequest(DocumentReference userRef) async {
    try {
      // Query for notifications where the viewed user has sent a follow request to the current user
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('made_by', isEqualTo: userRef)
          .where('made_to', isEqualTo: currentUserReference?.id)
          .where('is_follow_request', isEqualTo: true)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return notifications.docs.isNotEmpty;
    } catch (e) {
      print('Error checking for pending follow request: $e');
      return false;
    }
  }

  // Show a modern follow request snackbar at the top of the screen
  void _displayFollowRequestSnackbar(
      UserRecord profileUser, NotificationsRecord? notification) {
    _removeSnackbar();

    // Need to get the notification if we don't have it
    if (notification == null) {
      FirebaseFirestore.instance
          .collection('notifications')
          .where('made_by', isEqualTo: profileUser.reference)
          .where('made_to', isEqualTo: currentUserReference?.id)
          .where('is_follow_request', isEqualTo: true)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final notif = NotificationsRecord.fromSnapshot(snapshot.docs.first);
          _showSnackbarWithNotification(profileUser, notif);
        }
      });
    } else {
      _showSnackbarWithNotification(profileUser, notification);
    }
  }

  void _showSnackbarWithNotification(
      UserRecord profileUser, NotificationsRecord notification) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF9747FF).withOpacity(0.25),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: profileUser.photoUrl != null &&
                                      profileUser.photoUrl!.isNotEmpty
                                  ? Image.network(
                                      profileUser.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    )
                                  : Container(
                                      color: Colors.white.withOpacity(0.2),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Follow Request',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${profileUser.displayName ?? profileUser.userName ?? 'User'} wants to follow you',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: _removeSnackbar,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(Icons.close,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Decline button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                _removeSnackbar();
                                await _denyFollowRequest(
                                    notification, profileUser);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Decline',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          // Accept button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                _removeSnackbar();
                                await _acceptFollowRequest(
                                    notification, profileUser);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF6448FE),
                                      Color(0xFF9747FF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF9747FF).withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Accept',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
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

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _acceptFollowRequest(
      NotificationsRecord notification, UserRecord requestUser) async {
    try {
      // Create a batch to perform multiple operations
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update the notification status
      batch.update(notification.reference, {
        'is_read': true,
        'status': 'approved',
      });

      // 2. Add the follower to the user's followers list
      batch.update(currentUserReference!, {
        'users_following_me': FieldValue.arrayUnion([requestUser.reference]),
        'followers': FieldValue.arrayUnion([requestUser.reference]),
      });

      // 3. Add the user to the follower's following list
      batch.update(requestUser.reference, {
        'following_users': FieldValue.arrayUnion([currentUserReference]),
        'following': FieldValue.arrayUnion([currentUserReference]),
      });

      // 4. Remove the user from the pending requests list
      batch.update(currentUserReference!, {
        'pending_follow_requests':
            FieldValue.arrayRemove([requestUser.reference]),
      });

      // Commit all operations at once
      await batch.commit();

      // Show a success message
      FollowStatusPopup.showFollowStatusPopup(
        context,
        isFollowed: true,
        status: 'request_accepted',
      );

      setState(() {});
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

  Future<void> _denyFollowRequest(
      NotificationsRecord notification, UserRecord requestUser) async {
    try {
      // Create a batch to perform multiple operations
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update the notification status
      batch.update(notification.reference, {
        'is_read': true,
        'status': 'declined',
      });

      // 2. Remove the user from the pending requests list
      batch.update(currentUserReference!, {
        'pending_follow_requests':
            FieldValue.arrayRemove([requestUser.reference]),
      });

      // Commit all operations at once
      await batch.commit();

      // Show a success message
      FollowStatusPopup.showFollowStatusPopup(
        context,
        isFollowed: false,
        status: 'request_declined',
      );

      setState(() {});
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
    // Check if we have a valid profile reference
    if (_profileReference == null) {
      // Show error UI if no valid profile reference
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          title: Text(
            'User Not Found',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 22,
                ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.white,
          ),
          centerTitle: true,
          elevation: 2,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                'The user profile could not be found.',
                style: FlutterFlowTheme.of(context).bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use the _profileReference instead of widget.profileparameter
    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(_profileReference!),
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
                                profpara: _profileReference,
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
            body: FutureBuilder<bool>(
              future: _checkForPendingFollowRequest(_profileReference!),
              builder: (context, pendingRequestSnapshot) {
                // When we have the result, show the snackbar if needed
                if (pendingRequestSnapshot.hasData &&
                    pendingRequestSnapshot.data == true) {
                  // Only show the snackbar once
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_hasShownFollowRequestSnackbar) {
                      _hasShownFollowRequestSnackbar = true;
                      _displayFollowRequestSnackbar(userpageUserRecord, null);
                    }
                  });
                }

                return LottieBackground(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Reduce this padding for app bar - was too large
                        SizedBox(
                            height: MediaQuery.of(context).padding.top + 16),

                        // Profile Header Section with Instagram-like layout
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                              // Profile Image with border/shadow
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
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userpageUserRecord.displayName ?? '',
                                      style: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .override(
                                            fontFamily: 'Outfit',
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '@${userpageUserRecord.userName}',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Figtree',
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
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
                                          _buildStatColumn(
                                            context,
                                            userpageUserRecord
                                                .usersFollowingMe.length
                                                .toString(),
                                            'Followers',
                                          ),
                                          _buildStatColumn(
                                            context,
                                            userpageUserRecord
                                                .followingUsers.length
                                                .toString(),
                                            'Following',
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

                        // Follow/Unfollow Button
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: AuthUserStreamWidget(
                            builder: (context) {
                              final isFollowing = (currentUserDocument
                                          ?.followingUsers
                                          .toList() ??
                                      [])
                                  .contains(userpageUserRecord.reference);

                              final isPendingRequest = (userpageUserRecord
                                              .pendingFollowRequests ??
                                          [])
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
                                      await userpageUserRecord.reference
                                          .update({
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
                                                FieldValue.arrayRemove([
                                              userpageUserRecord.reference
                                            ]),
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
                                      await userpageUserRecord.reference
                                          .update({
                                        ...mapToFirestore(
                                          {
                                            'pending_follow_requests':
                                                FieldValue.arrayRemove(
                                                    [currentUserReference]),
                                          },
                                        ),
                                      });

                                      // Find and update any existing notifications
                                      final notifications =
                                          await FirebaseFirestore.instance
                                              .collection('notifications')
                                              .where('made_by',
                                                  isEqualTo:
                                                      currentUserReference)
                                              .where('made_to',
                                                  isEqualTo:
                                                      userpageUserRecord
                                                          .reference.id)
                                              .where('is_follow_request',
                                                  isEqualTo: true)
                                              .where('status',
                                                  isEqualTo: 'pending')
                                              .get();

                                      // Update the notifications
                                      final batch =
                                          FirebaseFirestore.instance.batch();
                                      for (final doc in notifications.docs) {
                                        batch.update(doc.reference,
                                            {'status': 'cancelled'});
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
                                      print(
                                          'Error cancelling follow request: $e');
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
                                      await userpageUserRecord.reference
                                          .update({
                                        ...mapToFirestore(
                                          {
                                            'pending_follow_requests':
                                                FieldValue.arrayUnion(
                                                    [currentUserReference]),
                                          },
                                        ),
                                      });

                                      await NotificationsRecord
                                          .createNotification(
                                        isALike: false,
                                        isRead: false,
                                        madeBy: currentUserReference,
                                        madeTo:
                                            userpageUserRecord.reference?.id,
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
                                      await userpageUserRecord.reference
                                          .update({
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
                                                FieldValue.arrayUnion([
                                              userpageUserRecord.reference
                                            ]),
                                          },
                                        ),
                                      });

                                      await NotificationsRecord
                                          .createNotification(
                                        isALike: false,
                                        isRead: false,
                                        madeBy: currentUserReference,
                                        madeTo:
                                            userpageUserRecord.reference?.id,
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
                          margin: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Heading with zero padding
                              Container(
                                margin: EdgeInsets.only(bottom: 16),
                                padding: EdgeInsets.zero,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                          isEqualTo: _profileReference)
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
                                              .contains(_profileReference) ??
                                          false)) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                      
                                      // Skip private posts unless viewing your own profile
                                      if (post.isPrivate && _profileReference != currentUserReference) {
                                        return SizedBox.shrink();
                                      }
                                      
                                      return Container(
                                        margin:
                                            index == 0 ? EdgeInsets.zero : null,
                                        child: StreamBuilder<UserRecord>(
                                          stream: UserRecord.getDocument(
                                              post.poster!),
                                          builder: (context, userSnapshot) {
                                            if (!userSnapshot.hasData) {
                                              return Container(
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
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
                );
              },
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
