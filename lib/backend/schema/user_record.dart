import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:built_collection/built_collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

class UserRecord extends FirestoreRecord {
  UserRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "email" field.
  String? _email;
  String? get email => _email;
  bool hasEmail() => _email != null;

  // "display_name" field.
  String? _displayName;
  String? get displayName => _displayName;
  bool hasDisplayName() => _displayName != null;

  // "photo_url" field.
  String? _photoUrl;
  String? get photoUrl => _photoUrl;
  bool hasPhotoUrl() => _photoUrl != null;

  // "uid" field.
  String? _uid;
  String? get uid => _uid;
  bool hasUid() => _uid != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "phone_number" field.
  String? _phoneNumber;
  String? get phoneNumber => _phoneNumber;
  bool hasPhoneNumber() => _phoneNumber != null;

  // "user_name" field.
  String? _userName;
  String? get userName => _userName;
  bool hasUserName() => _userName != null;

  // "following_users" field.
  List<DocumentReference>? _followingUsers;
  List<DocumentReference> get followingUsers => _followingUsers ?? const [];
  bool hasFollowingUsers() => _followingUsers != null;

  // "users_following_me" field.
  List<DocumentReference>? _usersFollowingMe;
  List<DocumentReference> get usersFollowingMe => _usersFollowingMe ?? const [];
  bool hasUsersFollowingMe() => _usersFollowingMe != null;

  // "blocked_users" field.
  List<DocumentReference>? _blockedUsers;
  List<DocumentReference> get blockedUsers => _blockedUsers ?? const [];
  bool hasBlockedUsers() => _blockedUsers != null;

  // "is_private" field.
  bool? _isPrivate;
  bool get isPrivate => _isPrivate ?? false;
  bool hasIsPrivate() => _isPrivate != null;

  // "date_of_birth" field.
  DateTime? _dateOfBirth;
  DateTime? get dateOfBirth => _dateOfBirth;
  bool hasDateOfBirth() => _dateOfBirth != null;

  // "gender" field.
  String? _gender;
  String get gender => _gender ?? '';
  bool hasGender() => _gender != null;

  // "luna_coins" field.
  int? _lunaCoins;
  int get lunaCoins => _lunaCoins ?? 0;
  bool hasLunaCoins() => _lunaCoins != null;

  // "pending_follow_requests" field.
  List<DocumentReference>? _pendingFollowRequests;
  List<DocumentReference> get pendingFollowRequests =>
      _pendingFollowRequests ?? const [];
  bool hasPendingFollowRequests() => _pendingFollowRequests != null;

  // "pending_follow_requests_paths" field.
  List<String>? _pendingFollowRequestsPaths;
  List<String> get pendingFollowRequestsPaths =>
      _pendingFollowRequestsPaths ?? const [];
  bool hasPendingFollowRequestsPaths() => _pendingFollowRequestsPaths != null;

  // "is_2fa_enabled" field.
  bool? _is2FAEnabled;
  bool get is2FAEnabled => _is2FAEnabled ?? false;
  bool hasIs2FAEnabled() => _is2FAEnabled != null;

  // "2fa_secret_key" field.
  String? _twoFactorSecretKey;
  String get twoFactorSecretKey => _twoFactorSecretKey ?? '';
  bool hasTwoFactorSecretKey() => _twoFactorSecretKey != null;

  // "daily_dream_uploads" field.
  int? _dailyDreamUploads;
  int get dailyDreamUploads => _dailyDreamUploads ?? 0;
  bool hasDailyDreamUploads() => _dailyDreamUploads != null;

  // "last_upload_reset_date" field.
  DateTime? _lastUploadResetDate;
  DateTime? get lastUploadResetDate => _lastUploadResetDate;
  bool hasLastUploadResetDate() => _lastUploadResetDate != null;

  // "last_username_change_date" field.
  DateTime? _lastUsernameChangeDate;
  DateTime? get lastUsernameChangeDate => _lastUsernameChangeDate;
  bool hasLastUsernameChangeDate() => _lastUsernameChangeDate != null;

  // "unlocked_backgrounds" field.
  List<String>? _unlockedBackgrounds;
  List<String> get unlockedBackgrounds => _unlockedBackgrounds ?? const [];
  bool hasUnlockedBackgrounds() => _unlockedBackgrounds != null;

