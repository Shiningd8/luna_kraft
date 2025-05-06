import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'membership_page_model.dart';
import 'dart:ui';
import '/services/ad_service.dart';
import '/services/paywall_manager.dart';
import '/services/models/subscription_product.dart';
import '/services/models/coin_product.dart';
import '/services/purchase_service.dart';
import '/services/coin_service.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Custom delayed animation widget
class DelayedAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  const DelayedAnimation({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  _DelayedAnimationState createState() => _DelayedAnimationState();
}

class _DelayedAnimationState extends State<DelayedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class LunaCoinDisplay extends StatelessWidget {
  const LunaCoinDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0, 0, 16, 0),
      child: AuthUserStreamWidget(
        builder: (context) => StreamBuilder<UserRecord>(
          stream: currentUserReference != null
              ? UserRecord.getDocument(currentUserReference!)
              : null,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('Error in LunaCoinDisplay stream: ${snapshot.error}');
              return Text(
                'Error loading coins',
                style: TextStyle(color: Colors.white),
              );
            }

            if (!snapshot.hasData) {
              print('No data in LunaCoinDisplay stream');
              return Text(
                'Loading...',
                style: TextStyle(color: Colors.white),
              );
            }

            final userRecord = snapshot.data;
            print('LunaCoinDisplay - User record received');

            final coins = userRecord?.lunaCoins ?? 0;
            print('LunaCoinDisplay - Current coins: $coins');

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Image.asset(
                    'assets/images/lunacoin.png',
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '$coins',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class MembershipPageWidget extends StatefulWidget {
  const MembershipPageWidget({super.key});

  static String routeName = 'MembershipPage';
  static String routePath = '/membershipPage';

  @override
  State<MembershipPageWidget> createState() => _MembershipPageWidgetState();
}

class _MembershipPageWidgetState extends State<MembershipPageWidget>
    with SingleTickerProviderStateMixin {
  late MembershipPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  int _currentCoinPackIndex = 1;
  int _currentMembershipPackIndex = 1;
  double _parallaxOffset = 0.0;

  // Animation variables
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;
  // Create enough hover states for all interactive elements (3 membership options, 3 coin packs, and extra for safety)
  final List<bool> _hoverStates = List.generate(10, (index) => false);

  // Video player controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Add a class level future that will be initialized once
  late Future<List<CoinProduct>> _coinProductsFuture;

  // Purchase result subscription
  StreamSubscription<CoinPurchaseResult>? _coinPurchaseSubscription;

  // Mock data for UI preview
  final List<Map<String, dynamic>> _coinPacks = [
    {
      'id': 'coins_100',
      'title': '100 Coins',
      'amount': 100,
      'price': '0.99',
      'bonus': '',
      'color': Color(0xFFF9A825),
    },
    {
      'id': 'coins_500',
      'title': '500 Coins',
      'amount': 500,
      'price': '4.99',
      'bonus': 'BEST VALUE',
      'color': Color(0xFFE65100),
    },
    {
      'id': 'coins_1000',
      'title': '1000 Coins',
      'amount': 1000,
      'price': '9.99',
      'bonus': 'MOST POPULAR',
      'color': Color(0xFFD32F2F),
    },
  ];

  // Real data from subscription service
  List<dynamic> _membershipProducts = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _model = MembershipPageModel();
    _scrollController.addListener(() {
      if (mounted) {
        // Only update state if scrolling a significant amount (reduce UI updates)
        if (_scrollController.offset % 5 == 0) {
          setState(() {
            _parallaxOffset = _scrollController.offset * 0.2;
          });
        }
      }
    });

    // Initialize animation controller with slightly slower animation for smoother feel
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    // Create animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _floatAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // We'll set up theme-dependent animations in didChangeDependencies
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start animations loop
    _animationController.repeat(reverse: true);

    // Initialize the coin products future
    _coinProductsFuture = PaywallManager.getCoinProducts();

    // Initialize video background
    _initializeVideoPlayer();

    // Listen for purchase results
    _coinPurchaseSubscription = CoinService.instance.purchaseResultsStream
        .listen(_handlePurchaseResult);

    // Initialize and preload a rewarded ad
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        print('Initializing ad service...');
        await AdService().loadRewardedAd();
        print('Ad service initialized successfully');

        // Load subscription products
        _loadSubscriptionProducts();
      } catch (e) {
        print('Error initializing ad service: $e');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize theme-dependent animations here, after context is fully available
    _colorAnimation = ColorTween(
      begin: FlutterFlowTheme.of(context).primary.withOpacity(0.6),
      end: FlutterFlowTheme.of(context).secondary.withOpacity(0.8),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Ensure ad service is initialized when dependencies change
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        print('Reloading ad service...');
        await AdService().loadRewardedAd();
        print('Ad service reloaded successfully');
      } catch (e) {
        print('Error reloading ad service: $e');
      }
    });
  }

  // Initialize the video player
  Future<void> _initializeVideoPlayer() async {
    try {
      // Load video file from assets
      _videoController = VideoPlayerController.asset(
        'assets/videos/space_background.mp4',
      );

      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0.0);
      _videoController!.play();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  @override
  void deactivate() {
    // Pause video when widget is deactivated
    _videoController?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _model.dispose();

    // Remove all listeners first
    _scrollController.removeListener(() {});
    _scrollController.dispose();

    // Dispose video controller
    _videoController?.dispose();

    // Cancel purchase subscription
    _coinPurchaseSubscription?.cancel();

    // Proper cleanup for animation controller
    try {
      if (_animationController.isAnimating) {
        _animationController.stop();
      }
      _animationController.dispose();
    } catch (e) {
      print('Error disposing animation controller: $e');
    }

    super.dispose();
  }

  // Function to handle coin purchases safely
  void _handlePurchase(Map<String, dynamic> pack, bool isMembership) async {
    if (!mounted) return; // Check if still mounted

    setState(() {
      _isLoading = true;
    });

    try {
      if (isMembership) {
        // Handle membership purchase
        final result = await PurchaseService.purchaseProduct(pack);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Subscription activated!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Purchase failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Handle coin purchase with direct Firestore access
        await _directFirestoreCoinPurchase(pack);
      }
    } catch (e) {
      print('Error in _handlePurchase: $e');
      if (!mounted) return; // Check again in catch block

      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Direct Firestore purchase method that bypasses UserRecord
  Future<void> _directFirestoreCoinPurchase(Map<String, dynamic> pack) async {
    try {
      // Verify user is logged in
      if (currentUserReference == null) {
        throw Exception('You must be logged in to purchase coins');
      }

      print('Starting direct Firestore purchase for: ${pack['id']}');

      // Get the user document directly from Firestore
      final userDoc = await FirebaseFirestore.instance
          .doc(currentUserReference!.path)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      // Get the current coin balance safely
      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User data is null');
      }

      // FIXED: Using correct field name 'luna_coins' instead of 'lunaCoins'
      final currentCoins =
          userData['luna_coins'] is int ? userData['luna_coins'] as int : 0;
      final purchasedCoins = pack['amount'] as int;
      final newCoinBalance = currentCoins + purchasedCoins;

      print(
          'Updating coins: $currentCoins + $purchasedCoins = $newCoinBalance');

      // Simple update instead of transaction
      // FIXED: Only using serverTimestamp() with update()
      await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
        'luna_coins': newCoinBalance,
        'lastPurchaseTimestamp': FieldValue.serverTimestamp(),
        'purchaseHistory': FieldValue.arrayUnion([
          {
            'type': 'coins',
            'amount': purchasedCoins,
            'price': pack['price'],
            'timestamp': Timestamp
                .now(), // Using Timestamp.now() instead of serverTimestamp
            'productId': pack['id'],
          }
        ]),
      });

      // Record purchase analytics (optional)
      try {
        // Log analytics only if this isn't a release build or the user has permissions
        await FirebaseFirestore.instance.collection('analytics').add({
          'event': 'coin_purchase',
          'userId': currentUserReference?.id,
          'productId': pack['id'],
          'amount': pack['amount'],
          'price': pack['price'],
          'timestamp': Timestamp.now(),
        }).timeout(Duration(seconds: 3), onTimeout: () {
          throw TimeoutException('Analytics write timed out');
        });
      } catch (e) {
        // Silently catch analytics errors - they are non-critical
        print('Analytics error (non-critical): $e');
      }

      if (mounted) {
        // Update local state and show success message
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$purchasedCoins Luna Coins added to your account!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Force UI refresh to update coin display
        setState(() {});
      }
    } catch (e) {
      print('Error in _directFirestoreCoinPurchase: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process purchase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Re-throw the error to be caught by the calling method
      throw e;
    }
  }

  // Clean, minimal tab-based subscription selector
  Widget _buildMembershipPacksCarousel(BuildContext context) {
    // Show loading indicator if products are being loaded
    if (_isLoadingProducts) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              FlutterFlowTheme.of(context).primary),
        ),
      );
    }

    // Show a message if no products are available
    if (_membershipProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Subscription plans could not be loaded',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Clean, minimal tab-based subscription selector
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Custom tab selector
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Animated selection indicator
                AnimatedPositioned(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: (_currentMembershipPackIndex *
                      (MediaQuery.of(context).size.width - 32) /
                      _membershipProducts.length),
                  top: 4,
                  bottom: 4,
                  width: (MediaQuery.of(context).size.width - 32) /
                      _membershipProducts.length,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab buttons
                Row(
                  children: List.generate(_membershipProducts.length, (index) {
                    final product =
                        _membershipProducts[index] as SubscriptionProduct;
                    final isSelected = _currentMembershipPackIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentMembershipPackIndex = index;
                          });
                        },
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 300),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.6),
                                    fontSize: isSelected ? 14 : 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                              child: Text(_getSubscriptionTitle(product.id)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Show selected subscription details with smooth transition
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.05, 0.0),
                    end: Offset(0.0, 0.0),
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildDetailedSubscriptionCard(
              _membershipProducts[_currentMembershipPackIndex]
                  as SubscriptionProduct,
              context,
              key: ValueKey<int>(_currentMembershipPackIndex),
            ),
          ),
        ],
      ),
    );
  }

  // Clean, elegant subscription card with minimal design
  Widget _buildDetailedSubscriptionCard(
      SubscriptionProduct product, BuildContext context,
      {Key? key}) {
    // Get features for this plan
    List<String> features = [];
    if (product.id == 'premium_weekly') {
      features = ['Dream Analysis', 'Exclusive Themes', '150 Coins'];
    } else if (product.id == 'premium_monthly') {
      features = [
        'Dream Analysis',
        'Exclusive Themes',
        '250 Coins',
        'Zen Mode'
      ];
    } else {
      features = ['All Features', '1000 Coins', 'Ad-free', 'Priority Support'];
    }

    // Get appropriate badge
    String badge = '';
    if (product.id == 'premium_monthly') {
      badge = 'BEST VALUE';
    } else if (product.id == 'premium_yearly') {
      badge = 'SAVE 45%';
    }

    // Create a stateful builder to handle hover state
    return StatefulBuilder(builder: (context, setState) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(_hoverStates[_currentMembershipPackIndex] ? 1.03 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hoverStates[_currentMembershipPackIndex]
                ? FlutterFlowTheme.of(context).primary.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: _hoverStates[_currentMembershipPackIndex] ? 1.5 : 1,
          ),
          boxShadow: _hoverStates[_currentMembershipPackIndex]
              ? [
                  BoxShadow(
                    color:
                        FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _purchaseSubscription(product),
              onHover: (isHovering) {
                setState(() {
                  _hoverStates[_currentMembershipPackIndex] = isHovering;
                });
              },
              splashColor: Colors.white.withOpacity(0.05),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Price section
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      transform: Matrix4.identity()
                        ..translate(
                          0.0,
                          _hoverStates[_currentMembershipPackIndex]
                              ? -5.0
                              : 0.0,
                          0.0,
                        ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatPrice(product).replaceAll(',', '.'),
                            style: FlutterFlowTheme.of(context)
                                .displaySmall
                                .override(
                                  fontFamily: 'Outfit',
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              _getSubscriptionDuration(product.id),
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Badge if applicable
                    if (badge.isNotEmpty)
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        transform: Matrix4.identity()
                          ..translate(
                            0.0,
                            _hoverStates[_currentMembershipPackIndex]
                                ? -3.0
                                : 0.0,
                            0.0,
                          ),
                        padding: EdgeInsets.only(top: 6),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                FlutterFlowTheme.of(context)
                                    .primary
                                    .withOpacity(_hoverStates[
                                            _currentMembershipPackIndex]
                                        ? 0.7
                                        : 0.5),
                                FlutterFlowTheme.of(context)
                                    .secondary
                                    .withOpacity(_hoverStates[
                                            _currentMembershipPackIndex]
                                        ? 0.7
                                        : 0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Outfit',
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                      ),

                    SizedBox(height: 20),

                    // Feature divider
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width:
                          _hoverStates[_currentMembershipPackIndex] ? 50 : 35,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _hoverStates[_currentMembershipPackIndex]
                            ? FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Features grid with animations
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: features.asMap().entries.map((entry) {
                        final index = entry.key;
                        final feature = entry.value;

                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200 + (index * 50)),
                          transform: Matrix4.identity()
                            ..translate(
                              0.0,
                              _hoverStates[_currentMembershipPackIndex]
                                  ? -2.0
                                  : 0.0,
                              0.0,
                            ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _hoverStates[_currentMembershipPackIndex]
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _hoverStates[_currentMembershipPackIndex]
                                  ? FlutterFlowTheme.of(context)
                                      .primary
                                      .withOpacity(0.3)
                                  : Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.check_rounded,
                                  color:
                                      _hoverStates[_currentMembershipPackIndex]
                                          ? FlutterFlowTheme.of(context).primary
                                          : FlutterFlowTheme.of(context)
                                              .primary
                                              .withOpacity(0.8),
                                  size:
                                      _hoverStates[_currentMembershipPackIndex]
                                          ? 14
                                          : 12,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                feature,
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Figtree',
                                      color: _hoverStates[
                                              _currentMembershipPackIndex]
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.9),
                                      fontSize: _hoverStates[
                                              _currentMembershipPackIndex]
                                          ? 11
                                          : 10,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20),

                    // Subscribe button with animation
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            FlutterFlowTheme.of(context).primary,
                            FlutterFlowTheme.of(context).secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(
                                    _hoverStates[_currentMembershipPackIndex]
                                        ? 0.4
                                        : 0.25),
                            blurRadius:
                                _hoverStates[_currentMembershipPackIndex]
                                    ? 25
                                    : 20,
                            spreadRadius:
                                _hoverStates[_currentMembershipPackIndex]
                                    ? -2
                                    : -5,
                            offset: Offset(
                                0,
                                _hoverStates[_currentMembershipPackIndex]
                                    ? 8
                                    : 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _purchaseSubscription(product),
                          borderRadius: BorderRadius.circular(22),
                          splashColor: Colors.white.withOpacity(0.1),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 200),
                              style: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: _hoverStates[
                                            _currentMembershipPackIndex]
                                        ? 15
                                        : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                              child: Text('Subscribe'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // Elegant coin selector with segmented control
  Widget _buildSimpleCoinPacks() {
    return FutureBuilder<List<CoinProduct>>(
      future: _coinProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  FlutterFlowTheme.of(context).primary),
            ),
          );
        }

        List<dynamic> coinData = [];
        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          // Use mock data
          coinData = _coinPacks;
        } else {
          // Use real data
          coinData = snapshot.data!
              .map((product) => {
                    'id': product.id,
                    'title': '${product.amount} Coins',
                    'amount': product.amount,
                    'price': product.price.replaceAll('\$', ''),
                    'bonus': product.bonus ?? '',
                    'color': _getCoinColor(product.amount),
                  })
              .toList();
        }

        return Container(
          margin: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Segmented control for coin selection
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    // Animated selection indicator
                    AnimatedPositioned(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: (_currentCoinPackIndex *
                          (MediaQuery.of(context).size.width - 32) /
                          coinData.length),
                      top: 4,
                      bottom: 4,
                      width: (MediaQuery.of(context).size.width - 32) /
                          coinData.length,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab buttons
                    Row(
                      children: List.generate(coinData.length, (index) {
                        final pack = coinData[index];
                        final isSelected = _currentCoinPackIndex == index;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentCoinPackIndex = index;
                              });
                            },
                            child: Container(
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: Duration(milliseconds: 300),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Outfit',
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.6),
                                        fontSize: isSelected ? 14 : 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                  child: Text('${pack['amount']}'),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Selected coin pack details with animation
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0.05, 0.0),
                        end: Offset(0.0, 0.0),
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildSelectedCoinPackCard(
                  coinData[_currentCoinPackIndex],
                  key: ValueKey<int>(_currentCoinPackIndex),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Clean design for selected coin pack
  Widget _buildSelectedCoinPackCard(dynamic pack, {Key? key}) {
    // Get bonus status
    final bool isPopular = pack['bonus'] == 'MOST POPULAR';
    final bool isBestValue = pack['bonus'] == 'BEST VALUE';
    String badge = '';
    if (isPopular) badge = 'MOST POPULAR';
    if (isBestValue) badge = 'BEST VALUE';

    return StatefulBuilder(builder: (context, setState) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(_hoverStates[_currentCoinPackIndex + 3] ? 1.03 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hoverStates[_currentCoinPackIndex + 3]
                ? Colors.amber.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: _hoverStates[_currentCoinPackIndex + 3] ? 1.5 : 1,
          ),
          boxShadow: _hoverStates[_currentCoinPackIndex + 3]
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handlePurchase(pack, false),
              onHover: (isHovering) {
                setState(() {
                  _hoverStates[_currentCoinPackIndex + 3] = isHovering;
                });
              },
              splashColor: Colors.white.withOpacity(0.05),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Coin icon and amount with animation
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      transform: Matrix4.identity()
                        ..translate(
                          0.0,
                          _hoverStates[_currentCoinPackIndex + 3] ? -5.0 : 0.0,
                          0.0,
                        ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                transform: Matrix4.identity()
                                  ..scale(
                                      _hoverStates[_currentCoinPackIndex + 3]
                                          ? 1.1
                                          : 1.0),
                                child: Image.asset(
                                  'assets/images/lunacoin.png',
                                  width: 32,
                                  height: 32,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: Duration(milliseconds: 200),
                                style: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .override(
                                      fontFamily: 'Outfit',
                                      color: Colors.white,
                                      fontSize: _hoverStates[
                                              _currentCoinPackIndex + 3]
                                          ? 26
                                          : 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                child: Text('${pack['amount']}'),
                              ),
                              AnimatedDefaultTextStyle(
                                duration: Duration(milliseconds: 200),
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Figtree',
                                      color: Colors.white.withOpacity(
                                          _hoverStates[
                                                  _currentCoinPackIndex + 3]
                                              ? 0.8
                                              : 0.6),
                                      fontSize: _hoverStates[
                                              _currentCoinPackIndex + 3]
                                          ? 13
                                          : 12,
                                    ),
                                child: Text('Luna Coins'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Badge if applicable with animation
                    if (badge.isNotEmpty)
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        transform: Matrix4.identity()
                          ..translate(
                            0.0,
                            _hoverStates[_currentCoinPackIndex + 3]
                                ? -3.0
                                : 0.0,
                            0.0,
                          ),
                        margin: EdgeInsets.only(top: 12),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(
                              _hoverStates[_currentCoinPackIndex + 3]
                                  ? 0.3
                                  : 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    fontFamily: 'Outfit',
                                    color: Colors.amber,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),

                    SizedBox(height: 20),

                    // One-time purchase note with animation
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      transform: Matrix4.identity()
                        ..translate(
                          0.0,
                          _hoverStates[_currentCoinPackIndex + 3] ? -2.0 : 0.0,
                          0.0,
                        ),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                            _hoverStates[_currentCoinPackIndex + 3]
                                ? 0.08
                                : 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'One-time purchase',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Figtree',
                              color: Colors.white.withOpacity(
                                  _hoverStates[_currentCoinPackIndex + 3]
                                      ? 0.9
                                      : 0.7),
                              fontSize: 10,
                            ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Purchase button with animation
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            FlutterFlowTheme.of(context).primary,
                            FlutterFlowTheme.of(context).secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(
                                    _hoverStates[_currentCoinPackIndex + 3]
                                        ? 0.4
                                        : 0.25),
                            blurRadius: _hoverStates[_currentCoinPackIndex + 3]
                                ? 25
                                : 20,
                            spreadRadius:
                                _hoverStates[_currentCoinPackIndex + 3]
                                    ? -2
                                    : -5,
                            offset: Offset(
                                0,
                                _hoverStates[_currentCoinPackIndex + 3]
                                    ? 8
                                    : 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handlePurchase(pack, false),
                          borderRadius: BorderRadius.circular(22),
                          splashColor: Colors.white.withOpacity(0.1),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 200),
                              style: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize:
                                        _hoverStates[_currentCoinPackIndex + 3]
                                            ? 15
                                            : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                              child: Text('Buy for \$${pack['price']}'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // Redesigned ad button with clean, elegant look
  Widget _buildSimpleAdButton() {
    return StatefulBuilder(builder: (context, setState) {
      bool isHovering = false;

      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        transform: Matrix4.identity()..scale(isHovering ? 1.02 : 1.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF7043).withOpacity(isHovering ? 0.8 : 0.7),
              Color(0xFFFF5722).withOpacity(isHovering ? 0.8 : 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF5722).withOpacity(isHovering ? 0.3 : 0.2),
              blurRadius: isHovering ? 20 : 15,
              spreadRadius: isHovering ? -3 : -5,
              offset: Offset(0, isHovering ? 7 : 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              setState(() {
                isHovering = false;
              });

              this.setState(() {
                _isLoading = true;
              });
              try {
                final adService = AdService();
                final adShown = await adService.showRewardedAd();
                if (!adShown && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Ad not available. Please try again later.'),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              } catch (e) {
                print('Error showing ad: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error showing ad. Please try again.'),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  this.setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            onHover: (hovering) {
              setState(() {
                isHovering = hovering;
              });
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Play icon with clean design and animation
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(isHovering ? 0.2 : 0.15),
                      border: Border.all(
                        color:
                            Colors.white.withOpacity(isHovering ? 0.25 : 0.2),
                        width: isHovering ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        transform: Matrix4.identity()
                          ..scale(isHovering ? 1.2 : 1.0),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),

                  // Text content with animation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 300),
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: isHovering ? 15 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                          child: Text('Watch an Advertisement'),
                        ),
                        SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 300),
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white
                                        .withOpacity(isHovering ? 0.8 : 0.7),
                                    fontSize: 10,
                                  ),
                          child: Text('Earn 10 Luna Coins for free'),
                        ),
                      ],
                    ),
                  ),

                  // Coin indicator with animation
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.fromLTRB(8, 5, 10, 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isHovering ? 0.2 : 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          transform: Matrix4.identity()
                            ..scale(isHovering ? 1.1 : 1.0),
                          child: Image.asset(
                            'assets/images/lunacoin.png',
                            width: 16,
                            height: 16,
                          ),
                        ),
                        SizedBox(width: 4),
                        AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 300),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: isHovering ? 13 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                          child: Text('10'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // Get subscription title
  String _getSubscriptionTitle(String productId) {
    if (productId == 'premium_weekly') {
      return 'Weekly';
    } else if (productId == 'premium_monthly') {
      return 'Monthly';
    } else {
      return 'Yearly';
    }
  }

  // Get subscription duration
  String _getSubscriptionDuration(String productId) {
    if (productId == 'premium_weekly') {
      return 'per week';
    } else if (productId == 'premium_monthly') {
      return 'per month';
    } else {
      return 'per year';
    }
  }

  // Add this helper method for formatting price
  String _formatPrice(SubscriptionProduct product) {
    // Simply use the price directly as provided by the store
    // The price from Google Play Console already includes the proper currency symbol and formatting
    return product.price;
  }

  // Handle purchase result
  void _handlePurchaseResult(CoinPurchaseResult result) {
    if (!mounted) return;

    if (result.success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${result.coinAmount} Luna Coins added to your account!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Refresh the UI to show updated coin count
      setState(() {});
    } else {
      // Show error message if not canceled by user
      if (result.message != null && !result.message!.contains('canceled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${result.message}'),
            backgroundColor: Colors.red.shade800,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Handle subscription purchase
  Future<void> _purchaseSubscription(dynamic product) async {
    try {
      setState(() {
        _isLoading = true;
      });

      debugPrint('MembershipPage: Starting purchase for ${product.id}');

      // Regular purchase flow
      final result = await PaywallManager.purchaseProduct(product);

      // Make sure we're still mounted before showing UI
      if (!mounted) return;

      if (result.success) {
        // Update user's subscription status in Firebase
        await _updateUserSubscriptionStatus(product);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription purchased successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show detailed error message dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Purchase Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.message ?? 'An unknown error occurred'),
                SizedBox(height: 16),
                if ((result.message ?? '').contains('not be found'))
                  Text(
                    'This product is not set up in the Google Play Console. Please make sure the in-app product IDs are configured correctly.',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Make sure we're still mounted before showing UI
      if (!mounted) return;

      // Show error message
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('An unexpected error occurred: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // New method to update user's subscription status in Firebase
  Future<void> _updateUserSubscriptionStatus(
      SubscriptionProduct product) async {
    if (currentUserReference == null) {
      print('Cannot update subscription: User not logged in');
      return;
    }

    try {
      // Calculate subscription end date based on product type
      DateTime now = DateTime.now();
      DateTime? expiryDate;

      if (product.id.contains('weekly')) {
        expiryDate = now.add(Duration(days: 7));
      } else if (product.id.contains('monthly')) {
        expiryDate = now.add(Duration(days: 30));
      } else if (product.id.contains('yearly')) {
        expiryDate = now.add(Duration(days: 365));
      } else {
        // Default to monthly if unknown
        expiryDate = now.add(Duration(days: 30));
      }

      // Get benefits associated with this subscription
      List<String> benefits = _getSubscriptionBenefits(product.id);

      // Update user document with subscription info
      await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
        'subscription': {
          'productId': product.id,
          'name': _getSubscriptionTitle(product.id),
          'startDate': Timestamp.now(),
          'expiryDate': Timestamp.fromDate(expiryDate),
          'autoRenew': true,
          'benefits': benefits,
          'isActive': true,
          'purchaseDate': Timestamp.now(),
        },
        'lastSubscriptionUpdate': Timestamp.now(),
        'isSubscribed': true,
      });

      print('User subscription updated successfully');

      // Log subscription purchase to analytics
      try {
        // Log analytics only if this isn't a release build or the user has permissions
        await FirebaseFirestore.instance.collection('analytics').add({
          'event': 'subscription_purchase',
          'userId': currentUserReference?.id,
          'productId': product.id,
          'price': product.price,
          'timestamp': Timestamp.now(),
          'subscription_type': _getSubscriptionTitle(product.id),
          'expiry_date': Timestamp.fromDate(expiryDate),
        }).timeout(Duration(seconds: 3), onTimeout: () {
          throw TimeoutException('Analytics write timed out');
        });
      } catch (e) {
        // Silently catch analytics errors - they are non-critical
        print('Analytics error (non-critical): $e');
      }
    } catch (e) {
      print('Error updating subscription status: $e');
      // Don't throw here, as we want the purchase to be considered successful
      // even if the status update fails (can be fixed later)
    }
  }

  // Helper method to get benefits based on subscription ID
  List<String> _getSubscriptionBenefits(String productId) {
    if (productId == 'premium_weekly') {
      return [
        'dream_analysis',
        'exclusive_themes',
        'bonus_coins_150',
      ];
    } else if (productId == 'premium_monthly') {
      return [
        'dream_analysis',
        'exclusive_themes',
        'bonus_coins_250',
        'zen_mode',
      ];
    } else if (productId == 'premium_yearly') {
      return [
        'dream_analysis',
        'exclusive_themes',
        'bonus_coins_1000',
        'zen_mode',
        'ad_free',
        'priority_support',
      ];
    } else {
      // Default benefits
      return ['premium_access'];
    }
  }

  // Restore purchases
  Future<void> _restorePurchases() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final results = await PaywallManager.restorePurchases();
      final success = results.any((result) => result.success);

      if (!mounted) return;

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchases restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show info message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No previous purchases found.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error restoring purchases: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Instead of using a custom particle effect, we'll use a simple static placeholder
  Widget _buildParticleEffect() {
    return Container(); // Empty container instead of heavy animation
  }

  // Load subscription products from the service
  Future<void> _loadSubscriptionProducts() async {
    try {
      setState(() {
        _isLoadingProducts = true;
      });

      // Load products from service
      final products = await PaywallManager.getMembershipProducts();

      if (mounted) {
        setState(() {
          _membershipProducts = products;
          _isLoadingProducts = false;
        });
        print('Loaded ${products.length} subscription products');
      }
    } catch (e) {
      print('Error loading subscription products: $e');
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  // Add this method to handle coin purchases
  Future<void> _purchaseCoins(CoinProduct product) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Verify user is logged in
      if (currentUserReference == null) {
        throw Exception('User not found. Please log in first.');
      }

      debugPrint('MembershipPage: Starting coin purchase for ${product.id}');

      // In debug mode, skip payment processing and directly add coins
      if (kDebugMode) {
        await _directDebugPurchase(product);
        return;
      }

      // Check if product has proper product details before starting purchase
      if (product.productDetails == null) {
        throw Exception(
            'Unable to start purchase. Product details not available.');
      }

      // Start the purchase process with the payment provider
      final result = await PaywallManager.purchaseProduct(product);

      // Make sure we're still mounted before showing UI
      if (!mounted) return;

      if (result.success) {
        // Get the user document directly from Firestore
        final userDoc = await FirebaseFirestore.instance
            .doc(currentUserReference!.path)
            .get();

        if (!userDoc.exists) {
          throw Exception('User document not found');
        }

        // Get current coin balance safely
        final userData = userDoc.data();
        if (userData == null) {
          throw Exception('User data is null');
        }

        // FIXED: Using correct field name 'luna_coins' instead of 'lunaCoins'
        final currentCoins =
            userData['luna_coins'] is int ? userData['luna_coins'] as int : 0;
        final newCoins = currentCoins + product.amount;

        // Simple update without transaction
        await FirebaseFirestore.instance
            .doc(currentUserReference!.path)
            .update({
          'luna_coins': newCoins,
          'lastPurchaseDate': FieldValue.serverTimestamp(),
          'purchaseHistory': FieldValue.arrayUnion([
            {
              'productId': product.id,
              'amount': product.amount,
              'price': product.price,
              'date': Timestamp
                  .now(), // Using Timestamp.now() instead of serverTimestamp
              'type': 'coin_purchase'
            }
          ])
        });

        // Log purchase analytics (optional)
        try {
          // Log analytics only if this isn't a release build or the user has permissions
          await FirebaseFirestore.instance.collection('analytics').add({
            'event': 'coin_purchase',
            'userId': currentUserReference?.id,
            'productId': product.id,
            'amount': product.amount,
            'price': product.price,
            'timestamp': Timestamp.now(),
          }).timeout(Duration(seconds: 3), onTimeout: () {
            throw TimeoutException('Analytics write timed out');
          });
        } catch (e) {
          // Silently catch analytics errors - they are non-critical
          print('Analytics error (non-critical): $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${product.amount} Luna Coins added to your account!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Force refresh UI to show new coin count
        setState(() {});
      } else {
        // Purchase failed
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Purchase Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.message ?? 'Purchase could not be completed.'),
                SizedBox(height: 16),
                if ((result.message ?? '').contains('not be found'))
                  Text(
                    'This product may not be set up correctly in the store. Please try again later.',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error purchasing coins: $e');

      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade800,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Direct purchase for debug mode
  Future<void> _directDebugPurchase(CoinProduct product) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verify user is logged in
      if (currentUserReference == null) {
        throw Exception('User not found. Please log in again.');
      }

      print('Starting direct debug purchase for ${product.id}');

      // Get the user document directly from Firestore
      final userDoc = await FirebaseFirestore.instance
          .doc(currentUserReference!.path)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      // Get current coin balance safely
      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User data is null');
      }

      // FIXED: Using correct field name 'luna_coins' instead of 'lunaCoins'
      final currentCoins =
          userData['luna_coins'] is int ? userData['luna_coins'] as int : 0;
      final newCoins = currentCoins + product.amount;

      print('Updating coins: $currentCoins + ${product.amount} = $newCoins');

      // Simple update without transaction
      await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
        'luna_coins': newCoins,
        'lastPurchaseDate': FieldValue.serverTimestamp(),
        'purchaseHistory': FieldValue.arrayUnion([
          {
            'productId': product.id,
            'amount': product.amount,
            'price': product.price,
            'date': Timestamp
                .now(), // Using Timestamp.now() instead of serverTimestamp
            'type': 'coin_purchase'
          }
        ])
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.amount} Luna Coins added to your account!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Force refresh of UI to show new coin balance
      setState(() {});
    } catch (e) {
      // Show error message
      print('Error in direct debug purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      throw e; // Re-throw to be caught by caller
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to get appropriate color based on coin amount
  Color _getCoinColor(int amount) {
    if (amount <= 100) {
      return Color(0xFFF9A825); // Yellow/gold for small amounts
    } else if (amount <= 500) {
      return Color(0xFFE65100); // Orange for medium amounts
    } else {
      return Color(0xFFD32F2F); // Red for large amounts
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Shop',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          LunaCoinDisplay(),
        ],
      ),
      body: Stack(
        children: [
          // Animated video background
          if (_isVideoInitialized && _videoController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),

          // Overlay gradient on top of video
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A1A2E).withOpacity(0.7),
                      Color(0xFF0F0F1B).withOpacity(0.9),
                    ],
                  ),
                ),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment(
                        _shimmerAnimation.value,
                        _shimmerAnimation.value,
                      ),
                      end: Alignment(
                        -_shimmerAnimation.value,
                        -_shimmerAnimation.value,
                      ),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: [0.35, 0.5, 0.65],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              );
            },
          ),

          // Animated particles
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: StarryBackgroundPainter(
                  animation: _animationController.value,
                ),
                child: Container(),
              );
            },
          ),

          // Content with staggered animations
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coins section title with staggered fade in
                  DelayedAnimation(
                    delay: Duration(milliseconds: 200),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Buy Luna Coins',
                        style: FlutterFlowTheme.of(context).titleLarge.override(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),

                  SizedBox(height: 8),

                  // Coin packs with staggered fade in
                  DelayedAnimation(
                    delay: Duration(milliseconds: 400),
                    child: _buildSimpleCoinPacks(),
                  ),

                  SizedBox(height: 16),

                  // Watch ad button with staggered fade in
                  DelayedAnimation(
                    delay: Duration(milliseconds: 600),
                    child: _buildSimpleAdButton(),
                  ),

                  SizedBox(height: 24),

                  // Subscription title with simple fade transition only
                  DelayedAnimation(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        'Choose Your Plan',
                        style: FlutterFlowTheme.of(context).titleLarge.override(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),

                  // Subscription options with staggered fade in
                  DelayedAnimation(
                    child: _buildMembershipPacksCarousel(context),
                  ),

                  SizedBox(height: 24),

                  // Restore purchases button with staggered fade in
                  DelayedAnimation(
                    delay: Duration(milliseconds: 800),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 48),
                      child: Center(
                        child: TextButton(
                          onPressed: _restorePurchases,
                          child: Text(
                            'Restore Purchases',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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

          // Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      FlutterFlowTheme.of(context).primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for starry background effect
class StarryBackgroundPainter extends CustomPainter {
  final double animation;

  StarryBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent stars

    // Draw 100 stars with varying opacity based on animation
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;

      // Vary star brightness with animation
      final opacity =
          (0.3 + 0.7 * math.sin((animation * math.pi * 2) + i * 0.2))
              .clamp(0.2, 0.9);

      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw 20 larger stars with glow effect
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.0 + 1.0;

      // Vary large star brightness with different phase
      final opacity = (0.5 +
              0.5 * math.sin((animation * math.pi * 2) + i * 0.5 + math.pi / 3))
          .clamp(0.3, 1.0);

      // Draw glow
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), radius * 2, glowPaint);

      // Draw star
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(StarryBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
