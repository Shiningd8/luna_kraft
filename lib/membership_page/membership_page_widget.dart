import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/game/screens/game_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'membership_page_model.dart';
import 'dart:ui';
import '/services/purchase_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
export 'membership_page_model.dart';
import '/services/ad_service.dart';

class LunaCoinDisplay extends StatelessWidget {
  const LunaCoinDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(0, 0, 16, 0),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: AuthUserStreamWidget(
        builder: (context) => StreamBuilder<UserRecord>(
          stream: currentUserReference != null
              ? UserRecord.getDocument(currentUserReference!)
              : null,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('Error in LunaCoinDisplay stream: ${snapshot.error}');
              return Text('Error loading coins');
            }

            if (!snapshot.hasData) {
              print('No data in LunaCoinDisplay stream');
              return Text('Loading...');
            }

            final userRecord = snapshot.data;
            print('LunaCoinDisplay - User record received');

            final coins = userRecord?.lunaCoins ?? 0;
            print('LunaCoinDisplay - Current coins: $coins');

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
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
                SizedBox(width: 6),
                Container(
                  constraints: BoxConstraints(minWidth: 40),
                  child: Text(
                    '$coins',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
  int _selectedCoinOption = -1;
  int _selectedMembershipOption = -1;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<Package> _availablePackages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MembershipPageModel());
    _scrollController.addListener(() {
      setState(() {});
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();

    // Initialize RevenueCat and fetch packages
    _initializePurchases();

    // Initialize and preload a rewarded ad
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          print('Initializing ad service...');
          await AdService().loadRewardedAd();
          print('Ad service initialized successfully');
        } catch (e) {
          print('Error initializing ad service: $e');
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure ad service is initialized when dependencies change
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          print('Reloading ad service...');
          await AdService().loadRewardedAd();
          print('Ad service reloaded successfully');
        } catch (e) {
          print('Error reloading ad service: $e');
        }
      }
    });
  }

  @override
  void deactivate() {
    // Don't dispose the ad service when the page is deactivated
    super.deactivate();
  }

  Future<void> _initializePurchases() async {
    try {
      await PurchaseService.init();
      await _fetchPackages();
    } catch (e) {
      debugPrint('Error initializing purchases: $e');
    }
  }

  Future<void> _fetchPackages() async {
    setState(() => _isLoading = true);
    try {
      final packages = await PurchaseService.getCoinPackages();
      setState(() => _availablePackages = packages);
    } catch (e) {
      debugPrint('Error fetching packages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePurchase(Package package) async {
    setState(() => _isLoading = true);
    try {
      final result = await PurchaseService.purchasePackage(package);
      if (result.success) {
        if (result.isMembership) {
          // Handle membership purchase success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Membership activated successfully!')),
          );
        } else if (result.coinAmount != null) {
          // Handle coin purchase success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${result.coinAmount} coins purchased successfully!')),
          );
          // Update the user's coin balance in Firebase
          final currentCoins = currentUserDocument?.lunaCoins ?? 0;
          await currentUserReference?.update({
            'luna_coins': currentCoins + result.coinAmount!,
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed. Please try again.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _earnCoinsWithAd() async {
    setState(() => _isLoading = true);
    try {
      final adService = AdService();
      final adResult = await adService.showRewardedAd();
      // The snackbar will be shown in the onUserEarnedReward callback in ad_service.dart
      if (!adResult) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ad. Please try again later.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          automaticallyImplyLeading: true,
          title: Text(
            'Membership & Coins',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  letterSpacing: 0.0,
                ),
          ),
          actions: [
            LunaCoinDisplay(),
          ],
        ),
        body: Stack(
          children: [
            // Animated Background
            Positioned.fill(
              child: Lottie.asset(
                'assets/jsons/Animation_-_1739171323302.json',
                fit: BoxFit.cover,
                animate: true,
              ),
            ),
            // Content
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  setState(() {});
                }
                return true;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(height: 120),
                      // Coins Section
                      _buildGlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
                              child: Text(
                                'Purchase Coins',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 180,
                              child: CarouselSlider(
                                carouselController: _model.carouselController,
                                options: CarouselOptions(
                                  height: 160,
                                  viewportFraction: 0.7,
                                  enlargeCenterPage: true,
                                  enlargeFactor: 0.15,
                                  enableInfiniteScroll: false,
                                  initialPage: 0,
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      _selectedCoinOption = index;
                                    });
                                  },
                                ),
                                items: [
                                  _buildCoinPurchaseOption(
                                    coins: 100,
                                    price: '\$0.99',
                                    isPopular: false,
                                    index: 0,
                                  ),
                                  _buildCoinPurchaseOption(
                                    coins: 500,
                                    price: '\$4.99',
                                    isPopular: true,
                                    index: 1,
                                  ),
                                  _buildCoinPurchaseOption(
                                    coins: 1000,
                                    price: '\$9.99',
                                    isPopular: false,
                                    index: 2,
                                  ),
                                ],
                              ),
                            ),
                            Center(child: _buildWatchAdButton()),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      // Membership Section
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium Membership',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                  ),
                            ),
                            SizedBox(height: 24),
                            CarouselSlider(
                              carouselController: _model.carouselController,
                              options: CarouselOptions(
                                height: 320,
                                viewportFraction: 0.8,
                                enlargeCenterPage: true,
                                autoPlay: false,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _selectedMembershipOption = index;
                                  });
                                },
                              ),
                              items: [
                                _buildMembershipCard(
                                  title: 'Weekly',
                                  price: '\$4.99',
                                  features: [
                                    'Dream Analysis',
                                    'Exclusive Themes',
                                    'Ad-Free Experience',
                                  ],
                                  isPopular: false,
                                  index: 0,
                                ),
                                _buildMembershipCard(
                                  title: 'Monthly',
                                  price: '\$19.99',
                                  features: [
                                    'Dream Analysis',
                                    'Exclusive Themes',
                                    'Ad-Free Experience',
                                    'Priority Support',
                                  ],
                                  isPopular: true,
                                  index: 1,
                                ),
                                _buildMembershipCard(
                                  title: 'Yearly',
                                  price: '\$99.99',
                                  features: [
                                    'Dream Analysis',
                                    'Exclusive Themes',
                                    'Ad-Free Experience',
                                    'Priority Support',
                                    'Early Access to Features',
                                  ],
                                  isPopular: false,
                                  index: 2,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      // Game Section
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Mini Games',
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        fontFamily: 'Outfit',
                                        color: Colors.white,
                                      ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Text(
                                      'New!',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            fontFamily: 'Outfit',
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            // Game Card
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/game/backgrounds/forest_background.png'),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Sleepy Sheep',
                                      style: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .override(
                                            fontFamily: 'Outfit',
                                            color: Colors.white,
                                            fontSize: 28,
                                          ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Help the sheep count dream portals in this fun endless runner!',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Outfit',
                                            color:
                                                Colors.white.withOpacity(0.9),
                                          ),
                                    ),
                                    SizedBox(height: 16),
                                    FFButtonWidget(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => GameScreen(),
                                          ),
                                        );
                                      },
                                      text: 'Play Now',
                                      icon: Icon(
                                        Icons.play_arrow_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      options: FFButtonOptions(
                                        width: double.infinity,
                                        height: 48,
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0, 0, 0, 0),
                                        iconPadding:
                                            EdgeInsetsDirectional.fromSTEB(
                                                0, 0, 0, 0),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        textStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              fontFamily: 'Outfit',
                                              color: Colors.white,
                                            ),
                                        elevation: 2,
                                        borderSide: BorderSide(
                                          color: Colors.transparent,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      // Dream Analysis Feature Card
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dream Analysis',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                  ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Get detailed analysis of your dreams with our AI-powered dream interpreter.',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                            ),
                            SizedBox(height: 16),
                            FFButtonWidget(
                              onPressed: () {
                                // TODO: Implement dream analysis
                              },
                              text: 'Try Now',
                              icon: Icon(
                                Icons.psychology,
                                size: 20,
                                color: Colors.white,
                              ),
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 48,
                                padding:
                                    EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                iconPadding:
                                    EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                color: FlutterFlowTheme.of(context).primary,
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      fontFamily: 'Outfit',
                                      color: Colors.white,
                                    ),
                                elevation: 2,
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 100),
                      // Add Free Coins button to the UI
                      _buildFreeCoinSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2D3E).withOpacity(0.95),
            Color(0xFF1F1F1F).withOpacity(0.90),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCoinPurchaseOption({
    required int coins,
    required String price,
    required bool isPopular,
    required int index,
  }) {
    final isSelected = _selectedCoinOption == index;
    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      height: 160,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Color(0xFF6C5DD3) : Colors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              if (isPopular)
                Positioned(
                  top: 8,
                  right: -20,
                  child: Transform.rotate(
                    angle: 0.8,
                    child: Container(
                      width: 70,
                      padding: EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF4D4D),
                      ),
                      child: Text(
                        'POPULAR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.zero,
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/lunacoin.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${coins} Coins',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          price,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setState(() => _selectedCoinOption = index);
                                    if (index < _availablePackages.length) {
                                      await _handlePurchase(
                                          _availablePackages[index]);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Purchase',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Color(0xFF6C5DD3)
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchAdButton() {
    return Container(
      margin: EdgeInsets.only(top: 12, bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _earnCoinsWithAd,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'Watch Ad for 10 Coins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isPopular,
    required int index,
  }) {
    final isSelected = _selectedMembershipOption == index;
    return Stack(
      children: [
        Container(
          width: isSelected ? 280 : 260,
          decoration: BoxDecoration(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? FlutterFlowTheme.of(context).primary
                  : Colors.white.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedMembershipOption = index;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  fontFamily: 'Outfit',
                                  color: Colors.white,
                                ),
                      ),
                      if (isSelected)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Selected',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Outfit',
                                      color: Colors.white,
                                    ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    price,
                    style: FlutterFlowTheme.of(context).titleLarge.override(
                          fontFamily: 'Outfit',
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                  ),
                  SizedBox(height: 12),
                  ...features.map((feature) => Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                feature,
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Outfit',
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  SizedBox(height: 12),
                  FFButtonWidget(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (index < _availablePackages.length) {
                              await _handlePurchase(_availablePackages[index]);
                            }
                          },
                    text: _isLoading ? 'Processing...' : 'Select Plan',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 36,
                      padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                      iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                      color: isSelected
                          ? FlutterFlowTheme.of(context).primary
                          : Colors.white.withOpacity(0.1),
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                fontFamily: 'Outfit',
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.8),
                              ),
                      elevation: 2,
                      borderSide: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isPopular)
          Positioned(
            top: 12,
            right: -35,
            child: Transform.rotate(
              angle: 0.8,
              child: Container(
                width: 120,
                padding: EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'POPULAR',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Add Free Coins button to the UI
  Widget _buildFreeCoinSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Free Luna Coins',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Watch a short video ad to earn 10 Luna Coins.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _earnCoinsWithAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent.withOpacity(0.6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Watch Ad for 10 Coins',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
