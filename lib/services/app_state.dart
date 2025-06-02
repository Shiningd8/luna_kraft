import 'package:flutter/material.dart';
import 'zen_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/utils/subscription_util.dart';

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
        
        // Add a slight delay to ensure subscription data is loaded
        Future.delayed(Duration(seconds: 1), () {
          validateBackgroundSelection();
        });
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
  Future<bool> isBackgroundUnlocked(String backgroundFile) async {
    // Basic backgrounds are always available
    if (backgroundFile == 'backgroundanimation.json' || backgroundFile == 'gradient.json') {
      return true;
    }
    
    // First check if user is premium - fast path for subscribers
    if (SubscriptionUtil.hasExclusiveThemes) {
      print('User has active subscription - all backgrounds are available');
      return true;
    }
    
    // For non-subscribers, check if the background is permanently unlocked
    try {
      // Load unlocked backgrounds first to ensure we have the latest data
      await _loadUnlockedBackgrounds();
      
      // Check if the background is in unlocked list
      final isUnlocked = _unlockedBackgrounds.contains(backgroundFile);
      
      print('Background $backgroundFile unlocked status: $isUnlocked (non-subscriber)');
      return isUnlocked;
    } catch (e) {
      print('Error checking if background is unlocked: $e');
      return false;
    }
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

  // Unlock a background and store in Firestore
  Future<bool> unlockBackground(String backgroundFile) async {
    // Check if already unlocked first
    final alreadyUnlocked = await isBackgroundUnlocked(backgroundFile);
    if (alreadyUnlocked) {
      return true; // Already unlocked
    }
    
    // If not already unlocked, continue with purchase...
    try {
      // Get current user
      final userRef = currentUserReference;
      if (userRef == null) {
        return false;
      }

      // Get the price
      final price = getBackgroundPrice(backgroundFile);
      
      // Get user's current coins
      final userDoc = await UserRecord.getDocumentOnce(userRef);
      final currentCoins = userDoc.lunaCoins;
      
      // Check if user has enough coins
      if (currentCoins < price) {
        return false;
      }
      
      // Add to unlocked backgrounds in memory
      _unlockedBackgrounds.add(backgroundFile);
      
      // Update Firestore with unlocked background and deduct coins
      await userRef.update({
        'luna_coins': FieldValue.increment(-price),
        'unlocked_backgrounds': FieldValue.arrayUnion([backgroundFile]),
      });
      
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
        .where((bg) => isPremiumBackgroundAvailable(bg['file']!))
        .toList();
    
    final locked = backgroundOptions
        .where((bg) => !isPremiumBackgroundAvailable(bg['file']!))
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

  // Load unlocked backgrounds from Firestore
  Future<void> _loadUnlockedBackgrounds() async {
    try {
      if (currentUserReference == null) return;
      
      // Fetch user document from Firestore
      final userDoc = await currentUserReference!.get();
      if (!userDoc.exists) return;
      
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return;
      
      // Get unlocked backgrounds
      final unlockedBgs = userData['unlocked_backgrounds'] as List<dynamic>?;
      
      if (unlockedBgs != null) {
        _unlockedBackgrounds = unlockedBgs.cast<String>();
      } else {
        // If field doesn't exist yet, initialize as empty list
        _unlockedBackgrounds = [];
      }
      
      notifyListeners();
      print('Loaded ${_unlockedBackgrounds.length} unlocked backgrounds from Firestore');
    } catch (e) {
      print('Error loading unlocked backgrounds from Firestore: $e');
    }
  }

  // Load background preference from Firestore (fall back to SharedPreferences)
  Future<void> _loadBackgroundPreference() async {
    try {
      if (currentUserReference == null) {
        // Fall back to SharedPreferences if not signed in
        final prefs = await SharedPreferences.getInstance();
        final savedBackground = prefs.getString(_backgroundSelectionKey) ?? 'backgroundanimation.json';
        _selectedBackground = savedBackground;
        return;
      }
      
      // First try to get from Firestore
      final userDoc = await currentUserReference!.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData.containsKey('selected_background')) {
          _selectedBackground = userData['selected_background'] as String? ?? 'backgroundanimation.json';
          notifyListeners();
          return;
        }
      }
      
      // Fall back to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedBackground = prefs.getString(_backgroundSelectionKey) ?? 'backgroundanimation.json';
      _selectedBackground = savedBackground;
      
      // Save to Firestore for future use
      if (currentUserReference != null) {
        await currentUserReference!.update({
          'selected_background': _selectedBackground,
        });
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading background preference: $e');
      
      // Final fallback to default
      _selectedBackground = 'backgroundanimation.json';
    }
  }

  // Set background and persist to Firestore
  Future<void> setBackground(String backgroundFile) async {
    try {
      // Check if this background is unlocked
      final isUnlocked = await isBackgroundUnlocked(backgroundFile);
      if (!isUnlocked) {
        print('Background is locked: $backgroundFile');
        return;
      }

      if (_selectedBackground == backgroundFile) return;

      _selectedBackground = backgroundFile;
      notifyListeners();

      try {
        // Save to Firestore if logged in
        if (currentUserReference != null) {
          await currentUserReference!.update({
            'selected_background': backgroundFile,
          });
        }
        
        // Also save to SharedPreferences as backup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_backgroundSelectionKey, backgroundFile);
      } catch (e) {
        print('Error saving background preference: $e');
      }
    } catch (e) {
      print('Error setting background: $e');
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

  // Helper method to unlock all backgrounds for premium users
  Future<void> unlockAllBackgroundsForPremium() async {
    try {
      if (!SubscriptionUtil.hasExclusiveThemes || currentUserReference == null) {
        return; // Only for premium users
      }
      
      // Get all background files except default ones
      // NOTE: We no longer permanently unlock backgrounds for premium users
      // Premium users get access during active subscription only
      final backgroundFiles = backgroundOptions
          .where((bg) => 
              bg['file'] != 'backgroundanimation.json' && 
              bg['file'] != 'gradient.json')
          .map((bg) => bg['file']!)
          .toList();
      
      // No need to update Firestore with permanently unlocked backgrounds
      // Premium users will only temporarily have access based on their subscription status
      
      // Update local state to show backgrounds as available in the UI
      _unlockedBackgrounds = [..._unlockedBackgrounds]; // Keep existing purchases
      
      // Force UI update to show all backgrounds as available
      notifyListeners();
      print('Premium backgrounds available for subscription user');
    } catch (e) {
      print('Error making premium backgrounds available: $e');
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
      
      // Check if user is premium and unlock all backgrounds if needed
      if (SubscriptionUtil.hasExclusiveThemes) {
        await unlockAllBackgroundsForPremium();
      }
      
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
      
      // Validate background selection after reloading data
      await validateBackgroundSelection();
      
      // Check if user is premium and unlock all backgrounds if needed
      if (SubscriptionUtil.hasExclusiveThemes) {
        await unlockAllBackgroundsForPremium();
      }
      
      notifyListeners();
      print('AppState reinitialized');
    } catch (e) {
      print('Error reinitializing AppState: $e');
      
      // If there's an error, default to the basic background
      try {
        await setBackground('backgroundanimation.json');
      } catch (setError) {
        print('Error setting default background: $setError');
      }
    }
  }

  // Add new method to validate the current background selection
  Future<void> validateBackgroundSelection() async {
    print('Validating background selection...');
    try {
      // Get current background
      final currentBackground = _selectedBackground;
      
      // If it's a default background, no need to validate
      if (currentBackground == 'backgroundanimation.json' || 
          currentBackground == 'gradient.json') {
        print('Using default background, no validation needed');
        return;
      }
      
      // First check with immediate validation (for speed)
      final isImmediatelyAvailable = isPremiumBackgroundAvailable(currentBackground);
      
      if (isImmediatelyAvailable) {
        print('Selected background ($currentBackground) is available to this user');
        return;
      }
      
      // Double-check with the full async check in case we missed something
      final isAvailable = await isBackgroundUnlocked(currentBackground);
      
      // If not available, reset to default
      if (!isAvailable) {
        print('Selected background ($currentBackground) is not available to this user, resetting to default');
        await setBackground('backgroundanimation.json');
        
        // Show a debug message
        print('Background reset to default due to unavailability');
      } else {
        print('Selected background ($currentBackground) is available to this user');
      }
    } catch (e) {
      print('Error validating background selection: $e');
      // Reset to default in case of error
      await setBackground('backgroundanimation.json');
    }
  }

  // Check if a premium background is available now (based on current subscription status)
  bool isPremiumBackgroundAvailable(String backgroundFile) {
    // Default and gradient backgrounds are always available
    if (backgroundFile == 'backgroundanimation.json' || 
        backgroundFile == 'gradient.json') {
      return true;
    }
    
    // Check if user has premium benefits through subscription
    if (SubscriptionUtil.hasExclusiveThemes) {
      return true; // Premium users get all backgrounds while their subscription is active
    }
    
    // Check in user's unlocked backgrounds list - these are purchased permanently
    if (_unlockedBackgrounds.contains(backgroundFile)) {
      return true;
    }
    
    return false;
  }

  // Helper method to be used in filters for premium backgrounds
  bool filterAvailableBackgrounds(dynamic background) {
    final file = background['file'] as String?;
    if (file == null) return false;
    
    return isPremiumBackgroundAvailable(file);
  }
}
