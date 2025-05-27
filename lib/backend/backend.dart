import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../auth/firebase_auth/auth_util.dart';
import '../flutter_flow/flutter_flow_util.dart' as ff;
import 'schema/util/firestore_util.dart';
import 'schema/util/record_data.dart';
import 'schema/util/schema_util.dart';
import 'schema/structs/index.dart';

import 'schema/posts_record.dart';
import 'schema/user_record.dart';
import 'schema/notifications_record.dart';
import 'schema/analyze_record.dart';
import 'schema/comments_record.dart';
import 'schema/reports_record.dart';

export 'dart:async' show StreamSubscription;
export 'package:cloud_firestore/cloud_firestore.dart' hide Order;
export 'package:firebase_core/firebase_core.dart';
export 'schema/util/firestore_util.dart';
export 'schema/util/schema_util.dart';
export 'schema/util/record_data.dart';
export 'schema/structs/index.dart';

export 'schema/posts_record.dart';
export 'schema/user_record.dart';
export 'schema/notifications_record.dart';
export 'schema/analyze_record.dart';
export 'schema/comments_record.dart';
export 'schema/reports_record.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBD12Lf4b9UB_ZhinHFvNx3JT63u41sa_s',
      appId: '1:1097898434783:android:5c3c3c3c3c3c3c3c3c3c3c',
      messagingSenderId: '1097898434783',
      projectId: 'luna-kraft',
      storageBucket: 'luna-kraft.appspot.com',
    ),
  );

  // Configure Firestore settings
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    sslEnabled: true,
  );

  // Configure Auth settings
  FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: false,
    phoneNumber: null,
    smsCode: null,
  );
}

final _firestore = FirebaseFirestore.instance;

/// Functions to query PostsRecords (as a Stream and as a Future).
Future<int> queryPostsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(PostsRecord.collection);
  if (limit > 0) {
    query = query.limit(limit);
  }
  final snapshot = await query.count().get();
  return snapshot.count ?? 0;
}

Stream<List<PostsRecord>> queryPostsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(PostsRecord.collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query
      .snapshots()
      .map((s) => s.docs.map((d) => PostsRecord.fromSnapshot(d)).toList());
}

Future<List<PostsRecord>> queryPostsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(PostsRecord.collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  final snapshot = await query.get();
  return snapshot.docs.map((d) => PostsRecord.fromSnapshot(d)).toList();
}

/// Functions to query UserRecords (as a Stream and as a Future).
Future<int> queryUserRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(UserRecord.collection);
  if (limit > 0) {
    query = query.limit(limit);
  }
  final snapshot = await query.count().get();
  return snapshot.count ?? 0;
}

Stream<List<UserRecord>> queryUserRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(UserRecord.collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query
      .snapshots()
      .map((s) => s.docs.map((d) => UserRecord.fromSnapshot(d)).toList());
}

Future<List<UserRecord>> queryUserRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(UserRecord.collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  final snapshot = await query.get();
  return snapshot.docs.map((d) => UserRecord.fromSnapshot(d)).toList();
}

/// Functions to query NotificationsRecords (as a Stream and as a Future).
Future<int> queryNotificationsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(NotificationsRecord.collection);
  if (limit > 0) {
    query = query.limit(limit);
  }
  final snapshot = await query.count().get();
  return snapshot.count ?? 0;
}

Stream<List<NotificationsRecord>> queryNotificationsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(NotificationsRecord.collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query.snapshots().map(
      (s) => s.docs.map((d) => NotificationsRecord.fromSnapshot(d)).toList());
}

Future<List<NotificationsRecord>> queryNotificationsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(NotificationsRecord.collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  final snapshot = await query.get();
  return snapshot.docs.map((d) => NotificationsRecord.fromSnapshot(d)).toList();
}

Future<int> queryCollectionCount(
  Query collection, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0) {
    query = query.limit(limit);
  }
  final snapshot = await query.count().get();
  return snapshot.count ?? 0;
}

Stream<List<T>> queryCollection<T>(
  Query collection,
  T Function(DocumentSnapshot) fromSnapshot, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query
      .snapshots()
      .map((s) => s.docs.map((d) => fromSnapshot(d)).toList());
}

Future<List<T>> queryCollectionOnce<T>(
  Query collection,
  T Function(DocumentSnapshot) fromSnapshot, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  final snapshot = await query.get();
  return snapshot.docs.map((d) => fromSnapshot(d)).toList();
}

Filter filterIn(String field, List? list) => (list?.isEmpty ?? true)
    ? Filter(field, whereIn: null)
    : Filter(field, whereIn: list);

Filter filterArrayContainsAny(String field, List? list) =>
    (list?.isEmpty ?? true)
        ? Filter(field, arrayContainsAny: null)
        : Filter(field, arrayContainsAny: list);

extension QueryExtension on Query {
  Query whereIn(String field, List? list) => (list?.isEmpty ?? true)
      ? where(field, whereIn: null)
      : where(field, whereIn: list);

