import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'obstacle.dart';
import '../main_game.dart';

class Sheep extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<SleepySheepGame> {
  static const double jumpForce = -500;
  static const double doubleJumpForce = -400; // Slightly weaker second jump
  static const double maxSpeed = 300;

  // Make gravity a variable instead of a constant
  double gravity = 800;

  double velocityY = 0;
  bool isJumping = false;
  bool hasDoubleJumped = false; // Track if double jump has been used

  // Random for debug info
  final math.Random _random = math.Random();

  // Helper method to check if sheep is currently invulnerable
  bool get isInvulnerable => gameRef.isTransitioning;

  // Make animations public so they can be accessed from the game class
  late SpriteAnimation idleAnimation;
  late SpriteAnimation jumpAnimation;
  late SpriteAnimation sleepAnimation;
  late SpriteAnimation doubleJumpAnimation; // Animation for double jump

  @override
  Future<void> onLoad() async {
    // Set the anchor point to top-left (default) explicitly
    anchor = Anchor.topLeft;

    // Load sprite sheet
    final spriteSheet = await Sprite.load(
      'game/sprites/sheep_sheet.png',
      images: gameRef.images,
    );

    // Get the frame size from your actual sprite sheet
    final frameWidth = spriteSheet.image.width ~/ 3; // 3 columns
    final frameHeight = spriteSheet.image.height ~/ 3; // 3 rows

    // Create animations with adjusted frame positions to prevent overlap
    idleAnimation = SpriteAnimation.fromFrameData(
      spriteSheet.image,
      SpriteAnimationData.sequenced(
        amount: 3,
        stepTime: 0.2,
        textureSize: Vector2(
            frameWidth.toDouble(), frameHeight.toDouble() - 6), // Adjust height
        texturePosition:
            Vector2(0, 8), // Keep top offset to hide legs from above
      ),
    );

    jumpAnimation = SpriteAnimation.fromFrameData(
      spriteSheet.image,
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.1,
        textureSize: Vector2(
            frameWidth.toDouble(), frameHeight.toDouble() - 6), // Adjust height
        texturePosition: Vector2(0, frameHeight.toDouble() + 8), // Keep offset
      ),
    );

