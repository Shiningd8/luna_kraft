import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/widgets/modern_notification_toast.dart';
import '/services/notification_service.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal() {
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _initializeService();
  }

  // Lifecycle observer
  final _AppLifecycleObserver _lifecycleObserver = _AppLifecycleObserver();

  // Connectivity
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  bool _isInBackground = false;
  bool _isInitialized = false;

  // Reconnection attempts
  int _reconnectionAttempts = 0;
  Timer? _reconnectionTimer;
  Timer? _keepAliveTimer;
  Timer? _networkCheckTimer;

  // Stream controller for network status
  final StreamController<bool> _networkStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get networkStatusStream => _networkStatusController.stream;

  // Initialize service with retry mechanism
  Future<void> _initializeService() async {
    if (_isInitialized) return;

    try {
      // Configure Firestore settings
      await _configureFirestore();

      // Set up initial connectivity check
      await _checkConnectivity();

      // Set up connectivity monitoring
      _setupConnectivityMonitor();

      // Start periodic network checks
      _startPeriodicNetworkCheck();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing NetworkService: $e');
      // Retry initialization after delay
      Future.delayed(Duration(seconds: 5), _initializeService);
    }
  }

  // Configure Firestore with optimized settings
  Future<void> _configureFirestore() async {
    try {
      // Configure Firestore settings for mobile platforms
      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        sslEnabled: true,
      );

      print('Firestore configured successfully');
    } catch (e) {
      print('Error configuring Firestore: $e');
      throw e;
    }
  }

  // Start periodic network check
  void _startPeriodicNetworkCheck() {
    _networkCheckTimer?.cancel();
    _networkCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!_isConnected || _isInBackground) {
        await _checkConnectivity();
      }
    });
  }

  // Enhanced connection check
  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final hadConnection = _isConnected;
      _isConnected = result != ConnectivityResult.none;

      // Only verify Firestore if we have a network connection
      if (_isConnected) {
        if (!hadConnection || _isInBackground) {
          await _verifyFirestoreConnection();
        }
        _networkStatusController.add(true);
      } else {
        _networkStatusController.add(false);
      }
    } catch (e) {
      print('Error checking connectivity: $e');
      // Don't assume connected on error
      _isConnected = false;
      _networkStatusController.add(false);
    }
  }

  // Verify Firestore connection using user document
  Future<void> _verifyFirestoreConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .get()
          .timeout(Duration(seconds: 5));

      print('Firestore connection verified');
    } catch (e) {
      print('Error verifying Firestore connection: $e');
      _scheduleReconnection();
    }
  }

  // Schedule reconnection attempt
  void _scheduleReconnection() {
    if (_reconnectionAttempts >= 5) {
      _reconnectionAttempts = 0;
      return;
    }

    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(
      Duration(seconds: pow(2, _reconnectionAttempts).toInt()),
      () async {
        _reconnectionAttempts++;
        await _verifyFirestoreConnection();
      },
    );
  }

  // Set up connectivity monitoring
  void _setupConnectivityMonitor() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  // Update connection status
  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    print(
        'Connectivity status: ${_isConnected ? 'Connected' : 'Disconnected'}');

    if (_isConnected != wasConnected) {
      _networkStatusController.add(_isConnected);

      if (_isConnected && !wasConnected) {
        _verifyFirestoreConnection();
      }
    }
  }

  // Enhanced background handling
  void onBackground() {
    _isInBackground = true;
    _startBackgroundMonitoring();
  }

  // Enhanced foreground handling
  void onForeground() {
    _isInBackground = false;
    _reconnectionAttempts = 0;
    _checkConnectivity();
    _startForegroundMonitoring();
  }

  // Start background monitoring
  void _startBackgroundMonitoring() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _checkConnectivity();
      }
    });
  }

  // Start foreground monitoring
  void _startForegroundMonitoring() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (_isConnected && !_isInBackground) {
        _checkConnectivity();
      }
    });
  }

  // Clean up resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _reconnectionTimer?.cancel();
    _keepAliveTimer?.cancel();
    _networkCheckTimer?.cancel();
    _networkStatusController.close();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
  }

  // Background handler setup
  void _setupBackgroundHandler() {
    // Increase timeouts for background operations
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      sslEnabled: true,
      host: 'firestore.googleapis.com', // Explicitly set host
    );
  }

  // Clear DNS cache (Android specific)
  Future<void> _clearDnsCache() async {
    try {
      if (Platform.isAndroid) {
        await Process.run('nslookup', ['firestore.googleapis.com']);
      }
    } catch (e) {
      print('Error clearing DNS cache: $e');
    }
  }
}

// Global navigatorKey to get BuildContext from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Lifecycle observer to handle app state changes
class _AppLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state changed to: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        print('App resumed - refreshing connections');
        NetworkService().onForeground();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        print('App paused/inactive - preparing for background');
        NetworkService().onBackground();
        break;
      case AppLifecycleState.detached:
        print('App detached - ensuring background operation');
        NetworkService().onBackground();
        break;
      default:
        print('Unhandled lifecycle state: $state');
        break;
    }
  }
}
