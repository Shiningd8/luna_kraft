import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Test ad unit ID for rewarded ads
  static const String _rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5354046379';

  Future<void> loadRewardedAd() async {
    if (_isAdLoaded) return;

    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isAdLoaded = true;
            print('Rewarded ad loaded successfully');

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
      return false;
    }

    try {
      await _rewardedAd?.show(
        onUserEarnedReward: (_, reward) async {
          print('User earned reward: ${reward.amount} ${reward.type}');
          // Grant 10 coins to the user
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(currentUser.uid)
                  .get();
              final currentCoins = userDoc.data()?['coins'] ?? 0;
              await _firestore.collection('users').doc(currentUser.uid).update({
                'coins': currentCoins + 10,
              });
              print('Successfully updated user coins');
            } catch (e) {
              print('Error updating user coins: $e');
            }
          }
        },
      );
      return true;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      return false;
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _isAdLoaded = false;
  }
}
