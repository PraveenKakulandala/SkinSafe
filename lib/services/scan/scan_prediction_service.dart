import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../../shared/models/scan_prediction_result.dart';
import '../../shared/models/selected_scan_image.dart';

abstract interface class ScanPredictionService {
  Future<ScanPredictionResult> predictScan({required SelectedScanImage image});
}

class ScanPredictionServiceException implements Exception {
  final String message;
  final List<Uri> attemptedEndpoints;
  final Object? cause;

  const ScanPredictionServiceException(
    this.message, {
    this.attemptedEndpoints = const <Uri>[],
    this.cause,
  });

  @override
  String toString() => message;
}

class HttpScanPredictionService implements ScanPredictionService {
  final List<Uri> endpoints;
  final http.Client _client;
  final Duration timeout;

  HttpScanPredictionService({
    Uri? endpoint,
    List<Uri>? endpoints,
    http.Client? client,
    Duration? timeout,
  }) : endpoints = endpoints ?? _defaultEndpoints(endpoint),
       _client = client ?? http.Client(),
       timeout = timeout ?? const Duration(seconds: 12);

  static List<Uri> _defaultEndpoints(Uri? endpoint) {
    if (endpoint != null) {
      return <Uri>[endpoint];
    }

    final configuredEndpoint = const String.fromEnvironment(
      'SKINSAFE_PREDICTION_URL',
    ).trim();
    if (configuredEndpoint.isNotEmpty) {
      return <Uri>[Uri.parse(configuredEndpoint)];
    }

    if (kIsWeb) {
      return <Uri>[Uri.parse('http://127.0.0.1:8000/predict')];
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => <Uri>[
        Uri.parse('http://10.0.2.2:8000/predict'),
        Uri.parse('http://127.0.0.1:8000/predict'),
      ],
      _ => <Uri>[Uri.parse('http://127.0.0.1:8000/predict')],
    };
  }

  @override
  Future<ScanPredictionResult> predictScan({
    required SelectedScanImage image,
  }) async {
    Object? lastError;
    final attemptedEndpoints = <Uri>[];

    for (final endpoint in endpoints) {
      attemptedEndpoints.add(endpoint);
      try {
        return await _predictAgainstEndpoint(endpoint: endpoint, image: image);
      } catch (error) {
        lastError = error;
      }
    }

    throw ScanPredictionServiceException(
      'Could not reach the local prediction API.',
      attemptedEndpoints: attemptedEndpoints,
      cause: lastError,
    );
  }

  Future<ScanPredictionResult> _predictAgainstEndpoint({
    required Uri endpoint,
    required SelectedScanImage image,
  }) async {
    final request = http.MultipartRequest('POST', endpoint)
      ..headers['Accept'] = 'application/json'
      ..files.add(
        http.MultipartFile.fromBytes('file', image.bytes, filename: image.name),
      );

    final streamedResponse = await _client.send(request).timeout(timeout);
    final response = await http.Response.fromStream(
      streamedResponse,
    ).timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Prediction API returned ${response.statusCode}: ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'Prediction API returned an invalid payload.',
      );
    }

    return ScanPredictionResult.fromJson(body);
  }
}

class OnDeviceTfliteScanPredictionService implements ScanPredictionService {
  final String modelAssetPath;
  final String configAssetPath;

  Future<_LoadedTfliteModel>? _loadedModel;

  OnDeviceTfliteScanPredictionService({
    this.modelAssetPath = 'ml/output/melanoma_risk_classifier.tflite',
    this.configAssetPath = 'ml/output/model_config.json',
  });

