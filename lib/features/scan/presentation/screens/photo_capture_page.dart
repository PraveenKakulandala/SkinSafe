import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class PhotoCapturePage extends StatelessWidget {
  const PhotoCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Photo Capture',
      description:
          'This page can manage live camera capture, gallery selection, and capture settings before analysis.',
    );
  }
}
