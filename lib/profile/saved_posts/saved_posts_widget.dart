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

class SavedPostsWidget extends StatefulWidget {
  const SavedPostsWidget({super.key});

  static String routeName = 'SavedPosts';
  static String routePath = '/savedPosts';

  @override
  State<SavedPostsWidget> createState() => _SavedPostsWidgetState();
}

class _SavedPostsWidgetState extends State<SavedPostsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return LottieBackground(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Saved Dreams',
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  fontFamily: 'Outfit',
                  letterSpacing: 0.0,
                  color: Colors.white,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 0.0,
        ),
        body: StreamBuilder<List<PostsRecord>>(
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
                      'Error loading saved dreams',
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Figtree',
                            color: Colors.white.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading saved dreams...',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Figtree',
                            color: Colors.white,
                          ),
                    ),
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

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: validPosts.length,
                itemBuilder: (context, index) {
                  final post = validPosts[index];
                  return StreamBuilder<UserRecord>(
                    stream: UserRecord.getDocument(post.poster!),
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
                        return Container(
                          height: 200,
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground
                                .withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final user = userSnapshot.data!;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: StandardizedPostItem(
                          post: post,
                          user: user,
                          animateEntry: true,
                          animationIndex: index,
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Icon(
          icon,
          color: isActive
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).secondaryText,
          size: 28,
        ),
      ),
    );
  }
}
