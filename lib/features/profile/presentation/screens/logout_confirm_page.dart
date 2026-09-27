import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class LogoutConfirmPage extends StatelessWidget {
  const LogoutConfirmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Logout Confirmation',
      description:
          'This page can confirm logout and explain what will happen before ending the user session.',
    );
  }
}
