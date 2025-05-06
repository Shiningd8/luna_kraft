import 'package:flutter/material.dart';
import 'zen_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
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

  // Get the zen audio service instance
  ZenAudioService get zenAudioService => _zenAudioService;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isInitialized => _isInitialized;
  bool get lowPerformanceMode => _lowPerformanceMode;
  String get selectedBackground => _selectedBackground;

  // Available background options
  List<Map<String, String>> get backgroundOptions {
    print('Accessing backgroundOptions - returning Lottie files only');
    return [
      {'name': 'Default', 'file': 'backgroundanimation.json'},
      {'name': 'Hills', 'file': 'hills.json'},
      {'name': 'Ocean', 'file': 'ocean.json'},
      {'name': 'Rainforest', 'file': 'rainforest.json'},
      {'name': 'Gradient', 'file': 'gradient.json'},
      {'name': 'Night Hill', 'file': 'nighthill.json'},
      {'name': 'Night Lake', 'file': 'nightlake.json'},
    ];
  }

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
      final savedBackground =
          prefs.getString(_userBackgroundKey) ?? 'backgroundanimation.json';

      // Migrate users from removed backgrounds to default
      if (savedBackground == 'valley.json' ||
          savedBackground == 'windmill.json') {
        _selectedBackground = 'backgroundanimation.json';
        // Save the updated preference
        await prefs.setString(_userBackgroundKey, _selectedBackground);
        print('Migrated user from removed background to default');
      }
      // Migrate from old file names to new ones
      else if (savedBackground == 'night_hill.json') {
        _selectedBackground = 'nighthill.json';
        await prefs.setString(_userBackgroundKey, _selectedBackground);
        print('Migrated user from night_hill.json to nighthill.json');
      } else if (savedBackground == 'night_lake.json') {
        _selectedBackground = 'nightlake.json';
        await prefs.setString(_userBackgroundKey, _selectedBackground);
        print('Migrated user from night_lake.json to nightlake.json');
      } else {
        _selectedBackground = savedBackground;
      }

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
      await _zenAudioService.initialize();
      await _loadPerformancePreference();
      await _loadBackgroundPreference();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing app state: $e');
    }
  }

  // Clean up resources
  Future<void> cleanup() async {
    await _zenAudioService.dispose();
    _isInitialized = false;
    notifyListeners();
  }

  // Force reinitialize to make sure changes are applied
  Future<void> forceReinitialize() async {
    print('Force reinitializing AppState');
    try {
      await _loadBackgroundPreference();
      notifyListeners();
      print('AppState reinitialized');
    } catch (e) {
      print('Error reinitializing AppState: $e');
    }
  }
}
