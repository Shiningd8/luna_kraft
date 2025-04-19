import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'dart:ui';
import 'package:flame/game.dart';
import '../main_game.dart';
import 'dart:math';

class Background extends PositionComponent with HasGameRef<SleepySheepGame> {
  static const double baseSpeed =
      200; // Base speed that will be synchronized with obstacles
  final WorldState worldState;
  double opacity = 1.0;
  late SpriteComponent _background;
  bool _hasGroundImage = false;
  late PositionComponent _groundContainer;

  Background({required this.worldState});

  @override
  Future<void> onLoad() async {
    // Load appropriate background based on world state
    final imageName = switch (worldState) {
      WorldState.normal => 'game/backgrounds/background.png',
      WorldState.space => 'game/backgrounds/space_background.png',
      WorldState.underwater => 'game/backgrounds/underwater_background.png',
      WorldState.candy => 'game/backgrounds/candy_background.png',
      WorldState.forest => 'game/backgrounds/forest_background.png',
    };

    // Load the sprite
    final sprite = await Sprite.load(imageName, images: gameRef.images);

    // Get the game screen size
    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;

    // Calculate size to fill screen while maintaining aspect ratio if possible
    double backgroundWidth, backgroundHeight;
    double xPosition = 0;

    if (worldState == WorldState.space) {
      // For space background, ensure it fills the entire screen
      backgroundWidth = screenWidth;
      backgroundHeight = screenHeight;
      xPosition = 0; // Align to left edge

      // Create background component with darkened paint for space
      _background = SpriteComponent(
        sprite: sprite,
        size: Vector2(backgroundWidth, backgroundHeight),
        position: Vector2(xPosition, 0),
        paint: Paint()
          ..colorFilter = ColorFilter.mode(
            const Color(0xFF000033)
                .withOpacity(0.3), // Darken the space background
            BlendMode.srcATop,
          ),
      );
    } else {
      // For other backgrounds, maintain aspect ratio
      final imageWidth = sprite.srcSize.x;
      final imageHeight = sprite.srcSize.y;

      // Calculate height needed to maintain aspect ratio while filling screen height
      final heightScale = screenHeight / imageHeight;
      backgroundWidth = imageWidth * heightScale;
      backgroundHeight = screenHeight;

      // Center horizontally if wider than screen
      xPosition = (screenWidth - backgroundWidth) / 2;
      if (xPosition > 0) {
        // If image is narrower than screen, stretch to fit width
        backgroundWidth = screenWidth;
        xPosition = 0;
      }

      // Create background component normally for non-space worlds
      _background = SpriteComponent(
        sprite: sprite,
        size: Vector2(backgroundWidth, backgroundHeight),
        position: Vector2(xPosition, 0),
      );
    }

    // Add the static background
    add(_background);

    // Only add ground for non-space worlds
    if (worldState != WorldState.space) {
      // Create ground layer - either from image or a colored rectangle
      _groundContainer = PositionComponent();
      try {
        // Try loading ground.png for the ground layer
        final groundSprite = await Sprite.load('game/backgrounds/ground.png',
            images: gameRef.images);

        // Create two ground components for seamless scrolling
        final groundComponent1 = SpriteComponent(
          sprite: groundSprite,
          size:
              Vector2(screenWidth * 1.2, screenHeight * 0.34), // Taller ground
          position: Vector2(0, 0),
        );

        final groundComponent2 = SpriteComponent(
          sprite: groundSprite,
          size:
              Vector2(screenWidth * 1.2, screenHeight * 0.34), // Taller ground
          position: Vector2(screenWidth * 1.2, 0),
        );

        _groundContainer.add(groundComponent1);
        _groundContainer.add(groundComponent2);
        _hasGroundImage = true;
      } catch (e) {
        // If ground sprite not available, create a simple colored ground
        print('Ground sprite not found: $e');
        _createColoredGround(screenWidth, screenHeight);
      }

      // Position ground to align with the visible ground in image
      _groundContainer.position = Vector2(0, screenHeight * 0.67 + 11);
      add(_groundContainer);
    } else {
      // For space, create an empty ground container
      _groundContainer = PositionComponent();
      add(_groundContainer);
      _hasGroundImage = false;
    }

    // Add world-specific effects
    switch (worldState) {
      case WorldState.space:
        // For space, keep the background static with no effects
        // Just add some non-moving stars for decoration
        _addStaticStars(screenWidth, screenHeight);
        break;
      case WorldState.underwater:
        add(
          MoveEffect.by(
            Vector2(0, 5),
            EffectController(
              duration: 2,
              reverseDuration: 2,
              infinite: true,
            ),
          ),
        );
        break;
      case WorldState.candy:
        add(
          ColorEffect(
            const Color(0xFFFFB6C1).withOpacity(0.3),
            EffectController(
              duration: 1,
              reverseDuration: 1,
              infinite: true,
            ),
          ),
        );
        break;
      case WorldState.forest:
        add(
          SequenceEffect(
            [
              ScaleEffect.by(
                Vector2.all(0.02),
                EffectController(duration: 1),
              ),
              ScaleEffect.by(
                Vector2.all(-0.02),
                EffectController(duration: 1),
              ),
            ],
            infinite: true,
          ),
        );
        break;
      default:
        break;
    }
  }

  void _createColoredGround(double screenWidth, double screenHeight) {
    // Create main ground layer - sandy color to match the wheat field
    final groundLayer1 = RectangleComponent(
      size: Vector2(screenWidth * 1.2, screenHeight * 0.3),
      position: Vector2(0, 0),
      paint: Paint()..color = const Color(0xFFD9A066), // Wheat color
    );

    final groundLayer2 = RectangleComponent(
      size: Vector2(screenWidth * 1.2, screenHeight * 0.3),
      position: Vector2(screenWidth * 1.2, 0),
      paint: Paint()..color = const Color(0xFFD9A066), // Matching color
    );

    _groundContainer.add(groundLayer1);
    _groundContainer.add(groundLayer2);
  }

  // Add static stars to the space background (no animation)
  void _addStaticStars(double screenWidth, double screenHeight) {
    final random = Random();
    // Add 70 stars of varying sizes
    for (int i = 0; i < 70; i++) {
      // Random star size between 1 and 4
      final starSize = 1.0 + random.nextDouble() * 3.0;

      // Random position across the screen
      final starX = random.nextDouble() * screenWidth;
      final starY = random.nextDouble() * screenHeight;

      // Create star as a white circle with varying opacity
      final opacity = 0.5 + random.nextDouble() * 0.5; // Between 0.5 and 1.0
      final star = CircleComponent(
        radius: starSize,
        position: Vector2(starX, starY),
        paint: Paint()..color = const Color(0xFFFFFFFF).withOpacity(opacity),
      );

      add(star);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if the game is paused
    if (gameRef.isPaused || gameRef.isGameOver) return;

    // Skip ground movement for space world
    if (worldState == WorldState.space) return;

    final screenWidth = gameRef.size.x;

    // Get the current obstacle speed
    final currentSpeed =
        gameRef.worldProperties[gameRef.currentWorldState]?.obstacleSpeed ??
            baseSpeed;

    // Move ground at the same speed as obstacles
    _groundContainer.position.x -= currentSpeed * dt;

    // Reset ground position when first ground segment moves completely off screen
    if (_groundContainer.position.x <= -screenWidth * 1.2) {
      _groundContainer.position.x = 0;
    }
  }
}
