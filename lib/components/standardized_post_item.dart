import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luna_kraft/backend/backend.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_util.dart' as util;
import 'package:luna_kraft/flutter_flow/flutter_flow_util.dart';
import 'package:luna_kraft/auth/firebase_auth/auth_util.dart';
import 'package:luna_kraft/components/animated_like_button.dart';
import 'package:luna_kraft/components/save_post_popup.dart';
import 'package:luna_kraft/components/share_options_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '/flutter_flow/app_navigation_helper.dart';
import '/utils/tag_formatter.dart';
import '/utils/serialization_helpers.dart';
import '../services/comments_service.dart';

class StandardizedPostItem extends StatefulWidget {
  final PostsRecord post;
  final UserRecord user;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final bool showUserInfo;
  final bool animateEntry;
  final int animationIndex;
  final bool showDeleteOption;

  const StandardizedPostItem({
    Key? key,
    required this.post,
    required this.user,
    this.onLike,
    this.onSave,
    this.onDelete,
    this.showUserInfo = true,
    this.animateEntry = false,
    this.animationIndex = 0,
    this.showDeleteOption = false,
  }) : super(key: key);

  @override
  State<StandardizedPostItem> createState() => _StandardizedPostItemState();
}

class _StandardizedPostItemState extends State<StandardizedPostItem> {
  // Local state to manage likes and saves
  late bool _isLiked;
  late bool _isSaved;
  late int _likeCount;
  late int _saveCount;

  @override
  void initState() {
    super.initState();
    _updateLocalState();
  }

