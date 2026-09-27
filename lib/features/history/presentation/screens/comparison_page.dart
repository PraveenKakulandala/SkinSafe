import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class ComparisonPage extends StatelessWidget {
  const ComparisonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Comparison',
      description:
          'This page can compare two lesion captures side by side for longitudinal follow-up.',
    );
  }
}
