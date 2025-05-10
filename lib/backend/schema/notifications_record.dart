import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

class NotificationsRecord extends FirestoreRecord {
  NotificationsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "is_a_like" field.
  bool? _isALike;
  bool get isALike => _isALike ?? false;
  bool hasIsALike() => _isALike != null;

  // "is_read" field.
  bool? _isRead;
  bool get isRead => _isRead ?? false;
  bool hasIsRead() => _isRead != null;

  // "post_ref" field.
  DocumentReference? _postRef;
  DocumentReference? get postRef => _postRef;
  bool hasPostRef() => _postRef != null;

  // "made_by" field.
  DocumentReference? _madeBy;
  DocumentReference? get madeBy => _madeBy;
  bool hasMadeBy() => _madeBy != null;

  // "made_to" field.
  String? _madeTo;
  String? get madeTo => _madeTo;
  bool hasMadeTo() => _madeTo != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "made_by_username" field.
  String? _madeByUsername;
  String get madeByUsername => _madeByUsername ?? '';
  bool hasMadeByUsername() => _madeByUsername != null;

  // "is_follow_request" field.
  bool? _isFollowRequest;
  bool get isFollowRequest => _isFollowRequest ?? false;
  bool hasIsFollowRequest() => _isFollowRequest != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "is_reply" field - indicates whether this is a notification for a reply to a comment
  bool? _isReply;
  bool get isReply => _isReply ?? false;
  bool hasIsReply() => _isReply != null;

  void _initializeFields() {
    // For boolean fields, explicitly cast to bool to avoid type issues
    final rawIsALike = snapshotData['is_a_like'];
    if (rawIsALike != null) {
      if (rawIsALike is bool) {
        _isALike = rawIsALike;
      } else {
        // Try to convert other types to bool
        _isALike =
            rawIsALike == true || rawIsALike == 'true' || rawIsALike == 1;
      }
    } else {
      _isALike = false;
    }

    _isRead = snapshotData['is_read'] as bool?;
    _postRef = snapshotData['post_ref'] as DocumentReference?;
    _madeBy = snapshotData['made_by'] as DocumentReference?;

    // Handle the madeTo field which could be either a String or DocumentReference
    if (snapshotData['made_to'] is String) {
      _madeTo = snapshotData['made_to'] as String?;
    } else if (snapshotData['made_to'] is DocumentReference) {
      final madeToRef = snapshotData['made_to'] as DocumentReference?;
      _madeTo = madeToRef?.id;
    } else {
      _madeTo = null;
    }

    _date = snapshotData['date'] as DateTime?;
    _madeByUsername = snapshotData['made_by_username'] as String?;

    // Handle isFollowRequest the same way as isALike
    final rawIsFollowRequest = snapshotData['is_follow_request'];
    if (rawIsFollowRequest != null) {
      if (rawIsFollowRequest is bool) {
        _isFollowRequest = rawIsFollowRequest;
      } else {
        _isFollowRequest = rawIsFollowRequest == true ||
            rawIsFollowRequest == 'true' ||
            rawIsFollowRequest == 1;
      }
    } else {
      _isFollowRequest = false;
    }

    _status = snapshotData['status'] as String?;

    // Handle isReply the same way as isALike
    final rawIsReply = snapshotData['is_reply'];
    if (rawIsReply != null) {
      if (rawIsReply is bool) {
        _isReply = rawIsReply;
      } else {
        _isReply =
            rawIsReply == true || rawIsReply == 'true' || rawIsReply == 1;
      }
    } else {
      _isReply = false;
    }
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('notifications');

  static Stream<NotificationsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => NotificationsRecord.fromSnapshot(s));

  static Future<NotificationsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => NotificationsRecord.fromSnapshot(s));

  static NotificationsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      NotificationsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static NotificationsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      NotificationsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'NotificationsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is NotificationsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;

  // Add a static method to create a notification with proper field types
  static Future<DocumentReference> createNotification({
    bool isALike = false,
    bool isRead = false,
    DocumentReference? postRef,
    DocumentReference? madeBy,
    dynamic madeTo, // Accept both String and DocumentReference
    DateTime? date,
    String? madeByUsername,
    bool isFollowRequest = false,
    String status = '',
    bool isReply = false, // Add isReply parameter
  }) async {
    // Ensure madeTo is always stored as String
    String? madeToString;
    if (madeTo is String) {
      madeToString = madeTo;
    } else if (madeTo is DocumentReference) {
      madeToString = madeTo.id;
    }

    final notificationData = {
      'is_a_like': isALike,
      'is_read': isRead,
      if (postRef != null) 'post_ref': postRef,
      if (madeBy != null) 'made_by': madeBy,
      if (madeToString != null) 'made_to': madeToString,
      'date': date ?? DateTime.now(),
      if (madeByUsername != null) 'made_by_username': madeByUsername,
      'is_follow_request': isFollowRequest,
      'status': status,
      'is_reply': isReply, // Add isReply field
    };

    return await collection.add(notificationData);
  }
}
