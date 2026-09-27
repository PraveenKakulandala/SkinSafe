import '../../shared/models/scan_record.dart';

class LesionComparisonSnapshot {
  final ScanRecord latest;
  final ScanRecord? previous;

  const LesionComparisonSnapshot({
    required this.latest,
    required this.previous,
  });

  bool get hasPrevious => previous != null;

  double? get riskDelta {
    if (latest.riskScore == null || previous?.riskScore == null) {
      return null;
    }
    return latest.riskScore! - previous!.riskScore!;
  }

  double? get coverageDelta {
    if (latest.lesionCoveragePercent == null ||
        previous?.lesionCoveragePercent == null) {
      return null;
    }
    return latest.lesionCoveragePercent! - previous!.lesionCoveragePercent!;
  }
}

class LesionTrackingService {
  const LesionTrackingService();

  List<String> lesionLabelsFor(List<ScanRecord> records) {
    return records
        .map((record) => record.location.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<ScanRecord> timelineForLesion({
    required List<ScanRecord> records,
    required String lesionLabel,
  }) {
    return records
        .where((record) => record.location.trim() == lesionLabel.trim())
        .toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  }

  LesionComparisonSnapshot? buildComparison({
    required List<ScanRecord> records,
    required String lesionLabel,
  }) {
    final timeline = timelineForLesion(records: records, lesionLabel: lesionLabel);
    if (timeline.isEmpty) {
      return null;
    }

    return LesionComparisonSnapshot(
      latest: timeline.first,
      previous: timeline.length > 1 ? timeline[1] : null,
    );
  }

  ScanRecord? latestFollowUpReference({
    required List<ScanRecord> records,
    required String patientName,
    required String bodyArea,
    required String lesionLabel,
  }) {
    final normalizedPatient = patientName.trim().toLowerCase();
    final normalizedArea = bodyArea.trim().toLowerCase();
    final normalizedLesion = lesionLabel.trim().toLowerCase();

    final matching = records
        .where(
          (record) =>
              record.patientName.trim().toLowerCase() == normalizedPatient &&
              record.bodyArea.trim().toLowerCase() == normalizedArea &&
              record.location.trim().toLowerCase() == normalizedLesion,
        )
        .toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

    return matching.isEmpty ? null : matching.first;
  }
}
