import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class ZenAudioSound {
  final String name;
  final String assetPath;
  final String iconPath;
  double volume;
  bool isActive;
  AudioPlayer? player;

  ZenAudioSound({
    required this.name,
    required this.assetPath,
    required this.iconPath,
    this.volume = 0.5,
    this.isActive = false,
    this.player,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'assetPath': assetPath,
      'iconPath': iconPath,
      'volume': volume,
      'isActive': isActive,
    };
  }

  factory ZenAudioSound.fromJson(Map<String, dynamic> json) {
    return ZenAudioSound(
      name: json['name'],
      assetPath: json['assetPath'],
      iconPath: json['iconPath'],
      volume: json['volume'],
      isActive: json['isActive'],
    );
  }
}

class ZenAudioPreset {
  final String name;
  final List<ZenAudioSound> sounds;

  ZenAudioPreset({required this.name, required this.sounds});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sounds': sounds.map((sound) => sound.toJson()).toList(),
    };
  }

  factory ZenAudioPreset.fromJson(Map<String, dynamic> json) {
    return ZenAudioPreset(
      name: json['name'],
      sounds: (json['sounds'] as List)
          .map((sound) => ZenAudioSound.fromJson(sound))
          .toList(),
    );
  }
}

class ZenAudioService extends ChangeNotifier {
  static final ZenAudioService _instance = ZenAudioService._internal();

  List<ZenAudioSound> _availableSounds = [];
  List<ZenAudioPreset> _presets = [];
  bool _isPlaying = false;
  bool _isInitialized = false;
  Timer? _zenTimer;
  int _timerDurationMinutes = 0;

  // Keep track of which sounds were active when paused
  List<String> _activeSoundsBeforePause = [];

  // Debug flag - set to true for verbose logging
  final bool _debug = true;

  // Getters
  List<ZenAudioSound> get availableSounds => _availableSounds;
  List<ZenAudioPreset> get presets => _presets;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  int get timerDurationMinutes => _timerDurationMinutes;

  // Singleton constructor
  factory ZenAudioService() {
    return _instance;
  }

  ZenAudioService._internal() {
    _debugLog('ZenAudioService initialized');
  }

  // Helper method for debug logging
  void _debugLog(String message) {
    if (_debug) {
      print('🧘 ZenAudioService: $message');
    }
  }

  // For debugging purposes - force the playing state
  void forcePlayingState(bool playing) {
    if (_isPlaying != playing) {
      _debugLog('⚠️ FORCE PLAYING STATE from $_isPlaying to $playing');
      _isPlaying = playing;
      notifyListeners();
    }
  }

  // Update the playing state based on whether any active sounds are actually playing
  void updatePlayingState() {
    bool anyActiveSounds = false;
    bool anyPlaying = false;

    for (final sound in _availableSounds) {
      if (sound.isActive) {
        anyActiveSounds = true;
        if (sound.player != null && sound.player!.playing) {
          anyPlaying = true;
          break;
        }
      }
    }

    // If there are active sounds but none are playing, the user expects to see the play button
    // If there are active sounds and at least one is playing, show the pause button
    if (_isPlaying != anyPlaying) {
      _debugLog(
          '⚠️ UPDATING PLAYING STATE: $_isPlaying → $anyPlaying (active sounds: $anyActiveSounds)');
      _isPlaying = anyPlaying;
      notifyListeners();
    }
  }

  // Initialize the zen audio service with available sounds
  Future<void> initialize() async {
    if (_isInitialized) return;

    _debugLog('Initializing zen audio service');

    // Define available sounds
    _availableSounds = [
      ZenAudioSound(
        name: 'Rain',
        assetPath: 'audio/zen/rain.mp3',
        iconPath: 'icons/zen/rain.png',
      ),
      ZenAudioSound(
        name: 'Thunder',
        assetPath: 'audio/zen/thunder.mp3',
        iconPath: 'icons/zen/thunder.png',
      ),
      ZenAudioSound(
        name: 'Forest',
        assetPath: 'audio/zen/forest.mp3',
        iconPath: 'icons/zen/forest.png',
      ),
      ZenAudioSound(
        name: 'Ocean',
        assetPath: 'audio/zen/ocean.mp3',
        iconPath: 'icons/zen/ocean.png',
      ),
      ZenAudioSound(
        name: 'Fireplace',
        assetPath: 'audio/zen/fireplace.mp3',
        iconPath: 'icons/zen/fire.png',
      ),
      ZenAudioSound(
        name: 'Wind',
        assetPath: 'audio/zen/wind.mp3',
        iconPath: 'icons/zen/wind.png',
      ),
      ZenAudioSound(
        name: 'Birds',
        assetPath: 'audio/zen/birds.mp3',
        iconPath: 'icons/zen/birds.png',
      ),
      ZenAudioSound(
        name: 'Stream',
        assetPath: 'audio/zen/stream.mp3',
        iconPath: 'icons/zen/stream.png',
      ),
    ];

    // Load saved presets
    await loadPresets();

    _isInitialized = true;
    notifyListeners();
  }

