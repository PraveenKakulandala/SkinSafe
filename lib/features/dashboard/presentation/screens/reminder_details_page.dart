import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class ReminderDetailsPage extends StatelessWidget {
  const ReminderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Reminder Details',
      description:
          'This page can show reminder timing, scan intervals, and follow-up actions for the selected patient.',
    );
  }
}
