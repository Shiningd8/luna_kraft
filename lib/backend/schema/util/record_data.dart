import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> createPostsRecordData({
  String? title,
  String? dream,
  String? tags,
  DateTime? date,
  DocumentReference? poster,
  bool? postIsEdited,
  String? themes,
  DocumentReference? userref,
  String? videoBackgroundUrl,
  double? videoBackgroundOpacity,
  List<DocumentReference>? likes,
  List<DocumentReference>? postSavedBy,
}) {
  final firestoreData = {
    if (title != null) 'Title': title,
    if (dream != null) 'Dream': dream,
    if (tags != null) 'Tags': tags,
    if (date != null) 'date': date,
    if (poster != null) 'poster': poster,
    if (postIsEdited != null) 'post_is_edited': postIsEdited,
    if (themes != null) 'themes': themes,
    if (userref != null) 'userref': userref,
    if (videoBackgroundUrl != null) 'video_background_url': videoBackgroundUrl,
    if (videoBackgroundOpacity != null)
      'video_background_opacity': videoBackgroundOpacity,
    if (likes != null) 'likes': likes,
    if (postSavedBy != null) 'Post_saved_by': postSavedBy,
  };

  return firestoreData;
}

Map<String, dynamic> createUserRecordData({
  String? email,
  String? displayName,
  String? photoUrl,
  String? uid,
  DateTime? createdTime,
  String? phoneNumber,
  String? userName,
  List<DocumentReference>? followingUsers,
  List<DocumentReference>? blockedUsers,
  bool? isPrivate,
  DateTime? dateOfBirth,
  String? gender,
  int? lunaCoins,
  List<DocumentReference>? pendingFollowRequests,
  List<String>? pendingFollowRequestsPaths,
}) {
  final firestoreData = {
    if (email != null) 'email': email,
    if (displayName != null) 'display_name': displayName,
    if (photoUrl != null) 'photo_url': photoUrl,
    if (uid != null) 'uid': uid,
    if (createdTime != null) 'created_time': createdTime,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (userName != null) 'user_name': userName,
    if (followingUsers != null) 'following_users': followingUsers,
    if (blockedUsers != null) 'blocked_users': blockedUsers,
    if (isPrivate != null) 'is_private': isPrivate,
    if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
    if (gender != null) 'gender': gender,
    if (lunaCoins != null) 'luna_coins': lunaCoins,
    if (pendingFollowRequests != null)
      'pending_follow_requests': pendingFollowRequests,
    if (pendingFollowRequestsPaths != null)
      'pending_follow_requests_paths': pendingFollowRequestsPaths,
  };

  return firestoreData;
}

Map<String, dynamic> createNotificationsRecordData({
  bool? isALike,
  bool? isRead,
  DocumentReference? postRef,
  DocumentReference? madeBy,
  dynamic madeTo,
  DateTime? date,
  String? madeByUsername,
  bool? isFollowRequest,
  String? status,
}) {
  String? madeToString;
  if (madeTo is String) {
    madeToString = madeTo;
  } else if (madeTo is DocumentReference) {
    madeToString = madeTo.id;
  }

  final firestoreData = {
    if (isALike != null) 'is_a_like': isALike,
    if (isRead != null) 'is_read': isRead,
    if (postRef != null) 'post_ref': postRef,
    if (madeBy != null) 'made_by': madeBy,
    if (madeToString != null) 'made_to': madeToString,
    if (date != null) 'date': date,
    if (madeByUsername != null) 'made_by_username': madeByUsername,
    if (isFollowRequest != null) 'is_follow_request': isFollowRequest,
    if (status != null) 'status': status,
  };

  return firestoreData;
}

Map<String, dynamic> createAnalyzeRecordData({
  DocumentReference? userref,
  DateTime? timestamp,
  List<String>? userDreams,
}) {
  final firestoreData = {
    if (userref != null) 'userref': userref,
    if (timestamp != null) 'timestamp': timestamp,
    if (userDreams != null) 'user_dreams': userDreams,
  };

  return firestoreData;
}

Map<String, dynamic> createDreamAnalysisRecordData({
  String? moodAnalysis,
  Map<String, List<String>>? moodEvidence,
  String? dreamPersona,
  Map<String, List<String>>? personaEvidence,
  String? dreamEnvironment,
  Map<String, List<String>>? environmentEvidence,
  String? personalGrowthInsights,
  Map<String, List<String>>? growthEvidence,
  String? recommendedActions,
  Map<String, List<String>>? actionEvidence,
  DateTime? date,
  DocumentReference? userref,
}) {
  final firestoreData = {
    if (moodAnalysis != null) 'mood_analysis': moodAnalysis,
    if (moodEvidence != null) 'mood_evidence': moodEvidence,
    if (dreamPersona != null) 'dream_persona': dreamPersona,
    if (personaEvidence != null) 'persona_evidence': personaEvidence,
    if (dreamEnvironment != null) 'dream_environment': dreamEnvironment,
    if (environmentEvidence != null)
      'environment_evidence': environmentEvidence,
    if (personalGrowthInsights != null)
      'personal_growth_insights': personalGrowthInsights,
    if (growthEvidence != null) 'growth_evidence': growthEvidence,
    if (recommendedActions != null) 'recommended_actions': recommendedActions,
    if (actionEvidence != null) 'action_evidence': actionEvidence,
    if (date != null) 'date': date,
    if (userref != null) 'userref': userref,
  };

  return firestoreData;
}

Map<String, dynamic> createCommentsRecordData({
  String? comment,
  DateTime? date,
  DocumentReference? postref,
  DocumentReference? userref,
}) {
  final firestoreData = {
    if (comment != null) 'comment': comment,
    if (date != null) 'date': date,
    if (postref != null) 'postref': postref,
    if (userref != null) 'userref': userref,
  };

  return firestoreData;
}
