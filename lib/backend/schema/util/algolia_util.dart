import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/lat_lng.dart';

class AlgoliaObjectSnapshot {
  final Map<String, dynamic> data;
  final DocumentReference reference;

  AlgoliaObjectSnapshot(this.data, this.reference);
}

Future<List<AlgoliaObjectSnapshot>> searchAlgolia<T>({
  required String searchTerm,
  required String searchObj,
  FutureOr<LatLng>? location,
  int? maxResults,
  double? searchRadiusMeters,
  bool useFrontendSearch = false,
}) async {
  // TODO: Implement actual Algolia search
  // For now, return empty list
  return [];
}

String indexCommentsRecord = 'comments';
