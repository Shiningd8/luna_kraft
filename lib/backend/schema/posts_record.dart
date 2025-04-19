import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

class PostsRecord extends FirestoreRecord {
  PostsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "Title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "Dream" field.
  String? _dream;
  String get dream => _dream ?? '';
  bool hasDream() => _dream != null;

  // "Tags" field.
  String? _tags;
  String get tags => _tags ?? '';
  bool hasTags() => _tags != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "poster" field.
  DocumentReference? _poster;
  DocumentReference? get poster => _poster;
  bool hasPoster() => _poster != null;

  // "likes" field.
  List<DocumentReference>? _likes;
  List<DocumentReference> get likes => _likes ?? const [];
  bool hasLikes() => _likes != null;

  // "Post_saved_by" field.
  List<DocumentReference>? _postSavedBy;
  List<DocumentReference> get postSavedBy => _postSavedBy ?? const [];
  bool hasPostSavedBy() => _postSavedBy != null;

  // "video_background_url" field.
  String? _videoBackgroundUrl;
  String get videoBackgroundUrl => _videoBackgroundUrl ?? '';
  bool hasVideoBackgroundUrl() => _videoBackgroundUrl != null;

  // "video_background_opacity" field.
  double? _videoBackgroundOpacity;
  double get videoBackgroundOpacity => _videoBackgroundOpacity ?? 0.0;
  bool hasVideoBackgroundOpacity() => _videoBackgroundOpacity != null;

  // "post_is_edited" field.
  bool? _postIsEdited;
  bool get postIsEdited => _postIsEdited ?? false;
  bool hasPostIsEdited() => _postIsEdited != null;

  // "themes" field.
  String? _themes;
  String get themes => _themes ?? '';
  bool hasThemes() => _themes != null;

  // "userref" field.
  DocumentReference? _userref;
  DocumentReference? get userref => _userref;
  bool hasUserref() => _userref != null;

  // "is_private" field.
  bool? _isPrivate;
  bool get isPrivate => _isPrivate ?? false;
  bool hasIsPrivate() => _isPrivate != null;

  void _initializeFields() {
    _title =
        snapshotData['title'] as String? ?? snapshotData['Title'] as String?;
    _dream =
        snapshotData['dream'] as String? ?? snapshotData['Dream'] as String?;
    _tags = snapshotData['tags'] as String? ?? snapshotData['Tags'] as String?;
    _date = snapshotData['date'] as DateTime?;
    _poster = snapshotData['poster'] as DocumentReference?;
    _likes = getDataList(snapshotData['likes']);
    _postSavedBy = getDataList(snapshotData['Post_saved_by']);
    _videoBackgroundUrl = snapshotData['video_background_url'] as String?;
    _videoBackgroundOpacity =
        snapshotData['video_background_opacity'] as double?;
    _postIsEdited = snapshotData['post_is_edited'] as bool?;
    _themes = snapshotData['themes'] as String?;
    _userref = snapshotData['userref'] as DocumentReference?;
    _isPrivate = snapshotData['is_private'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('posts');

  static Stream<PostsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => PostsRecord.fromSnapshot(s));

  static Future<PostsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => PostsRecord.fromSnapshot(s));

  static PostsRecord fromSnapshot(DocumentSnapshot snapshot) => PostsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PostsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PostsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PostsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PostsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}
