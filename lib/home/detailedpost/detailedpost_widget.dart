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
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Add this import for ImageFilter
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detailedpost_model.dart';
import 'package:flutter/rendering.dart';
import '/components/save_post_popup.dart';
import '/components/animated_like_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/utils/tag_formatter.dart';
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
      if (_scrollController.hasClients) {
        await _animateToComments();
        break;
      }
      await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
    }
  }

  Future<void> _animateToComments() async {
    if (!mounted || !_scrollController.hasClients) return;

    print('DetailedpostWidget: Scrolling to comments with animation');

    try {
      // Ensure we have the latest scroll metrics
      await Future.delayed(Duration(milliseconds: 100));

      // Get the current scroll metrics
      final position = _scrollController.position;
      final maxScroll = position.maxScrollExtent;

      // First scroll all the way to the bottom to ensure comments are visible
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );

      // Optional: Slight bounce effect
      if (mounted && _scrollController.hasClients) {
        await _scrollController.animateTo(
          maxScroll * 0.98, // Bounce back slightly
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );

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
    if (!mounted || !_scrollController.hasClients) return;
    _ensureCommentsVisible();
  }

  @override
  void dispose() {
    _model.dispose();
    _scrollController.dispose();
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
            Container(
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
                  errorWidget: (context, url, error) {
                    print('Error loading profile image: $error');
                    return Container(
                      color: FlutterFlowTheme.of(context).primary,
                      child: Center(
                        child: Text(
                          userRecord.displayName?.isNotEmpty ?? false
                              ? userRecord.displayName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
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
    final commentsRef = FirebaseFirestore.instance.collection('comments');
    final snapshot = await commentsRef
        .where('postref', isEqualTo: widget.docref)
        .count()
        .get();
    return snapshot.count!;
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
                    setState(() {});
                  },
                ),
              ],
            ),
            FutureBuilder<int>(
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

                    setState(() {});
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
    return _buildGlassmorphicContainer(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: currentUserDocument?.photoUrl?.isEmpty == true
                      ? 'https://ui-avatars.com/api/?name=${currentUserDisplayName.isNotEmpty ? currentUserDisplayName[0] : "U"}&background=random'
                      : currentUserDocument?.photoUrl ?? '',
                  width: 40,
                  height: 40,
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
                  errorWidget: (context, url, error) {
                    print('Error loading profile image: $error');
                    return Container(
                      color: FlutterFlowTheme.of(context).primary,
                      child: Center(
                        child: Text(
                          currentUserDisplayName.isNotEmpty
                              ? currentUserDisplayName[0].toUpperCase()
                              : 'U',
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: TextFormField(
                    controller: _model.textController,
                    focusNode: _model.textFieldFocusNode,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Outfit',
                          color: Colors.white.withOpacity(0.9),
                        ),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle:
                          FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Outfit',
                                color: Colors.white.withOpacity(0.5),
                              ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
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
      ),
    );
  }

  Widget _buildCommentItem(CommentsRecord comment) {
    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(comment.userref!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        final userRecord = snapshot.data!;
        return _buildGlassmorphicContainer(
          blur: 8,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture with Navigation
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (userRecord.reference == currentUserReference) {
                        // Navigate to own profile page
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
                        child: userRecord.photoUrl?.isEmpty == true
                            ? Container(
                                color: FlutterFlowTheme.of(context).primary,
                                child: Center(
                                  child: Text(
                                    userRecord.displayName?.isNotEmpty == true
                                        ? userRecord.displayName![0]
                                            .toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : Image.network(
                                userRecord.photoUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: FlutterFlowTheme.of(context).primary,
                                    child: Center(
                                      child: Text(
                                        userRecord.displayName?.isNotEmpty ==
                                                true
                                            ? userRecord.displayName![0]
                                                .toUpperCase()
                                            : '?',
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
                  ),
                ),
                SizedBox(width: 12),
                // Comment Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            userRecord.displayName ?? '',
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
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Outfit',
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        comment.comment ?? '',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Outfit',
                              color: Colors.white.withOpacity(0.9),
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

  Stream<List<CommentsRecord>> _queryComments() {
    if (widget.docref == null) {
      print('No document reference available for comments query');
      return Stream.value([]);
    }

    print('Querying comments for post: ${widget.docref?.id}');
    print('Post reference path: ${widget.docref?.path}');

    // First, let's verify the post exists
    return FirebaseFirestore.instance
        .collection('comments')
        .where('postref', isEqualTo: widget.docref)
        .snapshots()
        .map((snapshot) {
      try {
        print('Found ${snapshot.docs.length} comments');
        print('Snapshot metadata: ${snapshot.metadata}');

        // Log each document's data
        for (var doc in snapshot.docs) {
          print('Comment document data: ${doc.data()}');
          print('Comment document path: ${doc.reference.path}');
        }

        final comments = snapshot.docs
            .map((doc) {
              try {
                final comment = CommentsRecord.fromSnapshot(doc);
                print('Successfully processed comment:');
                print('  - Comment text: ${comment.comment}');
                print('  - User ref: ${comment.userref?.path}');
                print('  - Post ref: ${comment.postref?.path}');
                print('  - Date: ${comment.date}');
                return comment;
              } catch (e) {
                print('Error processing comment document: $e');
                print('Document data: ${doc.data()}');
                return null;
              }
            })
            .whereType<CommentsRecord>()
            .toList();

        print('Final processed comments count: ${comments.length}');
        return comments;
      } catch (e) {
        print('Error processing comments snapshot: $e');
        return <CommentsRecord>[];
      }
    }).handleError((error) {
      print('Error in comments stream: $error');
      return <CommentsRecord>[];
    });
  }

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

      final commentData = {
        'comment': commentText,
        'date': util.getCurrentTimestamp,
        'postref': widget.docref,
        'userref': currentUserReference,
      };

      print('Comment data to be stored: $commentData');

      final commentRef = await FirebaseFirestore.instance
          .collection('comments')
          .add(commentData);

      print('Comment added with ID: ${commentRef.id}');
      print('Comment document path: ${commentRef.path}');

      // Verify the comment was added
      final addedCommentDoc = await commentRef.get();
      print('Added comment data: ${addedCommentDoc.data()}');

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
        );
      }

      _model.textController?.clear();
      _model.textFieldFocusNode?.unfocus();
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

  Widget _buildCommentsList(List<CommentsRecord> comments) {
    if (comments.isEmpty) {
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
      itemCount: comments.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildCommentItem(comments[index]);
      },
    );
  }

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
            Container(
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
