import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class CaptureGuidePage extends StatelessWidget {
  const CaptureGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Capture Guide',
      description:
          'This page can show visual guidance for stability timing, framing, and follow-up alignment.',
    );
  }
}
