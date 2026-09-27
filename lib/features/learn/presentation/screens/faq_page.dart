import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'FAQ',
      description:
          'This page can answer common user questions about scans, results, reminders, and follow-up care.',
    );
  }
}
