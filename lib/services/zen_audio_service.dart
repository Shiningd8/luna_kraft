import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '/auth/firebase_auth/auth_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/utils/subscription_util.dart';

class ZenAudioSound {
  final String name;
  final String assetPath;
  final String iconPath;
  double volume;
  bool isActive;
  AudioPlayer? player;
  final bool isLocked;
  final int? unlockPrice;

  ZenAudioSound({
    required this.name,
    required this.assetPath,
    required this.iconPath,
    this.volume = 0.5,
    this.isActive = false,
    this.player,
    this.isLocked = false,
    this.unlockPrice,
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
  List<String> _unlockedSounds = []; // Store unlocked sounds

  // Keep track of which sounds were active when paused
  List<String> _activeSoundsBeforePause = [];

  // Debug flag - set to true for verbose logging
  final bool _debug = true;

  // Keys for storing unlocked sounds
  static const String _unlockedSoundsKey = 'unlocked_zen_sounds';

  // Getters
  List<ZenAudioSound> get availableSounds => _availableSounds;
  List<ZenAudioPreset> get presets => _presets;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  int get timerDurationMinutes => _timerDurationMinutes;
  List<String> get unlockedSounds => _unlockedSounds;

  // Singleton constructor
  factory ZenAudioService() {
    return _instance;
  }

  ZenAudioService._internal() {
    _debugLog('ZenAudioService initialized');
    _loadUnlockedSounds();
    
    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadUnlockedSounds();
      }
    });
  }

  // Helper method for debug logging
  void _debugLog(String message) {
    if (_debug) {
      print('🧘 ZenAudioService: $message');
    }
  }

  // Get the current user's unlocked sounds key for SharedPreferences (fallback)
  String get _userUnlockedSoundsKey {
    final user = currentUserReference;
    return user != null ? '${_unlockedSoundsKey}_${user.id}' : _unlockedSoundsKey;
  }

  // Load unlocked sounds from Firestore (and fallback to SharedPreferences)
  Future<void> _loadUnlockedSounds() async {
    try {
      // First try to load from Firestore if user is logged in
      if (currentUserReference != null) {
        final userDoc = await currentUserReference!.get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          
          if (userData != null && userData.containsKey('unlocked_zen_sounds')) {
            final unlockedSoundsList = userData['unlocked_zen_sounds'] as List<dynamic>?;
            
            if (unlockedSoundsList != null) {
              _unlockedSounds = unlockedSoundsList.cast<String>();
              _debugLog('Loaded unlocked sounds from Firestore: $_unlockedSounds');
              notifyListeners();
              return;
            }
          }
        }
      }
      
      // Fallback to SharedPreferences if Firestore failed or user is not logged in
      final prefs = await SharedPreferences.getInstance();
      final savedUnlocked = prefs.getStringList(_userUnlockedSoundsKey);
      
      if (savedUnlocked != null) {
        _unlockedSounds = savedUnlocked;
        _debugLog('Loaded unlocked sounds from SharedPreferences: $_unlockedSounds');
      } else {
        // Default to empty list for new users
        _unlockedSounds = [];
        _debugLog('No unlocked sounds found, using empty list');
      }
      
      // If user is logged in, sync the unlocked sounds to Firestore
      if (currentUserReference != null && _unlockedSounds.isNotEmpty) {
        await currentUserReference!.update({
          'unlocked_zen_sounds': _unlockedSounds,
        });
        _debugLog('Synced unlocked sounds to Firestore');
      }
      
      notifyListeners();
    } catch (e) {
      _debugLog('Error loading unlocked sounds: $e');
    }
  }

  // Save unlocked sounds to both Firestore and SharedPreferences
  Future<void> _saveUnlockedSounds() async {
    try {
      // Save to Firestore if user is logged in
      if (currentUserReference != null) {
        await currentUserReference!.update({
          'unlocked_zen_sounds': _unlockedSounds,
        });
        _debugLog('Saved unlocked sounds to Firestore: $_unlockedSounds');
      }
      
      // Always save to SharedPreferences as a backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_userUnlockedSoundsKey, _unlockedSounds);
      _debugLog('Saved unlocked sounds to SharedPreferences: $_unlockedSounds');
    } catch (e) {
      _debugLog('Error saving unlocked sounds: $e');
    }
  }

  // Check if a sound is unlocked
  bool isSoundUnlocked(String soundName) {
    // First check if user has directly purchased this sound (permanent)
    if (_unlockedSounds.contains(soundName)) {
      _debugLog('Sound $soundName is permanently unlocked');
      return true;
    }
    
    // Then check if it's one of the premium sounds and user has premium subscription
    if ((soundName == 'Wind' || 
         soundName == 'Birds' || 
         soundName == 'Stream' || 
         soundName == 'Calm Night' || 
         soundName == 'Tranquil Horizons' || 
         soundName == 'Whisper of Snowfall') && 
        SubscriptionUtil.hasZenMode) {
      _debugLog('Sound $soundName is temporarily unlocked via premium subscription');
      return true; // Premium subscribers get temporary access to all sounds
    }
    
    // For non-premium sounds, they're unlocked by default
    if (soundName != 'Wind' && 
        soundName != 'Birds' && 
        soundName != 'Stream' && 
        soundName != 'Calm Night' && 
        soundName != 'Tranquil Horizons' && 
        soundName != 'Whisper of Snowfall') {
      _debugLog('Sound $soundName is a free sound (unlocked by default)');
      return true;
    }
    
    _debugLog('Sound $soundName is locked - requires purchase or subscription');
    return false;
  }

  // Get the price for a sound
  int getSoundPrice(String soundName) {
    switch (soundName) {
      case 'Wind':
        return 120;
      case 'Birds':
        return 150;
      case 'Stream':
        return 180;
      case 'Calm Night':
        return 200;
      case 'Tranquil Horizons':
        return 230;
      case 'Whisper of Snowfall':
        return 260;
      default:
        return 0; // All other sounds are free
    }
  }

  // Unlock a sound permanently (purchase with LunaCoins)
  Future<bool> unlockSound(String soundName) async {
    if (_unlockedSounds.contains(soundName)) {
      return true; // Already unlocked permanently
    }

    // Get current user
    final userRef = currentUserReference;
    if (userRef == null) {
      return false;
    }

    try {
      // Get the price
      final price = getSoundPrice(soundName);
      
      // Get user's current coins
      final userDoc = await UserRecord.getDocumentOnce(userRef);
      final currentCoins = userDoc.lunaCoins;
      
      // Check if user has enough coins
      if (currentCoins < price) {
        return false;
      }
      
      // Deduct coins using the correct field name
      await userRef.update({
        'luna_coins': FieldValue.increment(-price),
      });
      
      // Add to unlocked sounds in memory
      _unlockedSounds.add(soundName);
      
      // Save to both Firestore and SharedPreferences
      await _saveUnlockedSounds();
      
      // Update available sounds to reflect new unlock status
      _updateLockedSoundStatus();
      
      // Notify listeners
      notifyListeners();
      
      return true;
    } catch (e) {
      _debugLog('Error unlocking sound: $e');
      return false;
    }
  }

  // Update the locked status of all sounds
  void _updateLockedSoundStatus() {
    for (final sound in _availableSounds) {
      // Only update premium sounds
      if (['Wind', 'Birds', 'Stream', 'Calm Night', 'Tranquil Horizons', 'Whisper of Snowfall'].contains(sound.name)) {
        // A sound is unlocked if purchased with coins or user has premium
        bool isUnlocked = _unlockedSounds.contains(sound.name) || 
                         SubscriptionUtil.hasZenMode;
        
        // Since isLocked is final, we need to use reflection to modify it
        // This is a workaround for the immutable field
        try {
          final instance = sound as dynamic;
          instance.isLocked = !isUnlocked;
          _debugLog('Updated lock status for ${sound.name}: locked=${!isUnlocked}');
        } catch (e) {
          _debugLog('Error updating lock status for ${sound.name}: $e');
        }
      }
    }
  }

  // Public method to refresh sound lock status based on subscription changes
  void refreshSoundLockStatus() {
    _updateLockedSoundStatus();
    notifyListeners();
    _debugLog('Sound lock status refreshed based on subscription changes');
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

    // Load unlocked sounds first
    await _loadUnlockedSounds();

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
        isLocked: !isSoundUnlocked('Wind'),
        unlockPrice: 120,
      ),
      ZenAudioSound(
        name: 'Birds',
        assetPath: 'assets/audio/zen/birds.mp3',
        iconPath: 'assets/icons/zen/birds.png',
        isLocked: !isSoundUnlocked('Birds'),
        unlockPrice: 150,
      ),
      ZenAudioSound(
        name: 'Stream',
        assetPath: 'assets/audio/zen/stream.mp3',
        iconPath: 'assets/icons/zen/stream.png',
        isLocked: !isSoundUnlocked('Stream'),
        unlockPrice: 180,
      ),
      ZenAudioSound(
        name: 'Whispering Zen',
        assetPath: 'assets/audio/zen/music_whispering_zen.mp3',
        iconPath: 'assets/icons/zen/rain.png', // Using an existing icon
      ),
      ZenAudioSound(
        name: 'Calm Night',
        assetPath: 'assets/audio/zen/music_calm_night.mp3',
        iconPath: 'assets/icons/zen/ocean.png', // Using an existing icon
        isLocked: !isSoundUnlocked('Calm Night'),
        unlockPrice: 200,
      ),
      ZenAudioSound(
        name: 'Tranquil Horizons',
        assetPath: 'assets/audio/zen/music_tranquil_horizons.mp3',
        iconPath: 'assets/icons/zen/forest.png', // Using an existing icon
        isLocked: !isSoundUnlocked('Tranquil Horizons'),
        unlockPrice: 230,
      ),
      ZenAudioSound(
        name: 'Whisper of Snowfall',
        assetPath: 'assets/audio/zen/music_whisper_of_snowfall.mp3',
        iconPath: 'assets/icons/zen/wind.png', // Using an existing icon
        isLocked: !isSoundUnlocked('Whisper of Snowfall'),
        unlockPrice: 260,
      ),
    ];
    
    _debugLog('Sounds initialized with proper lock states:');
    for (final sound in _availableSounds) {
      if (['Wind', 'Birds', 'Stream', 'Calm Night', 'Tranquil Horizons', 'Whisper of Snowfall'].contains(sound.name)) {
        _debugLog('${sound.name}: isLocked=${sound.isLocked}, unlockPrice=${sound.unlockPrice}');
      }
    }

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
    
    // Check if the sound is locked
    if (sound.isLocked && !isSoundUnlocked(soundName)) {
      _debugLog('Attempted to toggle locked sound: $soundName');
      return; // Don't toggle locked sounds
    }

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
            await _createAndInitializePlayer(sound.assetPath, sound.name);

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

          // Skip locked sounds
          if (sound.isLocked && !isSoundUnlocked(soundName)) {
            _debugLog('Skipping locked sound: $soundName');
            continue;
          }

          // Only resume sounds that have been previously active
          if (sound.isActive) {
            try {
              // Check if we have a valid player first
              if (sound.player != null) {
                // Resume playback
                await sound.player!.play();
                _debugLog('Resumed playback for ${sound.name}');
              } else {
                // Create a new player if needed
                _debugLog(
                    'Creating new player for ${sound.name} because previous player was null');
                sound.player = await _createAndInitializePlayer(
                    sound.assetPath, sound.name);
                if (sound.player != null) {
                  await sound.player!.setVolume(sound.volume);
                  await sound.player!.play();
                  _debugLog('Started playing ${sound.name} with new player');
                } else {
                  _debugLog('❌ Failed to create player for ${sound.name}');
                }
              }
            } catch (e) {
              _debugLog('Error resuming ${sound.name}: $e');
            }
          }
        }
      }

      // Clear the stored active sounds to avoid duplicating them in future resumes
      _activeSoundsBeforePause = [];

      // Log the current state of all active sounds
      _logActiveSoundsState();
    } catch (e) {
      _debugLog('Error in resumeAllSounds: $e');
    }
  }

  // Stop all sounds completely
  Future<void> stopAllSounds() async {
    _debugLog('🛑 STOPPING ALL SOUNDS');

    try {
      // Immediately update the playing state to update UI
      _isPlaying = false;
      notifyListeners();

      // Force immediate stop of all sounds - add this first to immediately cut audio
      for (final sound in _availableSounds.where((s) => s.player != null)) {
        try {
          if (sound.player != null && sound.player!.playing) {
            await sound.player!.stop();
          }
        } catch (e) {
          _debugLog('Error stopping ${sound.name}: $e');
        }
      }

      // Stop and dispose all players
      for (final sound in _availableSounds.where((s) => s.player != null)) {
        try {
          await _safeDisposePlayer(sound.player, sound.name);
          sound.player = null;
          sound.isActive = false;
          _debugLog('Stopped and reset ${sound.name}');
        } catch (e) {
          _debugLog('Error stopping ${sound.name}: $e');
        }
      }

      // Ensure all sounds are marked as inactive
      for (final sound in _availableSounds) {
        sound.isActive = false;
      }

      // Clear the stored active sounds
      _activeSoundsBeforePause = [];

      // Force another check to make sure all players are truly disposed
      for (final sound in _availableSounds) {
        if (sound.player != null) {
          try {
            await sound.player!.stop();
            await sound.player!.dispose();
            sound.player = null;
            _debugLog('Forcefully stopped and disposed ${sound.name}');
          } catch (e) {
            _debugLog('Error in final dispose for ${sound.name}: $e');
          }
        }
      }

      // Log the current state
      _debugLog('All sounds stopped and reset');
    } catch (e) {
      _debugLog('Error in stopAllSounds: $e');
    }

    // Force another update to ensure UI is synced
    notifyListeners();
  }

  // Save the current mix as a preset
  Future<void> savePreset(String presetName) async {
    try {
      // Create a copy of current sound settings
      List<ZenAudioSound> presetSounds = [];
      for (final sound in _availableSounds) {
        if (sound.isActive) {
          presetSounds.add(ZenAudioSound(
            name: sound.name,
            assetPath: sound.assetPath,
            iconPath: sound.iconPath,
            volume: sound.volume,
            isActive: true,
          ));
        }
      }

      // Create the preset
      final preset = ZenAudioPreset(
        name: presetName,
        sounds: presetSounds,
      );

      // Check if a preset with this name already exists
      final existingIndex =
          _presets.indexWhere((p) => p.name == presetName);
      if (existingIndex >= 0) {
        // Replace existing preset
        _presets[existingIndex] = preset;
      } else {
        // Add new preset
        _presets.add(preset);
      }

      // Save to persistent storage
      await savePresets();

      _debugLog('Saved preset: $presetName with ${presetSounds.length} sounds');
    } catch (e) {
      _debugLog('Error saving preset: $e');
    }

    notifyListeners();
  }

  // Load a saved preset
  Future<void> loadPreset(String presetName) async {
    try {
      // Find the preset
      final presetIndex = _presets.indexWhere((p) => p.name == presetName);
      if (presetIndex < 0) {
        _debugLog('Preset not found: $presetName');
        return;
      }

      final preset = _presets[presetIndex];

      // Stop all current sounds
      await stopAllSounds();

      // Apply the preset settings
      for (final presetSound in preset.sounds) {
        // Find matching sound in available sounds
        final soundIndex = _availableSounds
            .indexWhere((s) => s.name == presetSound.name);
        if (soundIndex >= 0) {
          final sound = _availableSounds[soundIndex];
          
          // Skip locked sounds
          if (sound.isLocked && !isSoundUnlocked(sound.name)) {
            _debugLog('Skipping locked sound in preset: ${sound.name}');
            continue;
          }
          
          // Set volume and active state
          sound.volume = presetSound.volume;
          sound.isActive = true;

          // Create and play the sound
          sound.player =
              await _createAndInitializePlayer(sound.assetPath, sound.name);
          if (sound.player != null) {
            await sound.player!.setVolume(sound.volume);
            await sound.player!.play();
          }
        }
      }

      // Update playing state
      _isPlaying = true;

      _debugLog('Loaded preset: $presetName');
    } catch (e) {
      _debugLog('Error loading preset: $e');
    }

    notifyListeners();
  }

  // Delete a saved preset
  Future<void> deletePreset(String presetName) async {
    try {
      // Remove the preset
      _presets.removeWhere((p) => p.name == presetName);

      // Save to persistent storage
      await savePresets();

      _debugLog('Deleted preset: $presetName');
    } catch (e) {
      _debugLog('Error deleting preset: $e');
    }

    notifyListeners();
  }

  // Set a timer to stop sounds after a specified time
  void setTimer(int minutes) {
    // Cancel any existing timer
    if (_zenTimer != null) {
      _zenTimer!.cancel();
      _zenTimer = null;
    }

    if (minutes <= 0) {
      _timerDurationMinutes = 0;
      notifyListeners();
      return;
    }

    _timerDurationMinutes = minutes;
    _debugLog('Setting timer for $minutes minutes');

    // Create a new timer
    _zenTimer = Timer(Duration(minutes: minutes), () {
      stopAllSounds();
      _timerDurationMinutes = 0;
      notifyListeners();
    });

    notifyListeners();
  }

  // Cancel the current timer
  void cancelTimer() {
    if (_zenTimer != null) {
      _zenTimer!.cancel();
      _zenTimer = null;
    }
    _timerDurationMinutes = 0;
    notifyListeners();
  }

  // Handle application exit
  Future<void> dispose() async {
    try {
      // Cancel any timers
      _zenTimer?.cancel();

      // Stop all sounds
      for (final sound in _availableSounds.where((s) => s.player != null)) {
        await _safeDisposePlayer(sound.player, sound.name);
      }

      _debugLog('Successfully disposed ZenAudioService');
    } catch (e) {
      _debugLog('Error disposing ZenAudioService: $e');
    }
  }
}
