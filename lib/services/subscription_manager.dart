import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'dart:async';

/// Service to manage user subscription status and verification
class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();

  // Singleton instance
  static SubscriptionManager get instance => _instance;

  // Private constructor
  SubscriptionManager._internal();

  // Stream controller for subscription changes
  final _subscriptionStatusController =
      StreamController<SubscriptionStatus>.broadcast();

  // Stream for subscription status
  Stream<SubscriptionStatus> get subscriptionStatus =>
      _subscriptionStatusController.stream;

  // Cached subscription status
  SubscriptionStatus? _cachedStatus;

  // Listen for Firestore changes
  StreamSubscription? _firestoreSubscription;

  // Initialize subscription manager
  Future<void> initialize() async {
    // Clean up any existing subscriptions
    await dispose();

    // Start listening for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _startListeningToSubscriptionChanges();
      } else {
        _stopListeningToSubscriptionChanges();
        _updateSubscriptionStatus(SubscriptionStatus(
          isSubscribed: false,
          subscriptionTier: null,
          expiryDate: null,
          benefits: [],
        ));
      }
    });
  }

  // Start listening to Firestore for subscription changes
  void _startListeningToSubscriptionChanges() {
    if (currentUserReference == null) return;

    _firestoreSubscription = FirebaseFirestore.instance
        .doc(currentUserReference!.path)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final userData = snapshot.data() as Map<String, dynamic>?;
      if (userData == null) return;

      // Get subscription data
      final subscription = userData['subscription'] as Map<String, dynamic>?;
      final isSubscribed = userData['isSubscribed'] as bool? ?? false;

      if (subscription != null && isSubscribed) {
        // Check if subscription is active and not expired
        final expiryDate = (subscription['expiryDate'] as Timestamp?)?.toDate();
        final isActive = subscription['isActive'] as bool? ?? false;

        final isExpired = expiryDate != null &&
            expiryDate.isBefore(DateTime.now()) &&
            !(subscription['autoRenew'] as bool? ?? false);

        if (isActive && !isExpired) {
          // Valid subscription
          _updateSubscriptionStatus(SubscriptionStatus(
            isSubscribed: true,
            subscriptionTier: subscription['productId'] as String? ?? 'unknown',
            expiryDate: expiryDate,
            benefits: _parseBenefits(subscription['benefits']),
          ));
        } else {
          // Expired subscription
          _updateSubscriptionStatus(SubscriptionStatus(
            isSubscribed: false,
            subscriptionTier: null,
            expiryDate: null,
            benefits: [],
          ));

          // If expired, update the user's subscription status
          if (isExpired) {
            _markSubscriptionAsExpired();
          }
        }
      } else {
        // No subscription
        _updateSubscriptionStatus(SubscriptionStatus(
          isSubscribed: false,
          subscriptionTier: null,
          expiryDate: null,
          benefits: [],
        ));
      }
    });
  }

  // Convert benefits from various formats to a List<String>
  List<String> _parseBenefits(dynamic benefits) {
    if (benefits == null) {
      return [];
    } else if (benefits is List) {
      return benefits.map((e) => e.toString()).toList();
    } else if (benefits is String) {
      return [benefits];
    }
    return [];
  }

  // Mark subscription as expired in Firebase
  Future<void> _markSubscriptionAsExpired() async {
    try {
      if (currentUserReference == null) return;

      await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
        'isSubscribed': false,
        'subscription.isActive': false,
        'lastSubscriptionUpdate': Timestamp.now(),
      });

      print('Subscription marked as expired');
    } catch (e) {
      print('Error marking subscription as expired: $e');
    }
  }

  // Stop listening to Firestore changes
  void _stopListeningToSubscriptionChanges() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
  }

  // Update subscription status and notify listeners
  void _updateSubscriptionStatus(SubscriptionStatus status) {
    _cachedStatus = status;
    _subscriptionStatusController.add(status);
  }

  // Check if user has an active subscription
  bool get isSubscribed => _cachedStatus?.isSubscribed ?? false;

  // Get subscription tier
  String? get subscriptionTier => _cachedStatus?.subscriptionTier;

  // Check if user has a specific benefit
  bool hasBenefit(String benefit) {
    return _cachedStatus?.benefits.contains(benefit) ?? false;
  }

  // Get all benefits
  List<String> get benefits => _cachedStatus?.benefits ?? [];

  // Get days left in subscription
  int get daysLeft {
    final expiryDate = _cachedStatus?.expiryDate;
    if (expiryDate == null) return 0;

    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  // Dispose resources
  Future<void> dispose() async {
    await _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
  }
}

/// Class representing subscription status
class SubscriptionStatus {
  final bool isSubscribed;
  final String? subscriptionTier;
  final DateTime? expiryDate;
  final List<String> benefits;

  SubscriptionStatus({
    required this.isSubscribed,
    required this.subscriptionTier,
    required this.expiryDate,
    required this.benefits,
  });

  @override
  String toString() =>
      'SubscriptionStatus(isSubscribed: $isSubscribed, tier: $subscriptionTier, expires: $expiryDate, benefits: $benefits)';
}
