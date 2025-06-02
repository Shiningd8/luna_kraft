// The membership page handles subscriptions and coin purchases.
// IMPORTANT: All coin purchases now go through the proper purchase flow via PurchaseService,
// ensuring coins are only added to a user's account AFTER payment confirmation from the store.
// Direct Firestore updates are no longer used, fixing the security issue where coins could be
// added without payment verification.

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
// import '/flutter_flow/flutter_flow_util.dart'; // Unnecessary - provided by backend.dart
// import '/flutter_flow/flutter_flow_widgets.dart'; // Unused import
import '/utils/subscription_util.dart';
import '/services/admob_service.dart';
// import 'package:carousel_slider/carousel_slider.dart'; // Unused import
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Unnecessary - provided by material.dart
// import 'package:lottie/lottie.dart'; // Unused import
import 'membership_page_model.dart';
import 'dart:ui'; // Needed for ImageFilter.blur
import '/services/paywall_manager.dart';
import '/services/models/subscription_product.dart';
import '/services/models/coin_product.dart';
import '/services/purchase_service.dart';
import 'dart:async';
// import 'dart:math'; // Unused import
// import 'package:flutter/foundation.dart'; // Unnecessary - provided by material.dart
// import 'package:simple_animations/simple_animations.dart'; // Unused import
// import 'package:supercharged/supercharged.dart'; // Unused import
// import 'package:video_player/video_player.dart'; // Unused import
// import 'dart:math' as math; // Duplicate unused import
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for FirebaseFirestore
// import 'package:firebase_core/firebase_core.dart'; // Unused import
// import 'package:firebase_auth/firebase_auth.dart'; // Unused import
import 'package:shared_preferences/shared_preferences.dart';

// Remove Unity Ads MethodChannel
// const MethodChannel _unityChannel = MethodChannel('com.flutterflow.lunakraft/unity_ads');

