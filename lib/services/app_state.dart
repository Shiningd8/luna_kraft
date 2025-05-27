import 'package:flutter/material.dart';
import 'zen_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  final ZenAudioService _zenAudioService = ZenAudioService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isMusicEnabled = true;
  bool _isInitialized = false;
  bool _lowPerformanceMode = false;
  static const String _lowPerformanceModeKey = 'low_performance_mode';
  static const String _backgroundSelectionKey = 'background_selection';
  static const String _unlockedBackgroundsKey = 'unlocked_backgrounds';
  String _selectedBackground = 'backgroundanimation.json'; // Default background
  List<String> _unlockedBackgrounds = []; // User's unlocked backgrounds

  // Singleton constructor
  factory AppState() {
    return _instance;
  }

  AppState._internal() {
    _loadPerformancePreference();
    _loadBackgroundPreference();
    _loadUnlockedBackgrounds();
    // Listen for auth state changes to reload preferences
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadBackgroundPreference();
        _loadUnlockedBackgrounds();
      }
    });
  }

  // Get the zen audio service instance
  ZenAudioService get zenAudioService => _zenAudioService;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isInitialized => _isInitialized;
  bool get lowPerformanceMode => _lowPerformanceMode;
  String get selectedBackground => _selectedBackground;
  List<String> get unlockedBackgrounds => _unlockedBackgrounds;

  // Check if a background is unlocked
  bool isBackgroundUnlocked(String backgroundFile) {
    // Default and gradient backgrounds are always unlocked
    if (backgroundFile == 'backgroundanimation.json' || 
        backgroundFile == 'gradient.json') {
      return true;
    }
    
    return _unlockedBackgrounds.contains(backgroundFile);
  }

  // Get the price for a background (progressively increasing)
  int getBackgroundPrice(String backgroundFile) {
    // Base price is 100
    final basePrice = 100;
    // Find the index of the background in the options list
    final index = backgroundOptions
        .indexWhere((bg) => bg['file'] == backgroundFile);
    
    if (index <= 1) {
      return 0; // Default and gradient are free
    }
    
    // Each subsequent background costs 20 more coins
    return basePrice + ((index - 2) * 20);
  }

  // Unlock a background
  Future<bool> unlockBackground(String backgroundFile) async {
    if (isBackgroundUnlocked(backgroundFile)) {
      return true; // Already unlocked
    }

    // Get current user
    final userRef = currentUserReference;
    if (userRef == null) {
      return false;
    }

    try {
      // Get the price
      final price = getBackgroundPrice(backgroundFile);
      
      // Get user's current coins
      final userDoc = await UserRecord.getDocumentOnce(userRef);
      final currentCoins = userDoc.lunaCoins;
      
      // Check if user has enough coins
      if (currentCoins < price) {
        return false;
      }
      
      // Deduct coins
      await userRef.update({
        'luna_coins': FieldValue.increment(-price),
      });
      
      // Add to unlocked backgrounds
      _unlockedBackgrounds.add(backgroundFile);
      await _saveUnlockedBackgrounds();
      
      // Notify listeners
      notifyListeners();
      
      return true;
    } catch (e) {
      print('Error unlocking background: $e');
      return false;
    }
  }

  // Available background options
  List<Map<String, String>> get backgroundOptions {
    print('Accessing backgroundOptions - returning Lottie files only');
    return [
      {'name': 'Default', 'file': 'backgroundanimation.json'},
      {'name': 'Gradient', 'file': 'gradient.json'},
      {'name': 'Hills', 'file': 'hills.json'},
      {'name': 'Ocean', 'file': 'ocean.json'},
      {'name': 'Rainforest', 'file': 'rainforest.json'},
      {'name': 'Night Hill', 'file': 'nighthill.json'},
      {'name': 'Night Lake', 'file': 'nightlake.json'},
      {'name': 'Zig Fill', 'file': 'zigfill.json'},
      {'name': 'Music Notes', 'file': 'Musicnotes.json'},
    ];
  }

  // Get sorted background options - unlocked first, then locked
  List<Map<String, String>> get sortedBackgroundOptions {
    final unlocked = backgroundOptions
        .where((bg) => isBackgroundUnlocked(bg['file']!))
        .toList();
    
    final locked = backgroundOptions
        .where((bg) => !isBackgroundUnlocked(bg['file']!))
        .toList();
    
    return [...unlocked, ...locked];
  }

  // Get the current user's background selection key
  String get _userBackgroundKey {
    final user = _auth.currentUser;
    return user != null
        ? '${_backgroundSelectionKey}_${user.uid}'
        : _backgroundSelectionKey;
  }

  // Get the current user's unlocked backgrounds key
  String get _userUnlockedBackgroundsKey {
    final user = _auth.currentUser;
    return user != null
        ? '${_unlockedBackgroundsKey}_${user.uid}'
        : _unlockedBackgroundsKey;
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

  // Load unlocked backgrounds from SharedPreferences
  Future<void> _loadUnlockedBackgrounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUnlocked = prefs.getStringList(_userUnlockedBackgroundsKey);
      
      if (savedUnlocked != null) {
        _unlockedBackgrounds = savedUnlocked;
      } else {
        // Default to empty list for new users
        _unlockedBackgrounds = [];
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading unlocked backgrounds: $e');
    }
  }

  // Save unlocked backgrounds to SharedPreferences
  Future<void> _saveUnlockedBackgrounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_userUnlockedBackgroundsKey, _unlockedBackgrounds);
    } catch (e) {
      print('Error saving unlocked backgrounds: $e');
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

    // Check if this background is unlocked
    if (!isBackgroundUnlocked(backgroundFile)) {
      print('Background is locked: $backgroundFile');
      return;
    }

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
      await _loadUnlockedBackgrounds();
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
      await _loadUnlockedBackgrounds();
      notifyListeners();
      print('AppState reinitialized');
    } catch (e) {
      print('Error reinitializing AppState: $e');
    }
  }
}
