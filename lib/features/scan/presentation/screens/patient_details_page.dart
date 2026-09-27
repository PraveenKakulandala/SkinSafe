import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class PatientDetailsPage extends StatelessWidget {
  const PatientDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Patient Details',
      description:
          'This page can hold patient name, age, and contact details as a dedicated step in the scan flow.',
    );
  }
}
