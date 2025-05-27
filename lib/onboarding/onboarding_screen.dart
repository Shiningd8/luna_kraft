import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:luna_kraft/onboarding/onboarding_data.dart';
import 'package:luna_kraft/onboarding/onboarding_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _backgroundAnimController;
  bool _showSkip = true;
  String _profileType = "Dreamer"; // Default profile type

  @override
  void initState() {
    super.initState();
    _backgroundAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _showSkip = page < onboardingPages.length - 1;
    });
  }

  void _nextPage() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      print(
          'Onboarding completed - calling onComplete callback with profile type: $_profileType');
      // Ensure we mark completion with the selected profile type
      widget.onComplete();
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      onboardingPages.length - 1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _selectProfileType(String type) {
    setState(() {
      _profileType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        body: Stack(
          children: [
            // Animated background
            AnimatedBuilder(
              animation: _backgroundAnimController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 24, 26, 51),
                        Color.fromARGB(255, 39, 47, 87),
                        Color.fromARGB(255, 61, 55, 95),
                      ],
                      stops: [
                        0,
                        _backgroundAnimController.value * 0.5 + 0.3,
                        1.0,
                      ],
                    ),
                  ),
                );
              },
            ),

            // Animated stars in background with natural pattern
            ...List.generate(40, (index) {
              // Use Math.sin and Math.cos with random values to create organic patterns
              final randomAngle = (index * 0.62831853 + index * 0.1);
              final randomRadius = (index % 5) * 60.0 + (index * 3.7) % 40;
              final randomSize = (index % 3) * 0.7 + 1.2; // Varied star sizes
              final delay = (index * 37) % 500; // Varied animation delays
              
              return Positioned(
                // Use sin/cos for more organic positioning, with varied offsets
                left: MediaQuery.of(context).size.width * (0.1 + 0.8 * ((math.sin(randomAngle) + 1) / 2)),
                top: 80 + 200 * ((math.cos(randomAngle) + 1) / 2) + (index % 7) * 10,
                child: Container(
                  width: randomSize,
                  height: randomSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7 + (index % 4) * 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: randomSize,
                        spreadRadius: randomSize * 0.2,
                      ),
                    ],
                  ),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scaleXY(
                      begin: 0.7,
                      end: 1.2,
                      curve: Curves.easeInOut,
                      duration: (1200 + (index % 7) * 300).ms,
                    )
                    .fadeIn(
                      curve: Curves.easeIn,
                      duration: (700 + delay).ms,
                    ),
              );
            }),

            // Main content - PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: onboardingPages.length,
              itemBuilder: (context, index) {
                final page = onboardingPages[index];

                // Final page with simplified layout
                if (index == onboardingPages.length - 1) {
                  return SimpleFinalOnboardingPage(
                    page: page,
                  );
                }

                return OnboardingPage(
                  page: page,
                  pageIndex: index,
                );
              },
            ),

            // Bottom navigation controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip button - only show on pages before the last one
                    if (_showSkip)
                      TextButton(
                        onPressed: _skipToEnd,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    else
                      SizedBox(width: 60),

                    // Page indicator
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: onboardingPages.length,
                      effect: ExpandingDotsEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 4,
                        expansionFactor: 3,
                        activeDotColor: Colors.white,
                        dotColor: Colors.white.withOpacity(0.3),
                      ),
                    ),

                    // Next/Enter button
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF3D376F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        _currentPage < onboardingPages.length - 1
                            ? 'Next'
                            : 'Enter Lunakraft',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class SimpleFinalOnboardingPage extends StatelessWidget {
  final OnboardingPageData page;

  const SimpleFinalOnboardingPage({
    Key? key,
    required this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation section
          Expanded(
            flex: 6,
            child: _buildParticleAnimation(),
          ),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ).animate().fadeIn(
                duration: 1000.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ).animate(delay: 300.ms).fadeIn(
                duration: 1200.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 120), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildParticleAnimation() {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        child: Center(
          child: Stack(
            children: [
              // Enhanced Moon with lunar details
              Positioned(
                top: 50,
                right: 0,
                left: 0,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Moon glow
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                      ),
                      
                      // Main moon surface
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment(-0.2, -0.2),
                            radius: 0.9,
                            colors: [
                              Color(0xFFF5F5F5), // Bright white center
                              Color(0xFFE0E0E0), // Light gray
                              Color(0xFFCECECE), // Medium gray edge
                            ],
                            stops: [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                      
                      // Lunar craters
                      Positioned(
                        top: 30,
                        left: 30,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.05),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                                offset: Offset(-1, -1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Smaller crater
                      Positioned(
                        top: 60,
                        right: 35,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.04),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 3,
                                spreadRadius: 1,
                                offset: Offset(-1, -1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Tiny crater
                      Positioned(
                        bottom: 35,
                        left: 40,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.03),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 2,
                                spreadRadius: 1,
                                offset: Offset(-1, -1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().scale(
                    begin: Offset(0.8, 0.8),
                    end: Offset(1.0, 1.0),
                    duration: 2000.ms,
                    curve: Curves.easeOut,
                  ),
                ),
              ),

              // Stars in random positions with natural pattern
              ...List.generate(25, (index) {
                final randomAngle = (index * 0.52831853 + index * 0.07);
                final randomRadius = 80 + (index % 7) * 15;
                final randomSize = 2.0 + (index % 4) * 0.8;
                final delay = (index * 43) % 600;

                // Calculate position using polar coordinates for a more natural spread
                final x = constraints.maxWidth / 2 + 
                    randomRadius * math.cos(randomAngle) * 
                    (0.5 + (index % 5) * 0.1);
                    
                final y = 120 + 
                    randomRadius * math.sin(randomAngle) * 
                    (0.5 + (index % 3) * 0.1);

                return Positioned(
                  left: x % constraints.maxWidth,
                  top: y % 250,
                  child: Container(
                    width: randomSize,
                    height: randomSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8 + (index % 3) * 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: randomSize,
                          spreadRadius: randomSize * 0.2,
                        ),
                      ],
                    ),
                  ).animate(delay: delay.ms)
                    .fadeIn(duration: 800.ms)
                    .scaleXY(
                      begin: 0.6,
                      end: 1.2,
                      duration: (1500 + (index % 5) * 300).ms,
                    ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }
}
