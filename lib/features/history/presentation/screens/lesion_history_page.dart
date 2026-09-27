import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class LesionHistoryPage extends StatelessWidget {
  const LesionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Lesion History',
      description:
          'This page can show one lesion timeline, comparison cards, and status changes over time.',
    );
  }
}
