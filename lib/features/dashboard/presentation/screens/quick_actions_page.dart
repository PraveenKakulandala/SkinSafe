import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class QuickActionsPage extends StatelessWidget {
  const QuickActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Quick Actions',
      description:
          'This page can hold fast shortcuts for scanning, reviewing history, reminders, and clinical next steps.',
    );
  }
}
