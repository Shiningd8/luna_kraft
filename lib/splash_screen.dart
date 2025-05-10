import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
  // Animation controllers
  late AnimationController _fadeInController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _fadeOutController;
  late AnimationController _logoAnimController;
  late AnimationController _particleController;
  late AnimationController _textSlideController;

  // Animation values
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _glow;
  late Animation<double> _fadeOut;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<Offset> _textSlide;

  // Stars for background
  final List<_Star> _stars = [];
  final List<_Particle> _particles = [];
  late AnimationController _starsController;

  @override
  void initState() {
    super.initState();

    // Generate stars for background
    final random = math.Random(42);
    for (int i = 0; i < 100; i++) {
      _stars.add(_Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 2.0 + 0.5,
        opacity: random.nextDouble() * 0.6 + 0.3,
        twinkleSpeed: random.nextDouble() * 0.5 + 0.5,
      ));
    }

    // Generate floating particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 1.2 + 0.3,
        speed: random.nextDouble() * 0.2 + 0.1,
        color: Color.fromRGBO(
          200 + random.nextInt(55),
          200 + random.nextInt(55),
          240,
          random.nextDouble() * 0.4 + 0.1,
        ),
        angle: random.nextDouble() * math.pi * 2,
      ));
    }

    // Set system UI overlay style to immersive for splash screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Initialize stars animation controller
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 2),
    )..repeat();

    // Initialize particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize controllers
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _textSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Create animations
    _fadeIn = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeIn,
    );

    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );

    _glow = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeOutController,
        curve: Curves.easeOut,
      ),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.1),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 60.0,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _logoAnimController,
        curve: Curves.easeInOut,
      ),
    );

    _logoRotation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(
        parent: _logoAnimController,
        curve: Curves.easeInOut,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textSlideController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Run animation sequence
    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    // Start with fade in and logo animation
    _fadeInController.forward();
    _logoAnimController.forward();
    await Future.delayed(Duration(milliseconds: 600));

    // Start text slide animation
    _textSlideController.forward();
    await Future.delayed(Duration(milliseconds: 300));

    // Start subtle scaling
    _scaleController.forward();
    await Future.delayed(Duration(milliseconds: 300));

    // Add glow effect
    _glowController.repeat(reverse: true);
    await Future.delayed(Duration(milliseconds: 2000));

    // Fade out everything
    _fadeOutController.forward();
    await _fadeOutController.forward().orCancel;

    // Return to normal UI mode and complete
    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      widget.onAnimationComplete();
    }
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _fadeOutController.dispose();
    _logoAnimController.dispose();
    _starsController.dispose();
    _particleController.dispose();
    _textSlideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeOutController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeOut.value,
          child: Material(
            color: Colors.black,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  // Starry background
                  AnimatedBuilder(
                    animation: _starsController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _StarryNightPainter(
                          stars: _stars,
                          animationValue: _starsController.value,
                          starOpacity: _fadeIn.value,
                        ),
                      );
                    },
                  ),

                  // Subtle space gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.0, 0.2),
                        radius: 1.5,
                        colors: [
                          Color(0xFF0A1128),
                          Color(0xFF090B16),
                          Colors.black,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  // Floating particles
                  AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ParticlesPainter(
                          particles: _particles,
                          animationValue: _particleController.value,
                        ),
                      );
                    },
                  ),

                  // Centered content with animations
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with animations
                        AnimatedBuilder(
                          animation: Listenable.merge(
                              [_logoOpacity, _logoScale, _logoRotation]),
                          builder: (context, child) {
                            return Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.rotate(
                                angle: _logoRotation.value,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Moon glow effect
                                      Container(
                                        width: 160,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white
                                                  .withOpacity(0.15),
                                              blurRadius: 30,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Moon image
                                      Image.asset(
                                        'assets/images/translogo.png',
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.contain,
                                      ),
                                      // Crater glow effect
                                      Positioned(
                                        top: 60,
                                        left: 45,
                                        child: Container(
                                          width: 15,
                                          height: 15,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withOpacity(
                                                    0.4 * _glow.value),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 40,
                                        right: 55,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withOpacity(
                                                    0.3 * _glow.value),
                                                blurRadius: 6,
                                                spreadRadius: 1,
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
                          },
                        ),

                        SizedBox(height: 24),

                        // App name text with animations
                        AnimatedBuilder(
                          animation: Listenable.merge(
                              [_fadeIn, _scale, _glow, _textSlide]),
                          builder: (context, child) {
                            return SlideTransition(
                              position: _textSlide,
                              child: Opacity(
                                opacity: _fadeIn.value,
                                child: Transform.scale(
                                  scale: _scale.value,
                                  child: ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Color(0xFFC7D3E9), // Light silver/blue
                                        Color(0xFFEEF2F9), // White/silver
                                        Color(0xFFADBDD7), // Blue-grey/silver
                                      ],
                                      stops: [0.0, 0.5, 1.0],
                                    ).createShader(bounds),
                                    child: Text(
                                      'LunaKraft',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2.5,
                                        shadows: [
                                          Shadow(
                                            color: Color(0xFFB6C2D6)
                                                .withOpacity(_glow.value),
                                            blurRadius: 15.0,
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Subtle shooting stars
                  AnimatedBuilder(
                    animation: _starsController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ShootingStarPainter(
                          animationValue: _starsController.value,
                          starOpacity: _fadeIn.value,
                        ),
                      );
                    },
                  ),

                  // Shine effect
                  AnimatedBuilder(
                    animation: _starsController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ShineEffectPainter(
                          animationValue: _starsController.value,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

// Particle class for floating dust particles
class _Particle {
  final double x; // Normalized x position (0-1)
  final double y; // Normalized y position (0-1)
  final double size; // Size of particle
  final double speed; // Speed of movement
  final Color color; // Particle color
  final double angle; // Movement angle

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.angle,
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

// Custom painter for floating particles
class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlesPainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate current position with slow movement
      final currentX = (particle.x +
              math.cos(particle.angle) * particle.speed * animationValue) %
          1.0;
      final currentY = (particle.y +
              math.sin(particle.angle) * particle.speed * animationValue) %
          1.0;

      // Pulse size effect
      final pulsePhase = (animationValue * 0.5 + currentX * 0.3) % 1.0;
      final pulseFactor = 0.2 * math.sin(pulsePhase * math.pi * 2) + 1.0;

      final paint = Paint()
        ..color = particle.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size);

      // Draw particle
      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height),
        particle.size * pulseFactor,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldPainter) =>
      animationValue != oldPainter.animationValue;
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
          Colors.white.withOpacity(0.5),
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
