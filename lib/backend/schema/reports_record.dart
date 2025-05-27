import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

class ReportsRecord extends FirestoreRecord {
  ReportsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data);

  // "type" field - type of report (user, comment, etc.)
  String? get type => snapshotData['type'] as String?;
  // "reason" field - reason for the report
  String? get reason => snapshotData['reason'] as String?;
  // "reported_user_id" field - ID of reported user (for user reports)
  String? get reportedUserId => snapshotData['reported_user_id'] as String?;
  // "reported_user_email" field - email of reported user (for user reports)
  String? get reportedUserEmail => snapshotData['reported_user_email'] as String?;
  // "reported_user_display_name" field - name of reported user
  String? get reportedUserDisplayName => snapshotData['reported_user_display_name'] as String?;
  // "comment_id" field - ID of reported comment (for comment reports)
  String? get commentId => snapshotData['comment_id'] as String?;
  // "post_id" field - ID of post containing reported comment (for comment reports)
  String? get postId => snapshotData['post_id'] as String?;
  // "post_owner_id" field - ID of post owner (for comment reports)
  String? get postOwnerId => snapshotData['post_owner_id'] as String?;
  // "reporter_id" field - ID of user making the report
  String? get reporterId => snapshotData['reporter_id'] as String?;
  // "reporter_email" field - email of user making the report
  String? get reporterEmail => snapshotData['reporter_email'] as String?;
  // "timestamp" field - when the report was made
  DateTime? get timestamp => snapshotData['timestamp'] as DateTime?;
  // "status" field - status of the report (new, reviewed, etc.)
  String? get status => snapshotData['status'] as String?;

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('reports');

  static ReportsRecord fromSnapshot(DocumentSnapshot snapshot) => 
      ReportsRecord._(
        snapshot.reference,
        snapshot.data() as Map<String, dynamic>,
      );

  @override
  String toString() =>
      'ReportsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ReportsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createReportsRecordData({
  String? type,
  String? reason,
  String? reportedUserId,
  String? reportedUserEmail,
  String? reportedUserDisplayName,
  String? commentId,
  String? postId,
  String? postOwnerId,
  String? reporterId,
  String? reporterEmail,
  DateTime? timestamp,
  String? status,
}) {
  final firestoreData = {
    if (type != null) 'type': type,
    if (reason != null) 'reason': reason,
    if (reportedUserId != null) 'reported_user_id': reportedUserId,
    if (reportedUserEmail != null) 'reported_user_email': reportedUserEmail,
    if (reportedUserDisplayName != null) 'reported_user_display_name': reportedUserDisplayName,
    if (commentId != null) 'comment_id': commentId,
    if (postId != null) 'post_id': postId,
    if (postOwnerId != null) 'post_owner_id': postOwnerId,
    if (reporterId != null) 'reporter_id': reporterId,
    if (reporterEmail != null) 'reporter_email': reporterEmail,
    if (timestamp != null) 'timestamp': timestamp,
    if (status != null) 'status': status,
  };

  return firestoreData;
} 