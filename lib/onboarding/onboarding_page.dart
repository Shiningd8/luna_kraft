import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:luna_kraft/onboarding/onboarding_data.dart';

class OnboardingPage extends StatefulWidget {
  final OnboardingPageData page;
  final int pageIndex;

  const OnboardingPage({
    Key? key,
    required this.page,
    required this.pageIndex,
  }) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Start animation after a brief delay to allow for page transition
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation section (depends on the animation type)
          Expanded(
            flex: 6,
            child: _buildAnimation(),
          ),

          // Title
          Text(
            widget.page.title,
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
            widget.page.description,
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

          // CTA Button (if specified)
          if (widget.page.ctaText != null) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Handle CTA action (like permission request)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3D376F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: Text(
                widget.page.ctaText!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate(delay: 600.ms).fadeIn(
                  duration: 1000.ms,
                  curve: Curves.easeOutCubic,
                ),
          ],

          const SizedBox(height: 120), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildAnimation() {
    switch (widget.page.animationType) {
      case AnimationType.lottie:
        return _buildLottieAnimation();
      case AnimationType.custom:
        return _buildCustomAnimation();
      case AnimationType.particles:
        return _buildParticleAnimation();
      case AnimationType.imageSequence:
        return _buildImageSequence();
      default:
        return _buildLottieAnimation();
    }
  }

  Widget _buildLottieAnimation() {
    // Check if animation path is provided
    if (widget.page.animationPath.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use Lottie for standard animations
    return Container(
      padding: const EdgeInsets.all(20),
      child: Lottie.asset(
        widget.page.animationPath,
        controller: _animationController,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        options: LottieOptions(enableMergePaths: true),
        frameRate: FrameRate.max,
        // Add error builder to handle JSON parsing errors
        errorBuilder: (context, exception, stackTrace) {
          // Show a fallback widget when there's an error loading the animation
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.monetization_on,
              size: 80,
              color: Colors.white,
            ),
          );
        },
      ),
    ).animate().fade(duration: 800.ms);
  }

  Widget _buildCustomAnimation() {
    switch (widget.pageIndex) {
      case 2: // Social Connections (index 2)
        return _buildSocialNetworkAnimation();
      case 4: // LunaCoins (index 4)
        return _buildLunaCoinsAnimation();
      case 5: // Zen Mode (index 5)
        return _buildSoundWaveAnimation();
      default:
        return Container();
    }
  }

  Widget _buildSocialNetworkAnimation() {
    // Custom network animation with avatars and connecting lines
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: NetworkPainter(_animationController.value),
          child: Container(),
        );
      },
    ).animate().fade(duration: 1000.ms);
  }

  Widget _buildSoundWaveAnimation() {
    // Custom sound wave animation for Zen Mode
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 10,
                height: 100.0 * (0.4 + (index % 3) * 0.2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(5),
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                    delay: 100.ms * index,
                  )
                  .scaleY(
                    begin: 0.3,
                    end: 1.0,
                    duration: 800.ms,
                    curve: Curves.easeInOut,
                  );
            }),
          ),
        ),

        const SizedBox(height: 40),

        // Sound options
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSoundOption("Rain", Icons.water_drop),
            _buildSoundOption("Wind", Icons.air),
            _buildSoundOption("Ocean", Icons.waves),
          ],
        ).animate().fadeIn(delay: 300.ms, duration: 800.ms),
      ],
    );
  }

  Widget _buildSoundOption(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticleAnimation() {
    return Container(
      child: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              children: [
                // Moon
                Positioned(
                  top: 50,
                  right: 0,
                  left: 0,
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ).animate().scale(
                          begin: Offset(0.8, 0.8),
                          end: Offset(1.0, 1.0),
                          duration: 2000.ms,
                          curve: Curves.easeOut,
                        ),
                  ),
                ),

                // Stars in random positions
                ...List.generate(20, (index) {
                  final delay = (index * 100).ms;
                  final position = index * 20.0;
                  final size = 4.0 + (index % 3) * 2.0;

                  return Positioned(
                    left: (index * 17) % MediaQuery.of(context).size.width,
                    top: ((index * 25) % 200) + 20,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ).animate(delay: delay).fadeIn(duration: 500.ms).scaleXY(
                          begin: 0.5,
                          end: 1.0,
                          duration: 1000.ms,
                        ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageSequence() {
    // Placeholder for image sequence animation
    return Container();
  }

  Widget _buildLunaCoinsAnimation() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Main centered coin with animations
            Center(
              child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 2000),
                  tween: Tween<double>(begin: -5, end: 5),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, value),
                      child: Container(
                        width: 200,
                        height: 200,
                        child: Image.asset(
                          'assets/images/lunacoin.png',
                          fit: BoxFit.contain,
                        ),
                      )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1.05, 1.05),
                            duration: 1500.ms,
                            curve: Curves.easeInOut,
                          )
                          .rotate(
                            begin: -0.05,
                            end: 0.05,
                            duration: 2000.ms,
                            curve: Curves.easeInOut,
                          )
                          .shimmer(
                            duration: 2500.ms,
                            color: Colors.yellow.withOpacity(0.3),
                          ),
                    );
                  }),
            ),

            // Small coin 1
            Positioned(
              top: 80,
              left: centerX - 80,
              child: _buildSmallCoin(0),
            ),

            // Small coin 2
            Positioned(
              top: 100,
              right: centerX - 70,
              child: _buildSmallCoin(400),
            ),

            // Small coin 3
            Positioned(
              top: 60,
              right: centerX - 130,
              child: _buildSmallCoin(800),
            ),
          ],
        );
      }),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildSmallCoin(int delayMs) {
    return TweenAnimationBuilder(
        duration: const Duration(milliseconds: 1500),
        tween: Tween<double>(begin: 0, end: -40),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value),
            child: TweenAnimationBuilder(
                duration: const Duration(milliseconds: 1500),
                tween: Tween<double>(begin: 1.0, end: 0.0),
                curve: Curves.easeIn,
                builder: (context, opacity, child) {
                  return Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'assets/images/lunacoin.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }),
          );
        });
  }
}

// Custom painter for the social network animation
class NetworkPainter extends CustomPainter {
  final double animationValue;

  NetworkPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw connecting lines
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6 * animationValue)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Central node
    final centralNodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), 15, centralNodePaint);

    // Surrounding nodes
    final nodePositions = [
      Offset(centerX - 80, centerY - 60),
      Offset(centerX + 90, centerY - 40),
      Offset(centerX - 100, centerY + 20),
      Offset(centerX + 70, centerY + 70),
      Offset(centerX - 40, centerY + 90),
    ];

    for (var i = 0; i < nodePositions.length; i++) {
      // Only show nodes up to the animation progress
      if (i <= (nodePositions.length * animationValue)) {
        // Draw connection line
        final path = Path();
        path.moveTo(centerX, centerY);
        path.lineTo(nodePositions[i].dx, nodePositions[i].dy);
        canvas.drawPath(path, paint);

        // Draw node
        final nodePaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(nodePositions[i], 10, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
