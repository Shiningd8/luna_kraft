import 'package:flutter/animation.dart';

/// A helper class to safely manage animation controller operations
/// This prevents common errors like calling methods on disposed animation controllers
class AnimationGuard {
  final AnimationController _controller;
  final bool Function() _isMountedCallback;
  bool _isDisposed = false;

  AnimationGuard(this._controller, this._isMountedCallback);

  /// Safely start the animation
  void forward() {
    if (!_isDisposed && _isMountedCallback() && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  /// Safely reverse the animation
  void reverse() {
    if (!_isDisposed && _isMountedCallback() && _controller.isAnimating) {
      _controller.reverse();
    }
  }

  /// Safely stop the animation
  void stop() {
    if (!_isDisposed && _isMountedCallback() && _controller.isAnimating) {
      _controller.stop();
    }
  }

  /// Mark as disposed to prevent further operations
  void markAsDisposed() {
    _isDisposed = true;
  }
}
