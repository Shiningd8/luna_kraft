import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../flutter_flow/flutter_flow_theme.dart';

class AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final Function() onTap;
  final Color? activeColor;
  final Color? inactiveColor;
  final double iconSize;
  final bool showCount;

  const AnimatedLikeButton({
    Key? key,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
    this.activeColor,
    this.inactiveColor,
    this.iconSize = 28,
    this.showCount = true,
  }) : super(key: key);

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _controller = AnimationController(
      vsync: this,
      duration: 300.milliseconds,
    );

    // Simple scale animation
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked) {
      _isLiked = widget.isLiked;
      if (_isLiked && !oldWidget.isLiked) {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.activeColor ?? FlutterFlowTheme.of(context).primary;
    final inactiveColor = widget.inactiveColor ??
        Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: InkWell(
                  onTap: () {
                    if (!_isLiked) {
                      _controller.forward(from: 0.0);
                    } else {
                      _controller.forward(from: 0.0);
                    }
                    setState(() {
                      _isLiked = !_isLiked;
                    });
                    widget.onTap();
                  },
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? activeColor : inactiveColor,
                    size: widget.iconSize,
                  ).animate(target: _isLiked ? 1 : 0).shimmer(
                        duration: 700.ms,
                        color: _isLiked
                            ? Colors.white.withOpacity(0.8)
                            : Colors.transparent,
                      ),
                ),
              ),
            );
          },
        ),
        if (widget.showCount) ...[
          SizedBox(width: 4),
          AnimatedSwitcher(
            duration: 300.milliseconds,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              widget.likeCount.toString(),
              key: ValueKey<int>(widget.likeCount),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Outfit',
                    color: inactiveColor,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
