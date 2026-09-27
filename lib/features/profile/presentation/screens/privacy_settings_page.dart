import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Privacy Settings',
      description:
          'This page can manage privacy controls, data storage explanations, and account-level security options.',
    );
  }
}
