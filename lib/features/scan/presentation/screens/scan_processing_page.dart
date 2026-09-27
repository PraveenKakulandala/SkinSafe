import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class ScanProcessingPage extends StatelessWidget {
  const ScanProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Scan Processing',
      description:
          'This page can show model progress, local save state, and current scan-analysis steps in progress.',
    );
  }
}
