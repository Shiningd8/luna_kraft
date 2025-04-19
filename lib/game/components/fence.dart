import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class Fence extends SpriteComponent with CollisionCallbacks {
  static const double speed = 200;

  @override
  Future<void> onLoad() async {
    // TODO: Load fence sprite
    sprite = await Sprite.load('fence.png');
    size = Vector2(30, 50);
    position = Vector2(800, 300);

    // Add hitbox
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move fence from right to left
    position.x -= speed * dt;

    // Remove fence when it's off screen
    if (position.x < -size.x) {
      removeFromParent();
    }
  }
}
