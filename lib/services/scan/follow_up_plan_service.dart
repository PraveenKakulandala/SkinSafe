import '../../shared/models/scan_record.dart';

class FollowUpPlan {
  final String patientName;
  final String bodyArea;
  final String lesionLabel;
  final DateTime basedOnDate;
  final DateTime nextReviewDate;
  final String urgencyLabel;
  final String summary;

  const FollowUpPlan({
    required this.patientName,
    required this.bodyArea,
    required this.lesionLabel,
    required this.basedOnDate,
    required this.nextReviewDate,
    required this.urgencyLabel,
    required this.summary,
  });

  bool get isDueNow => !nextReviewDate.isAfter(DateTime.now());
}

class FollowUpPlanService {
  const FollowUpPlanService();

  FollowUpPlan? buildFromRecords(List<ScanRecord> records) {
    if (records.isEmpty) {
      return null;
    }

    final sorted = List<ScanRecord>.from(records)
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    final reminderRecords =
        sorted.where((record) => record.hasFollowUpReminder).toList()..sort(
          (a, b) => a.followUpReminderDate!.compareTo(b.followUpReminderDate!),
        );
    if (reminderRecords.isNotEmpty) {
      return _buildFromSavedReminder(reminderRecords.first);
    }

    return null;
  }

  FollowUpPlan _buildFromSavedReminder(ScanRecord record) {
    final nextReviewDate = record.followUpReminderDate!;
    final today = DateTime.now();
    final daysUntilReview = DateTime(
      nextReviewDate.year,
      nextReviewDate.month,
      nextReviewDate.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    final urgencyLabel = daysUntilReview <= 0
        ? 'Follow-up due now'
        : daysUntilReview <= 3
        ? 'Follow-up due soon'
        : 'Follow-up scheduled';
    final summary = record.followUpReminderReason.isNotEmpty
        ? record.followUpReminderReason
        : 'Re-scan the same lesion with the same body area and spot label for a clearer comparison.';

    return FollowUpPlan(
      patientName: record.patientName,
      bodyArea: record.bodyArea,
      lesionLabel: record.location,
      basedOnDate: record.capturedAt,
      nextReviewDate: nextReviewDate,
      urgencyLabel: urgencyLabel,
      summary: summary,
    );
  }
}
