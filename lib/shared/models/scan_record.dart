class ScanRecord {
  final String id;
  final String patientName;
  final String patientAge;
  final String patientContact;
  final String title;
  final DateTime capturedAt;
  final String bodyArea;
  final String location;
  final String captureSource;
  final String predictedClass;
  final String modelVersion;
  final String status;
  final double? riskScore;
  final String summary;
  final String note;
  final String nextStep;
  final bool recentChangeObserved;
  final bool familyHistoryReported;
  final bool priorSkinCancerReported;
  final bool newOrGrowingLesionObserved;
  final bool borderColorChangeObserved;
  final bool lesionSymptomsObserved;
  final String questionnaireSummary;
  final String baselineRiskSummary;
  final String combinedRiskSummary;
  final String savedAssetLabel;
  final double? lesionCoveragePercent;
  final double? imageQualityScore;
  final String imageQualityStatus;
  final String imageQualitySummary;
  final String preprocessingSummary;
  final bool followUpReminderEnabled;
  final DateTime? followUpReminderDate;
  final int? followUpReminderDays;
  final String followUpReminderReason;
  final String rawImageUrl;
  final String rawStoragePath;
  final String illustrationImageUrl;
  final String illustrationStoragePath;

  const ScanRecord({
    required this.id,
    required this.patientName,
    required this.patientAge,
    required this.patientContact,
    required this.title,
    required this.capturedAt,
    required this.bodyArea,
    required this.location,
    required this.captureSource,
    required this.predictedClass,
    required this.modelVersion,
    required this.status,
    required this.riskScore,
    required this.summary,
    required this.note,
    required this.nextStep,
    required this.recentChangeObserved,
    required this.familyHistoryReported,
    required this.priorSkinCancerReported,
    this.newOrGrowingLesionObserved = false,
    this.borderColorChangeObserved = false,
    this.lesionSymptomsObserved = false,
    required this.questionnaireSummary,
    this.baselineRiskSummary = '',
    this.combinedRiskSummary = '',
    required this.savedAssetLabel,
    required this.lesionCoveragePercent,
    this.imageQualityScore,
    this.imageQualityStatus = '',
    this.imageQualitySummary = '',
    this.preprocessingSummary = '',
    this.followUpReminderEnabled = false,
    this.followUpReminderDate,
    this.followUpReminderDays,
    this.followUpReminderReason = '',
    required this.rawImageUrl,
    required this.rawStoragePath,
    required this.illustrationImageUrl,
    required this.illustrationStoragePath,
  });

  bool get hasRawImage => rawImageUrl.isNotEmpty;

  bool get hasIllustrationImage => illustrationImageUrl.isNotEmpty;

  String get imageUrl =>
      illustrationImageUrl.isNotEmpty ? illustrationImageUrl : rawImageUrl;

  String get storagePath => illustrationStoragePath.isNotEmpty
      ? illustrationStoragePath
      : rawStoragePath;

  bool get hasFollowUpReminder =>
      followUpReminderEnabled && followUpReminderDate != null;

  bool get isFollowUpReminderDue =>
      hasFollowUpReminder && !followUpReminderDate!.isAfter(DateTime.now());
}
