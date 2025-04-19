import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart' hide mapEquals;
import 'package:flutter/foundation.dart';

abstract class FirestoreRecord {
  final DocumentReference reference;
  final Map<String, dynamic> snapshotData;

  FirestoreRecord(this.reference, this.snapshotData);

  @override
  bool operator ==(Object other) =>
      other is FirestoreRecord &&
      (reference == other.reference ||
          mapEquals(snapshotData, other.snapshotData));

  @override
  int get hashCode => reference.hashCode;
}
