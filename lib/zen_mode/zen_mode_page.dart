import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '/services/app_state.dart';
import '/services/zen_audio_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
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

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    if (widget.isActive) {
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(RippleAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _rippleController.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _rippleController.stop();
    }
  }

  @override
  void dispose() {
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
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

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
      _controller.forward();
    } else {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
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

  @override
  void initState() {
    super.initState();

    // Initialize services
    final appState = Provider.of<AppState>(context, listen: false);
    zenAudioService = appState.zenAudioService;
    zenAudioService.initialize();

    // Add listener to update UI when service state changes
    zenAudioService.addListener(_onZenServiceChanged);

    // Setup pulse animation for play button
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    // Setup title fade animation
    _titleFadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();

    // Setup title shimmer animation
    _titleShimmerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2200),
    );

    Future.delayed(Duration(milliseconds: 4000), () {
      if (mounted) {
        _titleShimmerController.repeat();
      }
    });

    // Setup timer pulse animation
    _timerPulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);

    // Setup Lottie animation controller - don't automatically start repeating
    _lottieController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    );

    // Start animation only if widget is still mounted
    if (mounted) {
      _lottieController?.repeat();
    }

    // Setup menu animation controller
    _menuController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    // Setup page transition controller
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..forward();

    // Setup rotation controller for circular menu
    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30),
    )..repeat();

    // Setup timer ripple animation
    _timerRippleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();

    _isInitialized = true;

    // Update UI when returning to the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Immediately sync UI with service state
        _syncUIWithAudioService();

        setState(() {
          _selectedTimerMinutes = zenAudioService.timerDurationMinutes;
          _updateBackgroundImage();
          print(
            'ZenMode initialized: isPlaying=$_isPlaying, service.isPlaying=${zenAudioService.isPlaying}',
          );
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // This is a safe place to get references to any ancestor widgets
    // that might be needed later in dispose()
    if (!_isInitialized) {
      // Only get references when not already initialized
      // to avoid unnecessary lookups
      final appState = Provider.of<AppState>(context, listen: false);
      zenAudioService = appState.zenAudioService;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Check if we're still able to access zenAudioService
    if (zenAudioService != null) {
      // Remove listener using stored reference
      zenAudioService.removeListener(_onZenServiceChanged);
    }

    // Stop animations before disposing to prevent assertions
    _pulseController.stop();
    _titleFadeController.stop();
    _titleShimmerController.stop();
    _timerRippleController.stop();
    _timerPulseController.stop();
    if (_lottieController != null) {
      _lottieController!.stop();
    }
    _menuController.stop();
    _pageTransitionController.stop();
    _rotationController.stop();

    // Cancel the countdown timer if it exists
    _timerCountdown?.cancel();

    // Now dispose of controllers
    _presetNameController.dispose();
    _pulseController.dispose();
    _titleFadeController.dispose();
    _titleShimmerController.dispose();
    _timerRippleController.dispose();
    _timerPulseController.dispose();
    if (_lottieController != null) {
      _lottieController!.dispose();
      _lottieController = null; // Set to null after disposal
    }
    _menuController.dispose();
    _pageTransitionController.dispose();
    _rotationController.dispose();

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

    // Set loading state to give immediate feedback
    setState(() {});

    // Toggle this sound's state and update background
    zenAudioService.toggleSound(soundName).then((_) {
      if (mounted) {
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
      if (mounted) {
        setState(() {
          _isPlaying = zenAudioService.isPlaying;
        });
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final sounds = zenAudioService.availableSounds;

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: true,
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
                AnimatedBuilder(
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
                          ],
                        ),
                      ),
                    );
                  },
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
              // Lottie animation background
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.darken,
                  ),
                  child: _isInitialized && _lottieController != null
                      ? Lottie.asset(
                          'assets/jsons/boat.json',
                          controller: _lottieController!,
                          fit: BoxFit.cover,
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
                                    color: FlutterFlowTheme.of(
                                      context,
                                    ).primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: FlutterFlowTheme.of(
                                        context,
                                      ).primary,
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
                                          style: FlutterFlowTheme.of(
                                            context,
                                          ).bodyMedium.override(
                                                fontFamily: 'Readex Pro',
                                                color: Colors.white,
                                              ),
                                        ),
                                        SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _toggleSound(sound.name),
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
                            return GestureDetector(
                              onTap: () {
                                // Add a visual indicator of the tap before action completes
                                HapticFeedback.lightImpact();
                                _toggleSound(sound.name as String);
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? FlutterFlowTheme.of(
                                          context,
                                        ).primary.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive
                                        ? FlutterFlowTheme.of(
                                            context,
                                          ).primary
                                        : Colors.white.withOpacity(0.2),
                                    width: isActive ? 2 : 1,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: FlutterFlowTheme.of(
                                              context,
                                            ).primary.withOpacity(0.3),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
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
                                      style: FlutterFlowTheme.of(
                                        context,
                                      ).bodyMedium.override(
                                            fontFamily: 'Readex Pro',
                                            color: Colors.white,
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
                                                zenAudioService.setSoundVolume(
                                                  sound.name as String,
                                                  value,
                                                );
                                                setState(() {});
                                              },
                                            ),
                                          ),
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
            ],
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
                ],
              ),
            );
          },
        );
      },
    );
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