  @override
  void didUpdateWidget(StandardizedPostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.reference != widget.post.reference ||
        oldWidget.post.likes != widget.post.likes ||
        oldWidget.post.postSavedBy != widget.post.postSavedBy) {
      _updateLocalState();
    }
  }

  void _updateLocalState() {
    _isLiked = widget.post.likes.contains(currentUserReference);
    _isSaved = widget.post.postSavedBy.contains(currentUserReference);
    _likeCount = widget.post.likes.length;
    _saveCount = widget.post.postSavedBy.length;
  }

  // Handle like action locally
  Future<void> _handleLike() async {
    final hasLiked = _isLiked;

    // Update UI immediately
    setState(() {
      _isLiked = !hasLiked;
      _likeCount = hasLiked ? _likeCount - 1 : _likeCount + 1;
    });

    // Update database
    try {
      await widget.post.reference.update({
        'likes': hasLiked
            ? FieldValue.arrayRemove([currentUserReference])
            : FieldValue.arrayUnion([currentUserReference]),
      });

      // Create notification if needed
      if (!hasLiked &&
          widget.post.poster != null &&
          widget.post.poster != currentUserReference) {
        try {
          await NotificationsRecord.createNotification(
            isALike: true,
            isRead: false,
            postRef: widget.post.reference,
            madeBy: currentUserReference,
            madeTo: widget.post.poster?.id,
            date: DateTime.now(),
            madeByUsername: currentUserDocument?.userName ?? '',
            isFollowRequest: false,
            status: '',
          );
        } catch (e) {
          print('Error creating like notification: $e');
        }
      }

      // Call original callback if provided
      if (widget.onLike != null) widget.onLike!();
    } catch (e) {
      // If there's an error, revert local state
      print('Error updating like state: $e');
      setState(() {
        _isLiked = hasLiked;
        _likeCount = hasLiked ? _likeCount + 1 : _likeCount - 1;
      });
    }
  }

  // Handle save action locally
  Future<void> _handleSave() async {
    final isSaved = _isSaved;

    // Update UI immediately
    setState(() {
      _isSaved = !isSaved;
      _saveCount = isSaved ? _saveCount - 1 : _saveCount + 1;
    });

    // Update database
    try {
      await widget.post.reference.update({
        'Post_saved_by': isSaved
            ? FieldValue.arrayRemove([currentUserReference])
            : FieldValue.arrayUnion([currentUserReference]),
      });

      // Show the save popup
      SavePostPopup.showSavedPopup(context, isSaved: !isSaved);

      // Call original callback if provided
      if (widget.onSave != null) widget.onSave!();
    } catch (e) {
      // If there's an error, revert local state
      print('Error updating save state: $e');
      setState(() {
        _isSaved = isSaved;
        _saveCount = isSaved ? _saveCount + 1 : _saveCount - 1;
      });
    }
  }

  // Stream to get comment count for a post
  Stream<int> _getCommentCountStream() {
    return FirebaseFirestore.instance
        .collection('comments')
        .where('postref', isEqualTo: widget.post.reference)
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
    Widget postWidget = GestureDetector(
      onTap: () => AppNavigationHelper.navigateToDetailedPost(
        context,
        docref: serializeParam(
          widget.post.reference,
          ParamType.DocumentReference,
        ),
        userref: serializeParam(
          widget.post.poster,
          ParamType.DocumentReference,
        ),
      ),
      onLongPress: widget.showDeleteOption && widget.onDelete != null
          ? () => _showDeleteOverlay(context)
          : null,
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Hero(
              tag: 'post_image_${widget.post.reference.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildPostBackground(widget.post, context),
              ),
            ),
          ),
          // Add glassmorphic overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Container(
                  color: Colors.black.withOpacity(0.05),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info row (conditionally shown)
                if (widget.showUserInfo) ...[
                  Row(
                    children: [
                      _buildUserAvatar(context, widget.user),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.displayName ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              util.dateTimeFormat(
                                  'relative', widget.post.date!),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
                // Post content
                Text(
                  widget.post.title,
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Figtree',
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.post.dream,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Figtree',
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.9),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Tags (if present)
                if (widget.post.tags != null &&
                    widget.post.tags.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TagFormatter.buildTagsWidget(
                      context,
                      widget.post.tags,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Figtree',
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
                // Interaction buttons
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedLikeButton(
                      isLiked: _isLiked,
                      likeCount: _likeCount,
                      iconSize: 28,
                      activeColor: FlutterFlowTheme.of(context).primary,
                      inactiveColor: Colors.white.withOpacity(0.8),
                      onTap: _handleLike,
                    ),
                    // Comments button with StreamBuilder for real-time updates
                    StreamBuilder<int>(
                      stream: _getCommentCountStream(),
                      builder: (context, snapshot) {
                        final commentCount = snapshot.data ?? 0;
                        return _buildInteractionButton(
                          context: context,
                          icon: Icons.mode_comment_outlined,
                          count: commentCount,
                          onTap: () {
                            context.pushNamed(
                              'Detailedpost',
                              queryParameters: {
                                'docref': serializeParam(
                                  widget.post.reference,
                                  ParamType.DocumentReference,
                                ),
                                'userref': serializeParam(
                                  widget.post.poster,
                                  ParamType.DocumentReference,
                                ),
                                'showComments': serializeParam(
                                  true,
                                  ParamType.bool,
                                ),
                              },
                            );
                          },
                        );
                      },
                    ),
                    _buildInteractionButton(
                      context: context,
                      icon: _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      count: _saveCount,
                      onTap: _handleSave,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.ios_share,
                        color: Colors.white.withOpacity(0.8),
                        size: 28,
                      ),
                      onPressed: () {
                        ShareOptionsDialog.show(
                            context, widget.post, widget.user);
                      },
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Apply animation if needed
    if (widget.animateEntry) {
      return postWidget
          .animate()
          .fade(
            duration: 250.ms,
            curve: Curves.easeOutQuart,
          )
          .scale(
            begin: const Offset(0.98, 0.98),
            end: const Offset(1.0, 1.0),
            duration: 250.ms,
            curve: Curves.easeOutQuart,
          );
    }

    return postWidget;
  }

  Widget _buildInteractionButton({
    required BuildContext context,
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 28,
          ),
          onPressed: onTap,
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          constraints: BoxConstraints(),
        ),
        SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(BuildContext context, UserRecord user) {
    final photoUrl = user.photoUrl ?? '';
    final displayName = user.displayName ?? '';
    final firstLetter = displayName.isNotEmpty ? displayName[0] : '?';

    return Container(
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
            color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
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
            : CachedNetworkImage(
                imageUrl: photoUrl,
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
                  print('Failed URL: $url');
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
    );
  }

  Widget _buildPostBackground(PostsRecord post, BuildContext context) {
    // For old posts with video backgrounds, show fallback background
    if (post.videoBackgroundUrl.isNotEmpty &&
        (post.videoBackgroundUrl.contains('assets/videos/postbg/') ||
            post.videoBackgroundUrl.contains('.mp4') ||
            post.videoBackgroundUrl.contains('.webm'))) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FlutterFlowTheme.of(context).primary.withOpacity(0.2),
              FlutterFlowTheme.of(context).secondary.withOpacity(0.2),
            ],
          ),
        ),
      );
    }

    // For new posts with image backgrounds
    return PostBackgroundWidget(
      imagePath: post.videoBackgroundUrl,
      opacity: post.videoBackgroundOpacity ?? 0.75,
    );
  }

  void _showDeleteOverlay(BuildContext context) {
    // Use the built-in showModalBottomSheet instead of a custom overlay
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.bookmark_remove,
                color: FlutterFlowTheme.of(context).primary,
              ),
              title: Text(
                'Unsave this dream',
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Figtree',
                      color: Colors.white,
                    ),
              ),
              subtitle: Text(
                'Remove from your saved dreams collection',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Figtree',
                      color: Colors.white.withOpacity(0.7),
                    ),
              ),
              onTap: () {
                Navigator.pop(context);
                if (widget.onDelete != null) {
                  widget.onDelete!();
                }
              },
            ),
            Divider(color: Colors.white.withOpacity(0.1)),
            ListTile(
              leading: Icon(
                Icons.cancel_outlined,
                color: Colors.white.withOpacity(0.7),
              ),
              title: Text(
                'Cancel',
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Figtree',
                      color: Colors.white,
                    ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class PostBackgroundWidget extends StatelessWidget {
  final String imagePath;
  final double opacity;

  const PostBackgroundWidget({
    Key? key,
    required this.imagePath,
    this.opacity = 0.75,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return _buildFallbackBackground(context);
    }

    return Opacity(
      opacity: opacity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FlutterFlowTheme.of(context).primary.withOpacity(0.2),
            FlutterFlowTheme.of(context).secondary.withOpacity(0.2),
          ],
        ),
      ),
    );
  }
}
