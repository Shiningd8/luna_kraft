import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp;
import '/components/emptysaved_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:timeago/timeago.dart' as timeago;
import '/components/animated_like_button.dart';
import '/components/save_post_popup.dart';
import '/widgets/space_background.dart';
import 'package:luna_kraft/components/standardized_post_item.dart';
import 'package:provider/provider.dart';
import '/services/app_state.dart';
import '/widgets/lottie_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';

class SavedPostsWidget extends StatefulWidget {
  const SavedPostsWidget({super.key});

  static String routeName = 'SavedPosts';
  static String routePath = '/savedPosts';

  @override
  State<SavedPostsWidget> createState() => _SavedPostsWidgetState();
}

class _SavedPostsWidgetState extends State<SavedPostsWidget>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _fadeController;
  final _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                automaticallyImplyLeading: true,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.05),
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
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 26.0,
                  ).animate().shimmer(delay: 2.seconds, duration: 1.seconds),
                  onPressed: () async {
                    context.pop();
                  },
                ),
                title: Text(
                  'Saved Dreams',
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                        fontFamily: 'Outfit',
                        letterSpacing: 0.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ).animate().fade(duration: 400.ms).slideX(
                    begin: 0.2,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutQuad),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
                    ).animate().shimmer(delay: 4.seconds, duration: 1.seconds),
                    onPressed: () {
                      _showInfoDialog(context);
                    },
                  ),
                ],
                centerTitle: true,
                elevation: 0.0,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeController,
            child: StreamBuilder<List<PostsRecord>>(
              stream: queryPostsRecord(
                queryBuilder: (postsRecord) => postsRecord
                    .where('Post_saved_by', arrayContains: currentUserReference)
                    .limit(50),
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error in saved posts stream: ${snapshot.error}');
                  print('Error type: ${snapshot.error.runtimeType}');
                  if (snapshot.error is Error) {
                    final error = snapshot.error as Error;
                    print('Error stack trace: ${error.stackTrace}');
                  }
                  if (snapshot.error.toString().contains('requires an index')) {
                    print(
                        'Index needs to be created. Please create the composite index in Firebase Console.');
                  }
                  return Center(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ).animate().fade(duration: 400.ms).scale(),
                          SizedBox(height: 16),
                          Text(
                            'Error loading saved dreams',
                            style: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  fontFamily: 'Outfit',
                                  color: Colors.white,
                                ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please try again later',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Figtree',
                                  color: Colors.white.withOpacity(0.7),
                                ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  FlutterFlowTheme.of(context).primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                            ),
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fade(duration: 300.ms)
                        .scale(begin: Offset(0.95, 0.95)),
                  );
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            FlutterFlowTheme.of(context).primary,
                          ),
                        ).animate().fade(duration: 600.ms).scale(
                              duration: 1500.ms,
                              curve: Curves.easeInOut,
                              begin: Offset(0.95, 0.95),
                              end: Offset(1.05, 1.05),
                            ),
                        SizedBox(height: 16),
                        Text(
                          'Loading saved dreams...',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white,
                                  ),
                        )
                            .animate()
                            .fade(duration: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  );
                }

                final posts = snapshot.data!;

                // Filter out posts with missing poster references
                final validPosts =
                    posts.where((post) => post.poster != null).toList();

                if (validPosts.isEmpty) {
                  return EmptysavedWidget();
                }

                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      color: Colors.white,
                      strokeWidth: 3,
                      displacement: 50,
                      child: AnimationLimiter(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: validPosts.length,
                          itemBuilder: (context, index) {
                            final post = validPosts[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 30.0,
                                child: FadeInAnimation(
                                  child: StreamBuilder<UserRecord>(
                                    stream:
                                        UserRecord.getDocument(post.poster!),
                                    builder: (context, userSnapshot) {
                                      // Handle error case - user document doesn't exist or other error
                                      if (userSnapshot.hasError) {
                                        print(
                                            'Error loading user for post ${post.reference.id}: ${userSnapshot.error}');
                                        return SizedBox(); // Don't display the post if we can't load the user
                                      }

                                      if (!userSnapshot.hasData) {
                                        // Instead of showing a loading indicator, we'll check if this might be a deleted user
                                        if (userSnapshot.connectionState ==
                                            ConnectionState.done) {
                                          // If the connection is done but we have no data, the user probably doesn't exist
                                          return SizedBox(); // Don't display posts from non-existent users
                                        }

                                        // Only show brief loading if we're still waiting for a response
                                        return _buildLoadingPostCard();
                                      }

                                      final user = userSnapshot.data!;

                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 16),
                                        child: StandardizedPostItem(
                                          post: post,
                                          user: user,
                                          animateEntry:
                                              false, // We're using staggered animations instead
                                          animationIndex: index,
                                          showDeleteOption: true,
                                          onDelete: () {
                                            _confirmUnsavePost(context, post);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Scroll to top button
                    if (_showScrollToTop)
                      Positioned(
                        right: 16,
                        bottom: 24,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.9),
                          elevation: 6,
                          onPressed: () {
                            _scrollController.animateTo(
                              0,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                            );
                          },
                          child: Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                          ),
                        )
                            .animate()
                            .fade(duration: 200.ms)
                            .scale(begin: Offset(0.8, 0.8)),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Loading post card
  Widget _buildLoadingPostCard() {
    return Container(
      height: 180,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            FlutterFlowTheme.of(context).primary,
          ),
        ),
      ),
    ).animate().shimmer(
          duration: 1.5.seconds,
          delay: 200.ms,
        );
  }

  // Show info dialog
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                color: FlutterFlowTheme.of(context).primary,
                size: 40,
              ).animate().fade().scale(),
              SizedBox(height: 16),
              Text(
                'Saved Dreams',
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                    ),
              ),
              SizedBox(height: 12),
              Text(
                'All dreams you\'ve saved will appear here. Tap and hold a dream card to quickly unsave it.',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Figtree',
                      color: Colors.white.withOpacity(0.9),
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Got it',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ).animate().fade().scale(begin: Offset(0.95, 0.95)),
    );
  }

  // Confirm unsave post dialog
  void _confirmUnsavePost(BuildContext context, PostsRecord post) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark_remove,
                color: FlutterFlowTheme.of(context).primary,
                size: 40,
              ).animate().fade().scale(),
              SizedBox(height: 16),
              Text(
                'Unsave Dream?',
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                    ),
              ),
              SizedBox(height: 12),
              Text(
                'This dream will be removed from your saved collection.',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Figtree',
                      color: Colors.white.withOpacity(0.9),
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Remove post from saved
                      await post.reference.update({
                        'Post_saved_by':
                            FieldValue.arrayRemove([currentUserReference]),
                      });
                      // Show feedback
                      SavePostPopup.showSavedPopup(context, isSaved: false);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'Unsave',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fade().scale(begin: Offset(0.95, 0.95)),
    );
  }
}