// Constants for ad cooldown
const int MAX_AD_VIEWS = 3;
const int COOLDOWN_MINUTES = 30; // 30 minute cooldown (changed from 60)

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
  int _currentMembershipPackIndex = -1;
  double _parallaxOffset = 0.0;

  // Ad cooldown state variables
  int _adViewsCount = 0;
  DateTime? _lastAdViewTime;
  DateTime? _cooldownEndTime;
  bool _isInCooldown = false;
  Timer? _cooldownTimer;
  String _cooldownTimeRemaining = '';
  
  // Animation variables
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;
  // Create enough hover states for all interactive elements (3 membership options, 3 coin packs, and extra for safety)
  final List<bool> _hoverStates = List.generate(10, (index) => false);

  // Add a class level future that will be initialized once
  late Future<List<CoinProduct>> _coinProductsFuture;

  // Mock data for UI preview
  final List<Map<String, dynamic>> _coinPacks = [
    {
      'id': 'ios.lunacoin_100',
      'title': '100 Coins',
      'amount': 100,
      'price': '0.99',
      'bonus': '',
      'color': Color(0xFFF9A825),
    },
    {
      'id': 'ios.lunacoin_500',
      'title': '500 Coins',
      'amount': 500,
      'price': '4.99',
      'bonus': 'BEST VALUE',
      'color': Color(0xFFE65100),
    },
    {
      'id': 'ios.lunacoin_1000',
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
  bool _purchaseSuccess = false;

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

    // Initialize with valid index for proper UI rendering
    _currentMembershipPackIndex = 0;

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

    // Load ad view state and check cooldown immediately when the page loads
    _loadAdViewState();

    // Initialize and preload a rewarded ad
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        print('Initializing ad service...');
        // Replace with a simple delay to simulate initialization
        await Future.delayed(Duration(milliseconds: 500));
        print('Ad service removed - initialization skipped');

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
      begin: FlutterFlowTheme.of(context).primary.withAlpha((0.6 * 255).round()),
      end: FlutterFlowTheme.of(context).secondary.withAlpha((0.8 * 255).round()),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Always update cooldown status when returning to this page
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        _loadAdViewState();
      }
    });
  }

  @override
  void deactivate() {
    // Previous video player code removed
    super.deactivate();
  }

  @override
  void dispose() {
    _model.dispose();

    // Remove all listeners first
    _scrollController.removeListener(() {});
    _scrollController.dispose();

    // Proper cleanup for animation controller
    try {
      if (_animationController.isAnimating) {
        _animationController.stop();
      }
      _animationController.dispose();
    } catch (e) {
      print('Error disposing animation controller: $e');
    }
    
    // Cancel the cooldown timer
    _cancelCooldownTimer();

    super.dispose();
  }

  // Function to handle coin purchases safely
  Future<void> _handlePurchase(Map<String, dynamic> pack, bool isMembership) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get the product ID directly from the pack data
      final productId = pack['id'] as String?;
      
      if (productId == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid product information'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Use direct product ID purchase method
      debugPrint('Purchasing product with ID: $productId');
      final result = await PaywallManager.purchaseProductById(productId);
      
      setState(() {
        _isLoading = false;
      });
      
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMembership 
              ? 'Subscription activated successfully!' 
              : 'Coins purchased successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = result.message ?? 'Purchase failed';
        // Handle common error cases
        if (errorMessage.contains('cancelled')) {
          errorMessage = 'Purchase was cancelled';
        } else if (errorMessage.contains('not found')) {
          errorMessage = 'Product not available for purchase';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during purchase: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Format the error message to be more user-friendly
      String errorMessage = 'An error occurred during purchase';
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Purchase was cancelled';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
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
            child: _membershipProducts.isNotEmpty && _currentMembershipPackIndex >= 0 && _currentMembershipPackIndex < _membershipProducts.length 
              ? _buildDetailedSubscriptionCard(
                  _membershipProducts[_currentMembershipPackIndex] as SubscriptionProduct,
                  context,
                  key: ValueKey<int>(_currentMembershipPackIndex),
                )
              : Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Select a subscription plan above', 
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                      ),
                    ),
                  ),
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
    // Check if this is the current subscription
    final isCurrentPlan = isCurrentSubscription(product.id);
    
    // Get subscription expiry date if this is the current plan
    String expiryDate = '';
    if (isCurrentPlan) {
      final daysLeft = SubscriptionUtil.daysLeft;
      if (daysLeft > 0) {
        final expiryDateTime = DateTime.now().add(Duration(days: daysLeft));
        expiryDate = '${expiryDateTime.day}/${expiryDateTime.month}/${expiryDateTime.year}';
      }
    }
    
    // Get features for this plan
    List<String> features = [];
    if (product.id.contains('weekly') || product.id == 'ios.premium_weekly_sub') {
      features = ['Dream Analysis', 'Exclusive Themes', '150 Coins'];
    } else if (product.id.contains('monthly') || product.id == 'ios.premium_monthly') {
      features = [
        'Dream Analysis',
        'Exclusive Themes',
        '250 Coins',
        'Zen Mode'
      ];
    } else if (product.id.contains('yearly') || product.id == 'ios.premium_yearly') {
      features = ['All Features', '1000 Coins', 'Ad-free', 'Priority Support'];
    }

    // Get appropriate badge
    String badge = '';
    if (product.id.contains('monthly') || product.id == 'ios.premium_monthly') {
      badge = 'BEST VALUE';
    } else if (product.id.contains('yearly') || product.id == 'ios.premium_yearly') {
      badge = 'SAVE 45%';
    }

    // Create a stateful builder to handle hover state
    return StatefulBuilder(builder: (context, setState) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(
              (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex]) ? 1.03 : 1.0),
        decoration: BoxDecoration(
          color: isCurrentPlan
              ? Colors.green.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentPlan
                ? Colors.green.withOpacity(0.5)
                : _hoverStates[_currentMembershipPackIndex]
                    ? FlutterFlowTheme.of(context).primary.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
            width: (isCurrentPlan || _hoverStates[_currentMembershipPackIndex]) ? 1.5 : 1,
          ),
          boxShadow: (isCurrentPlan || _hoverStates[_currentMembershipPackIndex])
              ? [
                  BoxShadow(
                    color: isCurrentPlan
                        ? Colors.green.withOpacity(0.2)
                        : FlutterFlowTheme.of(context).primary.withOpacity(0.2),
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
            child: Stack(
              children: [
                // Main content
                InkWell(
                  onTap: isCurrentPlan ? null : () => _purchaseMembership(product),
                  onHover: isCurrentPlan 
                      ? null
                      : (isHovering) {
                          setState(() {
                            _hoverStates[_currentMembershipPackIndex] = isHovering;
                          });
                        },
                  splashColor: isCurrentPlan ? Colors.transparent : Colors.white.withOpacity(0.05),
                  highlightColor: isCurrentPlan ? Colors.transparent : Colors.white.withOpacity(0.05),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Current plan badge if applicable
                        if (isCurrentPlan)
                          Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Current Plan',
                                  style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        // Expiry date if applicable  
                        if (isCurrentPlan && expiryDate.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Expires: $expiryDate',
                              style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ),

                        // Price section
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          transform: Matrix4.identity()
                            ..translate(
                              0.0,
                              (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
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
                                      color: isCurrentPlan ? Colors.green : Colors.white,
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
                                        color: isCurrentPlan 
                                            ? Colors.green.withOpacity(0.7)
                                            : Colors.white.withOpacity(0.6),
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
                                (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
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
                                        .withOpacity((!isCurrentPlan && _hoverStates[_currentMembershipPackIndex]) ? 0.7 : 0.5),
                                    FlutterFlowTheme.of(context)
                                        .secondary
                                        .withOpacity((!isCurrentPlan && _hoverStates[_currentMembershipPackIndex]) ? 0.7 : 0.5),
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
                              (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex]) ? 50 : 35,
                          height: 3,
                          decoration: BoxDecoration(
                            color: (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
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
                                  (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
                                      ? -2.0
                                      : 0.0,
                                  0.0,
                                ),
                              padding:
                                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
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
                                          (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
                                              ? FlutterFlowTheme.of(context).primary
                                              : FlutterFlowTheme.of(context)
                                                  .primary
                                                  .withOpacity(0.8),
                                      size:
                                          (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
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
                                          color: (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.9),
                                          fontSize: (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
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
                          height: 50,
                          width: double.infinity,
                          margin: EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCurrentPlan
                                ? [
                                    Colors.green.withOpacity(0.7),
                                    Colors.green.withOpacity(0.6),
                                  ]
                                : [
                                    FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(
                                            (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
                                                ? 0.9
                                                : 0.8),
                                    FlutterFlowTheme.of(context)
                                        .secondary
                                        .withOpacity(
                                            (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
                                                ? 0.9
                                                : 0.8),
                                  ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: isCurrentPlan
                                    ? Colors.green.withOpacity(0.3)
                                    : FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(
                                            (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
                                                ? 0.4
                                                : 0.25),
                                blurRadius:
                                    (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
                                        ? 25
                                        : 20,
                                spreadRadius:
                                    (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
                                        ? -2
                                        : -5,
                                offset: Offset(
                                    0,
                                    (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
                                        ? 8
                                        : 5),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isCurrentPlan ? null : () => _purchaseMembership(product),
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
                                          fontSize: (!isCurrentPlan && _hoverStates[_currentMembershipPackIndex])
                                              ? 15
                                              : 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isCurrentPlan)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        if (isCurrentPlan)
                                          SizedBox(width: 6),
                                        Text(isCurrentPlan ? 'Current Plan' : 'Subscribe'),
                                      ],
                                    ),
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
              ],
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
      
      // Determine button state based on cooldown
      final bool isButtonEnabled = !_isInCooldown;
      final String buttonText = _isInCooldown 
          ? 'Wait $_cooldownTimeRemaining'
          : 'Watch an Advertisement';
      final String subText = _isInCooldown
          ? 'Available in $_cooldownTimeRemaining'
          : 'Earn 5 Luna Coins for free';
      
      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        transform: Matrix4.identity()..scale(isHovering && isButtonEnabled ? 1.02 : 1.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isButtonEnabled
                ? [
                    Color(0xFFFF7043).withOpacity(isHovering ? 0.8 : 0.7),
                    Color(0xFFFF5722).withOpacity(isHovering ? 0.8 : 0.7),
                  ]
                : [
                    Colors.grey.withOpacity(0.5),
                    Colors.grey.withOpacity(0.6),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isButtonEnabled
                  ? Color(0xFFFF5722).withOpacity(isHovering ? 0.3 : 0.2)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: isHovering && isButtonEnabled ? 20 : 15,
              spreadRadius: isHovering && isButtonEnabled ? -3 : -5,
              offset: Offset(0, isHovering && isButtonEnabled ? 7 : 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isButtonEnabled ? () async {
              setState(() {
                isHovering = false;
              });

              this.setState(() {
                _isLoading = true;
              });
              try {
                // Use AdMobService to show a rewarded ad
                final adMobService = AdMobService();
                
                // First load the rewarded ad
                final adLoaded = await adMobService.loadRewardedAd();
                
                if (!adLoaded) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not load ad. Please try again later.'),
                        backgroundColor: Colors.orange.shade800,
                      ),
                    );
                  }
                  return;
                }
                
                // Show the rewarded ad
                final result = await adMobService.showRewardedAd();
                
                if (result['success'] == true) {
                  // Record this ad view for cooldown tracking
                  await _recordAdView();
                  
                  // Add coins to the user's account after successful ad view
                  int coins = 5; // Changed from 10 to 5 coins
                  
                  // Add coins using secure server-side method (Firestore FieldValue.increment)
                  final currentUser = currentUserReference;
                  if (currentUser != null) {
                    try {
                      // CRITICAL FIX: Use FieldValue.increment to ONLY modify luna_coins
                      // This ensures we don't affect other fields like unlocked_backgrounds
                      await FirebaseFirestore.instance.doc(currentUser.path).update({
                        'luna_coins': FieldValue.increment(coins),
                        'last_coin_update': FieldValue.serverTimestamp(),
                      });
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You earned $coins Luna Coins!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error adding coins: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding coins. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ad did not complete. No coins awarded.'),
                        backgroundColor: Colors.orange.shade800,
                      ),
                    );
                  }
                }
              } catch (e) {
                print('Error showing ad: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error. Please try again later.'),
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
            } : null,
            onHover: isButtonEnabled ? (hovering) {
              setState(() {
                isHovering = hovering;
              });
            } : null,
            borderRadius: BorderRadius.circular(16),
            splashColor: isButtonEnabled ? Colors.white.withOpacity(0.1) : Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Play or timer icon with clean design and animation
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(isHovering && isButtonEnabled ? 0.2 : 0.15),
                          border: Border.all(
                            color: Colors.white.withOpacity(isHovering && isButtonEnabled ? 0.25 : 0.2),
                            width: isHovering && isButtonEnabled ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            transform: Matrix4.identity()
                              ..scale(isHovering && isButtonEnabled ? 1.2 : 1.0),
                            child: Icon(
                              _isInCooldown ? Icons.timer : Icons.play_arrow_rounded,
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
                                        fontSize: isHovering && isButtonEnabled ? 15 : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                              child: Text(buttonText),
                            ),
                            SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 300),
                              style:
                                  FlutterFlowTheme.of(context).bodySmall.override(
                                        fontFamily: 'Figtree',
                                        color: Colors.white
                                            .withOpacity(isHovering && isButtonEnabled ? 0.8 : 0.7),
                                        fontSize: 10,
                                      ),
                              child: Text(subText),
                            ),
                          ],
                        ),
                      ),

                      // Coin indicator with animation
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.fromLTRB(8, 5, 10, 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isHovering && isButtonEnabled ? 0.2 : 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              transform: Matrix4.identity()
                                ..scale(isHovering && isButtonEnabled ? 1.1 : 1.0),
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
                                        fontSize: isHovering && isButtonEnabled ? 13 : 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                              child: Text('5'), // Changed from 10 to 5
                            ),
                          ],
                        ),
                      ),
                    ],
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
    if (productId.contains('weekly') || productId == 'ios.premium_weekly_sub') {
      return 'Weekly';
    } else if (productId.contains('monthly') || productId == 'ios.premium_monthly') {
      return 'Monthly';
    } else if (productId.contains('yearly') || productId == 'ios.premium_yearly') {
      return 'Yearly';
    } else {
      return 'Premium';
    }
  }

  // Get subscription duration
  String _getSubscriptionDuration(String productId) {
    if (productId.contains('weekly') || productId == 'ios.premium_weekly_sub') {
      return 'per week';
    } else if (productId.contains('monthly') || productId == 'ios.premium_monthly') {
      return 'per month';
    } else if (productId.contains('yearly') || productId == 'ios.premium_yearly') {
      return 'per year';
    } else {
      return '';
    }
  }

  // Add this helper method for formatting price
  String _formatPrice(SubscriptionProduct product) {
    // Simply use the price directly as provided by the store
    // The price from Google Play Console already includes the proper currency symbol and formatting
    return product.price;
  }

  // Handle subscription purchase
  Future<void> _purchaseMembership(SubscriptionProduct product) async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      // Use the new purchasePackage method to process the subscription
      final result = await PurchaseService.purchasePackage(product);

      if (result.success) {
        // Purchase was successful
        setState(() {
          _purchaseSuccess = true;
          _currentMembershipPackIndex = -1;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase successful!'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
        
        // Force a UI refresh to update subscription status display
        setState(() {});
      } else {
        // Purchase failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${result.message}'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error during purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
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
          if (products.isNotEmpty) {
            _currentMembershipPackIndex = 0;
          }
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

  // Add a method to check if the current subscription is active
  bool isCurrentSubscription(String productId) {
    final currentTier = SubscriptionUtil.subscriptionTier;
    if (currentTier == null) return false;
    
    // Match by subscription type (weekly, monthly, yearly)
    if (productId.contains('weekly') && currentTier.contains('weekly')) return true;
    if (productId.contains('monthly') && currentTier.contains('monthly')) return true;
    if (productId.contains('yearly') && currentTier.contains('yearly')) return true;
    
    return false;
  }

  // Add a widget to show subscription status
  Widget _buildSubscriptionBadge(bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive 
          ? FlutterFlowTheme.of(context).primary.withOpacity(0.2)
          : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
            ? FlutterFlowTheme.of(context).primary
            : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: isActive
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: FlutterFlowTheme.of(context).primary,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'Current Plan',
                style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                  color: FlutterFlowTheme.of(context).primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        : Container(),
    );
  }

  // Add a simple current plan badge
  Widget _buildCurrentPlanBadge() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Text(
        'Current Plan',
        textAlign: TextAlign.center,
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Figtree',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  // Restore purchases
  Future<void> _restorePurchases() async {
    try {
      setState(() {
        _isLoadingProducts = true;
      });

      final results = await PurchaseService.restorePurchases();
      final success = results.any((result) => result.success);

      if (!mounted) return;

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchases restored successfully!'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
        
        // Force a UI refresh to update subscription status display
        setState(() {});
      } else {
        // Show info message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No previous purchases found.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error restoring purchases: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring purchases: $e'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  // Load ad view state from SharedPreferences
  Future<void> _loadAdViewState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user ID as key prefix for user-specific storage
      final userId = currentUserUid;
      if (userId == null || userId.isEmpty) return;
      
      final prefix = 'adViews_$userId';
      
      setState(() {
        _adViewsCount = prefs.getInt('${prefix}_count') ?? 0;
        
        final lastViewTimeMillis = prefs.getInt('${prefix}_lastViewTime');
        if (lastViewTimeMillis != null) {
          _lastAdViewTime = DateTime.fromMillisecondsSinceEpoch(lastViewTimeMillis);
        }
        
        final cooldownEndTimeMillis = prefs.getInt('${prefix}_cooldownEndTime');
        if (cooldownEndTimeMillis != null) {
          _cooldownEndTime = DateTime.fromMillisecondsSinceEpoch(cooldownEndTimeMillis);
          
          // Check if still in cooldown - compare with current time
          final now = DateTime.now();
          if (_cooldownEndTime != null && _cooldownEndTime!.isAfter(now)) {
            _isInCooldown = true;
            
            // Initialize the cooldown remaining time based on current time
            _updateCooldownTimeRemaining();
          } else {
            // Cooldown expired, reset if needed
            _isInCooldown = false;
            if (_adViewsCount >= MAX_AD_VIEWS) {
              _resetAdViewsAfterCooldown();
            }
          }
        }
      });
      
      // Start the timer to update the displayed time remaining
      _startCooldownTimerIfNeeded();
    } catch (e) {
      print('Error loading ad view state: $e');
    }
  }
  
  // Save ad view state to SharedPreferences
  Future<void> _saveAdViewState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user ID as key prefix for user-specific storage
      final userId = currentUserUid;
      if (userId == null || userId.isEmpty) return;
      
      final prefix = 'adViews_$userId';
      
      await prefs.setInt('${prefix}_count', _adViewsCount);
      
      if (_lastAdViewTime != null) {
        await prefs.setInt('${prefix}_lastViewTime', _lastAdViewTime!.millisecondsSinceEpoch);
      }
      
      if (_cooldownEndTime != null) {
        await prefs.setInt('${prefix}_cooldownEndTime', _cooldownEndTime!.millisecondsSinceEpoch);
      }
    } catch (e) {
      print('Error saving ad view state: $e');
    }
  }
  
  // Record a new ad view and check if cooldown should start
  Future<void> _recordAdView() async {
    setState(() {
      _adViewsCount += 1;
      _lastAdViewTime = DateTime.now();
      
      // Check if we've reached the max views
      if (_adViewsCount >= MAX_AD_VIEWS) {
        _startCooldown();
      }
    });
    
    await _saveAdViewState();
  }
  
  // Reset ad views count after cooldown period
  void _resetAdViewsAfterCooldown() {
    setState(() {
      _adViewsCount = 0;
      _isInCooldown = false;
      _cooldownEndTime = null;
      _cooldownTimeRemaining = '';
    });
    
    _saveAdViewState();
    _cancelCooldownTimer();
  }
  
  // Start cooldown period with exact timestamps
  void _startCooldown() {
    final now = DateTime.now();
    final endTime = now.add(Duration(minutes: COOLDOWN_MINUTES));
    
    setState(() {
      _isInCooldown = true;
      _cooldownEndTime = endTime;
    });
    
    // Save cooldown end time to SharedPreferences for persistence
    _saveAdViewState();
    
    // Start the UI update timer
    _startCooldownTimer();
  }
  
  // Start cooldown timer if needed - only updates UI display, actual cooldown based on timestamps
  void _startCooldownTimerIfNeeded() {
    if (_isInCooldown && _cooldownEndTime != null) {
      _startCooldownTimer();
    }
  }
  
  // Start the cooldown timer to update UI only
  void _startCooldownTimer() {
    _cancelCooldownTimer(); // Cancel any existing timer
    
    _updateCooldownTimeRemaining();
    
    // Update every second - but this only affects the display
    // The actual cooldown is determined by timestamps
    _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        _cancelCooldownTimer();
        return;
      }
      
      final now = DateTime.now();
      if (_cooldownEndTime != null && now.isAfter(_cooldownEndTime!)) {
        // Cooldown period ended
        _resetAdViewsAfterCooldown();
      } else {
        _updateCooldownTimeRemaining();
      }
    });
  }
  
  // Cancel the cooldown timer
  void _cancelCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
  }
  
  // Update the cooldown time remaining display based on current time
  void _updateCooldownTimeRemaining() {
    if (_cooldownEndTime == null) {
      setState(() {
        _cooldownTimeRemaining = '';
      });
      return;
    }
    
    final now = DateTime.now();
    if (now.isAfter(_cooldownEndTime!)) {
      setState(() {
        _cooldownTimeRemaining = '';
        _isInCooldown = false;
        // Reset ad views if needed
        if (_adViewsCount >= MAX_AD_VIEWS) {
          _resetAdViewsAfterCooldown();
        }
      });
      return;
    }
    
    final difference = _cooldownEndTime!.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    
    setState(() {
      if (hours > 0) {
        _cooldownTimeRemaining = '${hours}h ${minutes}m ${seconds}s';
      } else if (minutes > 0) {
        _cooldownTimeRemaining = '${minutes}m ${seconds}s';
      } else {
        _cooldownTimeRemaining = '${seconds}s';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
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
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).brightness == Brightness.light
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.05),
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
              title: Text(
                'NightMarket',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              centerTitle: false,
              titleSpacing: 16.0,
              actions: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 0, 12, 0),
                  child: LunaCoinDisplay(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Static Image background
          SizedBox.expand(
            child: Image.asset(
              'assets/images/starrybg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Simple gradient overlay without animations
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E).withOpacity(0.2), // More transparent at top to match appbar
                  Color(0xFF0F0F1B).withOpacity(0.7),
                  Color(0xFF0F0F1B).withOpacity(0.9),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
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
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
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
