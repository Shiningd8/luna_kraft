import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsStruct {
  final bool? isALike;
  final bool? isRead;
  final DocumentReference? postRef;
  final DocumentReference? madeBy;
  final String? madeTo;
  final DateTime? date;
  final String? madeByUsername;
  final bool? isFollowRequest;
  final String? status;

  NotificationsStruct({
    this.isALike,
    this.isRead,
    this.postRef,
    this.madeBy,
    this.madeTo,
    this.date,
    this.madeByUsername,
    this.isFollowRequest,
    this.status,
  });

  factory NotificationsStruct.fromMap(Map<String, dynamic> data) {
    return NotificationsStruct(
      isALike: data['is_a_like'] as bool?,
      isRead: data['is_read'] as bool?,
      postRef: data['post_ref'] as DocumentReference?,
      madeBy: data['made_by'] as DocumentReference?,
      madeTo: data['made_to'] as String?,
      date: data['date'] as DateTime?,
      madeByUsername: data['made_by_username'] as String?,
      isFollowRequest: data['is_follow_request'] as bool?,
      status: data['status'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_a_like': isALike,
      'is_read': isRead,
      'post_ref': postRef,
      'made_by': madeBy,
      'made_to': madeTo,
      'date': date,
      'made_by_username': madeByUsername,
      'is_follow_request': isFollowRequest,
      'status': status,
    };
  }
}