  Query whereNotIn(String field, List? list) => (list?.isEmpty ?? true)
      ? where(field, whereNotIn: null)
      : where(field, whereNotIn: list);

  Query whereArrayContainsAny(String field, List? list) =>
      (list?.isEmpty ?? true)
          ? where(field, arrayContainsAny: null)
          : where(field, arrayContainsAny: list);
}

class FFFirestorePage<T> {
  final List<T> data;
  final Stream<List<T>>? dataStream;
  final QueryDocumentSnapshot? nextPageMarker;

  FFFirestorePage(this.data, this.dataStream, this.nextPageMarker);
}

typedef RecordBuilder<T> = T Function(DocumentSnapshot);

Future<FFFirestorePage<T>> queryCollectionPage<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (nextPageMarker != null) {
    query = query.startAfterDocument(nextPageMarker);
  }
  if (pageSize > 0) {
    query = query.limit(pageSize);
  }
  Stream<QuerySnapshot>? docSnapshotStream;
  QuerySnapshot docSnapshot;
  if (isStream) {
    docSnapshotStream = query.snapshots();
    docSnapshot = await docSnapshotStream.first;
  } else {
    docSnapshot = await query.get();
  }
  final getDocs = (QuerySnapshot s) => s.docs
      .map(
        (d) => recordBuilder(d),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList();
  final data = getDocs(docSnapshot);
  final dataStream = docSnapshotStream?.map(getDocs);
  final nextPageToken = docSnapshot.docs.isEmpty ? null : docSnapshot.docs.last;
  return FFFirestorePage(data, dataStream, nextPageToken);
}

// Creates a Firestore document representing the logged in user if it doesn't yet exist
Future maybeCreateUser(User user) async {
  final userRecord = UserRecord.collection.doc(user.uid);
  final userExists = await userRecord.get().then((u) => u.exists);
  if (userExists) {
    currentUserDocument = await UserRecord.getDocumentOnce(userRecord);
    return;
  }

  final userData = createUserRecordData(
    email: user.email ??
        FirebaseAuth.instance.currentUser?.email ??
        user.providerData.firstOrNull?.email,
    displayName:
        user.displayName ?? FirebaseAuth.instance.currentUser?.displayName,
    photoUrl: user.photoURL,
    uid: user.uid,
    phoneNumber: user.phoneNumber,
    createdTime: ff.getCurrentTimestamp,
  );

  await userRecord.set(userData);
  currentUserDocument = UserRecord.getDocumentFromData(userData, userRecord);
}

Future updateUserDocument({String? email}) async {
  await currentUserDocument?.reference
      .update(createUserRecordData(email: email));
}

// Safely applies orderBy to a query, first checking if collection has any documents
Future<Query> applySafeOrderBy(Query query, String field,
    {bool descending = false}) async {
  try {
    // First check if the collection has any documents
    final snapshot = await query.limit(1).get();
    if (snapshot.docs.isEmpty) {
      // If collection is empty, return the query without ordering
      print('Collection is empty - skipping orderBy for $field');
      return query;
    }

    // Check if the first document has the field we want to order by
    final firstDoc = snapshot.docs.first.data() as Map<String, dynamic>?;
    if (firstDoc == null || !firstDoc.containsKey(field)) {
      print('Field $field not found in document - skipping orderBy');
      return query;
    }

    // If we have documents and the field exists, apply orderBy
    return query.orderBy(field, descending: descending);
  } catch (e) {
    print('Error in applySafeOrderBy: $e');
    // Return the original query if any error occurs
    return query;
  }
}

/// Functions to query CommentsRecords (as a Stream and as a Future).
Future<int> queryCommentsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(CommentsRecord.collection);
  if (limit > 0) {
    query = query.limit(limit);
  }
  final snapshot = await query.count().get();
  return snapshot.count ?? 0;
}

Stream<List<CommentsRecord>> queryCommentsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(CommentsRecord.collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query
      .snapshots()
      .map((s) => s.docs.map((d) => CommentsRecord.fromSnapshot(d)).toList());
}

Future<List<CommentsRecord>> queryCommentsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(CommentsRecord.collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  final snapshot = await query.get();
  return snapshot.docs.map((d) => CommentsRecord.fromSnapshot(d)).toList();
}

/// Functions to query ReportsRecords (as a Stream and as a Future).
Future<int> queryReportsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(_firestore.collection('reports'));
  if (limit > 0) {
    query = query.limit(limit);
  }
  final snapshot = await query.count().get();
  return snapshot.count ?? 0;
}

Stream<List<ReportsRecord>> queryReportsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(_firestore.collection('reports'));
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query.snapshots().map(
      (s) => s.docs.map((d) => ReportsRecord.fromSnapshot(d)).toList());
}

Future<List<ReportsRecord>> queryReportsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(_firestore.collection('reports'));
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  final snapshot = await query.get();
  return snapshot.docs.map((d) => ReportsRecord.fromSnapshot(d)).toList();
}
