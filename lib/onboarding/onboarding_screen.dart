import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:luna_kraft/onboarding/onboarding_data.dart';
import 'package:luna_kraft/onboarding/onboarding_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
    return Scaffold(
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

          // Animated stars in background
          ...List.generate(30, (index) {
            final random = index * 3.14159 / 15;
            return Positioned(
              left: 100 * (index % 5) + 20,
              top: 60 * (index ~/ 5) + 40,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .scaleXY(
                    begin: 0.5,
                    end: 1.5,
                    curve: Curves.easeInOut,
                    duration: 1500.ms,
                  )
                  .fadeIn(
                    curve: Curves.easeIn,
                    duration: (700 + index * 100).ms,
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

              // Final page with profile selection
              if (index == onboardingPages.length - 1) {
                return FinalOnboardingPage(
                  title: page.title,
                  description: page.description,
                  selectedProfileType: _profileType,
                  onProfileSelect: _selectProfileType,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
    );
  }
}

class FinalOnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String selectedProfileType;
  final Function(String) onProfileSelect;

  const FinalOnboardingPage({
    Key? key,
    required this.title,
    required this.description,
    required this.selectedProfileType,
    required this.onProfileSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title with animation
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
              .animate()
              .fade(duration: 500.ms)
              .slide(begin: Offset(0, 20), end: Offset.zero),

          SizedBox(height: 20),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          )
              .animate(delay: 200.ms)
              .fade(duration: 500.ms)
              .slide(begin: Offset(0, 20), end: Offset.zero),

          SizedBox(height: 40),

          Text(
            "Choose your dreamer profile:",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ).animate(delay: 400.ms).fade(duration: 500.ms),

          SizedBox(height: 30),

          // Profile type selection
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProfileTypeButton(
                  "Dreamer", selectedProfileType == "Dreamer", onProfileSelect),
              SizedBox(width: 15),
              _buildProfileTypeButton("Explorer",
                  selectedProfileType == "Explorer", onProfileSelect),
              SizedBox(width: 15),
              _buildProfileTypeButton("Observer",
                  selectedProfileType == "Observer", onProfileSelect),
            ],
          )
              .animate(delay: 600.ms)
              .fade(duration: 500.ms)
              .slideY(begin: 20, end: 0),
        ],
      ),
    );
  }

  Widget _buildProfileTypeButton(
      String type, bool isSelected, Function(String) onSelect) {
    return InkWell(
      onTap: () => onSelect(type),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          type,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Color(0xFF3D376F) : Colors.white,
          ),
        ),
      ),
    );
  }
}