  @override
  Future<ScanPredictionResult> predictScan({
    required SelectedScanImage image,
  }) async {
    final decodedImage = img.decodeImage(image.bytes);
    if (decodedImage == null) {
      throw const ScanPredictionServiceException(
        'The selected image could not be decoded.',
      );
    }

    final orientedImage = img.bakeOrientation(decodedImage);
    final model = await _loadModel();
    final illustration = _createLesionIllustration(orientedImage);
    final quality = _evaluateImageQuality(
      orientedImage,
      lesionCoveragePercent: illustration.coveragePercent,
      preprocessingSummary: model.config.preprocessingSummary,
    );
    final preprocessedImage = _preprocessForModel(
      orientedImage,
      config: model.config,
    );
    final input = _buildModelInput(
      preprocessedImage,
      width: model.config.imageWidth,
      height: model.config.imageHeight,
    );
    final output = List.generate(1, (_) => List<double>.filled(1, 0));

    model.interpreter.run(input, output);

    final melanomaProbability = output.first.first.clamp(0.0, 1.0);
    final nonMelanomaProbability = 1.0 - melanomaProbability;
    final confidence = math.max(melanomaProbability, nonMelanomaProbability);
    final predictedClass = _buildPredictedClass(
      melanomaProbability,
      config: model.config,
      quality: quality,
    );
    final message = _buildPatientMessage(
      melanomaProbability,
      config: model.config,
      quality: quality,
    );

    return ScanPredictionResult(
      predictedClass: predictedClass,
      melanomaProbability: melanomaProbability,
      confidence: confidence,
      status: message.status,
      summary: message.summary,
      recommendation: _buildRecommendationWithQuality(
        message.recommendation,
        quality,
      ),
      modelVersion: model.config.modelVersion,
      illustrationBytes: illustration.bytes,
      illustrationFilename: 'lesion_illustration.png',
      lesionCoveragePercent: illustration.coveragePercent,
      visualizationSummary:
          'A lesion-shape illustration was generated on this device from the selected scan photo.',
      imageQualityScore: quality.score,
      imageQualityStatus: quality.status,
      imageQualitySummary: quality.summary,
      imageQualityWarnings: quality.warnings,
      preprocessingSummary: quality.preprocessingSummary,
    );
  }

  Future<_LoadedTfliteModel> _loadModel() {
    return _loadedModel ??= _createLoadedModel();
  }

  Future<_LoadedTfliteModel> _createLoadedModel() async {
    final config = await _TfliteModelConfig.load(configAssetPath);
    final options = tfl.InterpreterOptions()..threads = 2;
    final interpreter = await tfl.Interpreter.fromAsset(
      modelAssetPath,
      options: options,
    );
    interpreter.allocateTensors();
    return _LoadedTfliteModel(interpreter: interpreter, config: config);
  }

