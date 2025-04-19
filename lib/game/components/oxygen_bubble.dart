import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../main_game.dart';
import 'sheep.dart';
import 'dart:math' as math;

class OxygenBubble extends CircleComponent
    with CollisionCallbacks, HasGameRef<SleepySheepGame> {
  // Bubble properties
  static const double _baseSpeed = 140.0;
  static const double _scoreValue = 10.0;
  static const double _bubbleRadius = 20.0;
  final math.Random _random = math.Random();

  // Store initial position for safety
  final Vector2 _initialPosition;

  OxygenBubble({required Vector2 position})
      : _initialPosition = position.clone(),
        super(
          radius: _bubbleRadius,
          position: position,
          anchor: Anchor.center,
          paint: Paint()
            ..color = Colors.lightBlue.withOpacity(0.7)
            ..style = PaintingStyle.fill,
        ) {
    // Set anchor directly in constructor to ensure it's set
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    // Ensure anchor is properly set
    anchor = Anchor.center;

    // Add a shimmering effect to the bubble
    final shimmerPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final shimmer = CircleComponent(
      radius: radius * 0.3,
      position: Vector2(radius * 0.3, radius * 0.3),
      anchor: Anchor.topLeft,
      paint: shimmerPaint,
    );

    add(shimmer);

    // Add a glowing outline
    final outlinePaint = Paint()
      ..color = Colors.lightBlue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final outline = CircleComponent(
      radius: radius + 3,
      position: Vector2.zero(),
      anchor: Anchor.center,
      paint: outlinePaint,
    );

    add(outline);

    // Add pulsing size effect
    add(
      ScaleEffect.by(
        Vector2.all(1.2),
        EffectController(
          duration: 0.8,
          reverseDuration: 0.8,
          infinite: true,
        ),
      ),
    );

    // Add floating up-down motion
    add(
      MoveEffect.by(
        Vector2(0, 10),
        EffectController(
          duration: 1.2,
          reverseDuration: 1.2,
          infinite: true,
        ),
      ),
    );

    // Add collision detection
    add(
      CircleHitbox(
        radius: radius * 0.8,
        position: Vector2.zero(),
        anchor: Anchor.center,
      )..debugMode = false,
    );
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Sheep) {
      // Collect the bubble
      collectBubble();
    }
  }

  void collectBubble() {
    try {
      // Add score
      gameRef.score += _scoreValue.toInt();

      // Check if position is valid, if not use initial position
      final effectPosition = position.isNaN ? _initialPosition : position;

      // Create collection effect
      final collectionEffect = CircleComponent(
        radius: radius * 2,
        position: effectPosition,
        anchor: Anchor.center,
        paint: Paint()..color = Colors.white.withOpacity(0.7),
      );

      // Explicitly set anchor to prevent _centerOffset error
      collectionEffect.anchor = Anchor.center;

      // Add expanding and fading effect
      collectionEffect.add(
        ScaleEffect.by(
          Vector2.all(3.0),
          EffectController(
            duration: 0.5,
            curve: Curves.easeOut,
          ),
          onComplete: () => collectionEffect.removeFromParent(),
        ),
      );

      collectionEffect.add(
        OpacityEffect.fadeOut(
          EffectController(
            duration: 0.5,
          ),
        ),
      );

      // Add the collection effect to the game
      gameRef.add(collectionEffect);

      // Remove the bubble itself
      removeFromParent();
    } catch (e) {
      print('ERROR in collectBubble: $e');
      // Just remove the bubble if effect creation fails
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Skip updates if game is paused or over
    if (gameRef.isPaused || gameRef.isGameOver) return;

    try {
      // Safety check to prevent the disappearing issue
      if (position.isNaN || position.x.isNaN || position.y.isNaN) {
        print(
            'WARNING: OxygenBubble has invalid position. Removing from game.');
        removeFromParent();
        return;
      }

      // Move from right to left with slight variation in speed
      position.x -= (_baseSpeed + _random.nextDouble() * 20) * dt;

      // Remove if off screen
      if (position.x < -radius * 2) {
        removeFromParent();
      }
    } catch (e) {
      print('ERROR in oxygen bubble update: $e');
      removeFromParent(); // Remove problematic bubble
    }
  }
}
