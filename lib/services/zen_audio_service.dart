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

  // Helper method to safely dispose of an audio player
  Future<void> _safeDisposePlayer(AudioPlayer? player, String soundName) async {
    if (player != null) {
      try {
        await player.stop();
        await player.dispose();
        _debugLog('Successfully disposed player for $soundName');
      } catch (e) {
        _debugLog('Error disposing player for $soundName: $e');
      }
    }
  }

  // Helper method to safely create and initialize an audio player
  Future<AudioPlayer?> _createAndInitializePlayer(
      String assetPath, String soundName) async {
    try {
      _debugLog('🎵 Creating player for $soundName with path $assetPath');
      final player = AudioPlayer();

      // Set up error handling
      player.playbackEventStream.listen(
        (event) => _debugLog('Playback event for $soundName: $event'),
        onError: (Object e, StackTrace st) {
          _debugLog('Error in playback for $soundName: $e');
        },
      );

      // Make sure path is correctly formatted for just_audio
      String audioPath = assetPath;

      _debugLog('🔍 Setting source for $soundName: $audioPath');
      await player.setAsset(audioPath);
      _debugLog('✅ Source set successfully for $soundName');

      await player.setLoopMode(LoopMode.all);

      _debugLog('🎧 Successfully initialized player for $soundName');
      return player;
    } catch (e) {
      _debugLog('❌ Error creating player for $soundName: $e');
      return null;
    }
  }

  // Initialize the zen audio service with available sounds
  Future<void> initialize() async {
    if (_isInitialized) return;

    _debugLog('Initializing zen audio service');

    // Define available sounds with correct asset paths
    _availableSounds = [
      ZenAudioSound(
        name: 'Rain',
        assetPath: 'assets/audio/zen/rain.mp3',
        iconPath: 'assets/icons/zen/rain.png',
      ),
      ZenAudioSound(
        name: 'Thunder',
        assetPath: 'assets/audio/zen/thunder.mp3',
        iconPath: 'assets/icons/zen/thunder.png',
      ),
      ZenAudioSound(
        name: 'Forest',
        assetPath: 'assets/audio/zen/forest.mp3',
        iconPath: 'assets/icons/zen/forest.png',
      ),
      ZenAudioSound(
        name: 'Ocean',
        assetPath: 'assets/audio/zen/ocean.mp3',
        iconPath: 'assets/icons/zen/ocean.png',
      ),
      ZenAudioSound(
        name: 'Fireplace',
        assetPath: 'assets/audio/zen/fireplace.mp3',
        iconPath: 'assets/icons/zen/fire.png',
      ),
      ZenAudioSound(
        name: 'Wind',
        assetPath: 'assets/audio/zen/wind.mp3',
        iconPath: 'assets/icons/zen/wind.png',
      ),
      ZenAudioSound(
        name: 'Birds',
        assetPath: 'assets/audio/zen/birds.mp3',
        iconPath: 'assets/icons/zen/birds.png',
      ),
      ZenAudioSound(
        name: 'Stream',
        assetPath: 'assets/audio/zen/stream.mp3',
        iconPath: 'assets/icons/zen/stream.png',
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

  // Helper method to log the state of all active sounds for debugging
  void _logActiveSoundsState() {
    if (!_debug) return;

    _debugLog('=== ACTIVE SOUNDS STATE ===');
    int totalActive = 0;
    int totalPlaying = 0;

    for (final sound in _availableSounds) {
      if (sound.isActive) {
        totalActive++;
        bool isPlaying = sound.player != null && sound.player!.playing;
        if (isPlaying) totalPlaying++;
        _debugLog(
            '${sound.name}: active=${sound.isActive}, playing=$isPlaying, volume=${sound.volume}');
      }
    }

    _debugLog('Total active: $totalActive, Total playing: $totalPlaying');
    _debugLog('=========================');
  }

  // Toggle a sound on or off
  Future<void> toggleSound(String soundName) async {
    _debugLog('🔄 Toggling sound: $soundName');

    final soundIndex = _availableSounds.indexWhere((s) => s.name == soundName);
    if (soundIndex == -1) {
      _debugLog('Sound not found: $soundName');
      return;
    }

    final sound = _availableSounds[soundIndex];

    // Toggle the active state
    sound.isActive = !sound.isActive;

    try {
      if (sound.isActive) {
        // When toggling ON, create and play the sound
        _debugLog('▶️ Starting playback for newly activated sound: $soundName');

        // Always create a new player instance for each sound
        // First dispose of any existing player to avoid memory leaks
        if (sound.player != null) {
          await _safeDisposePlayer(sound.player, soundName);
          sound.player = null;
        }

        // Create a completely new player for this sound
        sound.player =
            await _createAndInitializePlayer(sound.assetPath, soundName);

        if (sound.player != null) {
          // Set volume before playing
          await sound.player!.setVolume(sound.volume);

          // Start playing
          await sound.player!.play();
          _debugLog('Started playing $soundName with volume ${sound.volume}');
        } else {
          _debugLog('❌ Failed to create player for $soundName');
          sound.isActive = false;
        }
      } else {
        // When toggling OFF, stop and cleanup
        _debugLog('⏹️ Stopping playback for deactivated sound: $soundName');

        if (sound.player != null) {
          await _safeDisposePlayer(sound.player, soundName);
          sound.player = null;
          _debugLog('Stopped and disposed player for $soundName');
        }
      }

      // Check if any sounds are still active and playing
      bool anyActive =
          _availableSounds.any((s) => s.isActive && s.player != null);
      _isPlaying = anyActive;

      // Log the current state of all active sounds
      _logActiveSoundsState();
    } catch (e) {
      _debugLog('❌ Error in toggleSound for $soundName: $e');
      // Revert the active state in case of error
      sound.isActive = !sound.isActive;
    }

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
      try {
        await sound.player!.setVolume(volume);
        _debugLog('Updated volume for $soundName to $volume');
      } catch (e) {
        _debugLog('Error setting volume for $soundName: $e');
      }
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
        await _safeDisposePlayer(sound.player, sound.name);
        sound.player = null;
      }

      // Then play all active sounds
      for (final sound in _availableSounds.where((s) => s.isActive)) {
        _debugLog('Creating new player for ${sound.name}');

        // Always create a fresh player for each sound
        if (sound.player != null) {
          await _safeDisposePlayer(sound.player, sound.name);
        }

        // Create a completely new player
        sound.player =
            await _createAndInitializePlayer(sound.assetPath, sound.name);

        if (sound.player != null) {
          // Set volume before playing
          await sound.player!.setVolume(sound.volume);

          // Start playing
          await sound.player!.play();
          _debugLog('Started playing ${sound.name}');
        } else {
          _debugLog('❌ Failed to create player for ${sound.name}');
        }
      }

      // Update playing state based on whether any sounds are active
      _isPlaying = _availableSounds.any((s) => s.isActive && s.player != null);

      // Log the current state of all active sounds
      _logActiveSoundsState();
    } catch (e) {
      _debugLog('Error in playAllActiveSounds: $e');
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

      // Stop all players (don't dispose them yet)
      for (final sound in _availableSounds.where((s) => s.player != null)) {
        try {
          await sound.player!.pause();
          _debugLog('Paused ${sound.name}');
        } catch (e) {
          _debugLog('Error pausing ${sound.name}: $e');
        }
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

          // Clean up existing player if any
          if (sound.player != null) {
            await _safeDisposePlayer(sound.player, sound.name);
          }

          // Create a completely new player
          sound.player =
              await _createAndInitializePlayer(sound.assetPath, sound.name);

          if (sound.player != null) {
            // Set volume before playing
            await sound.player!.setVolume(sound.volume);

            // Start playing
            await sound.player!.play();
            _debugLog('Started playing ${sound.name}');
          } else {
            _debugLog('❌ Failed to create player for ${sound.name}');
            sound.isActive = false;
          }
        }
      }

      // Clear the stored list after resuming
      _activeSoundsBeforePause = [];

      // Update playing state based on whether any sounds are active
      _isPlaying = _availableSounds.any((s) => s.isActive && s.player != null);

      // Log the current state of all active sounds
      _logActiveSoundsState();
    } catch (e) {
      _debugLog('Error in resumeAllSounds: $e');
      updatePlayingState();
    }
  }

  // Stop all sounds
  Future<void> stopAllSounds() async {
    _debugLog('Stopping all sounds');

    try {
      _isPlaying = false;
      notifyListeners();

      for (final sound in _availableSounds) {
        try {
          await _safeDisposePlayer(sound.player, sound.name);
          sound.player = null;
          sound.isActive = false;
        } catch (e) {
          _debugLog('Error stopping sound ${sound.name}: $e');
          sound.isActive = false;
          sound.player = null;
        }
      }

      _activeSoundsBeforePause = [];
      cancelTimer();
      notifyListeners();
    } catch (e) {
      _debugLog('Error in stopAllSounds: $e');
      for (final sound in _availableSounds) {
        sound.isActive = false;
        sound.player = null;
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
          // Attempt emergency sound stop with multiple fallbacks
          try {
            _isPlaying = false;
            notifyListeners();

            // First attempt - try to stop each sound individually
            for (final sound in _availableSounds) {
              try {
                sound.isActive = false;
                if (sound.player != null) {
                  sound.player!.stop();
                }
              } catch (soundError) {
                _debugLog('Error stopping individual sound: $soundError');
              }
            }

            // Second attempt - reset all state variables
            _timerDurationMinutes = 0;
            notifyListeners();
          } catch (emergencyError) {
            _debugLog('Emergency error handling failed: $emergencyError');
          }
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
