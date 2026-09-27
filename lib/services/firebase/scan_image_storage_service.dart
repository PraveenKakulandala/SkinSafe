import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/models/selected_scan_image.dart';
import '../../shared/models/uploaded_scan_image.dart';

abstract interface class ScanImageStorageService {
  Future<UploadedScanImage> uploadImage({
    required String uid,
    required SelectedScanImage image,
    required String assetFolder,
    required String assetRole,
  });
}

class LocalScanImageStorageService implements ScanImageStorageService {
  @override
  Future<UploadedScanImage> uploadImage({
    required String uid,
    required SelectedScanImage image,
    required String assetFolder,
    required String assetRole,
  }) async {
    final normalizedFolder = assetFolder.trim().isEmpty
        ? 'misc'
        : assetFolder.trim();
    final extension = image.extension;
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final candidateRoots = <Directory>[
      await getApplicationSupportDirectory(),
      await getTemporaryDirectory(),
    ];

    Object? lastError;

    for (final rootDirectory in candidateRoots) {
      final directory = Directory(
        '${rootDirectory.path}${Platform.pathSeparator}skinsafe${Platform.pathSeparator}$uid${Platform.pathSeparator}scans${Platform.pathSeparator}$normalizedFolder',
      );

      try {
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final filePath =
            '${directory.path}${Platform.pathSeparator}scan_$timestamp$extension';
        final file = File(filePath);

        debugPrint(
          'Saving $assetRole locally at $filePath (${image.bytes.length} bytes).',
        );

        await file.writeAsBytes(image.bytes, flush: true);

        return UploadedScanImage(
          imageUrl: file.path,
          storagePath: file.path,
        );
      } catch (error) {
        lastError = error;
        debugPrint(
          'Failed to save $assetRole at ${directory.path}: $error',
        );
      }
    }

    throw FileSystemException(
      'Unable to save $assetRole to the app storage directories.',
      '',
      lastError is OSError ? lastError : null,
    );
  }
}

class MemoryScanImageStorageService implements ScanImageStorageService {
  @override
  Future<UploadedScanImage> uploadImage({
    required String uid,
    required SelectedScanImage image,
    required String assetFolder,
    required String assetRole,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    return UploadedScanImage(
      imageUrl: 'preview://$uid/$assetFolder/${image.id}',
      storagePath: 'preview://$uid/$assetFolder/${image.id}',
    );
  }
}
