import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart' as util;
import '/flutter_flow/nav/nav.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp, dateTimeFormat;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/comments_record.dart';
import '/backend/schema/util/schema_util.dart';
import '/widgets/sensor_background_image.dart';
import '/components/share_options_dialog.dart';
import '/utils/serialization_helpers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Add this import for ImageFilter
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detailedpost_model.dart';
import 'package:flutter/rendering.dart';
import '/components/save_post_popup.dart';
import '/components/animated_like_button.dart';
import '/utils/tag_formatter.dart';
import '/services/comments_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '/backend/cloud_functions/cloud_functions.dart';
export 'detailedpost_model.dart';

T createModel<T>(BuildContext context, T Function() model) => model();

class DetailedpostWidget extends StatefulWidget {
  const DetailedpostWidget({
    super.key,
    required this.docref,
    this.userref,
    this.showComments,
  });

  final DocumentReference? docref;
  final DocumentReference? userref;
  final bool? showComments;

  static String routeName = 'Detailedpost';
  static String routePath = '/detailedpost';

  @override
  State<DetailedpostWidget> createState() => _DetailedpostWidgetState();
}

class _DetailedpostWidgetState extends State<DetailedpostWidget> {
  late DetailedpostModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsKey = GlobalKey();

  // Add a comment count refresh notifier
  final ValueNotifier<int> _commentCountRefresh = ValueNotifier<int>(0);