    // Double jump animation can use the same frames as regular jump
    // but with faster timing to appear more energetic
    doubleJumpAnimation = SpriteAnimation.fromFrameData(
      spriteSheet.image,
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.08, // Faster for more energetic look
        textureSize: Vector2(
            frameWidth.toDouble(), frameHeight.toDouble() - 6), // Adjust height
        texturePosition: Vector2(
            0, frameHeight.toDouble() + 8), // Same position as jump animation
      ),
    );

    sleepAnimation = SpriteAnimation.fromFrameData(
      spriteSheet.image,
      SpriteAnimationData.sequenced(
        amount: 3,
        stepTime: 0.3,
        textureSize: Vector2(
            frameWidth.toDouble(), frameHeight.toDouble() - 6), // Adjust height
        texturePosition:
            Vector2(0, frameHeight.toDouble() * 2 + 8), // Keep offset
      ),
    );

    // Set initial animation
    animation = idleAnimation;

    // Scale the sheep to a larger size for the game
    size = Vector2(110, 110);

    // Position the sheep directly on the visible wheat field ridge
    final groundY = gameRef.size.y * 0.72;
    position = Vector2(
        50, groundY - size.y + 10); // Add offset to place feet on ground

    // Create a larger, more visible hitbox for better collision detection
    final hitbox = RectangleHitbox(
      size: Vector2(70, 70), // Larger hitbox for better collision detection
      position: Vector2(20, 20), // Centered in the sprite
    );

    // Make hitbox visible for debugging
    hitbox.debugMode = true;

    add(hitbox);

    // Set higher priority to ensure sheep renders on top
    priority = 10;

    print(
        'Sheep initialized with hitbox size ${hitbox.size} at position ${hitbox.position}');
  }

  void jump() {
    if (!isJumping) {
      // First jump
      velocityY = jumpForce;
      isJumping = true;
      hasDoubleJumped = false; // Reset double jump flag
      animation = jumpAnimation;
    } else if (!hasDoubleJumped) {
      // Double jump - only allowed while already in the air
      velocityY = doubleJumpForce;
      hasDoubleJumped = true;
      animation = doubleJumpAnimation;
    }
  }

  void startSleeping() {
    animation = sleepAnimation;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    // Skip collision handling if game is paused or transitioning
    if (gameRef.isPaused || gameRef.isGameOver) return;

    // For debugging, show detail about initial collision
    final otherType = other.runtimeType.toString();
    print('Sheep COLLISION START with: $otherType');

    // Special handling for DreamPortal - provide explicit callback to help with teleportation
    if (otherType.contains('DreamPortal')) {
      print('Sheep detected collision START with portal');
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Skip collision handling if game is paused, sheep is invulnerable, or game is over
    if (gameRef.isPaused || gameRef.isGameOver || isInvulnerable) return;

    // Handle collision with obstacles
    if (other is Obstacle) {
      // Check if this is a haystack and if player hasn't double jumped
      if (other.isHaystack) {
        // Only cause game over if player hasn't double jumped
        // Double jump allows passing through haystacks
        if (!hasDoubleJumped) {
          gameRef.gameOver();
        }
      } else {
        // Regular obstacle, always causes game over
        gameRef.gameOver();
      }
    }

    // Enhanced debug info about collisions with any component
    final sheepCenter = position + (size / 2);
    final otherComponent = other.runtimeType.toString();
    final otherPosition = other.position;
    final distance = (sheepCenter - (other.position + (other.size / 2))).length;

    // Handle collision with portals is managed by the DreamPortal class, but add debug log
    if (other.runtimeType.toString().contains('DreamPortal')) {
      // More detailed portal collision logging
      print('*** PORTAL COLLISION DATA ***');
      print('  Sheep position: $position, center: $sheepCenter');
      print('  Portal position: $otherPosition, size: ${other.size}');
      print('  Distance between centers: $distance');
      print('  Intersection points: $intersectionPoints');
      print('  Game transition state: ${gameRef.isTransitioning}');
      print('******************************');
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    // Debug message for collision end
    final otherType = other.runtimeType.toString();
    print('Sheep COLLISION END with: $otherType');

    // Special handling for portal collision end
    if (otherType.contains('DreamPortal')) {
      print('Sheep collision with portal ENDED');
    }
  }

  @override
  void update(double dt) {
    try {
      super.update(dt);

      // Skip updates if the game is paused
      if (gameRef.isPaused || gameRef.isGameOver) {
        // When paused, just don't apply physics or animation updates
        return;
      }

      // Safety check for invalid position
      if (position.isNaN || position.x.isNaN || position.y.isNaN) {
        print('WARNING: Sheep has invalid position. Resetting position.');
        // Reset to a safe position based on current world
        if (gameRef.currentWorldState == WorldState.space) {
          position = Vector2(50, gameRef.size.y * 0.5);
        } else if (gameRef.currentWorldState == WorldState.underwater) {
          position = Vector2(50, gameRef.size.y * 0.5 - (size.y / 2));
        } else {
          final groundY = gameRef.size.y * 0.72;
          position = Vector2(50, groundY - size.y + 10);
        }
        velocityY = 0;
        // Ensure anchor is set properly
        anchor = Anchor.topLeft;
      }

      // Special handling for space world - DEFER TO MAIN GAME
      if (gameRef.currentWorldState == WorldState.space) {
        // Update animations based on velocity
        if (velocityY < 0) {
          // Moving upward - use jump animation
          if (animation != jumpAnimation) {
            animation = jumpAnimation;
          }
        } else {
          // Falling downward - use sleep animation
          if (animation != sleepAnimation) {
            animation = sleepAnimation;
          }
        }

        // Ensure no color effects are applied
        if (paint.colorFilter != null) {
          paint = Paint();
        }

        // Keep scale normal in space world (matching normal world)
        if (scale.x != 1.0) {
          scale = Vector2.all(1.0);
        }

        // Periodically log sheep position for debugging
        if (_random.nextDouble() < 0.01) {
          print(
              'SPACE SHEEP: ${position.x}, ${position.y}, velocity: $velocityY');
        }

        // IMPORTANT: We no longer apply gravity or calculate position here
        // This is now handled entirely by the main game class
        // We still need to respect bounds though

        // Keep sheep within upper bound
        final minY =
            gameRef.size.y * 0.05; // Upper boundary (near top of screen)
        if (position.y < minY) {
          position.y = minY;
          velocityY = 0; // Stop upward movement at top of screen
        }

        // Make sure sheep stays on the left side (same as normal world)
        position.x = 50;
      } else {
        // Reset sheep visual effects for normal worlds if needed
        if (paint != null && paint.colorFilter != null) {
          paint = Paint(); // Clear any color filters
        }

        // Apply normal world physics
        velocityY += gravity * dt;
        position.y += velocityY * dt;

        // Get ground position at the visible wheat field ridge
        final groundY = gameRef.size.y * 0.89;

        // Check if sheep has landed
        if (position.y >= groundY - size.y + 20) {
          position.y = groundY - size.y + 20;
          velocityY = 0;
          if (isJumping) {
            isJumping = false;
            hasDoubleJumped = false; // Reset double jump on landing
            animation = idleAnimation;
          }
        }
      }
    } catch (e) {
      print('ERROR in sheep update: $e');
      // Reset sheep to a safe state if update fails
      position = Vector2(50, gameRef.size.y * 0.5);
      velocityY = 0;
      anchor = Anchor.topLeft;
    }
  }
}
