import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

class AnalyzeRecord extends FirestoreRecord {
  AnalyzeRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userref" field.
  DocumentReference? _userref;
  DocumentReference? get userref => _userref;
  bool hasUserref() => _userref != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "user_dreams" field.
  List<String>? _userDreams;
  List<String> get userDreams => _userDreams ?? const [];
  bool hasUserDreams() => _userDreams != null;

  void _initializeFields() {
    _userref = snapshotData['userref'] as DocumentReference?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _userDreams = getDataList(snapshotData['user_dreams']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('analyze');

  static Stream<AnalyzeRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AnalyzeRecord.fromSnapshot(s));

  static Future<AnalyzeRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AnalyzeRecord.fromSnapshot(s));

  static AnalyzeRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AnalyzeRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AnalyzeRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AnalyzeRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AnalyzeRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AnalyzeRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}
