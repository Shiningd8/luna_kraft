import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    Key? key,
    required this.onAnimationComplete,
  }) : super(key: key);

  final VoidCallback onAnimationComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _logoController;
  late AnimationController _starsController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  // Animation states
  bool _showLogo = false;
  bool _showStars = false;
  bool _showText = false;
  bool _finishAnimation = false;
  bool _showShiningEffect = false;

  // Stars generation
  final List<_Star> _stars = [];
  final int _starCount = 150;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style to immersive for splash screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Generate random stars
    final random = math.Random();
    for (int i = 0; i < _starCount; i++) {
      _stars.add(_Star(
        x: random.nextDouble() * 1.2 -
            0.1, // -0.1 to 1.1 to allow stars slightly off-screen
        y: random.nextDouble() * 1.2 - 0.1,
        size: random.nextDouble() * 2.5 + 0.5, // 0.5 to 3.0
        opacity: random.nextDouble() * 0.7 + 0.3, // 0.3 to 1.0
        twinkleSpeed: random.nextDouble() * 2 + 1, // 1.0 to 3.0
      ));
    }

    // Setup animation controllers
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000),
    );

    // Start animation sequence
    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    // Start with background animation
    _backgroundController.forward();
    await Future.delayed(Duration(milliseconds: 300));

    // Show and animate stars
    if (!mounted) return;
    setState(() => _showStars = true);
    _starsController.repeat();
    _rotateController.repeat();
    await Future.delayed(Duration(milliseconds: 400));

    // Animate logo with entrance effect
    if (!mounted) return;
    setState(() => _showLogo = true);
    _logoController.forward();
    await Future.delayed(Duration(milliseconds: 400));

    // Start pulsing animation for logo
    _pulseController.repeat(reverse: true);
    await Future.delayed(Duration(milliseconds: 400));

    // Show app name with special animation
    if (!mounted) return;
    setState(() => _showText = true);
    _textController.forward();
    await Future.delayed(Duration(milliseconds: 800));

    // Show shining effect
    if (!mounted) return;
    setState(() => _showShiningEffect = true);
    await Future.delayed(Duration(milliseconds: 1200));

    // Finish animation
    if (!mounted) return;
    setState(() => _finishAnimation = true);
    await Future.delayed(Duration(milliseconds: 800));

    // Return to normal UI mode and complete
    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      widget.onAnimationComplete();
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    _starsController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Night Sky Background with image
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Opacity(
                opacity: _backgroundController.value,
                child: AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle:
                            _rotateController.value * 0.03, // Subtle rotation
                        child: Transform.scale(
                          scale: 1.0 +
                              (_backgroundController.value *
                                  0.1), // Subtle zoom
                          child: Image.asset(
                            'assets/images/splashbg.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }),
              );
            },
          ),

          // Stars (optional, since background might already have stars)
          if (_showStars)
            AnimatedBuilder(
              animation: _starsController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _StarryNightPainter(
                    stars: _stars,
                    animationValue: _starsController.value,
                    starOpacity: _finishAnimation
                        ? 1.0 - (_starsController.value * 0.8)
                        : 1.0,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          // Shooting stars effect
          if (_showStars)
            AnimatedBuilder(
              animation: _starsController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ShootingStarPainter(
                    animationValue: _starsController.value,
                    starOpacity: _finishAnimation ? 0.0 : 0.8,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          // Logo (Crescent Moon)
          if (_showLogo)
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Positioned(
                  top: MediaQuery.of(context).size.height * 0.25,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _finishAnimation
                        ? 1.0 - (_logoController.value * 0.9)
                        : _logoController.value,
                    duration: Duration(milliseconds: 600),
                    child: Center(
                      child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset:
                                  Offset(0, (1 - _logoController.value) * 30),
                              child: Transform.scale(
                                scale: 1.0 + _pulseController.value * 0.05,
                                child: Image.asset(
                                  'assets/images/lunamoon.png',
                                  width: 180,
                                  height: 180,
                                ).animate(target: _logoController.value).scale(
                                    begin: const Offset(0.6, 0.6),
                                    end: const Offset(1.0, 1.0),
                                    duration: 800.ms,
                                    curve: Curves.elasticOut),
                              ),
                            );
                          }),
                    ),
                  ),
                );
              },
            ),

          // Shine effect on the moon
          if (_showShiningEffect && _showLogo && !_finishAnimation)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: _ShineEffectPainter(
                      animationValue: _starsController.value,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),
            ),

          // Luna Kraft Text
          if (_showText)
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.35,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _finishAnimation ? 0.0 : 1.0,
                duration: Duration(milliseconds: 500),
                child: Column(
                  children: [
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildAnimatedLetters("LUNAKRAFT"),
                      ),
                    ),

                    // Tagline
                    SizedBox(height: 20),
                    Text(
                      'DREAM • SHARE • CONNECT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontFamily: 'Figtree',
                        letterSpacing: 4.0,
                        fontWeight: FontWeight.w300,
                      ),
                    )
                        .animate(target: _finishAnimation ? 0 : 1)
                        .fadeIn(
                            duration: 800.ms,
                            delay: 800.ms,
                            curve: Curves.easeOut)
                        .slideY(
                            begin: 0.3,
                            end: 0,
                            duration: 800.ms,
                            delay: 800.ms,
                            curve: Curves.easeOut)
                        .shimmer(
                            duration: 1800.ms,
                            delay: 1200.ms,
                            color: Colors.white.withOpacity(0.9))
                        .then(delay: 600.ms)
                        .fadeOut(duration: 500.ms),
                  ],
                ),
              ),
            ),

          // Loading Indicator
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _showText && !_finishAnimation ? 1.0 : 0.0,
                duration: Duration(milliseconds: 400),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: Offset(0.5, 0.5), duration: 400.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedLetters(String text) {
    List<Widget> letters = [];

    for (int i = 0; i < text.length; i++) {
      letters.add(
        Text(
          text[i],
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w600,
            fontFamily: 'Figtree',
            letterSpacing: 4.0,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.7),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        )
            .animate(target: _showText ? 1 : 0)
            .fadeIn(
              duration: 400.ms,
              delay: Duration(milliseconds: 150 * i),
              curve: Curves.easeOut,
            )
            .slideY(
              begin: 0.5,
              end: 0,
              duration: 600.ms,
              delay: Duration(milliseconds: 150 * i),
              curve: Curves.elasticOut,
            ),
      );
    }

    return letters;
  }
}

