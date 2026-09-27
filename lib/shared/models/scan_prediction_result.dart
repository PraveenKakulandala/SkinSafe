import 'dart:convert';
import 'dart:typed_data';

class ScanPredictionResult {
  final String predictedClass;
  final double melanomaProbability;
  final double confidence;
  final String status;
  final String summary;
  final String recommendation;
  final String modelVersion;
  final Uint8List? illustrationBytes;
  final String illustrationMimeType;
  final String illustrationFilename;
  final double lesionCoveragePercent;
  final String visualizationSummary;
  final double imageQualityScore;
  final String imageQualityStatus;
  final String imageQualitySummary;
  final List<String> imageQualityWarnings;
  final String preprocessingSummary;

  const ScanPredictionResult({
    required this.predictedClass,
    required this.melanomaProbability,
    required this.confidence,
    required this.status,
    required this.summary,
    required this.recommendation,
    required this.modelVersion,
    this.illustrationBytes,
    this.illustrationMimeType = 'image/png',
    this.illustrationFilename = 'lesion_illustration.png',
    this.lesionCoveragePercent = 0,
    this.visualizationSummary = '',
    this.imageQualityScore = 0,
    this.imageQualityStatus = '',
    this.imageQualitySummary = '',
    this.imageQualityWarnings = const <String>[],
    this.preprocessingSummary = '',
  });

  double get melanomaProbabilityPercent => melanomaProbability * 100;

  double get confidencePercent => confidence * 100;

  bool get hasIllustration =>
      illustrationBytes != null && illustrationBytes!.isNotEmpty;

  factory ScanPredictionResult.fromJson(Map<String, dynamic> json) {
    return ScanPredictionResult(
      predictedClass: (json['predicted_class'] as String?) ?? 'Unknown',
      melanomaProbability: _asDouble(json['melanoma_probability']),
      confidence: _asDouble(json['confidence']),
      status: (json['status'] as String?) ?? 'Analysis unavailable',
      summary: (json['summary'] as String?) ?? '',
      recommendation: (json['recommendation'] as String?) ?? '',
      modelVersion: (json['model_version'] as String?) ?? 'unknown',
      illustrationBytes: _decodeBase64Bytes(json['illustration_base64']),
      illustrationMimeType:
          (json['illustration_mime_type'] as String?) ?? 'image/png',
      illustrationFilename:
          (json['illustration_filename'] as String?) ??
          'lesion_illustration.png',
      lesionCoveragePercent: _asDouble(json['lesion_coverage_percent']),
      visualizationSummary: (json['visualization_summary'] as String?) ?? '',
      imageQualityScore: _asDouble(json['image_quality_score']),
      imageQualityStatus: (json['image_quality_status'] as String?) ?? '',
      imageQualitySummary: (json['image_quality_summary'] as String?) ?? '',
      imageQualityWarnings: _asStringList(json['image_quality_warnings']),
      preprocessingSummary: (json['preprocessing_summary'] as String?) ?? '',
    );
  }

  static double _asDouble(Object? value) {
    return switch (value) {
      num number => number.toDouble(),
      _ => 0,
    };
  }

  static Uint8List? _decodeBase64Bytes(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  static List<String> _asStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
