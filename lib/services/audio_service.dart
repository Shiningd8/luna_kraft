import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// Implementation that doesn't use external audio packages yet
class AudioService {
  static final AudioService _instance = AudioService._internal();
  AudioPlayer? _player;
  bool _isInitialized = false;
  bool _isMusicEnabled = true;
  bool _hasError = false;
  String _lastError = '';
  bool _needsUserInteraction = true;
  bool _isWeb = false;
  bool _isInitializing = false;

  // Debug flag - set to true for verbose logging
  final bool _debug = true;

  // Getter for the current music state
  bool get isMusicEnabled => _isMusicEnabled;

  // Getter for last error
  String get lastError => _lastError;

  // Singleton constructor
  factory AudioService() {
    return _instance;
  }

  AudioService._internal() {
    _isWeb = kIsWeb;
    _debugLog(
        'AudioService initialized on ${_isWeb ? 'web' : 'native'} platform');
  }

  // Helper method for debug logging
  void _debugLog(String message) {
    if (_debug) {
      print('🎵 AudioService: $message');
    }
  }

  // Helper to set error state
  void _setError(String message) {
    _lastError = message;
    _debugLog('ERROR: $message');
    _hasError = true;
  }

  // Initialize the audio player with the background music
  Future<void> initialize() async {
    if (_isInitialized || _hasError || _isInitializing) return;

    _isInitializing = true;
    _debugLog('Initializing audio service');

    try {
      // Add a delay for web initialization
      if (_isWeb) {
        await Future.delayed(Duration(seconds: 1));
      }

      if (_player == null) {
        _player = AudioPlayer();
        _debugLog('Created new AudioPlayer instance');
      }

      // Set the audio source
      _debugLog('Setting audio source to background_music.mp3');
      await _player!.setSource(AssetSource('audio/background_music.mp3'));
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(0.7);

      _isInitialized = true;
      _debugLog('AudioService initialized successfully');
    } catch (e) {
      _setError('Error initializing AudioService: $e');
    } finally {
      _isInitializing = false;
    }
  }

  // Play the background music
  Future<void> play() async {
    if (_hasError) {
      _debugLog('Cannot play: service has error');
      return;
    }

    if (!_isInitialized) {
      _debugLog('Player not initialized, initializing first');
      await initialize();
    }

    if (_isMusicEnabled) {
      try {
        _debugLog('Attempting to play music');
        // Add a small delay before playing
        await Future.delayed(Duration(milliseconds: 100));
        await _player?.resume();
        _debugLog('Background music started successfully');
      } catch (e) {
        _setError('Error playing background music: $e');
      }
    } else {
      _debugLog('Music is disabled, not playing');
    }
  }

  // Play from the beginning
  Future<void> playFromStart() async {
    if (!_isInitialized) {
      _debugLog('Not initialized, attempting initialization...');
      await initialize();
    }

    if (!_isInitialized) {
      _debugLog('Failed to initialize, cannot play');
      return;
    }

    try {
      _debugLog('Starting playback from beginning');
      await _player?.stop();
      // Add a longer delay for web
      await Future.delayed(Duration(milliseconds: _isWeb ? 1000 : 500));
      await _player?.resume();
      _debugLog('Playback started successfully');
    } catch (e) {
      _setError('Error playing from start: $e');
    }
  }

  // Pause the background music
  Future<void> pause() async {
    if (_hasError || !_isInitialized) return;

    try {
      await _player?.pause();
      _debugLog('Background music paused');
    } catch (e) {
      _setError('Error pausing background music: $e');
    }
  }

  // Toggle music on/off
  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;

    if (_isMusicEnabled) {
      await play();
    } else {
      await pause();
    }
  }

  // Set volume level (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (_hasError || !_isInitialized) return;

    try {
      _debugLog('Setting volume to $volume');
      await _player?.setVolume(volume);
      _debugLog('Volume set successfully');
    } catch (e) {
      _setError('Error setting volume: $e');
    }
  }

  // Clean up resources
  Future<void> dispose() async {
    if (_isInitialized && !_hasError) {
      try {
        _debugLog('Disposing audio player');
        await _player?.stop();
        await _player?.dispose();
        _isInitialized = false;
        _debugLog('Disposed successfully');
      } catch (e) {
        _setError('Error disposing: $e');
      }
    }
    _player = null;
  }

  // Handle user interaction for web autoplay
  Future<void> handleUserInteraction() async {
    if (!_isInitialized) {
      _debugLog('Cannot play: service not initialized');
      return;
    }

    try {
      _needsUserInteraction = false;
      _debugLog('User interaction detected, attempting to play');
      // Add a delay after user interaction
      await Future.delayed(Duration(milliseconds: 500));
      await playFromStart();
      _debugLog('Background music started from beginning');
    } catch (e) {
      _setError('Failed to handle user interaction: $e');
    }
  }

  // Get diagnostic information
  Map<String, dynamic> getDiagnostics() {
    return {
      'isInitialized': _isInitialized,
      'isPlaying': _player?.state == PlayerState.playing,
      'volume': _player?.volume,
      'platform': _isWeb ? 'web' : 'native',
    };
  }
}
