import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../shared/models/selected_scan_image.dart';

abstract interface class ScanImagePickerService {
  Future<SelectedScanImage?> pickImage(ScanImageSource source);
}

class DeviceScanImagePickerService implements ScanImagePickerService {
  final ImagePicker _imagePicker;

  DeviceScanImagePickerService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<SelectedScanImage?> pickImage(ScanImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source == ScanImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1600,
    );

    if (file == null) {
      return null;
    }

    final bytes = await file.readAsBytes();

    return SelectedScanImage(
      id: 'selected-${DateTime.now().microsecondsSinceEpoch}',
      name: file.name,
      path: file.path,
      bytes: bytes,
      source: source,
    );
  }
}

class MemoryScanImagePickerService implements ScanImagePickerService {
  static final Uint8List _samplePng = Uint8List.fromList(const <int>[
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    6,
    0,
    0,
    0,
    31,
    21,
    196,
    137,
    0,
    0,
    0,
    13,
    73,
    68,
    65,
    84,
    120,
    156,
    99,
    248,
    255,
    255,
    63,
    0,
    5,
    254,
    2,
    254,
    167,
    53,
    129,
    132,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ]);

  @override
  Future<SelectedScanImage?> pickImage(ScanImageSource source) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    return SelectedScanImage(
      id: 'preview-${DateTime.now().microsecondsSinceEpoch}',
      name: 'preview_scan.png',
      path: null,
      bytes: _samplePng,
      source: source,
    );
  }
}
