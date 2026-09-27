import 'dart:typed_data';

enum ScanImageSource { camera, gallery }

extension ScanImageSourceLabel on ScanImageSource {
  String get label => switch (this) {
    ScanImageSource.camera => 'Camera',
    ScanImageSource.gallery => 'Gallery',
  };
}

class SelectedScanImage {
  final String id;
  final String name;
  final String? path;
  final Uint8List bytes;
  final ScanImageSource source;

  const SelectedScanImage({
    required this.id,
    required this.name,
    required this.path,
    required this.bytes,
    required this.source,
  });

  String get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) {
      return '.jpg';
    }
    return name.substring(dotIndex).toLowerCase();
  }
}
