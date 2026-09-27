import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class ScanReviewPage extends StatelessWidget {
  const ScanReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Scan Review',
      description:
          'This page can show the selected patient, lesion details, and photo before analysis starts.',
    );
  }
}
