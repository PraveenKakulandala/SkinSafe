import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Edit Profile',
      description:
          'This page can let users update name, age, contact details, and other personal information.',
    );
  }
}
