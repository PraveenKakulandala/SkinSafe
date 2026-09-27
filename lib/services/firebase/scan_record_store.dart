import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/scan_record.dart';

abstract interface class ScanRecordStore {
  Future<List<ScanRecord>> fetchRecords(String uid);
  Future<void> saveRecord({required String uid, required ScanRecord record});
}

class FirestoreScanRecordStore implements ScanRecordStore {
  final FirebaseFirestore _firestore;

  FirestoreScanRecordStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ScanRecord>> fetchRecords(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('scan_records')
        .orderBy('capturedAt', descending: true)
        .get();

    return snapshot.docs.map((document) {
      final data = document.data();
      final capturedAtValue = data['capturedAt'];
      final followUpReminderDateValue = data['followUpReminderDate'];

      return ScanRecord(
        id: document.id,
        patientName: (data['patientName'] as String?) ?? 'Unknown patient',
        patientAge: (data['patientAge'] as String?) ?? '',
        patientContact: (data['patientContact'] as String?) ?? '',
        title: (data['title'] as String?) ?? 'Saved scan',
        capturedAt: switch (capturedAtValue) {
          Timestamp timestamp => timestamp.toDate(),
          DateTime dateTime => dateTime,
          _ => DateTime.now(),
        },
        bodyArea:
            (data['bodyArea'] as String?) ??
            (data['location'] as String?) ??
            'Unspecified',
        location: (data['location'] as String?) ?? 'Unknown location',
        captureSource: (data['captureSource'] as String?) ?? 'Unknown',
        predictedClass: (data['predictedClass'] as String?) ?? 'Unknown',
        modelVersion: (data['modelVersion'] as String?) ?? 'unknown',
        status: (data['status'] as String?) ?? 'Awaiting AI analysis',
        riskScore: (data['riskScore'] as num?)?.toDouble(),
        summary: (data['summary'] as String?) ?? '',
        note: (data['note'] as String?) ?? '',
        nextStep: (data['nextStep'] as String?) ?? '',
        recentChangeObserved: (data['recentChangeObserved'] as bool?) ?? false,
        familyHistoryReported:
            (data['familyHistoryReported'] as bool?) ?? false,
        priorSkinCancerReported:
            (data['priorSkinCancerReported'] as bool?) ?? false,
        newOrGrowingLesionObserved:
            (data['newOrGrowingLesionObserved'] as bool?) ?? false,
        borderColorChangeObserved:
            (data['borderColorChangeObserved'] as bool?) ?? false,
        lesionSymptomsObserved:
            (data['lesionSymptomsObserved'] as bool?) ?? false,
        questionnaireSummary: (data['questionnaireSummary'] as String?) ?? '',
        baselineRiskSummary: (data['baselineRiskSummary'] as String?) ?? '',
        combinedRiskSummary: (data['combinedRiskSummary'] as String?) ?? '',
        savedAssetLabel:
            (data['savedAssetLabel'] as String?) ??
            'Raw scan photo and generated lesion illustration',
        lesionCoveragePercent: (data['lesionCoveragePercent'] as num?)
            ?.toDouble(),
        imageQualityScore: (data['imageQualityScore'] as num?)?.toDouble(),
        imageQualityStatus: (data['imageQualityStatus'] as String?) ?? '',
        imageQualitySummary: (data['imageQualitySummary'] as String?) ?? '',
        preprocessingSummary: (data['preprocessingSummary'] as String?) ?? '',
        followUpReminderEnabled:
            (data['followUpReminderEnabled'] as bool?) ?? false,
        followUpReminderDate: switch (followUpReminderDateValue) {
          Timestamp timestamp => timestamp.toDate(),
          DateTime dateTime => dateTime,
          _ => null,
        },
        followUpReminderDays: (data['followUpReminderDays'] as num?)?.toInt(),
        followUpReminderReason:
            (data['followUpReminderReason'] as String?) ?? '',
        rawImageUrl: (data['rawImageUrl'] as String?) ?? '',
        rawStoragePath: (data['rawStoragePath'] as String?) ?? '',
        illustrationImageUrl:
            (data['illustrationImageUrl'] as String?) ??
            (data['imageUrl'] as String?) ??
            '',
        illustrationStoragePath:
            (data['illustrationStoragePath'] as String?) ??
            (data['storagePath'] as String?) ??
            '',
      );
    }).toList();
  }

  @override
  Future<void> saveRecord({
    required String uid,
    required ScanRecord record,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('scan_records')
        .doc(record.id)
        .set({
          'patientName': record.patientName,
          'patientAge': record.patientAge,
          'patientContact': record.patientContact,
          'title': record.title,
          'capturedAt': Timestamp.fromDate(record.capturedAt),
          'bodyArea': record.bodyArea,
          'location': record.location,
          'captureSource': record.captureSource,
          'predictedClass': record.predictedClass,
          'modelVersion': record.modelVersion,
          'status': record.status,
          'riskScore': record.riskScore,
          'summary': record.summary,
          'note': record.note,
          'nextStep': record.nextStep,
          'recentChangeObserved': record.recentChangeObserved,
          'familyHistoryReported': record.familyHistoryReported,
          'priorSkinCancerReported': record.priorSkinCancerReported,
          'newOrGrowingLesionObserved': record.newOrGrowingLesionObserved,
          'borderColorChangeObserved': record.borderColorChangeObserved,
          'lesionSymptomsObserved': record.lesionSymptomsObserved,
          'questionnaireSummary': record.questionnaireSummary,
          'baselineRiskSummary': record.baselineRiskSummary,
          'combinedRiskSummary': record.combinedRiskSummary,
          'savedAssetLabel': record.savedAssetLabel,
          'lesionCoveragePercent': record.lesionCoveragePercent,
          'imageQualityScore': record.imageQualityScore,
          'imageQualityStatus': record.imageQualityStatus,
          'imageQualitySummary': record.imageQualitySummary,
          'preprocessingSummary': record.preprocessingSummary,
          'followUpReminderEnabled': record.followUpReminderEnabled,
          'followUpReminderDate': record.followUpReminderDate == null
              ? null
              : Timestamp.fromDate(record.followUpReminderDate!),
          'followUpReminderDays': record.followUpReminderDays,
          'followUpReminderReason': record.followUpReminderReason,
          'rawImageUrl': record.rawImageUrl,
          'rawStoragePath': record.rawStoragePath,
          'illustrationImageUrl': record.illustrationImageUrl,
          'illustrationStoragePath': record.illustrationStoragePath,
          // Legacy fields remain populated so older builds still have one
          // preview image to render.
          'imageUrl': record.imageUrl,
          'storagePath': record.storagePath,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}

class MemoryScanRecordStore implements ScanRecordStore {
  final Map<String, List<ScanRecord>> _recordsByUser =
      <String, List<ScanRecord>>{};

  @override
  Future<List<ScanRecord>> fetchRecords(String uid) async {
    final records = _recordsByUser[uid] ?? const <ScanRecord>[];
    return List<ScanRecord>.from(records)
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  }

  @override
  Future<void> saveRecord({
    required String uid,
    required ScanRecord record,
  }) async {
    final records = _recordsByUser.putIfAbsent(uid, () => <ScanRecord>[]);
    records.removeWhere((existingRecord) => existingRecord.id == record.id);
    records.add(record);
  }
}
