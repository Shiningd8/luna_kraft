import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../flutter_flow/nav/nav.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Test ad unit ID for rewarded ads
  static const String _rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  Future<void> loadRewardedAd() async {
    if (_isAdLoaded) {
      print('Ad already loaded, skipping load request');
      return;
    }

    try {
      print('Starting to load rewarded ad...');
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            print('Rewarded ad loaded successfully');
            _rewardedAd = ad;
            _isAdLoaded = true;

            _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print('Ad dismissed');
                _isAdLoaded = false;
                ad.dispose();
                loadRewardedAd(); // Load the next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('Ad failed to show: ${error.message}');
                _isAdLoaded = false;
                ad.dispose();
                loadRewardedAd(); // Load the next ad
              },
              onAdShowedFullScreenContent: (ad) {
                print('Ad showed successfully');
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('Failed to load rewarded ad: ${error.message}');
            print('Error code: ${error.code}');
            print('Error domain: ${error.domain}');
            _isAdLoaded = false;
          },
        ),
      );
    } catch (e) {
      print('Error loading rewarded ad: $e');
      _isAdLoaded = false;
    }
  }

  Future<bool> showRewardedAd() async {
    if (!_isAdLoaded) {
      print('Ad not loaded, attempting to load...');
      await loadRewardedAd();
      if (!_isAdLoaded) {
        print('Failed to load ad after attempt');
        return false;
      }
    }

    try {
      print('Attempting to show rewarded ad...');
      await _rewardedAd?.show(
        onUserEarnedReward: (_, reward) async {
          print('User earned reward: ${reward.amount} ${reward.type}');
          // Grant 10 coins to the user
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            print('Current user found: ${currentUser.uid}');
            try {
              // Get the user document reference
              final userRef =
                  _firestore.collection('User').doc(currentUser.uid);

              // Get current document
              final userDoc = await userRef.get();
              if (!userDoc.exists) {
                print('User document does not exist!');
                return;
              }

              // Get current coins
              final currentCoins = userDoc.data()?['luna_coins'] ?? 0;
              print('Current coins before update: $currentCoins');

              // Calculate new coins
              final newCoins = currentCoins + 10;
              print('New coins value to be set: $newCoins');

              // Update the document
              await userRef.update({
                'luna_coins': newCoins,
              });
              print('Update completed successfully');

              // Verify the update
              final updatedDoc = await userRef.get();
              final updatedCoins = updatedDoc.data()?['luna_coins'] ?? 0;
              print('Verified updated coins: $updatedCoins');

              if (updatedCoins != newCoins) {
                print('WARNING: Coin update verification failed!');
                print('Expected: $newCoins, Got: $updatedCoins');
              }

              // Show success snackbar after the reward is granted
              if (appNavigatorKey.currentContext != null) {
                ScaffoldMessenger.of(appNavigatorKey.currentContext!)
                    .showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: EdgeInsets.only(right: 12),
                          child: Image.asset(
                            'assets/images/lunacoin.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Text(
                          'You earned 10 Luna Coins!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Color(0xFF6C5DD3),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              print('Error updating user coins: $e');
              print('Error details: ${e.toString()}');
              print('Error stack trace: ${StackTrace.current}');
            }
          } else {
            print('No current user found!');
          }
        },
      );
      print('Ad show completed');
      return true;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      print('Error details: ${e.toString()}');
      print('Error stack trace: ${StackTrace.current}');
      return false;
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _isAdLoaded = false;
  }
}