  // Method to refresh comment count
  void _refreshCommentCount() {
    _commentCountRefresh.value = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DetailedpostModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    // More responsive scroll to comments when opened from a comment icon tap
    if (widget.showComments == true) {
      print('DetailedpostWidget: Will scroll to comments');
      // Wait for the widget to be fully built and laid out
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Give more time for content to load and layout to stabilize
        if (!mounted) return; // Add mounted check before scheduling the delay
        Future.delayed(Duration(milliseconds: 500), () {
          if (!mounted) return;
          _ensureCommentsVisible();
        });
      });
    }
  }

  void _ensureCommentsVisible() async {
    if (!mounted) return;

    // Try multiple times with increasing delays if needed
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        await _animateToComments();
        break;
      }
      await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
      if (!mounted) return;
    }
  }

  Future<void> _animateToComments() async {
    if (!mounted || !_scrollController.hasClients) return;

    print('DetailedpostWidget: Scrolling to comments with animation');

    try {
      // Ensure we have the latest scroll metrics
      await Future.delayed(Duration(milliseconds: 100));
      if (!mounted) return;

      // Get the current scroll metrics
      final position = _scrollController.position;
      final maxScroll = position.maxScrollExtent;

      // First scroll all the way to the bottom to ensure comments are visible
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;

      // Optional: Slight bounce effect
      if (mounted && _scrollController.hasClients) {
        await _scrollController.animateTo(
          maxScroll * 0.98, // Bounce back slightly
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
        if (!mounted) return;

        // Return to the bottom
        if (mounted && _scrollController.hasClients) {
          await _scrollController.animateTo(
            maxScroll,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
      }
    } catch (e) {
      print('Error scrolling to comments: $e');
    }
  }

  void _scrollToComments() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;
    _ensureCommentsVisible();
  }

  @override
  void dispose() {
    _model.dispose();
    _scrollController.dispose();

    // Dispose the ValueNotifier
    _commentCountRefresh.dispose();

    // Cancel any ongoing animations or delayed operations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This ensures we're not in the middle of a build when we cancel operations
      // Set a flag or cancel timers if necessary
    });

    super.dispose();
  }

  Widget _buildGlassmorphicContainer({
    required Widget child,
    double blur = 10,
    Color? gradientColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (gradientColor ?? Colors.white).withOpacity(0.15),
                (gradientColor ?? Colors.white).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildUserHeader(UserRecord userRecord) {
    return _buildGlassmorphicContainer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                // Navigate to user's profile
                if (userRecord.reference == currentUserReference) {
                  // Navigate to current user's profile
                  context.pushNamed('prof1');
                } else {
                  // Navigate to other user's profile
                  context.pushNamed(
                    'Userpage',
                    queryParameters: {
                      'profileparameter': serializeParam(
                        userRecord.reference,
                        ParamType.DocumentReference,
                      ),
                    }.withoutNulls,
                  );
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CachedNetworkImage(
                    imageUrl: userRecord.photoUrl?.isEmpty ?? true
                        ? 'https://ui-avatars.com/api/?name=${userRecord.displayName?[0] ?? '?'}&background=random'
                        : userRecord.photoUrl ?? '',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: FlutterFlowTheme.of(context).primary,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
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
                    userRecord.displayName ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    userRecord.userName ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDreamContent(PostsRecord post) {
    return _buildGlassmorphicContainer(
      blur: 15,
      gradientColor: FlutterFlowTheme.of(context).primary,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title ?? '',
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 22,
                  ),
            ),
            SizedBox(height: 12),
            Text(
              post.dream ?? '',
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                    fontFamily: 'Outfit',
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 16,
                  ),
            ),
            // Display tags if available
            if (post.tags != null && post.tags.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TagFormatter.buildTagsWidget(
                  context,
                  post.tags,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                SizedBox(width: 4),
                Text(
                  util.dateTimeFormat('relative', post.date),
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Outfit',
                        color: Colors.white.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<int> getCommentsCount() async {
    try {
      print('Getting comments count for post: ${widget.docref?.id}');
      return await CommentsService.getCommentCount(widget.docref!);
    } catch (e) {
      print('Error getting comments count: $e');
      return 0;
    }
  }

  Widget _buildInteractionBar(PostsRecord post) {
    final likes = post.likes ?? [];
    final hasLiked = likes.contains(currentUserReference);
    final isSaved = post.postSavedBy.contains(currentUserReference);

    return _buildGlassmorphicContainer(
      blur: 8,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                AnimatedLikeButton(
                  isLiked: hasLiked,
                  likeCount: likes.length,
                  onTap: () async {
                    if (hasLiked) {
                      // Unlike
                      await widget.docref!.update({
                        'likes': FieldValue.arrayRemove([currentUserReference]),
                      });
                    } else {
                      // Like
                      await widget.docref!.update({
                        'likes': FieldValue.arrayUnion([currentUserReference]),
                      });

                      // Create a like notification if necessary
                      if (currentUserReference != widget.userref &&
                          widget.userref != null) {
                        try {
                          // Use direct Firebase method for consistency
                          final notificationData = {
                            'is_a_like': true,
                            'is_read': false,
                            'post_ref': widget.docref,
                            'made_by': currentUserReference,
                            'made_to': widget.userref?.id,
                            'date': DateTime.now(),
                            'made_by_username':
                                currentUserDocument?.userName ?? '',
                            'is_follow_request': false,
                            'status': '',
                          };

                          print('Creating like notification in detailed post:');
                          print('  - Post ID: ${widget.docref?.id}');
                          print('  - Made by: ${currentUserReference?.id}');
                          print('  - Made to: ${widget.userref?.id}');
                          print('  - Full data: $notificationData');

                          final notifRef = await FirebaseFirestore.instance
                              .collection('notifications')
                              .add(notificationData);

                          print(
                              'Created like notification with ID: ${notifRef.id}');
                        } catch (e) {
                          print('Error creating like notification: $e');
                        }
                      }
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            ValueListenableBuilder<int>(
              valueListenable: _commentCountRefresh,
              builder: (context, refreshValue, child) {
                return FutureBuilder<int>(
                  future: getCommentsCount(),
                  builder: (context, snapshot) {
                    return _buildInteractionButton(
                      icon: Icons.comment_outlined,
                      activeIcon: Icons.comment,
                      count: snapshot.data ?? 0,
                      isActive: false,
                      onTap: () {
                        // Use the new animation method directly
                        _ensureCommentsVisible();
                      },
                    );
                  },
                );
              },
            ),
            Row(
              children: [
                _buildInteractionButton(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  activeIcon: Icons.bookmark,
                  count: post.postSavedBy.length,
                  isActive: isSaved,
                  onTap: () async {
                    final savedByElement = currentUserReference;
                    print('Saving post with user reference: $savedByElement');
                    print('Current post data: ${post.snapshotData}');
                    print(
                        'Current Post_saved_by field: ${post.snapshotData['Post_saved_by']}');

                    // Initialize Post_saved_by as an empty array if it doesn't exist
                    final currentSavedBy =
                        post.snapshotData['Post_saved_by'] as List<dynamic>? ??
                            [];
                    final isCurrentlySaved =
                        currentSavedBy.contains(savedByElement);

                    await post.reference.update({
                      'Post_saved_by': isCurrentlySaved
                          ? FieldValue.arrayRemove([savedByElement])
                          : FieldValue.arrayUnion([savedByElement]),
                    });
                    print('Post saved status updated: ${!isCurrentlySaved}');
                    print(
                        'Updated post data: ${(await post.reference.get()).data()}');

                    // Show the save popup
                    SavePostPopup.showSavedPopup(context,
                        isSaved: !isCurrentlySaved);

                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            _buildInteractionButton(
              icon: Icons.ios_share,
              activeIcon: Icons.ios_share,
              count: 0,
              isActive: false,
              onTap: () async {
                // Get the user record for the poster
                final UserRecord? posterUser =
                    await UserRecord.getDocumentOnce(widget.userref!);
                if (posterUser != null) {
                  // Get the post document
                  final postDoc = await widget.docref!.get();
                  final postRecord = PostsRecord.fromSnapshot(postDoc);
                  ShareOptionsDialog.show(context, postRecord, posterUser);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required IconData activeIcon,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? FlutterFlowTheme.of(context).primary
                  : FlutterFlowTheme.of(context).secondaryText,
              size: 28,
            ),
          ),
          SizedBox(width: 4),
          Text(
            count.toString(),
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Outfit',
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(PostsRecord post) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show who we're replying to if applicable
          if (_model.replyingToComment != null)
            Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                            ),
                        children: [
                          TextSpan(
                            text: 'Replying to comment: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: _model.replyingToComment!.comment,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _model.replyingToComment = null;
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _model.textController,
                  focusNode: _model.textFieldFocusNode,
                  obscureText: false,
                  decoration: InputDecoration(
                    hintText: _model.replyingToComment != null
                        ? 'Write a reply...'
                        : 'Add a comment...',
                    hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Outfit',
                          color: Colors.white.withOpacity(0.7),
                        ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor:
                        FlutterFlowTheme.of(context).secondary.withOpacity(0.1),
                    contentPadding:
                        EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
                  ),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                      ),
                  maxLines: 5,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  validator: (val) =>
                      _model.textControllerValidator?.call(context, val),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  if (_model.textController.text.isEmpty) {
                    return;
                  }

                  await _addComment(_model.textController.text);
                },
                icon: Icon(
                  Icons.send_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentsRecord comment) {
    // Check if comment is marked for deletion
    final bool isPendingDeletion =
        comment.snapshotData['pendingDeletion'] == true;

    // Check if comment is soft deleted
    final bool isDeleted = comment.snapshotData['deleted'] == true;

    // Don't show deleted comments at all
    if (isDeleted) {
      return Container();
    }

    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(comment.userref!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        final userRecord = snapshot.data!;

        // Check if the current user has liked this comment
        final bool isLiked = comment.likes.contains(currentUserReference);

        return _buildGlassmorphicContainer(
          blur: 8,
          child: Opacity(
            opacity: isPendingDeletion ? 0.6 : 1.0,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header row with avatar, name, and menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar with InkWell for navigation
                          InkWell(
                            onTap: () {
                              if (isPendingDeletion) return;
                              // Navigate to user's profile
                              if (userRecord.reference ==
                                  currentUserReference) {
                                // Navigate to current user's profile
                                context.pushNamed('prof1');
                              } else {
                                // Navigate to other user's profile
                                context.pushNamed(
                                  'Userpage',
                                  queryParameters: {
                                    'profileparameter': serializeParam(
                                      userRecord.reference,
                                      ParamType.DocumentReference,
                                    ),
                                  }.withoutNulls,
                                );
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .primary
                                    .withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: CachedNetworkImage(
                                  imageUrl: userRecord.photoUrl?.isEmpty ?? true
                                      ? 'https://ui-avatars.com/api/?name=${userRecord.displayName?[0] ?? '?'}&background=random'
                                      : userRecord.photoUrl ?? '',
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: FlutterFlowTheme.of(context).primary,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Name and time
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  userRecord.displayName ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  util.dateTimeFormat(
                                    'relative',
                                    comment.date ?? DateTime.now(),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: 'Outfit',
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Menu - hide for comments pending deletion
                          if (!isPendingDeletion)
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: _buildCommentOptionsMenu(comment),
                            ),
                        ],
                      ),
                      // Comment text
                      Padding(
                        padding: EdgeInsets.only(left: 44, top: 4, right: 8),
                        child: Text(
                          isPendingDeletion
                              ? 'This comment is being deleted...'
                              : (comment.comment ?? ''),
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'Outfit',
                                color: Colors.white
                                    .withOpacity(isPendingDeletion ? 0.7 : 0.9),
                                fontStyle: isPendingDeletion
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                        ),
                      ),
                      // Like and reply buttons - hide for comments pending deletion
                      if (!isPendingDeletion)
                        Padding(
                          padding: EdgeInsets.only(left: 44, top: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Like button
                              InkWell(
                                onTap: () => _likeComment(comment),
                                child: Container(
                                  height: 24,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 16,
                                        color: isLiked
                                            ? FlutterFlowTheme.of(context).error
                                            : Colors.white.withOpacity(0.7),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        comment.likes.length.toString(),
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'Outfit',
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              // Reply button
                              InkWell(
                                onTap: () => _showReplyInput(comment),
                                child: Container(
                                  height: 24,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.reply,
                                        size: 16,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Reply',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'Outfit',
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Show replies if there are any (and this comment isn't pending deletion)
                      if (!comment.isReply && !isPendingDeletion)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: _buildRepliesSection(comment),
                        ),
                    ],
                  ),
                ),

                // Show deletion indicator badge
                if (isPendingDeletion)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.7),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Deleting',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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

  // Method to handle liking/unliking a comment
  Future<void> _likeComment(CommentsRecord comment) async {
    try {
      final likes = List<DocumentReference>.from(comment.likes);
      final userRef = currentUserReference!;

      if (likes.contains(userRef)) {
        // Unlike: remove user reference from likes list
        likes.remove(userRef);
      } else {
        // Like: add user reference to likes list
        likes.add(userRef);
      }

      // Update the comment document
      await comment.reference.update({'likes': likes});

      // If the user is liking someone else's comment, create a notification
      if (!likes.contains(userRef) && comment.userref != currentUserReference) {
        final username = currentUserDocument?.userName?.trim() ?? '';

        await NotificationsRecord.createNotification(
          isALike: true,
          isRead: false,
          postRef: widget.docref,
          madeBy: currentUserReference,
          madeTo: comment.userref?.id,
          date: util.getCurrentTimestamp,
          madeByUsername: username,
          isFollowRequest: false,
        );
      }
    } catch (e) {
      print('Error liking/unliking comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating like status: $e'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  // Method to add a new comment or reply
  Future<void> _addComment(String? comment) async {
    final commentText = comment?.trim() ?? '';
    if (commentText.isEmpty) return;

    print('Adding comment to post: ${widget.docref?.id}');
    print('Post reference path: ${widget.docref?.path}');
    print('Comment text: $commentText');
    print('User reference: ${currentUserReference?.id}');
    print('User reference path: ${currentUserReference?.path}');

    try {
      // Verify the post exists before adding comment
      final postDoc = await widget.docref!.get();
      if (!postDoc.exists) {
        print('Post does not exist!');
        return;
      }

      // If replying to a comment, make sure it's not deleted
      if (_model.replyingToComment != null) {
        // Check if parent comment has been deleted
        final parentCommentDoc =
            await _model.replyingToComment!.reference.get();
        final parentCommentData =
            parentCommentDoc.data() as Map<String, dynamic>?;
        if (!parentCommentDoc.exists || parentCommentData?['deleted'] == true) {
          print('Cannot reply to a deleted comment');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'This comment has been deleted and cannot be replied to.'),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
          // Reset reply state
          setState(() {
            _model.replyingToComment = null;
          });
          return;
        }
      }

      final commentData = {
        'comment': commentText,
        'date': util.getCurrentTimestamp,
        'postref': widget.docref,
        'userref': currentUserReference,
        'likes': [],
        'deleted': false,
      };

      // If replying to a comment, add additional data
      if (_model.replyingToComment != null) {
        commentData['parentCommentRef'] = _model.replyingToComment!.reference;
        commentData['isReply'] = true;
      } else {
        commentData['isReply'] = false;
      }

      print('Comment data to be stored: $commentData');

      // Use CommentsService instead of direct Firestore access
      String? commentId;
      if (_model.replyingToComment != null) {
        commentId = await CommentsService.createComment(
          postId: widget.docref!.id,
          userId: currentUserReference!.id,
          comment: commentText,
          parentCommentId: _model.replyingToComment!.reference.id,
        );
      } else {
        commentId = await CommentsService.createComment(
          postId: widget.docref!.id,
          userId: currentUserReference!.id,
          comment: commentText,
        );
      }

      if (commentId == null) {
        print('Failed to create comment');
        return;
      }

      print('Comment added with ID: $commentId');

      // Verify the comment was added
      final addedCommentDoc = await FirebaseFirestore.instance
          .collection('comments')
          .doc(commentId)
          .get();
      print('Added comment data: ${addedCommentDoc.data()}');

      // Determine notification recipient
      if (_model.replyingToComment != null) {
        // If replying to a comment, notify the comment author
        final commentAuthorRef = _model.replyingToComment!.userref;

        // Don't notify yourself
        if (currentUserReference != commentAuthorRef) {
          final username = currentUserDocument?.userName?.trim() ?? '';
          print('Creating reply notification:');
          print('Made by: ${currentUserReference?.id}');
          print('Made to: ${commentAuthorRef?.id}');
          print('Username: $username');

          // Create notification for the comment author
          await NotificationsRecord.createNotification(
            isALike: false,
            isRead: false,
            postRef: widget.docref,
            madeBy: currentUserReference,
            madeTo: commentAuthorRef?.id,
            date: util.getCurrentTimestamp,
            madeByUsername: username,
            isFollowRequest: false,
            isReply: true, // This is a reply to a comment
          );

          // Also notify the post author if different from comment author and not the current user
          if (widget.userref != commentAuthorRef &&
              widget.userref != currentUserReference) {
            await NotificationsRecord.createNotification(
              isALike: false,
              isRead: false,
              postRef: widget.docref,
              madeBy: currentUserReference,
              madeTo: widget.userref?.id,
              date: util.getCurrentTimestamp,
              madeByUsername: username,
              isFollowRequest: false,
              isReply:
                  false, // This is a comment on a post (from post author's perspective)
            );
          }
        }
      } else {
        // If adding a top-level comment, notify the post author
        if (currentUserReference != widget.userref) {
          final username = currentUserDocument?.userName?.trim() ?? '';
          print('Creating comment notification:');
          print('Made by: ${currentUserReference?.id}');
          print('Made to: ${widget.userref?.id}');
          print('Username: $username');

          await NotificationsRecord.createNotification(
            isALike: false,
            isRead: false,
            postRef: widget.docref,
            madeBy: currentUserReference,
            madeTo: widget.userref?.id,
            date: util.getCurrentTimestamp,
            madeByUsername: username,
            isFollowRequest: false,
            isReply: false, // This is a top-level comment, not a reply
          );
        }
      }

      // Clear input and reset reply state
      _model.textController?.clear();
      _model.textFieldFocusNode?.unfocus();
      setState(() {
        _model.replyingToComment = null;
      });

      // Refresh the comment count
      _refreshCommentCount();
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding comment: $e'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  // Method to display options menu for a comment
  Widget _buildCommentOptionsMenu(CommentsRecord comment) {
    // Check permissions - only post owners can delete comments
    final isPostOwner = currentUserReference == widget.userref;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: FlutterFlowTheme.of(context).secondaryBackground,
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: Colors.white.withOpacity(0.7),
          size: 18,
        ),
        offset: Offset(0, 8),
        onSelected: (value) {
          if (value == 'report') {
            _showReportCommentDialog(comment);
          } else if (value == 'delete') {
            _deleteComment(comment);
          }
        },
        itemBuilder: (context) {
          final List<PopupMenuItem<String>> items = [];

          // Add delete option if user is the post owner
          if (isPostOwner) {
            items.add(
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: FlutterFlowTheme.of(context).error,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Delete Comment',
                      style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                            color: FlutterFlowTheme.of(context).error,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Add report option for everyone
          items.add(
            PopupMenuItem<String>(
              value: 'report',
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Report Comment',
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                ],
              ),
            ),
          );

          return items;
        },
      ),
    );
  }

  // Method to delete a comment
  Future<void> _deleteComment(CommentsRecord comment) async {
    try {
      // Show confirmation dialog
      final bool confirmDelete = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
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
                    padding: EdgeInsets.all(20),
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
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .error
                                .withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.delete_outline,
                              color: FlutterFlowTheme.of(context).error,
                              size: 30,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Delete Comment',
                          style: FlutterFlowTheme.of(context).titleLarge,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Are you sure you want to delete this comment? This action cannot be undone.',
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style:
                                      FlutterFlowTheme.of(context).bodyMedium,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor:
                                      FlutterFlowTheme.of(context).error,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ) ??
          false;

      if (!confirmDelete) return;

      // Show loading indicator
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
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
              Text('Deleting comment...'),
            ],
          ),
          backgroundColor: FlutterFlowTheme.of(context).primary,
          duration: Duration(seconds: 5),
        ),
      );

      // Mark the comment as pending deletion in the UI
      await comment.reference.update({'pendingDeletion': true});

      // Use the updated soft delete method
      await _performSoftDeletion(comment);

      // Show success message
      if (mounted) {
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                Text('Comment deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 2),
          ),
        );

        // Force UI refresh
        setState(() {});
      }
    } catch (e) {
      print('Error in comment deletion process: $e');

      // If there was an error, remove the pending deletion flag
      try {
        await comment.reference.update({'pendingDeletion': false});
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Error deleting comment: ${e.toString()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: FlutterFlowTheme.of(context).error,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Method to perform soft deletion of comments
  Future<void> _performSoftDeletion(CommentsRecord comment) async {
    print('Starting soft deletion for comment ID: ${comment.reference.id}');
    print('Current user: ${currentUserReference?.id}');
    print('Post owner: ${widget.userref?.id}');
    print('Comment owner: ${comment.userref?.id}');

    // Check if current user is either the comment author or post owner
    final isCommentAuthor = currentUserReference == comment.userref;
    final isPostOwner = currentUserReference == widget.userref;

    print('Is comment author: $isCommentAuthor');
    print('Is post owner: $isPostOwner');

    try {
      // Use the CommentsService class for a more robust handling of permissions
      final success = await CommentsService.deleteComment(
        commentId: comment.reference.id,
        postId: comment.postref?.id,
        isAuthor: isCommentAuthor,
        isPostOwner: isPostOwner,
        userId: currentUserReference?.id,
      );

      if (!success) {
        print('CommentsService.deleteComment returned false');
        throw Exception('Failed to delete comment');
      }

      print('Successfully soft deleted comment via CommentsService');

      // Refresh the comment count
      _refreshCommentCount();
    } catch (e) {
      print('Error in soft deletion: $e');
      throw e; // Re-throw to be handled by the calling function
    }
  }

  // Method to show a dialog for reporting a comment
  Future<void> _showReportCommentDialog(CommentsRecord comment) async {
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
                      'Report Comment',
                      style: FlutterFlowTheme.of(context).titleLarge,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Why are you reporting this comment?',
                  style: FlutterFlowTheme.of(context).bodyLarge,
                ),
                SizedBox(height: 16),
                _buildReportOption('Inappropriate content'),
                _buildReportOption('Harassment or bullying'),
                _buildReportOption('Spam'),
                _buildReportOption('False information'),
                _buildReportOption('Other'),
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
  Widget _buildReportOption(String reason) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _submitReport(reason);
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

  // Method to handle the report submission
  Future<void> _submitReport(String reason) async {
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

      await Future.delayed(Duration(milliseconds: 800));

      // In a real app, we would create a report document in Firestore here
      // For now, just simulate a successful report

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
                  'Comment reported successfully. Thank you for helping improve our community.',
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
      print('Error reporting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reporting comment: $e'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  // Method to show reply input for a specific comment
  void _showReplyInput(CommentsRecord parentComment) {
    print('Showing reply input for comment ID: ${parentComment.reference.id}');
    setState(() {
      _model.replyingToComment = parentComment;
      _model.textController?.clear();
    });

    // Focus the text field
    _model.textFieldFocusNode?.requestFocus();

    // Scroll to the comment input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  // Build replies section for a parent comment
  Widget _buildRepliesSection(CommentsRecord parentComment) {
    print(
        'Building replies section for comment: ${parentComment.reference.id}');
    return StreamBuilder<List<CommentsRecord>>(
      stream: queryCommentsRecord(
        queryBuilder: (query) => query
            .where('parentCommentRef', isEqualTo: parentComment.reference)
            .orderBy('date', descending: false),
      ),
      builder: (context, snapshot) {
        // Log data received
        print('Replies snapshot hasData: ${snapshot.hasData}');
        print('Replies snapshot hasError: ${snapshot.hasError}');
        if (snapshot.hasError) {
          print('Replies snapshot error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return Container();
        }

        final allReplies = snapshot.data!;
        print('Found ${allReplies.length} total replies');

        // Filter out deleted replies in the client code
        final replies = allReplies
            .where((reply) => reply.snapshotData['deleted'] != true)
            .toList();
        print('After filtering, ${replies.length} visible replies remain');

        if (replies.isEmpty) {
          return Container();
        }

        // Create a map to track expanded state for each parent comment
        if (!_model.expandedReplies.containsKey(parentComment.reference.id)) {
          _model.expandedReplies[parentComment.reference.id] = false;
        }

        // Get the current expanded state
        final bool isExpanded =
            _model.expandedReplies[parentComment.reference.id]!;

        // Show only the first reply if not expanded
        final displayedReplies =
            isExpanded ? replies : replies.take(1).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display visible replies
            Padding(
              padding: EdgeInsets.only(left: 24),
              child: ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: displayedReplies.length,
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _buildReplyItem(displayedReplies[index]);
                },
              ),
            ),

            // Show "Load more replies" button if there are hidden replies
            if (replies.length > 1)
              Padding(
                padding: EdgeInsets.only(left: 24, top: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      // Toggle expanded state
                      _model.expandedReplies[parentComment.reference.id] =
                          !isExpanded;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color:
                          FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        SizedBox(width: 4),
                        Text(
                          isExpanded
                              ? 'Hide replies'
                              : 'View ${replies.length - 1} more ${replies.length == 2 ? 'reply' : 'replies'}',
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Build a reply item (simplified version of comment item)
  Widget _buildReplyItem(CommentsRecord reply) {
    print(
        'Building reply item: ${reply.reference.id}, isDeleted: ${reply.snapshotData['deleted'] == true}');

    // Don't show deleted replies
    if (reply.snapshotData['deleted'] == true) {
      print('Reply is deleted, not displaying: ${reply.reference.id}');
      return Container();
    }

    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(reply.userref!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        final userRecord = snapshot.data!;

        // Check if the current user has liked this reply
        final bool isLiked = reply.likes.contains(currentUserReference);

        return Container(
          margin: EdgeInsets.only(top: 8, left: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with avatar, name, and menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with InkWell for navigation
                  InkWell(
                    onTap: () {
                      // Navigate to user's profile
                      if (userRecord.reference == currentUserReference) {
                        // Navigate to current user's profile
                        context.pushNamed('prof1');
                      } else {
                        // Navigate to other user's profile
                        context.pushNamed(
                          'Userpage',
                          queryParameters: {
                            'profileparameter': serializeParam(
                              userRecord.reference,
                              ParamType.DocumentReference,
                            ),
                          }.withoutNulls,
                        );
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: userRecord.photoUrl?.isEmpty ?? true
                              ? 'https://ui-avatars.com/api/?name=${userRecord.displayName?[0] ?? '?'}&background=random'
                              : userRecord.photoUrl ?? '',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                          errorWidget: (context, url, error) {
                            return Container(
                              color: FlutterFlowTheme.of(context).primary,
                              child: Center(
                                child: Text(
                                  userRecord.displayName?.isNotEmpty ?? false
                                      ? userRecord.displayName![0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
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
                  SizedBox(width: 8),
                  // Name and time
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userRecord.displayName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          util.dateTimeFormat(
                            'relative',
                            reply.date ?? DateTime.now(),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Menu
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: _buildCommentOptionsMenu(reply),
                  ),
                ],
              ),
              // Comment text
              Padding(
                padding: EdgeInsets.only(left: 40, top: 4, right: 8, bottom: 4),
                child: Text(
                  reply.comment ?? '',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                ),
              ),
              // Like button
              Padding(
                padding: EdgeInsets.only(left: 40, top: 2),
                child: InkWell(
                  onTap: () => _likeComment(reply),
                  child: Container(
                    height: 24,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isLiked
                              ? FlutterFlowTheme.of(context).error
                              : Colors.white.withOpacity(0.7),
                        ),
                        SizedBox(width: 4),
                        Text(
                          reply.likes.length.toString(),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Update the _queryComments method to filter out deleted comments
  Stream<List<CommentsRecord>> _queryComments() {
    return queryCommentsRecord(
      queryBuilder: (commentsRecord) => commentsRecord
          .where('postref', isEqualTo: widget.docref)
          .where('isReply', isEqualTo: false)
          .orderBy('date', descending: false),
    );
  }

  // Build the comments section UI
  Widget _buildCommentsSection(PostsRecord post) {
    return Column(
      key: _commentsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                FlutterFlowTheme.of(context).primary.withOpacity(0.7),
                FlutterFlowTheme.of(context).primary.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.4),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: EdgeInsets.only(bottom: 16, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Comments',
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
              // Scroll indicator
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        _buildCommentInput(post),
        SizedBox(height: 24),
        StreamBuilder<List<CommentsRecord>>(
          stream: _queryComments(),
          builder: (context, commentsSnapshot) {
            if (!commentsSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              );
            }
            final comments = commentsSnapshot.data!;
            return _buildCommentsList(comments);
          },
        ),
      ],
    );
  }

  // Build the list of comments
  Widget _buildCommentsList(List<CommentsRecord> comments) {
    // Filter out deleted comments
    final visibleComments = comments
        .where((comment) => comment.snapshotData['deleted'] != true)
        .toList();

    if (visibleComments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
              SizedBox(height: 16),
              Text(
                'No comments yet',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'Outfit',
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: visibleComments.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildCommentItem(visibleComments[index]);
      },
    );
  }

  void _showPermissionExplanationDialog() {
    showDialog(
      context: context,
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security_outlined,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Firestore Permission Settings',
                          style: FlutterFlowTheme.of(context).titleLarge,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'The error is occurring because Firestore security rules need to be updated to allow users to delete their own comments or comments on their posts.',
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '1. Security Rule Solution:',
                    style: FlutterFlowTheme.of(context).titleMedium,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'match /comments/{commentId} {\n'
                      '  allow delete: if request.auth != null && \n'
                      '  (resource.data.userref == request.auth.uid || \n'
                      '   get(resource.data.postref).data.poster == request.auth.uid);\n'
                      '}',
                      style: TextStyle(
                        fontFamily: 'Courier New',
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '2. Cloud Function Solution:',
                    style: FlutterFlowTheme.of(context).titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Alternatively, implement this Firebase Cloud Function:',
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '// Create a file: functions/src/index.ts',
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'import * as functions from "firebase-functions";\n'
                          'import * as admin from "firebase-admin";\n\n'
                          'admin.initializeApp();\n\n'
                          'export const deleteComment = functions.https.onCall(async (data, context) => {\n'
                          '  // Make sure user is authenticated\n'
                          '  if (!context.auth) {\n'
                          '    throw new functions.https.HttpsError(\n'
                          '      "unauthenticated",\n'
                          '      "You must be logged in to delete comments"\n'
                          '    );\n'
                          '  }\n\n'
                          '  const { commentId } = data;\n'
                          '  if (!commentId) {\n'
                          '    throw new functions.https.HttpsError(\n'
                          '      "invalid-argument",\n'
                          '      "Comment ID is required"\n'
                          '    );\n'
                          '  }\n\n'
                          '  try {\n'
                          '    // Get the comment document\n'
                          '    const commentRef = admin.firestore().collection("comments").doc(commentId);\n'
                          '    const commentSnap = await commentRef.get();\n\n'
                          '    if (!commentSnap.exists) {\n'
                          '      throw new functions.https.HttpsError(\n'
                          '        "not-found",\n'
                          '        "Comment does not exist"\n'
                          '      );\n'
                          '    }\n\n'
                          '    const commentData = commentSnap.data();\n'
                          '    const postRef = commentData?.postref;\n'
                          '    const commentAuthorId = commentData?.userref?.id;\n\n'
                          '    // Check if user is comment author\n'
                          '    if (commentAuthorId === context.auth.uid) {\n'
                          '      // User is comment author, proceed with deletion\n'
                          '      await commentRef.delete();\n'
                          '      return { success: true, deleted: "author" };\n'
                          '    }\n\n'
                          '    // Check if user is post owner\n'
                          '    if (postRef) {\n'
                          '      const postSnap = await admin.firestore().doc(postRef.path).get();\n'
                          '      if (postSnap.exists) {\n'
                          '        const postData = postSnap.data();\n'
                          '        const postOwnerId = postData?.poster?.id || postData?.userref?.id;\n\n'
                          '        if (postOwnerId === context.auth.uid) {\n'
                          '          // User is post owner, proceed with deletion\n'
                          '          await commentRef.delete();\n'
                          '          return { success: true, deleted: "post_owner" };\n'
                          '        }\n'
                          '      }\n'
                          '    }\n\n'
                          '    throw new functions.https.HttpsError(\n'
                          '      "permission-denied",\n'
                          '      "You do not have permission to delete this comment"\n'
                          '    );\n'
                          '  } catch (error) {\n'
                          '    console.error("Error deleting comment:", error);\n'
                          '    throw new functions.https.HttpsError(\n'
                          '      "internal",\n'
                          '      "Error deleting comment: " + error.message\n'
                          '    );\n'
                          '  }\n'
                          '});',
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'To use in Flutter:',
                    style: FlutterFlowTheme.of(context).titleSmall,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'final functions = FirebaseFunctions.instance;\n'
                      'final result = await functions.httpsCallable(\'deleteComment\').call({\n'
                      '  \'commentId\': comment.reference.id,\n'
                      '});',
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Got it'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PostsRecord>(
      stream: PostsRecord.getDocument(widget.docref!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: SpinKitRipple(
                color: FlutterFlowTheme.of(context).primary,
                size: 50,
              ),
            ),
          );
        }
        final post = snapshot.data!;

        // Add fallback values for post fields that might be missing
        final postTitle = post.title ?? 'Untitled Dream';
        final postDream = post.dream ?? 'No dream content available';
        final postDate = post.date ?? DateTime.now();
        final postVideoUrl = post.videoBackgroundUrl ?? '';
        final postLikes = post.likes ?? [];
        final postSavedBy = post.postSavedBy ?? [];

        // Check if userref is null, if it is, use post.poster as fallback
        final userReference = widget.userref ?? post.poster;

        // Only proceed with StreamBuilder if userReference is not null
        if (userReference == null) {
          return Scaffold(
            key: scaffoldKey,
            backgroundColor: Colors.transparent,
            body: Hero(
              tag: 'post_image_${widget.docref?.id ?? "default"}',
              child: SensorBackgroundImage(
                imageUrl: postVideoUrl,
                motionMultiplier: 0.0,
                child: SafeArea(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
                            child: Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.arrow_back_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                                Text(
                                  'Dream Details',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .override(
                                        fontFamily: 'Outfit',
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Anonymous user placeholder since we don't have a valid user reference
                                _buildAnonymousUserHeader(),
                                SizedBox(height: 16),
                                _buildDreamContent(post),
                                SizedBox(height: 16),
                                _buildInteractionBar(post),
                                // Always show comments section regardless of showComments value
                                SizedBox(height: 16),
                                _buildCommentsSection(post),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return StreamBuilder<UserRecord>(
          stream: UserRecord.getDocument(userReference),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: SpinKitRipple(
                    color: FlutterFlowTheme.of(context).primary,
                    size: 50,
                  ),
                ),
              );
            }
            final userRecord = userSnapshot.data!;

            return Scaffold(
              key: scaffoldKey,
              backgroundColor: Colors.transparent,
              body: Hero(
                tag: 'post_image_${widget.docref?.id ?? "default"}',
                child: SensorBackgroundImage(
                  imageUrl: postVideoUrl,
                  motionMultiplier: 0.0,
                  child: SafeArea(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
                              child: Row(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                  Text(
                                    'Dream Details',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .override(
                                          fontFamily: 'Outfit',
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16, 16, 16, 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildUserHeader(userRecord),
                                  SizedBox(height: 16),
                                  _buildDreamContent(post),
                                  SizedBox(height: 16),
                                  _buildInteractionBar(post),
                                  // Always show comments section regardless of showComments value
                                  SizedBox(height: 16),
                                  _buildCommentsSection(post),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  // Anonymous user header when the user reference is missing
  Widget _buildAnonymousUserHeader() {
    return _buildGlassmorphicContainer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                // Navigate to current user's profile when clicking an anonymous user avatar
                context.pushNamed('prof1');
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                    'Unknown User',
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.95),
                        ),
                  ),
                  Text(
                    'This user\'s data is not available',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Outfit',
                          color: Colors.white.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
