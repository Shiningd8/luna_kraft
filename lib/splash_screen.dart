import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

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
  // Add back audio player
  late AudioPlayer _audioPlayer;
  
  // Animation controllers
  late AnimationController _fadeInController;
  late AnimationController _logoAnimController;
  late AnimationController _fadeOutController;

  // Animation values
  late Animation<double> _fadeIn;
  late Animation<double> _logoScale;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    // Initialize audio player
    _audioPlayer = AudioPlayer();
    _initializeAudio();

    // Initialize controllers with shorter durations
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create animations
    _fadeIn = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeIn,
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

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeOutController,
        curve: Curves.easeOut,
      ),
    );

    // Run animation sequence
    _runAnimationSequence();
  }

  Future<void> _initializeAudio() async {
    try {
      // Set up audio player with intro music
      await _audioPlayer.setAsset('assets/audio/splashintro.mp3');
      await _audioPlayer.setVolume(0.8); // Set volume to 80%
      await _audioPlayer.play();
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  Future<void> _runAnimationSequence() async {
    // Start with fade in and logo animation
    _fadeInController.forward();
    _logoAnimController.forward();
    await Future.delayed(Duration(milliseconds: 500));

    // Wait for animations to complete
    await Future.delayed(Duration(milliseconds: 2000));

    // Gradually decrease volume before fade out
    for (double volume = 0.8; volume >= 0.0; volume -= 0.1) {
      if (!mounted) break;
      await _audioPlayer.setVolume(volume);
      await Future.delayed(Duration(milliseconds: 50));
    }

    // Fade out everything
    await _fadeOutController.forward();

    // Stop audio
    await _audioPlayer.stop();

    // Complete splash screen
    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      widget.onAnimationComplete();
    }
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _logoAnimController.dispose();
    _fadeOutController.dispose();
    _audioPlayer.dispose();
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Simple gradient background
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

                // Centered logo and text
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      AnimatedBuilder(
                        animation: Listenable.merge([_fadeIn, _logoScale]),
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeIn.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Image.asset(
                                'assets/images/translogo.png',
                                width: 150,
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 20),

                      // App name text
                      AnimatedBuilder(
                        animation: _fadeIn,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeIn.value,
                            child: Text(
                              'LunaKraft',
                              style: GoogleFonts.montserrat(
                                fontSize: 48,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
