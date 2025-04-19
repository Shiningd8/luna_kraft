import 'package:flutter/material.dart';
import 'audio_service.dart';
import 'zen_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  final AudioService _audioService = AudioService();
  final ZenAudioService _zenAudioService = ZenAudioService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isMusicEnabled = true;
  bool _isInitialized = false;
  bool _lowPerformanceMode = false;
  static const String _lowPerformanceModeKey = 'low_performance_mode';
  static const String _backgroundSelectionKey = 'background_selection';
  String _selectedBackground = 'backgroundanimation.json'; // Default background

  // Singleton constructor
  factory AppState() {
    return _instance;
  }

  AppState._internal() {
    _loadPerformancePreference();
    _loadBackgroundPreference();
    // Listen for auth state changes to reload preferences
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadBackgroundPreference();
      }
    });
  }

  // Get the audio service instance
  AudioService get audioService => _audioService;

  // Get the zen audio service instance
  ZenAudioService get zenAudioService => _zenAudioService;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isInitialized => _isInitialized;
  bool get lowPerformanceMode => _lowPerformanceMode;
  String get selectedBackground => _selectedBackground;

  // Available background options
  List<Map<String, String>> get backgroundOptions => [
        {'name': 'Default', 'file': 'backgroundanimation.json'},
        {'name': 'Hills', 'file': 'hills.json'},
        {'name': 'Ocean', 'file': 'ocean.json'},
        {'name': 'Rainforest', 'file': 'rainforest.json'},
        {'name': 'Valley', 'file': 'valley.json'},
        {'name': 'Windmill', 'file': 'windmill.json'},
      ];

  // Get the current user's background selection key
  String get _userBackgroundKey {
    final user = _auth.currentUser;
    return user != null
        ? '${_backgroundSelectionKey}_${user.uid}'
        : _backgroundSelectionKey;
  }

  // Load performance mode preference from SharedPreferences
  Future<void> _loadPerformancePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lowPerformanceMode = prefs.getBool(_lowPerformanceModeKey) ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading performance preferences: $e');
    }
  }

  // Load background preference from SharedPreferences
  Future<void> _loadBackgroundPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedBackground =
          prefs.getString(_userBackgroundKey) ?? 'backgroundanimation.json';
      notifyListeners();
    } catch (e) {
      print('Error loading background preference: $e');
    }
  }

  // Set background and persist the setting
  Future<void> setBackground(String backgroundFile) async {
    if (_selectedBackground == backgroundFile) return;

    _selectedBackground = backgroundFile;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userBackgroundKey, backgroundFile);
    } catch (e) {
      print('Error saving background preference: $e');
    }
  }

  // Set performance mode and persist the setting
  Future<void> setLowPerformanceMode(bool value) async {
    if (_lowPerformanceMode == value) return;

    _lowPerformanceMode = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lowPerformanceModeKey, value);
    } catch (e) {
      print('Error saving performance preference: $e');
    }
  }

  // Initialize app state services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _audioService.initialize();
      await _zenAudioService.initialize();
      await _loadPerformancePreference();
      await _loadBackgroundPreference();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing app state: $e');
    }
  }

  // Toggle music and notify listeners
  Future<void> toggleMusic() async {
    if (!_isInitialized) {
      await initialize();
    }

    _isMusicEnabled = !_isMusicEnabled;
    if (_isMusicEnabled) {
      await _audioService.playFromStart();
    } else {
      await _audioService.pause();
    }
    notifyListeners();
  }

  // Clean up resources
  Future<void> cleanup() async {
    await _audioService.dispose();
    await _zenAudioService.dispose();
    _isInitialized = false;
    notifyListeners();
  }
}
