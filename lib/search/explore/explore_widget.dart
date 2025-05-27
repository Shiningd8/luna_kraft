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
import '/widgets/custom_text_form_field.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';
export 'explore_model.dart';

class ExploreWidget extends StatefulWidget {
  const ExploreWidget({
    super.key, 
    this.searchType,
    this.searchTerm,
  });

  static String routeName = 'Explore';
  static String routePath = '/explore';
  
  // Add parameters for tag search
  final String? searchType;
  final String? searchTerm;
  
  // Add a static method to navigate to explore page with tag search
  static void navigateToTagSearch(BuildContext context, String tag) {
    print('DEBUG_TAG_SEARCH: navigateToTagSearch called with tag: $tag');
    
    try {
      // Check if we're already on the explore page
      final currentRoute = GoRouterState.of(context).matchedLocation;
      final bool isAlreadyOnExplorePage = currentRoute.startsWith('/explore');
      
      print('DEBUG_TAG_SEARCH: Current route: $currentRoute, isAlreadyOnExplorePage: $isAlreadyOnExplorePage');
      
      // To preserve the bottom navigation bar, we need to use go_router properly
      // We should avoid MaterialPageRoute which creates a navigator that hides the bottom navbar
      if (isAlreadyOnExplorePage) {
        // If already on the explore page, we need to:
        // 1. First go to another tab (temporarily)
        // 2. Then go back to explore with the tag
        // This forces the explore page to rebuild with the new parameters
        print('DEBUG_TAG_SEARCH: On explore page, using 2-step navigation to force refresh');
        
        // First navigate to home tab (or any other tab) - just enough to trigger a rebuild
        context.go('/');
        
        // Then after a tiny delay, go back to explore with the tag parameter
        Future.delayed(Duration(milliseconds: 50), () {
          if (context.mounted) {
            context.go('/explore?searchType=tag&searchTerm=$tag');
            print('DEBUG_TAG_SEARCH: Second step - navigated to explore with parameters');
          }
        });
      } else {
        // If not on explore page, simply go to explore with the tag parameter
        print('DEBUG_TAG_SEARCH: Not on explore page, navigating directly with parameters');
        context.go('/explore?searchType=tag&searchTerm=$tag');
      }

      // Verify after a short delay that navigation was successful
      Future.delayed(Duration(milliseconds: 300), () {
        print('DEBUG_TAG_SEARCH: Navigation should be complete. Tag search for: $tag should be active.');
      });
    } catch (e) {
      print('DEBUG_TAG_SEARCH: Error in navigateToTagSearch: $e');
      
      // Fallback using named route
      try {
        print('DEBUG_TAG_SEARCH: Using fallback named route navigation');
        context.goNamed(
          'Explore',
          queryParameters: {
            'searchType': 'tag',
            'searchTerm': tag,
          },
        );
      } catch (navError) {
        print('DEBUG_TAG_SEARCH: Named route navigation failed: $navError');
      
        // Last resort using standard method
        try {
          print('DEBUG_TAG_SEARCH: Using standard go navigation as last resort');
          context.go('/explore?searchType=tag&searchTerm=$tag');
        } catch (finalError) {
          print('DEBUG_TAG_SEARCH: All navigation methods failed: $finalError');
        }
      }
    }
  }

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
  String _timeFilter = 'week'; // Default time filter (week, day, month)
  List<PostsRecord> _filteredSearchResults = [];
  bool _processedSearchParams = false; // Track if we've already processed search parameters

