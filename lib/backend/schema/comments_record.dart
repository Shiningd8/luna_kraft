import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/util/algolia_util.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/lat_lng.dart';

import 'index.dart';

class CommentsRecord extends FirestoreRecord {
  CommentsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "comment" field.
  String? _comment;
  String get comment => _comment ?? '';
  bool hasComment() => _comment != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "postref" field.
  DocumentReference? _postref;
  DocumentReference? get postref => _postref;
  bool hasPostref() => _postref != null;

  // "userref" field.
  DocumentReference? _userref;
  DocumentReference? get userref => _userref;
  bool hasUserref() => _userref != null;

  void _initializeFields() {
    _comment = snapshotData['comment'] as String?;
    _date = snapshotData['date'] as DateTime?;
    _postref = snapshotData['postref'] as DocumentReference?;
    _userref = snapshotData['userref'] as DocumentReference?;
  }

  static const _documentPath = 'comments';

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection(_documentPath);

  static Future<CommentsRecord?> getDocument(DocumentReference ref) =>
      ref.get().then((s) => CommentsRecord.fromSnapshot(s));

  static CommentsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CommentsRecord._(snapshot.reference,
          mapFromFirestore(snapshot.data() as Map<String, dynamic>));

  static CommentsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CommentsRecord._(reference, mapFromFirestore(data));

  static CommentsRecord fromAlgolia(AlgoliaObjectSnapshot snapshot) =>
      CommentsRecord.getDocumentFromData(snapshot.data, snapshot.reference);

  static Future<List<CommentsRecord>> search({
    String? term,
    FutureOr<LatLng>? location,
    int? maxResults,
    double? searchRadiusMeters,
    bool useFrontendSearch = false,
  }) async {
    final searchTerm = term ?? '';
    final searchObj = indexCommentsRecord;
    final searchResults = await searchAlgolia<CommentsRecord>(
      searchTerm: searchTerm,
      searchObj: searchObj,
      location: location,
      maxResults: maxResults,
      searchRadiusMeters: searchRadiusMeters,
      useFrontendSearch: useFrontendSearch,
    );
    return searchResults.map((r) => CommentsRecord.fromAlgolia(r)).toList();
  }

  static Future<CommentsRecord?> searchObject({
    String? term,
    FutureOr<LatLng>? location,
    int? maxResults,
    double? searchRadiusMeters,
    bool useFrontendSearch = false,
  }) async {
    final searchResults = await search(
      term: term,
      location: location,
      maxResults: 1,
      searchRadiusMeters: searchRadiusMeters,
      useFrontendSearch: useFrontendSearch,
    );
    return searchResults.isNotEmpty ? searchResults.first : null;
  }

  static CommentsRecord? _currentDocument;
  static CommentsRecord get currentDocument {
    assert(_currentDocument != null,
        'No _CommentsRecord._currentDocument loaded. Try requesting the document first.');
    return _currentDocument!;
  }

  static Future<CommentsRecord> getCurrentDocument() async {
    final ref = FirebaseFirestore.instance.doc('$_documentPath/current');
    final doc = await ref.get();
    assert(doc.exists, 'No document found at $_documentPath/current');
    _currentDocument = CommentsRecord.fromSnapshot(doc);
    return _currentDocument!;
  }

  @override
  String toString() =>
      'CommentsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(Object other) =>
      other is CommentsRecord &&
      (reference == other.reference ||
          mapEquals(snapshotData, other.snapshotData));
}
