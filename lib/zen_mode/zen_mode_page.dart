import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '/services/app_state.dart';
import '/services/zen_audio_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/utils/animation_helpers.dart';
import '/utils/subscription_util.dart';
import '/services/subscription_manager.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_kraft/auth/firebase_auth/auth_util.dart';
import 'package:luna_kraft/backend/schema/user_record.dart';

// Add a fallback AnimationGuard class right after imports
import 'dart:math' as math;

// Fallback AnimationGuard in case the import fails
class _FallbackAnimationGuard {
  final AnimationController _controller;
  final bool Function() _isMountedCallback;
  bool _isDisposed = false;

  _FallbackAnimationGuard(this._controller, this._isMountedCallback);

  void forward() {
    if (!_isDisposed && _isMountedCallback() && !_controller.isAnimating) {
      try {
        _controller.forward();
      } catch (e) {
        print('Error in animation: $e');
      }
    }
  }

  void reverse() {
    if (!_isDisposed && _isMountedCallback() && _controller.isAnimating) {
      try {
        _controller.reverse();
      } catch (e) {
        print('Error in animation: $e');
      }
    }
  }

  void stop() {
    if (!_isDisposed && _isMountedCallback() && _controller.isAnimating) {
      try {
        _controller.stop();
      } catch (e) {
        print('Error in animation: $e');
      }
    }
  }

  void markAsDisposed() {
    _isDisposed = true;
  }
}

class ZenModePage extends StatefulWidget {
  const ZenModePage({Key? key}) : super(key: key);

  @override
  State<ZenModePage> createState() => _ZenModePageState();
}

// Custom animated container for sound cards
class AnimatedSoundCard extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final VoidCallback onTap;

  const AnimatedSoundCard({
    Key? key,
    required this.child,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedSoundCard> createState() => _AnimatedSoundCardState();
}

class _AnimatedSoundCardState extends State<AnimatedSoundCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late dynamic _animationGuard;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Try to use AnimationGuard, fall back to our internal version if it fails
    try {
      _animationGuard = AnimationGuard(_animationController, () => _isMounted);
    } catch (e) {
      print('Using fallback animation guard: $e');
      _animationGuard =
          _FallbackAnimationGuard(_animationController, () => _isMounted);
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _animationGuard.markAsDisposed();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _animationGuard.forward(),
      onTapUp: (_) => _animationGuard.reverse(),
      onTapCancel: () => _animationGuard.reverse(),
      child: AnimatedScale(
        scale: widget.isActive ? 1.05 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}

// Ripple animation for the play button
class RippleAnimation extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const RippleAnimation({Key? key, required this.child, this.isActive = false})
      : super(key: key);

  @override
  State<RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<RippleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  late dynamic _animationGuard;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    // Try to use AnimationGuard, fall back to our internal version if it fails
    try {
      _animationGuard = AnimationGuard(_rippleController, () => _isMounted);
    } catch (e) {
      print('Using fallback animation guard: $e');
      _animationGuard =
          _FallbackAnimationGuard(_rippleController, () => _isMounted);
    }

    if (widget.isActive) {
      _animationGuard.forward();
    }
  }

  @override
  void didUpdateWidget(RippleAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _rippleController.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _animationGuard.stop();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _animationGuard.markAsDisposed();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.isActive)
          ...List.generate(3, (index) {
            return Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, child) {
                    final double progress = _rippleController.value;
                    final double delayFactor = index * 0.3;
                    final double delayedProgress =
                        (progress - delayFactor).clamp(0.0, 1.0);
                    final double size = 80 + (index * 20.0);
                    final double scale = 0.7 + (delayedProgress * 0.5);
                    final double opacity = (1.0 - delayedProgress) * 0.5;

                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: FlutterFlowTheme.of(
                              context,
                            ).primary.withOpacity(0.2 - index * 0.05),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        widget.child,
      ],
    );
  }
}

// A custom widget for animations with delay
class DelayedAnimation extends StatefulWidget {
  final Widget child;
  final int delay;
  final Duration duration;

  const DelayedAnimation({
    Key? key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  State<DelayedAnimation> createState() => _DelayedAnimationState();
}

class _DelayedAnimationState extends State<DelayedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late dynamic _animationGuard;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Try to use AnimationGuard, fall back to our internal version if it fails
    try {
      _animationGuard = AnimationGuard(_controller, () => _isMounted);
    } catch (e) {
      print('Using fallback animation guard: $e');
      _animationGuard = _FallbackAnimationGuard(_controller, () => _isMounted);
    }

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    if (widget.delay == 0) {
      _animationGuard.forward();
    } else {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (_isMounted) {
          _animationGuard.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _animationGuard.markAsDisposed();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class _ZenModePageState extends State<ZenModePage>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _presetNameController = TextEditingController();

  // Store a reference to the ZenAudioService
  late final ZenAudioService zenAudioService;

  // Add timer-related state variables
  Timer? _timerCountdown;
  String _timerDisplay = '';

  // Night Garden mode state
  bool _isNightGardenMode = false;
  late AnimationController _nightGardenFadeController;

  // Screen brightness variables
  double _originalBrightness = 1.0;
  final double _nightGardenBrightness = 0.15; // Very dim for battery saving
  final ScreenBrightness _screenBrightness = ScreenBrightness();

  // Helper method to get icon based on sound name
  IconData _getSoundIcon(String soundName) {
    switch (soundName.toLowerCase()) {
      case 'rain':
        return Icons.water_drop;
      case 'thunder':
        return Icons.bolt;
      case 'forest':
        return Icons.forest;
      case 'ocean':
        return Icons.water;
      case 'fireplace':
        return Icons.local_fire_department;
      case 'wind':
        return Icons.air;
      case 'birds':
        return Icons.flutter_dash;
      case 'stream':
        return Icons.waves;
      default:
        return Icons.music_note;
    }
  }

  // Timer selection options
  final List<int> _timerOptions = [15, 30, 60, 180, 360];
  int? _selectedTimerMinutes;

  String _backgroundImage = 'images/zen/default_background.jpg';
  bool _isPlaying = false;
  bool _isMenuExpanded = false;
  double _menuOpenPercent = 0.0;
  int _selectedSoundIndex = -1;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _titleFadeController;
  late AnimationController _titleShimmerController;
  late AnimationController _timerPulseController;
  AnimationController? _lottieController;
  late AnimationController _menuController;
  late AnimationController _pageTransitionController;
  bool _isInitialized = false;

  // For the rotating sound selector
  late AnimationController _rotationController;
  final double _initialRadius = 130.0;
  final int _maxDisplayedSounds = 8;

  // For the ripple effect on timer icon
  late AnimationController _timerRippleController;
  bool _isDisposed = false;

  // Debug helper method
  void _debugLog(String message) {
    print('🧘 ZenMode: $message');
  }

  // Ensure UI is in sync with audio service
  void _syncUIWithAudioService() {
    if (mounted && !_isDisposed) {
      setState(() {
        final serviceIsPlaying = zenAudioService.isPlaying;
        if (_isPlaying != serviceIsPlaying) {
          print(
            'Syncing UI: _isPlaying=$_isPlaying, service.isPlaying=$serviceIsPlaying',
          );
          _isPlaying = serviceIsPlaying;
        }
      });
    }
  }

  // Add variables for the intro experience
  bool _showZenModeIntro = false;
  late PageController _introPageController;
  late AnimationController _introFadeController;
  int _currentIntroPage = 0;
  final int _totalIntroPages = 4;

  // Add a variable to track the overlay entry
  OverlayEntry? _nightGardenOverlay;

  // Add a class variable to track subscription status  
  bool _hasFullAccess = false;
  
  @override
  void initState() {
    super.initState();
    // Check subscription status for Zen Mode access
    _hasFullAccess = SubscriptionUtil.hasZenMode;
    
    // Add subscription status listener
    SubscriptionManager.instance.subscriptionStatus.listen((status) {
      if (mounted) {
        setState(() {
          _hasFullAccess = SubscriptionUtil.hasZenMode;
        });
      }
    });
    
    _debugLog('Initializing ZenModePage');

    // Initialize intro page controller
    _introPageController = PageController();

    // Initialize intro fade animation
    _introFadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    // Check if user needs to see intro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedsZenModeIntro();
    });

    // Initialize services
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      zenAudioService = appState.zenAudioService;
      _debugLog('Got ZenAudioService reference');

      zenAudioService.initialize();
      _debugLog('ZenAudioService initialized');

      // Add listener to update UI when service state changes
      zenAudioService.addListener(_onZenServiceChanged);
      _debugLog('Added service change listener');
    } catch (e) {
      print('❌ Error initializing zen audio service: $e');
    }

    try {
      _debugLog('Setting up animation controllers');
      // Setup pulse animation for play button
      _pulseController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 2),
      );
      _pulseController.repeat(reverse: true);
      _debugLog('Pulse controller initialized');