  // "unlocked_zen_sounds" field.
  List<String>? _unlockedZenSounds;
  List<String> get unlockedZenSounds => _unlockedZenSounds ?? const [];
  bool hasUnlockedZenSounds() => _unlockedZenSounds != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _userName = snapshotData['user_name'] as String?;
    _followingUsers = getDataList(snapshotData['following_users']);
    _usersFollowingMe = getDataList(snapshotData['users_following_me']);
    _blockedUsers = getDataList(snapshotData['blocked_users']);
    _isPrivate = snapshotData['is_private'] as bool?;
    _dateOfBirth = snapshotData['date_of_birth'] as DateTime?;
    _gender = snapshotData['gender'] as String?;
    _lunaCoins = snapshotData['luna_coins'] as int?;
    _pendingFollowRequests =
        getDataList(snapshotData['pending_follow_requests']);
    _pendingFollowRequestsPaths =
        getDataList(snapshotData['pending_follow_requests_paths']);
    _is2FAEnabled = snapshotData['is_2fa_enabled'] as bool?;
    _twoFactorSecretKey = snapshotData['2fa_secret_key'] as String?;
    _dailyDreamUploads = snapshotData['daily_dream_uploads'] as int?;
    _lastUploadResetDate = snapshotData['last_upload_reset_date'] as DateTime?;
    _lastUsernameChangeDate =
        snapshotData['last_username_change_date'] as DateTime?;
    _unlockedBackgrounds = getDataList(snapshotData['unlocked_backgrounds']);
    _unlockedZenSounds = getDataList(snapshotData['unlocked_zen_sounds']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('User');

  static Stream<UserRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserRecord.fromSnapshot(s));

  static Future<UserRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UserRecord.fromSnapshot(s));

  static UserRecord fromSnapshot(DocumentSnapshot snapshot) => UserRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UserRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserRecord &&
      reference.path.hashCode == other.reference.path.hashCode;

  // Helper method to access fields by string name
  dynamic get(String fieldName) {
    switch (fieldName) {
      case 'email': return _email;
      case 'display_name': return _displayName;
      case 'photo_url': return _photoUrl;
      case 'uid': return _uid;
      case 'created_time': return _createdTime;
      case 'phone_number': return _phoneNumber;
      case 'user_name': return _userName;
      case 'following_users': return _followingUsers;
      case 'users_following_me': return _usersFollowingMe;
      case 'blocked_users': return _blockedUsers;
      case 'is_private': return _isPrivate;
      case 'date_of_birth': return _dateOfBirth;
      case 'gender': return _gender;
      case 'luna_coins': return _lunaCoins;
      case 'pending_follow_requests': return _pendingFollowRequests;
      case 'pending_follow_requests_paths': return _pendingFollowRequestsPaths;
      case 'is_2fa_enabled': return _is2FAEnabled;
      case '2fa_secret_key': return _twoFactorSecretKey;
      case 'daily_dream_uploads': return _dailyDreamUploads;
      case 'last_upload_reset_date': return _lastUploadResetDate;
      case 'last_username_change_date': return _lastUsernameChangeDate;
      case 'unlocked_backgrounds': return _unlockedBackgrounds;
      case 'unlocked_zen_sounds': return _unlockedZenSounds;
      default: {
        // Try to access directly from snapshotData if available
        if (snapshotData.containsKey(fieldName)) {
          return snapshotData[fieldName];
        }
        return null;
      }
    }
  }
}

class UserRecordField {
  static const String email = 'email';
  static const String displayName = 'display_name';
  static const String photoUrl = 'photo_url';
  static const String uid = 'uid';
  static const String createdTime = 'created_time';
  static const String phoneNumber = 'phone_number';
  static const String isNewUser = 'is_new_user';
  static const String purchasedProducts = 'purchased_products';
  static const String referralCode = 'referral_code';
  static const String lunaCoins = 'luna_coins';
  static const String streakCount = 'streak_count';
  static const String lastDayActive = 'last_day_active';
  static const String backgroundIndex = 'background_index';
  static const String streakData = 'streak_data';
  static const String unlockAllBackgrounds = 'unlock_all_backgrounds';
  static const String userBenefits = 'user_benefits';
  static const String unlockedBackgrounds = 'unlocked_backgrounds';
  static const String unlockedZenSounds = 'unlocked_zen_sounds';
}
