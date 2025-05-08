import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp, dateTimeFormat;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart' hide createModel;
import '/utils/serialization_helpers.dart';
import '/index.dart';
import '/home/detailedpost/detailedpost_widget.dart' as detailedpost;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'dart:ui';
import 'explore_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:luna_kraft/components/standardized_post_item.dart';
import '/widgets/lottie_background.dart';
export 'explore_model.dart';

class ExploreWidget extends StatefulWidget {
  const ExploreWidget({super.key});

  static String routeName = 'Explore';
  static String routePath = '/explore';

  @override
  State<ExploreWidget> createState() => _ExploreWidgetState();
}

class _ExploreWidgetState extends State<ExploreWidget> {
  late ExploreModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isNavigating = false;
  bool _isDisposed = false;
  final _searchController = TextEditingController();
  List<UserRecord> _exploreUserRecordList = [];
  List<UserRecord> _userSearchResults = [];
  List<PostsRecord> _postSearchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  bool _isSearchingTags = false; // Toggle between user search and tag search

  @override
  void initState() {
    super.initState();
    _model = detailedpost.createModel(context, () => ExploreModel());
    _model.searchBarTextController ??= _searchController;

    _searchController.addListener(() {
      if (mounted) {
        _onSearchChanged(_searchController.text);
      }
    });

    print('ExploreWidget initialized');

    // Check if UserRecord collection exists
    UserRecord.collection.limit(1).get().then((snapshot) {
      print('UserRecord collection exists: ${snapshot.docs.isNotEmpty}');
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        if (data != null) {
          final dataMap = data as Map<String, dynamic>;
          print(
              'First document has user_name: ${dataMap.containsKey('user_name')}');
        } else {
          print('First document data is null');
        }
      }
    }).catchError((error) {
      print('Error checking UserRecord collection: $error');
    });

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _isSearching = false;
      _postSearchResults = [];
      safeSetState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        safeSetState(() {});
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.removeListener(() {});
    _searchController.dispose();
    _debounceTimer?.cancel();
    _model.dispose();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (!_isDisposed && !_isNavigating && mounted) {
      setState(fn);
    }
  }

  Future<void> _handleNavigation(DocumentReference userRef) async {
    if (_isNavigating || _isDisposed) return;

    _isNavigating = true;

    try {
      if (mounted) {
        if (userRef == currentUserReference) {
          // Navigate to own profile page
          await context.pushNamed('prof1');
        } else {
          // Navigate to other user's profile
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

  void _onSearchChanged(String query) {
    if (_isDisposed) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        _isSearching = query.isNotEmpty;
        if (query.isEmpty) {
          _userSearchResults = [];
          _postSearchResults = [];
        } else if (!_isSearchingTags) {
          // Search for users
          final lowercaseQuery = query.toLowerCase();
          _userSearchResults = _exploreUserRecordList.where((user) {
            final userName = (user.userName ?? '').toLowerCase();
            final displayName = (user.displayName ?? '').toLowerCase();
            return userName.contains(lowercaseQuery) ||
                displayName.contains(lowercaseQuery);
          }).toList();
        } else {
          // For tag search, we'll trigger a rebuild which will use the StreamBuilder
          // for post filtering
          print('Searching for tag: ${query.trim()}');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserRecord>>(
      stream: queryUserRecord(
        queryBuilder: (userRecord) =>
            userRecord.orderBy('user_name', descending: false),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorScaffold(
              'Unable to load data. Please try again later.');
        }

        if (!snapshot.hasData) {
          return _buildLoadingScaffold();
        }

        try {
          _exploreUserRecordList = snapshot.data!;
          List<UserRecord> exploreUserRecordList = snapshot.data!;

          return WillPopScope(
            onWillPop: () async {
              if (_isNavigating) return false;
              return true;
            },
            child: LottieBackground(
              child: Scaffold(
                key: scaffoldKey,
                extendBody: true,
                extendBodyBehindAppBar: true,
                backgroundColor: Colors.transparent,
                body: Stack(
                  children: [
                    // Content
                    Column(
                      children: [
                        // Glassmorphic App Bar
                        ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: SafeArea(
                                bottom: false,
                                child: Container(
                                  height: 48,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Explore',
                                        style: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .override(
                                              fontFamily: 'Outfit',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Search Bar with Glassmorphism
                        Container(
                          margin: EdgeInsets.only(bottom: 4),
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // Animated Search mode toggle
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 15, sigmaY: 15),
                                    child: Container(
                                      width: 350,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.25),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.15),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.25),
                                            blurRadius: 20,
                                            spreadRadius: -5,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(28),
                                        child: Stack(
                                          children: [
                                            // Animated sliding indicator with glow
                                            AnimatedPositioned(
                                              duration:
                                                  Duration(milliseconds: 400),
                                              curve: Curves.easeOutBack,
                                              left: _isSearchingTags ? 175 : 0,
                                              top: 0,
                                              bottom: 0,
                                              width: 175,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(28),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0xFF7963DF)
                                                          .withOpacity(0.8),
                                                      blurRadius: 25,
                                                      spreadRadius: -5,
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(28),
                                                  child: Stack(
                                                    children: [
                                                      // Animated gradient background
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(28),
                                                          gradient:
                                                              LinearGradient(
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                            colors: [
                                                              Color(0xFF8A74F9),
                                                              Color(0xFF6953CF),
                                                            ],
                                                          ),
                                                        ),
                                                      ),

                                                      // Lottie animation overlay with clip to prevent overflow
                                                      Positioned.fill(
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(28),
                                                          child: Lottie.asset(
                                                            'assets/jsons/astro.json',
                                                            fit: BoxFit.cover,
                                                            alignment: Alignment
                                                                .center,
                                                          ),
                                                        ),
                                                      ),

                                                      // Shimmer effect with improved width
                                                      Positioned.fill(
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(28),
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            child: Stack(
                                                              children: [
                                                                // Wider shimmer that animates across the full width
                                                                Positioned(
                                                                  left: -350,
                                                                  top: 0,
                                                                  bottom: 0,
                                                                  width: 700,
                                                                  child:
                                                                      TweenAnimationBuilder(
                                                                    tween: Tween<
                                                                            double>(
                                                                        begin:
                                                                            -350,
                                                                        end:
                                                                            350),
                                                                    duration: Duration(
                                                                        milliseconds:
                                                                            2500),
                                                                    curve: Curves
                                                                        .easeInOut,
                                                                    builder: (context,
                                                                        value,
                                                                        child) {
                                                                      return Transform
                                                                          .translate(
                                                                        offset: Offset(
                                                                            value,
                                                                            0),
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            gradient:
                                                                                LinearGradient(
                                                                              begin: Alignment.centerLeft,
                                                                              end: Alignment.centerRight,
                                                                              colors: [
                                                                                Colors.white.withOpacity(0),
                                                                                Colors.white.withOpacity(0.3),
                                                                                Colors.white.withOpacity(0),
                                                                              ],
                                                                              stops: [
                                                                                0.0,
                                                                                0.5,
                                                                                1.0
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                    onEnd: () {
                                                                      if (mounted) {
                                                                        setState(
                                                                            () {
                                                                          // Trigger rebuild to restart animation
                                                                        });
                                                                      }
                                                                    },
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Toggle buttons
                                            Row(
                                              children: [
                                                // Users button
                                                Expanded(
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () {
                                                        if (_isSearchingTags) {
                                                          HapticFeedback
                                                              .selectionClick();
                                                          setState(() {
                                                            _isSearchingTags =
                                                                false;
                                                            _searchController
                                                                .clear();
                                                          });
                                                        }
                                                      },
                                                      splashColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      child: AnimatedScale(
                                                        scale: !_isSearchingTags
                                                            ? 1.1
                                                            : 1.0,
                                                        duration: Duration(
                                                            milliseconds: 200),
                                                        child: Center(
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons.person,
                                                                size: 24,
                                                                color: !_isSearchingTags
                                                                    ? FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText,
                                                              ),
                                                              SizedBox(
                                                                  width: 8),
                                                              AnimatedDefaultTextStyle(
                                                                duration: Duration(
                                                                    milliseconds:
                                                                        200),
                                                                style:
                                                                    TextStyle(
                                                                  color: !_isSearchingTags
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                  fontWeight: !_isSearchingTags
                                                                      ? FontWeight
                                                                          .w600
                                                                      : FontWeight
                                                                          .normal,
                                                                  fontSize:
                                                                      !_isSearchingTags
                                                                          ? 17
                                                                          : 16,
                                                                ),
                                                                child: Text(
                                                                    'Users'),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // Tags button
                                                Expanded(
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () {
                                                        if (!_isSearchingTags) {
                                                          HapticFeedback
                                                              .selectionClick();
                                                          setState(() {
                                                            _isSearchingTags =
                                                                true;
                                                            _searchController
                                                                .clear();
                                                          });
                                                        }
                                                      },
                                                      splashColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      child: AnimatedScale(
                                                        scale: _isSearchingTags
                                                            ? 1.1
                                                            : 1.0,
                                                        duration: Duration(
                                                            milliseconds: 200),
                                                        child: Center(
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons.tag,
                                                                size: 24,
                                                                color: _isSearchingTags
                                                                    ? FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText,
                                                              ),
                                                              SizedBox(
                                                                  width: 8),
                                                              AnimatedDefaultTextStyle(
                                                                duration: Duration(
                                                                    milliseconds:
                                                                        200),
                                                                style:
                                                                    TextStyle(
                                                                  color: _isSearchingTags
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                  fontWeight: _isSearchingTags
                                                                      ? FontWeight
                                                                          .w600
                                                                      : FontWeight
                                                                          .normal,
                                                                  fontSize:
                                                                      _isSearchingTags
                                                                          ? 17
                                                                          : 16,
                                                                ),
                                                                child: Text(
                                                                    'Tags'),
                                                              ),
                                                            ],
                                                          ),
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
                              SizedBox(height: 8),
                              // Search bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .primary
                                            .withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 15,
                                          spreadRadius: -5,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: TextFormField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: _isSearchingTags
                                            ? 'Search posts by tags...'
                                            : 'Search users...',
                                        hintStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Figtree',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 16),
                                        prefixIcon: AnimatedContainer(
                                          duration: Duration(milliseconds: 300),
                                          padding: EdgeInsets.all(8),
                                          child: Icon(
                                            _isSearchingTags
                                                ? Icons.tag
                                                : Icons.search,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            size: 22,
                                          ),
                                        ),
                                        suffixIcon: _searchController
                                                .text.isNotEmpty
                                            ? TweenAnimationBuilder<double>(
                                                tween: Tween<double>(
                                                    begin: 0.0, end: 1.0),
                                                duration:
                                                    Duration(milliseconds: 200),
                                                builder:
                                                    (context, value, child) {
                                                  return Opacity(
                                                    opacity: value,
                                                    child: Transform.scale(
                                                      scale:
                                                          0.7 + (value * 0.3),
                                                      child: IconButton(
                                                        onPressed: () {
                                                          _searchController
                                                              .clear();
                                                        },
                                                        icon: Icon(
                                                          Icons.clear_rounded,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          size: 22,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        // Existing behavior
                                      },
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Figtree',
                                            fontSize: 16,
                                          ),
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Main Content
                        Expanded(
                          child: _isSearching
                              ? _buildSearchResults()
                              : _buildDefaultContent(exploreUserRecordList),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        } catch (e, stackTrace) {
          print('Error processing user data: $e');
          print('StackTrace: $stackTrace');
          return _buildErrorScaffold('Error processing data');
        }
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isSearchingTags ? Icons.tag : Icons.search,
              color: FlutterFlowTheme.of(context).secondaryText,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              _isSearchingTags ? 'Enter a tag to search' : 'Search for users',
              style: FlutterFlowTheme.of(context).titleMedium,
            ),
            SizedBox(height: 4),
            Text(
              _isSearchingTags
                  ? 'Try searching for "lucid", "nightmare", etc.'
                  : 'Enter a name or username to find people',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Figtree',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // User search mode
    if (!_isSearchingTags) {
      if (_userSearchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'No users found',
                style: FlutterFlowTheme.of(context).titleMedium,
              ),
              SizedBox(height: 4),
              Text(
                'Try another search term',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Figtree',
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _userSearchResults.length,
        itemBuilder: (context, index) {
          final userItem = _userSearchResults[index];
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: _buildUserCard(userItem),
          );
        },
      );
    }

    // Tag search mode
    return StreamBuilder<List<PostsRecord>>(
      stream: queryPostsRecord(
        queryBuilder: (postsRecord) =>
            postsRecord.orderBy('date', descending: true),
      ),
      builder: (context, snapshot) {
        // Add error handling
        if (snapshot.hasError) {
          print('Error in tag search: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: FlutterFlowTheme.of(context).error,
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  'Error searching posts',
                  style: FlutterFlowTheme.of(context).titleMedium,
                ),
                SizedBox(height: 4),
                Text(
                  'Please try again',
                  style: FlutterFlowTheme.of(context).bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  'No posts found',
                  style: FlutterFlowTheme.of(context).titleMedium,
                ),
                SizedBox(height: 4),
                Text(
                  'Try again later',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Figtree',
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Print all post tags for debugging
        for (var post in snapshot.data!) {
          print('Post: ${post.title}, Tags: ${post.tags}');
        }

        final searchText = _searchController.text.toLowerCase().trim();
        final filteredPosts = snapshot.data!.where((post) {
          try {
            // Skip posts with no poster reference
            if (post.poster == null) {
              return false;
            }

            // Skip posts from private accounts that the user doesn't follow
            final posterRef = post.poster!;

            // Check if post creator has a private account
            bool isPrivateAccount = false;
            bool isFollowingUser = false;

            // Find the user in our cached user list
            for (var user in _exploreUserRecordList) {
              if (user.reference == posterRef) {
                isPrivateAccount = user.isPrivate;
                isFollowingUser = currentUserDocument?.followingUsers
                        .contains(user.reference) ??
                    false;
                break;
              }
            }

            // Skip posts from private accounts that the user doesn't follow
            if (isPrivateAccount && !isFollowingUser) {
              return false;
            }

            // Safely handle potentially null or empty tags
            if (post.tags == null || post.tags.isEmpty) {
              return false;
            }

            // Match posts that have the tag as a whole word or part of a tag
            final postTags = post.tags.toLowerCase();

            // Debug prints
            print('Searching for "$searchText" in post tags: "$postTags"');

            // Try different matching strategies:
            // 1. Exact match
            if (postTags == searchText) {
              print('Exact match found!');
              return true;
            }

            // 2. Contains match
            if (postTags.contains(searchText)) {
              print('Contains match found!');
              return true;
            }

            // 3. Word boundary match (if tags are comma-separated)
            if (postTags
                .split(',')
                .map((tag) => tag.trim())
                .any((tag) => tag.contains(searchText))) {
              print('Tag list match found!');
              return true;
            }

            return false;
          } catch (e) {
            print('Error filtering post: $e');
            return false;
          }
        }).toList();

        print(
            'Found ${filteredPosts.length} matching posts for tag "$searchText"');

        if (filteredPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  'No posts found with tag: "$searchText"',
                  style: FlutterFlowTheme.of(context).titleMedium,
                ),
                SizedBox(height: 4),
                Text(
                  'Try another tag or check your spelling',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Figtree',
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Tag header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                    FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        FlutterFlowTheme.of(context).primary.withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: -5,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.tag,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Posts tagged with ',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Figtree',
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                      ),
                                ),
                                Text(
                                  '"${_searchController.text}"',
                                  style: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        fontFamily: 'Outfit',
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Text(
                              'Showing ${filteredPosts.length} matching results',
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
                      ),
                      SizedBox(width: 4),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${filteredPosts.length}',
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    fontFamily: 'Outfit',
                                    color: FlutterFlowTheme.of(context).primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // List of posts
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  final post = filteredPosts[index];
                  // Skip rendering posts with missing poster references
                  if (post.poster == null) {
                    return SizedBox(); // Return empty widget for invalid posts
                  }

                  // Double-check that post isn't from a private account that user doesn't follow
                  bool isPrivateAccount = false;
                  bool isFollowingUser = false;

                  // Find the user in our cached user list
                  for (var user in _exploreUserRecordList) {
                    if (user.reference == post.poster) {
                      isPrivateAccount = user.isPrivate;
                      isFollowingUser = currentUserDocument?.followingUsers
                              .contains(user.reference) ??
                          false;
                      break;
                    }
                  }

                  // Skip posts from private accounts that the user doesn't follow
                  if (isPrivateAccount && !isFollowingUser) {
                    return SizedBox(); // Don't display posts from private accounts
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: _buildPostCard(post),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultContent(List<UserRecord> exploreUserRecordList) {
    return CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        // Popular Users Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context)
                          .primary
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Popular Users',
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: FlutterFlowTheme.of(context).primary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Popular Users List
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              // Filter out blocked users and current user
              final filteredUsers = exploreUserRecordList
                  .where((user) =>
                      user.reference != currentUserReference &&
                      !(currentUserDocument?.blockedUsers
                              .contains(user.reference) ??
                          false))
                  .toList();

              final uservariable = filteredUsers
                  .map((user) => MapEntry(
                        user,
                        exploreUserRecordList
                            .where((otherUser) => otherUser.followingUsers
                                .contains(user.reference))
                            .length,
                      ))
                  .toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final sortedUsers =
                  uservariable.map((e) => e.key).take(5).toList();

              return ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: sortedUsers.length,
                itemBuilder: (context, index) {
                  final user = sortedUsers[index];
                  return Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                    child: _buildPopularUserCard(
                      user,
                      uservariable
                          .firstWhere((entry) => entry.key == user)
                          .value,
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Recent Posts Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context)
                          .primary
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.article_rounded,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Recent Posts',
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: FlutterFlowTheme.of(context).primary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Posts List
        SliverPadding(
          padding: EdgeInsets.only(bottom: 80),
          sliver: StreamBuilder<List<PostsRecord>>(
            stream: queryPostsRecord(
              queryBuilder: (postsRecord) =>
                  postsRecord.where('poster', whereIn: [
                ...exploreUserRecordList
                    .where((user) =>
                        !user.isPrivate &&
                        !(currentUserDocument?.blockedUsers
                                .contains(user.reference) ??
                            false) &&
                        !(currentUserDocument?.followingUsers
                                .contains(user.reference) ??
                            false))
                    .map((user) => user.reference)
                    .toList(),
              ]).orderBy('date', descending: true),
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                  ),
                );
              }

              List<PostsRecord> posts = snapshot.data!;

              if (posts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No posts found',
                            style: FlutterFlowTheme.of(context).titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Filter out posts that don't have a valid poster reference
              final validPosts =
                  posts.where((post) => post.poster != null).toList();

              if (validPosts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No valid posts found',
                            style: FlutterFlowTheme.of(context).titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = validPosts[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _buildPostCard(post),
                    );
                  },
                  childCount: validPosts.length,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularUserCard(UserRecord user, int followerCount) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNavigation(user.reference),
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context)
                    .secondaryBackground
                    .withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: -5,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Animated avatar with glow effect
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: FlutterFlowTheme.of(context)
                                  .primary
                                  .withOpacity(0.4 * value),
                              blurRadius: 15 * value,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 2,
                                ),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(
                                    (user.photoUrl ?? '').isNotEmpty
                                        ? ((user.photoUrl ?? '').contains('?')
                                            ? user.photoUrl ?? ''
                                            : (user.photoUrl ?? '') +
                                                '?alt=media')
                                        : 'https://ui-avatars.com/api/?name=${(user.displayName ?? '').isNotEmpty ? (user.displayName ?? '')[0] : "?"}&background=random',
                                  ),
                                ),
                              ),
                            ),

                            // Subtle shimmer effect
                            Positioned.fill(
                              child: ClipOval(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment(-1.0 + (value * 2), 0),
                                      end: Alignment(0, 1),
                                      colors: [
                                        Colors.white.withOpacity(0),
                                        Colors.white.withOpacity(0.2 * value),
                                        Colors.white.withOpacity(0),
                                      ],
                                      stops: [0.0, 0.5, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? '',
                          style: FlutterFlowTheme.of(context)
                              .titleMedium
                              .override(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '@${user.userName ?? ''}',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: FlutterFlowTheme.of(context).primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? FlutterFlowTheme.of(context)
                                      .primaryText
                                      .withOpacity(0.7)
                                  : FlutterFlowTheme.of(context).secondaryText,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '$followerCount followers',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? FlutterFlowTheme.of(context)
                                            .primaryText
                                            .withOpacity(0.7)
                                        : FlutterFlowTheme.of(context)
                                            .secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(PostsRecord post) {
    // Make sure the post has a valid poster reference
    if (post.poster == null) {
      return SizedBox(); // Don't display posts without a valid poster reference
    }

    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(post.poster!),
      builder: (context, snapshot) {
        // Handle error case - user document doesn't exist or other error
        if (snapshot.hasError) {
          print(
              'Error loading user for post ${post.reference.id}: ${snapshot.error}');
          return SizedBox(); // Don't display the post if we can't load the user
        }

        if (!snapshot.hasData) {
          // Instead of showing a loading indicator, we'll check if this might be a deleted user
          if (snapshot.connectionState == ConnectionState.done) {
            // If the connection is done but we have no data, the user probably doesn't exist
            return SizedBox(); // Don't display posts from non-existent users
          }

          // Only show brief loading if we're still waiting for a response
          return Card(
            clipBehavior: Clip.antiAlias,
            color: FlutterFlowTheme.of(context)
                .secondaryBackground
                .withOpacity(0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Container(
              height: 200,
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FlutterFlowTheme.of(context).primary,
                    ),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          );
        }

        final user = snapshot.data!;

        // Create a custom enhanced post card with glassmorphism
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                margin: EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context)
                            .secondaryBackground
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            spreadRadius: -5,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: StandardizedPostItem(
                        post: post,
                        user: user,
                        animateEntry: true,
                        animationIndex: 0,
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

  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
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

  Widget _buildErrorScaffold(String errorMessage) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              color: FlutterFlowTheme.of(context).error,
              size: 40,
            ),
            SizedBox(height: 16),
            Text(
              errorMessage,
              style: FlutterFlowTheme.of(context).titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserRecord user) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNavigation(user.reference),
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context)
                    .secondaryBackground
                    .withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: -5,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Profile image with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: FlutterFlowTheme.of(context)
                                  .primary
                                  .withOpacity(0.3 * value),
                              blurRadius: 12 * value,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).primary,
                              width: 2,
                            ),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(
                                (user.photoUrl ?? '').isNotEmpty
                                    ? ((user.photoUrl ?? '').contains('?')
                                        ? user.photoUrl ?? ''
                                        : (user.photoUrl ?? '') + '?alt=media')
                                    : 'https://ui-avatars.com/api/?name=${(user.displayName ?? '').isNotEmpty ? (user.displayName ?? '')[0] : "?"}&background=random',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? '',
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'Figtree',
                                fontWeight: FontWeight.w600,
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '@${user.userName}',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: FlutterFlowTheme.of(context).primary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserRecord user) {
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
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
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
        ),
      ),
    );
  }
}
