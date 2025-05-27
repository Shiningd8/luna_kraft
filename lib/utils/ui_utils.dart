import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

/// UI Utilities for custom UI components and effects
class UIUtils {
  /// Shows a custom pill-shaped snackbar at the top of the screen
  /// This is more visually appealing than the default Scaffold snackbar
  /// and doesn't conflict with bottom sheets
  static void showPillSnackBar(
    BuildContext context, {
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    Color? textColor,
    bool hapticFeedback = true,
  }) {
    // Provide haptic feedback if enabled
    if (hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // Get the overlay state to insert our custom snackbar
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    
    // Declare the overlayEntry variable first
    late OverlayEntry overlayEntry;
    
    // Define the onDismiss callback that will be passed to the content widget
    void onDismiss() {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    }
    
    // Create an overlay entry for our custom snackbar
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Center(
            child: _PillSnackBarContent(
              message: message,
              icon: icon,
              backgroundColor: backgroundColor ?? theme.primaryColor,
              textColor: textColor ?? Colors.white,
              duration: duration,
              onDismiss: onDismiss,
            ),
          ),
        ),
      ),
    );

    // Insert the overlay entry
    overlay.insert(overlayEntry);
  }
}

/// A stateful widget to handle the pill snackbar content and animation
class _PillSnackBarContent extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _PillSnackBarContent({
    required this.message,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_PillSnackBarContent> createState() => _PillSnackBarContentState();
}

class _PillSnackBarContentState extends State<_PillSnackBarContent> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Create a single animation controller for both in and out animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    // Create an opacity animation
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    // Create a slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Start the appear animation immediately
    _controller.forward();
    
    // Schedule dismissal after the specified duration
    _scheduleDismissal();
  }
  
  void _scheduleDismissal() {
    Future.delayed(widget.duration, () {
      // Only dismiss if still mounted
      if (mounted && _controller.status != AnimationStatus.dismissed) {
        // Reverse the animation and call the dismiss callback when done
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: widget.backgroundColor.withOpacity(0.7),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.textColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 