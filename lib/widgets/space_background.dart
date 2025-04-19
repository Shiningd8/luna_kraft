import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart';

class SpaceBackground extends StatefulWidget {
  final Widget child;
  final bool lowPerformanceMode;

  const SpaceBackground({
    Key? key,
    required this.child,
    this.lowPerformanceMode = false,
  }) : super(key: key);

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground>
    with TickerProviderStateMixin {
  double _targetOffsetX = 0;
  double _targetOffsetY = 0;
  double _currentOffsetX = 0;
  double _currentOffsetY = 0;
  late List<Star> _stars;
  final Random _random = Random();
  late AnimationController _simulationController;
  bool _isSimulatingMotion = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Optimized parameters
  final double _smoothingFactor = 0.1; // Smoother with less lag
  final double _motionMultiplier = 0.15; // Reduced for better performance
  int _lastUpdateTime = 0;
  final int _throttleMs = 100; // Limit updates to reduce CPU load
  AccelerometerEvent? _lastEvent;

  @override
  void initState() {
    super.initState();

    // Reduce star count further for web platform
    final int starCount = kIsWeb
        ? (widget.lowPerformanceMode ? 40 : 70)
        : (widget.lowPerformanceMode ? 60 : 100);

    // Generate fewer stars for better performance
    _stars = List.generate(
      starCount,
      (_) => Star(
        x: _random.nextDouble() * 1.0,
        y: _random.nextDouble() * 1.0,
        size: 1.0 + _random.nextDouble() * 2.0,
        twinkleSpeed: 0.3 + _random.nextDouble() * 1.2, // Slower twinkle
        parallaxFactor: 0.3 +
            _random.nextDouble() * 1.2, // Less parallax for better performance
      ),
    );

    // Setup simulation controller - slower for web
    _simulationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: kIsWeb ? 20 : 10), // Slower on web
    )..addListener(() {
        if (_isSimulatingMotion) {
          // Use less intensive motion values for web
          final double amplitude = kIsWeb ? 1.0 : 1.5;
          _updateMotion(
            sin(_simulationController.value * 2 * pi) * amplitude,
            cos(_simulationController.value * 2 * pi) * amplitude,
          );
        }
      });

    // Start with simulation mode
    _isSimulatingMotion = true;
    _simulationController.repeat();

    // Initialize accelerometer
    _initializeAccelerometer();
  }

  @override
  void didUpdateWidget(SpaceBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lowPerformanceMode != oldWidget.lowPerformanceMode) {
      // Update stars count if performance mode changes
      setState(() {
        _stars = List.generate(
          widget.lowPerformanceMode ? 60 : 100,
          (_) => Star(
            x: _random.nextDouble() * 1.0,
            y: _random.nextDouble() * 1.0,
            size: 1.0 + _random.nextDouble() * 2.0,
            twinkleSpeed: 0.3 + _random.nextDouble() * 1.2,
            parallaxFactor: 0.3 + _random.nextDouble() * 1.2,
          ),
        );
      });
    }
  }

  void _updateMotion(double x, double y) {
    if (!mounted) return;

    // Throttle updates to reduce CPU load - use higher throttle on web
    final now = DateTime.now().millisecondsSinceEpoch;
    final throttleTime = kIsWeb ? 150 : _throttleMs; // Increase throttle on web
    if (now - _lastUpdateTime < throttleTime) {
      return;
    }
    _lastUpdateTime = now;

    setState(() {
      // Apply low-pass filter for smooth motion
      _targetOffsetX = x;
      _targetOffsetY = y;

      // Use different smoothing factor for web
      final smoothFactor = kIsWeb ? 0.05 : _smoothingFactor;
      _currentOffsetX += (_targetOffsetX - _currentOffsetX) * smoothFactor;
      _currentOffsetY += (_targetOffsetY - _currentOffsetY) * smoothFactor;
    });
  }

  Future<void> _initializeAccelerometer() async {
    try {
      // On web platforms, we just use the simulation mode with optimized parameters
      if (kIsWeb) {
        _debugLog(
            'Running in web environment, using optimized simulation mode');
        setState(() {
          _isSimulatingMotion = true;

          // Use a slower animation on web for better performance
          _simulationController.duration = Duration(seconds: 20);
          _simulationController.repeat();
        });
        return;
      }

      _debugLog('Initializing accelerometer...');
      await _accelerometerSubscription?.cancel();

      _accelerometerSubscription = accelerometerEvents.listen(
        (AccelerometerEvent event) {
          if (!mounted) return;

          _isSimulatingMotion = false;
          _simulationController.stop();

          // Store the event for throttled processing
          _lastEvent = event;

          // Don't call setState directly here - use throttled update
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - _lastUpdateTime >= _throttleMs) {
            // Apply motion multiplier and update
            _updateMotion(
              event.x * _motionMultiplier,
              event.y * _motionMultiplier,
            );
          }
        },
        onError: (error) {
          _debugLog('Accelerometer error: $error');
          if (mounted) {
            setState(() {
              _isSimulatingMotion = true;
              _simulationController.repeat();
            });
          }
        },
        cancelOnError: false,
      );

      await accelerometerEvents.first;
      _debugLog('Accelerometer initialized successfully');
    } catch (e) {
      _debugLog('Error initializing accelerometer: $e');
      if (mounted) {
        setState(() {
          _isSimulatingMotion = true;
          _simulationController.repeat();
        });
      }
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _simulationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background color (dark space)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF050A30), // Dark blue at top
                Color(0xFF000000), // Black at bottom
              ],
            ),
          ),
        ),

        // Animated stars with parallax effect
        // We don't use TweenAnimationBuilder to reduce rebuilds
        RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: StarsPainter(
              stars: _stars,
              offsetX: _currentOffsetX,
              offsetY: _currentOffsetY,
              opacity: 1.0,
              lowPerformanceMode: widget.lowPerformanceMode,
            ),
          ),
        ),

        // Static moon with subtle glow - wrapped in RepaintBoundary to optimize rendering
        if (!widget.lowPerformanceMode)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            right: MediaQuery.of(context).size.width * 0.1,
            child: RepaintBoundary(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.9),
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: MoonCratersPainter(),
                ),
              ),
            ),
          ),

        // Debug overlay
        if (_isSimulatingMotion && kDebugMode)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Simulated Motion',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),

        // Content
        widget.child,
      ],
    );
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      print('🌠 SpaceBackground: $message');
    }
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;
  final double parallaxFactor;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.parallaxFactor,
  });
}

