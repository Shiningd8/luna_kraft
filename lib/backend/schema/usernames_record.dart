import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../schema/util/schema_util.dart';

class UsernamesRecord {
  final String? userName;
  final DocumentReference? userRef;
  final DocumentReference? reference;
  final List<String>? usernameInUse;

  UsernamesRecord({
    this.userName,
    this.userRef,
    this.reference,
    this.usernameInUse,
  });

  factory UsernamesRecord.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    return UsernamesRecord(
      userName: data?['user_name'] as String?,
      userRef: data?['user_ref'] as DocumentReference?,
      reference: snapshot.reference,
      usernameInUse:
          (data?['username_in_use'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_name': userName,
      'user_ref': userRef,
      'username_in_use': usernameInUse,
    };
  }

  static Future<UsernamesRecord?> getDocument(DocumentReference ref) async {
    final snapshot = await ref.get();
    if (!snapshot.exists) return null;
    return UsernamesRecord.fromSnapshot(snapshot);
  }

  static Future<List<UsernamesRecord>> getDocuments(
      {QueryDocumentSnapshot? startAfter,
      int? limit,
      DocumentReference? parent}) {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('usernames');

    if (parent != null) {
      query = query.where('user_ref', isEqualTo: parent);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.get().then((snapshot) {
      return snapshot.docs
          .map((doc) => UsernamesRecord.fromSnapshot(doc))
          .toList();
    });
  }

  static Future<List<UsernamesRecord>> queryUsernamesRecord({
    DocumentReference? parent,
    QueryDocumentSnapshot? startAfter,
    int? limit,
  }) {
    return getDocuments(
      startAfter: startAfter,
      limit: limit,
      parent: parent,
    );
  }
}
