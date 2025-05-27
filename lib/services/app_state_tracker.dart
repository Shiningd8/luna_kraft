import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to track and update the app's state in Firestore for the current user.
/// 
/// This is used by the Cloud Functions to determine whether push notifications 
/// should be sent (when app is in background or terminated) or skipped (when in foreground).
class AppStateTracker with WidgetsBindingObserver {
  static final AppStateTracker _instance = AppStateTracker._internal();
  factory AppStateTracker() => _instance;
  
  AppStateTracker._internal();

  bool _isInitialized = false;
  
  /// Initialize the app state tracker
  void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
      
      // Set initial state when app starts
      _updateAppState('foreground');
      
      print('AppStateTracker initialized');
    }
  }
  
  /// Clean up the tracker
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
      print('AppStateTracker disposed');
    }
  }
  
  /// Updates the app state when the app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state changed to: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _updateAppState('foreground');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _updateAppState('background');
        break;
    }
  }
  
  /// Update the app state in Firestore for the current user
  Future<void> _updateAppState(String state) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('User').doc(user.uid).update({
          'app_state': state,
          'app_state_updated': FieldValue.serverTimestamp(),
        });
        print('Updated app state in Firestore: $state');
      } catch (e) {
        print('Error updating app state in Firestore: $e');
      }
    } else {
      print('Can\'t update app state: No user is logged in');
    }
  }
  
  /// Manually set app state to foreground
  Future<void> setForeground() async {
    await _updateAppState('foreground');
  }
  
  /// Manually set app state to background
  Future<void> setBackground() async {
    await _updateAppState('background');
  }
} 