  img.Image _preprocessForModel(
    img.Image sourceImage, {
    required _TfliteModelConfig config,
  }) {
    final mode = config.preprocessingMode;
    var preparedImage = img.Image.from(sourceImage);

    if (mode.contains('center_crop')) {
      preparedImage = _centerCropSquare(preparedImage);
    }

    if (mode == 'center_crop_sharpen') {
      preparedImage = _applyUnsharpMask(preparedImage);
    }

    return img.copyResize(
      preparedImage,
      width: config.imageWidth,
      height: config.imageHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  img.Image _centerCropSquare(img.Image sourceImage) {
    final side = math.min(sourceImage.width, sourceImage.height);
    return img.copyCrop(
      sourceImage,
      x: (sourceImage.width - side) ~/ 2,
      y: (sourceImage.height - side) ~/ 2,
      width: side,
      height: side,
    );
  }

  img.Image _applyUnsharpMask(img.Image sourceImage) {
    final original = img.Image.from(sourceImage);
    final blurred = img.gaussianBlur(img.Image.from(sourceImage), radius: 1);
    final sharpened = img.Image.from(sourceImage);

    const amount = 1.2;
    const threshold = 3.0;
    for (var y = 0; y < sharpened.height; y++) {
      for (var x = 0; x < sharpened.width; x++) {
        final sourcePixel = original.getPixel(x, y);
        final blurredPixel = blurred.getPixel(x, y);

        sharpened.setPixelRgb(
          x,
          y,
          _unsharpChannel(sourcePixel.r, blurredPixel.r, amount, threshold),
          _unsharpChannel(sourcePixel.g, blurredPixel.g, amount, threshold),
          _unsharpChannel(sourcePixel.b, blurredPixel.b, amount, threshold),
        );
      }
    }

    return sharpened;
  }

  int _unsharpChannel(
    num source,
    num blurred,
    double amount,
    double threshold,
  ) {
    final difference = source.toDouble() - blurred.toDouble();
    if (difference.abs() < threshold) {
      return source.round().clamp(0, 255).toInt();
    }

    return (source + (difference * amount)).round().clamp(0, 255).toInt();
  }

  List<List<List<List<double>>>> _buildModelInput(
    img.Image sourceImage, {
    required int width,
    required int height,
  }) {
    final resized = img.copyResize(
      sourceImage,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );

    return <List<List<List<double>>>>[
      List.generate(height, (y) {
        return List.generate(width, (x) {
          final pixel = resized.getPixel(x, y);
          return <double>[
            pixel.r.toDouble(),
            pixel.g.toDouble(),
            pixel.b.toDouble(),
          ];
        });
      }),
    ];
  }

  String _buildPredictedClass(
    double melanomaProbability, {
    required _TfliteModelConfig config,
    required _ScanImageQualityAssessment quality,
  }) {
    if (quality.isRetakeRecommended &&
        melanomaProbability < config.cautionThreshold) {
      return 'Image quality limited';
    }

    if (melanomaProbability >= config.specialistThreshold) {
      return 'Strong melanoma-like pattern';
    }

    if (melanomaProbability >= config.cautionThreshold) {
      return 'Melanoma-like pattern';
    }

    if (melanomaProbability >= config.borderlineThreshold) {
      return 'Uncertain pattern';
    }

    return 'Non-melanoma pattern';
  }

  _PatientPredictionMessage _buildPatientMessage(
    double melanomaProbability, {
    required _TfliteModelConfig config,
    required _ScanImageQualityAssessment quality,
  }) {
    if (quality.isRetakeRecommended &&
        melanomaProbability < config.cautionThreshold) {
      return const _PatientPredictionMessage(
        status: 'Retake recommended',
        summary:
            'The photo quality is not strong enough for a confident low-risk review.',
        recommendation:
            'Retake the scan in bright, even lighting. Keep the phone steady, fill the frame with the lesion area, and avoid heavy blur or shadow.',
      );
    }

    if (melanomaProbability >= config.specialistThreshold) {
      return const _PatientPredictionMessage(
        status: 'Specialist review recommended',
        summary:
            'The model detected a strong melanoma-like pattern in this image.',
        recommendation:
            'Please arrange dermatologist review as soon as possible. This app result supports decision-making but is not a medical diagnosis.',
      );
    }

    if (melanomaProbability >= config.cautionThreshold) {
      return const _PatientPredictionMessage(
        status: 'Caution advised',
        summary: 'The model found features that deserve closer review.',
        recommendation:
            'Repeat the scan under clear lighting if needed and seek dermatologist review, especially if the lesion is changing in shape, color, border, or symptoms.',
      );
    }

    if (melanomaProbability >= config.borderlineThreshold) {
      return const _PatientPredictionMessage(
        status: 'Monitor closely',
        summary:
            'The model found a borderline pattern, but not enough to raise a stronger warning.',
        recommendation:
            'Keep a dated record and repeat the scan if the lesion changes. Seek clinician review if it grows, bleeds, itches, changes color, or looks different from nearby moles.',
      );
    }

    return const _PatientPredictionMessage(
      status: 'Low melanoma risk',
      summary:
          'The model found a stronger match with non-melanoma examples than melanoma examples.',
      recommendation:
          'Continue monitoring the lesion and repeat the scan if the area changes over time. Seek clinician review if you remain concerned.',
    );
  }

  String _buildRecommendationWithQuality(
    String baseRecommendation,
    _ScanImageQualityAssessment quality,
  ) {
    if (quality.warnings.isEmpty || quality.isRetakeRecommended) {
      return baseRecommendation;
    }

    final warningText = quality.warnings.take(2).join(' ');
    return '$baseRecommendation Photo quality note: $warningText';
  }

  _ScanImageQualityAssessment _evaluateImageQuality(
    img.Image sourceImage, {
    required double lesionCoveragePercent,
    required String preprocessingSummary,
  }) {
    final stats = _measureImageStats(sourceImage);
    final minSide = math.min(sourceImage.width, sourceImage.height);
    final warnings = <String>[];
    var score = 100.0;

    void applyPenalty(bool condition, double penalty, String warning) {
      if (!condition) {
        return;
      }
      score -= penalty;
      warnings.add(warning);
    }

    if (minSide < 224) {
      applyPenalty(
        true,
        35,
        'Image resolution is too low for a reliable scan.',
      );
    } else if (minSide < 512) {
      applyPenalty(
        true,
        12,
        'A closer, higher-resolution image would improve the scan.',
      );
    }

    if (stats.brightness < 0.18) {
      applyPenalty(true, 24, 'The photo looks too dark.');
    } else if (stats.brightness > 0.88) {
      applyPenalty(true, 24, 'The photo looks overexposed.');
    } else if (stats.brightness < 0.28) {
      applyPenalty(true, 10, 'The lighting is a little dim.');
    } else if (stats.brightness > 0.80) {
      applyPenalty(true, 10, 'The lighting is a little too bright.');
    }

    if (stats.contrast < 0.045) {
      applyPenalty(true, 20, 'The lesion edges are difficult to separate.');
    } else if (stats.contrast < 0.075) {
      applyPenalty(true, 9, 'The image has low contrast.');
    }

    if (stats.sharpnessVariance < 18) {
      applyPenalty(true, 28, 'The photo appears blurry.');
    } else if (stats.sharpnessVariance < 45) {
      applyPenalty(true, 12, 'A steadier photo would improve sharpness.');
    }

    if (lesionCoveragePercent < 1.0) {
      applyPenalty(true, 24, 'The lesion is hard to isolate in this image.');
    } else if (lesionCoveragePercent < 3.0) {
      applyPenalty(
        true,
        12,
        'Move a little closer so the lesion is easier to review.',
      );
    } else if (lesionCoveragePercent > 82.0) {
      applyPenalty(true, 12, 'The lesion area may be cropped too tightly.');
    }

    final clampedScore = score.clamp(0.0, 100.0).toDouble();
    final status = clampedScore >= 80
        ? 'Good photo quality'
        : clampedScore >= 65
        ? 'Usable with caution'
        : 'Retake recommended';
    final roundedScore = clampedScore.round();
    final summary = warnings.isEmpty
        ? 'Quality score $roundedScore/100. Lighting, sharpness, and lesion visibility look acceptable.'
        : 'Quality score $roundedScore/100. ${warnings.first}';

    return _ScanImageQualityAssessment(
      score: clampedScore,
      status: status,
      summary: summary,
      warnings: List<String>.unmodifiable(warnings),
      preprocessingSummary: preprocessingSummary,
    );
  }

  _ImageQualityStats _measureImageStats(img.Image sourceImage) {
    final longestSide = math.max(sourceImage.width, sourceImage.height);
    final workingImage = longestSide <= 320
        ? sourceImage
        : img.copyResize(
            sourceImage,
            width: sourceImage.width >= sourceImage.height ? 320 : null,
            height: sourceImage.height > sourceImage.width ? 320 : null,
            interpolation: img.Interpolation.linear,
          );
    final width = workingImage.width;
    final height = workingImage.height;
    final luminanceValues = List<double>.filled(width * height, 0);
    var sum = 0.0;
    var sumSquares = 0.0;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        final pixel = workingImage.getPixel(x, y);
        final luminance =
            ((0.299 * pixel.r) + (0.587 * pixel.g) + (0.114 * pixel.b))
                .toDouble();
        luminanceValues[index] = luminance;
        sum += luminance;
        sumSquares += luminance * luminance;
      }
    }

    final pixelCount = luminanceValues.length;
    if (pixelCount == 0) {
      return const _ImageQualityStats(
        brightness: 0,
        contrast: 0,
        sharpnessVariance: 0,
      );
    }

    final mean = sum / pixelCount;
    final variance = (sumSquares / pixelCount) - (mean * mean);
    var laplacianSumSquares = 0.0;
    var laplacianCount = 0;

    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final index = y * width + x;
        final laplacian =
            (4 * luminanceValues[index]) -
            luminanceValues[index - 1] -
            luminanceValues[index + 1] -
            luminanceValues[index - width] -
            luminanceValues[index + width];
        laplacianSumSquares += laplacian * laplacian;
        laplacianCount++;
      }
    }

    return _ImageQualityStats(
      brightness: mean / 255.0,
      contrast: math.sqrt(math.max(variance, 0)) / 255.0,
      sharpnessVariance: laplacianCount == 0
          ? 0
          : laplacianSumSquares / laplacianCount,
    );
  }

  _GeneratedIllustration _createLesionIllustration(img.Image sourceImage) {
    final longestSide = math.max(sourceImage.width, sourceImage.height);
    final scale = longestSide <= 512 ? 1.0 : 512 / longestSide;
    final working = scale == 1.0
        ? sourceImage
        : img.copyResize(
            sourceImage,
            width: (sourceImage.width * scale).round(),
            height: (sourceImage.height * scale).round(),
            interpolation: img.Interpolation.linear,
          );
    final width = working.width;
    final height = working.height;
    final totalPixels = width * height;
    final scores = List<double>.filled(totalPixels, 0);
    final grayscaleValues = List<double>.filled(totalPixels, 0);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        final pixel = working.getPixel(x, y);
        final red = pixel.r.toDouble() / 255.0;
        final green = pixel.g.toDouble() / 255.0;
        final blue = pixel.b.toDouble() / 255.0;
        grayscaleValues[index] = 0.299 * red + 0.587 * green + 0.114 * blue;
      }
    }

    final skinReference = _percentile(grayscaleValues, 72);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        final pixel = working.getPixel(x, y);
        final red = pixel.r.toDouble() / 255.0;
        final green = pixel.g.toDouble() / 255.0;
        final blue = pixel.b.toDouble() / 255.0;
        final darkness =
            ((skinReference - grayscaleValues[index]) /
                    math.max(skinReference, 0.001))
                .clamp(0.0, 1.0);
        final redness = (red - ((green + blue) / 2.0)).clamp(0.0, 1.0);
        scores[index] = (0.76 * darkness) + (0.24 * redness);
      }
    }

    var bestMask = <bool>[];
    var bestCount = 0;
    var bestDistance = double.infinity;
    for (final percentile in const <double>[90, 87, 84, 81, 78, 75]) {
      final threshold = _percentile(scores, percentile);
      final mask = List<bool>.generate(
        totalPixels,
        (index) => scores[index] >= threshold,
      );
      final component = _largestComponent(mask, width, height);
      if (component.count == 0) {
        continue;
      }

      final coverage = component.count / totalPixels;
      final distance = (coverage - 0.18).abs();
      if (distance < bestDistance) {
        bestMask = component.mask;
        bestCount = component.count;
        bestDistance = distance;
      }
    }

    if (bestMask.isEmpty) {
      bestMask = List<bool>.generate(totalPixels, (index) => false);
    }

    final illustration = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        if (!bestMask[index]) {
          illustration.setPixelRgb(x, y, 248, 243, 238);
          continue;
        }

        final mix = (0.35 + (0.65 * scores[index])).clamp(0.0, 1.0);
        var red = _lerp(191, 89, mix);
        var green = _lerp(111, 43, mix);
        var blue = _lerp(83, 31, mix);

        if (_isContour(bestMask, width, height, x, y)) {
          red = 30;
          green = 109;
          blue = 216;
        } else if (_isInnerPixel(bestMask, width, height, x, y)) {
          red = _lerp(red, 61, 0.22);
          green = _lerp(green, 27, 0.22);
          blue = _lerp(blue, 18, 0.22);
        }

        illustration.setPixelRgb(x, y, red, green, blue);
      }
    }

    return _GeneratedIllustration(
      bytes: Uint8List.fromList(img.encodePng(illustration)),
      coveragePercent: (bestCount / totalPixels) * 100,
    );
  }

  double _percentile(List<double> values, double percentile) {
    if (values.isEmpty) {
      return 0;
    }
    final sorted = List<double>.from(values)..sort();
    final index = ((percentile / 100) * (sorted.length - 1)).round();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  _MaskComponent _largestComponent(List<bool> mask, int width, int height) {
    final visited = List<bool>.filled(mask.length, false);
    var bestMask = List<bool>.filled(mask.length, false);
    var bestCount = 0;

    for (var start = 0; start < mask.length; start++) {
      if (!mask[start] || visited[start]) {
        continue;
      }

      final currentPixels = <int>[];
      final queue = <int>[start];
      visited[start] = true;

      for (var cursor = 0; cursor < queue.length; cursor++) {
        final index = queue[cursor];
        currentPixels.add(index);
        final x = index % width;
        final y = index ~/ width;

        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) {
              continue;
            }
            final nx = x + dx;
            final ny = y + dy;
            if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
              continue;
            }
            final nextIndex = ny * width + nx;
            if (visited[nextIndex] || !mask[nextIndex]) {
              continue;
            }
            visited[nextIndex] = true;
            queue.add(nextIndex);
          }
        }
      }

      if (currentPixels.length > bestCount) {
        bestCount = currentPixels.length;
        bestMask = List<bool>.filled(mask.length, false);
        for (final pixelIndex in currentPixels) {
          bestMask[pixelIndex] = true;
        }
      }
    }

    return _MaskComponent(mask: bestMask, count: bestCount);
  }

  bool _isContour(List<bool> mask, int width, int height, int x, int y) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
          return true;
        }
        if (!mask[ny * width + nx]) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isInnerPixel(List<bool> mask, int width, int height, int x, int y) {
    for (var dy = -4; dy <= 4; dy++) {
      for (var dx = -4; dx <= 4; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
          return false;
        }
        if (!mask[ny * width + nx]) {
          return false;
        }
      }
    }
    return true;
  }

  int _lerp(num start, num end, double amount) {
    return (start + ((end - start) * amount)).round().clamp(0, 255);
  }
}

