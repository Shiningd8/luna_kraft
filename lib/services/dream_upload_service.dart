import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/firebase_auth/auth_util.dart';
import '../backend/schema/user_record.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DreamUploadService {
  static const int MAX_FREE_UPLOADS = 3;
  static const int LUNA_COINS_COST = 50;

  /// Checks if a user can upload a dream for free or needs to pay
  static Future<Map<String, dynamic>> checkUploadAvailability() async {
    final currentUserDoc =
        await UserRecord.getDocumentOnce(currentUserReference!);

    // Get current date at midnight (to compare dates properly)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if we need to reset the counter (new day)
    final lastResetDate = currentUserDoc.lastUploadResetDate;
    final shouldReset = lastResetDate == null ||
        DateTime(lastResetDate.year, lastResetDate.month, lastResetDate.day) !=
            today;

    if (shouldReset) {
      // It's a new day, reset the counter
      return {
        'canUploadForFree': true,
        'remainingFreeUploads': MAX_FREE_UPLOADS,
        'lunaCoins': currentUserDoc.lunaCoins,
        'needsReset': true
      };
    } else {
      // Same day, check current count
      final dailyUploads = currentUserDoc.dailyDreamUploads;
      final remainingFreeUploads = MAX_FREE_UPLOADS - dailyUploads;

      return {
        'canUploadForFree': remainingFreeUploads > 0,
        'remainingFreeUploads':
            remainingFreeUploads > 0 ? remainingFreeUploads : 0,
        'lunaCoins': currentUserDoc.lunaCoins,
        'needsReset': false
      };
    }
  }

  /// Increments the user's dream upload count for the day
  /// If it's a new day, resets the counter to 1
  static Future<void> incrementDreamUploadCount() async {
    final userRef = currentUserReference!;
    final userData = await UserRecord.getDocumentOnce(userRef);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if we need to reset the counter (new day)
    final lastResetDate = userData.lastUploadResetDate;
    final shouldReset = lastResetDate == null ||
        DateTime(lastResetDate.year, lastResetDate.month, lastResetDate.day) !=
            today;

    if (shouldReset) {
      // It's a new day, reset counter to 1 (this upload)
      await userRef.update({
        'daily_dream_uploads': 1,
        'last_upload_reset_date': now,
      });
    } else {
      // Same day, increment counter
      await userRef.update({
        'daily_dream_uploads': FieldValue.increment(1),
      });
    }
  }

  /// Charges the user luna coins for a premium upload
  static Future<bool> chargeLunaCoinsForUpload() async {
    final userRef = currentUserReference!;
    final userData = await UserRecord.getDocumentOnce(userRef);

    // Check if user has enough coins
    if (userData.lunaCoins < LUNA_COINS_COST) {
      return false; // Not enough coins
    }

    try {
      // CRITICAL FIX: Use FieldValue.increment to only update this field
      // This preserves all other fields including unlocked_backgrounds
      await userRef.update({
        'luna_coins': FieldValue.increment(-LUNA_COINS_COST),
        'last_coin_update': FieldValue.serverTimestamp(),
      });
      
      return true; // Payment successful
    } catch (e) {
      print('Error charging coins: $e');
      return false;
    }
  }
}
