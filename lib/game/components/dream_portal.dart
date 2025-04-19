import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';
import 'dart:ui';
import 'package:flutter/material.dart' show Colors, Curves;
import '../main_game.dart';
import 'sheep.dart';
import 'obstacle.dart';
import 'dart:math' as math;

class DreamPortal extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<SleepySheepGame> {
  static const double speed = 200;
  bool isActive = true;
  bool isTransitioning = false;
  final WorldState targetWorld;
  final String portalColor;

  // Add a random for debug messages
  final math.Random _random = math.Random();

  DreamPortal({
    required this.targetWorld,
    required this.portalColor,
  });

  @override
  Future<void> onLoad() async {
    try {
      print('Attempting to load portal: $portalColor');

      // Use the correct path format - Flame will prepend "assets/" automatically
      final assetPath = 'game/portals/${portalColor}_portal_sheet.png';

      print('Loading portal from path: $assetPath');

      // Load sprite sheet using the Flame engine's image loading system
      final sprite = await gameRef.images.load(assetPath);
      print('Successfully loaded sprite: ${sprite.width}x${sprite.height}');

      // Create animation from the sprite sheet
      animation = SpriteAnimation.fromFrameData(
        sprite,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.15,
          textureSize: Vector2(264, 413),
        ),
      );

      print(
          'Successfully created portal animation with ${animation?.frames.length ?? 0} frames');

      // Position and size the portal
      size = Vector2(160, 240);
      position = Vector2(gameRef.size.x, gameRef.size.y * 0.65);

      // Create a more visible hitbox for debugging
      final hitbox = RectangleHitbox(
        size: Vector2(size.x * 0.9, size.y * 0.9),
        position: Vector2(size.x * 0.05, size.y * 0.05),
      );

      // Set debug mode to true to visualize hitbox (remove for production)
      hitbox.debugMode = true;

      // Add the hitbox
      add(hitbox);

      // Add glow effect
      add(OpacityEffect.fadeOut(
        EffectController(
          duration: 0.5,
          reverseDuration: 0.5,
          infinite: true,
        ),
      ));

      print('Complete portal initialization successful');
    } catch (e) {
      print('ERROR LOADING PORTAL: $e');
      print('Stack trace: ${StackTrace.current}');
      removeFromParent();
      return;
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    // Add debug print for any collision
    print('PORTAL: Collision START with ${other.runtimeType}');

    // Immediately check for valid sheep collision
    if (other is Sheep &&
        isActive &&
        !isTransitioning &&
        !gameRef.isTransitioning) {
      _checkForValidPortalEntry(other, intersectionPoints);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Continuously check for portal entry while colliding
    if (other is Sheep &&
        isActive &&
        !isTransitioning &&
        !gameRef.isTransitioning) {
      _checkForValidPortalEntry(other, intersectionPoints);
    }
  }

  // Helper method to avoid code duplication and ensure reliable collision detection
  void _checkForValidPortalEntry(Sheep sheep, Set<Vector2> intersectionPoints) {
    // Get the sheep center
    final sheepCenter = sheep.position + (sheep.size / 2);
    final portalCenter = position + (size / 2);

    // Calculate horizontal distance
    final horizontalDistance = (sheepCenter.x - portalCenter.x).abs();

    // CRITICAL: Are we using intersectionPoints.isNotEmpty as a safety check
    if (horizontalDistance < sheep.size.x * 0.6 &&
        intersectionPoints.isNotEmpty) {
      // Print details of the collision
      print('PORTAL: Valid sheep entry detected!');
      print('PORTAL: Horizontal distance = $horizontalDistance');
      print('PORTAL: Intersection points = $intersectionPoints');

      // Show visual feedback
      _showCollisionEffect();

      // Trigger transition (only if not already in progress)
      if (!isTransitioning && !gameRef.isTransitioning) {
        // Set flags to prevent multiple triggers
        isTransitioning = true;
        isActive = false;
        gameRef.isTransitioning = true;

        print('PORTAL: Starting transition sequence!');
        // Start the portal transition sequence
        _startPortalTransition(sheep);
      }
    }
  }

  void _showCollisionEffect() {
    // Add a brief visual effect to show the collision was detected
    final effect = CircleComponent(
      radius: 10,
      position: size / 2,
      paint: Paint()..color = const Color(0xFFFFFFFF),
    );

    // Add pulsing effect
    effect.add(
      ScaleEffect.by(
        Vector2.all(5),
        EffectController(
          duration: 0.5,
          curve: Curves.easeOut,
        ),
        onComplete: () => effect.removeFromParent(),
      ),
    );

    // Add the effect
    add(effect);
  }

  void _startPortalTransition(Sheep sheep) {
    // Create a full-screen black overlay for transition
    final blackOverlay = RectangleComponent(
      size: gameRef.size,
      position: Vector2.zero(),
      paint: Paint()..color = const Color(0xFF000000), // Start fully black
    );
    blackOverlay.priority = 999; // Ensure it's on top of everything
    gameRef.add(blackOverlay);

    // Stop sheep movement but don't pause the game
    sheep.velocityY = 0;

    // Remove all obstacles immediately to prevent collisions during transition
    gameRef.children
        .whereType<Obstacle>()
        .forEach((obstacle) => obstacle.removeFromParent());

    // Remove the portal immediately
    removeFromParent();

    // Wait 3 seconds, then set up new world
    Future.delayed(Duration(seconds: 3), () {
      if (gameRef.isTransitioning) {
        // Check if we're still transitioning
        // Set up the new world while screen is black
        gameRef.setupNewWorld(targetWorld, blackOverlay);

        // Start fading out the black overlay
        blackOverlay.add(
          ColorEffect(
            const Color(0x00000000), // Fully transparent
            EffectController(
              duration: 0.5,
              curve: Curves.easeOut,
            ),
            onComplete: () {
              // Remove the overlay when fade out is complete
              blackOverlay.removeFromParent();
              // Reset transition state
              gameRef.isTransitioning = false;
            },
          ),
        );
      }
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isActive) {
      // Removed !gameRef.isPaused check since we don't pause anymore
      // Move portal from right to left
      position.x -= speed * dt;

      // Remove portal when it's off screen
      if (position.x < -size.x) {
        print('Portal removed as it went off screen');
        removeFromParent();
      }
    }
  }
}
