import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

Map<String, dynamic> mapFromFirestore(Map<String, dynamic> data) {
  return data.map((key, value) {
    if (value is Timestamp) {
      return MapEntry(key, value.toDate());
    }
    if (value is DocumentReference) {
      return MapEntry(key, value);
    }
    if (value is List) {
      return MapEntry(
        key,
        value.map((v) {
          if (v is Timestamp) return v.toDate();
          if (v is DocumentReference) return v;
          if (v is Map<String, dynamic>) return mapFromFirestore(v);
          return v;
        }).toList(),
      );
    }
    if (value is Map<String, dynamic>) {
      return MapEntry(key, mapFromFirestore(value));
    }
    return MapEntry(key, value);
  });
}

Map<String, dynamic> mapToFirestore(Map<String, dynamic> data) {
  return data.map((key, value) {
    if (value is DateTime) {
      return MapEntry(key, Timestamp.fromDate(value));
    }
    if (value is DocumentReference) {
      return MapEntry(key, value);
    }
    if (value is List) {
      return MapEntry(
        key,
        value.map((v) {
          if (v is DateTime) return Timestamp.fromDate(v);
          if (v is DocumentReference) return v;
          if (v is Map<String, dynamic>) return mapToFirestore(v);
          return v;
        }).toList(),
      );
    }
    if (value is Map<String, dynamic>) {
      return MapEntry(key, mapToFirestore(value));
    }
    return MapEntry(key, value);
  });
}

List<T> getDataList<T>(dynamic data) {
  if (data == null) {
    return [];
  }
  if (data is List) {
    return data.cast<T>();
  }
  return [];
}