class _LoadedTfliteModel {
  final tfl.Interpreter interpreter;
  final _TfliteModelConfig config;

  const _LoadedTfliteModel({required this.interpreter, required this.config});
}

class _TfliteModelConfig {
  final int imageWidth;
  final int imageHeight;
  final double threshold;
  final double cautionThreshold;
  final double specialistThreshold;
  final double borderlineThreshold;
  final String modelVersion;
  final String preprocessingMode;

  const _TfliteModelConfig({
    required this.imageWidth,
    required this.imageHeight,
    required this.threshold,
    required this.cautionThreshold,
    required this.specialistThreshold,
    required this.borderlineThreshold,
    required this.modelVersion,
    required this.preprocessingMode,
  });

  String get preprocessingSummary => switch (preprocessingMode) {
    'center_crop_sharpen' =>
      'The image was orientation-corrected, center-cropped, mildly sharpened, and resized for the on-device model.',
    'center_crop' =>
      'The image was orientation-corrected, center-cropped, and resized for the on-device model.',
    _ =>
      'The image was orientation-corrected and resized for the on-device model.',
  };

  static Future<_TfliteModelConfig> load(String assetPath) async {
    try {
      final rawConfig = await rootBundle.loadString(assetPath);
      final json = jsonDecode(rawConfig);
      if (json is! Map<String, dynamic>) {
        return fallback;
      }

      final imageSize = json['image_size'];
      final width = imageSize is List && imageSize.isNotEmpty
          ? (imageSize.first as num?)?.toInt() ?? fallback.imageWidth
          : fallback.imageWidth;
      final height = imageSize is List && imageSize.length > 1
          ? (imageSize[1] as num?)?.toInt() ?? fallback.imageHeight
          : fallback.imageHeight;

      return _TfliteModelConfig(
        imageWidth: width,
        imageHeight: height,
        threshold:
            (json['threshold'] as num?)?.toDouble() ?? fallback.threshold,
        cautionThreshold:
            (json['caution_threshold'] as num?)?.toDouble() ??
            (json['threshold'] as num?)?.toDouble() ??
            fallback.cautionThreshold,
        specialistThreshold:
            (json['specialist_threshold'] as num?)?.toDouble() ??
            fallback.specialistThreshold,
        borderlineThreshold:
            (json['borderline_threshold'] as num?)?.toDouble() ??
            fallback.borderlineThreshold,
        modelVersion:
            (json['model_version'] as String?) ?? fallback.modelVersion,
        preprocessingMode:
            (json['preprocessing_mode'] as String?) ??
            fallback.preprocessingMode,
      );
    } catch (_) {
      return fallback;
    }
  }

