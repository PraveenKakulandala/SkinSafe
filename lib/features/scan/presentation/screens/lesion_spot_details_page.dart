import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class LesionSpotDetailsPage extends StatelessWidget {
  const LesionSpotDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Lesion Spot Details',
      description:
          'This page can capture a clear lesion label, optional note, and exact spot information for one mole.',
    );
  }
}
