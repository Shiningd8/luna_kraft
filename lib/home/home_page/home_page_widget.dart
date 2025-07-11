import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp, dateTimeFormat;
import '/components/emptylist_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart' as util;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/pages/notification_page/notification_page_widget.dart';
import '/widgets/space_background.dart';
import '/services/app_state.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/util/firestore_util.dart';
import '/widgets/notification_test_button.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' as io;
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/components/save_post_popup.dart';
import '/components/animated_like_button.dart';
import '/flutter_flow/app_navigation_helper.dart';
import '/widgets/lottie_background.dart';
import 'package:luna_kraft/components/standardized_post_item.dart';
import '/components/dream_fact_widget.dart';
import '/components/share_options_dialog.dart';
import '/utils/tag_formatter.dart';
import '/utils/serialization_helpers.dart';
import '/services/comments_service.dart';
import '/utils/share_util.dart';
import '/components/invite_friend_dialog.dart';
import '/services/notification_service.dart';
import '/utils/subscription_util.dart';

// Separate class for home feed content
class _HomeFeedContent extends StatefulWidget {
  const _HomeFeedContent({Key? key}) : super(key: key);

  @override
  State<_HomeFeedContent> createState() => _HomeFeedContentState();
}

class _HomeFeedContentState extends State<_HomeFeedContent> {
  List<PostsRecord> _allPosts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  PostsRecord? _latestPost;
  Map<String, UserRecord> _userCache = {};
  // Keep track of loading state for different sections
  bool _loadingFollowingPosts = true;
  bool _loadingPublicPosts = true;
  // Add a scroll controller for smoother scrolling
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    // Initialize the scroll controller
    _scrollController = ScrollController();
    // Start preloading user data
    _preloadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Preload user data for filtering private accounts
  Future<void> _preloadUserData() async {
    try {
      // Get all users to identify private accounts
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .get();
      
      for (var doc in usersSnapshot.docs) {
        try {
          final userData = UserRecord.getDocumentFromData(
            doc.data(),
            doc.reference,
          );
          _userCache[doc.id] = userData;
        } catch (e) {
          print('Error processing user data: $e');
        }
      }
    } catch (e) {
      print('Error preloading user data: $e');
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Clear existing posts
      _allPosts.clear();
      _latestPost = null;

      // First get ALL posts from the database
      final allPostsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('date', descending: true)
          .get();

      List<PostsRecord> allPosts = [];

      // Process all posts and validate user references
      for (var doc in allPostsQuery.docs) {
        try {
          final post = PostsRecord.fromSnapshot(doc);

          // Skip posts without a valid poster reference
          if (post.poster == null) {
            continue;
          }

          // Verify the user exists
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(post.poster!.id)
              .get();

          if (!userDoc.exists) {
            continue;
          }

          // Check if this is a public post or from current user
          final isCurrentUserPost = post.poster == currentUserReference;
          final isFollowedUser =
              currentUserDocument?.followingUsers?.contains(post.poster) ??
                  false;

          // Skip posts from blocked users
          final isBlockedUser = currentUserDocument?.blockedUsers?.contains(post.poster) ?? false;
          if (isBlockedUser) {
            continue;
          }

          // Only include public posts OR your own posts (including private ones)
          if (!post.isPrivate || isCurrentUserPost) {
            allPosts.add(post);
          }
        } catch (e) {
          continue;
        }
      }

      // Sort posts by date
      allPosts.sort((a, b) => b.date!.compareTo(a.date!));

      // Take only the most recent posts
      _allPosts = allPosts.take(50).toList();

      // Load user data for all posts efficiently
      final Set<DocumentReference> userRefs =
          _allPosts.map((post) => post.poster!).toSet();

      // Load user data in parallel with error handling
      await Future.wait(
        userRefs.map((userRef) async {
          try {
            if (!_userCache.containsKey(userRef.id)) {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userRef.id)
                  .get();

              if (userDoc.exists && userDoc.data() != null) {
                final userData = UserRecord.fromSnapshot(userDoc);
                _userCache[userRef.id] = userData;
              }
            }
          } catch (e) {
            // Silently handle errors
          }
        }),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Access denied. Please check your permissions.';
        case 'unavailable':
          return 'Service temporarily unavailable. Please try again later.';
        case 'resource-exhausted':
          return 'Too many requests. Please wait a moment and try again.';
        default:
          return 'Failed to load posts. ${error.message}';
      }
    }
    return 'Failed to load posts. Please try again.';
  }

  // Update a specific post's like status locally
  void _updatePostLikeState(PostsRecord post, bool isLiked) {
    final index =
        _allPosts.indexWhere((p) => p.reference.id == post.reference.id);
    if (index >= 0) {
      setState(() {
        // We can't modify the PostsRecord directly, so we'll just create a new copy
        // for our local state management
        final currentPost = _allPosts[index];

        // Handle the like action
        if (isLiked) {
          // Add the current user to likes if not already there
          if (!currentPost.likes.contains(currentUserReference)) {
            currentPost.likes.add(currentUserReference!);
          }
        } else {
          // Remove the current user from likes
          currentPost.likes.remove(currentUserReference);
        }
      });
    }
  }

  // Update a specific post's save status locally
  void _updatePostSaveState(PostsRecord post, bool isSaved) {
    final index =
        _allPosts.indexWhere((p) => p.reference.id == post.reference.id);
    if (index >= 0) {
      setState(() {
        // We can't modify the PostsRecord directly, so we'll just create a new copy
        // for our local state management
        final currentPost = _allPosts[index];

        // Handle the save action
        if (isSaved) {
          // Add the current user to saved posts if not already there
          if (!currentPost.postSavedBy.contains(currentUserReference)) {
            currentPost.postSavedBy.add(currentUserReference!);
          }
        } else {
          // Remove the current user from saved posts
          currentPost.postSavedBy.remove(currentUserReference);
        }
      });
    }
  }

  // Stream to get comment count for a post
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
    return StreamBuilder<List<PostsRecord>>(
      stream: queryPostsRecord(
        queryBuilder: (postsRecord) =>
            postsRecord.orderBy('date', descending: true),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading posts',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          if (_isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: FlutterFlowTheme.of(context).primary,
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Welcome to LunaKraft!',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                      ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Share your first dream or follow others to see their dream stories here',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Figtree',
                          color: Colors.white.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        // Filter out private posts from other users
        List<PostsRecord> allPosts = snapshot.data!.where((post) => 
          !post.isPrivate || post.poster == currentUserReference
        ).toList();
        
        final followingUsers = currentUserDocument?.followingUsers ?? [];
        final blockedUsers = currentUserDocument?.blockedUsers ?? [];
        final isFollowingAnyone = followingUsers.isNotEmpty;
        PostsRecord? latestPost;

        // Log preloaded user cache status
        print('Preloaded user cache has ${_userCache.length} users');

        // Find the latest post from current user
        for (var post in allPosts) {
          if (post.poster == currentUserReference) {
            latestPost = post;
            break;
          }
        }

        // Separate posts into following posts and other public posts
        // For following users, include more recent posts (last week)
        final oneWeekAgo = DateTime.now().subtract(Duration(days: 7));
        
        // 1. Posts from following users (not private, not blocked)
        final followingPosts = allPosts.where((post) {
          // Skip posts without a valid poster reference
          if (post.poster == null) {
            return false;
          }

          // Skip the latest post as it will be displayed separately
          if (latestPost != null && post.reference.id == latestPost.reference.id) {
            return false;
          }

          // Skip posts from current user (they'll see their latest post in the purple box)
          if (post.poster == currentUserReference) {
            return false;
          }

          // Skip posts from blocked users
          if (blockedUsers.contains(post.poster)) {
            return false;
          }

          // Skip private posts unless they belong to followed users
          if (post.isPrivate && !followingUsers.contains(post.poster)) {
            return false;
          }

          // Skip posts older than a week
          if (post.date == null || post.date!.isBefore(oneWeekAgo)) {
            return false;
          }

          // Only include posts from followed users
          return followingUsers.contains(post.poster);
        }).toList();

        // 2. Other public posts (not from following, not private, not blocked, not from private accounts)
        final publicPosts = allPosts.where((post) {
          // Skip posts without a valid poster reference
          if (post.poster == null) {
            return false;
          }

          // Skip the latest post as it will be displayed separately
          if (latestPost != null && post.reference.id == latestPost.reference.id) {
            return false;
          }

          // Skip posts from current user (they'll see their latest post in the purple box)
          if (post.poster == currentUserReference) {
            return false;
          }

          // Skip posts from blocked users
          if (blockedUsers.contains(post.poster)) {
            return false;
          }

          // Skip private posts
          if (post.isPrivate) {
            return false;
          }
          
          // Skip posts from private accounts that user doesn't follow
          if (post.poster != null) {
            final posterId = post.poster!.id;
            final userData = _userCache[posterId];
            
            // If we have user data and the account is private, check follow status
            if (userData != null && userData.isPrivate) {
              // If user doesn't follow this private account, skip the post
              if (!followingUsers.contains(post.poster)) {
                return false;
              }
            }
          }

          // Skip posts from following users (they're already in followingPosts)
          if (followingUsers.contains(post.poster)) {
            return false;
          }

          // Include all other public posts
          return true;
        }).toList();

        // If there are no valid posts to display
        if (followingPosts.isEmpty && publicPosts.isEmpty && latestPost == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Welcome to LunaKraft!',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                      ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Share your first dream or follow others to see their dream stories here',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Figtree',
                          color: Colors.white.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        // Build the combined feed
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          displacement: 50,
          edgeOffset: 0,
          color: FlutterFlowTheme.of(context).primary,
          backgroundColor: Colors.transparent,
          child: ListView.builder(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 80,
            ),
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            itemCount: (latestPost != null ? 1 : 0) + 
                      // Add section for users not following anyone
                      (followingUsers.isEmpty ? 1 : 0) +
                      followingPosts.length + 
                      (followingUsers.isNotEmpty && followingPosts.isEmpty ? 1 : 0) + // Message for no recent posts from followers
                      // Always show divider and "Discover More Dreams" header
                      1 + // Divider for everyone
                      publicPosts.length,
            itemBuilder: (context, index) {
              int currentIndex = index;
              
              // First item is the latest post from the current user
              if (latestPost != null && currentIndex == 0) {
                currentIndex++;
                return StreamBuilder<UserRecord>(
                  stream: UserRecord.getDocument(latestPost.poster!),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return SizedBox();
                    }
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _buildLatestPostItem(
                        context,
                        latestPost,
                        userSnapshot.data!,
                      ),
                    );
                  },
                );
              }
              
              // "Follow friends" section for users not following anyone
              if (followingUsers.isEmpty && currentIndex == (latestPost != null ? 1 : 0)) {
                currentIndex++;
                return Padding(
                  padding: EdgeInsets.only(bottom: 16, top: 8),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                          FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Follow Friends & Family',
                              style: FlutterFlowTheme.of(context).titleSmall.override(
                                fontFamily: 'Outfit',
                                color: FlutterFlowTheme.of(context).primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Connect with friends and family to see their dreams in your feed.',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Figtree',
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              context.pushNamed('Explore');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FlutterFlowTheme.of(context).primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.explore, size: 18),
                                SizedBox(width: 8),
                                Text('Explore Users'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Following users posts
              if (currentIndex < (latestPost != null ? 1 : 0) + 
                             (followingUsers.isEmpty ? 1 : 0) + 
                             followingPosts.length) {
                final postIndex = currentIndex - (latestPost != null ? 1 : 0) - (followingUsers.isEmpty ? 1 : 0);
                final post = followingPosts[postIndex];
                
                return StreamBuilder<UserRecord>(
                  stream: UserRecord.getDocument(post.poster!),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return SizedBox();
                    }
                    
                    final user = userSnapshot.data!;
                    
                    // If this is a private post and the user isn't following the poster, don't show it
                    if (post.isPrivate && !followingUsers.contains(post.poster)) {
                      return SizedBox();
                    }
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: StandardizedPostItem(
                        post: post,
                        user: user,
                        animateEntry: true,
                        animationIndex: currentIndex,
                        onLike: () {
                          final isCurrentlyLiked = post.likes.contains(currentUserReference);
                          _updatePostLikeState(post, !isCurrentlyLiked);
                        },
                        onSave: () {
                          final isCurrentlySaved = post.postSavedBy.contains(currentUserReference);
                          _updatePostSaveState(post, !isCurrentlySaved);
                        },
                      ),
                    );
                  },
                );
              }
              
              // No recent posts message for followed users
              if (followingUsers.isNotEmpty && followingPosts.isEmpty && 
                  currentIndex == (latestPost != null ? 1 : 0) + (followingUsers.isEmpty ? 1 : 0)) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 16, top: 8),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                          FlutterFlowTheme.of(context).primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'No Recent Dreams',
                              style: FlutterFlowTheme.of(context).titleSmall.override(
                                fontFamily: 'Outfit',
                                color: FlutterFlowTheme.of(context).primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'People you follow haven\'t shared any dreams in the past week. You\'ll see their recent dreams here when they do!',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Figtree',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Always show Divider between any posts above and public posts
              if (currentIndex == (latestPost != null ? 1 : 0) + 
                             (followingUsers.isEmpty ? 1 : 0) +
                             followingPosts.length +
                             (followingUsers.isNotEmpty && followingPosts.isEmpty ? 1 : 0)) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Divider(
                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                        thickness: 1.5,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.explore,
                                color: FlutterFlowTheme.of(context).primary,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Discover More Dreams',
                                style: FlutterFlowTheme.of(context).titleSmall.override(
                                  fontFamily: 'Outfit',
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // Public posts section
              if (currentIndex >= (latestPost != null ? 1 : 0) + 
                               (followingUsers.isEmpty ? 1 : 0) +
                               followingPosts.length + 
                               (followingUsers.isNotEmpty && followingPosts.isEmpty ? 1 : 0) +
                               1) { // +1 for the divider
                final postIndex = currentIndex - 
                                 (latestPost != null ? 1 : 0) - 
                                 (followingUsers.isEmpty ? 1 : 0) -
                                 followingPosts.length - 
                                 (followingUsers.isNotEmpty && followingPosts.isEmpty ? 1 : 0) -
                                 1; // -1 for the divider
                
                if (postIndex >= publicPosts.length) {
                  return SizedBox();
                }
                
                final post = publicPosts[postIndex];
                
                // Double-check: Only show this post if user is not private
                return StreamBuilder<UserRecord>(
                  stream: UserRecord.getDocument(post.poster!),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return SizedBox();
                    }
                    
                    final user = userSnapshot.data!;
                    
                    // Skip posts from private accounts that user doesn't follow
                    if (user.isPrivate && !followingUsers.contains(post.poster)) {
                      return SizedBox(); // Don't show this post
                    }
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: StandardizedPostItem(
                        post: post,
                        user: user,
                        animateEntry: true,
                        animationIndex: currentIndex,
                        onLike: () {
                          final isCurrentlyLiked = post.likes.contains(currentUserReference);
                          _updatePostLikeState(post, !isCurrentlyLiked);
                        },
                        onSave: () {
                          final isCurrentlySaved = post.postSavedBy.contains(currentUserReference);
                          _updatePostSaveState(post, !isCurrentlySaved);
                        },
                      ),
                    );
                  },
                );
              }
              
              return SizedBox();
            },
          ),
        );
      },
    );
  }

  // Helper method to build the latest post item
  Widget _buildLatestPostItem(
      BuildContext context, PostsRecord? latestPost, UserRecord user) {
    if (latestPost == null) return SizedBox();

    final bool initialIsLiked = latestPost.likes.contains(currentUserReference);
    final bool initialIsSaved =
        latestPost.postSavedBy.contains(currentUserReference);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isLiked = initialIsLiked;
        bool isSaved = initialIsSaved;
        int likeCount = latestPost.likes.length;
        int saveCount = latestPost.postSavedBy.length;

        return GestureDetector(
          onTap: () => context.pushNamed(
            'Detailedpost',
            queryParameters: {
              'docref': serializeParam(
                latestPost.reference,
                ParamType.DocumentReference,
              ),
              'userref': serializeParam(
                latestPost.poster,
                ParamType.DocumentReference,
              ),
            },
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Your Latest Post',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: FlutterFlowTheme.of(context).primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Spacer(),
                            Text(
                              util.dateTimeFormat('relative', latestPost.date!),
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          latestPost.title,
                          style:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          latestPost.dream,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white,
                                  ),
                        ),
                        if (latestPost.tags != null &&
                            latestPost.tags.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: TagFormatter.buildClickableTagsWidget(
                              context,
                              latestPost.tags.split(',')
                                  .map((tag) => tag.trim())
                                  .where((tag) => tag.isNotEmpty)
                                  .toList(),
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Figtree',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                AnimatedLikeButton(
                                  isLiked: isLiked,
                                  likeCount: likeCount,
                                  iconSize: 28,
                                  activeColor:
                                      FlutterFlowTheme.of(context).primary,
                                  inactiveColor: Colors.white.withOpacity(0.8),
                                  onTap: () async {
                                    final userRef = currentUserReference;
                                    if (userRef == null) return;

                                    // Update local state immediately
                                    final newIsLiked = !isLiked;
                                    setState(() {
                                      isLiked = newIsLiked;
                                      likeCount = newIsLiked
                                          ? likeCount + 1
                                          : likeCount - 1;
                                    });

                                    // Update in parent state to reflect when scrolling
                                    _updatePostLikeState(
                                        latestPost, newIsLiked);

                                    // Update database
                                    try {
                                      await latestPost.reference.update({
                                        'likes': newIsLiked
                                            ? FieldValue.arrayUnion([userRef])
                                            : FieldValue.arrayRemove([userRef]),
                                      });

                                      // Create notification if liking
                                      if (newIsLiked &&
                                          latestPost.poster != null &&
                                          latestPost.poster !=
                                              currentUserReference) {
                                        try {
                                          await NotificationsRecord
                                              .createNotification(
                                            isALike: true,
                                            isRead: false,
                                            postRef: latestPost.reference,
                                            madeBy: currentUserReference,
                                            madeTo: latestPost.poster?.id,
                                            date: DateTime.now(),
                                            madeByUsername:
                                                currentUserDocument?.userName ??
                                                    '',
                                            isFollowRequest: false,
                                            status: '',
                                          );
                                        } catch (e) {
                                          print(
                                              'Error creating like notification: $e');
                                        }
                                      }
                                    } catch (e) {
                                      // If there's an error, revert local state
                                      print('Error updating like state: $e');
                                      setState(() {
                                        isLiked = !newIsLiked;
                                        likeCount = !newIsLiked
                                            ? likeCount + 1
                                            : likeCount - 1;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                StreamBuilder<int>(
                                  stream: _getCommentCountStream(
                                      latestPost.reference),
                                  builder: (context, snapshot) {
                                    final commentCount = snapshot.data ?? 0;
                                    return _buildInteractionButton(
                                      context: context,
                                      icon: Icons.mode_comment_outlined,
                                      count: commentCount,
                                      onTap: () {
                                        AppNavigationHelper
                                            .navigateToDetailedPost(
                                          context,
                                          docref: serializeParam(
                                            latestPost.reference,
                                            ParamType.DocumentReference,
                                          ),
                                          userref: serializeParam(
                                            latestPost.poster,
                                            ParamType.DocumentReference,
                                          ),
                                          showComments: true,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildInteractionButton(
                                  context: context,
                                  icon: isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_outline,
                                  count: saveCount,
                                  onTap: () async {
                                    // Update local state immediately
                                    final newIsSaved = !isSaved;
                                    setState(() {
                                      isSaved = newIsSaved;
                                      saveCount = newIsSaved
                                          ? saveCount + 1
                                          : saveCount - 1;
                                    });

                                    // Update in parent state to reflect when scrolling
                                    _updatePostSaveState(
                                        latestPost, newIsSaved);

                                    // Update database
                                    try {
                                      await latestPost.reference.update({
                                        'Post_saved_by': newIsSaved
                                            ? FieldValue.arrayUnion(
                                                [currentUserReference])
                                            : FieldValue.arrayRemove(
                                                [currentUserReference]),
                                      });

                                      // Show the save popup
                                      SavePostPopup.showSavedPopup(context,
                                          isSaved: newIsSaved);
                                    } catch (e) {
                                      // If there's an error, revert local state
                                      print('Error updating save state: $e');
                                      setState(() {
                                        isSaved = !newIsSaved;
                                        saveCount = !newIsSaved
                                            ? saveCount + 1
                                            : saveCount - 1;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.ios_share,
                                color: Colors.white.withOpacity(0.8),
                                size: 28,
                              ),
                              onPressed: () async {
                                // Get the user record for the poster
                                final UserRecord? posterUser =
                                    await UserRecord.getDocumentOnce(
                                        latestPost.poster!);
                                if (posterUser != null) {
                                  ShareOptionsDialog.show(context, latestPost, posterUser);
                                }
                              },
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              constraints: BoxConstraints(),
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
        )
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
      },
    );
  }

  // Helper method for building interaction buttons
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
}

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _refreshTimestamp = DateTime.now().millisecondsSinceEpoch;
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerAnimation;
  AppState? _appState;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isDisposed = false;
  late ScrollController _scrollController;
  bool _isScrolled = false;
  bool _showHeaderShadow = false;
  bool _checkingNotificationPermission = false;
  Timer? _notificationRequestTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store AppState reference when dependencies change
    _appState = context.read<AppState>();
  }

  @override
  void initState() {
    super.initState();
    // Register observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerAnimationController,
      curve: Curves.easeInOutQuart,
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Schedule notification permission check
    _scheduleNotificationPermissionCheck();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _drawerAnimationController.dispose();
    // Cleanup music service when leaving the page
    _appState?.cleanup();
    _videoController?.dispose();
    _scrollController.dispose();
    _notificationRequestTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Remove or comment out the lines that reference _appState?.audioService.pause() and _appState?.audioService.playFromStart() to fix linter errors
  }

  @override
  Widget build(BuildContext context) {
    return _buildWithErrorHandling(context);
  }

  Future<void> signOut() async {
    if (_isDisposed) return; // Prevent sign out if widget is disposed

    try {
      // Store AppState reference before any async operation
      final AppState? appState = _appState;
      final navigator = Navigator.of(context);
      final router = GoRouter.of(context);

      // Clean up app state first if available
      if (appState != null) {
        await appState.cleanup();
      }

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear any stored state
      await FFAppState().initializePersistedState();

      // Navigate to sign in page using stored references
      if (!_isDisposed) {
        // First pop any remaining navigation stack
        while (navigator.canPop()) {
          navigator.pop();
        }
        // Then navigate to sign in
        router.go('/');
      }
    } catch (e) {
      print('Error signing out: $e');
      // Don't try to display errors via scaffold messenger to avoid deactivation issues
    }
  }

  Widget _buildWithErrorHandling(BuildContext context) {
    try {
      return LottieBackground(
        child: Scaffold(
          key: scaffoldKey,
          extendBody: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.menu,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                scaffoldKey.currentState?.openDrawer();
                _drawerAnimationController.forward();
              },
            ),
            title: Text(
              'LunaKraft',
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Figtree',
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            actions: [
              // Notification button
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: IconButton(
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () async {
                        // Get all notifications first
                        final notificationsQuery = FirebaseFirestore.instance
                            .collection('notifications')
                            .orderBy('date', descending: true);

                        final notifs = await notificationsQuery.get();

                        // Then filter unread ones client-side
                        final batch = FirebaseFirestore.instance.batch();
                        final currentUserID = currentUserReference?.id ?? '';

                        for (var doc in notifs.docs) {
                          try {
                            final data = doc.data();
                            if (data['is_read'] == false) {
                              // Handle both string and DocumentReference types for made_to field
                              String madeTo = '';
                              if (data['made_to'] is String) {
                                madeTo = data['made_to'] as String? ?? '';
                              } else if (data['made_to'] is DocumentReference) {
                                // If made_to is a DocumentReference, get its ID
                                final madeToRef =
                                    data['made_to'] as DocumentReference?;
                                madeTo = madeToRef?.id ?? '';
                              }

                              final isForCurrentUser =
                                  madeTo == currentUserID ||
                                      (currentUserID.isNotEmpty &&
                                          madeTo.contains(currentUserID)) ||
                                      (madeTo.isNotEmpty &&
                                          currentUserID.contains(madeTo));

                              if (isForCurrentUser) {
                                batch.update(doc.reference, {'is_read': true});
                              }
                            }
                          } catch (e) {
                            print(
                                'Error processing notification ${doc.id}: $e');
                          }
                        }

                        await batch.commit();

                        // Clear iOS badge count after marking notifications as read
                        try {
                          await NotificationService().clearIOSBadgeCount();
                        } catch (e) {
                          print('Error clearing iOS badge count: $e');
                        }

                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const NotificationPageWidget(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;
                              var tween = Tween(begin: begin, end: end).chain(
                                CurveTween(curve: curve),
                              );
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          ),
                        );
                      },
                    ),
                  ),
                  StreamBuilder<List<NotificationsRecord>>(
                    stream: queryNotificationsRecord(
                      queryBuilder: (q) => q.where('made_to',
                          isEqualTo: currentUserReference?.id),
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox.shrink();
                      }

                      // Filter unread notifications client-side
                      final notifications = snapshot.data!;
                      final unreadCount = notifications.where((notification) {
                        try {
                          // Check if this notification is for the current user
                          String madeTo = '';
                          if (notification.madeTo is String) {
                            madeTo = notification.madeTo ?? '';
                          } else if (notification.snapshotData['made_to']
                              is DocumentReference) {
                            // If made_to is a DocumentReference, get its ID
                            final madeToRef = notification
                                .snapshotData['made_to'] as DocumentReference?;
                            madeTo = madeToRef?.id ?? '';
                          }

                          final currentUserID = currentUserReference?.id ?? '';
                          final isForCurrentUser = madeTo == currentUserID ||
                              (currentUserID.isNotEmpty &&
                                  madeTo.contains(currentUserID)) ||
                              (madeTo.isNotEmpty &&
                                  currentUserID.contains(madeTo));

                          return isForCurrentUser && !notification.isRead;
                        } catch (e) {
                          print('Error processing notification: $e');
                          return false;
                        }
                      }).length;

                      if (unreadCount == 0) {
                        return SizedBox.shrink();
                      }

                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          onDrawerChanged: (isOpened) {
            if (isOpened) {
              _drawerAnimationController.forward();
            } else {
              _drawerAnimationController.reverse();
            }
          },
          drawer: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: AnimatedBuilder(
              animation: _drawerAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-280 * (1 - _drawerAnimation.value), 0),
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: Offset(5, 0),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(20)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            border: Border(
                              right: BorderSide(
                                width: 1,
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(20)),
                          ),
                          child: CustomPaint(
                            painter: DrawerPatternPainter(
                              color: Colors.white.withOpacity(0.05),
                            ),
                            child: SafeArea(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User Profile Section
                                  Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                FlutterFlowTheme.of(context)
                                                    .primary,
                                                FlutterFlowTheme.of(context)
                                                    .secondary,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary
                                                        .withOpacity(0.3),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            child: currentUserDocument
                                                        ?.photoUrl?.isEmpty !=
                                                    false
                                                ? Center(
                                                    child: Text(
                                                      currentUserDisplayName
                                                              .isNotEmpty
                                                          ? currentUserDisplayName[
                                                                  0]
                                                              .toUpperCase()
                                                          : '?',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  )
                                                : Image.network(
                                                    currentUserDocument
                                                            ?.photoUrl ??
                                                        '',
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      print(
                                                          'Error loading profile image: $error');
                                                      return Center(
                                                        child: Text(
                                                          currentUserDisplayName
                                                                  .isNotEmpty
                                                              ? currentUserDisplayName[
                                                                      0]
                                                                  .toUpperCase()
                                                              : '?',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 24,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          currentUserDisplayName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          currentUserEmail,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.15),
                                    height: 1,
                                    thickness: 1,
                                  ),
                                  SizedBox(height: 16),
                                  // Navigation Items
                                  Expanded(
                                    child: ListView(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      children: [
                                        _buildDrawerItem(
                                          icon: Icons.person_outline,
                                          title: 'Profile',
                                          onTap: () {
                                            Navigator.pop(context);
                                            context.pushNamed('prof1');
                                          },
                                        ),
                                        _buildDrawerItem(
                                          icon: Icons.psychology_outlined,
                                          title: 'Dream Analysis',
                                          onTap: () {
                                            Navigator.pop(context);
                                            // Direct navigation to Dream Analysis for testing
                                            // context.pushNamed('DreamAnalysis');
                                            
                                            // Enable subscription check
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
                                        ),
                                        _buildDrawerItem(
                                          icon: Icons.bookmark_outline,
                                          title: 'Saved Dreams',
                                          onTap: () {
                                            Navigator.pop(context);
                                            context.pushNamed('SavedPosts');
                                          },
                                        ),
                                        _buildDrawerItem(
                                          icon: Icons.spa_outlined,
                                          title: 'Zen Mode',
                                          onTap: () {
                                            Navigator.pop(context);
                                            context.pushNamed('zen-mode');
                                          },
                                        ),
                                        _buildDrawerItem(
                                          icon: Icons.share_outlined,
                                          title: 'Invite a Friend',
                                          onTap: () async {
                                            Navigator.pop(context);
                                            // Get user's display name for personalized invitation
                                            final displayName =
                                                currentUserDisplayName
                                                        .isNotEmpty
                                                    ? currentUserDisplayName
                                                    : null;

                                            // Show invite friend dialog
                                            await InviteFriendDialog.show(
                                              context,
                                              userName: displayName,
                                            );
                                          },
                                        ),
                                        _buildDrawerItem(
                                          icon: Icons.settings_outlined,
                                          title: 'Settings',
                                          onTap: () {
                                            Navigator.pop(context);
                                            context.pushNamed('Settings');
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.15),
                                    height: 1,
                                    thickness: 1,
                                  ),
                                  _buildDrawerItem(
                                    icon: Icons.logout,
                                    title: 'Sign Out',
                                    onTap: () async {
                                      try {
                                        if (_isDisposed) return;
                                        await AuthUtil.safeSignOut(
                                          context: context,
                                          shouldNavigate: true,
                                          navigateTo: '/',
                                        );
                                      } catch (e) {
                                        print('Error signing out: $e');
                                        // Don't try to display errors via scaffold messenger to avoid deactivation issues
                                      }
                                    },
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
            ),
          ),
          body: AuthUserStreamWidget(
            builder: (context) => Column(
              children: [
                // Dream Fact Widget at the top of the page
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 2),
                  child: AnimatedDreamFactWidget(),
                ),
                // Feed Section with Latest Post included in the feed
                Expanded(
                  child: const _HomeFeedContent(),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error with SpaceBackground: $e');
      return _buildErrorFallback(context);
    }
  }

  Widget _buildErrorFallback(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      extendBody: true,
      backgroundColor: Color(0xFF050A30),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          'LunaKraft',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Figtree',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      child: Center(
                        child: Text(
                          currentUserDisplayName.isNotEmpty
                              ? currentUserDisplayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      currentUserDisplayName,
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      currentUserEmail,
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: FlutterFlowTheme.of(context).secondaryText,
                height: 1,
                thickness: 1,
              ),
              SizedBox(height: 16),
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        context.pushNamed('prof1');
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.psychology_outlined,
                      title: 'Dream Analysis',
                      onTap: () {
                        Navigator.pop(context);
                        // Direct navigation to Dream Analysis for testing
                        // context.pushNamed('DreamAnalysis');
                        
                        // Enable subscription check
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
                    ),
                    _buildDrawerItem(
                      icon: Icons.bookmark_outline,
                      title: 'Saved Dreams',
                      onTap: () {
                        Navigator.pop(context);
                        context.pushNamed('SavedPosts');
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.spa_outlined,
                      title: 'Zen Mode',
                      onTap: () {
                        Navigator.pop(context);
                        context.pushNamed('zen-mode');
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.share_outlined,
                      title: 'Invite a Friend',
                      onTap: () async {
                        Navigator.pop(context);
                        // Get user's display name for personalized invitation
                        final displayName = currentUserDisplayName.isNotEmpty
                            ? currentUserDisplayName
                            : null;

                        // Show invite friend dialog
                        await InviteFriendDialog.show(
                          context,
                          userName: displayName,
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        context.pushNamed('Settings');
                      },
                    ),
                  ],
                ),
              ),
              Divider(
                color: FlutterFlowTheme.of(context).secondaryText,
                height: 1,
                thickness: 1,
              ),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Sign Out',
                onTap: () async {
                  try {
                    if (_isDisposed) return;
                    await AuthUtil.safeSignOut(
                      context: context,
                      shouldNavigate: true,
                      navigateTo: '/',
                    );
                  } catch (e) {
                    print('Error signing out: $e');
                    // Don't try to display errors via scaffold messenger to avoid deactivation issues
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Text(
          'Something went wrong. Please try again.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (title == 'Sign Out') {
            // Close the drawer first
            Navigator.pop(context);
            // Then show a confirmation dialog
            showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.5),
              builder: (dialogContext) => TweenAnimationBuilder<double>(
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
                                  style:
                                      FlutterFlowTheme.of(context).bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            side: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
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
                                          Navigator.pop(
                                              dialogContext); // Close dialog
                                          if (_isDisposed) return;

                                          try {
                                            await AuthUtil.safeSignOut(
                                              context: context,
                                              shouldNavigate: true,
                                              navigateTo: '/',
                                            );
                                          } catch (e) {
                                            print('Error signing out: $e');
                                            // Don't show snackbar errors here to avoid widget deactivation issues
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              FlutterFlowTheme.of(context)
                                                  .error
                                                  .withOpacity(0.8),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12),
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
              ),
            );
          } else {
            onTap();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, UserRecord user) {
    final photoUrl = user.photoUrl ?? '';
    final displayName = user.displayName ?? '';
    final firstLetter = displayName.isNotEmpty ? displayName[0] : '?';
    final avatarUrl =
        'https://ui-avatars.com/api/?name=$firstLetter&background=random';
    final imageUrl =
        photoUrl.isEmpty || photoUrl.contains('firebasestorage.googleapis.com')
            ? avatarUrl
            : photoUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              FlutterFlowTheme.of(context).primary,
              FlutterFlowTheme.of(context).secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
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
            : Center(
                child: Text(
                  firstLetter.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPostBackground(PostsRecord post, BuildContext context) {
    print('Building background for post: ${post.title}');
    print('Background path: ${post.videoBackgroundUrl}');
    print('Background opacity: ${post.videoBackgroundOpacity}');

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

  void _onScroll() {
    // Only update state if absolutely needed, and don't perform any actions that would affect scroll position
    if (_scrollController.hasClients && mounted) {
      final currentOffset = _scrollController.offset;
      final newIsScrolled = currentOffset > 50;
      final newShowHeaderShadow = currentOffset > 10;
      
      // Only call setState if values actually changed to prevent unnecessary rebuilds
      if (newIsScrolled != _isScrolled || newShowHeaderShadow != _showHeaderShadow) {
        setState(() {
          _isScrolled = newIsScrolled;
          _showHeaderShadow = newShowHeaderShadow;
        });
      }
    }
  }

  // Schedule notification permission check after a delay
  void _scheduleNotificationPermissionCheck() {
    // Check permissions after a longer delay to give users time to experience the app
    _notificationRequestTimer = Timer(Duration(seconds: 5), () {
      _checkNotificationPermission();
    });
  }

  // Check if notification permission should be requested
  Future<void> _checkNotificationPermission() async {
    if (_checkingNotificationPermission) return;
    _checkingNotificationPermission = true;

    try {
      // Ensure user is logged in
      if (currentUser?.uid == null) {
        _checkingNotificationPermission = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final permissionAsked = prefs.getBool('notification_permission_asked') ?? false;
      final permissionGranted = prefs.getBool('notification_permission_granted') ?? false;

      // If permission is already granted, no need to proceed
      if (permissionGranted) {
        _checkingNotificationPermission = false;
        return;
      }

      // If never asked before, ask now after the user has had some time to use the app
      if (!permissionAsked) {
        // Use post frame callback to avoid interfering with current build
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          print('Requesting notification permission after user has signed in');
          final hasPermission = await NotificationService().requestPermission();
          final currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
          await prefs.setInt('notification_permission_last_asked_time', currentTimeMillis);
          await prefs.setBool('notification_permission_asked', true);
          await prefs.setBool('notification_permission_granted', hasPermission);
          print('Notification permission status after request: $hasPermission');
        });
        _checkingNotificationPermission = false;
        return;
      }

      // Check if we should ask again (only if asked more than a week ago)
      final lastAskedTimeMillis = prefs.getInt('notification_permission_last_asked_time') ?? 0;
      final currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
      final weekInMillis = 7 * 24 * 60 * 60 * 1000; // One week in milliseconds

      // If already asked recently, don't ask again
      if (permissionAsked && (currentTimeMillis - lastAskedTimeMillis < weekInMillis)) {
        _checkingNotificationPermission = false;
        return;
      }

      // If it's been more than a week since last asked, ask again
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        print('Re-requesting notification permission after one week');
        final hasPermission = await NotificationService().requestPermission();
        await prefs.setInt('notification_permission_last_asked_time', currentTimeMillis);
        await prefs.setBool('notification_permission_asked', true);
        await prefs.setBool('notification_permission_granted', hasPermission);
        print('Notification permission status after re-request: $hasPermission');
      });
    } catch (e) {
      print('Error checking notification permission: $e');
    } finally {
      _checkingNotificationPermission = false;
    }
  }
}

class DrawerPatternPainter extends CustomPainter {
  final Color color;

  DrawerPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < size.width; i += 20) {
      for (var j = 0; j < size.height; j += 20) {
        canvas.drawCircle(
          Offset(i.toDouble(), j.toDouble()),
          1,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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

class PostItemWidget extends StatelessWidget {
  final PostsRecord post;
  final UserRecord user;
  final VoidCallback onLike;
  final VoidCallback onSave;

  const PostItemWidget({
    Key? key,
    required this.post,
    required this.user,
    required this.onLike,
    required this.onSave,
  }) : super(key: key);

  // Stream to get comment count for the post
  Stream<int> _getCommentCountStream() {
    return FirebaseFirestore.instance
        .collection('comments')
        .where('postref', isEqualTo: post.reference)
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
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PostBackgroundWidget(
              imagePath: post.videoBackgroundUrl,
              opacity: post.videoBackgroundOpacity ?? 0.75,
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
              // User info row
              Row(
                children: [
                  _buildUserAvatar(context, user),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          util.dateTimeFormat('relative', post.date!),
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
              // Post content
              Text(
                post.title,
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Outfit',
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 4),
              Text(
                post.dream,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Figtree',
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Interaction buttons
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedLikeButton(
                    isLiked: post.likes.contains(currentUserReference),
                    likeCount: post.likes.length,
                    iconSize: 28,
                    activeColor: FlutterFlowTheme.of(context).primary,
                    inactiveColor: Colors.white.withOpacity(0.8),
                    onTap: () async {
                      final hasLiked =
                          post.likes.contains(currentUserReference);

                      // Toggle the like state
                      await post.reference.update({
                        'likes': hasLiked
                            ? FieldValue.arrayRemove([currentUserReference])
                            : FieldValue.arrayUnion([currentUserReference]),
                      });

                      // Call the original onLike callback
                      onLike();
                    },
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
                          print(
                              'Comment icon tapped in PostItemWidget for post: ${post.reference.id}');
                          print(
                              'Navigating to DetailedPost with showComments=true');

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
                            showComments: true,
                          );
                        },
                      );
                    },
                  ),
                  _buildInteractionButton(
                    context: context,
                    icon: post.postSavedBy.contains(currentUserReference)
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                    count: post.postSavedBy.length,
                    onTap: () async {
                      final isSaved =
                          post.postSavedBy.contains(currentUserReference);

                      // Toggle the save state
                      await post.reference.update({
                        'Post_saved_by': isSaved
                            ? FieldValue.arrayRemove([currentUserReference])
                            : FieldValue.arrayUnion([currentUserReference]),
                      });

                      // Call the original onSave callback
                      onSave();

                      // Show the save popup
                      SavePostPopup.showSavedPopup(context, isSaved: !isSaved);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.ios_share,
                      color: Colors.white.withOpacity(0.8),
                      size: 28,
                    ),
                    onPressed: () async {
                      // Get the user record for the poster
                      final UserRecord? posterUser =
                          await UserRecord.getDocumentOnce(post.poster!);
                      if (posterUser != null) {
                        ShareOptionsDialog.show(context, post, posterUser);
                      }
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
    );
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
    final avatarUrl =
        'https://ui-avatars.com/api/?name=$firstLetter&background=random';
    final imageUrl =
        photoUrl.isEmpty || photoUrl.contains('firebasestorage.googleapis.com')
            ? avatarUrl
            : photoUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              FlutterFlowTheme.of(context).primary,
              FlutterFlowTheme.of(context).secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
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
            : Center(
                child: Text(
                  firstLetter.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}