  @override
  void initState() {
    super.initState();
    print('DEBUG_TAG_SEARCH: ExploreWidget.initState called');
    
    _model = detailedpost.createModel(context, () => ExploreModel());
    _model.searchBarTextController ??= _searchController;

    print('DEBUG_TAG_SEARCH: Setting up search controller and default state');
    
    // Initialize default state
    _isSearchingTags = false;
    _isSearching = false;
    _filteredSearchResults = [];
    _postSearchResults = [];
    _userSearchResults = [];
    _processedSearchParams = false;
    
    // Clear the search controller initially - it will be set if parameters exist
    _searchController.clear();
    
    // Add listener after initializing the controller
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });

    print('DEBUG_TAG_SEARCH: Initial state - _isSearchingTags=$_isSearchingTags, _isSearching=$_isSearching');
    
    // Check if UserRecord collection exists
    UserRecord.collection.limit(1).get().then((snapshot) {
      print('UserRecord collection exists: ${snapshot.docs.isNotEmpty}');
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        if (data != null) {
          final dataMap = data as Map<String, dynamic>;
          print('First document has user_name: ${dataMap.containsKey('user_name')}');
        } else {
          print('First document data is null');
        }
      }
    }).catchError((error) {
      print('Error checking UserRecord collection: $error');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        safeSetState(() {});
      }
    });
    
    // Process navigation arguments - moved this after controller setup
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_processedSearchParams) {
        print('DEBUG_TAG_SEARCH: About to process search parameters in postFrameCallback');
        _processSearchParameters();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    print('DEBUG_TAG_SEARCH: ExploreWidget.dispose called - cleaning up resources');
    
    // Cancel any pending timers
    _debounceTimer?.cancel();
    
    // Remove listener before clearing the controller
    _searchController.removeListener(() {
      _onSearchChanged(_searchController.text);
    });
    
    // Log the current search state before disposal
    print('DEBUG_TAG_SEARCH: Dispose state - _isSearchingTags=$_isSearchingTags, _isSearching=$_isSearching, searchText=${_searchController.text}');
    
    // Properly dispose of the controller
    _searchController.dispose();
    _model.dispose();
    
    // Clear cache variables to free memory
    _exploreUserRecordList = [];
    _userSearchResults = [];
    _postSearchResults = [];
    _filteredSearchResults = [];
    
    // Important: Also reset search state flags to ensure next instance starts fresh
    _isSearchingTags = false;
    _isSearching = false;
    _processedSearchParams = false;
    
    print('DEBUG_TAG_SEARCH: ExploreWidget fully disposed');
    
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
          _filteredSearchResults = [];
        } else if (!_isSearchingTags) {
          // Search for users
          final lowercaseQuery = query.toLowerCase();
          _userSearchResults = _exploreUserRecordList.where((user) {
            // Skip current user
            if (user.reference == null || currentUserReference == null) {
              return false;
            }
            
            if (user.reference == currentUserReference) {
              return false;
            }
            
            // Skip blocked users (safely check for null)
            if (currentUserDocument != null && 
                currentUserDocument!.blockedUsers.contains(user.reference)) {
              return false;
            }
            
            // Skip users who have blocked the current user (safely check for null)
            if (currentUserReference != null &&
                user.blockedUsers != null &&
                user.blockedUsers.contains(currentUserReference)) {
              return false;
            }
            
            final userName = (user.userName ?? '').toLowerCase();
            final displayName = (user.displayName ?? '').toLowerCase();
            return userName.contains(lowercaseQuery) ||
                displayName.contains(lowercaseQuery);
          }).toList();
        } else {
          // For tag search, ensure we're searching without hashtag if present
          final cleanQuery = query.startsWith('#') ? query.substring(1).trim() : query.trim();
          print('Searching for tag: $cleanQuery');
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
                                              color: Colors.white,
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
                                        borderRadius:
                                            BorderRadius.circular(28),
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
                                    child: CustomTextFormField(
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
        padding: EdgeInsets.fromLTRB(16, 0, 16, 80), // Added bottom padding of 80
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
        queryBuilder: (postsRecord) {
          // Start with all the user references we want to include
          final userReferences = [
            // Include posts from users that the current user doesn't follow (if not private)
            ..._exploreUserRecordList
                .where((user) =>
                    !user.isPrivate &&
                    !(currentUserDocument?.blockedUsers
                            .contains(user.reference) ??
                        false))
                .map((user) => user.reference)
                .toList(),
            // Also include posts from users that the current user follows
            ...(currentUserDocument?.followingUsers ?? []),
          ];
          
          // Make sure we include current user in the list
          if (currentUserReference != null && !userReferences.contains(currentUserReference)) {
            userReferences.add(currentUserReference!);
          }
          
          // Check if we have any user references to query
          if (userReferences.isEmpty) {
            print('No user references available for tag search query');
            // Return a default query that will return no results but won't error
            return postsRecord.where('id', isEqualTo: 'no_results');
          }
          
          // Firestore has a limit of 10 items in a whereIn clause
          // If we have more than 10 users, we need to use a different approach
          if (userReferences.length > 10) {
            print('More than 10 user references (${userReferences.length}), using alternative query');
            // Use a simpler query that doesn't use whereIn
            return postsRecord
                .where('is_private', isEqualTo: false)
                .orderBy('date', descending: true);
          }
                    
          return postsRecord
              .where('poster', whereIn: userReferences)
              .orderBy('date', descending: true);
        },
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

        // Show loading UI only on first load
        if (snapshot.connectionState == ConnectionState.waiting && _model.isFirstLoad) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        // Process search results
        List<PostsRecord> postsToFilter = snapshot.data ?? [];
        
        // If we're waiting for new data but have previous results, use the cached data to prevent flickering
        if (snapshot.connectionState == ConnectionState.waiting && !_model.isFirstLoad && _filteredSearchResults.isNotEmpty) {
          postsToFilter = _filteredSearchResults;
        } else if (snapshot.hasData) {
          // Cache the new results
          _postSearchResults = snapshot.data!;
        }

        if (postsToFilter.isEmpty) {
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
                  'No posts found with tag: "${_searchController.text}"',
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

        final searchText = _searchController.text.toLowerCase().trim();
        
        // Only filter posts if we have a valid search term
        List<PostsRecord> filteredPosts;
        
        // Cache search results to prevent flickering
        if (!_model.isFirstLoad && _filteredSearchResults.isNotEmpty && snapshot.connectionState == ConnectionState.waiting) {
          // Use previously filtered results while waiting for new data
          filteredPosts = _filteredSearchResults;
        } else {
          try {
            // Get clean search term once for efficiency
            final cleanSearchText = searchText.toLowerCase().trim();
            
            if (cleanSearchText.isEmpty) {
              filteredPosts = []; // No search term, no results
            } else {
              // Filter the posts based on the search text
              filteredPosts = postsToFilter.where((post) {
                try {
                  // Skip posts with no poster reference
                  if (post.poster == null) {
                    return false;
                  }
                  
                  // First check: Private posts (personal posts)
                  // Private posts should ONLY be visible to their creator, regardless of followers
                  if (post.isPrivate) {
                    return post.poster == currentUserReference; // Only show to creator
                  }
  
                  // Second check: Posts from private accounts (but public posts)
                  // These should only be visible to followers
                  final posterRef = post.poster!;
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
  
                  // If this is a private account and the current user isn't following them,
                  // don't show the post (unless it's the current user's own post)
                  if (isPrivateAccount && !isFollowingUser && post.poster != currentUserReference) {
                    return false;
                  }
  
                  // Safely handle potentially null or empty tags
                  if (post.tags == null || post.tags.isEmpty) {
                    return false;
                  }
  
                  // Split the post tags by comma and trim each tag
                  final postTagsList = post.tags
                      .toLowerCase()
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
                  
                  // Try different matching strategies:
                  // 1. Exact tag match (preferred)
                  if (postTagsList.contains(cleanSearchText)) {
                    return true;
                  }
                  
                  // 2. Starts with search (for partial tag search)
                  for (var tag in postTagsList) {
                    if (tag.startsWith(cleanSearchText)) {
                      return true;
                    }
                  }
                  
                  // 3. Contains match (least preferred, but useful for partial text)
                  if (cleanSearchText.length > 2) { // Only for search terms longer than 2 characters
                    for (var tag in postTagsList) {
                      if (tag.contains(cleanSearchText)) {
                        return true;
                      }
                    }
                  }
  
                  return false;
                } catch (e) {
                  print('Error filtering post: $e');
                  return false;
                }
              }).toList();
            }
            
            // Cache the filtered results
            _filteredSearchResults = filteredPosts;
          } catch (e) {
            print('Error during tag filtering: $e');
            // Use empty list to avoid crash
            filteredPosts = [];
          }
        }
        
        // Only print debug information on first run to reduce log spam
        if (_model.isFirstLoad) {
          print('Found ${filteredPosts.length} matching posts for tag "$searchText"');
          // Mark that we've completed the first load
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _model.isFirstLoad = false;
              });
            }
          });
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
              child: Padding(
                padding: EdgeInsets.only(bottom: 20), // Extra bottom padding
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 80), // Added bottom padding of 80
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
                          false) &&
                      !(user.blockedUsers.contains(currentUserReference) ?? false))
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
        // Popular Posts Section with Time Filter Toggle
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Column(
              children: [
                Container(
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
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Most Liked Posts',
                              style:
                                  FlutterFlowTheme.of(context).titleMedium.override(
                                        fontFamily: 'Outfit',
                                        fontSize: 18,
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
                // Time Filter Toggle
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate positions based on container width
                              final containerWidth = constraints.maxWidth;
                              final tabWidth = containerWidth / 3;
                              
                              return Stack(
                                children: [
                                  // Animated sliding indicator
                                  AnimatedPositioned(
                                    duration: Duration(milliseconds: 400),
                                    curve: Curves.easeOutBack,
                                    left: _timeFilter == 'day' 
                                        ? 0 
                                        : _timeFilter == 'week' 
                                            ? tabWidth
                                            : tabWidth * 2,
                                    top: 0,
                                    bottom: 0,
                                    width: tabWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF7963DF).withOpacity(0.8),
                                            blurRadius: 25,
                                            spreadRadius: -5,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(28),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(28),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF8A74F9),
                                                Color(0xFF6953CF),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Toggle buttons
                                  Row(
                                    children: [
                                      // Today button
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              if (_timeFilter != 'day') {
                                                HapticFeedback.selectionClick();
                                                setState(() => _timeFilter = 'day');
                                              }
                                            },
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            child: Center(
                                              child: Text(
                                                'Today',
                                                style: TextStyle(
                                                  color: _timeFilter == 'day'
                                                      ? Colors.white
                                                      : FlutterFlowTheme.of(context).secondaryText,
                                                  fontWeight: _timeFilter == 'day'
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                  fontSize: _timeFilter == 'day' ? 16 : 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Week button
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              if (_timeFilter != 'week') {
                                                HapticFeedback.selectionClick();
                                                setState(() => _timeFilter = 'week');
                                              }
                                            },
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            child: Center(
                                              child: Text(
                                                'This Week',
                                                style: TextStyle(
                                                  color: _timeFilter == 'week'
                                                      ? Colors.white
                                                      : FlutterFlowTheme.of(context).secondaryText,
                                                  fontWeight: _timeFilter == 'week'
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                  fontSize: _timeFilter == 'week' ? 16 : 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Month button
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              if (_timeFilter != 'month') {
                                                HapticFeedback.selectionClick();
                                                setState(() => _timeFilter = 'month');
                                              }
                                            },
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            child: Center(
                                              child: Text(
                                                'This Month',
                                                style: TextStyle(
                                                  color: _timeFilter == 'month'
                                                      ? Colors.white
                                                      : FlutterFlowTheme.of(context).secondaryText,
                                                  fontWeight: _timeFilter == 'month'
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                  fontSize: _timeFilter == 'month' ? 16 : 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Dynamic status indicator
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Builder(
              builder: (context) {
                // Create status message based on _timeFilter
                String timeHeaderMessage = '';
                switch (_timeFilter) {
                  case 'day':
                    timeHeaderMessage = 'Showing most liked posts from today';
                    break;
                  case 'week':
                    timeHeaderMessage = 'Showing most liked posts from this week';
                    break;
                  case 'month':
                    timeHeaderMessage = 'Showing most liked posts from this month';
                    break;
                }
                
                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 500),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            timeHeaderMessage,
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Figtree',
                                  fontSize: 14,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Posts List
        SliverPadding(
          padding: EdgeInsets.only(bottom: 80),
          sliver: StreamBuilder<List<PostsRecord>>(
            stream: queryPostsRecord(
              queryBuilder: (postsRecord) =>
                  postsRecord.where('is_private', isEqualTo: false).orderBy('date', descending: true),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
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

              if (snapshot.hasError) {
                print('Error loading posts: ${snapshot.error}');
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: FlutterFlowTheme.of(context).error,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Error loading posts',
                            style: FlutterFlowTheme.of(context).titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

              List<PostsRecord> allPosts = snapshot.data!;

              // Filter out posts that don't have a valid poster reference
              final validPosts = allPosts.where((post) => post.poster != null).toList();

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

              // Filter for posts from non-private, non-blocked users
              final filteredByUserPosts = validPosts.where((post) {
                // Find the user for this post
                final posterRef = post.poster!;
                bool isPrivateAccount = false;
                bool isBlockedUser = false;
                bool hasBlockedCurrentUser = false;

                // Get user info from our cached user list
                for (var user in _exploreUserRecordList) {
                  if (user.reference == posterRef) {
                    isPrivateAccount = user.isPrivate;
                    isBlockedUser = currentUserDocument?.blockedUsers.contains(user.reference) ?? false;
                    hasBlockedCurrentUser = user.blockedUsers.contains(currentUserReference) ?? false;
                    break;
                  }
                }

                // Skip posts from private accounts, blocked users, or users who blocked current user
                if (isPrivateAccount || isBlockedUser || hasBlockedCurrentUser) {
                  return false;
                }

                return true;
              }).toList();
              
              // Get the appropriate time cutoff based on the current time filter
              DateTime timeCutoff = DateTime.now();
              switch (_timeFilter) {
                case 'day':
                  timeCutoff = DateTime.now().subtract(Duration(hours: 24));
                  break;
                case 'week':
                  timeCutoff = DateTime.now().subtract(Duration(days: 7));
                  break;
                case 'month':
                  timeCutoff = DateTime.now().subtract(Duration(days: 30));
                  break;
                default:
                  timeCutoff = DateTime.now().subtract(Duration(days: 7));
              }
              
              // Filter posts by time period
              final filteredByTimePosts = filteredByUserPosts
                  .where((post) => post.date != null && post.date!.isAfter(timeCutoff))
                  .toList();
                  
              // Sort posts by like count (descending)
              filteredByTimePosts.sort((a, b) => b.likes.length.compareTo(a.likes.length));

              final postsToShow = filteredByTimePosts.isEmpty 
                  ? (filteredByUserPosts..sort((a, b) => b.likes.length.compareTo(a.likes.length)))
                  : filteredByTimePosts;

              // Update status message if no posts are found for the selected time period
              String statusMessage = '';
              if (filteredByTimePosts.isEmpty && filteredByUserPosts.isNotEmpty) {
                switch (_timeFilter) {
                  case 'day':
                    statusMessage = 'No posts found from today. Showing all-time most liked posts instead.';
                    break;
                  case 'week':
                    statusMessage = 'No posts found from this week. Showing all-time most liked posts instead.';
                    break;
                  case 'month':
                    statusMessage = 'No posts found from this month. Showing all-time most liked posts instead.';
                    break;
                }
              }
              
              // Take the top posts to display (limit to 50)
              final finalPostsToShow = postsToShow.take(50).toList();

              if (finalPostsToShow.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
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
                            'No matching posts found',
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
                    final post = finalPostsToShow[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _buildPostCard(post),
                    );
                  },
                  childCount: finalPostsToShow.length,
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
    
    // Use ValueKey to maintain widget identity across rebuilds
    return KeyedSubtree(
      key: ValueKey('post-${post.reference.id}'),
      child: StreamBuilder<UserRecord>(
        stream: UserRecord.getDocument(post.poster!),
        builder: (context, snapshot) {
          // Try to find user in cached user list first
          UserRecord? cachedUser;
          for (var user in _exploreUserRecordList) {
            if (user.reference == post.poster) {
              cachedUser = user;
              break;
            }
          }
          
          // Handle error case - user document doesn't exist or other error
          if (snapshot.hasError) {
            print('Error loading user for post ${post.reference.id}: ${snapshot.error}');
            
            // If we have cached user data, use it instead
            if (cachedUser != null) {
              return _buildPostCardContent(post, cachedUser);
            }
            
            return SizedBox(); // Don't display the post if we can't load the user
          }

          // If we have data from the stream, use it
          if (snapshot.hasData) {
            return _buildPostCardContent(post, snapshot.data!);
          }
          
          // If we're waiting but have cached user data, use the cached version
          if (cachedUser != null) {
            return _buildPostCardContent(post, cachedUser);
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
        },
      ),
    );
  }
  
  // Extract the post card content to a separate method for better organization
  Widget _buildPostCardContent(PostsRecord post, UserRecord posterUser) {
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
                    user: posterUser,
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
                              blurRadius: 15 * value,
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

  // Extracted method to process search parameters for better organization
  void _processSearchParameters() {
    if (!mounted || _processedSearchParams) return;
    
    // Mark as processed to prevent double processing
    _processedSearchParams = true;
    
    print('DEBUG_TAG_SEARCH: Start processing search parameters');
    
    // Print route information for debugging
    print('DEBUG_TAG_SEARCH: Widget params - searchType: ${widget.searchType}, searchTerm: ${widget.searchTerm}');
    
    // First check direct widget constructor parameters - do this first since it doesn't rely on router state
    if (widget.searchType == 'tag' && widget.searchTerm != null && widget.searchTerm!.isNotEmpty) {
      print('DEBUG_TAG_SEARCH: Using direct widget parameters for search: ${widget.searchTerm}');
      _setupTagSearch(widget.searchTerm!);
      return; // Exit early to avoid attempting to use GoRouterState
    }
    
    // Only try to access GoRouterState if we're in the context of a GoRouter
    GoRouterState? goRouterState;
    Map<String, String>? queryParams;
    
    try {
      // Try to get GoRouterState, but don't crash if it's not available
      goRouterState = GoRouterState.of(context);
      queryParams = goRouterState.uri.queryParameters;
      print('DEBUG_TAG_SEARCH: GoRouter state: ${goRouterState.uri}');
      print('DEBUG_TAG_SEARCH: Query parameters: $queryParams');
    } catch (e) {
      print('DEBUG_TAG_SEARCH: Unable to access GoRouterState: $e');
      // If we can't access router state but have direct parameters, we already processed them above
      // Nothing more to do here
      if (widget.searchType != null && widget.searchTerm != null) return;
      
      queryParams = null; // Ensure it's null if we couldn't get it
    }
    
    // Store whether we processed any parameters from the URL
    bool processedUrlParameters = false;
    
    // Check for route arguments from Navigator
    final modalRoute = ModalRoute.of(context);
    final routeArgs = modalRoute?.settings.arguments as Map<String, dynamic>?;
    print('DEBUG_TAG_SEARCH: Route arguments: $routeArgs');
    
    // Then check query parameters (GoRouter)
    if (queryParams != null && queryParams.containsKey('searchTerm')) {
      final searchType = queryParams['searchType'] ?? 'tag';  // Default to tag search if not specified
      final searchTerm = queryParams['searchTerm'];
      print('DEBUG_TAG_SEARCH: Found query parameter searchType: $searchType, searchTerm: $searchTerm');
      
      if (searchTerm != null && searchTerm.isNotEmpty) {
        print('DEBUG_TAG_SEARCH: Setting up tag search for: $searchTerm (from query params)');
        // Set search mode to tags if searchType is 'tag' or not specified
        _isSearchingTags = (searchType == 'tag');
        // Set the search text
        _searchController.text = searchTerm;
        // Trigger search
        _isSearching = true;
        // Mark as not first load
        _model.isFirstLoad = false;
        processedUrlParameters = true;
        setState(() {});
        
        // Try to clear URL parameters after processing to prevent persistent search
        try {
          if (mounted && goRouterState != null) {
            print('DEBUG_TAG_SEARCH: Clearing URL parameters to prevent persistence');
            
            // Use replaceNamed to keep the same route but without parameters
            // This prevents the parameters from persisting in browser history
            context.replaceNamed('Explore');
          }
        } catch (e) {
          print('DEBUG_TAG_SEARCH: Error clearing URL: $e');
        }
      }
    } 
    // Then check route arguments (Navigator)
    else if (routeArgs != null && routeArgs.containsKey('searchTerm')) {
      final searchType = routeArgs['searchType'] as String? ?? 'tag';  // Default to tag search
      final searchTerm = routeArgs['searchTerm'] as String?;
      print('DEBUG_TAG_SEARCH: Found route argument searchType: $searchType, searchTerm: $searchTerm');
      
      if (searchTerm != null && searchTerm.isNotEmpty) {
        print('DEBUG_TAG_SEARCH: Setting up tag search for: $searchTerm (from route args)');
        _setupTagSearch(searchTerm);
        processedUrlParameters = true;
      }
    } else {
      // No search parameters found, explicitly reset search state
      print('DEBUG_TAG_SEARCH: No search parameters found, resetting search state');
      _resetSearchState();
    }
    
    print('DEBUG_TAG_SEARCH: Finished processing search parameters, processedUrlParameters=$processedUrlParameters');
  }
  
  // Helper method to reset search state
  void _resetSearchState() {
    print('DEBUG_TAG_SEARCH: Explicitly resetting search state');
    _searchController.clear();
    _isSearchingTags = false;
    _isSearching = false;
    _filteredSearchResults = [];
    _postSearchResults = [];
    _userSearchResults = [];
    _model.isFirstLoad = true;
    setState(() {});
  }
  
  // Helper method to set up tag search with a given term
  void _setupTagSearch(String searchTerm) {
    print('DEBUG_TAG_SEARCH: Setting up tag search in _setupTagSearch method: $searchTerm');
    
    // Normalize the search term (remove hashtag if present, trim spaces)
    String normalizedTerm = searchTerm.trim();
    if (normalizedTerm.startsWith('#')) {
      normalizedTerm = normalizedTerm.substring(1).trim();
    }
    
    print('DEBUG_TAG_SEARCH: Normalized search term: "$normalizedTerm" (original: "$searchTerm")');
    
    // Set search mode to tags
    _isSearchingTags = true;
    
    // Set the search text
    _searchController.text = normalizedTerm;
    
    // Trigger search
    _isSearching = true;
    
    // Mark as not first load
    _model.isFirstLoad = false;
    
    print('DEBUG_TAG_SEARCH: Search state updated: _isSearchingTags=$_isSearchingTags, _isSearching=$_isSearching');
    setState(() {});
  }
}