      // Setup title fade animation
      _titleFadeController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800),
      );
      _titleFadeController.forward();
      _debugLog('Title fade controller initialized');

      // Setup title shimmer animation
      _titleShimmerController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2200),
      );
      _debugLog('Title shimmer controller initialized');

      Future.delayed(Duration(milliseconds: 4000), () {
        if (mounted && !_isDisposed) {
          try {
            _titleShimmerController.repeat();
            _debugLog('Title shimmer animation started');
          } catch (e) {
            print('❌ Error starting title shimmer: $e');
          }
        }
      });

      // Setup timer pulse animation
      _timerPulseController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 1),
      );
      _timerPulseController.repeat(reverse: true);
      _debugLog('Timer pulse controller initialized');

      // Setup Lottie animation controller with robust error handling
      try {
        _lottieController = AnimationController(
          vsync: this,
          duration: Duration(seconds: 10),
        );
        _debugLog('Lottie controller initialized');

        if (mounted && !_isDisposed) {
          try {
            _lottieController?.repeat();
            _debugLog('Lottie animation started');
          } catch (e) {
            print('❌ Error starting Lottie animation: $e');
          }
        }
      } catch (e) {
        print('❌ Error creating Lottie controller: $e');
        _lottieController = null;
      }

      // Setup menu animation controller
      _menuController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
      );
      _debugLog('Menu controller initialized');

      // Setup page transition controller
      _pageTransitionController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500),
      );
      _pageTransitionController.forward();
      _debugLog('Page transition controller initialized');

      // Setup rotation controller for circular menu
      _rotationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 30),
      );
      _rotationController.repeat();
      _debugLog('Rotation controller initialized');

      // Setup timer ripple animation
      _timerRippleController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500),
      );
      _timerRippleController.repeat();
      _debugLog('Timer ripple controller initialized');

      // Setup Night Garden fade animation
      _nightGardenFadeController = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: 800), // Increase duration for smoother transition
      );
      _debugLog('Night Garden fade controller initialized');

      _isInitialized = true;
      _debugLog('All animation controllers initialized successfully');
    } catch (e) {
      print('❌ Error initializing animation controllers: $e');
      _isInitialized = false;
    }

    // Update UI when returning to the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _debugLog('Post-frame callback executing');
        // Immediately sync UI with service state
        _syncUIWithAudioService();

        setState(() {
          _selectedTimerMinutes = zenAudioService.timerDurationMinutes;
          _updateBackgroundImage();
          _debugLog('UI state updated with service state');
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if route has changed and we're leaving the page
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      // Stop all sounds when navigating away from this page
      if (zenAudioService.isPlaying) {
        // Use async method in a fire-and-forget way here
        () async {
          await zenAudioService.stopAllSounds();
          print('🔊 Stopped all sounds due to navigation away from Zen Mode page');
        }();
      } else {
        // Double-check all sounds are stopped even if isPlaying is false
        zenAudioService.stopAllSounds();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debugLog('Disposing ZenModePage');

    // Stop all sounds if they're still playing
    if (zenAudioService.isPlaying) {
      zenAudioService.stopAllSounds();
      print('🔊 Stopped all sounds on ZenModePage dispose');
    }

    // Remove Night Garden overlay if active
    if (_nightGardenOverlay != null) {
      _nightGardenOverlay?.remove();
      _nightGardenOverlay = null;
    }

    // Restore original screen brightness when disposing if in Night Garden mode
    if (_isNightGardenMode) {
      try {
        _screenBrightness.setScreenBrightness(_originalBrightness);
        // Reset screen brightness system to ensure it works correctly after zen mode
        Future.delayed(Duration(milliseconds: 200), () {
          _screenBrightness.resetScreenBrightness();
        });
      } catch (e) {
        print('Error restoring brightness on dispose: $e');
      }
    } else {
      // Reset screen brightness system even if not in Night Garden mode
      // to ensure proper brightness control after exiting zen mode
      try {
        _screenBrightness.resetScreenBrightness();
      } catch (e) {
        print('Error resetting brightness on dispose: $e');
      }
    }

    // Check if we're still able to access zenAudioService
    if (zenAudioService != null) {
      // Remove listener using stored reference
      try {
        zenAudioService.removeListener(_onZenServiceChanged);
      } catch (e) {
        print('Error removing audio service listener: $e');
      }
    }

    // Safely dispose animation controllers
    try {
      _presetNameController.dispose();
    } catch (e) {
      print('Error disposing presetNameController: $e');
    }

    try {
      if (_pulseController != null) {
        _pulseController.dispose();
      }
    } catch (e) {
      print('Error disposing pulseController: $e');
    }

    try {
      if (_titleFadeController != null) {
        _titleFadeController.dispose();
      }
    } catch (e) {
      print('Error disposing titleFadeController: $e');
    }

    try {
      if (_titleShimmerController != null) {
        _titleShimmerController.dispose();
      }
    } catch (e) {
      print('Error disposing titleShimmerController: $e');
    }

    try {
      if (_timerRippleController != null) {
        _timerRippleController.dispose();
      }
    } catch (e) {
      print('Error disposing timerRippleController: $e');
    }

    try {
      if (_timerPulseController != null) {
        _timerPulseController.dispose();
      }
    } catch (e) {
      print('Error disposing timerPulseController: $e');
    }

    try {
      if (_lottieController != null) {
        _lottieController!.stop();
        _lottieController!.dispose();
        _lottieController = null;
      }
    } catch (e) {
      print('Error disposing lottieController: $e');
    }

    try {
      if (_menuController != null) {
        _menuController.dispose();
      }
    } catch (e) {
      print('Error disposing menuController: $e');
    }

    try {
      if (_pageTransitionController != null) {
        _pageTransitionController.dispose();
      }
    } catch (e) {
      print('Error disposing pageTransitionController: $e');
    }

    try {
      if (_rotationController != null) {
        _rotationController.dispose();
      }
    } catch (e) {
      print('Error disposing rotationController: $e');
    }

    try {
      if (_nightGardenFadeController != null) {
        _nightGardenFadeController.dispose();
      }
    } catch (e) {
      print('Error disposing nightGardenFadeController: $e');
    }

    // Cancel any active timers
    try {
      if (_timerCountdown != null) {
        _timerCountdown!.cancel();
        _timerCountdown = null;
      }
    } catch (e) {
      print('Error cancelling timer: $e');
    }

    // Dispose intro controllers
    _introPageController.dispose();
    _introFadeController.dispose();

    super.dispose();
  }

  // Callback when ZenAudioService state changes
  void _onZenServiceChanged() {
    if (mounted && !_isDisposed) {
      setState(() {
        _isPlaying = zenAudioService.isPlaying;
        print("SERVICE STATE CHANGED: isPlaying=$_isPlaying");
      });
    }
  }

  // Toggle the expanded menu
  void _toggleMenu() {
    setState(() {
      _isMenuExpanded = !_isMenuExpanded;
      if (_isMenuExpanded) {
        _menuController.forward();
        _menuOpenPercent = 1.0;
      } else {
        _menuController.reverse();
        _menuOpenPercent = 0.0;
        _selectedSoundIndex = -1;
      }
    });
  }

  // Calculate position for circular menu items
  Offset _calculatePosition(int index, int total) {
    final double angle = (index / total) * 2 * math.pi;
    final double x = _initialRadius * math.cos(angle);
    final double y = _initialRadius * math.sin(angle);
    return Offset(x, y);
  }

  // Update background based on active sounds
  void _updateBackgroundImage() {
    // Default background
    String newBackground = 'images/zen/default_background.jpg';

    // Check for active sounds to determine background
    final activeSounds = zenAudioService.availableSounds
        .where((dynamic sound) => sound.isActive as bool)
        .toList();

    if (activeSounds.isNotEmpty) {
      // Prioritize certain backgrounds
      if (activeSounds.any(
        (dynamic sound) => sound.name == 'Rain' || sound.name == 'Thunder',
      )) {
        newBackground = 'images/zen/rain_background.jpg';
      } else if (activeSounds.any(
        (dynamic sound) => sound.name == 'Fireplace',
      )) {
        newBackground = 'images/zen/fire_background.jpg';
      } else if (activeSounds.any(
        (dynamic sound) => sound.name == 'Forest' || sound.name == 'Birds',
      )) {
        newBackground = 'images/zen/forest_background.jpg';
      } else if (activeSounds.any((dynamic sound) => sound.name == 'Ocean')) {
        newBackground = 'images/zen/ocean_background.jpg';
      }
    }

    setState(() {
      _backgroundImage = newBackground;
    });
  }

  // Toggle a specific sound
  void _toggleSound(String soundName) {
    print('TOGGLING SOUND: $soundName');
    
    final soundIndex = zenAudioService.availableSounds.indexWhere((s) => s.name == soundName);
    if (soundIndex == -1) return;
    
    final sound = zenAudioService.availableSounds[soundIndex];
    
    // Check if sound is locked
    if (sound.isLocked && !zenAudioService.isSoundUnlocked(soundName)) {
      // Show purchase dialog for locked sounds
      _showPurchaseSoundDialog(context, soundName);
      return;
    }

    // Set loading state to give immediate feedback
    if (mounted && !_isDisposed) {
      setState(() {});
    }

    // Toggle this sound's state and update background
    zenAudioService.toggleSound(soundName).then((_) {
      if (mounted && !_isDisposed) {
        print(
          'TOGGLED SOUND: $soundName, isPlaying=${zenAudioService.isPlaying}',
        );

        // Force a full UI update
        setState(() {
          _isPlaying = zenAudioService.isPlaying;
          _updateBackgroundImage();
        });
      }
    }).catchError((error) {
      print("Error toggling sound: $error");
      // Force refresh UI state to keep in sync with service
      if (mounted && !_isDisposed) {
        setState(() {
          _isPlaying = zenAudioService.isPlaying;
        });
      }
    });
  }

  // Show dialog to purchase locked sound
  void _showPurchaseSoundDialog(BuildContext context, String soundName) {
    final soundPrice = zenAudioService.getSoundPrice(soundName);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StreamBuilder<UserRecord>(
          stream: UserRecord.getDocument(currentUserReference!),
          builder: (context, snapshot) {
            // Return loading indicator if data is not yet available
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            
            final userData = snapshot.data!;
            
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 350,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Text(
                      'Unlock $soundName Sound',
                      style: FlutterFlowTheme.of(context).titleLarge.override(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Sound icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getSoundIcon(soundName),
                          size: 40,
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Description text
                    Text(
                      'You can unlock this premium sound using Luna Coins or by subscribing to Premium.',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                    SizedBox(height: 16),
                    
                    // Price and user balance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Price',
                              style: FlutterFlowTheme.of(context).labelMedium,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                  ),
                                  child: Image.asset(
                                    'assets/images/lunacoin.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '$soundPrice',
                                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                                    fontFamily: 'Figtree',
                                    fontWeight: FontWeight.bold,
                                    color: FlutterFlowTheme.of(context).warning,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(width: 40),
                        Column(
                          children: [
                            Text(
                              'Your Balance',
                              style: FlutterFlowTheme.of(context).labelMedium,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  color: FlutterFlowTheme.of(context).secondary,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${userData.lunaCoins}',
                                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                                    fontFamily: 'Figtree',
                                    fontWeight: FontWeight.bold,
                                    color: userData.lunaCoins >= soundPrice
                                      ? FlutterFlowTheme.of(context).secondary
                                      : FlutterFlowTheme.of(context).error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Purchase button and premium button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancel button
                        FFButtonWidget(
                          onPressed: () => Navigator.pop(dialogContext),
                          text: 'Cancel',
                          options: FFButtonOptions(
                            width: 100,
                            height: 50,
                            color: FlutterFlowTheme.of(context).secondaryBackground,
                            textStyle: FlutterFlowTheme.of(context).bodyLarge.override(
                              fontFamily: 'Figtree',
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                            elevation: 0,
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        
                        // Purchase with coins button
                        FFButtonWidget(
                          onPressed: userData.lunaCoins >= soundPrice
                            ? () async {
                                // Close purchase dialog
                                Navigator.pop(dialogContext);
                                
                                // Unlock the sound
                                bool success = await zenAudioService.unlockSound(soundName);
                                
                                if (success) {
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Successfully unlocked $soundName sound!',
                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                          fontFamily: 'Figtree',
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: FlutterFlowTheme.of(context).primary,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  
                                  // Force refresh
                                  if (mounted) {
                                    setState(() {});
                                  }
                                } else {
                                  // Show error message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to unlock sound. Please try again.',
                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                          fontFamily: 'Figtree',
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: FlutterFlowTheme.of(context).error,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            : null,
                          text: 'Buy with Coins',
                          options: FFButtonOptions(
                            width: 150,
                            height: 50,
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Figtree',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            elevation: 3,
                            borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    
                    // Premium option
                    if (userData.lunaCoins < soundPrice)
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            Text(
                              'Not enough coins?',
                              style: FlutterFlowTheme.of(context).bodyMedium,
                            ),
                            SizedBox(height: 8),
                            FFButtonWidget(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                // Navigate to membership page
                                Navigator.pushNamed(context, 'MembershipPage');
                              },
                              text: 'Get Premium Membership',
                              options: FFButtonOptions(
                                width: 220,
                                height: 40,
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Figtree',
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                                elevation: 0,
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Toggle play/pause for all sounds
  void _togglePlayPause() {
    bool isCurrentlyPlaying = zenAudioService.isPlaying;
    print(
        "TOGGLE PLAY/PAUSE - Current state: ${isCurrentlyPlaying ? 'PLAYING' : 'PAUSED'}");

    // Count active sounds
    int activeSoundsCount =
        zenAudioService.availableSounds.where((s) => s.isActive).length;

    if (activeSoundsCount == 0) {
      // No active sounds - show message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tap on a sound to activate it first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (isCurrentlyPlaying) {
      // Currently playing, so PAUSE
      print("PAUSING all sounds");
      zenAudioService.pauseAllSounds();
      setState(() {}); // Force UI update
    } else {
      // Currently paused, so PLAY
      print("PLAYING all sounds");
      zenAudioService.resumeAllSounds();
      setState(() {}); // Force UI update
    }
  }

  // Show dialog to save a preset
  void _showSavePresetDialog() {
    _presetNameController.text =
        'My Mix ${DateTime.now().day}-${DateTime.now().month}';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(
              context,
            ).primaryBackground.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, -0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: AnimationController(
                      vsync: this,
                      duration: Duration(milliseconds: 400),
                    )..forward(),
                    curve: Curves.easeOut,
                  ),
                ),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: AnimationController(
                        vsync: this,
                        duration: Duration(milliseconds: 400),
                      )..forward(),
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: Text(
                    'Save Your Zen Mix',
                    style: FlutterFlowTheme.of(context).headlineSmall,
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _presetNameController,
                style: FlutterFlowTheme.of(context).bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Enter a name for your sound mix',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: Text(
                      'Cancel',
                      style: FlutterFlowTheme.of(
                        context,
                      ).bodyMedium.override(
                            fontFamily: 'Readex Pro',
                            color: Colors.white.withOpacity(0.7),
                          ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: FlutterFlowTheme.of(
                        context,
                      ).bodyMedium.override(
                            fontFamily: 'Readex Pro',
                            color: Colors.white,
                          ),
                    ),
                    onPressed: () async {
                      if (_presetNameController.text.isNotEmpty) {
                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        await appState.zenAudioService.savePreset(
                          _presetNameController.text,
                        );
                        Navigator.pop(context);

                        // Show success animation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 10),
                                Text('Mix saved successfully!'),
                              ],
                            ),
                            backgroundColor:
                                FlutterFlowTheme.of(context).primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show dialog to load or delete presets
  void _showPresetsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final appState = Provider.of<AppState>(context);
        final presets = appState.zenAudioService.presets;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(
                context,
              ).primaryBackground.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - value)),
                        child: Text(
                          'Your Saved Mixes',
                          style: FlutterFlowTheme.of(context).headlineSmall,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Container(
                  constraints: BoxConstraints(maxHeight: 300),
                  child: presets.isEmpty
                      ? Center(
                          child: Text(
                            'No saved mixes yet',
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: presets.length,
                          itemBuilder: (context, index) {
                            final preset = presets[index];
                            return DelayedAnimation(
                              delay: index * 100,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      preset.name,
                                      style: FlutterFlowTheme.of(
                                        context,
                                      ).titleMedium.override(
                                            fontFamily: 'Outfit',
                                            color: Colors.white,
                                          ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.play_arrow,
                                            color: Colors.white,
                                          ),
                                          onPressed: () async {
                                            await appState.zenAudioService
                                                .loadPreset(preset.name);
                                            Navigator.pop(context);
                                            setState(() {
                                              _isPlaying = true;
                                              _updateBackgroundImage();
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            await appState.zenAudioService
                                                .deletePreset(preset.name);
                                            Navigator.pop(context);
                                            _showPresetsDialog(); // Refresh the dialog
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      await appState.zenAudioService
                                          .loadPreset(preset.name);
                                      Navigator.pop(context);
                                      setState(() {
                                        _isPlaying = true;
                                        _updateBackgroundImage();
                                      });
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(
                        'Close',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Readex Pro',
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Set a timer for auto-stopping
  void _setTimer(int minutes) {
    // Cancel existing timer
    _timerCountdown?.cancel();

    setState(() {
      if (_selectedTimerMinutes == minutes || minutes == 0) {
        // If tapping the same button or cancel, cancel the timer
        _selectedTimerMinutes = null;
        zenAudioService.cancelTimer();
        _timerDisplay = '';
      } else {
        _selectedTimerMinutes = minutes;
        zenAudioService.setTimer(minutes);

        // Start countdown display
        int secondsRemaining = minutes * 60;
        _updateTimerDisplay(secondsRemaining);

        _timerCountdown = Timer.periodic(Duration(seconds: 1), (timer) {
          secondsRemaining--;

          if (secondsRemaining <= 0) {
            // Timer complete
            timer.cancel();
            _showTimerCompleteNotification();
            setState(() {
              _selectedTimerMinutes = null;
              _timerDisplay = '';
            });
          } else {
            // Update timer display
            _updateTimerDisplay(secondsRemaining);
          }
        });
      }
    });
  }

  // Update timer display text
  void _updateTimerDisplay(int seconds) {
    if (!mounted) return;

    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;

    setState(() {
      if (hours > 0) {
        _timerDisplay =
            '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
      } else {
        _timerDisplay =
            '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
      }
    });
  }

  // Show notification when timer completes
  void _showTimerCompleteNotification() {
    if (!mounted) return;

    try {
      // Stop all sounds safely
      Future.microtask(() async {
        try {
          await zenAudioService.stopAllSounds();

          // Only update state if component is still mounted
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        } catch (e) {
          print('Error stopping sounds on timer completion: $e');
          // Fallback approach if the primary method fails
          if (mounted) {
            for (var sound in zenAudioService.availableSounds) {
              if (sound.isActive) {
                zenAudioService.toggleSound(sound.name);
              }
            }
          }
        }
      });

      // Show notification after ensuring we've handled the audio state
      Future.delayed(Duration(milliseconds: 300), () {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.timer_off, color: Colors.white),
                SizedBox(width: 10),
                Text('Time\'s up! Your zen session has ended.'),
              ],
            ),
            backgroundColor: FlutterFlowTheme.of(context).primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      });
    } catch (e) {
      print('Error in timer completion handler: $e');
    }
  }

  // Stop all active sounds
  void _stopAllSounds() {
    print("STOPPING ALL SOUNDS");

    // Stop all sounds in the service
    zenAudioService.stopAllSounds();

    // Force UI update
    setState(() {});

    // Give user feedback
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All sounds stopped'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Toggle Night Garden (battery saver) mode
  void _toggleNightGardenMode() async {
    if (!_isNightGardenMode) {
      // Enter Night Garden mode
      // Save current brightness before entering Night Garden mode
      try {
        _originalBrightness = await _screenBrightness.current;
        await _screenBrightness.setScreenBrightness(_nightGardenBrightness);
      } catch (e) {
        print('Error managing screen brightness: $e');
      }

      // Hide the system UI before creating the overlay
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      // Create and insert a full-screen overlay that truly covers everything
      _nightGardenOverlay = OverlayEntry(
        builder: (context) => Material(
          color: Color(0xFF050716),
          child: WillPopScope(
            onWillPop: () async {
              _toggleNightGardenMode();
              return false;
            },
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 500),
              child: Stack(
                children: [
                  // Static stars with different opacities (no animation)
                  ...List.generate(20, (index) {
                    final random = math.Random(index);
                    final size = random.nextDouble() * 2.0 + 0.5;
                    final position = Offset(
                      random.nextDouble() * MediaQuery.of(context).size.width,
                      random.nextDouble() * MediaQuery.of(context).size.height,
                    );
                    final opacity = 0.4 + random.nextDouble() * 0.6;

                    return Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(opacity),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),

                  // Main centered content
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title
                          Text(
                            'Night Garden',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w200,
                              letterSpacing: 2.0,
                            ),
                          ),
                          SizedBox(height: 8),

                          // Subtitle in simple container
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .primary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Battery Saving Mode',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),

                          SizedBox(height: 50),

                          // Clock display (simplified)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context)
                                    .primary
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: StreamBuilder<int>(
                              stream: Stream.periodic(
                                  Duration(seconds: 1), (x) => x),
                              builder: (context, snapshot) {
                                final now = DateTime.now();
                                return Text(
                                  _timerDisplay.isNotEmpty
                                      ? _timerDisplay
                                      : DateFormat('HH:mm').format(now),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w200,
                                    letterSpacing: 2,
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: 60),

                          // Relaxation message instead of sound list
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 30,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context)
                                    .primary
                                    .withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.spa_outlined,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 40,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Close your eyes, breathe deeply,\nand let the sounds guide you to peace.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.5,
                                    height: 1.6,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Your sounds are playing in the background',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Exit button (simplified)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: Center(
                      child: GestureDetector(
                        onTap: _toggleNightGardenMode,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Exit Night Garden',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Insert the overlay into the Overlay
      Overlay.of(context).insert(_nightGardenOverlay!);

      setState(() {
        _isNightGardenMode = true;
      });
    } else {
      // Exit Night Garden mode
      // First remove the overlay with an animation
      if (_nightGardenOverlay != null) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            _nightGardenOverlay?.remove();
            _nightGardenOverlay = null;
          }
        });
      }

      setState(() {
        _isNightGardenMode = false;
      });

      // Restore original brightness
      try {
        await _screenBrightness.setScreenBrightness(_originalBrightness);
        // Reset the system brightness after a delay to ensure it works correctly
        await Future.delayed(Duration(milliseconds: 200));
        await _screenBrightness.resetScreenBrightness();
      } catch (e) {
        print('Error restoring screen brightness: $e');
      }

      // Restore the system UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  // First, add a method to stop the timer
  void _stopTimer() {
    if (_timerCountdown != null) {
      _timerCountdown!.cancel();
      _timerCountdown = null;
    }

    setState(() {
      _selectedTimerMinutes = null;
      _timerDisplay = '';
    });

    zenAudioService.cancelTimer();

    // Show feedback to user
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.timer_off, color: Colors.white),
            SizedBox(width: 10),
            Text('Timer stopped'),
          ],
        ),
        backgroundColor: FlutterFlowTheme.of(context).primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Helper method to check if user needs to see the intro
  Future<void> _checkIfNeedsZenModeIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Check if the user has seen the Zen Mode intro before
      final hasSeenIntro = prefs.getBool('has_seen_zen_mode_intro') ?? false;

      if (!hasSeenIntro) {
        if (mounted) {
          setState(() {
            _showZenModeIntro = true;
          });

          // Initialize the intro fade animation
          _introFadeController.forward();
        }
      }
    } catch (e) {
      print('Error checking Zen Mode intro status: $e');
    }
  }

  // Mark that the user has seen the intro
  Future<void> _markZenModeIntroComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_zen_mode_intro', true);

      if (mounted) {
        // Animate out the intro
        await _introFadeController.reverse();

        setState(() {
          _showZenModeIntro = false;
        });
      }
    } catch (e) {
      print('Error marking Zen Mode intro as complete: $e');
      // Fallback for error case - just remove the intro
      if (mounted) {
        setState(() {
          _showZenModeIntro = false;
        });
      }
    }
  }

  // For testing - resets the intro seen flag to show it again
  Future<void> _resetZenModeIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_zen_mode_intro', false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zen Mode intro reset. Restart to see it again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error resetting Zen Mode intro: $e');
    }
  }

  // Add a method to check if a specific sound requires subscription
  bool _isSoundAvailable(ZenAudioSound sound) {
    // If user has full access via subscription, all sounds are available
    if (_hasFullAccess) {
      return true;
    }
    
    // Non-locked sounds are always available
    if (!sound.isLocked) {
      return true;
    }
    
    // For locked sounds, check if user has already unlocked it
    return zenAudioService.isSoundUnlocked(sound.name);
  }
  
  // Method to handle sound selection with subscription checks
  void _handleSoundSelection(ZenAudioSound sound) {
    if (_isSoundAvailable(sound)) {
      // User can access this sound - proceed with toggling it
      _toggleSound(sound.name);
    } else {
      // Instead of showing premium required dialog, show purchase option
      _showPurchaseSoundDialog(context, sound.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        // Get sounds safely
        final List<ZenAudioSound> sounds = [];
        try {
          if (zenAudioService != null) {
            sounds.addAll(zenAudioService.availableSounds);
          }
        } catch (e) {
          print('Error getting sounds: $e');
        }

        return WillPopScope(
          onWillPop: () async {
            // Show confirmation dialog
            bool shouldExit = await _showExitConfirmationDialog();
            return shouldExit;
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false, // Disable default back button
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  _showExitConfirmationDialog();
                },
              ),
              iconTheme: IconThemeData(color: Colors.white),
              title: AnimatedBuilder(
                animation: _titleFadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _titleFadeController.value,
                    child: AnimatedBuilder(
                      animation: _titleShimmerController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.5),
                                Colors.white,
                              ],
                              stops: [0.0, _titleShimmerController.value, 1.0],
                            ).createShader(bounds);
                          },
                          child: Text(
                            'Zen Mode',
                            style: TextStyle(
                              fontSize: 24.0,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              centerTitle: true,
              actions: [
                if (_timerDisplay.isNotEmpty)
                  GestureDetector(
                    onTap: _stopTimer,
                    child: AnimatedBuilder(
                      animation: _timerPulseController,
                      builder: (context, child) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(
                                0.3 + (_timerPulseController.value * 0.2),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(
                                  0.5 + (_timerPulseController.value * 0.3),
                                ),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  color: Colors.white.withOpacity(
                                    0.7 + (_timerPulseController.value * 0.3),
                                  ),
                                  size: 18,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  _timerDisplay,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(
                                      0.8 + (_timerPulseController.value * 0.2),
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.close,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                // Night Garden mode toggle
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 0, 12, 0),
                  child: IconButton(
                    icon: Icon(
                        _isNightGardenMode ? Icons.brightness_3 : Icons.dark_mode,
                        color: Colors.white),
                    onPressed: _toggleNightGardenMode,
                    tooltip: 'Night Garden Mode',
                  ),
                ),
                // Timer button
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 0, 12, 0),
                  child: IconButton(
                    icon: Icon(Icons.timer, color: Colors.white),
                    onPressed: () => _showTimerBottomSheet(context),
                    tooltip: 'Set Timer',
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                // Lottie animation background with proper null handling
                Positioned.fill(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.5),
                      BlendMode.darken,
                    ),
                    child: _isInitialized && _lottieController != null
                        ? Lottie.asset(
                            'assets/jsons/boat.json',
                            controller: _lottieController,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('⚠️ Lottie error: $error');
                              print('⚠️ Lottie stacktrace: $stackTrace');
                              return Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white30,
                                    size: 64,
                                  ),
                                ),
                              );
                            },
                            onWarning: (warning) {
                              print('⚠️ Lottie warning: $warning');
                            },
                          )
                        : Container(color: Colors.black),
                  ),
                ),

                // Main content
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Space at the top for app bar
                      SizedBox(height: 100),

                      // Active sound chips at the top
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: sounds
                              .where(
                                (dynamic sound) => sound.isActive as bool,
                              )
                              .map<Widget>(
                                (dynamic sound) => Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                    8,
                                    0,
                                    8,
                                    0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .primary
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color:
                                            FlutterFlowTheme.of(context).primary,
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                        12,
                                        8,
                                        12,
                                        8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getSoundIcon(sound.name),
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            sound.name,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Readex Pro',
                                                  color: Colors.white,
                                                ),
                                          ),
                                          SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => _handleSoundSelection(sound),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                      // Sound tile grid
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio:
                                  0.85, // Adjusted for volume sliders
                            ),
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount: sounds.length,
                            itemBuilder: (context, index) {
                              final dynamic sound = sounds[index];
                              final bool isActive = sound.isActive as bool;
                              final bool isLocked = sound.isLocked as bool && 
                                  !zenAudioService.isSoundUnlocked(sound.name as String);
                                  
                              return GestureDetector(
                                onTap: () {
                                  // Add a visual indicator of the tap before action completes
                                  HapticFeedback.lightImpact();
                                  _handleSoundSelection(sound);
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? FlutterFlowTheme.of(context)
                                            .primary
                                            .withOpacity(0.3)
                                        : Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isActive
                                          ? FlutterFlowTheme.of(context).primary
                                          : Colors.white.withOpacity(0.2),
                                      width: isActive ? 2 : 1,
                                    ),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: FlutterFlowTheme.of(context)
                                                  .primary
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Stack(
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _getSoundIcon(sound.name),
                                            size: 48,
                                            color: Colors.white,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            sound.name,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Readex Pro',
                                                  color: Colors.white,
                                                ),
                                          ),
                                          if (isLocked)
                                            Padding(
                                              padding: EdgeInsets.only(top: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Premium Sound',
                                                    style: FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily: 'Readex Pro',
                                                          color: Colors.white70,
                                                          fontSize: 12,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          AnimatedContainer(
                                            duration: Duration(milliseconds: 300),
                                            height: isActive ? 40 : 0,
                                            child: AnimatedOpacity(
                                              opacity: isActive ? 1.0 : 0.0,
                                              duration: Duration(milliseconds: 300),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8.0,
                                                  vertical: 4.0,
                                                ),
                                                child: SliderTheme(
                                                  data: SliderThemeData(
                                                    trackHeight: 4,
                                                    thumbShape: RoundSliderThumbShape(
                                                      enabledThumbRadius: 6,
                                                    ),
                                                    overlayShape:
                                                        RoundSliderOverlayShape(
                                                      overlayRadius: 14,
                                                    ),
                                                    thumbColor: Colors.white,
                                                    activeTrackColor:
                                                        Colors.white.withOpacity(0.7),
                                                    inactiveTrackColor:
                                                        Colors.white.withOpacity(0.3),
                                                  ),
                                                  child: Slider(
                                                    value: sound.volume as double,
                                                    min: 0.0,
                                                    max: 1.0,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        sound.volume = value;
                                                      });
                                                      zenAudioService.setSoundVolume(
                                                          sound.name as String, value);
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isLocked)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.4),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.lock_open,
                                                  color: Colors.white,
                                                  size: 32,
                                                ),
                                                SizedBox(height: 8),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(context).warning.withOpacity(0.9),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: Colors.white.withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.2),
                                                        blurRadius: 4,
                                                        spreadRadius: 0,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 20,
                                                        height: 20,
                                                        margin: EdgeInsets.only(right: 6),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: Colors.white.withOpacity(0.2),
                                                          border: Border.all(
                                                            color: Colors.white.withOpacity(0.3),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(10),
                                                          child: Image.asset(
                                                            'assets/images/lunacoin.png',
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        '${zenAudioService.getSoundPrice(sound.name as String)}',
                                                        style: FlutterFlowTheme.of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily: 'Readex Pro',
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 15,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Play/pause button at the bottom
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Only show stop button when there are active sounds
                            Consumer<AppState>(
                              builder: (context, appState, _) {
                                // Check if any sounds are active
                                bool anySoundsActive = appState
                                    .zenAudioService.availableSounds
                                    .where((s) => s.isActive)
                                    .isNotEmpty;

                                if (!anySoundsActive) {
                                  // Don't show any button when no sounds are active
                                  return SizedBox();
                                }

                                // Show a modern stop button
                                return AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    final double scale =
                                        1.0 + (_pulseController.value * 0.05);

                                    return GestureDetector(
                                      onTap: _stopAllSounds,
                                      child: Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .primary
                                                .withOpacity(0.2),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: FlutterFlowTheme.of(context)
                                                  .primary
                                                  .withOpacity(0.5 +
                                                      (_pulseController.value *
                                                          0.5)),
                                              width: 2,
                                            ),
                                            // Add subtle gradient for modern look
                                            gradient: RadialGradient(
                                              colors: [
                                                FlutterFlowTheme.of(context)
                                                    .primary
                                                    .withOpacity(0.6),
                                                FlutterFlowTheme.of(context)
                                                    .primary
                                                    .withOpacity(0.2),
                                              ],
                                              radius: 0.8,
                                            ),
                                            // Add subtle shadow
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary
                                                        .withOpacity(0.1 +
                                                            (_pulseController
                                                                    .value *
                                                                0.2)),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              )
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.stop_rounded,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Night Garden Mode overlay
                if (_isNightGardenMode)
                  Container(), // Empty container since we're now using a true overlay

                // Intro overlay for first-time users
                if (_showZenModeIntro) _buildZenModeIntro(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show timer selection bottom sheet
  void _showTimerBottomSheet(BuildContext context) {
    // Default timer values
    int hours = 0;
    int minutes = 30;

    if (_selectedTimerMinutes != null) {
      hours = _selectedTimerMinutes! ~/ 60;
      minutes = _selectedTimerMinutes! % 60;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(
                  context,
                ).primaryBackground.withOpacity(0.9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Text(
                    'Set Timer',
                    style: FlutterFlowTheme.of(context).headlineSmall,
                  ),
                  SizedBox(height: 20),
                  // Cupertino-style time picker
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hours picker
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 44,
                            backgroundColor: Colors.transparent,
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                hours = index;
                              });
                            },
                            children: List<Widget>.generate(12, (int index) {
                              return Center(
                                child: Text(
                                  '$index',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                  ),
                                ),
                              );
                            }),
                            scrollController: FixedExtentScrollController(
                              initialItem: hours,
                            ),
                          ),
                        ),
                        Text(
                          'hours',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(width: 20),
                        // Minutes picker
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 44,
                            backgroundColor: Colors.transparent,
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                minutes = index * 5;
                              });
                            },
                            children: List<Widget>.generate(12, (int index) {
                              return Center(
                                child: Text(
                                  '${index * 5}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                  ),
                                ),
                              );
                            }),
                            scrollController: FixedExtentScrollController(
                              initialItem: minutes ~/ 5,
                            ),
                          ),
                        ),
                        Text(
                          'min',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 50,
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: FlutterFlowTheme.of(
                                  context,
                                ).bodyMedium.override(
                                      fontFamily: 'Readex Pro',
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Start button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final totalMinutes = (hours * 60) + minutes;
                            if (totalMinutes > 0) {
                              _setTimer(totalMinutes);
                            } else {
                              _setTimer(0); // Cancel timer if zero
                            }
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 50,
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .primary
                                  .withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Start Timer',
                                style: FlutterFlowTheme.of(
                                  context,
                                ).bodyMedium.override(
                                      fontFamily: 'Readex Pro',
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Quick presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [15, 30, 45, 60].map((preset) {
                      return GestureDetector(
                        onTap: () {
                          _setTimer(preset);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '$preset min',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Add the stop timer button when a timer is active
                  if (_selectedTimerMinutes != null) ...[
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        _stopTimer();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_off,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Stop Current Timer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Build the intro overlay
  Widget _buildZenModeIntro() {
    return AnimatedBuilder(
      animation: _introFadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _introFadeController.value,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.9),
        child: Stack(
          children: [
            // Page view with intro content
            PageView(
              controller: _introPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIntroPage = index;
                });
              },
              children: [
                // Page 1 - Welcome to Zen Mode
                _buildIntroPage(
                  icon: Icons.self_improvement,
                  title: 'Welcome to Zen Mode',
                  description:
                      'Your personal sound sanctuary for relaxation, focus, and mindfulness.',
                  color: FlutterFlowTheme.of(context).primary,
                ),

                // Page 2 - Mix and Match Sounds
                _buildIntroPage(
                  icon: Icons.library_music,
                  title: 'Mix Your Perfect Ambience',
                  description:
                      'Tap any sound card to activate it. Combine multiple sounds to create your perfect environment.',
                  color: FlutterFlowTheme.of(context).tertiary,
                ),

                // Page 3 - Set a Timer
                _buildIntroPage(
                  icon: Icons.timer,
                  title: 'Set a Timer',
                  description:
                      'Use the timer to automatically end your session. Tap the timer button in the top right.',
                  color: FlutterFlowTheme.of(context).secondary,
                ),

                // Page 4 - Night Garden Mode
                _buildIntroPage(
                  icon: Icons.dark_mode,
                  title: 'Night Garden Mode',
                  description:
                      'Activate battery-saving mode for nighttime use. Perfect for sleep sounds that run all night.',
                  color: Color(0xFF1E3A8A),
                ),
              ],
            ),

            // Bottom controls for navigation
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalIntroPages,
                      (index) => AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentIntroPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentIntroPage == index
                              ? FlutterFlowTheme.of(context).primary
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Skip button
                      TextButton(
                        onPressed: _markZenModeIntroComplete,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // Next/Done button
                      ElevatedButton(
                        onPressed: () {
                          if (_currentIntroPage < _totalIntroPages - 1) {
                            _introPageController.nextPage(
                              duration: Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _markZenModeIntroComplete();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          foregroundColor: Colors.white,
                          minimumSize: Size(120, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _currentIntroPage < _totalIntroPages - 1
                              ? 'Next'
                              : 'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build each intro page - fix to remove yellow underlines
  Widget _buildIntroPage({
    required IconData icon,
    required String title,
    required String description,
    String? image,
    required Color color,
  }) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                icon,
                size: 60,
                color: color,
              ),
            ),

            SizedBox(height: 40),

            // Title
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),

            // Description
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
                fontFamily: 'Readex Pro',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Show a confirmation dialog when users try to leave zen mode
  Future<bool> _showExitConfirmationDialog() async {
    bool shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.5 + (0.5 * value),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.spa_outlined,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Leave Zen Mode?',
                          style: FlutterFlowTheme.of(context).titleMedium.override(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Divider
                  Divider(
                    thickness: 1,
                    color: FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
                    indent: 20,
                    endIndent: 20,
                  ),
                  
                  // Message
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Text(
                      'Are you sure you want to exit zen mode? All sounds will stop playing.',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Buttons
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Stay button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(dialogContext, false),
                            child: Container(
                              height: 50,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Stay',
                                  style: FlutterFlowTheme.of(context).bodyMedium,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Leave button
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.pop(dialogContext, true);
                            },
                            child: Container(
                              height: 50,
                              margin: EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'Leave',
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        fontFamily: 'Readex Pro',
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ) ?? false;

    if (shouldExit && mounted) {
      // Stop all sounds
      if (zenAudioService.isPlaying) {
        await zenAudioService.stopAllSounds();
      }
      
      // Add fade out animation before navigating back
      await _animateExitAndNavigateBack();
    }
    
    return shouldExit;
  }

  // Animate exit with fade effect before navigating back
  Future<void> _animateExitAndNavigateBack() async {
    // Double-check that all sounds are stopped before animation
    if (zenAudioService.isPlaying) {
      await zenAudioService.stopAllSounds();
      // Wait a small amount of time to ensure audio is fully stopped
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    // Create an overlay entry with a black background that fades in
    final OverlayState overlayState = Overlay.of(context);
    
    // Create the animation controller locally
    final animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Create overlay entry using a separate variable to avoid self-reference
    final fadeOverlay = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Container(
            color: Colors.black.withOpacity(animationController.value * 0.7),
          );
        },
      ),
    );
    
    // Insert the overlay
    overlayState.insert(fadeOverlay);
    
    // Start the animation
    await animationController.forward();
    
    // Final check to ensure audio is completely stopped before navigation
    await zenAudioService.stopAllSounds();
    
    // Reset screen brightness system to ensure proper control after zen mode
    try {
      // Reset the system brightness to ensure it's properly working after zen mode
      await _screenBrightness.resetScreenBrightness();
      // Small delay to let the system catch up with brightness reset
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      print('Error resetting screen brightness on exit: $e');
    }
    
    // Navigate back after animation completes
    Navigator.of(context).pop();
    
    // Remove the overlay after a slight delay
    await Future.delayed(Duration(milliseconds: 100));
    fadeOverlay.remove();
    
    // Dispose the controller
    animationController.dispose();
  }
}

// Sound card widget
class SoundCard extends StatelessWidget {
  final dynamic sound;
  final VoidCallback onToggle;
  final Function(double) onVolumeChanged;

  const SoundCard({
    Key? key,
    required this.sound,
    required this.onToggle,
    required this.onVolumeChanged,
  }) : super(key: key);

  // Helper method to get icon based on sound name
  IconData _getSoundIcon(String soundName) {
    switch (soundName.toLowerCase()) {
      case 'rain':
        return Icons.water_drop;
      case 'thunder':
        return Icons.bolt;
      case 'forest':
        return Icons.forest;
      case 'ocean':
        return Icons.water;
      case 'fireplace':
        return Icons.local_fire_department;
      case 'wind':
        return Icons.air;
      case 'birds':
        return Icons.flutter_dash;
      case 'stream':
        return Icons.waves;
      default:
        return Icons.music_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: (sound.isActive as bool)
              ? FlutterFlowTheme.of(context).primary.withOpacity(0.7)
              : FlutterFlowTheme.of(
                  context,
                ).secondaryBackground.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (sound.isActive as bool)
                ? FlutterFlowTheme.of(context).primary
                : Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getSoundIcon(sound.name as String),
              color: Colors.white,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              sound.name as String,
              style: FlutterFlowTheme.of(
                context,
              ).titleMedium.override(fontFamily: 'Outfit', color: Colors.white),
            ),
            if (sound.isActive as bool)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                    thumbColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.7),
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                  ),
                  child: Slider(
                    value: sound.volume as double,
                    min: 0.0,
                    max: 1.0,
                    onChanged: onVolumeChanged,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