  static const fallback = _TfliteModelConfig(
    imageWidth: 224,
    imageHeight: 224,
    threshold: 0.5,
    cautionThreshold: 0.5,
    specialistThreshold: 0.75,
    borderlineThreshold: 0.35,
    modelVersion: 'ham10000-melanoma-binary-tflite',
    preprocessingMode: 'resize',
  );
}

class _PatientPredictionMessage {
  final String status;
  final String summary;
  final String recommendation;

  const _PatientPredictionMessage({
    required this.status,
    required this.summary,
    required this.recommendation,
  });
}

class _GeneratedIllustration {
  final Uint8List bytes;
  final double coveragePercent;

  const _GeneratedIllustration({
    required this.bytes,
    required this.coveragePercent,
  });
}

class _ScanImageQualityAssessment {
  final double score;
  final String status;
  final String summary;
  final List<String> warnings;
  final String preprocessingSummary;

  const _ScanImageQualityAssessment({
    required this.score,
    required this.status,
    required this.summary,
    required this.warnings,
    required this.preprocessingSummary,
  });

  bool get isRetakeRecommended => score < 65;
}

class _ImageQualityStats {
  final double brightness;
  final double contrast;
  final double sharpnessVariance;

  const _ImageQualityStats({
    required this.brightness,
    required this.contrast,
    required this.sharpnessVariance,
  });
}

class _MaskComponent {
  final List<bool> mask;
  final int count;

  const _MaskComponent({required this.mask, required this.count});
}

class MemoryScanPredictionService implements ScanPredictionService {
  @override
  Future<ScanPredictionResult> predictScan({
    required SelectedScanImage image,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return ScanPredictionResult(
      predictedClass: 'Non-melanoma pattern',
      melanomaProbability: 0.18,
      confidence: 0.82,
      status: 'Low melanoma risk',
      summary:
          'The preview model found a stronger match with non-melanoma examples than melanoma examples.',
      recommendation:
          'Keep monitoring the lesion and seek dermatologist review if the area changes in size, color, border, or symptoms.',
      modelVersion: 'preview-memory-v1',
      illustrationBytes: image.bytes,
      illustrationFilename: 'preview_lesion_illustration.png',
      lesionCoveragePercent: 24.0,
      visualizationSummary:
          'A generated preview illustration is ready to save instead of the raw scan image.',
      imageQualityScore: 92,
      imageQualityStatus: 'Good photo quality',
      imageQualitySummary:
          'Quality score 92/100. Preview lighting and sharpness are acceptable.',
      preprocessingSummary:
          'Preview mode uses the same result fields as the on-device scan.',
    );
  }
}
