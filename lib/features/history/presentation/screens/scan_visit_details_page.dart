import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class ScanVisitDetailsPage extends StatelessWidget {
  const ScanVisitDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Scan Visit Details',
      description:
          'This page can show one saved visit, scan summary, risk information, and media previews.',
    );
  }
}