// Star class to hold properties for each star
class _Star {
  final double x; // Normalized x position (0-1)
  final double y; // Normalized y position (0-1)
  final double size; // Size of star
  final double opacity; // Base opacity
  final double twinkleSpeed; // How quickly the star twinkles

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.twinkleSpeed,
  });
}

// Custom painter for starry night effect
class _StarryNightPainter extends CustomPainter {
  final List<_Star> stars;
  final double animationValue;
  final double starOpacity;

  _StarryNightPainter({
    required this.stars,
    required this.animationValue,
    required this.starOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final star in stars) {
      // Calculate current opacity with twinkling effect
      final twinklePhase = (animationValue * star.twinkleSpeed) % 1.0;
      final twinkleFactor = math.sin(twinklePhase * math.pi * 2);
      final currentOpacity =
          (star.opacity + twinkleFactor * 0.3).clamp(0.0, 1.0) * starOpacity;

      // Set paint properties
      paint.color = Colors.white.withOpacity(currentOpacity);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, star.size * 0.5);

      // Calculate position
      final x = star.x * size.width;
      final y = star.y * size.height;

      // Draw star
      canvas.drawCircle(Offset(x, y), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(_StarryNightPainter oldPainter) =>
      animationValue != oldPainter.animationValue ||
      starOpacity != oldPainter.starOpacity;
}

// Custom painter for shooting stars effect
class _ShootingStarPainter extends CustomPainter {
  final double animationValue;
  final double starOpacity;
  final List<_ShootingStar> _shootingStars = [];

  _ShootingStarPainter({
    required this.animationValue,
    required this.starOpacity,
  }) {
    // Create a few shooting stars with different timings
    final random = math.Random(42); // Fixed seed for consistent generation
    for (int i = 0; i < 5; i++) {
      _shootingStars.add(_ShootingStar(
        startX: random.nextDouble() * 0.8,
        startY: random.nextDouble() * 0.4,
        length: random.nextDouble() * 0.2 + 0.1,
        angle: -math.pi / 4 + (random.nextDouble() * 0.5),
        speed: random.nextDouble() * 0.5 + 1.0,
        delay: random.nextDouble() * 0.8,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (starOpacity <= 0) return;

    for (final star in _shootingStars) {
      // Calculate current progress with delay
      final progress = (animationValue * star.speed - star.delay) % 1.0;

      // Only draw when progress is between 0 and 1
      if (progress > 0 && progress < 1) {
        final paint = Paint()
          ..color = Colors.white.withOpacity(starOpacity * (1 - progress));

        // Calculate start position
        final startX = star.startX * size.width;
        final startY = star.startY * size.height;

        // Calculate current position
        final currentX =
            startX + math.cos(star.angle) * progress * size.width * star.length;
        final currentY = startY +
            math.sin(star.angle) * progress * size.height * star.length;

        // Adjustable trail length
        final trailLength = (1 - progress) * 0.08;

        // Draw trail
        final trailPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0),
              Colors.white.withOpacity(starOpacity * 0.8)
            ],
            stops: [0.0, 1.0],
          ).createShader(Rect.fromPoints(
            Offset(currentX - math.cos(star.angle) * size.width * trailLength,
                currentY - math.sin(star.angle) * size.height * trailLength),
            Offset(currentX, currentY),
          ));

        canvas.drawLine(
            Offset(currentX - math.cos(star.angle) * size.width * trailLength,
                currentY - math.sin(star.angle) * size.height * trailLength),
            Offset(currentX, currentY),
            trailPaint..strokeWidth = 2.0);

        // Draw head of shooting star
        canvas.drawCircle(Offset(currentX, currentY), 2.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ShootingStarPainter oldPainter) =>
      animationValue != oldPainter.animationValue ||
      starOpacity != oldPainter.starOpacity;
}

// Shooting star properties
class _ShootingStar {
  final double startX;
  final double startY;
  final double length;
  final double angle;
  final double speed;
  final double delay;

  _ShootingStar({
    required this.startX,
    required this.startY,
    required this.length,
    required this.angle,
    required this.speed,
    required this.delay,
  });
}

// Shine effect painter
class _ShineEffectPainter extends CustomPainter {
  final double animationValue;

  _ShineEffectPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Calculate shine position
    final shineProgress = (animationValue * 0.5) % 1.0;
    final shineAngle = shineProgress * 2 * math.pi;

    // Create shine gradient
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          0.5 + math.cos(shineAngle) * 0.5,
          0.5 + math.sin(shineAngle) * 0.5,
        ),
        radius: 0.2,
        colors: [
          Colors.white.withOpacity(0.7),
          Colors.transparent,
        ],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw shine
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_ShineEffectPainter oldPainter) =>
      animationValue != oldPainter.animationValue;
}
