import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'dart:ui'; // For Paint, Color, and BlendMode
import '../main_game.dart';
import 'sheep.dart';
import 'dart:math' as math;

class Obstacle extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SleepySheepGame> {
  final String imagePath;
  double speed; // Changed from final to allow runtime updates
  final WorldState worldState;
  final bool isHaystack; // Flag to identify haystack obstacles
  final math.Random _random = math.Random();

  Obstacle({
    required this.imagePath,
    required this.speed,
    required this.worldState,
    this.isHaystack = false, // Default to false for regular obstacles
  });

  @override
  Future<void> onLoad() async {
    // Load the obstacle sprite
    sprite = await Sprite.load(imagePath, images: gameRef.images);

    // Set size based on obstacle type
    if (isHaystack) {
      // Make haystack significantly larger to require double jump
      size = Vector2(140, 170); // Much taller than wide for haystack

      // Hide haystacks in space world
      if (worldState == WorldState.space) {
        opacity = 0; // Make it invisible
      }
    } else {
      // Regular obstacles with world-specific sizes
      switch (worldState) {
        case WorldState.normal:
          size = Vector2(90, 90); // Increased from 60x60
          break;
        case WorldState.space:
          // Make space obstacles (asteroids) bigger
          size =
              Vector2(130, 130); // Significantly larger for better visibility
          break;
        case WorldState.underwater:
          // Make underwater obstacles (bubbles) varying sizes
          final randomSize = 60.0 + (_random.nextDouble() * 40.0);
          size = Vector2(randomSize, randomSize);
          break;
        case WorldState.candy:
          size = Vector2(90, 90); // Increased from 60x60
          break;
        case WorldState.forest:
          size = Vector2(95, 95); // Increased from 65x65
          break;
      }
    }

    // Position the obstacle based on world type
    if (worldState == WorldState.space) {
      // For space, position obstacles randomly throughout the vertical space
      final randomY = gameRef.size.y * (0.3 + (0.4 * _random.nextDouble()));
      position = Vector2(gameRef.size.x, randomY);

      // Add floating effect for space obstacles
      if (!isHaystack) {
        add(
          MoveEffect.by(
            Vector2(0, 15),
            EffectController(
              duration: 1.0,
              reverseDuration: 1.0,
              infinite: true,
            ),
          ),
        );
      }
    } else if (worldState == WorldState.underwater) {
      // For underwater, bubbles come from random positions at the bottom
      final randomX = gameRef.size.x + (_random.nextDouble() * 100);
      final randomY = gameRef.size.y * (0.2 + (_random.nextDouble() * 0.6));
      position = Vector2(randomX, randomY);

      // Add undulating movement for underwater obstacles
      if (!isHaystack) {
        // Random vertical movement speed
        final verticalSpeed = 20.0 + (_random.nextDouble() * 20.0);

        // Random horizontal movement speed
        final horizontalSpeed = 10.0 + (_random.nextDouble() * 15.0);

        // Add wavy motion by oscillating both X and Y
        add(
          MoveEffect.by(
            Vector2(horizontalSpeed, verticalSpeed),
            EffectController(
              duration: 1.0 + (_random.nextDouble() * 0.5),
              reverseDuration: 1.0 + (_random.nextDouble() * 0.5),
              infinite: true,
            ),
          ),
        );

        // Add pulsing size effect for bubbles
        add(
          ScaleEffect.by(
            Vector2(0.2, 0.2),
            EffectController(
              duration: 1.0 + (_random.nextDouble() * 1.0),
              reverseDuration: 1.0 + (_random.nextDouble() * 1.0),
              infinite: true,
            ),
          ),
        );

        // Add slight rotation
        add(
          RotateEffect.by(
            0.05,
            EffectController(
              duration: 2.0,
              reverseDuration: 2.0,
              infinite: true,
            ),
          ),
        );
      }
    } else {
      // For other worlds, position on the ground
      final groundY = gameRef.size.y * 0.92;
      position = Vector2(gameRef.size.x,
          groundY - size.y + 10); // Add offset to place on ground
    }

    // Add hitbox with a proportional size
    final hitboxSize = Vector2(size.x * 0.7, size.y * 0.7);
    final offset =
        Vector2((size.x - hitboxSize.x) / 2, (size.y - hitboxSize.y) / 2);

    add(
      RectangleHitbox(
        size: hitboxSize,
        position: offset,
        isSolid: true,
      )..debugMode = false, // Hide hitbox in production
    );
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    // Collision logic is now handled in Sheep class
    if (other is Sheep) {
      // Let the sheep handle the collision based on obstacle type and jump state
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Skip updates if the game is paused
    if (gameRef.isPaused || gameRef.isGameOver) return;

    try {
      // Safety check: verify position is valid
      if (position.isNaN || position.x.isNaN || position.y.isNaN) {
        print('WARNING: Obstacle has invalid position. Removing from game.');
        removeFromParent();
        return;
      }

      // Move obstacle from right to left
      position.x -= speed * dt;

      // Remove obstacle when it's off screen
      if (position.x < -size.x) {
        removeFromParent();
      }
    } catch (e) {
      print('ERROR in obstacle update: $e');
      removeFromParent(); // Remove problematic obstacle to prevent further issues
    }
  }
}
