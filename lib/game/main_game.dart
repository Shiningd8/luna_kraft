import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'dart:async' as async;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/effects.dart';
import 'components/sheep.dart';
import 'components/fence.dart';
import 'components/dream_portal.dart';
import 'components/background.dart';
import 'components/obstacle.dart';
import 'components/oxygen_bubble.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/collisions.dart';
import 'package:flame/camera.dart';
import 'package:flame/parallax.dart';
import 'package:flame/timer.dart';
import 'package:flame/events.dart';

enum WorldState {
  normal,
  space, // Space dream world
  underwater, // Underwater dream world
  candy, // Candy dream world
  forest, // Forest dream world
}

class WorldProperties {
  final String backgroundImage;
  final String obstacleImage;
  final String haystackImage; // New haystack obstacle image
  final double obstacleSpeed;
  final double gravity;
  final String portalColor;

  const WorldProperties({
    required this.backgroundImage,
    required this.obstacleImage,
    required this.haystackImage,
    required this.obstacleSpeed,
    required this.gravity,
    required this.portalColor,
  });
}

class SleepySheepGame extends FlameGame
    with TapCallbacks, DoubleTapDetector, HasCollisionDetection {
  late Sheep sheep;
  late Background background;
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> pausedNotifier = ValueNotifier<bool>(false);
  int get score => scoreNotifier.value;
  set score(int value) => scoreNotifier.value = value;

  bool isGameOver = false;
  WorldState currentWorld = WorldState.normal;
  List<Background> backgrounds = [];
  double transitionProgress = 0;
  bool isTransitioning = false;
  WorldState currentWorldState = WorldState.normal;
  bool get isPaused => pausedNotifier.value;
  set isPaused(bool value) => pausedNotifier.value = value;
  async.Timer? _obstacleSpawner;
  async.Timer? _scoreTimer;

  // Track obstacles encountered in each world
  int _spaceWorldObstacleCount = 0;
  int _underwaterWorldObstacleCount = 0;

  // Underwater special mechanics
  double _oxygenBubbleTimer = 0;

  // Tap state for jetpack control in space world
  bool _isTapDown = false;

  // Jetpack thrust power
  final double _jetpackThrust =
      -500; // Stronger negative value for more noticeable upward movement

  // Track the last obstacle type to alternate
  bool _lastWasHaystack = false;
  final math.Random _random = math.Random();

  // Diagnostic logging for teleportation issues
  bool _lastTransitionState = false;
  DateTime? _lastTransitionChange;

  // World properties for each dream world
  final Map<WorldState, WorldProperties> worldProperties = {
    WorldState.normal: const WorldProperties(
      backgroundImage: 'game/backgrounds/background.png',
      obstacleImage: 'game/obstacles/fence.png',
      haystackImage: 'game/obstacles/hay.png',
      obstacleSpeed: 180,
      gravity: 800,
      portalColor: 'blue',
    ),
    WorldState.space: const WorldProperties(
      backgroundImage: 'game/backgrounds/space_background.png',
      obstacleImage: 'game/obstacles/asteroid.png',
      haystackImage:
          'game/obstacles/hay.png', // Keep same haystack in all worlds
      obstacleSpeed: 200,
      gravity:
          300, // Increased gravity for space world to make sheep fall faster
      portalColor: 'purple',
    ),
    WorldState.underwater: const WorldProperties(
      backgroundImage: 'game/backgrounds/underwater_background.png',
      obstacleImage: 'game/obstacles/bubble.png',
      haystackImage: 'game/obstacles/hay.png',
      obstacleSpeed: 160,
      gravity: 400,
      portalColor: 'blue',
    ),
    WorldState.candy: const WorldProperties(
      backgroundImage: 'game/backgrounds/candy_background.png',
      obstacleImage: 'game/obstacles/lollipop.png',
      haystackImage: 'game/obstacles/hay.png',
      obstacleSpeed: 190,
      gravity: 700,
      portalColor: 'red',
    ),
    WorldState.forest: const WorldProperties(
      backgroundImage: 'game/backgrounds/forest_background.png',
      obstacleImage: 'game/obstacles/mushroom.png',
      haystackImage: 'game/obstacles/hay.png',
      obstacleSpeed: 170,
      gravity: 750,
      portalColor: 'green',
    ),
  };

  double gameTime = 0;
  double timeToSpaceWorld = 30;

  @override
  Future<void> onLoad() async {
    // Initialize game components
    background = Background(worldState: currentWorldState);
    add(background);
    backgrounds.add(background);

    sheep = Sheep();
    add(sheep);

    // Start spawning obstacles
    _startObstacleSpawner();

    // Start score timer
    _startScoreTimer();

    // Add overlays
    overlays.add('score');
  }

  void _startScoreTimer() {
    _scoreTimer?.cancel();
    _scoreTimer = async.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused && !isGameOver) {
        score++;
      }
    });
  }

  void _startObstacleSpawner() {
    _obstacleSpawner?.cancel();

    // Base timing between 3000-5000ms
    _obstacleSpawner =
        async.Timer.periodic(const Duration(milliseconds: 3000), (timer) {
      if (!isPaused && !isGameOver) {
        // Add additional randomness to the spawn timing for better pacing
        final randomDelay =
            _random.nextInt(2000); // Random delay up to 2 seconds

        Future.delayed(Duration(milliseconds: randomDelay), () {
          if (!isPaused && !isGameOver) {
            final properties = worldProperties[currentWorldState]!;

            // Chance to spawn a portal instead of an obstacle (15% chance)
            final spawnPortal = _random.nextDouble() < 0.15;

            if (spawnPortal && !isTransitioning) {
              // For now, only allow portals to space world
              final targetWorld = WorldState.space;

              // Only spawn space portals if we're not already in space
              if (currentWorldState != WorldState.space) {
                // Get the portal color based on the target world
                final portalColor = worldProperties[targetWorld]!.portalColor;

                // Add debug print to verify portal is being spawned
                print('Spawning ${portalColor} portal to space!');

                // Add a dream portal
                add(
                  DreamPortal(
                    targetWorld: targetWorld,
                    portalColor: portalColor,
                  ),
                );
              } else {
                // If already in space, just spawn a regular obstacle
                _spawnRegularObstacle(properties);
              }
            } else {
              _spawnRegularObstacle(properties);
            }
          }
        });
      }
    });
  }

  // Helper method to spawn regular obstacles
  void _spawnRegularObstacle(WorldProperties properties) {
    // Never spawn haystacks in space world
    bool spawnHaystack = currentWorldState != WorldState.space &&
        !_lastWasHaystack &&
        _random.nextDouble() < 0.2;
    _lastWasHaystack = spawnHaystack;

    final imagePath =
        spawnHaystack ? properties.haystackImage : properties.obstacleImage;

    // Check if we need to spawn a portal to underwater world instead
    if (currentWorldState == WorldState.space &&
        _spaceWorldObstacleCount >= 20 &&
        !isTransitioning &&
        _random.nextDouble() < 0.3) {
      // 30% chance to spawn portal after reaching threshold

      print(
          'Spawning portal to underwater world after $_spaceWorldObstacleCount space obstacles!');

      add(
        DreamPortal(
          targetWorld: WorldState.underwater,
          portalColor: worldProperties[WorldState.underwater]!.portalColor,
        ),
      );

      return; // Don't spawn an obstacle this time
    }

    // Otherwise, spawn a regular obstacle
    add(
      Obstacle(
        imagePath: imagePath,
        speed: properties.obstacleSpeed,
        worldState: currentWorldState,
        isHaystack: spawnHaystack,
      ),
    );

    // Increment obstacle counter for the current world
    if (currentWorldState == WorldState.space) {
      _spaceWorldObstacleCount++;
      print('Space world obstacle count: $_spaceWorldObstacleCount');
    } else if (currentWorldState == WorldState.underwater) {
      _underwaterWorldObstacleCount++;
    }
  }

  void startWorldTransition(WorldState targetWorld) {
    // Only allow one transition at a time
    if (isTransitioning) {
      print('Cannot start transition - already in transition');
      return;
    }

    print('Starting world transition to: $targetWorld');
    isTransitioning = true;

    // Create a full-screen black overlay for transition
    final blackOverlay = RectangleComponent(
      position: Vector2.zero(),
      size: size,
      paint: Paint()..color = Colors.transparent, // Start transparent
    );
    blackOverlay.priority = 999; // Ensure it's on top of everything
    add(blackOverlay);

    // Fade in the black overlay (to black)
    blackOverlay.add(
      ColorEffect(
        Colors.black,
        EffectController(
          duration: 1.0, // 1 second fade in
        ),
      )..onComplete = () {
          // When black, set up new world after a delay
          Future.delayed(Duration(seconds: 1), () {
            setupNewWorld(targetWorld, blackOverlay);
          });
        },
    );
  }

  void setupNewWorld(WorldState newWorld, RectangleComponent blackOverlay) {
    // Remove old obstacles
    children
        .whereType<Obstacle>()
        .forEach((obstacle) => obstacle.removeFromParent());

    // Remove the old background
    backgrounds[0].removeFromParent();
    backgrounds.removeAt(0);

    // Create new background for the dream world
    final dreamBackground = Background(worldState: newWorld);
    add(dreamBackground);
    backgrounds.add(dreamBackground);

    // Update world state
    currentWorldState = newWorld;
    currentWorld = newWorld;

    // Reset obstacle counter when entering a new world
    if (newWorld == WorldState.space) {
      _spaceWorldObstacleCount = 0;
    } else if (newWorld == WorldState.underwater) {
      _underwaterWorldObstacleCount = 0;
    }

    // Set up space world specific elements
    if (newWorld == WorldState.space) {
      // Position sheep for space world with normal scale (matching normal world)
      sheep.scale = Vector2.all(1.0); // Normal scale, same as starting world
      sheep.position = Vector2(
          50, size.y * 0.5); // Left side of screen, middle of the screen
      sheep.velocityY = 0;

      // Apply space-specific properties to sheep
      sheep.gravity = 0; // Start with zero gravity to give player time to react
      // Use sleep animation in space world
      sheep.animation = sheep.sleepAnimation;

      // Apply subtle yellow glow to sheep for visibility in space
      sheep.paint = Paint()
        ..colorFilter = ColorFilter.mode(
          const Color(0xFFFFFF00).withOpacity(0.7), // Yellow with some opacity
          BlendMode.srcATop,
        );

      // Ensure sheep appears on top of other elements
      sheep.priority = 100;

      print(
          'Space world setup complete. Sheep at: ${sheep.position.x}, ${sheep.position.y}');

      // Gradually introduce gravity after 1 second - reduced delay for faster falling
      Future.delayed(Duration(milliseconds: 1000), () {
        if (currentWorldState == WorldState.space && !isPaused && !isGameOver) {
          // Apply gravity more quickly over 1 second
          const int steps = 10;
          final targetGravity = worldProperties[newWorld]!.gravity;
          final gravityStep = targetGravity / steps;

          for (int i = 1; i <= steps; i++) {
            Future.delayed(Duration(milliseconds: 100 * i), () {
              if (currentWorldState == WorldState.space &&
                  !isPaused &&
                  !isGameOver) {
                sheep.gravity = gravityStep * i;
                if (i == steps) {
                  print('Space gravity fully activated: ${sheep.gravity}');
                }
              }
            });
          }
        }
      });
    }
    // Set up underwater world specific elements
    else if (newWorld == WorldState.underwater) {
      // Position sheep for underwater world
      sheep.scale = Vector2.all(1.0);

      // Explicitly position the sheep in a visible part of the screen
      // Position the sheep on the left side and vertically centered
      sheep.position = Vector2(50, size.y * 0.5 - (sheep.size.y / 2));
      sheep.velocityY = 0;

      // Ensure sheep has an anchor and is visible
      sheep.anchor = Anchor.topLeft;
      sheep.opacity = 1.0;

      // Apply underwater-specific properties to sheep
      sheep.gravity = worldProperties[newWorld]!.gravity *
          0.5; // Reduced gravity for floating effect

      // Use sleep animation initially
      sheep.animation = sheep.sleepAnimation;

      // Apply blue tint to sheep for underwater effect
      sheep.paint = Paint()
        ..colorFilter = ColorFilter.mode(
          const Color(0xFF64B5F6).withOpacity(0.5), // Light blue with opacity
          BlendMode.srcATop,
        );

      sheep.priority = 100;

      // Reset oxygen bubble timer to start spawning bubbles soon
      _oxygenBubbleTimer = 1.0;

      print('Underwater world setup complete. Sheep at: ${sheep.position}');
    }

    // Update game properties based on new world
    _updateWorldProperties();

    // Fade back from black after a short delay
    Future.delayed(Duration(milliseconds: 200), () {
      blackOverlay.add(
        ColorEffect(
          Colors.transparent, // Fade to transparent
          EffectController(
            duration: 1.0, // 1 second fade out
          ),
        )..onComplete = () {
            // When fade out is complete, remove the overlay and finish transition
            blackOverlay.removeFromParent();
            isTransitioning = false;

            // Spawn a world-specific obstacle after transition
            if (newWorld == WorldState.space) {
              Future.delayed(Duration(milliseconds: 500), () {
                if (!isPaused && !isGameOver) {
                  final properties = worldProperties[newWorld]!;
                  print('Spawning first space obstacle');
                  add(
                    Obstacle(
                      imagePath: properties.obstacleImage,
                      speed: properties.obstacleSpeed,
                      worldState: newWorld,
                      isHaystack: false,
                    ),
                  );
                }
              });
            }
          },
      );
    });
  }

  void _updateWorldProperties() {
    final properties = worldProperties[currentWorldState]!;

    // Update obstacle speed for all existing obstacles
    children.whereType<Obstacle>().forEach((obstacle) {
      obstacle.speed = properties.obstacleSpeed;
    });

    // Update sheep's gravity
    sheep.gravity = properties.gravity;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (isPaused || isGameOver) return false;

    if (currentWorldState == WorldState.space) {
      _isTapDown = true;
      return true;
    } else if (currentWorldState == WorldState.underwater) {
      try {
        // Check if sheep exists and is properly initialized
        if (sheep.position.isNaN) {
          print(
              'Invalid sheep position when tapping in underwater world. Resetting position.');
          sheep.position = Vector2(50, size.y * 0.5 - (sheep.size.y / 2));
        }

        // Instead of directly setting velocityY, use a swimming impulse with safeguards
        if (sheep.velocityY > -250) {
          // Prevent stacking up too much upward velocity
          sheep.velocityY = -300; // Strong upward movement
          sheep.animation =
              sheep.jumpAnimation; // Use jump animation for swimming

          // Add a small bubble effect when swimming up
          _spawnCurrentBubble(
              sheep.position + Vector2(sheep.size.x * 0.5, sheep.size.y * 0.8),
              true);
        }

        // Log successful jump for debugging
        print('Swim up triggered, new velocity: ${sheep.velocityY}');
        return true;
      } catch (e) {
        print('ERROR when swimming: $e');
        // Recover from error
        sheep.position = Vector2(50, size.y * 0.5 - (sheep.size.y / 2));
        sheep.velocityY = -300;
        return true;
      }
    } else {
      // Normal world jumping
      sheep.jump();
      return true;
    }
  }

  @override
  bool onTapUp(TapUpEvent event) {
    if (currentWorldState == WorldState.space) {
      _isTapDown = false;
    }
    return true;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (currentWorldState == WorldState.space) {
      _isTapDown = false;
    }
  }

  void pauseGame() {
    isPaused = true;
    _obstacleSpawner?.cancel();
    _scoreTimer?.cancel();
  }

  void resumeGame() {
    isPaused = false;
    _startObstacleSpawner();
    _startScoreTimer();
  }

  void gameOver() {
    if (!isGameOver) {
      isGameOver = true;
      isPaused = true;
      _obstacleSpawner?.cancel();
      _scoreTimer?.cancel();
      overlays.add('gameOver');
    }
  }

  void incrementScore() {
    score++;
  }

  void reset() {
    isGameOver = false;
    isPaused = false;
    score = 0;
    _lastWasHaystack = false;
    gameTime = 0; // Reset game time to start from beginning
    isTransitioning = false; // Reset any transition state

    // Reset obstacle counters
    _spaceWorldObstacleCount = 0;
    _underwaterWorldObstacleCount = 0;

    // Remove all obstacles and portals
    children
        .whereType<Obstacle>()
        .forEach((obstacle) => obstacle.removeFromParent());

    children
        .whereType<DreamPortal>()
        .forEach((portal) => portal.removeFromParent());

    // If we're not in the normal world, go back to it
    if (currentWorldState != WorldState.normal) {
      // Remove the current background
      backgrounds[0].removeFromParent();
      backgrounds.removeAt(0);

      // Create new background for the normal world
      final normalBackground = Background(worldState: WorldState.normal);
      add(normalBackground);
      backgrounds.add(normalBackground);

      // Update world state
      currentWorldState = WorldState.normal;
      currentWorld = WorldState.normal;

      // Reset sheep properties to normal world values
      sheep.gravity = worldProperties[WorldState.normal]!.gravity;
      sheep.paint = Paint(); // Remove any special effects/glows
      sheep.scale = Vector2.all(1.0);
      sheep.animation = sheep.idleAnimation;
      sheep.anchor = Anchor.topLeft; // Ensure anchor is set properly
      sheep.opacity = 1.0; // Ensure sheep is visible
    }

    // Reset sheep position
    final groundY = size.y * 0.82;
    sheep.position = Vector2(50, groundY - sheep.size.y + 10);
    sheep.velocityY = 0;
    sheep.isJumping = false;
    sheep.hasDoubleJumped = false;

    // Restart obstacle spawning and score timer
    _startObstacleSpawner();
    _startScoreTimer();

    overlays.remove('gameOver');
  }

  @override
  void onRemove() {
    _obstacleSpawner?.cancel();
    _scoreTimer?.cancel();
    scoreNotifier.dispose();
    pausedNotifier.dispose();
    super.onRemove();
  }

  @override
  void update(double dt) {
    // Track transition state changes for debugging
    if (_lastTransitionState != isTransitioning) {
      final now = DateTime.now();
      final timeSinceLastChange = _lastTransitionChange != null
          ? now.difference(_lastTransitionChange!)
          : null;

      print(
          'TRANSITION STATE CHANGED: ${_lastTransitionState} -> ${isTransitioning}');
      if (timeSinceLastChange != null) {
        print(
            'Time since last transition change: ${timeSinceLastChange.inMilliseconds}ms');
      }

      // If transition is starting without user interaction, log stack trace
      if (isTransitioning &&
          !_lastTransitionState &&
          timeSinceLastChange != null &&
          timeSinceLastChange.inSeconds < 5) {
        // Check if there are no portals - which would indicate an unexpected transition
        final hasPortals =
            children.any((component) => component is DreamPortal);
        if (!hasPortals) {
          print(
              'WARNING: Transition started without visible portal! Stack trace:');
          print(StackTrace.current);
        }
      }

      _lastTransitionState = isTransitioning;
      _lastTransitionChange = now;
    }

    if (isPaused || isGameOver) return;

    // Update game timer
    gameTime += dt;

    // Check for world change after 30 seconds
    if (gameTime >= timeToSpaceWorld &&
        currentWorldState == WorldState.normal) {
      // Don't force the change if already in transition
      if (!isTransitioning) {
        changeToSpaceWorld();
      }
    }

    // Space world gravity and jetpack controls for sheep
    if (currentWorldState == WorldState.space) {
      // Apply gravity (make sheep fall) - will be 0 for the first 3 seconds, then increase gradually
      sheep.velocityY += sheep.gravity * dt;

      // Natural drag/resistance to slow movement in space - reduced for faster falling
      sheep.velocityY *= 0.995; // Reduced drag for faster falling

      // Apply jetpack thrust if screen is being held
      if (_isTapDown && !isGameOver) {
        // Debug output to verify _isTapDown is working
        print(
            'Jetpack activated! _isTapDown: $_isTapDown, thrust: $_jetpackThrust');

        // Direct velocity change instead of incremental
        sheep.velocityY += _jetpackThrust *
            dt *
            2; // Double the effect for more immediate response

        // Cap upward velocity to prevent too rapid ascent
        if (sheep.velocityY < -300) {
          sheep.velocityY = -300;
        }

        // Add gentle wobble effect when using jetpack
        sheep.angle = math.sin(gameTime * 10) * 0.05; // Subtle wobble
      } else {
        // Slowly return to normal orientation
        sheep.angle *= 0.95;
      }

      // Limit maximum falling speed in space
      const maxFallSpeed = 350.0; // Increased to allow faster falling
      if (sheep.velocityY > maxFallSpeed) {
        sheep.velocityY = maxFallSpeed;
      }

      // Update sheep position
      sheep.y += sheep.velocityY * dt;

      // Debug sheep movement
      if (gameTime % 1 < 0.02) {
        // Only print occasionally
        print(
            'Sheep position: ${sheep.y}, velocity: ${sheep.velocityY}, gravity: ${sheep.gravity}, isTapDown: $_isTapDown');
      }

      // Check if sheep is out of bounds (fell off screen)
      if (sheep.y > size.y + sheep.height && !isTransitioning) {
        // Game over if sheep falls off screen, but only if not in transition
        print('Sheep fell off screen - Game Over!');
        gameOver();
      }

      // Prevent sheep from going too high
      if (sheep.y < 0) {
        sheep.y = 0;
        sheep.velocityY = 0;
      }
    }
    // Underwater world physics
    else if (currentWorldState == WorldState.underwater) {
      try {
        // Check if sheep has valid position
        if (sheep.position.isNaN ||
            sheep.position.x.isNaN ||
            sheep.position.y.isNaN) {
          print(
              'WARNING: Sheep has invalid position in underwater world! Resetting position.');
          // Reset to a safe position
          sheep.position = Vector2(50, size.y * 0.5 - (sheep.size.y / 2));
          sheep.velocityY = 0;
        }

        // Apply gentle gravity (buoyancy effect)
        sheep.velocityY += sheep.gravity * dt;

        // Strong water resistance - sheep slows down quickly
        sheep.velocityY *= 0.98;

        // UNDERWATER SPECIAL MECHANIC: Water currents
        // Create alternating vertical current zones that push the sheep up or down
        final zoneWidth = size.x / 4; // Divide screen into 4 current zones
        int currentZone = (sheep.x / zoneWidth).floor();

        // Apply different current effects based on zone
        if (currentZone % 2 == 0) {
          // Upward current in even zones
          sheep.velocityY -= 50 * dt; // Gentle upward push

          // Show current effect occasionally
          if (_random.nextDouble() < 0.05) {
            _spawnCurrentBubble(sheep.position + Vector2(0, 30), true);
          }
        } else {
          // Downward current in odd zones
          sheep.velocityY += 70 * dt; // Stronger downward push

          // Show current effect occasionally
          if (_random.nextDouble() < 0.05) {
            _spawnCurrentBubble(sheep.position + Vector2(0, -30), false);
          }
        }

        // UNDERWATER SPECIAL MECHANIC: Oxygen bubbles
        _oxygenBubbleTimer -= dt;
        if (_oxygenBubbleTimer <= 0) {
          // Reset timer and spawn a bubble
          _oxygenBubbleTimer =
              3.0 + _random.nextDouble() * 2.0; // Every 3-5 seconds
          _spawnOxygenBubble();
        }

        // Update sheep position
        sheep.y += sheep.velocityY * dt;

        // Animate based on velocity
        if (sheep.velocityY < -50) {
          // Swimming upward
          if (sheep.animation != sheep.jumpAnimation) {
            sheep.animation = sheep.jumpAnimation;
          }
        } else if (sheep.velocityY > 50) {
          // Sinking
          if (sheep.animation != sheep.sleepAnimation) {
            sheep.animation = sheep.sleepAnimation;
          }
        } else {
          // Neutral floating
          if (sheep.animation != sheep.idleAnimation) {
            sheep.animation = sheep.idleAnimation;
          }
        }

        // Add gentle floating effect
        sheep.angle = math.sin(gameTime * 5) * 0.03;

        // Limit maximum speeds in water
        const maxWaterSpeed = 250.0;
        if (sheep.velocityY > maxWaterSpeed) {
          sheep.velocityY = maxWaterSpeed;
        } else if (sheep.velocityY < -maxWaterSpeed) {
          sheep.velocityY = -maxWaterSpeed;
        }

        // Check boundaries
        if (sheep.y > size.y + sheep.height && !isTransitioning) {
          // Game over if sheep falls off screen
          print('Sheep fell out of underwater world - Game Over!');
          gameOver();
        }

        // Prevent sheep from going too high
        if (sheep.y < 0) {
          sheep.y = 0;
          sheep.velocityY = 0;
        }

        // Periodically log sheep state in underwater world for debugging
        if (gameTime % 2 < 0.02) {
          print(
              'UNDERWATER SHEEP: pos=${sheep.position}, vel=${sheep.velocityY}, anchor=${sheep.anchor}');
        }
      } catch (e) {
        print('ERROR in underwater physics: $e');
        // Prevent game from crashing by resetting the sheep
        sheep.position = Vector2(50, size.y * 0.5 - (sheep.size.y / 2));
        sheep.velocityY = 0;
      }
    }

    super.update(dt);

    // Limit delta time to avoid huge jumps after pauses
    final limitedDt = dt > 0.05 ? 0.05 : dt;

    // Update game logic with limited dt
    if (!isPaused && !isGameOver) {
      _updateObstacles(limitedDt);
    }
  }

  void _updateObstacles(double dt) {
    // Ensure all obstacles use the current world's speed settings
    final currentSpeed =
        worldProperties[currentWorldState]?.obstacleSpeed ?? 200;

    children.whereType<Obstacle>().forEach((obstacle) {
      // Update obstacle speed to match current world settings
      obstacle.speed = currentSpeed;
    });
  }

  // Create visual bubbles to represent water currents
  void _spawnCurrentBubble(Vector2 position, bool isUpwardCurrent) {
    try {
      // Check for invalid position to prevent errors
      if (position.isNaN || position.x.isNaN || position.y.isNaN) {
        print('WARNING: Attempted to spawn bubble at invalid position');
        return;
      }

      // Create a bubble component
      final bubble = CircleComponent(
        radius: 3 + _random.nextDouble() * 5,
        position: position,
        anchor: Anchor.center, // Explicitly set anchor
        paint: Paint()..color = Colors.white.withOpacity(0.5),
      );

      // Explicitly initialize the anchor to prevent _centerOffset error
      bubble.anchor = Anchor.center;

      // Add directional movement effect based on current direction
      final direction = isUpwardCurrent ? -1.0 : 1.0;
      final distance = 40 + _random.nextDouble() * 30;

      bubble.add(
        MoveEffect.by(
          Vector2(0, direction * distance),
          EffectController(
            duration: 0.7 + _random.nextDouble() * 0.5,
            curve: Curves.easeOut,
          ),
          onComplete: () => bubble.removeFromParent(),
        ),
      );

      // Add fade out effect
      bubble.add(
        OpacityEffect.fadeOut(
          EffectController(
            duration: 0.5,
            startDelay: 0.2,
          ),
        ),
      );

      add(bubble);
    } catch (e) {
      print('ERROR spawning current bubble: $e');
      // Skip adding the bubble if there's an error
    }
  }

  // Spawn collectible oxygen bubbles in the underwater world
  void _spawnOxygenBubble() {
    // Only spawn in underwater world
    if (currentWorldState != WorldState.underwater || isPaused || isGameOver) {
      return;
    }

    // Create random position on right side of screen
    final randomY = size.y * (0.2 + (_random.nextDouble() * 0.6));
    final position = Vector2(size.x + 50, randomY);

    // Add the bubble
    add(OxygenBubble(position: position));
  }

  void changeToSpaceWorld() {
    if (!isTransitioning) {
      startWorldTransition(WorldState.space);
    }
  }
}
