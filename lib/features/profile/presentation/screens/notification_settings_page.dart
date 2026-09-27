import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Notification Settings',
      description:
          'This page can manage reminder notifications, follow-up intervals, and alert preferences.',
    );
  }
}