  // Load saved presets from shared preferences
  Future<void> loadPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getStringList('zen_presets');

      if (presetsJson != null) {
        _presets = presetsJson
            .map(
              (presetString) =>
                  ZenAudioPreset.fromJson(json.decode(presetString)),
            )
            .toList();
        _debugLog('Loaded ${_presets.length} presets');
      }
    } catch (e) {
      _debugLog('Error loading presets: $e');
    }
  }

  // Save presets to shared preferences
  Future<void> savePresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson =
          _presets.map((preset) => json.encode(preset.toJson())).toList();

      await prefs.setStringList('zen_presets', presetsJson);
      _debugLog('Saved ${_presets.length} presets');
    } catch (e) {
      _debugLog('Error saving presets: $e');
    }
  }

  // Toggle a sound on or off
  Future<void> toggleSound(String soundName) async {
    _debugLog('🔄 Toggling sound: $soundName');

    // Find the sound by name
    final soundIndex = _availableSounds.indexWhere((s) => s.name == soundName);
    if (soundIndex == -1) {
      _debugLog('Sound not found: $soundName');
      return;
    }

    final sound = _availableSounds[soundIndex];

    // Toggle the active state
    sound.isActive = !sound.isActive;
    _debugLog(
        'Sound $soundName is now ${sound.isActive ? "active" : "inactive"}');

    try {
      if (sound.isActive) {
        // When toggling on, immediately play the sound
        _debugLog('▶️ Starting playback for newly activated sound: $soundName');

        // Stop and dispose existing player if any
        if (sound.player != null) {
          await sound.player!.stop();
          await sound.player!.dispose();
        }

        // Create a new player
        sound.player = AudioPlayer();

        // Attempt to load and play the audio
        try {
          // First try with just the path
          await sound.player!.setAsset(sound.assetPath);
        } catch (e) {
          _debugLog('Error loading asset, trying with assets/ prefix: $e');
          // If that fails, try with "assets/" prefix
          await sound.player!.setAsset('assets/${sound.assetPath}');
        }

        // Configure looping
        await sound.player!.setLoopMode(LoopMode.all);

        // Set volume
        await sound.player!.setVolume(sound.volume);

        // Start playback immediately
        await sound.player!.play();
        _debugLog('Started playing $soundName with volume ${sound.volume}');

        // Update playing state
        _isPlaying = true;
      } else {
        // When toggling off, stop and clean up the player
        _debugLog('⏹️ Stopping playback for deactivated sound: $soundName');

        if (sound.player != null) {
          await sound.player!.stop();
          await sound.player!.dispose();
          sound.player = null;
        }

        // Check if any sounds are still active and playing
        bool anyStillPlaying = false;
        for (final s in _availableSounds) {
          if (s.isActive && s.player != null && s.player!.playing) {
            anyStillPlaying = true;
            break;
          }
        }

        // Update playing state
        _isPlaying = anyStillPlaying;
      }
    } catch (e) {
      _debugLog('❌ Error in toggleSound for $soundName: $e');
      // Revert the active state on error
      sound.isActive = !sound.isActive;
    }

    // Always notify listeners when done
    notifyListeners();
  }

  // Set volume for a specific sound
  Future<void> setSoundVolume(String soundName, double volume) async {
    final soundIndex = _availableSounds.indexWhere((s) => s.name == soundName);
    if (soundIndex == -1) return;

    final sound = _availableSounds[soundIndex];
    sound.volume = volume;

    // Update the volume for active player
    if (sound.isActive && sound.player != null) {
      await sound.player!.setVolume(volume);
      _debugLog('Updated volume for $soundName to $volume');
    }

    notifyListeners();
  }

  // Play all active sounds
  Future<void> playAllActiveSounds() async {
    _debugLog('Playing all active sounds');

    try {
      // First clean up any inactive sounds
      for (final sound in _availableSounds.where(
        (s) => !s.isActive && s.player != null,
      )) {
        await sound.player!.stop();
        await sound.player!.dispose();
        sound.player = null;
      }

      // Then play all active sounds
      for (final sound in _availableSounds.where((s) => s.isActive)) {
        if (sound.player == null) {
          // Create a new player for this sound
          sound.player = AudioPlayer();

          try {
            await sound.player!.setAsset(sound.assetPath);
          } catch (e) {
            _debugLog(
              'Error loading asset directly, trying with assets/ prefix: $e',
            );
            await sound.player!.setAsset('assets/${sound.assetPath}');
          }

          await sound.player!.setLoopMode(LoopMode.all);
          await sound.player!.setVolume(sound.volume);
          await sound.player!.play();

          _debugLog('Created and started new player for ${sound.name}');
        } else if (!sound.player!.playing) {
          // Resume existing players that aren't playing
          await sound.player!.play();
          _debugLog('Resumed ${sound.name}');
        }
      }

      // Check the actual playing state
      updatePlayingState();
    } catch (e) {
      _debugLog('Error in playAllActiveSounds: $e');
      // Check actual state after error
      updatePlayingState();
    }

    notifyListeners();
  }

  // Manually set the playing state (for forcing UI updates)
  void setPlayingState(bool playing) {
    _isPlaying = playing;
    _debugLog('🔄 Manually set playing state to $_isPlaying');
    notifyListeners();
  }

  // Pause all sounds
  Future<void> pauseAllSounds() async {
    _debugLog('🔴 PAUSING ALL SOUNDS');

    try {
      // Immediately update the playing state to update UI
      _isPlaying = false;
      notifyListeners();

      // Store names of all active sounds before pausing
      _activeSoundsBeforePause =
          _availableSounds.where((s) => s.isActive).map((s) => s.name).toList();

      _debugLog('Saved active sounds before pause: $_activeSoundsBeforePause');

      // Pause all players
      for (final sound in _availableSounds.where((s) => s.player != null)) {
        await sound.player!.pause();
        _debugLog('Paused ${sound.name}');
      }
    } catch (e) {
      _debugLog('Error in pauseAllSounds: $e');
    }
  }

  // Resume all active sounds
  Future<void> resumeAllSounds() async {
    _debugLog('🟢 RESUMING ALL SOUNDS');

    // Immediately update the playing state to update UI
    _isPlaying = true;
    notifyListeners();

    try {
      // Get the list of sounds to resume - either previously active sounds or currently active sounds
      List<String> soundsToResume = _activeSoundsBeforePause.isNotEmpty
          ? _activeSoundsBeforePause
          : _availableSounds
              .where((s) => s.isActive)
              .map((s) => s.name)
              .toList();

      _debugLog('Attempting to resume sounds: $soundsToResume');

      // Resume each sound
      for (final soundName in soundsToResume) {
        final soundIndex =
            _availableSounds.indexWhere((s) => s.name == soundName);
        if (soundIndex >= 0) {
          final sound = _availableSounds[soundIndex];

          // Make sure the sound is marked as active
          sound.isActive = true;

          if (sound.player == null) {
            // Create a new player
            sound.player = AudioPlayer();

            try {
              await sound.player!.setAsset(sound.assetPath);
            } catch (e) {
              _debugLog('Error loading asset, trying with assets/ prefix: $e');
              await sound.player!.setAsset('assets/${sound.assetPath}');
            }

            await sound.player!.setLoopMode(LoopMode.all);
            await sound.player!.setVolume(sound.volume);
            await sound.player!.play();
            _debugLog('Created new player for ${sound.name}');
          } else {
            // Resume existing player
            await sound.player!.setVolume(sound.volume);
            await sound.player!.play();
            _debugLog('Resumed existing player for ${sound.name}');
          }
        }
      }

      // Clear the stored list after resuming
      _activeSoundsBeforePause = [];
    } catch (e) {
      _debugLog('Error in resumeAllSounds: $e');

      // Check if any sounds are actually playing
      bool anyPlaying = false;
      for (final sound in _availableSounds) {
        if (sound.isActive && sound.player != null && sound.player!.playing) {
          anyPlaying = true;
          break;
        }
      }

      // Update state based on actual playing status
      if (_isPlaying != anyPlaying) {
        _isPlaying = anyPlaying;
        notifyListeners();
      }
    }
  }

  // Stop all sounds
  Future<void> stopAllSounds() async {
    _debugLog('Stopping all sounds');

    try {
      // First update the state to prevent UI issues
      _isPlaying = false;
      notifyListeners();

      // Then stop each sound individually with error handling
      for (final sound in _availableSounds) {
        try {
          if (sound.player != null) {
            await sound.player!.stop().timeout(
              Duration(milliseconds: 500),
              onTimeout: () {
                _debugLog('Timeout stopping player for ${sound.name}');
                return;
              },
            );

            await sound.player!.dispose().timeout(
              Duration(milliseconds: 500),
              onTimeout: () {
                _debugLog('Timeout disposing player for ${sound.name}');
                return;
              },
            );

            sound.player = null;
          }
          sound.isActive = false;
        } catch (e) {
          _debugLog('Error stopping sound ${sound.name}: $e');
          // Continue with other sounds even if one fails
          sound.isActive = false;
          sound.player = null;
        }
      }

      // Clear the stored active sounds list since we're explicitly stopping all sounds
      _activeSoundsBeforePause = [];

      cancelTimer();

      // Notify listeners again to ensure UI is updated
      notifyListeners();
    } catch (e) {
      _debugLog('Error in stopAllSounds: $e');

      // Emergency fallback - set all sounds to inactive
      for (final sound in _availableSounds) {
        sound.isActive = false;
        try {
          if (sound.player != null) {
            sound.player = null;
          }
        } catch (_) {
          // Ignore errors in the emergency fallback
        }
      }

      _isPlaying = false;
      notifyListeners();
    }
  }

  // Save current configuration as a preset
  Future<void> savePreset(String presetName) async {
    _debugLog('Saving preset: $presetName');

    // Create a deep copy of current sound states
    final soundsCopy = _availableSounds
        .map(
          (sound) => ZenAudioSound(
            name: sound.name,
            assetPath: sound.assetPath,
            iconPath: sound.iconPath,
            volume: sound.volume,
            isActive: sound.isActive,
          ),
        )
        .toList();

    final preset = ZenAudioPreset(name: presetName, sounds: soundsCopy);

    _presets.add(preset);
    await savePresets();
    notifyListeners();
  }

  // Load a preset
  Future<void> loadPreset(String presetName) async {
    _debugLog('Loading preset: $presetName');

    final presetIndex = _presets.indexWhere((p) => p.name == presetName);
    if (presetIndex == -1) return;

    // First stop all current sounds
    await stopAllSounds();

    // Apply preset configuration
    final preset = _presets[presetIndex];
    for (final presetSound in preset.sounds) {
      final soundIndex = _availableSounds.indexWhere(
        (s) => s.name == presetSound.name,
      );
      if (soundIndex != -1) {
        _availableSounds[soundIndex].volume = presetSound.volume;
        _availableSounds[soundIndex].isActive = presetSound.isActive;
      }
    }

    // Play all active sounds from the preset
    await playAllActiveSounds();
  }

  // Delete a preset
  Future<void> deletePreset(String presetName) async {
    _debugLog('Deleting preset: $presetName');

    _presets.removeWhere((p) => p.name == presetName);
    await savePresets();
    notifyListeners();
  }

  // Set a timer for auto-stopping sounds
  void setTimer(int durationMinutes) {
    _debugLog('Setting timer for $durationMinutes minutes');

    try {
      // Cancel any existing timer first
      cancelTimer();

      if (durationMinutes <= 0) {
        _debugLog('Timer duration is zero or negative, no timer will be set');
        return;
      }

      _timerDurationMinutes = durationMinutes;

      // Use Future.delayed instead of Timer for better error handling
      _zenTimer = Timer(Duration(minutes: durationMinutes), () {
        try {
          _debugLog('Timer completed, stopping all sounds');
          stopAllSounds();
          _timerDurationMinutes = 0;
          notifyListeners();
        } catch (e) {
          _debugLog('Error in timer completion callback: $e');
          // Attempt emergency sound stop
          _isPlaying = false;
          _timerDurationMinutes = 0;
          for (final sound in _availableSounds) {
            sound.isActive = false;
          }
          notifyListeners();
        }
      });

      notifyListeners();
    } catch (e) {
      _debugLog('Error setting timer: $e');
      // Reset timer state in case of error
      _timerDurationMinutes = 0;
      _zenTimer = null;
      notifyListeners();
    }
  }

  // Cancel the current timer
  void cancelTimer() {
    try {
      if (_zenTimer != null) {
        _debugLog('Cancelling timer');
        _zenTimer!.cancel();
        _zenTimer = null;
        _timerDurationMinutes = 0;
      }

      notifyListeners();
    } catch (e) {
      _debugLog('Error cancelling timer: $e');
      // Reset timer variables even if cancellation fails
      _zenTimer = null;
      _timerDurationMinutes = 0;
      notifyListeners();
    }
  }

  // Clean up resources
  Future<void> dispose() async {
    _debugLog('Disposing zen audio service');

    await stopAllSounds();
    cancelTimer();
  }
}