class StarsPainter extends CustomPainter {
  final List<Star> stars;
  final double offsetX;
  final double offsetY;
  final double opacity;
  final bool lowPerformanceMode;
  final Random random = Random();
  // Cache the current time to avoid recalculating it for each star
  final int _nowMs = DateTime.now().millisecondsSinceEpoch;
  final bool _isWeb = kIsWeb;

  StarsPainter({
    required this.stars,
    required this.offsetX,
    required this.offsetY,
    this.opacity = 1.0,
    this.lowPerformanceMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = _nowMs / 1000;

    // Use a single paint object and just change color to reduce object creation
    final paint = Paint()..style = PaintingStyle.fill;

    // Limit the number of stars drawn on web for better performance
    final starsToRender =
        _isWeb ? stars.take(stars.length ~/ 1.5).toList() : stars;

    for (var star in starsToRender) {
      // Calculate position with individual parallax effect - use smaller multiplier for web
      final parallaxMultiplier = _isWeb ? 15 : 20;
      final double x = (star.x * size.width) +
          (offsetX * star.parallaxFactor * parallaxMultiplier);
      final double y = (star.y * size.height) +
          (offsetY * star.parallaxFactor * parallaxMultiplier);

      // Skip if star is outside visible area (with padding)
      if (x < -20 || x > size.width + 20 || y < -20 || y > size.height + 20) {
        continue;
      }

      // Calculate twinkle effect - use even more simplified math in web
      final twinkle = lowPerformanceMode || _isWeb
          ? 0.7 // Fixed brightness in low performance mode and web
          : (sin(now * star.twinkleSpeed) + 1) / 2;

      paint.color = Colors.white.withOpacity((0.3 + (twinkle * 0.7)) * opacity);

      // Draw star with size variation - simplified for web
      canvas.drawCircle(
          Offset(x, y),
          lowPerformanceMode || _isWeb
              ? star.size // Fixed size in low performance mode and web
              : star.size * (0.8 + (twinkle * 0.4)),
          paint);
    }
  }

  @override
  bool shouldRepaint(StarsPainter oldDelegate) {
    return oldDelegate.offsetX != offsetX ||
        oldDelegate.offsetY != offsetY ||
        oldDelegate.opacity != opacity;
  }
}

class MoonCratersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Random random = Random(42); // Fixed seed for consistent craters

    // Draw craters with different sizes and positions
    for (int i = 0; i < 8; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double craterSize = 3 + random.nextDouble() * 8;

      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.15)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), craterSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
