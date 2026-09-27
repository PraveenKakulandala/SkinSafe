import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class PatientSelectPage extends StatelessWidget {
  const PatientSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Patient Select',
      description:
          'This page can list existing patients and let the user select or add a new patient before scanning.',
    );
  }
}
