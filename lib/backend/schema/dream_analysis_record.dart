import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

class DreamAnalysisRecord extends FirestoreRecord {
  DreamAnalysisRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "mood_analysis" field.
  String? _moodAnalysis;
  String? get moodAnalysis => _moodAnalysis;
  bool hasMoodAnalysis() => _moodAnalysis != null;

  // "mood_evidence" field.
  Map<String, List<String>>? _moodEvidence;
  Map<String, List<String>> get moodEvidence => _moodEvidence ?? const {};
  bool hasMoodEvidence() => _moodEvidence != null;

  // "dream_persona" field.
  String? _dreamPersona;
  String? get dreamPersona => _dreamPersona;
  bool hasDreamPersona() => _dreamPersona != null;

  // "persona_evidence" field.
  Map<String, List<String>>? _personaEvidence;
  Map<String, List<String>> get personaEvidence => _personaEvidence ?? const {};
  bool hasPersonaEvidence() => _personaEvidence != null;

  // "dream_environment" field.
  String? _dreamEnvironment;
  String? get dreamEnvironment => _dreamEnvironment;
  bool hasDreamEnvironment() => _dreamEnvironment != null;

  // "environment_evidence" field.
  Map<String, List<String>>? _environmentEvidence;
  Map<String, List<String>> get environmentEvidence =>
      _environmentEvidence ?? const {};
  bool hasEnvironmentEvidence() => _environmentEvidence != null;

  // "personal_growth_insights" field.
  String? _personalGrowthInsights;
  String? get personalGrowthInsights => _personalGrowthInsights;
  bool hasPersonalGrowthInsights() => _personalGrowthInsights != null;

  // "growth_evidence" field.
  Map<String, List<String>>? _growthEvidence;
  Map<String, List<String>> get growthEvidence => _growthEvidence ?? const {};
  bool hasGrowthEvidence() => _growthEvidence != null;

  // "recommended_actions" field.
  String? _recommendedActions;
  String? get recommendedActions => _recommendedActions;
  bool hasRecommendedActions() => _recommendedActions != null;

  // "action_evidence" field.
  Map<String, List<String>>? _actionEvidence;
  Map<String, List<String>> get actionEvidence => _actionEvidence ?? const {};
  bool hasActionEvidence() => _actionEvidence != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "userref" field.
  DocumentReference? _userref;
  DocumentReference? get userref => _userref;
  bool hasUserref() => _userref != null;

  void _initializeFields() {
    _moodAnalysis = snapshotData['mood_analysis'] as String?;
    _moodEvidence =
        (snapshotData['mood_evidence'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, (value as List).cast<String>()),
    );
    _dreamPersona = snapshotData['dream_persona'] as String?;
    _personaEvidence =
        (snapshotData['persona_evidence'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, (value as List).cast<String>()),
    );
    _dreamEnvironment = snapshotData['dream_environment'] as String?;
    _environmentEvidence =
        (snapshotData['environment_evidence'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, (value as List).cast<String>()),
    );
    _personalGrowthInsights =
        snapshotData['personal_growth_insights'] as String?;
    _growthEvidence =
        (snapshotData['growth_evidence'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, (value as List).cast<String>()),
    );
    _recommendedActions = snapshotData['recommended_actions'] as String?;
    _actionEvidence =
        (snapshotData['action_evidence'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, (value as List).cast<String>()),
    );
    _date = snapshotData['date'] as DateTime?;
    _userref = snapshotData['userref'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('dream_analysis');

  static Stream<DreamAnalysisRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DreamAnalysisRecord.fromSnapshot(s));

  static Future<DreamAnalysisRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DreamAnalysisRecord.fromSnapshot(s));

  static DreamAnalysisRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DreamAnalysisRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DreamAnalysisRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DreamAnalysisRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DreamAnalysisRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DreamAnalysisRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}
