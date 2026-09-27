import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class ScanLandingPage extends StatelessWidget {
  const ScanLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Scan Landing',
      description:
          'This page can introduce the scan flow, recent scans, and a clear button to begin a new guided scan.',
    );
  }
}
